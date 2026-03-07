#!/usr/bin/env bash
# setup.sh — One-command interactive setup for the workbench
# Windows entry: scripts/windows/bin/setup.cmd
#
# Creates junctions, symlinks, shell profile entries, global skills, and context dirs.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

header "Workbench Setup"

# ─── Step 1: Platform detection ────────────────────────────────────────────
echo ""
if is_windows; then
  info "Platform: Windows (Git Bash)"
elif is_mac; then
  info "Platform: macOS"
else
  info "Platform: Linux"
fi

# Check required tools
for tool in git python; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool found: $(command -v "$tool")"
  else
    warn "$tool not found (some features may not work)"
  fi
done

# ─── Step 2: Config bootstrap ──────────────────────────────────────────────
header "Configuration"

if [[ ! -f "$CONFIG" ]]; then
  info "No config.yaml found. Creating from template..."
  cp "$REPO_ROOT/config.example.yaml" "$CONFIG"
  echo ""
  echo "  Created config.yaml from template."
  echo "  Edit it later to customize: $CONFIG"
  echo ""

  # Prompt for minimal config
  read -rp "  Your name: " user_name
  read -rp "  Your organization: " user_org

  if [[ -n "$user_name" ]]; then
    sed -i "s/name: \"Jane Smith\"/name: \"$user_name\"/" "$CONFIG"
  fi
  if [[ -n "$user_org" ]]; then
    sed -i "s/organization: \"Acme Corp\"/organization: \"$user_org\"/" "$CONFIG"
  fi

  pass "Config created (edit config.yaml for full customization)"
else
  pass "config.yaml exists"
fi

# ─── Step 3: Create junctions and symlinks ─────────────────────────────────
header "Junctions & Symlinks"

# Ensure target directories exist
mkdir -p "$REPO_ROOT/.claude"
mkdir -p "$REPO_ROOT/.cursor"

# Directory junctions (no admin needed on Windows)
declare -A DIR_JUNCTIONS=(
  [".claude/agents"]=".agents/agents"
  [".claude/hooks"]=".agents/hooks"
  [".claude/skills"]=".agents/skills"
  [".cursor/agents"]=".agents/agents"
  [".cursor/hooks"]=".agents/hooks"
  [".cursor/skills"]=".agents/skills"
)

for dst in "${!DIR_JUNCTIONS[@]}"; do
  src="${DIR_JUNCTIONS[$dst]}"
  full_dst="$REPO_ROOT/$dst"
  full_src="$REPO_ROOT/$src"

  if is_link "$full_dst"; then
    pass "$dst (already linked)"
  elif [[ -d "$full_dst" ]]; then
    # Remove the directory if it's not a junction (was copied by git)
    rm -rf "$full_dst"
    if create_dir_link "$full_src" "$full_dst"; then
      pass "$dst → $src"
    else
      fail "$dst (could not create junction)"
    fi
  else
    if create_dir_link "$full_src" "$full_dst"; then
      pass "$dst → $src"
    else
      fail "$dst (could not create junction)"
    fi
  fi
done

# .cursor/mcp.json junction (file junction on Windows needs special handling — use dir junction to parent)
cursor_mcp_dst="$REPO_ROOT/.cursor/mcp.json"
cursor_mcp_src="$REPO_ROOT/.agents/mcp.json"
if [[ -f "$cursor_mcp_src" ]]; then
  if is_link "$cursor_mcp_dst"; then
    pass ".cursor/mcp.json (already linked)"
  else
    # For mcp.json, just copy on Windows since file junctions are tricky
    if is_windows; then
      cp "$cursor_mcp_src" "$cursor_mcp_dst"
      pass ".cursor/mcp.json (copied)"
    else
      ln -sf "$cursor_mcp_src" "$cursor_mcp_dst"
      pass ".cursor/mcp.json → .agents/mcp.json"
    fi
  fi
fi

# File symlink: .claude/CLAUDE.md → ../AGENTS.md
claude_md_dst="$REPO_ROOT/.claude/CLAUDE.md"
agents_md_src="$REPO_ROOT/AGENTS.md"
if is_link "$claude_md_dst"; then
  pass ".claude/CLAUDE.md (already linked)"
elif [[ -f "$claude_md_dst" ]]; then
  rm "$claude_md_dst"
  if create_file_link "$agents_md_src" "$claude_md_dst"; then
    pass ".claude/CLAUDE.md → AGENTS.md"
  else
    fail ".claude/CLAUDE.md — file symlink failed"
    if is_windows; then
      echo ""
      warn "File symlinks on Windows require admin privileges."
      echo "  Run this in an admin PowerShell:"
      echo "  New-Item -ItemType SymbolicLink -Path '$(to_win_path "$claude_md_dst")' -Target '$(to_win_path "$agents_md_src")'"
      echo ""
    fi
  fi
else
  if create_file_link "$agents_md_src" "$claude_md_dst"; then
    pass ".claude/CLAUDE.md → AGENTS.md"
  else
    fail ".claude/CLAUDE.md — file symlink failed"
    if is_windows; then
      echo ""
      warn "File symlinks on Windows require admin privileges."
      echo "  Run this in an admin PowerShell:"
      echo "  New-Item -ItemType SymbolicLink -Path '$(to_win_path "$claude_md_dst")' -Target '$(to_win_path "$agents_md_src")'"
      echo ""
    fi
  fi
fi

# ─── Step 4: Shell profile setup ──────────────────────────────────────────
header "Shell Profile"

if is_windows; then
  profile_file="$HOME/.bashrc"
  profile_line="source \"$REPO_ROOT/scripts/windows/wt-profile.sh\""
  path_line="export PATH=\"$REPO_ROOT/scripts/windows/bin:\$PATH\""

  if [[ -f "$profile_file" ]] && grep -qF "wt-profile.sh" "$profile_file"; then
    pass "wt-profile.sh already sourced in ~/.bashrc"
  else
    echo "" >> "$profile_file"
    echo "# Workbench: worktree functions and navigation" >> "$profile_file"
    echo "$profile_line" >> "$profile_file"
    pass "Added wt-profile.sh to ~/.bashrc"
  fi

  if [[ -f "$profile_file" ]] && grep -qF "scripts/windows/bin" "$profile_file"; then
    pass "bin/ already in PATH"
  else
    echo "$path_line" >> "$profile_file"
    pass "Added scripts/windows/bin/ to PATH"
  fi

  # Generate wt-config.sh
  wt_config="$REPO_ROOT/scripts/windows/wt-config.sh"
  worktree_root=$(parse_yaml_value "worktrees.root" 2>/dev/null || echo "C:/worktrees-SeekOut")
  cat > "$wt_config" << WTEOF
#!/bin/bash
# Auto-generated by setup.sh — do not edit
export WORKTREE_ROOT="$worktree_root"
export WORKTREE_SCRIPTS="$REPO_ROOT/scripts/windows"
export WORKBENCH_ROOT="$REPO_ROOT"
WTEOF
  pass "Generated scripts/windows/wt-config.sh"

elif is_mac; then
  profile_file="$HOME/.zshrc"
  profile_line="source \"$REPO_ROOT/scripts/mac/wt-profile.zsh\""

  if [[ -f "$profile_file" ]] && grep -qF "wt-profile.zsh" "$profile_file"; then
    pass "wt-profile.zsh already sourced in ~/.zshrc"
  else
    echo "" >> "$profile_file"
    echo "# Workbench: worktree functions and navigation" >> "$profile_file"
    echo "$profile_line" >> "$profile_file"
    pass "Added wt-profile.zsh to ~/.zshrc"
  fi
fi

# ─── Step 5: Global skills ────────────────────────────────────────────────
header "Global Skills"

SKILLS_SRC="$REPO_ROOT/.agents/skills"
SKILLS_DST="$HOME/.claude/skills"
mkdir -p "$SKILLS_DST"

mapfile -t GLOBAL_SKILLS < <(parse_yaml_list "skills.global" 2>/dev/null)

if [[ ${#GLOBAL_SKILLS[@]} -eq 0 ]]; then
  info "No global skills configured in config.yaml (skills.global)"
else
  created=0
  skipped=0
  for skill in "${GLOBAL_SKILLS[@]}"; do
    src="$SKILLS_SRC/$skill"
    dst="$SKILLS_DST/$skill"

    if [[ ! -d "$src" ]]; then
      warn "$skill — not found in .agents/skills/"
      continue
    fi

    if is_link "$dst"; then
      skipped=$((skipped + 1))
      continue
    elif [[ -e "$dst" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    if create_dir_link "$src" "$dst"; then
      created=$((created + 1))
    else
      warn "$skill — could not create link"
    fi
  done
  pass "Global skills: $created linked, $skipped already set up"
fi

# ─── Step 6: Context directories ──────────────────────────────────────────
header "Context Directories"

for dir in context/active context/archive context/plans context/notes; do
  mkdir -p "$REPO_ROOT/$dir"
done
pass "Context directories ready"

# ─── Step 7: Pre-commit hook ─────────────────────────────────────────────
header "Pre-commit Hook"

hook_src="$REPO_ROOT/.agents/hooks/check-unlisted-skills.sh"
hook_dst="$REPO_ROOT/.git/hooks/pre-commit"

if [[ -f "$hook_src" ]]; then
  mkdir -p "$REPO_ROOT/.git/hooks"
  if [[ -f "$hook_dst" ]]; then
    if grep -q "check-unlisted-skills" "$hook_dst"; then
      pass "Pre-commit hook already installed"
    else
      echo "" >> "$hook_dst"
      echo "# Workbench: warn about unlisted skills" >> "$hook_dst"
      echo "bash \"$hook_src\"" >> "$hook_dst"
      pass "Appended skill check to existing pre-commit hook"
    fi
  else
    cp "$hook_src" "$hook_dst"
    chmod +x "$hook_dst"
    pass "Pre-commit hook installed"
  fi
else
  warn "Hook source not found: $hook_src"
fi

# ─── Step 8: Run doctor ───────────────────────────────────────────────────
header "Verification"
echo ""

if [[ -f "$REPO_ROOT/scripts/doctor.sh" ]]; then
  bash "$REPO_ROOT/scripts/doctor.sh"
else
  info "doctor.sh not yet created — skipping verification"
fi

echo ""
echo "Setup complete! Restart your shell or run: source ~/.bashrc"
