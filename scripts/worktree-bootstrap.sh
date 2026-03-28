#!/bin/bash
# Bootstrap a worktree with symlinks to gitignored files from the main worktree.
# Used by wt.toml pre-start hook and conductor.

MAIN=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')

# Symlink config files
for f in certificates .envrc .envrc.local .env.yarn CLAUDE.local.md; do
  if [ -e "$MAIN/$f" ] && [ ! -e "$f" ]; then
    ln -sfn "$MAIN/$f" "$f"
  fi
done
mkdir -p .claude
if [ -e "$MAIN/.claude/settings.local.json" ] && [ ! -e .claude/settings.local.json ]; then
  ln -sfn "$MAIN/.claude/settings.local.json" .claude/settings.local.json
fi

# Symlink node_modules (root + packages that server/client build:deps need)
for d in . packages/server packages/client packages/ui packages/authorization packages/lib packages/lib-dynamodb; do
  if [ -d "$MAIN/$d/node_modules" ] && [ ! -e "$d/node_modules" ]; then
    ln -sfn "$MAIN/$d/node_modules" "$d/node_modules"
  fi
done

direnv allow 2>/dev/null || true
