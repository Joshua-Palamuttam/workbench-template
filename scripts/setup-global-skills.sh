#!/usr/bin/env bash
#
# Symlink portable workbench skills to ~/.claude/skills/
# so they're available in every Claude Code project.
#
# Reads the skills.global list from config.yaml.
# Re-run after adding/removing entries.
#
# On Windows (Git Bash/MSYS2), uses directory junctions via PowerShell
# since Git Bash ln -s creates copies instead of real symlinks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$REPO_ROOT/config.yaml"
SKILLS_SRC="$REPO_ROOT/.agents/skills"
SKILLS_DST="$HOME/.claude/skills"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: config.yaml not found at $CONFIG"
  echo "Copy config.example.yaml to config.yaml and fill in your values."
  exit 1
fi

# Parse skills.global list from config.yaml (simple grep, no yq dependency)
mapfile -t SKILLS < <(
  sed -n '/^skills:/,/^[^ ]/p' "$CONFIG" \
    | sed -n '/^ *global:/,/^$/p' \
    | grep '^ *- ' \
    | sed 's/^ *- *//; s/ *#.*//' \
    | tr -d '"' \
    | tr -d "'"
)

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "No skills listed under skills.global in config.yaml."
  exit 0
fi

mkdir -p "$SKILLS_DST"

# Detect Windows (Git Bash / MSYS2 / Cygwin)
is_windows=false
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
  is_windows=true
fi

# Convert MSYS/Git Bash path to Windows-friendly path for PowerShell
to_win_path() {
  if command -v cygpath &>/dev/null; then
    cygpath -m "$1"  # -m gives forward-slash Windows paths (C:/Users/...)
  else
    echo "$1"
  fi
}

# Check if a directory is a junction/symlink
is_link() {
  local path="$1"
  if $is_windows; then
    local win_path
    win_path="$(to_win_path "$path")"
    local link_type
    link_type=$(powershell.exe -NoProfile -Command "(Get-Item '$win_path' -ErrorAction SilentlyContinue).LinkType" 2>/dev/null | tr -d '\r\n')
    [[ "$link_type" == "Junction" || "$link_type" == "SymbolicLink" ]]
  else
    [[ -L "$path" ]]
  fi
}

# Create a junction (Windows) or symlink (Unix)
create_link() {
  local src="$1" dst="$2"
  if $is_windows; then
    local win_src win_dst
    win_src="$(to_win_path "$src")"
    win_dst="$(to_win_path "$dst")"
    powershell.exe -NoProfile -Command "New-Item -ItemType Junction -Path '$win_dst' -Target '$win_src' | Out-Null" 2>&1
  else
    ln -s "$src" "$dst"
  fi
}

created=0
skipped=0
missing=0

for skill in "${SKILLS[@]}"; do
  src="$SKILLS_SRC/$skill"
  dst="$SKILLS_DST/$skill"

  if [[ ! -d "$src" ]]; then
    echo "  MISSING  $skill (not found in .agents/skills/)"
    missing=$((missing + 1))
    continue
  fi

  if is_link "$dst"; then
    echo "  OK       $skill (already linked)"
    skipped=$((skipped + 1))
    continue
  elif [[ -e "$dst" ]]; then
    echo "  SKIP     $skill (non-link already exists at $dst)"
    skipped=$((skipped + 1))
    continue
  fi

  if create_link "$src" "$dst"; then
    echo "  LINKED   $skill"
    created=$((created + 1))
  else
    echo "  FAILED   $skill (could not create link)"
    missing=$((missing + 1))
  fi
done

echo ""
echo "Done: $created linked, $skipped unchanged, $missing missing"
