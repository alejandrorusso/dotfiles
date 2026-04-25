#!/usr/bin/env bash
# Scaffold a .devcontainer/ folder for a new project from one of the
# language-stack templates shipped in this repo.
#
# Usage:
#   create-devcontainer.sh --haskell [target-folder]
#   create-devcontainer.sh --latex   [target-folder]
#   create-devcontainer.sh --mkdocs  [target-folder]
#
# Add --force to overwrite an existing .devcontainer/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STACK=""
FORCE=0
TARGET="."
for arg in "$@"; do
  case "$arg" in
    --haskell) STACK="haskell" ;;
    --latex)   STACK="latex" ;;
    --mkdocs)  STACK="mkdocs" ;;
    --force)   FORCE=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
    *)  TARGET="$arg" ;;
  esac
done

if [ -z "$STACK" ]; then
  echo "error: must specify one of --haskell / --latex / --mkdocs" >&2
  exit 2
fi

SRC="$SCRIPT_DIR/$STACK"
DEST="$TARGET/.devcontainer"

if [ ! -d "$SRC" ]; then
  echo "error: template not found: $SRC" >&2
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "error: target folder does not exist: $TARGET" >&2
  exit 1
fi

if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
  echo "error: $DEST already exists (re-run with --force to overwrite)" >&2
  exit 1
fi

mkdir -p "$DEST"
cp "$SRC/devcontainer.json" "$DEST/devcontainer.json"
cp "$SRC/Dockerfile"        "$DEST/Dockerfile"

echo "Created $DEST/ from $STACK template"
echo
echo "Next steps:"
echo "  cd $TARGET"
echo "  bash $SCRIPT_DIR/../core.sh        # bring up + overlay your dotfiles"
