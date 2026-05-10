#Requires -Version 5.1
<#
.SYNOPSIS
    Scaffold a .devcontainer/ folder by composing one or more language-stack
    fragments shipped in this repo.
.DESCRIPTION
    Concatenates fragments under devcontainer-templates/ into
    <target>/.devcontainer/Dockerfile and copies a devcontainer.json. Pass
    multiple stack switches to combine stacks (e.g. -Haskell -Latex). Refuses
    to overwrite an existing .devcontainer/ unless -Force is passed.
.EXAMPLE
    .\create-devcontainer.ps1 -Haskell
    .\create-devcontainer.ps1 -Haskell -Latex
    .\create-devcontainer.ps1 -MkDocs C:\code\new-project -Force
#>
param(
  [switch]$Haskell,
  [switch]$Latex,
  [switch]$MkDocs,
  [Parameter(Position = 0)] [string]$Folder = ".",
  [switch]$Force
)
$ErrorActionPreference = 'Stop'

# Deterministic order regardless of how flags were passed, so the layer cache
# is stable across invocations.
$stacks = @()
if ($Haskell) { $stacks += 'haskell' }
if ($Latex)   { $stacks += 'latex' }
if ($MkDocs)  { $stacks += 'mkdocs' }
if ($stacks.Count -eq 0) {
  throw "specify at least one of -Haskell -Latex -MkDocs"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tplDir    = Join-Path $scriptDir "devcontainer-templates"
$fragDir   = Join-Path $tplDir "fragments"

if (-not (Test-Path $Folder -PathType Container)) {
  throw "target folder does not exist: $Folder"
}
# Resolve to absolute: [System.IO.File] uses .NET's CWD (often system32),
# not PowerShell's location, so relative paths land in the wrong place.
$Folder    = (Resolve-Path -LiteralPath $Folder).Path
$dest      = Join-Path $Folder ".devcontainer"
if ((Test-Path $dest) -and -not $Force) {
  throw "$dest already exists (re-run with -Force to overwrite)"
}

foreach ($s in $stacks) {
  foreach ($f in @("root.dockerfile", "user.dockerfile")) {
    $p = Join-Path $tplDir "$s/$f"
    if (-not (Test-Path $p -PathType Leaf)) { throw "fragment not found: $p" }
  }
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Assemble Dockerfile: base header, all root fragments, base user, all user fragments.
$parts  = @(Join-Path $fragDir "base-header.dockerfile")
$parts += $stacks | ForEach-Object { Join-Path $tplDir "$_/root.dockerfile" }
$parts += Join-Path $fragDir "base-user.dockerfile"
$parts += $stacks | ForEach-Object { Join-Path $tplDir "$_/user.dockerfile" }

# Concatenate, terminating each fragment with a newline so adjacent fragments
# don't collide on the same line. -Encoding utf8 is required: PS 5.1's default
# is the system ANSI codepage, which mojibakes UTF-8 fragments on read.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$buf = New-Object System.Text.StringBuilder
foreach ($p in $parts) {
  $piece = Get-Content $p -Raw -Encoding utf8
  if ($null -ne $piece) { [void]$buf.Append($piece) }
  if ($null -eq $piece -or -not $piece.EndsWith("`n")) { [void]$buf.Append("`n") }
}

# Write as UTF-8 without BOM. Set-Content's PS 5.1 default is UTF-16 LE
# (breaks docker build) and -Encoding ascii mangles non-ASCII chars to "?".
[System.IO.File]::WriteAllText((Join-Path $dest "Dockerfile"), $buf.ToString(), $utf8NoBom)

# devcontainer.json: take the first stack's and rewrite the "name" field.
$primary = $stacks[0]
$jsonSrc = Join-Path $tplDir "$primary/devcontainer.json"
$json    = Get-Content $jsonSrc -Raw -Encoding utf8
$json    = $json -replace '"name":\s*"[^"]*"', "`"name`": `"$($stacks -join '+')`""
[System.IO.File]::WriteAllText((Join-Path $dest "devcontainer.json"), $json, $utf8NoBom)

Write-Host "Created $dest\ from stacks: $($stacks -join ', ')"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  cd $Folder"
Write-Host "  $scriptDir\launch-devcontainer.ps1        # bring up + overlay your dotfiles"
