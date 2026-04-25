# dotfiles

Personal shell + neovim + tmux setup, designed to overlay onto any
devcontainer. The project's own `devcontainer.json` provides the language
toolchain (Haskell, LaTeX, etc.) — this repo just adds your editor and
shell on top.

Use it with the **devcontainers CLI** so every container you spin up gets
your config without polluting the project's shared `devcontainer.json`.

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
bash install.sh                              # core install
NODE_VERSION=22 bash install.sh              # pin a specific Node major instead of tracking LTS
```

Re-runnable — every step skips work that's already done.

## Install via devcontainers CLI

The devcontainer CLI clones this repo into `~/dotfiles` and runs
`install.sh` as the container user after `postCreateCommand` finishes.
Plugins compile against the devcontainer's libc, avoiding the arch-mismatch
problem you get when bind-mounting a `~/.local/share/nvim` from another
container.

### Quick-launch script

`core.sh` (bash) and `core.ps1` (PowerShell) are host-side launchers that
run `devcontainer up` + `devcontainer exec` with the right flags. `cd`
into the project you want to open, then run one of:

**bash**
```bash
bash /path/to/dotfiles/core.sh
```

**PowerShell**
```powershell
C:\path\to\dotfiles\core.ps1
```

You can also pass a workspace folder explicitly: `core.sh ~/code/my-repo`
or `.\core.ps1 C:\code\my-repo`.

> **PowerShell execution policy.** If you hit `cannot be loaded because
> running scripts is disabled`, run once:
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

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

## Layout

```
.
├── install.sh                — core installer
├── core.sh / core.ps1        — host-side launchers (bash / PowerShell)
├── list-devcontainers.sh / .ps1
│                             — list devcontainers visible to the CLI
├── bash/bashrc.d/            — sourced from ~/.bashrc in order
├── nvim/
│   ├── init-add.lua          — appended to NvChad's init.lua once
│   ├── fourmolu.yaml         — reference copy of fourmolu config
│   └── lua/                  — symlinked into ~/.config/nvim/lua
├── tmux/tmux.conf
└── powerline/default.twolines.json
```

## What's not in here

| Concern                            | Where to put it                                    |
| ---------------------------------- | -------------------------------------------------- |
| Language toolchains (GHC, texlive, mkdocs, …) | The project's own `.devcontainer`        |
| SSH keys, anthropic/openai keys    | Never in a dotfiles repo                           |
