#!/usr/bin/env bash
# Wrapper: runs install.sh --latex. Pointed at by --dotfiles-install-command
# because the devcontainer CLI's dotfiles hook does not forward extra args.
set -euo pipefail
exec bash "$(dirname "$(readlink -f "$0")")/install.sh" --latex
