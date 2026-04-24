#!/usr/bin/env bash
# List Docker containers created by devcontainer CLI or VS Code.
#
# Usage:
#   bash list-devcontainers.sh        # running containers only
#   bash list-devcontainers.sh -a     # include stopped containers

set -euo pipefail

args=(ps)
[[ "${1:-}" == "-a" || "${1:-}" == "--all" ]] && args+=("-a")
args+=(
  --filter "label=devcontainer.local_folder"
  --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Label \"devcontainer.local_folder\"}}"
)

docker "${args[@]}"
