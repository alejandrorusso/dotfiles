#!/usr/bin/env bash
# Bring up the devcontainer in the current (or given) workspace folder with
# the LaTeX layer of the dotfiles applied, then drop into a bash shell.
#
# Usage:  latex.sh [workspace-folder]
set -euo pipefail
WORKSPACE="${1:-.}"

devcontainer up \
  --workspace-folder "$WORKSPACE" \
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles \
  --dotfiles-install-command install-latex.sh \
  --dotfiles-target-path ~/dotfiles

exec devcontainer exec --workspace-folder "$WORKSPACE" bash
