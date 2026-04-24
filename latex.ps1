#Requires -Version 5.1
<#
.SYNOPSIS
    Bring up the devcontainer with the LaTeX layer of the dotfiles applied
    (texlive-xetex/luatex/science/extra, latexmk, biber, lhs2tex, zathura,
    Mason texlab + ltex-ls), then drop into a bash shell inside the container.
.EXAMPLE
    .\latex.ps1
    .\latex.ps1 C:\code\paper
#>
[CmdletBinding()]
param(
  [string]$Folder = "."
)
$ErrorActionPreference = 'Stop'

devcontainer up `
  --workspace-folder $Folder `
  --dotfiles-repository https://github.com/alejandrorusso/dotfiles `
  --dotfiles-install-command install-latex.sh `
  --dotfiles-target-path ~/dotfiles
if ($LASTEXITCODE -ne 0) { throw "devcontainer up failed (exit $LASTEXITCODE)" }

devcontainer exec --workspace-folder $Folder bash
