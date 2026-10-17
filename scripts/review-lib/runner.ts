import { spawn } from "node:child_process";
import { createWriteStream, existsSync } from "node:fs";
import { copyFile, mkdir, open, readFile, realpath, rename, rm, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { registerReviewChat } from "./agents-index";
import { claudeTranscript, createCodexChat, nativeChatCommand } from "./native-chat";
import { command, fetchPull } from "./github";
import { busy, directory, initialize, key, processAlive, readJson, writeJson, REVIEW_SCOPE, type Config, type Pull, type Review, type Run } from "./store";
import { claudeFlags, codexFlags } from "../agent-lib/agent";

export function runDirectory(root: string, review: Review): string {
  if (!review.run) {
    throw new Error(`No generated review for ${key(review.pull)}`);
  }

  return join(directory(root, review.pull), "runs", review.run.id);
}

export async function loadReview(root: string, pull: Pull): Promise<Review> {
  return await readJson<Review>(join(directory(root, pull), "review.json")) ?? { pull, run: null, checkoutSha: null };
}

async function saveReview(root: string, review: Review): Promise<void> {
  const dir = directory(root, review.pull);
  if (review.run) {
    review.run.lastActivityAt = new Date().toISOString();
  }
  await writeJson(join(dir, "review.json"), review);
  if (review.run) {
    await writeJson(join(runDirectory(root, review), "run.json"), review.run);
    await writeJson(join(dir, "chat.json"), {
      agent: review.run.agent, model: review.run.model, sessionId: review.run.sessionId,
      cwd: join(dir, "worktree"), nativeLog: review.run.nativeLog ?? null, events: join(runDirectory(root, review), "events.jsonl"),
    });
    await registerReviewChat(root, review);
  }
}

async function releaseLock(path: string): Promise<void> {
  try {
    const owner = Number(await readFile(path, "utf8"));
    if (owner === process.pid) {
      await rm(path);
    }
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
      throw error;
    }
  }
}

export async function startReview(root: string, pull: Pull, script: string, interactive = false): Promise<void> {
  const config = await initialize(root);
  const dir = directory(root, pull);
  await mkdir(dir, { recursive: true, mode: 0o700 });
  const lockPath = join(dir, "generation.lock");

  // An exclusive file closes the race between two UI instances starting the same PR.
  let lock;
  try {
    lock = await open(lockPath, "wx", 0o600);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "EEXIST") {
      throw error;
    }
    const owner = Number(await readFile(lockPath, "utf8"));
    const initializing = !owner && Date.now() - (await stat(lockPath)).mtimeMs < 30000;
    if (initializing || processAlive(owner)) {
      throw new Error(`Generation is already starting for ${key(pull)}.`);
    }
    await rm(lockPath);
    lock = await open(lockPath, "wx", 0o600);
  }
  await lock.writeFile(String(process.pid));
  await lock.close();

  try {
    const previous = await loadReview(root, pull);
    if (busy(previous.run)) {
      throw new Error(`Generation is already running for ${key(pull)}.`);
    }
    const startedAt = new Date().toISOString();
    const run: Run = {
      id: `${startedAt.replace(/[:.]/g, "-")}-${crypto.randomUUID().slice(0, 8)}`,
      status: "queued", agent: config.agent, model: config.model, fast: config.fast, sessionId: null,
      mode: interactive ? "interactive" : "background",
      headSha: pull.sha, baseSha: null, pid: process.pid, startedAt, finishedAt: null, error: null,
    };
    const review = { pull, run, checkoutSha: previous.checkoutSha };
    const runDir = runDirectory(root, review);
    await mkdir(runDir, { recursive: true, mode: 0o700 });
    await writeFile(join(runDir, "template.md"), await readFile(join(root, "prompt.md"), "utf8"), { mode: 0o600 });
    await saveReview(root, review);

    if (interactive) {
      console.log(`Opening ${run.agent} chat for ${key(pull)}. Preparing the worktree…`);
      const finished = await worker(root, pull, run.id);
      if (finished.run?.status !== "complete") {
        throw new Error(`Generation failed: ${finished.run?.error ?? "chat exited without HTML"}`);
      }
      return;
    }

    const log = await open(join(runDir, "worker.log"), "a", 0o600);
    try {
      const child = spawn(process.execPath, [script, "--home", root, "_worker", key(pull), run.id], {
        detached: true, stdio: ["ignore", log.fd, log.fd],
      });
      await new Promise<void>((resolve, reject) => {
        child.once("spawn", resolve);
        child.once("error", reject);
      });
      await writeFile(lockPath, String(child.pid));
      run.pid = child.pid!;
      await saveReview(root, review);
      child.unref();
    } finally {
      await log.close();
    }
  } catch (error) {
    await releaseLock(lockPath);
    throw error;
  }
}

async function findClone(pull: Pull): Promise<string> {
  const codeRoot = process.env.REVIEW_CODE_ROOT ?? join(homedir(), "code");
  const candidates = await Array.fromAsync(new Bun.Glob("*/.git").scan({ cwd: codeRoot, onlyFiles: false, dot: true }));
  const matches = await Promise.all(candidates.map(async (entry) => {
    const path = join(codeRoot, entry.slice(0, -5));
    try {
      const remote = await command(["git", "config", "--get", "remote.origin.url"], path);
      const slug = remote.match(/github\.com[/:]([^/]+\/[^/]+?)(?:\.git)?\/?$/)?.[1];
      return slug?.toLowerCase() === pull.repo ? path : null;
    } catch {
      return null;
    }
  }));
  const found = matches.filter((path): path is string => path !== null).sort();
  const preferred = found.find((path) => path.endsWith(`/${pull.repo.split("/")[1]}`)) ?? found[0];
  if (!preferred) {
    throw new Error(`Clone ${pull.repo} under ${codeRoot} first: gh repo clone ${pull.repo}`);
  }

  return preferred;
}

async function prepareWorktree(root: string, review: Review): Promise<string> {
  const { pull } = review;
  const clone = await findClone(pull);
  const worktree = join(directory(root, pull), "worktree");
  const refs = `refs/review/pr-${pull.number}`;
  await command([
    "git", "fetch", "origin", `+refs/pull/${pull.number}/head:${refs}/head`,
    `+refs/heads/${pull.base}:${refs}/base`,
  ], clone);
  const sha = await command(["git", "rev-parse", `${refs}/head`], clone);
  if (sha !== pull.sha) {
    throw new Error("The PR changed while fetching. Refresh and generate again.");
  }
  review.run!.baseSha = await command(["git", "rev-parse", `${refs}/base`], clone);

  const worktrees = JSON.parse(await command(["wt", "-C", clone, "list", "--format=json"])) as { path: string; branch?: string }[];
  const canonical = existsSync(worktree) ? await realpath(worktree) : worktree;
  const existing = worktrees.find((item) => item.path === canonical || item.path === worktree);
  if (!existing) {
    const branch = `jordan/review-pr-${pull.number}`;
    if (worktrees.some((item) => item.branch === branch)) {
      throw new Error(`${branch} already has a worktree elsewhere. Move or rename it before generating.`);
    }
    await command(["wt", "-C", clone, "switch", "--create", branch, "--base", sha, "--no-cd", "--yes"], clone, {
      ...process.env, WORKTRUNK_WORKTREE_PATH: worktree,
    });
  }

  const actual = await command(["git", "rev-parse", "--show-toplevel"], worktree);
  if (await realpath(actual) !== await realpath(worktree)) {
    throw new Error(`Expected a worktree at ${worktree}, got ${actual}`);
  }
  const dirty = await command(["git", "status", "--porcelain", "--untracked-files=no"], worktree);
  if (dirty) {
    throw new Error(`Save your tracked changes in ${worktree} before regenerating.`);
  }
  const current = await command(["git", "rev-parse", "HEAD"], worktree);
  if (existing && review.checkoutSha && current !== review.checkoutSha) {
    throw new Error(`The worktree HEAD changed outside rv (${current.slice(0, 8)}). Keep your commits and use another review directory.`);
  }
  // Detached checkout handles rebased PRs. Git preserves untracked files and rejects collisions.
  await command(["git", "switch", "--detach", sha], worktree);
  review.checkoutSha = sha;
  await saveReview(root, review);

  return worktree;
}

export function agentCommand(config: Config, sessionId: string | null): string[] {
  if (config.agent === "codex") {
    return ["codex", "exec", "--json", "--dangerously-bypass-approvals-and-sandbox", ...codexFlags(config), "-"];
  }

  return ["claude", "--print", "--verbose", "--output-format", "stream-json", "--dangerously-skip-permissions", "--session-id", sessionId!, ...claudeFlags(config)];
}

export function sessionFromEvent(event: Record<string, unknown>): string | null {
  const value = event.type === "thread.started" ? event.thread_id : event.session_id;

  return typeof value === "string" && /^[0-9a-f-]{36}$/i.test(value) ? value : null;
}

type AgentEvent = {
  type?: string;
  item?: { type?: string; text?: string };
  message?: { content?: { type: string; text?: string }[] };
};

export function textFromEvent(event: AgentEvent): string | null {
  if (event.type === "item.completed" && event.item?.type === "agent_message") {
    return event.item.text ?? null;
  }
  if (event.type === "assistant") {
    return event.message?.content?.filter((part) => part.type === "text")
      .map((part) => part.text ?? "").join("\n") || null;
  }

  return null;
}

async function generate(root: string, review: Review, cwd: string): Promise<void> {
  const run = review.run!;
  const runDir = runDirectory(root, review);
  const output = join(runDir, `${run.startedAt.slice(0, 10)}-diff.html`);
  const template = await readFile(join(runDir, "template.md"), "utf8");
  const prompt = `${template}\n\n## Review target\n\n${key(review.pull)} — ${review.pull.title}\n${review.pull.url}\n\n` +
    `The worktree is checked out at ${run.headSha}. The base commit is ${run.baseSha}.\n` +
    `Read the diff with: git diff ${run.baseSha}...${run.headSha}\n` +
    `Save the complete HTML to exactly: ${output}\n` +
    `${REVIEW_SCOPE}\n\n` +
    `Write the HTML, report its path, and wait for review feedback. Do not open a browser; rv opens the finished file.\n`;
  await writeFile(join(runDir, "prompt.md"), prompt, { mode: 0o600 });
  await writeFile(join(runDir, "chat.md"), `# ${key(review.pull)}\n\n## Prompt\n\n${prompt}\n\n## Assistant\n\n`, { mode: 0o600 });
  if (run.mode === "interactive") {
    await generateInChat(root, review, cwd, prompt, output);
    return;
  }
  run.sessionId = run.agent === "claude" ? crypto.randomUUID() : null;
  await saveReview(root, review);

  const events = createWriteStream(join(runDir, "events.jsonl"), { mode: 0o600 });
  const chat = createWriteStream(join(runDir, "chat.md"), { flags: "a", mode: 0o600 });
  const child = spawn(agentCommand(run, run.sessionId)[0], agentCommand(run, run.sessionId).slice(1), {
    cwd, stdio: ["pipe", "pipe", "inherit"],
  });
  const completion = new Promise<number>((resolve, reject) => {
    child.once("error", reject);
    child.once("exit", (code, signal) => resolve(code ?? (signal ? 130 : 1)));
  });
  // Install the rejection handler immediately while stdout is consumed below.
  void completion.catch(() => {});
  child.stdin!.on("error", (error) => console.error(`Agent stdin: ${error.message}`));
  child.stdin!.end(prompt);
  let agentError: string | null = null;
  const lines = createInterface({ input: child.stdout! });
  try {
    for await (const line of lines) {
      events.write(`${line}\n`);
      let event;
      try {
        event = JSON.parse(line);
      } catch {
        continue;
      }
      const sessionId = sessionFromEvent(event);
      if (sessionId && sessionId !== run.sessionId) {
        run.sessionId = sessionId;
        await saveReview(root, review);
      }
      const text = textFromEvent(event);
      if (text) {
        chat.write(`${text}\n\n`);
      }
      if (event.type === "turn.failed" || (event.type === "result" && event.is_error)) {
        agentError = JSON.stringify(event.error ?? event.errors ?? event.result ?? event);
      }
    }
    const code = await completion;
    if (code !== 0 || agentError) {
      throw new Error(`${run.agent} failed (exit ${code}): ${agentError ?? "see worker.log"}`);
    }
  } finally {
    events.end();
    chat.end();
  }

  const html = await readFile(output, "utf8");
  if (!/<html[\s>]/i.test(html) || !/<\/html>/i.test(html)) {
    throw new Error(`The agent did not write a complete HTML page at ${output}`);
  }
  const latest = join(directory(root, review.pull), "diff.html");
  await writeFile(`${latest}.tmp`, html, { mode: 0o600 });
  await rename(`${latest}.tmp`, latest);
  await writeJson(join(directory(root, review.pull), "html.json"), { runId: run.id, headSha: run.headSha });
}

async function generateInChat(root: string, review: Review, cwd: string, prompt: string, output: string): Promise<void> {
  const run = review.run!;
  const runDir = runDirectory(root, review);
  if (run.agent === "codex") {
    const session = await createCodexChat(cwd, run.model, key(review.pull));
    run.sessionId = session.id;
    run.nativeLog = session.path;
  } else {
    run.sessionId = crypto.randomUUID();
  }
  await saveReview(root, review);

  const args = nativeChatCommand(run, prompt);
  const child = spawn(args[0], args.slice(1), { cwd, stdio: "inherit" });
  const completion = new Promise<number>((resolve, reject) => {
    child.once("error", reject);
    child.once("exit", (code, signal) => resolve(code ?? (signal ? 130 : 1)));
  });
  void completion.catch(() => {});
  let published = "";
  let opened = false;
  let syncError: unknown = null;
  let syncing: Promise<void> | null = null;
  const synchronize = async () => {
    if (run.agent === "claude" && !run.nativeLog) {
      const path = await claudeTranscript(run.sessionId!);
      if (path) {
        run.nativeLog = path;
        await saveReview(root, review);
      }
    }
    let html: string;
    try {
      html = await readFile(output, "utf8");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return;
      }
      throw error;
    }
    if (html === published || !/<html[\s>]/i.test(html) || !/<\/html>/i.test(html)) {
      return;
    }
    const latest = join(directory(root, review.pull), "diff.html");
    await writeFile(`${latest}.tmp`, html, { mode: 0o600 });
    await rename(`${latest}.tmp`, latest);
    await writeJson(join(directory(root, review.pull), "html.json"), { runId: run.id, headSha: run.headSha });
    run.status = "complete";
    run.finishedAt = new Date().toISOString();
    await saveReview(root, review);
    published = html;
    if (!opened) {
      await command(["open", latest]);
      opened = true;
    }
  };
  const timer = setInterval(() => {
    if (!syncing) {
      syncing = synchronize().catch((error) => { syncError = error; }).finally(() => { syncing = null; });
    }
  }, 300);

  try {
    const code = await completion;
    clearInterval(timer);
    await syncing;
    await synchronize();
    if (run.nativeLog && existsSync(run.nativeLog)) {
      await copyFile(run.nativeLog, join(runDir, "native.jsonl"));
    }
    if (syncError) {
      throw syncError;
    }
    if (!published) {
      throw new Error(`${run.agent} chat exited (${code}) before writing a complete HTML review.`);
    }
  } finally {
    clearInterval(timer);
    await syncing;
  }
}

export async function worker(root: string, pull: Pull, runId: string): Promise<Review> {
  let review = await loadReview(root, pull);
  const deadline = Date.now() + 5000;
  // The parent hands off the lock and saved PID before the worker can write run state.
  while (review.run?.id === runId && review.run.pid !== process.pid && Date.now() < deadline) {
    await Bun.sleep(25);
    review = await loadReview(root, pull);
  }
  const run = review.run;
  if (!run || run.id !== runId || run.pid !== process.pid) {
    throw new Error(`Review run ${runId} was replaced before its worker started.`);
  }
  const lockPath = join(directory(root, pull), "generation.lock");
  run.pid = process.pid;
  run.status = "running";
  await writeFile(lockPath, String(process.pid));
  await saveReview(root, review);
  try {
    review.pull = await fetchPull(pull);
    run.headSha = review.pull.sha;
    const cwd = await prepareWorktree(root, review);
    await generate(root, review, cwd);
    run.status = "complete";
  } catch (error) {
    run.status = "failed";
    run.error = String(error);
    console.error(run.error);
  } finally {
    run.finishedAt = new Date().toISOString();
    await saveReview(root, review);
    await releaseLock(lockPath);
  }

  return review;
}
