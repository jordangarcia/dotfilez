#!/usr/bin/env bash
# kt69 command menu — launched as an overlay by kt69_menu.py kitten

set -euo pipefail

BRANCH="${KT69_BRANCH:-}"
OFFSET="${KT69_OFFSET:-}"
WORKTREE="${KT69_WORKTREE:-}"

if [[ -z "$BRANCH" ]]; then
  echo "not in a kt session"
  sleep 1
  exit 0
fi

# Helper: find a window in the current tab by user var
find_window() {
  local var_name="$1" var_value="$2"
  kitty @ ls | jq -r \
    --arg branch "$BRANCH" \
    --arg vname "$var_name" \
    --arg vval "$var_value" \
    '.[].tabs[].windows[] | select(.user_vars.kt69_branch == $branch and .user_vars[$vname] == $vval) | .id' \
    | head -1
}

# Helper: find the shell pane (kt69 window that's not CC and not dev pane)
find_shell_pane() {
  kitty @ ls | jq -r \
    --arg branch "$BRANCH" \
    '.[].tabs[].windows[] | select(
      .user_vars.kt69_branch == $branch
      and (.user_vars.kt69_dev_pane // "") == ""
      and (.title | test("Claude|claude"; "i") | not)
    ) | .id' \
    | head -1
}

# Display menu
clear
echo ""
echo "  kt ─ $BRANCH (offset=$OFFSET)"
echo "  ─────────────────────────────────────"
echo ""
printf "  \033[1;33md\033[0m  dev-cli     toggle dev-cli pane\n"
printf "  \033[1;33mb\033[0m  browser     open client in browser\n"
printf "  \033[1;33ma\033[0m  claude      launch claude overlay\n"
printf "  \033[1;33mt\033[0m  trs         switch claude session\n"
printf "  \033[1;33mp\033[0m  pr open     open PR in browser\n"
printf "  \033[1;33mc\033[0m  pr create   create new PR\n"
printf "  \033[1;33ms\033[0m  status      show session status\n"
printf "  \033[1;33mx\033[0m  stop        stop this session\n"
echo ""
echo "  ─────────────────────────────────────"
echo "  press a key or q to close"
echo ""

read -rsn1 choice

case "$choice" in
  d)
    # Toggle dev-cli pane
    DEV_PANE=$(find_window "kt69_dev_pane" "true")
    if [[ -n "$DEV_PANE" ]]; then
      kitty @ close-window -m "id:$DEV_PANE"
    else
      SHELL_PANE=$(find_shell_pane)
      if [[ -n "$SHELL_PANE" ]]; then
        NEW_ID=$(kitty @ launch --location=hsplit \
          --cwd="$WORKTREE" \
          --var "kt69_branch=$BRANCH" \
          --var "kt69_offset=$OFFSET" \
          --var "kt69_worktree=$WORKTREE" \
          --var "kt69_dev_pane=true" \
          --bias=20 \
          -m "id:$SHELL_PANE")
        kitty @ send-text -m "id:$NEW_ID" "yarn dev-cli start --offset $OFFSET\r"
      fi
    fi
    ;;
  b)
    open "https://localhost:$((3000 + OFFSET))"
    ;;
  a)
    kitty @ launch --type=overlay \
      --cwd="$WORKTREE" \
      claude
    ;;
  t)
    kitty @ launch --type=overlay \
      --env "KT69_BRANCH=$BRANCH" \
      --env "KT69_WORKTREE=$WORKTREE" \
      ~/.config/kitty/kt/kt69-trs-pick.sh
    ;;
  p)
    (cd "$WORKTREE" && gh pr view --web 2>/dev/null) || echo "no PR found"
    ;;
  c)
    kitty @ launch --type=overlay \
      --cwd="$WORKTREE" \
      gh pr create --web
    ;;
  s)
    kt status "$BRANCH"
    ;;
  x)
    kt stop "$BRANCH"
    ;;
  q|"")
    ;;
esac
