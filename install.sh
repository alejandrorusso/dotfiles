#!/usr/bin/env bash
# Dotfiles installer — distilled from /vol/docker-nvim-haskell-latex-LLM/dockerfiles/neo-h.docker.
#
# Core install covers neovim + tmux + shell tools. Haskell and LaTeX are
# opt-in via flags (the engine-v2 devcontainer already provides Haskell, so
# skip --haskell in that context).
#
# Safe to re-run: every step checks whether its target already exists before acting.
#
# Usage:
#   bash install.sh                      # core only (no Haskell, no LaTeX, no mkdocs)
#   bash install.sh --haskell            # core + GHC/Cabal/HLS/fourmolu/cabal-gild/hlint/hoogle/fast-tags
#   bash install.sh --latex              # core + texlive/zathura/biber/lhs2tex + Mason texlab/ltex-ls
#   bash install.sh --mkdocs             # core + mkdocs + mkdocs-material + puppeteer + Chrome
#   bash install.sh --all                # --haskell --latex --mkdocs
#   DOTFILES_DIR=/path bash install.sh   # override source dir

set -euo pipefail

WITH_HASKELL=0
WITH_LATEX=0
WITH_MKDOCS=0
for arg in "$@"; do
  case "$arg" in
    --haskell) WITH_HASKELL=1 ;;
    --latex)   WITH_LATEX=1 ;;
    --mkdocs)  WITH_MKDOCS=1 ;;
    --all)     WITH_HASKELL=1; WITH_LATEX=1; WITH_MKDOCS=1 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
HOME_DIR="${HOME:?HOME not set}"
NVIM_VERSION="v0.11.0"
NVIM_TARBALL="nvim-linux-x86_64"
TREESITTER_VERSION="0.25.10"   # last version compatible with GLIBC 2.35 (Ubuntu 22.04)
NVM_VERSION="v0.40.1"
# Default: latest LTS (tracked via nvm's lts/* alias).
# Override with e.g. NODE_VERSION=node (current) or NODE_VERSION=22 to pin.
NODE_VERSION="${NODE_VERSION:---lts}"
# Haskell versions pinned to match /vol/engine-v2/.devcontainer/devcontainer.json
# (so a --haskell install matches what the engine-v2 devcontainer provides).
GHC_VERSION="9.12.2"
CABAL_VERSION="3.16.0.0"
HLS_VERSION="recommended"      # let ghcup pick the latest HLS compatible with GHC_VERSION

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
  trash-cli tldr bat coreutils unzip locales ripgrep fd-find luarocks \
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
# 3. Node.js via NVM (Ubuntu 22.04's apt npm = Node 12, too old for tree-sitter-cli 0.25)
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME_DIR/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  log "Installing nvm ${NVM_VERSION}"
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# Source nvm for the rest of this script.
# nvm is not written for set -u; temporarily relax nounset.
set +u
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

log "Installing Node.js (${NODE_VERSION}) via nvm"
nvm install "$NODE_VERSION"   # idempotent: prints "already installed" if present
if [ "$NODE_VERSION" = "--lts" ]; then
  nvm alias default 'lts/*' >/dev/null
else
  nvm alias default "$NODE_VERSION" >/dev/null
fi
nvm use "$NODE_VERSION" >/dev/null
set -u

if ! command -v tree-sitter >/dev/null 2>&1; then
  log "Installing tree-sitter-cli@${TREESITTER_VERSION}"
  npm install -g "tree-sitter-cli@${TREESITTER_VERSION}"
fi

if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code CLI (@anthropic-ai/claude-code)"
  npm install -g @anthropic-ai/claude-code
fi

# ---------------------------------------------------------------------------
# 4. NeoVim v0.11.0 binary + jsregexp
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

log "Installing tmux plugins via tpm"
"$HOME_DIR/.tmux/plugins/tpm/bin/install_plugins"

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

log "Installing Mason tools (marksman, stylua, lua-language-server, prettier, clangd)"
"$NVIM_BIN" --headless +"MasonUpdate" +q || true
"$NVIM_BIN" --headless \
  +"MasonInstall marksman stylua lua-language-server prettier@2.8.8 clangd" \
  +q || warn "MasonInstall reported errors — continuing"

log "Installing treesitter parser for yaml"
"$NVIM_BIN" --headless +"TSInstall! yaml" +q || true

# ---------------------------------------------------------------------------
# 11. Optional: Haskell layer  (--haskell)
# ---------------------------------------------------------------------------
if [ "$WITH_HASKELL" -eq 1 ]; then
  log "[haskell] Installing GHC ${GHC_VERSION} / Cabal ${CABAL_VERSION} / HLS (${HLS_VERSION}) via ghcup"
  log "[haskell] Versions match /vol/engine-v2/.devcontainer/devcontainer.json"

  apt_install libnuma-dev zlib1g-dev libgmp-dev libgmp10 liblzma-dev

  if [ ! -x "$HOME_DIR/.ghcup/bin/ghcup" ]; then
    export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
  else
    log "[haskell] ghcup already present — skipping bootstrap"
  fi

  export PATH="$HOME_DIR/.ghcup/bin:$HOME_DIR/.cabal/bin:$PATH"

  ghcup install ghc    "$GHC_VERSION"    && ghcup set ghc    "$GHC_VERSION"
  ghcup install cabal  "$CABAL_VERSION"  && ghcup set cabal  "$CABAL_VERSION"
  ghcup install hls    "$HLS_VERSION"    && ghcup set hls    "$HLS_VERSION"

  cabal update
  command -v fast-tags >/dev/null 2>&1 || cabal install fast-tags
  command -v hlint     >/dev/null 2>&1 || cabal install hlint   # matches devcontainer.json globalPackages

  if ! command -v hoogle >/dev/null 2>&1; then
    log "[haskell] Building hoogle from source (workaround for upstream bug)"
    tmp=$(mktemp -d)
    git clone --depth 1 https://github.com/ndmitchell/hoogle.git "$tmp/hoogle"
    ( cd "$tmp/hoogle" && cabal install )
    hoogle generate || warn "[haskell] hoogle generate failed — run manually later"
    rm -rf "$tmp"
  fi

  # fourmolu and cabal-gild: install via cabal to pick up the same toolchain
  # used for building (Mason's prebuilt fourmolu binary can drift).
  command -v fourmolu   >/dev/null 2>&1 || cabal install fourmolu
  command -v cabal-gild >/dev/null 2>&1 || cabal install cabal-gild
fi

# ---------------------------------------------------------------------------
# 12. Optional: LaTeX layer  (--latex)
# ---------------------------------------------------------------------------
if [ "$WITH_LATEX" -eq 1 ]; then
  log "[latex] Installing texlive + zathura + biber + lhs2tex"

  # Accept the Microsoft fonts EULA non-interactively.
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true \
    | $SUDO debconf-set-selections

  apt_install \
    texlive-xetex texlive-luatex texlive-science \
    texlive-extra-utils texlive-bibtex-extra texlive-fonts-extra \
    latexmk biber lhs2tex \
    zathura python3-pygments ttf-mscorefonts-installer \
    pdftk evince inkscape

  log "[latex] Installing Mason texlab + ltex-ls"
  "$NVIM_BIN" --headless +"MasonInstall ltex-ls texlab" +q || warn "[latex] Mason install failed"

  log "[latex] Installing treesitter parsers for latex + bibtex"
  "$NVIM_BIN" --headless +"TSInstall! latex bibtex" +q || true
fi

# ---------------------------------------------------------------------------
# 13. Optional: MkDocs layer  (--mkdocs)
#     Python mkdocs + mkdocs-material + puppeteer + headless Chrome for PDF export
# ---------------------------------------------------------------------------
if [ "$WITH_MKDOCS" -eq 1 ]; then
  log "[mkdocs] Installing pip + mkdocs python packages"
  apt_install python3-pip python3-venv

  # Install as the current user (not root) to avoid PEP 668 'externally-managed-environment' errors.
  python3 -m pip install --user --upgrade Pygments
  python3 -m pip install --user \
    pymdown-extensions \
    mkdocs \
    mkdocs-material \
    mkdocs-include-markdown-plugin \
    mkdocs-excel-plugin \
    mkdocs-page-pdf

  log "[mkdocs] Installing Google Chrome + CJK fonts for PDF rendering"
  if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
    $SUDO install -d /etc/apt/keyrings
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
      | $SUDO gpg --dearmor -o /etc/apt/keyrings/google-linux.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
      | $SUDO tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
  fi
  apt_install \
    google-chrome-stable \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
    libxss1

  log "[mkdocs] Installing puppeteer (used by mkdocs-page-pdf)"
  mkdir -p "$HOME_DIR/.mkdocs-deps"
  ( cd "$HOME_DIR/.mkdocs-deps"
    [ -f package.json ] || npm init -y >/dev/null
    npm install puppeteer )
fi

log "Done. Open a new shell (or 'source ~/.bashrc') and run 'nvim' — checkhealth with ':checkhealth'."
[ "$WITH_HASKELL" -eq 1 ] && log "Haskell layer installed (GHC ${GHC_VERSION}, Cabal ${CABAL_VERSION}, HLS ${HLS_VERSION})."
[ "$WITH_LATEX"   -eq 1 ] && log "LaTeX layer installed."
[ "$WITH_MKDOCS"  -eq 1 ] && log "MkDocs layer installed (puppeteer under ~/.mkdocs-deps)."
[ "$WITH_HASKELL" -eq 0 ] && [ "$WITH_LATEX" -eq 0 ] && [ "$WITH_MKDOCS" -eq 0 ] && \
  log "Core only. Re-run with --haskell / --latex / --mkdocs (or --all) to add layers."
