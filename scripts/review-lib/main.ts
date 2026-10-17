import { realpath } from "node:fs/promises";
import { join } from "node:path";
import { refresh, resolvePull, takeDays } from "./github";
import { worker } from "./runner";
import { directory, initialize, key, reviewRoot } from "./store";
import { openReview, perform, preview } from "./actions";
import { dashboard } from "./dashboard";

const HELP = `review / rv — PR explanations, worktrees, and chats

  rv                          Print the PR dashboard
  rv <PR URL or number>        Open the review chat; generate missing HTML interactively
  rv dashboard                Print a linked table of PRs and review status
  rv list                     Alias for dashboard
  rv generate <PR>            Generate an HTML explanation in the background
  rv html <PR>                Open the saved HTML
  rv chat <PR>                Resume its chat (live transcript while generating)
  rv edit <PR>                Open its worktree in Neovim
  rv status <PR>              Print paths and generation status
  rv config                   Edit agent.json, config.json, and prompt.md in Neovim
  rv init                     Create configuration and print its directory

  PR = number, owner/repo#number, or GitHub/Graphite URL.
  Ambiguous PR numbers require owner/repo#number.

  --days <n>                  Dashboard window in days (default 7)
  --home <directory>          All configuration and saved reviews
                             Default: REVIEW_HOME or ~/reviews

  The agent comes from ~/code/dotfilez/agent.json (or AGENT_CONFIG), shared with greview:
    { "agent": "codex", "claude": { "model": "claude-opus-5-5", "fast": true }, "codex": { "model": null } }
  agent is claude or codex; model=null uses that CLI's configured default.
  fast turns on Claude fast mode. Claude runs with --dangerously-skip-permissions.
  config.json: { "stallMinutes": 10 }
  stallMinutes is the inactivity threshold before a live generation is shown as stalled.
  prompt.md is the editable HTML explanation prompt.

  Requires bun, gh, wt, and the chosen agent CLI.
  Clones are found under REVIEW_CODE_ROOT (default ~/code).
  Worktrees and generation history persist after exit.
`;

export async function main(): Promise<void> {
  const args = process.argv.slice(2);
  if (args.includes("--help") || args.includes("-h")) {
    console.log(HELP);
    return;
  }
  const homeIndex = args.indexOf("--home");
  if (homeIndex >= 0 && !args[homeIndex + 1]) {
    throw new Error("--home needs a directory.");
  }
  const root = reviewRoot(homeIndex >= 0 ? args.splice(homeIndex, 2)[1] : undefined);
  const days = takeDays(args);
  const [action, input, runId] = args;
  const script = await realpath(process.argv[1]);
  await initialize(root);

  switch (action) {
    case "init":
      console.log(root);
      return;
    case undefined:
    case "dashboard":
    case "list":
      try {
        await refresh(root, undefined, days);
      } catch (error) {
        console.error(`GitHub unavailable; showing saved data. ${String(error)}`);
      }
      process.stdout.write(await dashboard(root, undefined, days));
      return;
    case "config":
      await perform(root, "config", null, script);
      return;
    case "_worker": {
      const pull = await resolvePull(root, input);
      await worker(root, pull, runId);
      return;
    }
    case "status": {
      if (!input) {
        throw new Error("rv status needs a PR number or URL.");
      }
      const pull = await resolvePull(root, input);
      console.log(await preview(root, key(pull), pull));
      console.log(`\nWorktree: ${join(directory(root, pull), "worktree")}`);
      console.log(`HTML: ${join(directory(root, pull), "diff.html")}`);
      return;
    }
    case "generate":
    case "html":
    case "chat":
    case "edit":
    case "github": {
      if (!input) {
        throw new Error(`rv ${action} needs a PR number or URL.`);
      }
      const pull = await resolvePull(root, input);
      console.log(await perform(root, action, pull, script));
      return;
    }
    default: {
      const pull = await resolvePull(root, action);
      await openReview(root, pull, script);
    }
  }
}
