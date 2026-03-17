$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Overwrite = $false

foreach ($arg in $args) {
    switch ($arg) {
        "-Overwrite" { $Overwrite = $true }
        "--overwrite" { $Overwrite = $true }
        "-h" {
            Write-Host "Usage: powershell -ExecutionPolicy Bypass -File install-skills.ps1 [-Overwrite]"
            exit 0
        }
        "--help" {
            Write-Host "Usage: powershell -ExecutionPolicy Bypass -File install-skills.ps1 [-Overwrite]"
            exit 0
        }
        default {
            Write-Host "Unknown option: $arg"
            exit 1
        }
    }
}

if ($Overwrite) {
    & (Join-Path $ScriptDir "scripts\install-skills.ps1") -Overwrite
} else {
    & (Join-Path $ScriptDir "scripts\install-skills.ps1")
}
