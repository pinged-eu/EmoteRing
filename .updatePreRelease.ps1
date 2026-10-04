#!/usr/bin/env pwsh
#Requires -Version 7
# Project-specific hook, executed by updateRelease.ps1 right before commit/tag.
param(
    [Parameter(Mandatory = $true)]
    [string]$Tag
)

Write-Host "Running pre-release hook for tag $Tag.."

$version = $Tag -replace '^v', ''

# Stamp the release version into Addon.version in Data.lua
$dataFile = "Data.lua"
if (Test-Path $dataFile) {
    $content = Get-Content -Path $dataFile -Raw
    $updated = $content -replace 'Addon\.version\s*=\s*"[^"]*"', "Addon.version = `"$version`""
    if ($updated -eq $content) {
        throw "Could not find Addon.version assignment in $dataFile, aborting release."
    }
    Set-Content -Path $dataFile -Value $updated -NoNewline
    git add $dataFile
}

# Example: run project-specific checks before the release is committed
# npm run build
# if ($LASTEXITCODE) { throw "Build failed, aborting release." }