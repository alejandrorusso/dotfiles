#Requires -Version 5.1
<#
.SYNOPSIS
    Bring up the devcontainer with the MkDocs layer of the dotfiles applied
    (mkdocs + mkdocs-material + puppeteer + headless Chrome for PDF export),
    then drop into a bash shell inside the container.
.EXAMPLE
    .\mkdocs.ps1
    .\mkdocs.ps1 C:\code\docs
#>
[CmdletBinding()]
param(
  [string]$Folder = "."
)
$ErrorActionPreference = 'Stop'

devcontainer up `
  --workspace-folder $Folder `
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles `
  --dotfiles-install-command install-mkdocs.sh `
  --dotfiles-target-path ~/dotfiles
if ($LASTEXITCODE -ne 0) { throw "devcontainer up failed (exit $LASTEXITCODE)" }

devcontainer exec --workspace-folder $Folder bash
