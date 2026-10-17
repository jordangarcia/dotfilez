import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { allPulls, command } from "./github";
import { generationActivity, type GenerationActivity } from "./activity";
import { loadReview, runDirectory, startReview } from "./runner";
import { busy, directory, initialize, key, plain, readJson, type Pull, type Review, type Run } from "./store";
import { agentConfigPath, claudeFlags } from "../agent-lib/agent";

export function others(pull: Pull, viewer: string) {
  return pull.reviewers.filter((reviewer) => !reviewer.bot && reviewer.login !== viewer && reviewer.login !== pull.author);
}

export async function indicators(root: string, pull: Pull, review: Review): Promise<{ chat: string; html: string; activity: GenerationActivity }> {
  const dir = directory(root, pull);
  const html = await readJson<{ headSha: string }>(join(dir, "html.json"));
  const ready = existsSync(join(dir, "diff.html"));
  const run = review.run;
  const activity = await generationActivity(root, review);
  const active = activity.state === "running";
  const stalled = activity.state === "stalled";
  const failed = run && (run.status === "failed" || activity.state === "stopped");

  return {
    chat: run?.sessionId ? (stalled ? "stalled" : active ? "live" : "yes") : "-",
    html: stalled ? (ready ? "stall+old" : "stalled") : active ? (ready ? "run+old" : "running") : failed ? (ready ? "err+old" : "error") : ready ? (html?.headSha === pull.sha ? "ready" : "stale") : "-",
    activity,
  };
}

export async function preview(root: string, target: string, directPull?: Pull): Promise<string> {
  const { cache, pulls } = await allPulls(root);
  const pull = directPull ?? pulls.find((item) => key(item) === target);
  if (!pull) {
    return "Pass a PR number or URL.";
  }
  const review = await loadReview(root, pull);
  const status = await indicators(root, pull, review);
  const people = others(pull, cache?.viewer ?? "");
  const reviewers = people.map((person) => `  ${person.login}: ${person.state.toLowerCase().replaceAll("_", " ")}`);
  const botCount = pull.reviewers.filter((person) => person.bot).length;
  const lines = [
    `${key(pull)}  ${pull.state}`, pull.title, `Author: ${pull.author}`, pull.url, "",
    `GitHub decision: ${pull.decision ?? "none"}`,
    "Other reviewers:", ...(reviewers.length ? reviewers : ["  No submitted human reviews"]),
    ...(botCount ? [`  ${botCount} bot review(s)`] : []), "",
    `Chat: ${status.chat}   HTML: ${status.html}`, `Folder: ${directory(root, pull)}`,
  ];
  if (review.run) {
    const run = review.run;
    lines.push(`Agent: ${run.agent} / ${run.model ?? "CLI default"}`, `Run: ${run.id}`, `Commit: ${run.headSha}`);
    if (run.sessionId) {
      lines.push(`Chat ID: ${run.sessionId}`);
    }
    if (run.error) {
      lines.push(`Error: ${run.error}`);
    }
    if (status.html.startsWith("err") && !run.error) {
      lines.push("Worker stopped before completing. Generate again to retry.");
    }
    if (status.activity.state === "stalled" || status.activity.state === "running") {
      lines.push(`Last activity: ${status.activity.lastActivityAt} (${Math.floor(status.activity.idleMs / 60000)}m ago)`);
    }
    if (status.activity.state === "stalled") {
      lines.push(`Stalled: no output or setup activity for ${status.activity.stallMinutes} minutes. Worker PID ${run.pid} is still alive.`);
    } else if (busy(run)) {
      lines.push("Generation is running. Chat opens its live transcript.");
    }
  }
  lines.push("", "Description", "───────────", ...pull.body.split("\n"));

  return lines.map(plain).join("\n");
}

async function interactive(args: string[], cwd?: string): Promise<void> {
  const child = spawn(args[0], args.slice(1), { cwd, stdio: "inherit" });
  const code = await new Promise<number | null>((resolve, reject) => {
    child.once("error", reject);
    child.once("exit", resolve);
  });
  if (code !== 0) {
    throw new Error(`${args[0]} exited ${code}`);
  }
}

export async function perform(root: string, action: string, pull: Pull | null, script: string): Promise<string> {
  if (action === "config") {
    await interactive(["nvim", agentConfigPath(), join(root, "config.json"), join(root, "prompt.md")]);
    await initialize(root);
    return "Configuration saved.";
  }
  if (!pull) {
    throw new Error("Select a PR first.");
  }
  const dir = directory(root, pull);
  const review = await loadReview(root, pull);
  switch (action) {
    case "generate":
      await startReview(root, pull, script);
      return `Generating ${key(pull)} in the background.`;
    case "html": {
      const path = join(dir, "diff.html");
      if (!existsSync(path)) {
        throw new Error(busy(review.run) ? "HTML is still being generated." : "No HTML yet. Run rv with the PR URL to generate it.");
      }
      await command(["open", path]);
      return `Opened ${key(pull)} HTML.`;
    }
    case "github":
      await command(["open", pull.url]);
      return "Opened GitHub.";
    case "edit": {
      const path = join(dir, "worktree");
      if (!existsSync(join(path, ".git"))) {
        throw new Error("No worktree yet. Generate a review first.");
      }
      await interactive(["nvim", "."], path);
      return "Returned from Neovim.";
    }
    case "chat": {
      const run = review.run;
      if (!run) {
        throw new Error("No chat yet. Generate a review first.");
      }
      if (busy(run)) {
        const path = join(runDirectory(root, review), "chat.md");
        if (!existsSync(path)) {
          throw new Error("The worktree is being prepared; the chat has not started yet.");
        }
        console.log("Live generation transcript. Ctrl-C stops following; q returns to rv.");
        await interactive(["less", "+F", path]);
      } else {
        await resumeChat(root, pull, run);
      }
      return "Returned from chat.";
    }
    default:
      throw new Error(`Unknown action: ${action}`);
  }
}

async function resumeChat(root: string, pull: Pull, run: Run): Promise<void> {
  if (!run.sessionId) {
    throw new Error("The agent did not create a chat. Check rv status and worker.log.");
  }
  // The generation prompt opens every chat with REVIEW_SCOPE, so resuming sends nothing
  // and the chat waits for the next message.
  const args = run.agent === "codex"
    ? ["codex", "resume", "--include-non-interactive", run.sessionId]
    : ["claude", "--dangerously-skip-permissions", "--resume", run.sessionId, ...claudeFlags(run)];
  const cwd = join(directory(root, pull), "worktree");
  console.log(`Resuming ${key(pull)} in ${cwd}`);
  await interactive(args, cwd);
}

export async function openReview(root: string, pull: Pull, script: string): Promise<void> {
  const dir = directory(root, pull);
  const htmlPath = join(dir, "diff.html");
  let review = await loadReview(root, pull);
  const initialActivity = await generationActivity(root, review);
  const stalled = initialActivity.state === "stalled";
  const active = initialActivity.state === "running";
  if (stalled) {
    const message = `Generation is stalled: no activity for ${Math.floor(initialActivity.idleMs / 60000)}m (PID ${review.run!.pid}). The worker is still alive.`;
    if (!existsSync(htmlPath)) {
      throw new Error(`${message} No previous HTML is available. Inspect rv status ${key(pull)}; generation continues in the background.`);
    }
    console.log(`${message} Opening the previous successful review.`);
  }
  if (active || (!existsSync(htmlPath) && !stalled)) {
    if (active) {
      console.log(`Another generation is already running for ${key(pull)} (PID ${review.run!.pid}). Waiting for it to finish.`);
    } else {
      await startReview(root, pull, script, true);
      return;
    }
    console.log("Ctrl-C stops waiting and leaves generation running.");
    while (true) {
      review = await loadReview(root, pull);
      if (review.run?.status === "complete") {
        break;
      }
      const activity = await generationActivity(root, review);
      if (activity.state === "stalled") {
        const message = `Generation is stalled: no activity for ${Math.floor(activity.idleMs / 60000)}m (PID ${review.run!.pid}). The worker is still alive.`;
        if (!existsSync(htmlPath)) {
          throw new Error(`${message} No previous HTML is available. Inspect rv status ${key(pull)}; generation continues in the background.`);
        }
        console.log(`${message} Opening the previous successful review.`);
        break;
      }
      if (!busy(review.run)) {
        if (existsSync(htmlPath)) {
          console.log(`Generation stopped (${review.run?.error ?? "worker exited"}). Opening the previous successful review.`);
          break;
        }
        throw new Error(`Generation failed: ${review.run?.error ?? "worker stopped"}. See rv status ${key(pull)}.`);
      }
      await Bun.sleep(300);
    }
  }
  if (!existsSync(htmlPath)) {
    throw new Error(`Generation completed without HTML at ${htmlPath}. Run rv generate ${key(pull)} to retry.`);
  }

  // The HTML metadata identifies its chat even when a later generation fails.
  const html = await readJson<{ runId: string }>(join(dir, "html.json"));
  const run = html?.runId
    ? await readJson<Run>(join(dir, "runs", html.runId, "run.json"))
    : review.run;
  await command(["open", htmlPath]);
  if (!run) {
    throw new Error("Opened the HTML, but its saved chat metadata is missing.");
  }
  await resumeChat(root, pull, run);
}
