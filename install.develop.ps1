#!/usr/bin/env pwsh
# This script installs the addon in development mode. Use -Information or -Verbose for logging.
param(
  [string]$wowDirectory = "C:\BNetGames\World of Warcraft",
  [string]$linkType="SymbolicLink" # can be SymbolicLink or Junction
)

# create method Test-IsAdmin; returns boolean
function Test-IsAdmin
{
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# this directory here
if ($PSScriptRoot) {
  $myAddonDir = $PSScriptRoot
} else {
  $myAddonDir = Get-Location
}

# check if directory exists
if (!(Test-Path "$wowDirectory"))
{
  Write-Error "WoW Directory $wowDirectory does not exist!"
} else
{
  $flavors = @("_retail_", "_classic_", "_classic_era_", "_ptr_", "_classic_beta_", "_beta_", "_anniversary_", "_forever_")
  foreach ($flavor in $flavors)
  {
    # check if flavor directory exists
    if (!(Test-Path "$wowDirectory\$flavor"))
    {
      Write-Host "WoW Directory $wowDirectory with $flavor flavor does not exist!"
      continue
    }
    $addonDir = "$wowDirectory\$flavor\Interface\AddOns\EmoteRing"
    if (Test-Path $addonDir)
    {
      Write-Host "EmoteRing addon link already exists in $addonDir"
    } else
    {
      # check if user has administrator privileges
      if (-not (Test-IsAdmin))
      {
        Write-Error "You need administrator privileges to create symbolic links!"
      } else
      {
        # create link
        Write-Verbose "Creating link of type $linkType for EmoteRing addon..."
        New-Item -ItemType $linkType -Path "$wowDirectory\$flavor\Interface\AddOns\EmoteRing" -Target $myAddonDir
        Write-Host "Link in $flavor created successfully!"
      }
    }
  }
}
