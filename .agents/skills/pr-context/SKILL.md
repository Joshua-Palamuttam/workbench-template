---
name: pr-context
description: Gather full context for a PR — Jira ticket, design doc, Slack discussion. Produces an informed review brief so code review catches intent-vs-implementation gaps.
argument-hint: <PR number>
---

# PR Context

Gather the full picture around a pull request — not just the code, but the WHY behind it.

The user's GitHub org and repositories are defined in `config.yaml` under `github.org` and `github.repositories`. Jira ticket patterns are in `config.yaml` under `jira.projects[].ticket_pattern`.

## Input

The user will provide:
- A PR number (required)
- Optionally: the repository name

## Process

### Step 1: Get PR Details from GitHub

Use `gh pr view <number>` (via Bash) to get: title, description, author, branch name, files changed, comments and review status.

### Step 2: Find the Jira Ticket

Look for a Jira ticket ID in the PR title, description, or branch name (patterns from `config.yaml`). If found, fetch it.

### Step 3: Find Related Design Docs

From the Jira ticket, check for linked Confluence pages. Fetch if found.

### Step 4: Find Slack Discussion

Search Slack for the PR number or Jira ticket ID in engineering channels.

### Step 5: Present the Full Context

```
## PR #NNN: Title
**Author**: X | **Repo**: Y | **Status**: Z

### What This PR Does
(1-3 sentences from PR description + Jira ticket)

### Why It Exists
(From Jira: what problem it solves, business context)

### Design Context
(From Confluence: agreed approach, constraints)

### Slack Discussion
(Relevant discussion, concerns raised, alternatives considered)

### Files Changed
(High-level summary, concerning patterns)

### Review Considerations
(What to focus on during review: design alignment, edge cases, Slack concerns, PR size)
```

## Important Notes

- The point is to make code review INFORMED. Context prevents superficial reviews.
- If no Jira ticket is found, flag this.
- If the PR is large (20+ files), suggest reviewing in logical chunks.
- After running this, the user will likely switch to a worktree to review the code.
