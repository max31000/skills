#!/usr/bin/env bash
# ============================================================================
#  Universal Agent Skills Installer
#  Works on: macOS (bash/zsh), Linux, Windows (Git Bash / WSL)
#  Installs to: ~/.claude/skills/  (primary, seen by Claude Code + OpenCode)
#  Symlinks to: ~/.config/opencode/skills/  (OpenCode native path)
#
#  Configuration:
#    repos.conf      — external GitHub repos to clone skills from
#    custom-skills/  — local skill definitions (SKILL.md files)
#
#  Note: anthropic-skills:* (pdf, xlsx, pptx, docx, schedule) are built-in
#  to Claude Code and do not require manual installation here.
# ============================================================================
set -euo pipefail

OVERWRITE_FLAG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --overwrite)
            OVERWRITE_FLAG=true
            shift
            ;;
        -h|--help)
            printf 'Usage: bash scripts/install-skills.sh [--overwrite]\n'
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            exit 1
            ;;
    esac
done

# ── Script directory (where repos.conf and custom-skills/ live) ───────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_FILE="$ROOT_DIR/manifest/skills/repos.conf"
CUSTOM_DIR="$ROOT_DIR/custom-skills"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }

# ── Pre-flight checks ──────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || fail "git is not installed"
[ -f "$CONF_FILE" ]  || fail "repos.conf not found at $CONF_FILE"
[ -d "$CUSTOM_DIR" ] || fail "custom-skills/ directory not found at $CUSTOM_DIR"

# ── Build ALL_SKILLS dynamically from config ────────────────────────────────
ALL_SKILLS=()
REPO_SOURCES=()    # parallel array: source label per skill

while IFS='|' read -r repo_url clone_name src_subdir skills_csv; do
    [[ "$repo_url" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${repo_url// /}" ]] && continue
    skills_csv="${skills_csv## }"; skills_csv="${skills_csv%% }"
    clone_name="${clone_name## }"; clone_name="${clone_name%% }"
    IFS=',' read -ra skill_list <<< "$skills_csv"
    for s in "${skill_list[@]}"; do
        s="${s## }"; s="${s%% }"
        ALL_SKILLS+=("$s")
        REPO_SOURCES+=("$clone_name")
    done
done < "$CONF_FILE"

for skill_path in "$CUSTOM_DIR"/*/SKILL.md; do
    [ -f "$skill_path" ] || continue
    skill_name=$(basename "$(dirname "$skill_path")")
    ALL_SKILLS+=("$skill_name")
    REPO_SOURCES+=("custom")
done

# ── Paths ───────────────────────────────────────────────────────────────────
SKILLS_DIR="$HOME/.claude/skills"
OPENCODE_DIR="$HOME/.config/opencode/skills"
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'skills-install')

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$SKILLS_DIR"
mkdir -p "$OPENCODE_DIR"

info "Skills directory:   $SKILLS_DIR"
info "OpenCode symlink:   $OPENCODE_DIR"
echo ""

# ── Overwrite check ────────────────────────────────────────────────────────
existing=()
for s in "${ALL_SKILLS[@]}"; do
    [ -d "$SKILLS_DIR/$s" ] && [ -f "$SKILLS_DIR/$s/SKILL.md" ] && existing+=("$s")
done

OVERWRITE=false
if [ ${#existing[@]} -gt 0 ]; then
    echo -e "${YELLOW}Already installed (${#existing[@]}):${NC}"
    for s in "${existing[@]}"; do printf "    %s\n" "$s"; done
    echo ""

    if [[ "$OVERWRITE_FLAG" == "true" ]] || [[ "${INSTALL_SKILLS_OVERWRITE:-}" =~ ^(1|true|TRUE|yes|YES)$ ]]; then
        OVERWRITE=true
        ok "Existing skills will be overwritten."
    elif [[ "${BOOTSTRAP_NONINTERACTIVE:-}" =~ ^(1|true|TRUE|yes|YES)$ ]] || [[ ! -t 0 ]]; then
        info "Non-interactive mode detected. Existing skills will be skipped."
    else
        printf "Overwrite existing skills? [y/N] "
        read -r answer </dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            OVERWRITE=true
            ok "Existing skills will be overwritten."
        else
            info "Existing skills will be skipped. Only new skills will be installed."
        fi
    fi
    echo ""
fi

# ── Helper: clone a repo and copy specific skill folders ──────────────────
install_from_repo() {
    local repo_url="$1"
    local repo_name="$2"
    local src_subdir="$3"
    shift 3
    local skill_dirs=("$@")

    info "Cloning $repo_name..."
    git clone --depth 1 --quiet "$repo_url" "$TMP_DIR/$repo_name" 2>/dev/null || {
        warn "Failed to clone $repo_name — skipping"
        return 0
    }

    local base_path="$TMP_DIR/$repo_name"
    [ "$src_subdir" != "." ] && base_path="$base_path/$src_subdir"

    for skill in "${skill_dirs[@]}"; do
        if [ -d "$SKILLS_DIR/$skill" ] && [ -f "$SKILLS_DIR/$skill/SKILL.md" ] && [ "$OVERWRITE" = "false" ]; then
            info "  ~ $skill (skipped)"
            continue
        fi
        # Try configured path first, then fallback to "skills/" subdir
        if [ -d "$base_path/$skill" ] && [ -f "$base_path/$skill/SKILL.md" ]; then
            rm -rf "$SKILLS_DIR/$skill"
            cp -r "$base_path/$skill" "$SKILLS_DIR/$skill"
            ok "  + $skill"
        elif [ -d "$TMP_DIR/$repo_name/skills/$skill" ] && [ -f "$TMP_DIR/$repo_name/skills/$skill/SKILL.md" ]; then
            rm -rf "$SKILLS_DIR/$skill"
            cp -r "$TMP_DIR/$repo_name/skills/$skill" "$SKILLS_DIR/$skill"
            ok "  + $skill (from skills/)"
        else
            warn "  ! $skill — SKILL.md not found in repo, skipping"
        fi
    done
}

# ============================================================================
#  1. INSTALL FROM EXTERNAL REPOS (repos.conf)
# ============================================================================
while IFS='|' read -r repo_url clone_name src_subdir skills_csv; do
    [[ "$repo_url" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${repo_url// /}" ]] && continue

    repo_url="${repo_url## }"; repo_url="${repo_url%% }"
    clone_name="${clone_name## }"; clone_name="${clone_name%% }"
    src_subdir="${src_subdir## }"; src_subdir="${src_subdir%% }"
    skills_csv="${skills_csv## }"; skills_csv="${skills_csv%% }"

    IFS=',' read -ra skill_list <<< "$skills_csv"
    # Trim each skill name
    for i in "${!skill_list[@]}"; do
        skill_list[$i]="${skill_list[$i]## }"
        skill_list[$i]="${skill_list[$i]%% }"
    done

    echo -e "${CYAN}--- $clone_name ---${NC}"
    install_from_repo "$repo_url" "$clone_name" "$src_subdir" "${skill_list[@]}"
    echo ""
done < "$CONF_FILE"

# ============================================================================
#  2. INSTALL CUSTOM SKILLS (custom-skills/)
# ============================================================================
echo -e "${CYAN}--- Custom Skills ---${NC}"
for skill_md in "$CUSTOM_DIR"/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    skill_name=$(basename "$(dirname "$skill_md")")

    if [ -d "$SKILLS_DIR/$skill_name" ] && [ -f "$SKILLS_DIR/$skill_name/SKILL.md" ] && [ "$OVERWRITE" = "false" ]; then
        info "  ~ $skill_name (skipped)"
        continue
    fi
    mkdir -p "$SKILLS_DIR/$skill_name"
    cp "$skill_md" "$SKILLS_DIR/$skill_name/SKILL.md"
    ok "  + $skill_name (custom)"
done
echo ""

# ============================================================================
#  3. SYMLINK FOR OPENCODE
# ============================================================================
echo -e "${CYAN}--- Linking for OpenCode ---${NC}"

for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$OPENCODE_DIR/$skill_name"

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -d "$target" ]; then
        rm -rf "$target"
    fi

    if ln -s "$skill_dir" "$target" 2>/dev/null; then
        :
    else
        cp -r "$skill_dir" "$target"
    fi
done
ok "Linked $(ls -1d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ') skills -> $OPENCODE_DIR"
echo ""

# ============================================================================
#  SUMMARY
# ============================================================================
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "Installed skills:"
echo ""

printf "%-30s %s\n" "SKILL" "SOURCE"
printf "%-30s %s\n" "-----" "------"

for i in "${!ALL_SKILLS[@]}"; do
    s="${ALL_SKILLS[$i]}"
    src="${REPO_SOURCES[$i]}"
    [ -d "$SKILLS_DIR/$s" ] && printf "%-30s %s\n" "$s" "$src"
done

echo ""
echo "Paths:"
echo "  Claude Code: $SKILLS_DIR"
echo "  OpenCode:    $OPENCODE_DIR"
echo ""
echo "Note: anthropic-skills:* (pdf, xlsx, pptx, docx, schedule) are built-in"
echo "      to Claude Code and do not require manual installation."
echo ""
echo "To verify in Claude Code:  /skills"
echo "To verify in OpenCode:     ask 'list available skills'"
echo ""
echo "To uninstall: rm -rf $SKILLS_DIR $OPENCODE_DIR"
