$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$OverwriteSkills = $false

foreach ($arg in $args) {
    switch ($arg) {
        "-OverwriteSkills" { $OverwriteSkills = $true }
        "--overwrite-skills" { $OverwriteSkills = $true }
        "-h" {
            Write-Host "Usage: powershell -ExecutionPolicy Bypass -File bootstrap.ps1 [-OverwriteSkills]"
            exit 0
        }
        "--help" {
            Write-Host "Usage: powershell -ExecutionPolicy Bypass -File bootstrap.ps1 [-OverwriteSkills]"
            exit 0
        }
        default {
            Write-Host "Unknown option: $arg"
            exit 1
        }
    }
}

if ($OverwriteSkills) {
    & (Join-Path $ScriptDir "scripts\bootstrap.ps1") -OverwriteSkills
} else {
    & (Join-Path $ScriptDir "scripts\bootstrap.ps1")
}
