# ============================================================================
#  Universal Agent Skills Installer (PowerShell)
#  Works on: Windows 10+ (PowerShell 5.1+)
#  Installs to: ~/.claude/skills/  (primary, seen by Claude Code + OpenCode)
#  Copies to:   ~/.config/opencode/skills/  (OpenCode native path)
#
#  Configuration:
#    repos.conf      — external GitHub repos to clone skills from
#    custom-skills/  — local skill definitions (SKILL.md files)
#
#  Note: anthropic-skills:* (pdf, xlsx, pptx, docx, schedule) are built-in
#  to Claude Code and do not require manual installation here.
#
#  Usage: powershell -ExecutionPolicy Bypass -File install-skills.ps1
# ============================================================================

$ErrorActionPreference = "Stop"

param(
    [switch]$Overwrite
)

# ── Script directory ────────────────────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir    = Split-Path -Parent $ScriptDir
$ConfFile   = Join-Path $RootDir "manifest\skills\repos.conf"
$CustomDir  = Join-Path $RootDir "custom-skills"

# ── Colors / helpers ────────────────────────────────────────────────────────
function Write-Info  { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Msg) Write-Host "[FAIL]  $Msg" -ForegroundColor Red; exit 1 }

# ── Pre-flight checks ──────────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Fail "git is not installed" }
if (-not (Test-Path $ConfFile))  { Write-Fail "repos.conf not found at $ConfFile" }
if (-not (Test-Path $CustomDir)) { Write-Fail "custom-skills/ directory not found at $CustomDir" }

# ── Build ALL_SKILLS dynamically from config ────────────────────────────────
$AllSkills   = [System.Collections.Generic.List[string]]::new()
$SkillSource = [System.Collections.Generic.List[string]]::new()

$RepoEntries = @()
foreach ($line in Get-Content $ConfFile -Encoding UTF8) {
    $line = $line.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { continue }
    $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
    $entry = [PSCustomObject]@{
        Url       = $parts[0]
        CloneName = $parts[1]
        SubDir    = $parts[2]
        Skills    = $parts[3].Split(',') | ForEach-Object { $_.Trim() }
    }
    $RepoEntries += $entry
    foreach ($s in $entry.Skills) {
        $AllSkills.Add($s)
        $SkillSource.Add($entry.CloneName)
    }
}

foreach ($skillMd in Get-ChildItem -Path $CustomDir -Filter "SKILL.md" -Recurse -Depth 1) {
    $skillName = $skillMd.Directory.Name
    $AllSkills.Add($skillName)
    $SkillSource.Add("custom")
}

# ── Paths ───────────────────────────────────────────────────────────────────
$SkillsDir  = Join-Path $env:USERPROFILE ".claude\skills"
$OpenCodeDir = Join-Path $env:USERPROFILE ".config\opencode\skills"
$TmpDir     = Join-Path ([System.IO.Path]::GetTempPath()) "skills-install-$([System.IO.Path]::GetRandomFileName())"

New-Item -ItemType Directory -Path $SkillsDir   -Force | Out-Null
New-Item -ItemType Directory -Path $OpenCodeDir  -Force | Out-Null
New-Item -ItemType Directory -Path $TmpDir       -Force | Out-Null

Write-Info "Skills directory:   $SkillsDir"
Write-Info "OpenCode copy:      $OpenCodeDir"
Write-Host ""

# ── Overwrite check ────────────────────────────────────────────────────────
$existing = @()
foreach ($s in $AllSkills) {
    $p = Join-Path $SkillsDir "$s\SKILL.md"
    if (Test-Path $p) { $existing += $s }
}

if ($existing.Count -gt 0) {
    Write-Host "Already installed ($($existing.Count)):" -ForegroundColor Yellow
    foreach ($s in $existing) { Write-Host "    $s" }
    Write-Host ""

    $nonInteractive = $env:BOOTSTRAP_NONINTERACTIVE -match '^(1|true|TRUE|yes|YES)$' -or [Console]::IsInputRedirected
    if ($Overwrite -or $env:INSTALL_SKILLS_OVERWRITE -match '^(1|true|TRUE|yes|YES)$') {
        $Overwrite = $true
        Write-Ok "Existing skills will be overwritten."
    } elseif ($nonInteractive) {
        Write-Info "Non-interactive mode detected. Existing skills will be skipped."
    } else {
        $answer = Read-Host "Overwrite existing skills? [y/N]"
        if ($answer -match "^[Yy]$") {
            $Overwrite = $true
            Write-Ok "Existing skills will be overwritten."
        } else {
            Write-Info "Existing skills will be skipped. Only new skills will be installed."
        }
    }
    Write-Host ""
}

# ── Helper: clone a repo and copy specific skill folders ──────────────────
function Install-FromRepo {
    param(
        [string]$RepoUrl,
        [string]$RepoName,
        [string]$SrcSubDir,
        [string[]]$SkillDirs
    )

    Write-Info "Cloning $RepoName..."
    $clonePath = Join-Path $TmpDir $RepoName
    $result = & git clone --depth 1 --quiet $RepoUrl $clonePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Failed to clone $RepoName — skipping"
        return
    }

    $basePath = $clonePath
    if ($SrcSubDir -ne ".") {
        $basePath = Join-Path $clonePath $SrcSubDir
    }

    foreach ($skill in $SkillDirs) {
        $destPath = Join-Path $SkillsDir $skill
        $destMd   = Join-Path $destPath "SKILL.md"

        if ((Test-Path $destMd) -and (-not $Overwrite)) {
            Write-Info "  ~ $skill (skipped)"
            continue
        }

        # Try configured path first, then fallback to "skills/" subdir
        $srcSkill = Join-Path $basePath $skill
        $srcMd    = Join-Path $srcSkill "SKILL.md"
        $fallback = Join-Path $clonePath "skills\$skill"
        $fallMd   = Join-Path $fallback "SKILL.md"

        if ((Test-Path $srcMd)) {
            if (Test-Path $destPath) { Remove-Item -Path $destPath -Recurse -Force }
            Copy-Item -Path $srcSkill -Destination $destPath -Recurse -Force
            Write-Ok "  + $skill"
        } elseif ((Test-Path $fallMd)) {
            if (Test-Path $destPath) { Remove-Item -Path $destPath -Recurse -Force }
            Copy-Item -Path $fallback -Destination $destPath -Recurse -Force
            Write-Ok "  + $skill (from skills/)"
        } else {
            Write-Warn "  ! $skill — SKILL.md not found in repo, skipping"
        }
    }
}

# ============================================================================
#  1. INSTALL FROM EXTERNAL REPOS (repos.conf)
# ============================================================================
try {
    foreach ($entry in $RepoEntries) {
        Write-Host "--- $($entry.CloneName) ---" -ForegroundColor Cyan
        Install-FromRepo -RepoUrl $entry.Url -RepoName $entry.CloneName `
                         -SrcSubDir $entry.SubDir -SkillDirs $entry.Skills
        Write-Host ""
    }

    # ============================================================================
    #  2. INSTALL CUSTOM SKILLS (custom-skills/)
    # ============================================================================
    Write-Host "--- Custom Skills ---" -ForegroundColor Cyan
    foreach ($skillMd in Get-ChildItem -Path $CustomDir -Filter "SKILL.md" -Recurse -Depth 1) {
        $skillName = $skillMd.Directory.Name
        $destPath  = Join-Path $SkillsDir $skillName
        $destMd    = Join-Path $destPath "SKILL.md"

        if ((Test-Path $destMd) -and (-not $Overwrite)) {
            Write-Info "  ~ $skillName (skipped)"
            continue
        }
        New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        Copy-Item -Path $skillMd.FullName -Destination $destMd -Force
        Write-Ok "  + $skillName (custom)"
    }
    Write-Host ""

    # ============================================================================
    #  3. LINK/COPY FOR OPENCODE
    # ============================================================================
    Write-Host "--- Linking for OpenCode ---" -ForegroundColor Cyan
    $usedCopyFallback = $false

    foreach ($skillDir in Get-ChildItem -Path $SkillsDir -Directory) {
        $target = Join-Path $OpenCodeDir $skillDir.Name

        if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }

        try {
            New-Item -ItemType SymbolicLink -Path $target -Target $skillDir.FullName -ErrorAction Stop | Out-Null
        } catch {
            Copy-Item -Path $skillDir.FullName -Destination $target -Recurse -Force
            $usedCopyFallback = $true
        }
    }

    $count = (Get-ChildItem -Path $SkillsDir -Directory).Count
    Write-Ok "Linked $count skills -> $OpenCodeDir"

    if ($usedCopyFallback) {
        Write-Warn "Symlinks not available — used file copy instead."
        Write-Warn "Enable Developer Mode (Settings > For Developers) for symlink support."
    }
    Write-Host ""

    # ============================================================================
    #  SUMMARY
    # ============================================================================
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed skills:"
    Write-Host ""

    "{0,-30} {1}" -f "SKILL", "SOURCE"
    "{0,-30} {1}" -f "-----", "------"

    for ($i = 0; $i -lt $AllSkills.Count; $i++) {
        $s   = $AllSkills[$i]
        $src = $SkillSource[$i]
        $p   = Join-Path $SkillsDir "$s\SKILL.md"
        if (Test-Path $p) {
            "{0,-30} {1}" -f $s, $src
        }
    }

    Write-Host ""
    Write-Host "Paths:"
    Write-Host "  Claude Code: $SkillsDir"
    Write-Host "  OpenCode:    $OpenCodeDir"
    Write-Host ""
    Write-Host "Note: anthropic-skills:* (pdf, xlsx, pptx, docx, schedule) are built-in"
    Write-Host "      to Claude Code and do not require manual installation."
    Write-Host ""
    Write-Host "To verify in Claude Code:  /skills"
    Write-Host "To verify in OpenCode:     ask 'list available skills'"
    Write-Host ""
    Write-Host "To uninstall: Remove-Item -Recurse -Force $SkillsDir, $OpenCodeDir"

} finally {
    # ── Cleanup ─────────────────────────────────────────────────────────────
    if (Test-Path $TmpDir) {
        Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
