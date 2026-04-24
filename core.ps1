#Requires -Version 5.1
<#
.SYNOPSIS
    Bring up the devcontainer with only the core dotfiles layer applied, then
    drop into a bash shell inside the container.
.DESCRIPTION
    Use this launcher for projects like engine-v2 whose own devcontainer
    already provides the Haskell toolchain — the dotfiles just add nvim,
    tmux, shell tools, and claude-code.
.EXAMPLE
    .\core.ps1
    .\core.ps1 C:\code\engine-v2
#>
[CmdletBinding()]
param(
  [string]$Folder = "."
)
$ErrorActionPreference = 'Stop'

devcontainer up `
  --workspace-folder $Folder `
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles `
  --dotfiles-install-command install.sh `
  --dotfiles-target-path ~/dotfiles
if ($LASTEXITCODE -ne 0) { throw "devcontainer up failed (exit $LASTEXITCODE)" }

devcontainer exec --workspace-folder $Folder bash
