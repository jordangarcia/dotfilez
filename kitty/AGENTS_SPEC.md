# Agent chats in kitty

This system tracks Claude Code and Codex chats running in kitty. It lets you
find a chat, see what it is doing, name it, star it, close the rest, and
resume a closed chat.

## Core rule: the chat is the unit, not the tab

A chat is one agent session, identified by its session id. Every piece of
state in this system (name, star, history entry) belongs to a chat. A tab or
window is only where a chat currently runs.

Consequences:

- Starting a new chat in a tab (`/clear`, or exiting and rerunning `claude`)
  gives that tab a new chat. The old chat keeps its name and star and moves to
  history.
- Resuming a chat, from anywhere, brings back its name and star.
- One chat has one name, shown the same way in the tab bar and the picker.

## Components

| Component | File | Role |
|---|---|---|
| Hook | `~/code/dotfilez/bin/agent-kitty-vars` | Claude/Codex lifecycle hooks write window user vars |
| Picker | `kitty/kittens/agents.py` | `cmd+shift+a` finder over live, starred and closed chats |
| Star | `kitty/kittens/star_session.py` | `cmd+shift+s` stars or unstars the focused chat |
| Rename | `kitty/kittens/rename_chat.py` | `kitty_mod+r` names the focused chat |
| Close | `kitty/kittens/close_unstarred.py` | `cmd+shift+o` closes every window except starred and working chats |
| Tab bar | `kitty/tab_bar.py` | Shows each tab's title and a ★ for starred chats |

The hook is registered in `~/.claude/settings.json` and `~/.codex/hooks.json`.
Codex runs hooks only after you approve them in `/hooks`.

## Data

### Window user vars (set by the hook)

| Var | Meaning |
|---|---|
| `agent` | `claude` or `codex` |
| `agent_session` | Session id of the chat running in the window |
| `agent_status` | `working`, `attention`, `idle` or `error` |
| `agent_status_at` | Unix time of the last status change |
| `agent_cwd` | Working directory reported by the hook |
| `agent_prompt` | Last prompt sent, one line, first 300 characters |
| `agent_prompt_at` | Unix time of that prompt |

`SessionStart` sets `agent_session` for the new chat. `SessionEnd` removes all
of them. The vars are visible in `kitty @ ls` and usable in matches such as
`--match var:agent_status=attention`.

### State files (`~/.local/state/kitty-agents/`)

| File | Shape | Written by |
|---|---|---|
| `starred.json` | `{session: {agent, session, cwd, title, prompt, starred_at}}` | star kitten, picker `ctrl-s` |
| `names.json` | `{session: name}` | rename kitten, picker (adopting kitty tab names) |
| `prs.json` | `{pr url: {title, state, fetched_at}}` | picker preview |
| `reviews.json` | `{session: {agent, url, repo, number, title, dir, root}}` | `rv`, when a review chat starts |

Files are written with write-then-rename. The tab bar re-reads them only when
their modification time changes.

### Read-only sources

- `~/.claude/projects/*/<session>.jsonl`: Claude transcripts. Source of the
  generated title (`ai-title`), last prompt and time, last reply, linked PRs
  (`pr-link`), and the starting directory.
- `~/.claude/sessions/<pid>.json`: live Claude sessions by process id. Maps a
  window to its session before the hook has fired there.
- `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`: Codex transcripts. Source of
  the session id, directory, prompts and last reply.

## Titles

A chat's title is resolved in this order, highest first:

1. **Chat name.** The name you gave the chat with `kitty_mod+r`, from
   `names.json`. It is fixed until you change or clear it.
2. **Kitty tab name.** A tab renamed some other way (command palette,
   `kitty @ set-tab-title`). A tab name counts only when it does not start with
   Claude's `✳` or spinner glyph, because Claude sets glyph-prefixed tab titles
   itself. The picker adopts such a name as the chat's name and clears the tab
   name, so it cannot carry over to the next chat in that tab.
3. **Generated title.** For Claude, its live terminal title or the latest
   `ai-title` in the transcript, which update as the topic changes. For Codex,
   the opening prompt.
4. **Directory.** For tabs without a chat (plain shells), e.g. `code/gamma`.

Renaming prefills the current title. Submitting an empty name clears the chat
name and falls back to the generated title. In a tab without a chat,
`kitty_mod+r` is kitty's normal tab rename.

The tab bar shows the title of the tab's active window, truncated to 20
characters. A tab with several agent windows shows the active one.

## Statuses

| Status | Shown as | Meaning |
|---|---|---|
| `attention` | `● need` | Waiting on a permission prompt, question or plan approval |
| `error` | `✗ err` | The last turn failed |
| `working` | `◐ work` | Mid-turn |
| `idle` | `○ idle` | Finished its turn, waiting for you |
| `dormant` | `◌ dorm` | Starred chat with no open window |
| `closed` | `↺ past` | Recently closed chat, shown in history |
| `shell` | `· sh` | Window without an agent |

Claude windows without hook vars fall back to the status in their
`~/.claude/sessions/<pid>.json`, else `idle`.

## Picker (`cmd+shift+a`)

Opens as an overlay over the current window.

Each row shows tab position (1..n, the number `cmd+1..9` jumps to), status,
time since your last prompt, agent, latest linked PR (`+N` for more), ★ for
starred chats, title, last prompt, directory and short session id. A chat
that `rv` started to review a PR, and that links no PR of its own, shows
`rv#<number>` in blue instead. The
preview shows the full last prompt, the chat's PRs, and either the bottom of
the window's screen or, for dormant and closed chats, the agent's last reply.

Each PR in the preview shows its number, state (open, draft, merged, closed)
and title, up to four. A review chat adds a blue `rv #<number>` line with the
PR's state and title, then a dim line from `rv`'s saved review: when
`diff.html` was generated, whether the PR has new commits since, and who
approved (✅, you first) or requested changes (❌). Details come from one batched `gh api graphql` call for
the PRs not fetched in the last 10 minutes, cached in `prs.json`. Offline or
without `gh` auth, the preview falls back to cached details, then bare URLs.

| Key | Action |
|---|---|
| `enter` | Focus the window; for dormant or closed chats, resume in a new tab |
| `ctrl-s` | Star or unstar |
| `ctrl-g` | Open the chat's latest PR on GitHub, else the PR it reviews |
| `ctrl-h` | Switch to history and back |
| `tab` | Sort by last message (default) or tab order |
| `ctrl-a` | All windows (default) or agents only |
| `ctrl-r` | Refresh |
| `ctrl-j` / `ctrl-k` | Move down / up |
| `esc` | Quit |

Views:

- **All / agents:** live windows plus dormant starred chats.
- **History:** the 40 most recent chats from the last 14 days with no open
  window, newest first. Scripted runs (`claude -p`, SDK, `codex exec`, rv) and
  chats without a message are left out. History reads the first 64 KB and
  last 1 MB of each transcript.

Resuming runs, in an interactive shell in the chat's starting directory:

- Claude: `command claude --dangerously-skip-permissions --resume <session>`
- Codex: `codex resume --dangerously-bypass-approvals-and-sandbox <session>`

The shell stays open when the agent exits. The new tab gets no kitty tab name;
its title comes from the chat's name or generated title once the hook tags the
window.

## Stars (`cmd+shift+s`, picker `ctrl-s`)

Starring records the chat in `starred.json`. A starred chat:

- shows ★ in the picker, and in the tab bar while its window is open;
- stays in the picker as a dormant row after its window closes;
- survives `cmd+shift+o`.

Starring from a window without a chat does nothing.

## Close unstarred (`cmd+shift+o`)

Lists what it keeps and what it closes, then asks `[y/N]`. It keeps starred
chats and chats that are `working` or `attention`. It closes everything else,
including plain shells and the window you pressed it from. Closed Claude and
Codex chats remain resumable from history.

## Hook behavior

The hook runs on each lifecycle event and exits silently on any failure. It
only writes local files and returns in tens of milliseconds; a detached job
sends the window's newest state to kitty. Jobs for one window run one at a
time under a lock, and each sends the newest state when it runs, so a slow job
can never leave an older status behind. A kitty call that does not answer is
killed after 2 seconds.

| Event | Status |
|---|---|
| `SessionStart` | `idle`, and sets the new session id |
| `UserPromptSubmit` | `working`, and records the prompt |
| `PreToolUse` for AskUserQuestion, ExitPlanMode, request_user_input | `attention` |
| `PermissionRequest`, `Elicitation`, permission/elicitation `Notification` | `attention` |
| `PostToolUse`, `PostToolUseFailure`, `ElicitationResult` | `working` |
| idle `Notification`, `Stop`, `Interrupt` | `idle` |
| `StopFailure` | `error` |
| `SessionEnd` | clears the vars |

Subagent events are ignored. Without `KITTY_WINDOW_ID` and `KITTY_LISTEN_ON`
the hook does nothing rather than guess a window. A per-window cache skips
writes when nothing changed. Per-window state lives in
`$TMPDIR/agent-kitty-vars/` (`<window>.pending`, `<window>.key`,
`<window>.lock`).

## Limits

- The status is a single value per window. Parallel tool calls can clear
  `attention` before every pending request resolves.
- Codex has no generated title, PR links or per-process session file. Its
  windows get a session id, and so become nameable and starrable, only through
  approved hooks.
- A chat that has not fired a hook since the hooks were installed has no
  `agent_session` var. The picker still finds it through Claude's process
  file, but its tab bar name and ★ appear after its next event.
- History windows of 1 MB can miss older PR links in very long transcripts.
- History lists review chats even when their last prompt falls outside that
  window, using the PR title as a Codex review chat's title. Codex review chats
  come from `rv` through `codex app-server`, not the Codex TUI, and Claude
  review chats start as `claude -p`; `reviews.json` is what lets both through.
- Review details come from `rv`'s last GitHub refresh, so approvals made since
  then appear after the next `rv` run.
