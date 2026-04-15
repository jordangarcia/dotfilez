#!/bin/bash
# Remove node_modules symlinks and run a real yarn install in the worktree.
# Use after worktree-bootstrap.sh when you need to actually run the codebase.

set -e

DIRS=". packages/server packages/client packages/ui packages/authorization packages/lib packages/lib-dynamodb"

# Remove symlinked node_modules
for d in $DIRS; do
  if [ -L "$d/node_modules" ]; then
    echo "removing symlink: $d/node_modules"
    rm "$d/node_modules"
  fi
done

# Install from root (covers workspaces)
echo "running yarn install..."
yarn install

# Build internal dependencies needed by client and server
echo "building client deps..."
yarn workspace client build:deps

echo "building server deps..."
yarn workspace server build:deps
