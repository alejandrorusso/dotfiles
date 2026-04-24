#Requires -Version 5.1
<#
.SYNOPSIS
    List Docker containers that were created by devcontainer CLI or VS Code.
.EXAMPLE
    .\list-devcontainers.ps1
    .\list-devcontainers.ps1 -All   # include stopped containers
#>
[CmdletBinding()]
param(
  [switch]$All
)

$filter = @("--filter", "label=devcontainer.local_folder")
$format = "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Label `"devcontainer.local_folder`"}}"

$args = @("ps")
if ($All) { $args += "-a" }
$args += $filter
$args += @("--format", $format)

docker @args
