import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { type Run } from "./store";
import { claudeFlags, codexFlags } from "../agent-lib/agent";

export async function createCodexChat(cwd: string, model: string | null, target: string): Promise<{ id: string; path: string }> {
  const child = spawn("codex", ["app-server"], { cwd, stdio: ["pipe", "pipe", "pipe"] });
  const lines = createInterface({ input: child.stdout! });
  let stderr = "";
  let spawnError: Error | null = null;
  let timedOut = false;
  child.stderr!.on("data", (data) => { stderr = (stderr + data.toString()).slice(-8000); });
  child.on("error", (error) => { spawnError = error; lines.close(); });
  child.stdin!.on("error", (error) => { spawnError = error; });
  const exited = new Promise<void>((resolve) => child.once("close", () => resolve()));
  const timer = setTimeout(() => { timedOut = true; child.kill("SIGKILL"); }, 15000);
  const send = (message: object) => child.stdin!.write(`${JSON.stringify(message)}\n`);
  let thread: { id: string; path: string } | null = null;

  try {
    send({ id: 0, method: "initialize", params: {
      clientInfo: { name: "rv", title: "Review", version: "1" },
      capabilities: { experimentalApi: true },
    } });
    for await (const line of lines) {
      const message = JSON.parse(line);
      if (message.error) {
        throw new Error(JSON.stringify(message.error));
      }
      switch (message.id) {
        case 0:
          send({ method: "initialized" });
          send({ id: 1, method: "thread/start", params: {
            cwd, model, ephemeral: false, approvalPolicy: "never", sandbox: "danger-full-access",
          } });
          break;
        case 1: {
          const value = message.result?.thread;
          if (!value?.id || !value.path) {
            throw new Error("Codex did not return a saved thread ID and path.");
          }
          thread = { id: value.id, path: value.path };
          // A first history item makes an empty thread durable without starting a model turn.
          send({ id: 2, method: "thread/inject_items", params: {
            threadId: thread.id,
            items: [{ type: "message", role: "user", content: [{
              type: "input_text", text: `This is the review chat for ${target}. The next message contains the review instructions.`,
            }] }],
          } });
          break;
        }
        case 2:
          if (!thread) {
            throw new Error("Codex did not create the review chat.");
          }
          return thread;
      }
    }
    throw new Error(timedOut ? "Codex chat setup timed out." : String(spawnError ?? (stderr || "Codex stopped during chat setup.")));
  } catch (error) {
    throw new Error(`Could not create the Codex review chat: ${error}`);
  } finally {
    lines.close();
    child.stdin!.end();
    // Keep the deadline armed while waiting for app-server shutdown.
    await exited;
    clearTimeout(timer);
  }
}

export function nativeChatCommand(run: Run, prompt: string): string[] {
  if (!run.sessionId) {
    throw new Error("Create a saved session before opening the chat.");
  }
  return run.agent === "codex"
    ? ["codex", "resume", "--include-non-interactive", "--dangerously-bypass-approvals-and-sandbox", ...codexFlags(run), run.sessionId, prompt]
    : ["claude", "--dangerously-skip-permissions", "--session-id", run.sessionId, ...claudeFlags(run), prompt];
}

export async function claudeTranscript(sessionId: string): Promise<string | null> {
  const root = process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude");
  try {
    const matches = await Array.fromAsync(new Bun.Glob(`projects/*/${sessionId}.jsonl`).scan({ cwd: root, absolute: true }));
    return matches[0] ?? null;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw new Error(`Cannot locate Claude transcript for ${sessionId}: ${error}`);
  }
}
