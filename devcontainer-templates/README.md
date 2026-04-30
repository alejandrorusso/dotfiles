# devcontainer-templates

Ready-to-drop `.devcontainer/` templates for new projects. Each stack
ships fragments that pre-bake its toolchain, so container rebuilds
don't reinstall GHC / texlive / Chrome from scratch. Stacks can also
be **combined** — pass multiple flags to get one Dockerfile that
installs both toolchains in a single image.

Stacks:

- **haskell** — GHC 9.12.2, Cabal 3.16.0.0, HLS recommended, plus hlint,
  fourmolu, cabal-gild, fast-tags, hoogle. Pinned to engine-v2's
  toolchain.
- **latex** — texlive (xetex/luatex/science/extra), latexmk, biber,
  lhs2tex, zathura, pdftk, evince, inkscape.
- **mkdocs** — mkdocs + mkdocs-material + plugins, puppeteer + Google
  Chrome for `mkdocs-page-pdf`.

## Usage

The launcher script lives at the repo root (`create-devcontainer.sh` /
`create-devcontainer.ps1`); it reads the fragments out of this folder.
`cd` into the new project, then:

**bash**
```bash
bash /path/to/dotfiles/create-devcontainer.sh --haskell
bash /path/to/dotfiles/create-devcontainer.sh --latex
bash /path/to/dotfiles/create-devcontainer.sh --haskell --latex
```

**PowerShell**
```powershell
C:\path\to\dotfiles\create-devcontainer.ps1 -Haskell
C:\path\to\dotfiles\create-devcontainer.ps1 -Latex
C:\path\to\dotfiles\create-devcontainer.ps1 -Haskell -Latex
```

This creates `./.devcontainer/devcontainer.json` and `./.devcontainer/Dockerfile`.
Add `--force` (bash) / `-Force` (pwsh) to overwrite an existing `.devcontainer/`.

You can also pass an explicit target folder:

```bash
bash create-devcontainer.sh --haskell ~/code/new-project
```

## Composing with dotfiles

The templates are toolchain-only. To overlay your shell, neovim, tmux,
and CLI tools, use `launch-devcontainer.sh` / `launch-devcontainer.ps1`
to bring the container up:

```bash
cd /path/to/new-project
bash /path/to/dotfiles/launch-devcontainer.sh     # devcontainer up + dotfiles overlay + exec bash
```

## How fragments compose

Each stack is split into two Dockerfile fragments:

- `<stack>/root.dockerfile` — runs **as root** (apt installs, repo
  setup). Concatenated before the `vscode` user is created.
- `<stack>/user.dockerfile` — runs **as the `vscode` user** (per-user
  toolchain installs like `ghcup`, `pip --user`, `npm install`).
  Concatenated after `USER vscode`.

The shared parts (FROM, locale, base apt packages, vscode user
creation) live in `fragments/base-header.dockerfile` and
`fragments/base-user.dockerfile`. The script assembles them in this
order:

```
fragments/base-header.dockerfile
<stack-1>/root.dockerfile
<stack-2>/root.dockerfile
...
fragments/base-user.dockerfile
<stack-1>/user.dockerfile
<stack-2>/user.dockerfile
...
```

Stack order is fixed (haskell → latex → mkdocs) regardless of the
flag order on the command line, so the docker layer cache is stable
across invocations.

## Editing a template

Each stack lives in its own folder. Edit `<stack>/root.dockerfile`
to change apt packages, or `<stack>/user.dockerfile` to change the
user-level toolchain, then either rebuild the container in projects
already using that template (`Dev Containers: Rebuild Container`) or
re-run `create-devcontainer.sh --force` to copy the new files in.

## Notes

- **Haskell version pinning** lives in `haskell/user.dockerfile` as
  `ARG`s (`GHC_VERSION`, `CABAL_VERSION`, `HLS_VERSION`). Override
  per-project via `build.args` in the project's `devcontainer.json`.
- **LaTeX Mason packages** (`ltex-ls`, `texlab`) are not pre-installed —
  they belong to the nvim setup. Run `:MasonInstall ltex-ls texlab`
  once after first launch.
- **MkDocs Node.js**: `mkdocs/root.dockerfile` installs Node 20 from
  NodeSource so puppeteer can be baked into the image. The dotfiles
  overlay later installs nvm with the latest LTS; both coexist and
  nvm takes precedence in interactive shells.
- **devcontainer.json merging is shallow.** When combining stacks, the
  script copies the first selected stack's `devcontainer.json` and
  rewrites the `name` field. All three stacks currently ship
  near-identical JSON, so this is fine — but if you ever add per-stack
  `customizations.vscode.extensions`, the script will need a real JSON
  merge.
