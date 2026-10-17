import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { mkdir, mkdtemp, readFile, rename, rm, utimes, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { allPulls, command, daysAgo, resolvePull, takeDays, weekAgo } from "./github";
import { sessionFromEvent, textFromEvent } from "./runner";
import { parseTarget, plain, readJson, shellQuote, stallMinutes, writeJson, type Review } from "./store";
import { indicators, others } from "./actions";
import { generationActivity } from "./activity";
import { dashboard, relativeAge } from "./dashboard";

const script = resolve(import.meta.dir, "../review");
const pull = {
  repo: "acme/demo", number: 10, title: "Test review", body: "A test PR.", author: "author",
  url: "https://github.com/acme/demo/pull/10", state: "OPEN", updatedAt: new Date().toISOString(), createdAt: new Date(Date.now() - 2 * 86400000).toISOString(), head: "topic", base: "main", sha: "abc",
  decision: "APPROVED", reviewers: [
    { login: "me", state: "COMMENTED", bot: false },
    { login: "author", state: "COMMENTED", bot: false },
    { login: "colleague", state: "APPROVED", bot: false },
    { login: "robot", state: "COMMENTED", bot: true },
  ],
};

test("PR keys accept links, reject traversal, and preserve repository identity", () => {
  expect(parseTarget("https://github.com/acme/demo/pull/10/changes")).toEqual({ repo: "acme/demo", number: 10 });
  expect(parseTarget("https://app.graphite.com/github/pr/acme/demo/10?foo=bar")).toEqual({ repo: "acme/demo", number: 10 });
  expect(parseTarget("acme/demo#10")).toEqual({ repo: "acme/demo", number: 10 });
  expect(parseTarget("../demo#10")).toBeNull();
  expect(parseTarget("acme/..#10")).toBeNull();
  expect(parseTarget("acme/demo#0")).toBeNull();
});

test("reviewer indicators distinguish other people from the viewer, author, and bots", () => {
  expect(others(pull, "me").map((person) => person.login)).toEqual(["colleague"]);
});

test("terminal text is inert and paths are shell quoted", () => {
  expect(plain("hello\x1b[31m red\n\t\x00")).toBe("hello red   ");
  expect(shellQuote("a'b $(touch nope)")).toBe("'a'\\''b $(touch nope)'");
});

test("both agent protocols record exact session IDs and assistant text", () => {
  const id = "12345678-1234-1234-1234-123456789abc";
  expect(sessionFromEvent({ type: "thread.started", thread_id: id })).toBe(id);
  expect(sessionFromEvent({ type: "system", session_id: id })).toBe(id);
  expect(sessionFromEvent({ type: "thread.started", thread_id: "--last" })).toBeNull();
  expect(textFromEvent({ type: "item.completed", item: { type: "agent_message", text: "done" } })).toBe("done");
  expect(textFromEvent({ type: "assistant", message: { content: [{ type: "text", text: "done" }] } })).toBe("done");
});

test("relative PR ages handle minutes, hours, days, missing dates, and clock skew", () => {
  const now = Date.parse("2026-09-22T12:00:00Z");
  expect(relativeAge("2026-09-20T11:00:00Z", now)).toBe("2d ago");
  expect(relativeAge("2026-09-22T10:00:00Z", now)).toBe("2h ago");
  expect(relativeAge("2026-09-22T11:58:00Z", now)).toBe("2m ago");
  expect(relativeAge("2026-09-22T12:01:00Z", now)).toBe("just now");
  expect(relativeAge(undefined, now)).toBe("—");
  expect(relativeAge("invalid", now)).toBe("—");
});

test("stall timeout defaults to ten minutes and rejects invalid settings", () => {
  expect(stallMinutes({})).toBe(10);
  expect(stallMinutes({ stallMinutes: 3 })).toBe(3);
  for (const minutes of [0, -1, NaN, Infinity]) {
    expect(() => stallMinutes({ stallMinutes: minutes })).toThrow("positive number");
  }
});

describe("persistent review lifecycle with real Git/worktrunk and fake agent CLIs", () => {
  let fixture: string;
  let root: string;
  let agentConfig: string;
  let env: NodeJS.ProcessEnv;
  let sha: string;
  const sessionId = "12345678-1234-1234-1234-123456789abc";

  async function cli(args: string[], extra: NodeJS.ProcessEnv = {}) {
    const child = Bun.spawn([process.execPath, script, "--home", root, ...args], {
      env: { ...env, ...extra }, stdin: "ignore", stdout: "pipe", stderr: "pipe",
    });
    const [stdout, stderr, code] = await Promise.all([
      new Response(child.stdout).text(), new Response(child.stderr).text(), child.exited,
    ]);

    return { stdout, stderr, code };
  }

  async function finished(previousId?: string): Promise<Review> {
    const until = Date.now() + 20000;
    while (Date.now() < until) {
      const review = await readJson<Review>(join(root, "acme/demo/pr-10/review.json"));
      if (review?.run && review.run.id !== previousId && ["complete", "failed"].includes(review.run.status)) {
        return review;
      }
      await Bun.sleep(50);
    }

    throw new Error("Worker did not finish within 20 seconds");
  }

  beforeAll(async () => {
    fixture = await mkdtemp(join(tmpdir(), "rv-test-"));
    root = join(fixture, "reviews with spaces");
    agentConfig = join(fixture, "agent.json");
    const bin = join(fixture, "bin");
    const codeRoot = join(fixture, "code");
    const origin = join(fixture, "origin.git");
    await mkdir(bin);
    await mkdir(codeRoot);
    await writeFile(join(fixture, "wt.toml"), "");
    await writeFile(join(fixture, "gitconfig"), "");
    env = {
      ...process.env, PATH: `${bin}:${process.env.PATH}`, REVIEW_CODE_ROOT: codeRoot,
      WORKTRUNK_CONFIG_PATH: join(fixture, "wt.toml"), GIT_CONFIG_GLOBAL: join(fixture, "gitconfig"),
      RV_TEST_FIXTURE: fixture, CLAUDE_CONFIG_DIR: join(fixture, "claude-config"), AGENT_CONFIG: agentConfig,
      KITTY_AGENTS_STATE: join(fixture, "kitty-agents"),
    };
    process.env.KITTY_AGENTS_STATE = env.KITTY_AGENTS_STATE;
    // Fetch an existing commit into a disposable remote; tests create no commits or authorship.
    await command(["git", "init", "--bare", origin], undefined, env);
    await command(["git", "fetch", resolve(import.meta.dir, "../.."), "HEAD:refs/heads/main"], origin, env);
    await command(["git", "symbolic-ref", "HEAD", "refs/heads/main"], origin, env);
    sha = await command(["git", "rev-parse", "main"], origin, env);
    await command(["git", "update-ref", "refs/pull/10/head", sha], origin, env);
    await command(["git", "clone", origin, join(codeRoot, "demo")], undefined, env);
    await command(["git", "remote", "set-url", "origin", "https://github.com/acme/demo.git"], join(codeRoot, "demo"), env);
    await command(["git", "config", `url.file://${origin}.insteadOf`, "https://github.com/acme/demo.git"], join(codeRoot, "demo"), env);

    const node = {
      ...pull, repository: { nameWithOwner: pull.repo }, author: { login: pull.author },
      headRefName: pull.head, baseRefName: pull.base, headRefOid: sha, reviewDecision: pull.decision,
      latestReviews: { nodes: [
        { state: "APPROVED", author: { login: "colleague", __typename: "User" } },
        { state: "COMMENTED", author: { login: "robot", __typename: "Bot" } },
      ] },
    };
    await writeFile(join(bin, "gh"), `#!${process.execPath}
const node = ${JSON.stringify(node)};
const query = process.argv.join(' ');
if(process.env.RV_TEST_OFFLINE) process.exit(1);
const merged = { ...node, number: 12, state: 'MERGED', mergedAt: new Date(Date.now() - 3600000).toISOString() };
const nodes = query.includes('reviewed-by:@me') ? [merged] : [node];
console.log(JSON.stringify(query.includes('search(') ? { data: { viewer: {login:'me'}, search: {nodes,pageInfo:{hasNextPage:false,endCursor:null}}}} : {data:{repository:{pullRequest:node}}}));
`, { mode: 0o755 });
    await writeFile(join(bin, "open"), `#!${process.execPath}
await Bun.write(process.env.RV_TEST_FIXTURE + '/opened.json', JSON.stringify(process.argv.slice(2)));
`, { mode: 0o755 });
    const agent = `#!${process.execPath}
import { writeFile, appendFile, mkdir, rm } from 'node:fs/promises';
import { createInterface } from 'node:readline';
const args = process.argv.slice(2);
const fixture = process.env.RV_TEST_FIXTURE;
await appendFile(fixture + '/agent-calls.jsonl', JSON.stringify({args,cwd:process.cwd()})+'\\n');
if (args[0] === 'app-server') {
  for await (const line of createInterface({input:process.stdin})) {
    const message = JSON.parse(line);
    if (message.id === undefined) continue;
    const path = fixture + '/native-codex.jsonl';
    if (message.method === 'thread/inject_items') await writeFile(path, JSON.stringify(message)+'\\n');
    console.log(JSON.stringify({id:message.id,result:message.method === 'thread/start' ? {thread:{id:'${sessionId}',path}} : {}}));
  }
  process.exit(0);
}
const interactive = args.at(-1)?.includes('Save the complete HTML to exactly:');
if ((args.includes('resume') || args.includes('--resume')) && !interactive) process.exit(0);
const prompt = interactive ? args.at(-1) : await Bun.stdin.text();
const isClaude = process.argv[1].endsWith('claude');
const id = isClaude ? args[args.indexOf('--session-id')+1] : '${sessionId}';
console.log(interactive ? 'NATIVE_CHAT_STARTED' : JSON.stringify(isClaude ? {type:'system',session_id:id} : {type:'thread.started',thread_id:id}));
if (interactive && isClaude) {
  const project = process.env.CLAUDE_CONFIG_DIR + '/projects/demo';
  await mkdir(project, {recursive:true});
  await writeFile(project + '/' + id + '.jsonl', JSON.stringify({type:'assistant',message:{content:[{type:'text',text:'Review written.'}]}}));
}
await Bun.sleep(400);
if (process.env.RV_TEST_FAIL) { console.log(JSON.stringify({type:'turn.failed',error:{message:'test failure'}})); process.exit(1); }
const path = prompt.match(/Save the complete HTML to exactly: (.+)/)[1];
if (interactive) await rm(fixture + '/opened.json', {force:true});
await writeFile(path, '<!doctype html><html><body>Review</body></html>');
console.log(JSON.stringify(isClaude ? {type:'assistant',message:{content:[{type:'text',text:'Review written.'}]}} : {type:'item.completed',item:{type:'agent_message',text:'Review written.'}}));
if (interactive) {
  const deadline = Date.now()+4000;
  while (!await Bun.file(fixture + '/opened.json').exists()) {
    if (Date.now()>deadline) {console.error('HTML was not opened while chat was alive');process.exit(9);}
    await Bun.sleep(25);
  }
  console.log('HTML_OPENED_WHILE_CHAT_ALIVE');
}
`;

    await writeFile(join(bin, "codex"), agent, { mode: 0o755 });
    await writeFile(join(bin, "claude"), agent, { mode: 0o755 });
    await writeJson(agentConfig, { agent: "codex" });
  }, 20000);

  afterAll(async () => {
    await rm(fixture, { recursive: true, force: true });
  });

  test("initialization preserves prompt edits and list keeps approved PRs", async () => {
    expect((await cli(["init"])).code).toBe(0);
    await writeFile(join(root, "prompt.md"), "Custom explanation instructions.");
    await cli(["init"]);
    expect(await readFile(join(root, "prompt.md"), "utf8")).toBe("Custom explanation instructions.");
    const result = await cli(["list"]);
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("#10 — Test review");
    expect(result.stdout).toContain("#10");
    expect(result.stdout).toContain("colleague");
    expect(result.stdout).not.toContain("#12");
    await writeJson(agentConfig, { agent: "codex", codex: { model: "test-model" } });
  });

  test("interactive URL generation reports failure without opening incomplete HTML", async () => {
    const result = await cli([pull.url], { RV_TEST_FAIL: "1" });
    expect(result.code).toBe(1);
    expect(result.stderr).toContain("Generation failed");
    expect(result.stdout).toContain("test failure");
    expect(result.stdout).toContain("NATIVE_CHAT_STARTED");
    expect(await Bun.file(join(fixture, "opened.json")).exists()).toBe(false);
  }, 25000);

  test("URL opens native chat for generation, opens HTML before chat exits, and reuses the saved session", async () => {
    const first = await cli(["https://app.graphite.com/github/pr/acme/demo/10"]);
    expect(first.code).toBe(0);
    expect(first.stdout).toContain("Opening codex chat for acme/demo#10");
    expect(first.stdout).toContain("NATIVE_CHAT_STARTED");
    expect(first.stdout).toContain("HTML_OPENED_WHILE_CHAT_ALIVE");
    const review = await finished();
    const dir = join(root, "acme/demo/pr-10");
    expect(JSON.parse(await readFile(join(fixture, "opened.json"), "utf8"))).toEqual([join(dir, "diff.html")]);
    const calls = (await readFile(join(fixture, "agent-calls.jsonl"), "utf8")).trim().split("\n").map((line) => JSON.parse(line));
    expect(calls.at(-1).args.slice(0, 6)).toEqual(["resume", "--include-non-interactive", "--dangerously-bypass-approvals-and-sandbox", "--model", "test-model", sessionId]);
    expect(calls.at(-1).args.at(-1)).toContain("Custom explanation instructions.");
    expect(review.run?.mode).toBe("interactive");
    expect(await Bun.file(join(dir, "runs", review.run!.id, "native.jsonl")).exists()).toBe(true);
    expect(calls.at(-1).cwd).toBe(await command(["pwd", "-P"], join(dir, "worktree"), env));

    const again = await cli([pull.url], { RV_TEST_OFFLINE: "1" });
    expect(again.code).toBe(0);
    expect(again.stdout).not.toContain("Generating");
    expect((await readJson<Review>(join(dir, "review.json")))?.run?.id).toBe(review.run!.id);
  }, 25000);

  test("quiet live workers stall, fall back to saved HTML, and recover when output resumes", async () => {
    const dir = join(root, "acme/demo/pr-10");
    const previous = await readJson<Review>(join(dir, "review.json"));
    const config = await readFile(join(root, "config.json"), "utf8");
    const old = new Date(Date.now() - 20 * 60000).toISOString();
    const review: Review = {
      ...previous!, run: { ...previous!.run!, id: "test-stalled", nativeLog: undefined, status: "running", pid: process.pid, startedAt: old, lastActivityAt: old },
    };
    const runDir = join(dir, "runs", review.run!.id);
    await mkdir(runDir);
    try {
      await writeJson(join(dir, "review.json"), review);
      await writeFile(join(dir, "generation.lock"), String(process.pid));
      expect((await generationActivity(root, review)).state).toBe("stalled");
      expect(await dashboard(root, false)).toContain("Open (stalled)");
      const status = await cli(["status", "10"]);
      expect(status.stdout).toContain("Last activity:");
      expect(status.stdout).toContain("Stalled:");
      const opened = await cli([pull.url]);
      expect(opened.code).toBe(0);
      expect(opened.stdout).toContain("Generation is stalled");
      expect(opened.stdout).not.toContain("Waiting");
      expect(opened.stdout).toContain("Resuming");
      expect((await cli(["generate", "10"])).code).toBe(1);
      expect((await readJson<Review>(join(dir, "review.json")))?.run?.id).toBe("test-stalled");

      await rename(join(dir, "diff.html"), join(dir, "previous.html"));
      try {
        expect(await dashboard(root, false)).toContain("Stalled");
        const missing = await cli([pull.url]);
        expect(missing.code).toBe(1);
        expect(missing.stderr).toContain("No previous HTML is available");
      } finally {
        await rename(join(dir, "previous.html"), join(dir, "diff.html"));
      }

      await writeJson(join(root, "config.json"), { stallMinutes: 30 });
      expect((await generationActivity(root, review)).state).toBe("running");
      await writeFile(join(root, "config.json"), config);
      for (const name of ["events.jsonl", "worker.log", "chat.md", "run.json"]) {
        await writeFile(join(runDir, name), "progress");
        expect((await generationActivity(root, review)).state).toBe("running");
        await rm(join(runDir, name));
      }
      expect((await generationActivity(root, review)).state).toBe("stalled");

      const recent = new Date().toISOString();
      review.run!.startedAt = recent;
      review.run!.lastActivityAt = recent;
      await writeJson(join(root, "config.json"), { stallMinutes: 0.01 });
      await writeJson(join(dir, "review.json"), review);
      const waiting = await cli([pull.url]);
      expect(waiting.code).toBe(0);
      expect(waiting.stdout).toContain("Another generation is already running");
      expect(waiting.stdout).toContain("Generation is stalled");
      expect(waiting.stdout).toContain("Opening the previous successful review");
    } finally {
      await writeJson(join(dir, "review.json"), previous);
      await writeFile(join(root, "config.json"), config);
      await rm(join(dir, "generation.lock"), { force: true });
      await rm(runDir, { recursive: true, force: true });
    }
  }, 10000);

  test("URL waits for an existing generation when HTML is missing", async () => {
    const dir = join(root, "acme/demo/pr-10");
    await rm(join(dir, "diff.html"));
    expect((await cli(["generate", "10"])).code).toBe(0);
    const started = await readJson<Review>(join(dir, "review.json"));
    const waiting = await cli([pull.url]);
    expect(waiting.code).toBe(0);
    expect(waiting.stdout).toContain("Another generation is already running");
    const completed = await readJson<Review>(join(dir, "review.json"));
    expect(completed?.run?.id).toBe(started?.run?.id);
    expect(completed?.run?.status).toBe("complete");
  }, 25000);

  test("URL waits for regeneration even with an existing HTML file", async () => {
    const dir = join(root, "acme/demo/pr-10");
    expect((await cli(["generate", "10"])).code).toBe(0);
    const started = await readJson<Review>(join(dir, "review.json"));
    const waiting = await cli([pull.url]);
    expect(waiting.code).toBe(0);
    expect(waiting.stdout).toContain("Another generation is already running");
    const completed = await readJson<Review>(join(dir, "review.json"));
    expect(completed?.run?.id).toBe(started?.run?.id);
    expect(completed?.run?.status).toBe("complete");
  }, 25000);

  test("URL falls back to previous HTML if the generation it waits on fails", async () => {
    const dir = join(root, "acme/demo/pr-10");
    const htmlBefore = await readJson<{ runId: string }>(join(dir, "html.json"));
    expect((await cli(["generate", "10"], { RV_TEST_FAIL: "1" })).code).toBe(0);
    const waiting = await cli([pull.url]);
    expect(waiting.code).toBe(0);
    expect(waiting.stdout).toContain("Another generation is already running");
    expect(waiting.stdout).toContain("Opening the previous successful review");
    expect(await readJson<{ runId: string }>(join(dir, "html.json"))).toEqual(htmlBefore);
    expect(JSON.parse(await readFile(join(fixture, "opened.json"), "utf8"))).toEqual([join(dir, "diff.html")]);
  }, 25000);

  test("stale running metadata opens the previous review without starting or waiting", async () => {
    const dir = join(root, "acme/demo/pr-10");
    const previous = await readJson<Review>(join(dir, "review.json"));
    const deadPid = Number(await command([process.execPath, "-e", "console.log(process.pid)"]));
    await writeJson(join(dir, "review.json"), {
      ...previous, run: { ...previous!.run!, status: "running", pid: deadPid },
    });
    await writeFile(join(dir, "generation.lock"), String(deadPid));
    const opened = await cli([pull.url]);
    expect(opened.code).toBe(0);
    expect(opened.stdout).not.toContain("Waiting");
    expect(opened.stdout).not.toContain("Generating");
    expect(opened.stdout).toContain("Resuming");
    expect((await readJson<Review>(join(dir, "review.json")))?.run?.id).toBe(previous!.run!.id);
  });

  test("dead workers and abandoned empty locks allow a fresh generation", async () => {
    const dir = join(root, "acme/demo/pr-10");
    const previous = await readJson<Review>(join(dir, "review.json"));
    const deadPid = Number(await command([process.execPath, "-e", "console.log(process.pid)"]));
    await writeJson(join(dir, "review.json"), {
      ...previous, run: { ...previous!.run!, status: "running", pid: deadPid },
    });
    await writeFile(join(dir, "generation.lock"), String(deadPid));
    await rm(join(dir, "diff.html"));
    expect(await dashboard(root, false)).toContain("Failed");
    expect((await cli([pull.url])).code).toBe(0);
    expect((await readJson<Review>(join(dir, "review.json")))?.run?.id).not.toBe(previous!.run!.id);

    await writeFile(join(dir, "generation.lock"), "");
    const stale = new Date(Date.now() - 60000);
    await utimes(join(dir, "generation.lock"), stale, stale);
    const before = await readJson<Review>(join(dir, "review.json"));
    expect((await cli(["generate", "10"])).code).toBe(0);
    expect((await finished(before!.run!.id)).run?.status).toBe("complete");
  }, 25000);

  test("dashboard links PRs and HTML, reports reviews, and falls back offline", async () => {
    const linked = await dashboard(root, true);
    expect(linked).toContain(`\x1b]8;;${pull.url}\x1b\\\x1b[36;4m#10 — Test review\x1b[0m`);
    expect(linked).toContain("\x1b[36;4m📄 Open\x1b[0m");
    expect(linked).toContain("file://");
    expect(linked).toContain("diff.html");
    expect(linked).toContain("colleague");
    expect(linked).not.toContain("bots");
    expect(linked).not.toContain("commented");
    const result = await cli(["dashboard"], { RV_TEST_OFFLINE: "1" });
    expect(result.code).toBe(0);
    expect(result.stderr).toContain("GitHub unavailable");
    expect(result.stdout.split("\n")[0].trim().split(/\s+/)).toEqual(["Created", "PR", "Author", "HTML", "Approvals"]);
    expect(result.stdout).toContain("Created");
    expect(result.stdout).toContain("2d ago");
    expect(result.stdout).not.toContain("acme/");
    expect(result.stdout).toContain("#10");
    expect(result.stdout).not.toContain("\x1b");
  });

  test("generation persists worktree, HTML, model, events, and exact resumable chat", async () => {
    const first = await cli(["generate", "10"]);
    expect(first.code).toBe(0);
    const duplicate = await cli(["generate", "10"]);
    expect(duplicate.code).toBe(1);
    const review = await finished();
    expect(review.run?.error).toBeNull();
    expect(review.run?.status).toBe("complete");
    expect(review.run?.sessionId).toBe(sessionId);
    expect(review.run?.model).toBe("test-model");
    const dir = join(root, "acme/demo/pr-10");
    expect(await readFile(join(dir, "diff.html"), "utf8")).toContain("<html>");
    expect(await readFile(join(dir, "runs", review.run!.id, "chat.md"), "utf8")).toContain("Review written.");
    expect(await command(["git", "rev-parse", "HEAD"], join(dir, "worktree"), env)).toBe(sha);
    expect((await cli(["chat", "10"])).code).toBe(0);
    const calls = (await readFile(join(fixture, "agent-calls.jsonl"), "utf8")).trim().split("\n").map((line) => JSON.parse(line));
    expect(calls.at(-1).args).toEqual(["resume", "--include-non-interactive", sessionId]);
    expect(calls.at(-1).cwd).toBe(await command(["pwd", "-P"], join(dir, "worktree"), env));
  }, 25000);

  test("failed regeneration keeps the earlier HTML and generation history", async () => {
    const previous = await readJson<Review>(join(root, "acme/demo/pr-10/review.json"));
    expect((await cli(["generate", "10"], { RV_TEST_FAIL: "1" })).code).toBe(0);
    const review = await finished(previous!.run!.id);
    expect(review.run?.status).toBe("failed");
    expect(review.run?.error).toContain("test failure");
    expect(await readFile(join(root, "acme/demo/pr-10/diff.html"), "utf8")).toContain("<html>");
    const reopened = await cli([pull.url]);
    expect(reopened.code).toBe(0);
    expect(reopened.stdout).not.toContain("Generating");
    const status = await indicators(root, { ...pull, sha }, review);
    expect(status.html).toBe("err+old");
    expect(await readFile(join(root, "acme/demo/pr-10/runs", previous!.run!.id, "run.json"), "utf8")).toContain('"complete"');
  }, 25000);

  test("Claude generation records its own session and resumes with the right CLI", async () => {
    await writeJson(agentConfig, { agent: "claude", claude: { model: "test-claude", fast: true } });
    const previous = await readJson<Review>(join(root, "acme/demo/pr-10/review.json"));
    expect((await cli(["generate", "10"])).code).toBe(0);
    const review = await finished(previous!.run!.id);
    expect(review.run?.error).toBeNull();
    expect(review.run?.agent).toBe("claude");
    expect(review.run?.sessionId).toMatch(/^[0-9a-f-]{36}$/);
    const chats = await readJson<Record<string, { url: string; number: number; agent: string }>>(join(fixture, "kitty-agents", "reviews.json"));
    expect(chats?.[review.run!.sessionId!]).toMatchObject({ url: pull.url, number: 10, agent: "claude" });
    expect((await cli(["chat", "10"])).code).toBe(0);
    const calls = (await readFile(join(fixture, "agent-calls.jsonl"), "utf8")).trim().split("\n").map((line) => JSON.parse(line));
    expect(calls.at(-1).args.slice(0, 3)).toEqual(["--dangerously-skip-permissions", "--resume", review.run!.sessionId]);
    expect(calls.at(-1).args).toContain("test-claude");
    expect(calls.at(-1).args).toContain(JSON.stringify({ fastMode: true }));
    expect(calls.at(-1).args.join(" ")).not.toContain("This entire conversation is a pull request review");
  }, 25000);

  test("Claude URL opens the native chat with a saved session ID", async () => {
    const dir = join(root, "acme/demo/pr-10");
    await rm(join(dir, "diff.html"));
    const result = await cli([pull.url]);
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("Opening claude chat");
    expect(result.stdout).toContain("HTML_OPENED_WHILE_CHAT_ALIVE");
    const review = await readJson<Review>(join(dir, "review.json"));
    const calls = (await readFile(join(fixture, "agent-calls.jsonl"), "utf8")).trim().split("\n").map((line) => JSON.parse(line));
    expect(calls.at(-1).args.slice(0, 5)).toEqual(["--dangerously-skip-permissions", "--session-id", review!.run!.sessionId, "--model", "test-claude"]);
    expect(review?.run?.mode).toBe("interactive");
    expect(await Bun.file(join(dir, "runs", review!.run!.id, "native.jsonl")).exists()).toBe(true);
  }, 25000);

  test("tracked worktree edits block regeneration and remain intact", async () => {
    const dir = join(root, "acme/demo/pr-10");
    const tracked = await command(["git", "ls-files", "scripts/greview"], join(dir, "worktree"), env);
    const path = join(dir, "worktree", tracked);
    const original = await readFile(path, "utf8");
    await writeFile(path, `${original}\n// test local change\n`);
    const previous = await readJson<Review>(join(dir, "review.json"));
    expect((await cli(["generate", "10"])).code).toBe(0);
    const review = await finished(previous!.run!.id);
    expect(review.run?.status).toBe("failed");
    expect(review.run?.error).toContain("Save your tracked changes");
    expect(await readFile(path, "utf8")).toContain("test local change");
    expect((await cli([pull.url])).code).toBe(0);
    const calls = (await readFile(join(fixture, "agent-calls.jsonl"), "utf8")).trim().split("\n").map((line) => JSON.parse(line));
    expect(calls.at(-1).args.slice(0, 3)).toEqual(["--dangerously-skip-permissions", "--resume", previous!.run!.sessionId]);
    expect(calls.at(-1).args.join(" ")).not.toContain("Do not implement the suggested changes");
  }, 25000);

  test("bare PR numbers fail clearly when repositories collide", async () => {
    const other = { ...pull, repo: "other/demo" };
    const dir = join(root, "other/demo/pr-10");
    await mkdir(dir, { recursive: true });
    await writeJson(join(dir, "review.json"), { pull: other, run: null, checkoutSha: null });
    await expect(resolvePull(root, "10")).rejects.toThrow("ambiguous");
  });
});

test("creation date limits the dashboard while older saved reviews remain addressable", async () => {
  const root = await mkdtemp(join(tmpdir(), "rv-week-"));
  try {
    const old = { ...pull, number: 11, createdAt: "2020-01-01T00:00:00.000Z", updatedAt: new Date().toISOString() };
    await writeJson(join(root, "pulls.json"), {
      viewer: "me", fetchedAt: new Date().toISOString(), pulls: [pull, old],
    });
    expect((await allPulls(root)).pulls.map((item) => item.number)).toEqual([10]);
    await mkdir(join(root, "acme/demo/pr-11"), { recursive: true });
    await writeJson(join(root, "acme/demo/pr-11/review.json"), { pull: old, run: null, checkoutSha: null });
    expect((await allPulls(root)).pulls.map((item) => item.number)).toEqual([11, 10]);
    const table = await dashboard(root, false);
    expect(table).toContain("#10");
    expect(table).not.toContain("#11");
    expect(table).toContain("1 PRs | created in the last 7 days");
    expect((await resolvePull(root, "11")).number).toBe(11);
    expect(weekAgo(Date.parse("2026-09-22T12:00:00Z"))).toBe("2026-09-15T12:00:00.000Z");
    expect(daysAgo(14, Date.parse("2026-09-22T12:00:00Z"))).toBe("2026-09-08T12:00:00.000Z");
    const args = ["dashboard", "--days", "14"];
    expect(takeDays(args)).toBe(14);
    expect(args).toEqual(["dashboard"]);
    expect(takeDays(["dashboard"])).toBe(7);
    expect(() => takeDays(["--days", "0"])).toThrow("positive whole number");
    expect(() => takeDays(["--days"])).toThrow("got nothing");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("dashboard shows only open PRs, including when cached merges are recent", async () => {
  const root = await mkdtemp(join(tmpdir(), "rv-merged-"));
  try {
    const now = Date.now();
    const pulls = [
      pull,
      { ...pull, number: 11, state: "MERGED", mergedAt: new Date(now - 47 * 3600000).toISOString() },
      { ...pull, number: 12, state: "MERGED", mergedAt: new Date(now - 49 * 3600000).toISOString(), updatedAt: new Date(now).toISOString() },
      { ...pull, number: 13, state: "CLOSED" },
      { ...pull, number: 14, state: "MERGED" },
      { ...pull, number: 15, state: "MERGED", mergedAt: new Date(now).toISOString(), createdAt: "2020-01-01T00:00:00Z" },
    ];
    await writeJson(join(root, "pulls.json"), { viewer: "me", fetchedAt: new Date(now).toISOString(), pulls });
    const table = await dashboard(root, false);
    expect([...table.matchAll(/#(\d+)/g)].map((match) => Number(match[1]))).toEqual([10]);
    expect(table).not.toContain("⑂");
    expect(table).not.toContain("48h");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("dashboard lists human approvers with my username first", async () => {
  const root = await mkdtemp(join(tmpdir(), "rv-approvers-"));
  try {
    const reviewers = [
      { login: "colleague", state: "APPROVED", bot: false },
      { login: "me", state: "APPROVED", bot: false },
      { login: "another-reviewer", state: "APPROVED", bot: false },
      { login: "robot", state: "APPROVED", bot: true },
      { login: "author", state: "APPROVED", bot: false },
      { login: "commenter", state: "COMMENTED", bot: false },
      { login: "dismissed", state: "DISMISSED", bot: false },
      { login: "requester", state: "CHANGES_REQUESTED", bot: false },
    ];
    await writeJson(join(root, "pulls.json"), {
      viewer: "me", fetchedAt: new Date().toISOString(), pulls: [{ ...pull, reviewers }],
    });
    const table = await dashboard(root, false);
    expect(table.split("\n")[0].trimEnd()).toEndWith("Approvals");
    expect(table.split("\n")[2].trimEnd()).toEndWith("✅ me, colleague, another-reviewer");
    expect(table).not.toContain("robot");
    expect(table).not.toContain("commenter");
    expect(table).not.toContain("dismissed");
    expect(table).not.toContain("requester");

    await writeJson(join(root, "pulls.json"), {
      viewer: "me", fetchedAt: new Date().toISOString(),
      pulls: [{ ...pull, reviewers: reviewers.map((person) => ({ ...person, state: "DISMISSED" })) }],
    });
    const dismissed = await dashboard(root, false);
    expect(dismissed).not.toContain("me,");
    expect(dismissed).not.toContain("colleague");
    expect(dismissed.split("\n")[2].trimEnd()).toEndWith("—");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("dashboard clips long Unicode titles and keeps table columns aligned", async () => {
  const root = await mkdtemp(join(tmpdir(), "rv-table-"));
  try {
    await writeJson(join(root, "pulls.json"), {
      viewer: "me", fetchedAt: new Date().toISOString(), pulls: [{ ...pull, title: "界👩‍💻".repeat(40) }],
    });
    const table = await dashboard(root, false);
    expect(table).toContain("...");
    const lines = table.split("\n").slice(0, 3);
    const widths = lines.map((line) => Bun.stringWidth(line));
    expect(new Set(widths).size).toBe(1);
    expect(table).not.toContain("\x1b");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});


test("dashboard orders PRs by creation date across repositories, newest first", async () => {
  const root = await mkdtemp(join(tmpdir(), "rv-order-"));
  try {
    const now = Date.now();
    const pulls = [
      { ...pull, repo: "acme/aaa", number: 101, createdAt: new Date(now - 3 * 86400000).toISOString() },
      { ...pull, repo: "acme/zzz", number: 102, createdAt: new Date(now - 86400000).toISOString() },
      { ...pull, repo: "acme/aaa", number: 103, createdAt: new Date(now - 2 * 86400000).toISOString() },
    ];
    await writeJson(join(root, "pulls.json"), { viewer: "me", fetchedAt: new Date().toISOString(), pulls });
    const table = await dashboard(root, false);
    expect([...table.matchAll(/#(\d+)/g)].map((match) => Number(match[1]))).toEqual([102, 103, 101]);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
