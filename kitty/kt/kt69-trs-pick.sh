#!/usr/bin/env bash
# Pick a claude session for this branch, resume in the CC pane
set -euo pipefail

BRANCH="${KT69_BRANCH:-}"
WORKTREE="${KT69_WORKTREE:-}"

if [[ -z "$BRANCH" ]]; then
  echo "not in a kt session"
  sleep 1
  exit 0
fi

# Get sessions for this branch
SESSIONS=$(trs list -b "$BRANCH" --json --no-index 2>/dev/null \
  | jq -r '[.session_id, .start_time[:16], (.message_count | tostring) + " msgs", (.first_message[:100] | gsub("\n"; " "))] | join(" │ ")' \
  2>/dev/null || true)

if [[ -z "$SESSIONS" ]]; then
  echo "no sessions found for $BRANCH"
  sleep 1
  exit 0
fi

SESSION_LINE=$(echo "$SESSIONS" | fzf --prompt="session> " --height=100% --reverse --ansi || true)

if [[ -z "$SESSION_LINE" ]]; then
  exit 0
fi

SESSION_ID="${SESSION_LINE%% │*}"

# Find the CC pane — it's the window with kt69_branch set that's running claude
# Use var: matching to find kt69 windows, then pick the one that looks like CC
CC_WINDOW_ID=$(kitty @ ls | jq -r \
  --arg branch "$BRANCH" \
  '.[].tabs[].windows[] | select(.user_vars.kt69_branch == $branch and (.title | test("Claude|claude"; "i"))) | .id' \
  | head -1)

if [[ -z "$CC_WINDOW_ID" ]]; then
  # Fallback: first kt69 window for this branch
  CC_WINDOW_ID=$(kitty @ ls | jq -r \
    --arg branch "$BRANCH" \
    '.[].tabs[].windows[] | select(.user_vars.kt69_branch == $branch) | .id' \
    | head -1)
fi

if [[ -n "$CC_WINDOW_ID" ]]; then
  # Exit current claude and start new session
  kitty @ send-text -m "id:$CC_WINDOW_ID" "/exit\r"
  sleep 1
  kitty @ send-text -m "id:$CC_WINDOW_ID" "claude --resume $SESSION_ID\r"
fi
