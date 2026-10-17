# review / rv

A Bun CLI for HTML PR explanations, persistent worktrees, resumable Codex or Claude
chats, and a linked review dashboard.

## Start

```sh
rv https://github.com/gamma-app/steel-control-plane/pull/10
rv https://app.graphite.com/github/pr/gamma-app/steel-control-plane/10
rv dashboard
```

Requirements: Bun, authenticated `gh`, worktrunk (`wt`), and an authenticated
Codex or Claude CLI. Codex must support app-server thread creation and item injection.
Neovim opens source and configuration; macOS `open` opens HTML and GitHub.
Repository clones live under `~/code`, or `REVIEW_CODE_ROOT`.

Install both command names:

```sh
ln -s ~/code/dotfilez/scripts/review ~/.local/bin/review
ln -s ~/code/dotfilez/scripts/review ~/.local/bin/rv
```

## One directory

Everything lives under `~/reviews`. Set `REVIEW_HOME` or pass `--home /path/to/reviews`
to choose another directory. `rv init` creates the two editable configuration files.

`rv --days N` widens the dashboard from the default 7 days to N days, for both the GitHub search and the table.

The agent comes from `~/code/dotfilez/agent.json`, which `greview` also reads. Set
`AGENT_CONFIG` to use another file.

```json
{
  "agent": "codex",
  "claude": { "model": "claude-opus-5-5", "fast": true },
  "codex": { "model": null }
}
```

`agent` accepts `claude` or `codex`, and each agent keeps its own settings. `model` accepts
the model name you use with that CLI's `--model`; `null` uses its configured default.
`fast: true` turns on Claude fast mode (`--settings '{"fastMode":true}'`); codex ignores it.
Claude always runs with `--dangerously-skip-permissions`, including resumed chats. Each
generation saves this selection and a copy of `prompt.md`. Agent, model, and prompt changes
apply to the next generation. Resuming a chat uses its saved agent, model, fast setting, and
session ID.

`config.json` holds rv-only settings:

```json
{
  "stallMinutes": 10
}
```

`stallMinutes` sets the inactivity threshold and defaults to 10 when omitted; it applies
when status is checked.

`prompt.md` controls the explanation's content and presentation. The runner appends the
PR, exact head/base commits, and output path. The default prompt asks for background,
intuition, a code walkthrough, review notes, and an interactive quiz in one HTML page.

Example layout:

```text
~/reviews/
  config.json
  prompt.md
  pulls.json
  gamma-app/steel-control-plane/pr-10/
    worktree/
    diff.html
    html.json
    chat.json
    review.json
    runs/<timestamp>/
      template.md
      prompt.md
      <date>-diff.html
      chat.md
      events.jsonl
      native.jsonl
      run.json
      worker.log
```

`diff.html` holds the most recent successful explanation. Run directories preserve every
attempt, including failed runs. `chat.json` identifies the latest attempt's native session.
Background runs save assistant output in `chat.md` and `events.jsonl`. Interactive runs save
a copy of the native transcript as `native.jsonl` when the chat exits; `chat.json` also records
its live native transcript path. The agent's native history holds interactive follow-ups.
`html.json` identifies the run and chat that produced `diff.html`.

## Open a review

`rv <PR URL>` prepares the worktree and opens the normal Codex or Claude chat in the current
terminal with the review prompt when HTML is missing. You can watch, ask questions, and steer
it as it generates the review. RV opens the completed HTML while the chat stays open and saves
its session ID for later visits. Exiting before a complete HTML file exists marks the run failed.

With saved HTML, `rv <PR URL>` opens the file and resumes the chat that produced it from the
PR's worktree without sending a message, so the chat waits for your next message. GitHub URLs, Graphite URLs, `owner/repo#number`, and unambiguous PR numbers are
supported. Saved reviews can be opened while GitHub is unavailable.

Each review chat is recorded in `~/.local/state/kitty-agents/reviews.json` (override the
directory with `KITTY_AGENTS_STATE`) so the kitty agents picker (`cmd+shift+a`) can show the
PR it reviews, in blue, next to PRs a chat created.

The generation prompt opens every chat with review instructions that apply to the entire conversation.
Follow-up suggestions produce explanations, draft review comments, or review recommendations.
The agent posts comments, approvals, or change requests when explicitly asked. Repository code
stays read-only; the HTML explanation is the only writable artifact.

`rv generate <PR>` starts a background generation. When a background generation is already
running, `rv <PR>` waits for it, then opens the HTML and resumes the chat. Ctrl-C stops waiting;
the background worker continues. If the awaited generation fails or its worker exits, RV opens
the previous successful HTML and chat when available. Without saved HTML, it reports the failure.
`rv status <PR>` shows the saved details.

## Dashboard

`rv dashboard` (also `rv` or `rv list`) refreshes GitHub and prints a table with muted
horizontal rules between rows, gold headings, and cyan underlined links:

```text
Created   PR   Author   HTML   Approvals
```

The dashboard includes open PRs created in the last seven days that request your review,
that you have reviewed, or that RV has tracked or saved. Saved reviews remain
accessible by URL or PR number. Rows are sorted by creation date, newest first. GitHub requests are
paginated. Cached data remains available when GitHub is unavailable.

Each PR number and title form one link to GitHub, and `📄 Open` links to the
local HTML file using terminal hyperlinks (OSC 8). Piped output is plain text. Approvals list
human approvers by username, with `✅` beside yours and yours first when you have approved, excluding the PR
author; `—` means none.
`Created` shows time since the PR was opened, such as `2d ago`, `3h ago`, or `5m ago`.
`rv status <PR>` shows detailed reviewer names, generation status, and the last generation
activity timestamp. Long cells are truncated to keep the table readable.

HTML displays `📄 Open` when a saved file exists, `⏳ Running` during generation without a saved
file, `⚠️ Failed` after a failed or stopped worker without a saved file, and `—` otherwise.
A stalled generation displays `⚠️ Stalled`, or a linked `📄 Open (stalled)` when a saved HTML exists.

## Stalled generations

RV considers a live worker stalled after `stallMinutes` without agent output or setup
activity. It checks the timestamps of agent events, the native chat transcript, worker logs, and saved
setup/session transitions. This also covers runs already in progress. New output returns
the generation to `Running`; a quiet operation can be healthy despite showing `Stalled`.

`rv <PR>` stops waiting on a stalled generation and opens the previous successful HTML and
its chat. If no previous HTML exists, it exits with a message and the `rv status` command
for inspection. The worker continues in the background and keeps its lock, preventing a
second generation from sharing the worktree. `rv chat <PR>` follows the live transcript.

Dead workers display as failed and a new generation reclaims their locks. Empty startup
locks can be reclaimed after 30 seconds. The saved status file can still say `running` after
an unclean exit; display and retry behavior also check the process.

## Commands

```sh
rv dashboard
rv generate gamma-app/steel-control-plane#10
rv html 10
rv chat 10
rv edit 10
rv status 10
rv config
```

Bare numbers resolve across cached and saved PRs. If several repositories contain that
number, use `owner/repo#number` or a URL.

`rv generate` runs in a detached worker and continues when the terminal closes. Generation uses `wt`
to create a dedicated worktree, fetches the PR and its base, and checks out the exact head
in detached mode. The worktree persists. Tracked edits and user-created commits block
regeneration; Git preserves untracked files and rejects checkout collisions. Changes to a
PR's head are picked up when a new generation starts.

The generator inspects repository files and diffs and writes only the HTML explanation.
Its instructions prohibit running tests, builds, linters, type checks, scripts, applications,
or other code, and prohibit computer use or browser automation for testing. RV opens the HTML.
Agent CLIs run with their permission-bypass flags for unattended local generation. Errors
appear in `rv status <PR>` and the run's `worker.log`. One worker per PR is allowed. A stopped
worker is shown as an error; `rv generate <PR>` starts another attempt.

## Checks

```sh
bun test scripts/review-lib/review.test.ts
```

Integration tests use real Git/worktrunk in temporary repositories and simulated Codex and
Claude executables. They cover worktree retention, chat IDs and resume commands, model
selection, duplicate-generation protection, failed reruns, source-edit preservation,
ambiguous PR numbers, editable configuration, direct URL generation and reuse, dashboard
hyperlinks, offline fallback, relative PR ages, waiting for existing generations, dead-worker
recovery, stall detection, previous-review fallback, recovery when agent output resumes, and native Codex/Claude chat startup. Interactive tests
verify that HTML opens before the simulated chat exits. They make no model calls.

## rvme

`rvme` prints your own PRs updated in the last 7 days (`--days N` widens it), newest first, in the same table style as `rv`. It includes Devin PRs whose body says `Requested by: @<you>`, marked 🤖.

- **Status**: 🟣 merged, 🟢 open, ⚪ draft, 🔴 closed. Merged and closed show their age.
- **Reviews**: latest verdict per reviewer, ❌ changes requested first, then ✅ approvals. With no verdicts, it lists 💬 commenters, most recent first. A bare approval does not count as a comment.

Bots and your own activity are excluded. The table fits narrow terminals: the PR title shrinks first, then the widest other column. `rvme` reads GitHub directly and does not use the review home.
