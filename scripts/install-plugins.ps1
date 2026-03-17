$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir
$ManifestPath = Join-Path $RootDir "manifest\plugins\plugins.manifest.json"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Skipping plugin install: python not found."
    exit 0
}

python (Join-Path $ScriptDir "plugin_backend.py") --manifest $ManifestPath --home $env:USERPROFILE
