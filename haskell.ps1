#Requires -Version 5.1
<#
.SYNOPSIS
    Bring up the devcontainer with the Haskell layer of the dotfiles applied
    (GHC 9.12.2 / Cabal 3.16.0.0 / HLS / hlint / fourmolu / cabal-gild /
    hoogle / fast-tags), then drop into a bash shell inside the container.
.EXAMPLE
    .\haskell.ps1
    .\haskell.ps1 C:\code\my-haskell-project
#>
[CmdletBinding()]
param(
  [string]$Folder = "."
)
$ErrorActionPreference = 'Stop'

devcontainer up `
  --workspace-folder $Folder `
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles `
  --dotfiles-install-command install-haskell.sh `
  --dotfiles-target-path ~/dotfiles
if ($LASTEXITCODE -ne 0) { throw "devcontainer up failed (exit $LASTEXITCODE)" }

devcontainer exec --workspace-folder $Folder bash
