$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir
$LogDir = if ($env:BOOTSTRAP_LOG_DIR) { $env:BOOTSTRAP_LOG_DIR } else { Join-Path $RootDir ".bootstrap-logs\manual" }

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "FAIL: required dependency `python` is unavailable."
    Write-Host "Bootstrap cannot continue because tool planning depends on it."
    exit 1
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$ResultFile = Join-Path $LogDir "install-tools.json"
& python (Join-Path $ScriptDir "bootstrap_deps.py") install-tools --root $RootDir --log-dir $LogDir > $ResultFile
$ExitCode = $LASTEXITCODE

$payload = Get-Content $ResultFile -Raw | ConvertFrom-Json
foreach ($line in $payload.lines) {
    Write-Host $line
}

exit $ExitCode
