import { stat } from "node:fs/promises";
import { join } from "node:path";
import { busy, directory, readJson, stallMinutes, type Review, type Settings } from "./store";

export type GenerationActivity =
  | { state: "idle" | "stopped" }
  | { state: "running" | "stalled"; lastActivityAt: string; idleMs: number; stallMinutes: number };

export async function generationActivity(root: string, review: Review, now = Date.now()): Promise<GenerationActivity> {
  const run = review.run;
  if (!run || !["queued", "running"].includes(run.status)) {
    return { state: "idle" };
  }
  if (!busy(run)) {
    return { state: "stopped" };
  }

  const config = await readJson<Settings>(join(root, "config.json"));
  const minutes = stallMinutes(config);
  const runDir = join(directory(root, review.pull), "runs", run.id);
  // Output files cover both agents and workers already running when rv is updated.
  // run.json changes at setup/session transitions; no heartbeat refreshes this clock.
  const paths = ["events.jsonl", "worker.log", "chat.md", "run.json"].map((name) => join(runDir, name));
  if (run.nativeLog) {
    paths.push(run.nativeLog);
  }
  const modified = await Promise.all(paths.map(async (path) => {
    try {
      return (await stat(path)).mtimeMs;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return 0;
      }
      throw new Error(`Cannot check generation activity (${path}): ${error}`);
    }
  }));
  const recorded = [run.lastActivityAt, run.startedAt].map((value) => Date.parse(value ?? "")).filter(Number.isFinite);
  const lastActivity = Math.max(0, ...modified, ...recorded);
  const idleMs = Math.max(0, now - lastActivity);

  return {
    state: idleMs >= minutes * 60000 ? "stalled" : "running",
    lastActivityAt: new Date(lastActivity).toISOString(), idleMs, stallMinutes: minutes,
  };
}
