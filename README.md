# dotfiles

Personal shell + neovim + tmux setup, extracted from
`/vol/docker-nvim-haskell-latex-LLM/dockerfiles/neo-h.docker`.

Designed to be used with the **devcontainers CLI** so every devcontainer you
spin up gets your editor and shell without polluting the project's shared
`devcontainer.json`.

Haskell toolchain and LaTeX are **intentionally excluded** — the engine-v2
devcontainer installs GHC / Cabal / HLS itself, and LaTeX isn't needed there.

## What you get

- **neovim** v0.11.0 + NvChad starter, overlayed with your plugin list, key
  maps, LSP config, conform (format-on-save), autocmds, and chadrc theme
- **tmux** with tpm and your `.tmux.conf`
- **bash** additions: vi-mode, eza/bat/fzf/zoxide/carapace, powerline prompt
  (two-lines theme), XDG_RUNTIME_DIR, ansi-welcome banner
- **CLI tools**: eza, bat, fd, ripgrep, dust, bottom, duf, tldr, trash-cli,
  lazygit, zoxide, carapace, fzf, xclip, tmux, luarocks + jsregexp,
  tree-sitter-cli (pinned to the last GLIBC-2.35-compatible version)

## Install manually

```bash
bash install.sh
```

Re-runnable — every step skips work that's already done.

## Install via devcontainers CLI

Push this repo to GitHub, then launch any devcontainer with:

```bash
devcontainer up \
  --workspace-folder . \
  --dotfiles-repository https://github.com/<you>/dotfiles \
  --dotfiles-install-command install.sh \
  --dotfiles-target-path ~/dotfiles
```

The devcontainer CLI clones this repo into `~/dotfiles` and runs `install.sh`
as the container user after `postCreateCommand` finishes. Plugins compile
against the devcontainer's libc, avoiding the arch-mismatch problem you get
when bind-mounting a `~/.local/share/nvim` from another container.

## Layout

```
.
├── install.sh
├── bash/bashrc.d/      — sourced from ~/.bashrc in order
├── nvim/
│   ├── init-add.lua    — appended to NvChad's init.lua once
│   ├── fourmolu.yaml   — copied next to Mason's fourmolu binary
│   └── lua/            — symlinked into ~/.config/nvim/lua
├── tmux/tmux.conf
└── powerline/default.twolines.json
```

## What's skipped vs. neo-h.docker

| Skipped                       | Why                                           |
| ----------------------------- | --------------------------------------------- |
| GHC, Cabal, HLS, hoogle       | engine-v2 devcontainer provides them          |
| LaTeX (texlive, zathura, …)   | Not needed in engine-v2                       |
| mkdocs, puppeteer, Chrome     | Unrelated to editing                          |
| Python scipy                  | Unrelated                                     |
| SSH keys, anthropic/openai keys | Private — never belongs in a dotfiles repo  |
| claude-code npm               | Install separately if wanted                  |
