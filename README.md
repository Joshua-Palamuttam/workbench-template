# Workbench

Operational hub for a principal software engineer, powered by Claude Code. Plan, prioritize, estimate, and stay accountable — all from one repo.

This is **not** a code repository. It's where you think, plan, gather context, and manage your engineering workflow.

## What's Inside

- **Agents** (`.agents/agents/`) — 20 AI agent definitions for daily workflows: morning triage, weekly planning, estimation, Jira/Confluence/Slack integration, PR review, and more.
- **Skills** (`.agents/skills/`) — 38 invocable skills (`/doctor`, `/estimate`, `/morning-triage`, etc.) that wrap common workflows into single commands.
- **Hooks** (`.agents/hooks/`) — Session lifecycle hooks that inject daily context, log Slack messages, and check plan status.
- **Scripts** (`scripts/`) — Cross-platform shell scripts for setup, diagnostics, worktree management, and template sync.
- **Context** (`context/`) — Daily plans, weekly plans, calendar data, quarterly goals, and archived history.

## Quick Start

### Prerequisites

- Git (with Git Bash on Windows)
- Python 3.x
- [Claude Code](https://claude.ai/claude-code) CLI
- GitHub CLI (`gh`) — optional but recommended

### Setup

```bash
# Clone the repo
git clone https://github.com/Joshua-Palamuttam/workbench.git
cd workbench

# Run one-command setup
bash scripts/setup.sh
```

On Windows, you can also run:
```cmd
scripts\windows\bin\setup.cmd
```

Setup will:
1. Detect your platform (Windows/macOS/Linux)
2. Create `config.yaml` from the template if needed
3. Create directory junctions from `.claude/` and `.cursor/` to `.agents/`
4. Create a file symlink: `.claude/CLAUDE.md` -> `AGENTS.md`
5. Configure your shell profile for worktree commands
6. Set up global skills in `~/.claude/skills/`
7. Run diagnostics to verify everything

**Windows note:** The CLAUDE.md file symlink requires admin privileges. Setup will print the exact PowerShell command to run in an admin terminal.

### Configuration

Edit `config.yaml` to customize:

```yaml
user:
  name: "Your Name"
  role: "Your Title"
  organization: "Your Org"

worktrees:
  root: "C:/worktrees"
  repos:
    - name: my-repo
      url: https://github.com/org/repo.git
      default_base: develop
      type: standard

skills:
  global:          # Available in every project
    - estimate
    - sounding-board
    - jira-review
```

See `config.example.yaml` for all available options.

### Verify

```bash
bash scripts/doctor.sh
# or
/doctor   # from within Claude Code
```

## Architecture

### `.agents/` as Single Source of Truth

All AI tooling lives in `.agents/`. Tool-specific directories (`.claude/`, `.cursor/`) contain junctions pointing back:

```
.agents/                     # Canonical
  agents/                    # Agent definitions
  skills/                    # Skill definitions
  hooks/                     # Hook scripts
  mcp.json                   # MCP server config

.claude/                     # Claude Code (junctions)
  CLAUDE.md -> ../AGENTS.md  # Symlink
  agents -> ../.agents/agents
  skills -> ../.agents/skills
  hooks -> ../.agents/hooks
  settings.json              # Claude-specific (committed)
  settings.local.json        # Machine-specific (gitignored)
```

Junctions are gitignored and created by `scripts/setup.sh`.

### Key Skills

| Skill | What it does |
|-------|-------------|
| `/morning-triage` | Scan DMs, Slack, Jira to create a prioritized daily plan |
| `/weekly-plan` | Build a capacity-based weekly plan with estimation tracking |
| `/estimate` | Realistic time estimates with calibrated multipliers |
| `/doctor` | Diagnose the workbench environment |
| `/worktrees` | Show git worktree status across all managed repos |
| `/skill-import` | Import skills from GitHub, local paths, or a registry |
| `/template-sync` | Sync safe content to a public template repo |

### Worktree Management

Shell functions for managing git worktrees across multiple repos:

```bash
wt-status              # Status across all repos
wt-feature my-branch   # Create a feature worktree
wt-review 123          # Review a PR in an isolated worktree
wt-release             # Cut a release branch
wt-hotfix fix-name     # Create a hotfix worktree
```

Scripts live in `scripts/windows/` and `scripts/mac/`. Windows `.cmd` wrappers in `scripts/windows/bin/` are added to PATH by setup.

### Template Sync

Uses an **inverted allowlist** — skills and files are excluded from the public template by default. Each must be explicitly listed in `scripts/template-allowlist.yaml` to sync. A security scan checks for sensitive patterns before any push.

## Directory Structure

```
workbench/
  .agents/              # Canonical AI tooling
  .claude/              # Claude Code (junctions + settings)
  .cursor/              # Cursor (junctions + rules)
  scripts/
    lib.sh              # Shared cross-platform functions
    setup.sh            # One-command setup
    doctor.sh           # Environment diagnostics
    skill-add.sh        # Skill import
    template-sync.sh    # Template sync
    windows/            # Windows worktree scripts + bin/
    mac/                # macOS worktree scripts
    appinsights/        # Azure AppInsights tooling
  templates/            # Templates for new worktrees
  context/
    active/             # Current daily/weekly/calendar/goals
    archive/            # Historical data
    plans/              # Feature plans
    notes/              # Research and drafts
  config.yaml           # Personal config (gitignored)
  config.example.yaml   # Config template
  AGENTS.md             # Canonical instructions
```
