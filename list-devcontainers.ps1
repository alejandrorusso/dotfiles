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

$dockerArgs = @("ps", "--filter", "label=devcontainer.local_folder", "--format", "{{json .}}")
if ($All) { $dockerArgs = @("ps", "-a", "--filter", "label=devcontainer.local_folder", "--format", "{{json .}}") }

$rows = & docker @dockerArgs | ForEach-Object { $_ | ConvertFrom-Json }

$rows | Format-Table -AutoSize @(
  @{ Label = "CONTAINER ID"; Expression = { $_.ID } }
  @{ Label = "NAME";         Expression = { $_.Names } }
  @{ Label = "STATUS";       Expression = { $_.Status } }
  @{ Label = "WORKSPACE";    Expression = { $_.Labels.'devcontainer.local_folder' } }
)
