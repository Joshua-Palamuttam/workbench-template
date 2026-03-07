#!/usr/bin/env bash
# check-unlisted-skills.sh — Pre-commit hook: warn about skills not in template allowlist
# This is a WARNING only — it does not block the commit.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ALLOWLIST="$REPO_ROOT/scripts/template-allowlist.yaml"
SKILLS_DIR="$REPO_ROOT/.agents/skills"

if [[ ! -f "$ALLOWLIST" ]]; then
  exit 0
fi

unlisted=()
for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name=$(basename "$skill_dir")

  if ! grep -q "$skill_name" "$ALLOWLIST" 2>/dev/null; then
    unlisted+=("$skill_name")
  fi
done

if [[ ${#unlisted[@]} -gt 0 ]]; then
  echo ""
  echo "WARNING: ${#unlisted[@]} skill(s) not in template-allowlist.yaml:"
  for s in "${unlisted[@]}"; do
    echo "  - $s"
  done
  echo ""
  echo "These skills will NOT sync to the public template."
  echo "If this is intentional, ignore this warning."
  echo "To add: edit scripts/template-allowlist.yaml"
  echo ""
fi

# Always exit 0 — this is a warning, not a blocker
exit 0
