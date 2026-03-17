#!/bin/bash
# wt-remove.sh - Remove a worktree interactively or by name (macOS)
# Usage: wt-remove [name] [-d|--delete-branch] [-k|--keep-branch] [-f|--force] [-y|--yes] [--stale [days]]

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-lib.sh"

worktree_name=""
force_flag=""
delete_branch="" # empty=prompt, yes, no
auto_yes=false
stale_mode=false
stale_days=14

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f) force_flag="--force"; shift ;;
        --delete-branch|-d) delete_branch="yes"; shift ;;
        --keep-branch|-k) delete_branch="no"; shift ;;
        --yes|-y) auto_yes=true; shift ;;
        --stale)
            stale_mode=true
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                stale_days="$2"; shift
            fi
            shift
            ;;
        *) [[ -z "$worktree_name" ]] && worktree_name="$1"; shift ;;
    esac
done

repo_root=$(get_repo_root)
cd "$repo_root"

# Stale mode: find and remove worktrees with no recent commits
if [[ "$stale_mode" == true ]]; then
    info "Finding worktrees with no commits in the last ${stale_days} days..."
    stale_list=()
    for kind in _feature _hotfix _review; do
        [[ -d "$repo_root/$kind" ]] || continue
        for d in "$repo_root/$kind"/*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            last_commit=$(cd "$d" && git log -1 --format='%ct' 2>/dev/null || echo "0")
            now=$(date +%s)
            age_days=$(( (now - last_commit) / 86400 ))
            if [[ $age_days -ge $stale_days ]]; then
                stale_list+=("$name (${age_days}d old) [${kind#_}]")
            fi
        done
    done

    if [[ ${#stale_list[@]} -eq 0 ]]; then
        success "No stale worktrees found (threshold: ${stale_days} days)"
        exit 0
    fi

    echo ""
    echo "Stale worktrees (no commits in ${stale_days}+ days):"
    for item in "${stale_list[@]}"; do
        echo "  - $item"
    done
    echo ""

    if [[ "$auto_yes" != true ]]; then
        read -p "Remove all? [y/N] " -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] || { echo "Cancelled"; exit 0; }
    fi

    for item in "${stale_list[@]}"; do
        name="${item%% (*}"
        for kind in _feature _hotfix _review; do
            if [[ -d "$repo_root/$kind/$name" ]]; then
                branch_name=$(cd "$repo_root/$kind/$name" && git branch --show-current 2>/dev/null) || true
                git worktree remove "$kind/$name" --force 2>/dev/null || rm -rf "$kind/$name"
                success "Removed: $kind/$name"
                if [[ -n "$branch_name" && "$branch_name" != "main" && "$branch_name" != "master" && "$branch_name" != "develop" ]]; then
                    if [[ "$delete_branch" == "yes" ]]; then
                        git branch -D "$branch_name" 2>/dev/null && success "Branch deleted: $branch_name"
                    elif [[ "$delete_branch" != "no" && "$auto_yes" != true ]]; then
                        read -p "Delete branch '$branch_name'? [y/N] " -n 1 -r; echo
                        [[ $REPLY =~ ^[Yy]$ ]] && git branch -D "$branch_name" 2>/dev/null && success "Branch deleted: $branch_name"
                    fi
                fi
                break
            fi
        done
    done
    git worktree prune
    exit 0
fi

# Interactive selection if no name given
if [[ -z "$worktree_name" ]]; then
    selected=$(list_removable_worktrees "$repo_root" | fzf_select "Remove worktree") || { echo "Cancelled"; exit 0; }
    worktree_name="${selected%% \[*\]}"
fi

# Find the worktree path — with fuzzy matching fallback
worktree_path=""
for candidate in "_feature/$worktree_name" "_hotfix/$worktree_name" "_review/$worktree_name" "$worktree_name"; do
    [[ -d "$candidate" ]] && { worktree_path="$candidate"; break; }
done

# Fuzzy match if exact match not found
if [[ -z "$worktree_path" ]]; then
    matches=()
    match_paths=()
    for kind in _feature _hotfix _review; do
        [[ -d "$repo_root/$kind" ]] || continue
        for d in "$repo_root/$kind"/*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            if [[ "${name,,}" == *"${worktree_name,,}"* ]]; then
                matches+=("$name [${kind#_}]")
                match_paths+=("$kind/$name")
            fi
        done
    done

    if [[ ${#matches[@]} -eq 1 ]]; then
        worktree_path="${match_paths[0]}"
        info "Matched: ${matches[0]}"
    elif [[ ${#matches[@]} -gt 1 ]]; then
        echo "Multiple matches for '$worktree_name':"
        for m in "${matches[@]}"; do
            echo "  - $m"
        done
        selected=$(printf '%s\n' "${matches[@]}" | fzf_select "Pick one") || { echo "Cancelled"; exit 0; }
        selected_name="${selected%% \[*\]}"
        for kind in _feature _hotfix _review; do
            [[ -d "$repo_root/$kind/$selected_name" ]] && { worktree_path="$kind/$selected_name"; break; }
        done
    fi
fi

[[ -z "$worktree_path" ]] && { err "Not found: $worktree_name"; git worktree list; exit 1; }

# Get branch name before removing
branch_name=$(cd "$worktree_path" && git branch --show-current 2>/dev/null) || true

info "Removing: $worktree_path"

if ! git worktree remove "$worktree_path" $force_flag 2>/dev/null; then
    warn "Has modified/untracked files. Force remove?"
    if [[ "$auto_yes" == true ]]; then
        git worktree remove "$worktree_path" --force
    else
        read -p "[y/N] " -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] || { echo "Cancelled"; exit 1; }
        git worktree remove "$worktree_path" --force
    fi
fi

git worktree prune
success "Worktree removed: $worktree_path"

# Handle branch deletion
if [[ -n "$branch_name" && "$branch_name" != "main" && "$branch_name" != "master" && "$branch_name" != "develop" ]]; then
    if [[ "$delete_branch" == "yes" ]]; then
        git branch -D "$branch_name" 2>/dev/null && success "Branch deleted: $branch_name"
    elif [[ "$delete_branch" != "no" ]]; then
        if [[ "$auto_yes" == true ]]; then
            : # Don't auto-delete branches unless explicitly asked with -d
        else
            read -p "Delete local branch '$branch_name'? [y/N] " -n 1 -r; echo
            [[ $REPLY =~ ^[Yy]$ ]] && git branch -D "$branch_name" 2>/dev/null && success "Branch deleted: $branch_name"
        fi
    fi
fi
