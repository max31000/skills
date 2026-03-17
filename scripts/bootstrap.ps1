$ErrorActionPreference = "Stop"

param(
    [switch]$OverwriteSkills
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir
$LogDir = Join-Path $RootDir ".bootstrap-logs\$(Get-Date -Format 'yyyyMMddTHHmmss')"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "FAIL: required dependency `python` is unavailable."
    Write-Host "Bootstrap cannot continue because preflight and config rendering depend on it."
    exit 1
}

$PreflightFile = Join-Path $LogDir "preflight.json"
& python (Join-Path $ScriptDir "bootstrap_deps.py") preflight --root $RootDir --log-dir $LogDir > $PreflightFile
$preflight = Get-Content $PreflightFile -Raw | ConvertFrom-Json
foreach ($line in $preflight.lines) {
    Write-Host $line
}
foreach ($warning in $preflight.warnings) {
    Write-Host "warn $($warning.name)"
}

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Label"
    & $Action
}

${env:BOOTSTRAP_LOG_DIR} = $LogDir
${env:BOOTSTRAP_NONINTERACTIVE} = "1"
Invoke-Step "Installing packages" { & (Join-Path $ScriptDir "install-packages.ps1") }
Invoke-Step "Installing tool versions" { & (Join-Path $ScriptDir "install-tools.ps1") }
Invoke-Step "Rendering configs" { python (Join-Path $ScriptDir "render-configs.py") --root $RootDir }
if ($OverwriteSkills) {
    ${env:INSTALL_SKILLS_OVERWRITE} = "1"
    Invoke-Step "Installing skills" { & (Join-Path $ScriptDir "install-skills.ps1") -Overwrite }
} else {
    Invoke-Step "Installing skills" { & (Join-Path $ScriptDir "install-skills.ps1") }
}
Invoke-Step "Installing plugins" { & (Join-Path $ScriptDir "install-plugins.ps1") }
Invoke-Step "Verifying installation" { & (Join-Path $ScriptDir "verify-install.ps1") }

Write-Host ""
Write-Host "Bootstrap complete."
