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

# Symlink package-level .env.local and .vercel files
for d in packages/client packages/server; do
  if [ -e "$MAIN/$d/.env.local" ] && [ ! -e "$d/.env.local" ]; then
    ln -sfn "$MAIN/$d/.env.local" "$d/.env.local"
  fi
  if [ -d "$MAIN/$d/.vercel" ] && [ ! -e "$d/.vercel" ]; then
    ln -sfn "$MAIN/$d/.vercel" "$d/.vercel"
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

# Symlink Prisma generated client (gitignored, lives in source tree)
for d in packages/server packages/aijsx packages/event-tracking; do
  if [ -d "$MAIN/$d/src/db/generated" ] && [ ! -e "$d/src/db/generated" ]; then
    ln -sfn "$MAIN/$d/src/db/generated" "$d/src/db/generated"
  fi
done

direnv allow 2>/dev/null || true
