#!/usr/bin/env bash
# Session helpers for kt — queries kitty's own state via `kitty @ ls`
# No external registry file needed; all state lives in kitty user vars.

GAMMA_ROOT="$HOME/code/gamma"

# ─── Kitty queries ─────────────────────────────────────────────────────────

# Get full kitty state (cached per invocation to avoid repeated calls)
_kitty_state=""
_kitty_ls() {
  if [[ -z "$_kitty_state" ]]; then
    _kitty_state=$(kitty @ ls 2>/dev/null || echo '[]')
  fi
  echo "$_kitty_state"
}

# Find session data for a branch from kitty user vars
# Returns JSON: { branch, worktree, offset, tab_id }
session_get() {
  local branch="$1"
  _kitty_ls | jq -r --arg b "$branch" '
    [.[].tabs[] | select(.windows[] | .user_vars.kt69_branch == $b and (.user_vars.kt69_dev_tab // "") == "")]
    | first
    | if . then {
        branch: $b,
        worktree_path: .windows[0].user_vars.kt69_worktree,
        port_offset: (.windows[0].user_vars.kt69_offset | tonumber),
        kitty_tab_id: .id
      } else empty end
  ' 2>/dev/null
}

session_exists() {
  local branch="$1"
  local result
  result=$(session_get "$branch")
  [[ -n "$result" ]]
}

session_list_branches() {
  _kitty_ls | jq -r '
    [.[].tabs[].windows[].user_vars.kt69_branch // empty]
    | unique | .[]
  ' 2>/dev/null
}

# Find the lowest unused port offset (multiples of 100, starting at 100)
session_next_offset() {
  local used_offsets
  used_offsets=$(_kitty_ls | jq -r '
    [.[].tabs[].windows[].user_vars.kt69_offset // empty | tonumber]
    | unique | .[]
  ' 2>/dev/null)

  local offset=100
  while true; do
    if echo "$used_offsets" | grep -qx "$offset"; then
      offset=$((offset + 100))
      continue
    fi
    # Also check actual port availability
    if ! offset_ports_free "$offset"; then
      offset=$((offset + 100))
      continue
    fi
    break
  done
  echo "$offset"
}

# ─── Port helpers ──────────────────────────────────────────────────────────

port_in_use() {
  lsof -iTCP:"$1" -sTCP:LISTEN &>/dev/null
}

offset_ports_free() {
  local offset="$1"
  ! port_in_use $((3000 + offset)) && \
  ! port_in_use $((7000 + offset)) && \
  ! port_in_use $((8080 + offset))
}

# ─── Kitty tab helpers ─────────────────────────────────────────────────────

kitty_alive_tab_ids() {
  _kitty_ls | jq -r '.[].tabs[].id'
}

kitty_tab_alive() {
  local tab_id="$1"
  kitty_alive_tab_ids | grep -qx "$tab_id"
}

# Compute worktree path from branch name (matches worktrunk template)
worktree_path_for_branch() {
  local branch="$1"
  local sanitized="${branch//\//-}"
  echo "${GAMMA_ROOT}/.claude/worktrees/${sanitized}"
}
