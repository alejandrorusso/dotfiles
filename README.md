# dotfiles

Personal shell + neovim + tmux setup, extracted from
`/vol/docker-nvim-haskell-latex-LLM/dockerfiles/neo-h.docker`.

Designed to be used with the **devcontainers CLI** so every devcontainer you
spin up gets your editor and shell without polluting the project's shared
`devcontainer.json`.

Haskell, LaTeX, and MkDocs are **opt-in** via flags (`--haskell`, `--latex`,
`--mkdocs`). For engine-v2 the devcontainer provides GHC / Cabal / HLS, so
run the core install only. For a standalone workstation run `--all` to
match the original `neo-h.docker` setup.

**Haskell versions** (`--haskell`) are pinned to match
`/vol/engine-v2/.devcontainer/devcontainer.json`: GHC **9.12.2**,
Cabal **3.16.0.0**, HLS **recommended**, plus `hlint` + `fourmolu` +
`cabal-gild` installed via cabal.

## What you get

- **neovim** v0.11.0 + NvChad starter, overlayed with your plugin list, key
  maps, LSP config, conform (format-on-save), autocmds, and chadrc theme
- **tmux** with tpm and your `.tmux.conf`
- **bash** additions: vi-mode, eza/bat/fzf/zoxide/carapace, powerline prompt
  (two-lines theme), nvm sourcing, XDG_RUNTIME_DIR, ansi-welcome banner
- **Node.js** latest LTS via **nvm** (override with `NODE_VERSION=<major>`)
- **Claude Code CLI** (`@anthropic-ai/claude-code`) globally installed
- **CLI tools**: eza, bat, fd, ripgrep, dust, bottom, duf, tldr, trash-cli,
  lazygit, zoxide, carapace, fzf, xclip, tmux, luarocks + jsregexp,
  tree-sitter-cli (pinned to the last GLIBC-2.35-compatible version)

## Install manually

```bash
bash install.sh                              # core only: neovim, tmux, shell, Node (latest LTS via nvm), claude-code
bash install.sh --haskell                    # + GHC 9.12.2 / Cabal 3.16.0.0 / HLS / hlint / fourmolu / cabal-gild / hoogle / fast-tags
bash install.sh --latex                      # + texlive-xetex/luatex/science/extra, latexmk, biber, lhs2tex, zathura + Mason texlab/ltex-ls
bash install.sh --mkdocs                     # + mkdocs + mkdocs-material + puppeteer + headless Chrome
bash install.sh --all                        # all three layers
NODE_VERSION=22 bash install.sh              # pin a specific Node major instead of tracking LTS
```

Re-runnable — every step skips work that's already done. You can run it
once for core and re-run later with any layer flag when you need it.

## Install via devcontainers CLI

The devcontainer CLI clones this repo into `~/dotfiles` and runs the chosen
install script as the container user after `postCreateCommand` finishes.
Plugins compile against the devcontainer's libc, avoiding the arch-mismatch
problem you get when bind-mounting a `~/.local/share/nvim` from another
container.

### Quick-launch scripts

For each layer there's a host-side launcher that runs `devcontainer up` +
`devcontainer exec` with the right flags. `cd` into the project you want to
open, then run one of:

```bash
bash /path/to/dotfiles/core.sh       # core only (matches engine-v2; Haskell comes from the devcontainer)
bash /path/to/dotfiles/haskell.sh    # core + Haskell layer
bash /path/to/dotfiles/latex.sh      # core + LaTeX layer
bash /path/to/dotfiles/mkdocs.sh     # core + MkDocs layer
bash /path/to/dotfiles/all.sh        # core + all three layers
```

You can also pass a workspace folder explicitly: `haskell.sh ~/code/my-repo`.

Each launcher points `--dotfiles-install-command` at a small wrapper
(`install-<layer>.sh`) that invokes `install.sh` with the matching flag —
necessary because the devcontainer CLI's `--dotfiles-install-command`
doesn't forward arguments.

### Manual invocation

If you'd rather spell it out:

```bash
devcontainer up \
  --workspace-folder . \
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles \
  --dotfiles-install-command install.sh \
  --dotfiles-target-path ~/dotfiles

devcontainer exec --workspace-folder . bash
```

Swap `install.sh` for `install-haskell.sh` / `install-latex.sh` /
`install-mkdocs.sh` / `install-all.sh` to add layers.

## Layout

```
.
├── install.sh                — core installer with --haskell / --latex / --mkdocs / --all flags
├── install-{haskell,latex,mkdocs,all}.sh
│                             — wrappers that call install.sh with one flag each
│                               (pointed at by --dotfiles-install-command)
├── {core,haskell,latex,mkdocs,all}.sh
│                             — host-side launchers: `devcontainer up` + `exec` for a given layer
├── bash/bashrc.d/            — sourced from ~/.bashrc in order
├── nvim/
│   ├── init-add.lua          — appended to NvChad's init.lua once
│   ├── fourmolu.yaml         — reference copy of fourmolu config
│   └── lua/                  — symlinked into ~/.config/nvim/lua
├── tmux/tmux.conf
└── powerline/default.twolines.json
```

## What's opt-in / omitted vs. neo-h.docker

| Layer                              | How to get it                                      |
| ---------------------------------- | -------------------------------------------------- |
| GHC, Cabal, HLS, hlint, hoogle, fast-tags, fourmolu, cabal-gild | `--haskell` flag (matches engine-v2 devcontainer) |
| LaTeX (texlive, zathura, biber, …) | `--latex` flag                                     |
| mkdocs, puppeteer, Chrome          | `--mkdocs` flag                                    |
| Claude Code CLI                    | Installed by default                               |
| Python scipy                       | Omitted — unrelated                                |
| SSH keys, anthropic/openai keys    | Omitted — never belongs in a dotfiles repo         |
