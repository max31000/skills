$ErrorActionPreference = "Stop"

function Test-ManagedPath {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Host "OK: $Path"
    } else {
        Write-Host "WARN: missing $Path"
    }
}

Test-ManagedPath (Join-Path $env:USERPROFILE ".claude\settings.json")
Test-ManagedPath (Join-Path $env:USERPROFILE ".claude\skills")
Test-ManagedPath (Join-Path $env:USERPROFILE ".claude\commands")
Test-ManagedPath (Join-Path $env:USERPROFILE ".claude\agents")
Test-ManagedPath (Join-Path $env:USERPROFILE ".claude\commands\bootstrap-status.md")
Test-ManagedPath (Join-Path $env:USERPROFILE ".claude\agents\bootstrap-maintainer.md")
Test-ManagedPath (Join-Path $env:USERPROFILE ".config\opencode\opencode.json")
Test-ManagedPath (Join-Path $env:USERPROFILE ".config\opencode\skills")
Test-ManagedPath (Join-Path $env:USERPROFILE ".config\opencode\commands")
Test-ManagedPath (Join-Path $env:USERPROFILE ".config\opencode\commands\bootstrap-status.md")
