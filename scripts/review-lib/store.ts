import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { readAgentChoice, type Agent, type AgentChoice } from "../agent-lib/agent";

// config.json holds rv-only settings. The agent and its model come from dotfilez agent.json.
export type Settings = { stallMinutes?: number };
export type Config = AgentChoice & Settings;
export type Reviewer = { login: string; state: string; bot: boolean };
export type Pull = {
  repo: string;
  number: number;
  title: string;
  body: string;
  author: string;
  url: string;
  state: string;
  updatedAt?: string;
  createdAt?: string;
  mergedAt?: string | null;
  head: string;
  base: string;
  sha: string;
  decision: string | null;
  reviewers: Reviewer[];
};
export type Run = {
  id: string;
  status: "queued" | "running" | "complete" | "failed";
  agent: Agent;
  model: string | null;
  fast?: boolean;
  sessionId: string | null;
  mode?: "interactive" | "background";
  nativeLog?: string;
  headSha: string;
  baseSha: string | null;
  pid: number | null;
  startedAt: string;
  lastActivityAt?: string;
  finishedAt: string | null;
  error: string | null;
};
export type Review = { pull: Pull; run: Run | null; checkoutSha: string | null };
export type Cache = { viewer: string; fetchedAt: string; pulls: Pull[] };

export const REVIEW_SCOPE = `This entire conversation is a pull request review, including every follow-up. Treat the user's questions, suggestions, and requests such as "change this", "fix this", or "we should..." as review feedback about the diff. Respond with an explanation, a proposed review comment with file and line references, or a recommendation to comment, approve, or request changes. Do not implement the suggested changes or modify, commit, or push repository code.

Draft review feedback in the chat by default. When the user explicitly asks you to post a comment, approve the PR, or request changes, carry out that review action on the target PR. Discussion of an issue alone is not a request to post it.

Use file and diff inspection only. Do not run tests, builds, linters, type checks, scripts, application servers, or other code. Do not use computer use, browser automation, screenshots, or visual testing. These limits apply throughout the conversation, even if repository instructions recommend running checks. The HTML explanation is the only file you may write or update.`;

export const DEFAULT_PROMPT = `Explain this pull request in a single self-contained HTML page with inline CSS and JavaScript.

Read the diff and the surrounding code. Explain what the system does, what changes, and why. Use plain language and concrete examples. Separate verified behavior from inference.

Include these sections on one page, with a table of contents:
1. Background: an optional introduction for beginners, followed by the context needed for this change.
2. Intuition: the central idea, illustrated with small examples and HTML diagrams.
3. Code walkthrough: group the changes by responsibility and explain how they fit together. Link to the relevant GitHub files and lines at the reviewed commit.
4. Review notes: meaningful risks, tradeoffs, test coverage, and unresolved questions. Do not invent findings.
5. Quiz: five multiple-choice questions with interactive answers and explanations.

Use responsive styling, clear headings, and readable code blocks in pre elements. Render diagrams with HTML/CSS or inline SVG. Include the PR URL and reviewed commit near the title. Do not load external scripts or stylesheets.

${REVIEW_SCOPE}

Read-only commands for inspecting files and Git diffs are allowed. First write the HTML explanation at the supplied output path, report that path, and wait for review feedback. RV opens the HTML file.
`;

export function reviewRoot(value = process.env.REVIEW_HOME ?? "~/reviews"): string {
  return resolve(value.startsWith("~/") ? join(homedir(), value.slice(2)) : value);
}

export function key(pull: Pick<Pull, "repo" | "number">): string {
  return `${pull.repo}#${pull.number}`;
}

export function parseTarget(value: string): { repo: string; number: number } | null {
  const match = value.match(/^(?:https:\/\/github\.com\/|https:\/\/app\.graphite\.(?:com|dev)\/github\/pr\/)?([\w.-]+\/[\w.-]+)(?:\/pull\/|\/|#)([1-9]\d*)(?:[/?#].*)?$/);
  if (!match || match[1].split("/").some((part) => part === "." || part === "..")) {
    return null;
  }

  return { repo: match[1].toLowerCase(), number: Number(match[2]) };
}

export function directory(root: string, pull: Pick<Pull, "repo" | "number">): string {
  const target = parseTarget(key(pull));
  if (!target) {
    throw new Error(`Invalid review target: ${key(pull)}`);
  }

  return join(root, target.repo, `pr-${target.number}`);
}

export async function readJson<T>(path: string): Promise<T | null> {
  try {
    return JSON.parse(await readFile(path, "utf8")) as T;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw new Error(`Cannot read ${path}: ${error}`);
  }
}

export async function writeJson(path: string, value: unknown): Promise<void> {
  const temporary = `${path}.${process.pid}.${crypto.randomUUID()}.tmp`;
  try {
    await writeFile(temporary, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600 });
    await rename(temporary, path);
  } catch (error) {
    throw new Error(`Cannot save ${path}: ${error}`);
  }
}

export async function initialize(root: string): Promise<Config> {
  await mkdir(root, { recursive: true, mode: 0o700 });
  for (const [name, contents] of [
    ["config.json", `${JSON.stringify({ stallMinutes: 10 }, null, 2)}\n`],
    ["prompt.md", DEFAULT_PROMPT],
  ]) {
    try {
      await writeFile(join(root, name), contents, { flag: "wx", mode: 0o600 });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EEXIST") {
        throw error;
      }
    }
  }

  const settings = await readJson<Settings>(join(root, "config.json"));
  if (!settings) {
    throw new Error(`Cannot read ${root}/config.json`);
  }
  stallMinutes(settings);

  const choice = await readAgentChoice();

  return {
    ...choice,
    stallMinutes: settings.stallMinutes,
  };
}

export function stallMinutes(config: Settings | null): number {
  const minutes = config?.stallMinutes === undefined ? 10 : config.stallMinutes;
  if (!Number.isFinite(minutes) || minutes <= 0) {
    throw new Error("Set stallMinutes in config.json to a positive number (default: 10).");
  }

  return minutes;
}

export async function savedReviews(root: string): Promise<Review[]> {
  const names = await Array.fromAsync(new Bun.Glob("*/*/pr-*/review.json").scan({ cwd: root }));
  const results = await Promise.all(names.map(async (name) => {
    try {
      return await readJson<Review>(join(root, name));
    } catch (error) {
      console.error(String(error));
      return null;
    }
  }));

  return results.filter((review): review is Review => review !== null);
}

export function processAlive(pid: number | null): boolean {
  if (!pid) {
    return false;
  }
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code === "EPERM";
  }
}

export function busy(run: Run | null): boolean {
  return !!run && ["queued", "running"].includes(run.status) && processAlive(run.pid);
}

export function plain(value: string): string {
  // PR text is untrusted terminal input, including escape sequences and embedded tabs.
  return value.replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
    .replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "")
    .replace(/[\x00-\x1f\x7f-\x9f]/g, " ");
}

export function shellQuote(value: string): string {
  return `'${value.replace(/'/g, "'\\''")}'`;
}
