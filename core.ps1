#Requires -Version 5.1
<#
.SYNOPSIS
    Bring up the devcontainer, overlay the dotfiles, drop into a bash shell.
.DESCRIPTION
    The dotfiles add nvim, tmux, shell tools, and claude-code on top of
    whatever the project's devcontainer already provides (language
    toolchains belong in the project's own devcontainer.json).
.EXAMPLE
    .\core.ps1
    .\core.ps1 C:\code\my-project
#>
[CmdletBinding()]
param(
  [string]$Folder = "."
)
$ErrorActionPreference = 'Stop'

devcontainer up `
  --workspace-folder $Folder `
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles `
  --dotfiles-target-path ~/dotfiles
if ($LASTEXITCODE -ne 0) { throw "devcontainer up failed (exit $LASTEXITCODE)" }

# --dotfiles-install-command is unreliable: the CLI silently skips it under
# some Docker Desktop / CLI version combos, leaving a clone-only install with
# no bashrc wiring. Run the installer explicitly so failures surface.
# install.sh is idempotent.
devcontainer exec --workspace-folder $Folder bash -lc 'bash ~/dotfiles/install.sh'
if ($LASTEXITCODE -ne 0) { throw "dotfiles install.sh failed (exit $LASTEXITCODE)" }

devcontainer exec --workspace-folder $Folder bash
