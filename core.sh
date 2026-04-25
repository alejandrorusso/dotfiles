#!/usr/bin/env bash
# Bring up the devcontainer in the current (or given) workspace folder,
# overlay the dotfiles (neovim, tmux, shell tools, claude-code), and drop
# into a bash shell. Language toolchains come from the project's own
# devcontainer.
#
# Usage:  core.sh [workspace-folder]
set -euo pipefail
WORKSPACE="${1:-.}"

devcontainer up \
  --workspace-folder "$WORKSPACE" \
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles \
  --dotfiles-install-command install.sh \
  --dotfiles-target-path ~/dotfiles

exec devcontainer exec --workspace-folder "$WORKSPACE" bash
