import { readFile } from "node:fs/promises";
import { join } from "node:path";

export type Agent = "codex" | "claude";

// The active agent with its model settings, resolved from agent.json.
// model=null uses the CLI's configured default. fast turns on Claude fast mode; codex ignores it.
export type AgentChoice = {
  agent: Agent;
  model: string | null;
  fast: boolean;
};

type AgentSettings = {
  model?: string | null;
  fast?: boolean;
};

type AgentFile = {
  agent: Agent;
  claude?: AgentSettings;
  codex?: AgentSettings;
};

const AGENTS: Agent[] = ["codex", "claude"];

// Bun resolves symlinked entry scripts (~/.local/bin/greview) to their real path,
// so import.meta.dir is always inside the dotfilez checkout.
export function agentConfigPath(): string {
  return process.env.AGENT_CONFIG ?? join(import.meta.dir, "..", "..", "agent.json");
}

export function isAgent(value: unknown): value is Agent {
  return AGENTS.includes(value as Agent);
}

// override picks the other agent for one run while keeping that agent's settings from the file.
export async function readAgentChoice(override?: Agent): Promise<AgentChoice> {
  const path = agentConfigPath();

  let file: AgentFile;
  try {
    file = JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    throw new Error(`Cannot read agent config at ${path}: ${error}`);
  }

  const agent = override ?? file.agent;
  if (!isAgent(agent)) {
    throw new Error(`Set agent to codex or claude in ${path}`);
  }

  const settings = file[agent] ?? {};
  const model = settings.model ?? null;
  const fast = settings.fast ?? false;

  const validModel = model === null || (typeof model === "string" && model.trim().length > 0);
  if (!validModel) {
    throw new Error(`Set ${agent}.model to a model name or null in ${path}`);
  }

  if (typeof fast !== "boolean") {
    throw new Error(`Set ${agent}.fast to true or false in ${path}`);
  }

  return {
    agent,
    model,
    fast,
  };
}

// Model and speed flags shared by every claude invocation.
export function claudeFlags(options: { model: string | null; fast?: boolean }): string[] {
  const model = options.model ? ["--model", options.model] : [];
  const fast = options.fast ? ["--settings", JSON.stringify({ fastMode: true })] : [];

  return [...model, ...fast];
}

export function codexFlags(options: { model: string | null }): string[] {
  return options.model ? ["--model", options.model] : [];
}
