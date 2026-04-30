#!/usr/bin/env bash
# Scaffold a .devcontainer/ folder by composing one or more language-stack
# fragments shipped in this repo (under devcontainer-templates/).
#
# Usage:
#   create-devcontainer.sh --haskell [--latex] [--mkdocs] [target-folder]
#
# Pass multiple stack flags to combine. Add --force to overwrite an existing
# .devcontainer/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL_DIR="$SCRIPT_DIR/devcontainer-templates"
FRAG_DIR="$TPL_DIR/fragments"

WANT_HASKELL=0
WANT_LATEX=0
WANT_MKDOCS=0
FORCE=0
TARGET="."

for arg in "$@"; do
  case "$arg" in
    --haskell) WANT_HASKELL=1 ;;
    --latex)   WANT_LATEX=1 ;;
    --mkdocs)  WANT_MKDOCS=1 ;;
    --force)   FORCE=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
    *)  TARGET="$arg" ;;
  esac
done

# Deterministic order so the layer cache is stable regardless of flag order.
STACKS=()
[ "$WANT_HASKELL" -eq 1 ] && STACKS+=("haskell")
[ "$WANT_LATEX"   -eq 1 ] && STACKS+=("latex")
[ "$WANT_MKDOCS"  -eq 1 ] && STACKS+=("mkdocs")

if [ "${#STACKS[@]}" -eq 0 ]; then
  echo "error: must specify at least one of --haskell --latex --mkdocs" >&2
  exit 2
fi

DEST="$TARGET/.devcontainer"

if [ ! -d "$TARGET" ]; then
  echo "error: target folder does not exist: $TARGET" >&2
  exit 1
fi
if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
  echo "error: $DEST already exists (re-run with --force to overwrite)" >&2
  exit 1
fi

for s in "${STACKS[@]}"; do
  for f in root.dockerfile user.dockerfile; do
    [ -f "$TPL_DIR/$s/$f" ] \
      || { echo "error: fragment not found: $TPL_DIR/$s/$f" >&2; exit 1; }
  done
done

mkdir -p "$DEST"

# Assemble Dockerfile: base header, all root fragments, base user, all user fragments.
parts=("$FRAG_DIR/base-header.dockerfile")
for s in "${STACKS[@]}"; do parts+=("$TPL_DIR/$s/root.dockerfile"); done
parts+=("$FRAG_DIR/base-user.dockerfile")
for s in "${STACKS[@]}"; do parts+=("$TPL_DIR/$s/user.dockerfile"); done

cat "${parts[@]}" > "$DEST/Dockerfile"

# devcontainer.json: take the first stack's and rewrite the "name" field.
PRIMARY="${STACKS[0]}"
NAMES_JOINED=$(IFS=+; echo "${STACKS[*]}")
sed "s/\"name\":[[:space:]]*\"[^\"]*\"/\"name\": \"$NAMES_JOINED\"/" \
    "$TPL_DIR/$PRIMARY/devcontainer.json" > "$DEST/devcontainer.json"

JOINED=$(IFS=,; echo "${STACKS[*]}")
echo "Created $DEST/ from stacks: $JOINED"
echo
echo "Next steps:"
echo "  cd $TARGET"
echo "  bash $SCRIPT_DIR/launch-devcontainer.sh        # bring up + overlay your dotfiles"
