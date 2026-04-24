#!/usr/bin/env bash
# Bring up the devcontainer in the current (or given) workspace folder with
# only the core dotfiles layer (neovim, tmux, shell tools, claude-code),
# then drop into a bash shell. Use this for engine-v2 where the devcontainer
# already provides the Haskell toolchain.
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
