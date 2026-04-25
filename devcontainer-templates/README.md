# devcontainer-templates

Ready-to-drop `.devcontainer/` templates for new projects. Each stack
ships a Dockerfile that pre-bakes its toolchain, so container rebuilds
don't reinstall GHC / texlive / Chrome from scratch.

Stacks:

- **haskell** — GHC 9.12.2, Cabal 3.16.0.0, HLS recommended, plus hlint,
  fourmolu, cabal-gild, fast-tags, hoogle. Pinned to engine-v2's
  toolchain.
- **latex** — texlive (xetex/luatex/science/extra), latexmk, biber,
  lhs2tex, zathura, pdftk, evince, inkscape.
- **mkdocs** — mkdocs + mkdocs-material + plugins, puppeteer + Google
  Chrome for `mkdocs-page-pdf`.

## Usage

`cd` into the new project, then:

**bash**
```bash
bash /path/to/dotfiles/devcontainer-templates/create-devcontainer.sh --haskell
bash /path/to/dotfiles/devcontainer-templates/create-devcontainer.sh --latex
bash /path/to/dotfiles/devcontainer-templates/create-devcontainer.sh --mkdocs
```

**PowerShell**
```powershell
C:\path\to\dotfiles\devcontainer-templates\create-devcontainer.ps1 -Haskell
C:\path\to\dotfiles\devcontainer-templates\create-devcontainer.ps1 -Latex
C:\path\to\dotfiles\devcontainer-templates\create-devcontainer.ps1 -MkDocs
```

This creates `./.devcontainer/devcontainer.json` and `./.devcontainer/Dockerfile`.
Add `--force` (bash) / `-Force` (pwsh) to overwrite an existing `.devcontainer/`.

You can also pass an explicit target folder:

```bash
bash create-devcontainer.sh --haskell ~/code/new-project
```

## Composing with dotfiles

The templates are toolchain-only. To overlay your shell, neovim, tmux,
and CLI tools, use `core.sh` / `core.ps1` to bring the container up:

```bash
cd /path/to/new-project
bash /path/to/dotfiles/core.sh     # devcontainer up + dotfiles overlay + exec bash
```

## Editing a template

Each stack lives in its own folder. Edit the `Dockerfile` to change the
toolchain, then either rebuild the container in projects already using
that template (`Dev Containers: Rebuild Container`) or re-run
`create-devcontainer.sh --force` to copy the new files in.

## Notes

- **Haskell version pinning** lives in the Dockerfile as `ARG`s
  (`GHC_VERSION`, `CABAL_VERSION`, `HLS_VERSION`). Override per-project
  via `build.args` in the project's `devcontainer.json`.
- **LaTeX Mason packages** (`ltex-ls`, `texlab`) are not pre-installed —
  they belong to the nvim setup. Run `:MasonInstall ltex-ls texlab`
  once after first launch.
- **MkDocs Node.js**: the Dockerfile installs Node 20 from NodeSource so
  puppeteer can be baked into the image. The dotfiles overlay later
  installs nvm with the latest LTS; both coexist and nvm takes
  precedence in interactive shells.
