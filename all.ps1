#Requires -Version 5.1
<#
.SYNOPSIS
    Bring up the devcontainer with all dotfiles layers applied
    (Haskell + LaTeX + MkDocs), then drop into a bash shell inside the
    container.
.EXAMPLE
    .\all.ps1
    .\all.ps1 C:\code\my-project
#>
[CmdletBinding()]
param(
  [string]$Folder = "."
)
$ErrorActionPreference = 'Stop'

devcontainer up `
  --workspace-folder $Folder `
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles `
  --dotfiles-install-command install-all.sh `
  --dotfiles-target-path ~/dotfiles
if ($LASTEXITCODE -ne 0) { throw "devcontainer up failed (exit $LASTEXITCODE)" }

devcontainer exec --workspace-folder $Folder bash
