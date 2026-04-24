#!/usr/bin/env bash
# Dotfiles installer — distilled from /vol/docker-nvim-haskell-latex-LLM/dockerfiles/neo-h.docker.
# Haskell and LaTeX are intentionally excluded (provided by the engine-v2 devcontainer or not needed).
#
# Safe to re-run: every step checks whether its target already exists before acting.
#
# Usage:
#   bash install.sh                  # install everything into $HOME
#   DOTFILES_DIR=/path bash install.sh

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
HOME_DIR="${HOME:?HOME not set}"
NVIM_VERSION="v0.11.0"
NVIM_TARBALL="nvim-linux-x86_64"
TREESITTER_VERSION="0.25.10"   # last version compatible with GLIBC 2.35 (Ubuntu 22.04)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    warn "not running as root and sudo not found — apt steps will likely fail"
  fi
fi

apt_install() {
  $SUDO apt-get update -y
  $SUDO apt-get install -y --no-install-recommends "$@"
}

# ---------------------------------------------------------------------------
# 1. Base apt packages (shell tools, nvim deps — NO Haskell, NO LaTeX)
# ---------------------------------------------------------------------------
log "Installing apt packages"
apt_install \
  software-properties-common sudo ssh git wget curl make lzma \
  build-essential gcc autoconf automake gpg dirmngr gnupg2 socat lsb-release \
  ca-certificates \
  powerline less \
  trash-cli tldr bat coreutils unzip locales npm ripgrep fd-find luarocks \
  tmux inetutils-ping xclip duf

# fd ships as fdfind on Debian/Ubuntu; add a convenience symlink if missing.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  $SUDO ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# Locale
$SUDO locale-gen en_US.UTF-8 || true
$SUDO update-locale LANG=en_US.UTF-8 || true

# ---------------------------------------------------------------------------
# 2. Third-party CLI tools (eza, carapace, bottom, dust, zoxide, lazygit, fzf)
# ---------------------------------------------------------------------------
if ! command -v eza >/dev/null 2>&1; then
  log "Installing eza"
  $SUDO install -d /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | $SUDO tee /etc/apt/sources.list.d/gierens.list >/dev/null
  $SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  apt_install eza
fi

if ! command -v carapace >/dev/null 2>&1; then
  log "Installing carapace"
  echo "deb [trusted=yes] https://apt.fury.io/rsteube/ /" \
    | $SUDO tee /etc/apt/sources.list.d/rsteube.list >/dev/null
  apt_install carapace-bin
fi

if ! command -v btm >/dev/null 2>&1; then
  log "Installing bottom (btm)"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/btm.deb" https://github.com/ClementTsang/bottom/releases/download/0.10.2/bottom_0.10.2-1_amd64.deb
  $SUDO dpkg -i "$tmp/btm.deb"
  rm -rf "$tmp"
fi

if ! command -v dust >/dev/null 2>&1; then
  log "Installing dust"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/dust.deb" https://github.com/bootandy/dust/releases/download/v1.2.0/du-dust_1.2.0-1_amd64.deb
  $SUDO dpkg -i "$tmp/dust.deb"
  rm -rf "$tmp"
fi

if ! command -v zoxide >/dev/null 2>&1; then
  log "Installing zoxide"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | $SUDO sh -s -- --bin-dir=/usr/local/bin
fi

if ! command -v lazygit >/dev/null 2>&1; then
  log "Installing lazygit"
  tmp=$(mktemp -d)
  version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -Po '"tag_name": "v\K[^"]*')
  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  $SUDO install "$tmp/lazygit" /usr/local/bin
  rm -rf "$tmp"
fi

if [ ! -d "$HOME_DIR/.fzf" ]; then
  log "Installing fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME_DIR/.fzf"
  "$HOME_DIR/.fzf/install" --all --no-bash --no-zsh --no-fish >/dev/null
fi

# ---------------------------------------------------------------------------
# 3. NeoVim v0.11.0 binary + tree-sitter-cli + jsregexp
# ---------------------------------------------------------------------------
if [ ! -x "/opt/${NVIM_TARBALL}/bin/nvim" ]; then
  log "Installing NeoVim ${NVIM_VERSION}"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_TARBALL}.tar.gz"
  $SUDO tar -C /opt -xzf "$tmp/nvim.tar.gz"
  rm -rf "$tmp"
fi
NVIM_BIN="/opt/${NVIM_TARBALL}/bin/nvim"

if ! command -v tree-sitter >/dev/null 2>&1; then
  log "Installing tree-sitter-cli@${TREESITTER_VERSION}"
  $SUDO npm install -g "tree-sitter-cli@${TREESITTER_VERSION}"
fi

log "Installing luarocks jsregexp (required by some nvim plugins)"
$SUDO luarocks install --force jsregexp >/dev/null

# ---------------------------------------------------------------------------
# 4. Tmux plugin manager (tpm)
# ---------------------------------------------------------------------------
if [ ! -d "$HOME_DIR/.tmux/plugins/tpm" ]; then
  log "Installing tpm"
  git clone https://github.com/tmux-plugins/tpm "$HOME_DIR/.tmux/plugins/tpm"
fi

# ---------------------------------------------------------------------------
# 5. NvChad starter (only if ~/.config/nvim is empty)
# ---------------------------------------------------------------------------
if [ ! -d "$HOME_DIR/.config/nvim" ]; then
  log "Cloning NvChad starter into ~/.config/nvim"
  mkdir -p "$HOME_DIR/.config"
  git clone https://github.com/NvChad/starter "$HOME_DIR/.config/nvim"
fi

# ---------------------------------------------------------------------------
# 6. Symlink / copy the overlay config files
# ---------------------------------------------------------------------------
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  [ -L "$dst" ] || [ ! -e "$dst" ] || mv "$dst" "$dst.bak.$(date +%s)"
  ln -sfn "$src" "$dst"
}

log "Linking nvim overlays"
link "$DOTFILES_DIR/nvim/lua/options.lua"         "$HOME_DIR/.config/nvim/lua/options.lua"
link "$DOTFILES_DIR/nvim/lua/mappings.lua"        "$HOME_DIR/.config/nvim/lua/mappings.lua"
link "$DOTFILES_DIR/nvim/lua/chadrc.lua"          "$HOME_DIR/.config/nvim/lua/chadrc.lua"
link "$DOTFILES_DIR/nvim/lua/plugins/init.lua"    "$HOME_DIR/.config/nvim/lua/plugins/init.lua"
link "$DOTFILES_DIR/nvim/lua/configs/conform.lua" "$HOME_DIR/.config/nvim/lua/configs/conform.lua"
link "$DOTFILES_DIR/nvim/lua/configs/lspconfig.lua" "$HOME_DIR/.config/nvim/lua/configs/lspconfig.lua"
link "$DOTFILES_DIR/nvim/lua/custom/autocmds.lua" "$HOME_DIR/.config/nvim/lua/custom/autocmds.lua"

# Append init-add.lua to the NvChad init.lua once (idempotent).
INIT_MARKER="-- >>> dotfiles init-add.lua"
if ! grep -qF "$INIT_MARKER" "$HOME_DIR/.config/nvim/init.lua"; then
  log "Appending top-level init to ~/.config/nvim/init.lua"
  {
    printf '\n%s\n' "$INIT_MARKER"
    cat "$DOTFILES_DIR/nvim/init-add.lua"
  } >> "$HOME_DIR/.config/nvim/init.lua"
fi

# fourmolu config for Mason-installed fourmolu (harmless if Mason's dir doesn't exist).
if [ -d "$HOME_DIR/.local/share/nvim/mason/bin" ]; then
  cp -f "$DOTFILES_DIR/nvim/fourmolu.yaml" "$HOME_DIR/.local/share/nvim/mason/bin/fourmolu.yaml"
fi

log "Linking tmux.conf"
link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME_DIR/.tmux.conf"

# ---------------------------------------------------------------------------
# 7. Powerline two-lines theme
# ---------------------------------------------------------------------------
if [ -d /usr/share/powerline/config_files/themes/shell ]; then
  log "Installing powerline two-lines theme"
  $SUDO cp "$DOTFILES_DIR/powerline/default.twolines.json" \
    /usr/share/powerline/config_files/themes/shell/default.twolines.json
  $SUDO sed -i 's/default_leftonly/default.twolines/g' \
    /usr/share/powerline/config_files/config.json
fi

# ---------------------------------------------------------------------------
# 8. Ansi welcome banner
# ---------------------------------------------------------------------------
if [ ! -d "$HOME_DIR/.ansi-welcome" ]; then
  log "Cloning ansi-welcome"
  git clone https://github.com/alejandrorusso/ansi-welcome.git "$HOME_DIR/.ansi-welcome"
  chmod +x "$HOME_DIR/.ansi-welcome/random-ansi.sh"
fi

# ---------------------------------------------------------------------------
# 9. Wire bashrc.d into ~/.bashrc (idempotent)
# ---------------------------------------------------------------------------
BASHRC_MARKER="# >>> dotfiles bashrc.d <<<"
if ! grep -qF "$BASHRC_MARKER" "$HOME_DIR/.bashrc" 2>/dev/null; then
  log "Wiring bashrc.d into ~/.bashrc"
  cat >> "$HOME_DIR/.bashrc" <<EOF

$BASHRC_MARKER
for _f in "$DOTFILES_DIR"/bash/bashrc.d/*.sh; do
  [ -r "\$_f" ] && . "\$_f"
done
unset _f
# <<< dotfiles bashrc.d <<<
EOF
fi

# ---------------------------------------------------------------------------
# 10. Headless nvim plugin + Mason install
# ---------------------------------------------------------------------------
log "Bootstrapping nvim plugins (Lazy sync) — this may take a minute"
"$NVIM_BIN" --headless "+Lazy! sync" +qa || warn "Lazy sync reported errors — run nvim interactively to inspect"

log "Installing Mason tools (marksman, stylua, lua-language-server, prettier, ltex-ls, texlab, clangd, fourmolu)"
"$NVIM_BIN" --headless +"MasonUpdate" +q || true
"$NVIM_BIN" --headless \
  +"MasonInstall marksman stylua lua-language-server prettier@2.8.8 ltex-ls texlab clangd fourmolu" \
  +q || warn "MasonInstall reported errors — continuing"

log "Installing treesitter parser for yaml"
"$NVIM_BIN" --headless +"TSInstall! yaml" +q || true

log "Done. Open a new shell (or 'source ~/.bashrc') and run 'nvim' — checkhealth with ':checkhealth'."
