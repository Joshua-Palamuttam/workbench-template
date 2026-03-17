#!/bin/bash
# wt-profile.sh - Source this in your .bashrc or .zshrc
# Add this line to your shell profile:
#   source "C:/worktrees-SeekOut/workbench/scripts/windows/wt-profile.sh"

# Load generated config if available, otherwise use defaults
SCRIPT_DIR_PROFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR_PROFILE/wt-config.sh" ]; then
    source "$SCRIPT_DIR_PROFILE/wt-config.sh"
else
    export WORKTREE_ROOT="C:/worktrees-SeekOut"
    export WORKTREE_SCRIPTS="$SCRIPT_DIR_PROFILE"
    export WORKBENCH_ROOT="$(cd "$SCRIPT_DIR_PROFILE/../.." && pwd)"
fi

# ============================================================
# Core Worktree Functions
# ============================================================

# Initialize a new repo for worktree workflow
wt-init() {
    bash "$WORKTREE_SCRIPTS/wt-init.sh" "$@"
}

# Create a feature worktree
wt-feature() {
    bash "$WORKTREE_SCRIPTS/wt-feature.sh" "$@"
    # Auto-cd to the new worktree
    if [ $? -eq 0 ] && [ -n "$1" ]; then
        local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir)
        local dir_name=$(echo "$1" | sed 's|.*/||')
        cd "$repo_root/_feature/$dir_name" 2>/dev/null || true
    fi
}

# Quick PR review
wt-review() {
    bash "$WORKTREE_SCRIPTS/wt-review.sh" "$@"
    # Auto-cd to review worktree
    if [ $? -eq 0 ]; then
        local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir)
        cd "$repo_root/_review/current" 2>/dev/null || true
    fi
}

# Done with review
wt-review-done() {
    bash "$WORKTREE_SCRIPTS/wt-review-done.sh" "$@"
}

# Status across all repos
wt-status() {
    bash "$WORKTREE_SCRIPTS/wt-status.sh" "$@"
}

# Cleanup stale worktrees
wt-cleanup() {
    bash "$WORKTREE_SCRIPTS/wt-cleanup.sh" "$@"
}

# Migrate existing repo or clone from URL to worktree structure
wt-migrate() {
    bash "$WORKTREE_SCRIPTS/wt-migrate.sh" "$@"
}

# Remove a worktree
wt-remove() {
    bash "$WORKTREE_SCRIPTS/wt-remove.sh" "$@"
}

# ============================================================
# Claude Launchers (cc/ccd are global aliases set up by setup.sh)
# ============================================================

# Navigate to worktree and launch claude
wtc() { wtn "$@" && claude; }

# Navigate to worktree and launch claude --dangerously-skip-permissions
wtcd() { wtn "$@" && claude --dangerously-skip-permissions; }

# ============================================================
# Aliases
# ============================================================

alias wtrm='wt-remove'
alias wtg='wtn'

# ============================================================
# Quick Navigation
# ============================================================

# Jump to worktree root
wtgo() {
    cd "$WORKTREE_ROOT"
}

# Jump to a specific repo
wtr() {
    local repo=$1
    if [ -z "$repo" ]; then
        echo "Available repos:"
        ls -1 "$WORKTREE_ROOT" | grep '\.git$' | sed 's/\.git$//'
        return
    fi
    cd "$WORKTREE_ROOT/${repo}.git"
}

# Jump to develop worktree of current or specified repo
wtd() {
    local repo=$1
    if [ -z "$repo" ]; then
        # Try to detect from current location
        local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir 2>/dev/null)
        if [ -n "$repo_root" ]; then
            cd "$repo_root/develop" 2>/dev/null || echo "No develop worktree"
            return
        fi
    fi
    cd "$WORKTREE_ROOT/${repo}.git/develop" 2>/dev/null || echo "No develop worktree for $repo"
}

# Jump to main worktree
wtm() {
    local repo=$1
    if [ -z "$repo" ]; then
        local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir 2>/dev/null)
        if [ -n "$repo_root" ]; then
            cd "$repo_root/main" 2>/dev/null || echo "No main worktree"
            return
        fi
    fi
    cd "$WORKTREE_ROOT/${repo}.git/main" 2>/dev/null || echo "No main worktree for $repo"
}

# List worktrees in current repo
wtl() {
    git worktree list
}

# Interactive navigation (use -c to launch Claude Code after)
wtn() {
    # Handle wtn - (go to last worktree)
    if [ "$1" = "-" ]; then
        if [ -f ~/.wt_last ]; then
            local last_dir=$(cat ~/.wt_last)
            if [ -d "$last_dir" ]; then
                echo "$(pwd)" > ~/.wt_last
                cd "$last_dir"
                echo "$(pwd)"
                return 0
            else
                echo "Last worktree no longer exists: $last_dir"
                return 1
            fi
        else
            echo "No previous worktree"
            return 1
        fi
    fi
    # Save current dir before navigating
    echo "$(pwd)" > ~/.wt_last
    source "$WORKTREE_SCRIPTS/wtn.sh" "$@"
}

# ============================================================
# Release & Hotfix Workflow
# ============================================================

# Create a release branch
wt-release() {
    bash "$WORKTREE_SCRIPTS/wt-release.sh" "$@"
}


wt-hotfix() {
    bash "$WORKTREE_SCRIPTS/wt-hotfix.sh" "$@"
    # Auto-cd to the new worktree
    if [ $? -eq 0 ] && [ -n "$1" ]; then
        local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir)
        cd "$repo_root/_hotfix/$1" 2>/dev/null || true
    fi
}

wt-hotfix-done() {
    bash "$WORKTREE_SCRIPTS/wt-hotfix-done.sh" "$@"
}

wt-hotfix-pr() {
    bash "$WORKTREE_SCRIPTS/wt-hotfix-pr.sh" "$@"
    if [ $? -eq 0 ] && [ -f /tmp/.wt-hotfix-pr-last-dir ]; then
        local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir)
        local wt_dir=$(cat /tmp/.wt-hotfix-pr-last-dir)
        rm -f /tmp/.wt-hotfix-pr-last-dir
        cd "$repo_root/$wt_dir" 2>/dev/null || true
    fi
}

# Sync current branch with develop (or another branch)
wt-sync() {
    bash "$WORKTREE_SCRIPTS/wt-sync.sh" "$@"
}

# ============================================================
# Tab Completion (Bash)
# ============================================================

_wtr_completions() {
    local repos=$(ls -1 "$WORKTREE_ROOT" 2>/dev/null | grep '\.git$' | sed 's/\.git$//')
    COMPREPLY=($(compgen -W "$repos" -- "${COMP_WORDS[1]}"))
}

_wt_remove_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Complete flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-f --force -d --delete-branch -k --keep-branch -y --yes --stale" -- "$cur"))
        return
    fi

    # Complete worktree names
    local repo_root=$(git rev-parse --git-common-dir 2>/dev/null || git rev-parse --git-dir 2>/dev/null)
    [ -z "$repo_root" ] && return
    local names=""
    for kind in _feature _hotfix _review; do
        [ -d "$repo_root/$kind" ] || continue
        for d in "$repo_root/$kind"/*/; do
            [ -d "$d" ] && names+="$(basename "$d") "
        done
    done
    COMPREPLY=($(compgen -W "$names" -- "$cur"))
}

_wtn_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-c --code -" -- "$cur"))
        return
    fi
}

_wt_status_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--dirty" -- "$cur"))
        return
    fi
    local repos=$(ls -1 "$WORKTREE_ROOT" 2>/dev/null | grep '\.git$' | sed 's/\.git$//')
    COMPREPLY=($(compgen -W "$repos" -- "$cur"))
}

if [ -n "$BASH_VERSION" ]; then
    complete -F _wtr_completions wtr
    complete -F _wtr_completions wtd
    complete -F _wtr_completions wtm
    complete -F _wt_remove_completions wt-remove
    complete -F _wt_remove_completions wtrm
    complete -F _wt_remove_completions wt-hotfix-done
    complete -F _wtn_completions wtn
    complete -F _wtn_completions wtg
    complete -F _wt_status_completions wt-status
fi

# ============================================================
# Prompt Enhancement (Optional)
# ============================================================

# Uncomment to show worktree info in prompt
# wt_prompt_info() {
#     local wt_name=$(basename "$(pwd)")
#     local repo_name=$(basename "$(git rev-parse --git-common-dir 2>/dev/null)" .git)
#     if [ -n "$repo_name" ]; then
#         echo "[${repo_name}:${wt_name}]"
#     fi
# }

echo "✅ Worktree functions loaded. Type 'wt-status' to see all repos."
