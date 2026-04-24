#!/usr/bin/env bash
# Bring up the devcontainer in the current (or given) workspace folder with
# all dotfiles layers (Haskell + LaTeX + MkDocs) applied, then drop into a
# bash shell.
#
# Usage:  all.sh [workspace-folder]
set -euo pipefail
WORKSPACE="${1:-.}"

devcontainer up \
  --workspace-folder "$WORKSPACE" \
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles \
  --dotfiles-install-command install-all.sh \
  --dotfiles-target-path ~/dotfiles

exec devcontainer exec --workspace-folder "$WORKSPACE" bash
