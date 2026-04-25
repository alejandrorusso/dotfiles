#Requires -Version 5.1
<#
.SYNOPSIS
    Scaffold a .devcontainer/ folder from one of the language-stack
    templates shipped in this repo.
.DESCRIPTION
    Copies the chosen stack's Dockerfile and devcontainer.json into
    <target>/.devcontainer/. Refuses to overwrite an existing
    .devcontainer/ unless -Force is passed.
.EXAMPLE
    .\create-devcontainer.ps1 -Haskell
    .\create-devcontainer.ps1 -Latex C:\code\new-project
    .\create-devcontainer.ps1 -MkDocs -Force
#>
[CmdletBinding(DefaultParameterSetName = 'Haskell')]
param(
  [Parameter(ParameterSetName = 'Haskell', Mandatory = $true)] [switch]$Haskell,
  [Parameter(ParameterSetName = 'Latex',   Mandatory = $true)] [switch]$Latex,
  [Parameter(ParameterSetName = 'MkDocs',  Mandatory = $true)] [switch]$MkDocs,

  [Parameter(Position = 0)] [string]$Folder = ".",
  [switch]$Force
)
$ErrorActionPreference = 'Stop'

$stack = switch ($PSCmdlet.ParameterSetName) {
  'Haskell' { 'haskell' }
  'Latex'   { 'latex' }
  'MkDocs'  { 'mkdocs' }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$src       = Join-Path $scriptDir $stack
$dest      = Join-Path $Folder ".devcontainer"

if (-not (Test-Path $src -PathType Container)) {
  throw "template not found: $src"
}
if (-not (Test-Path $Folder -PathType Container)) {
  throw "target folder does not exist: $Folder"
}

if ((Test-Path $dest) -and -not $Force) {
  throw "$dest already exists (re-run with -Force to overwrite)"
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $src "devcontainer.json") (Join-Path $dest "devcontainer.json") -Force
Copy-Item (Join-Path $src "Dockerfile")        (Join-Path $dest "Dockerfile")        -Force

Write-Host "Created $dest\ from $stack template"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  cd $Folder"
Write-Host "  $scriptDir\..\core.ps1        # bring up + overlay your dotfiles"
