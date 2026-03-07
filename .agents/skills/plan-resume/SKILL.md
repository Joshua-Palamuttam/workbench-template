---
name: plan-resume
description: Generate a self-contained continuation prompt for resuming implementation of a feature plan. Reads plan.md + progress.md + handoff.md and produces output ready to paste into the target repo.
argument-hint: <plan-name>
---

# Plan Resume

Generate a self-contained continuation prompt for resuming implementation of a feature plan in the target repo. The output contains everything the implementing session needs — no additional file reads required to get started.

## Usage

```
/plan-resume <plan-name>
```

## Process

### Step 1: Load Artifacts

1. **Determine the plan name** from the first argument (`$0`). If no argument, use `AskUserQuestion` to get it.
2. **Read all three artifacts** from `context/plans/active/<plan-name>/`:
   - `plan.md` — the full implementation plan (step specs, project structure, verification)
   - `progress.md` — current implementation state (progress table, blockers, decisions, session log)
   - `handoff.md` — original handoff with hard rules, critical files, runtime API reference
3. If `progress.md` doesn't exist, tell the user: "No progress tracked yet. Copy `handoff.md` to the target repo for the first session. Progress tracking will start automatically."
4. If `plan.md` doesn't exist, error: "No plan found for `<plan-name>`. Run `/plan-create <plan-name>` first."

### Step 2: Extract State from progress.md

Parse these sections from `progress.md`:

- **Summary**: plan name, target repo, branch, overall status
- **Progress Overview table**: step numbers, statuses, notes. Count DONE / BLOCKED / PENDING.
- **Active Blockers table**: current blockers with severity and affected steps
- **Decision Changelog**: all DC-xxx entries
- **Session Log**: the most recent entry (for "next session should" and codebase state)
- **Step Details**: files created/modified per completed step

### Step 3: Identify Current + Remaining Work

From the Progress Overview table:
1. **Current step**: the first step with status BLOCKED or PENDING (not DONE)
2. **Remaining steps**: all steps after the current step that are not DONE
3. From `plan.md`, extract the **full spec** for the current step (the complete section from the plan, not just the one-liner from the progress table)

### Step 4: Filter Critical Files

From `handoff.md`, read the "Critical existing files to read before coding" and "Backend reference" tables. Filter to only files relevant to remaining work:
- If a file was only needed for completed steps, exclude it
- If unsure, include it (better to over-inform than under-inform)

### Step 5: Generate the Resume Prompt

Output the following sections **as a single markdown document** that the user will copy-paste into a Claude Code session in the target repo. Present it in a code fence so it's easy to copy.

---

**Resume prompt structure:**

```markdown
# Resume: [Plan Name] — Session Continuation

## What This Is

You are continuing implementation of [plan name]. This prompt contains everything you need — do not read additional files to get started.

**Plan**: [path to plan.md in command center]
**Branch**: [branch from progress.md summary]
**Overall status**: [from progress.md summary]
**Last session**: [date from most recent session log entry]

## Original Context

[From handoff.md: the "Strategic Context" or opening section — what/why in 2-3 sentences]

## Current State

**Progress**: [X/Y steps done, Z blocked, W pending]

**Active blockers**:
[List each blocker from Active Blockers table with ID, severity, and description]
[If no blockers: "None"]

**Codebase state**: [Verbatim from the most recent Session Log's "Codebase state" field]

## Decision Changes

These decisions were changed during implementation. Do not re-open them:

[Table of all DC-xxx entries from Decision Changelog. If none: "No decision changes yet."]

## Completed Steps

[For each DONE step from Progress Overview: step number, name, and key files from Step Details]

## What To Do Next

[Verbatim "next session should" instructions from the most recent Session Log entry]

### Current Step: [step number] — [step name from plan]

[Full step specification copied from plan.md — the complete section, not the one-liner]

## Remaining Steps

| # | Step | Status | Notes |
[Only non-DONE steps from Progress Overview table]

## Critical Files

[Filtered file tables from handoff.md — only files relevant to remaining work]

## Hard Rules

[Verbatim "Hard rules" section from handoff.md]

## Progress Tracking

After each step, update progress at:
`[COMMAND_CENTER_PATH]/context/plans/active/[PLAN_NAME]/progress.md`

Rules:
- Update Progress Overview table status + notes
- Add Step Details entry with files created/modified
- Add Session Log entry on every stop (newest first)
- Add Decision Changelog entry (DC-XXX) for any plan deviations
- Update Summary's "Last updated" and "Overall status"
```

---

### Step 6: Present to User

After generating the resume prompt:
1. Show a brief summary: "Resume prompt generated for `<plan-name>`. X/Y steps done, Z blockers, last session [date]."
2. Output the full resume prompt in a code fence for easy copying
3. Remind: "Copy this into a Claude Code session in the target repo to continue implementation."

## Key Principles

- **Self-contained.** The resume prompt must contain everything needed to continue. A new session in the target repo should not need to read plan.md, progress.md, or handoff.md separately.
- **Verbatim where it matters.** "Next session should" instructions and "Hard rules" are copied verbatim — don't paraphrase or summarize these.
- **Current step gets the full spec.** The one-liner in the progress table isn't enough. Copy the complete step section from plan.md so the implementing agent has all the details.
- **Don't re-open decisions.** Decision changes are presented as facts, not open questions. The implementing session should not re-litigate them.
- **Filter, don't dump.** Critical files are filtered to remaining work. Completed step details are summarized, not dumped in full.

## Important Notes

- This skill only reads files and generates output. It does not modify any artifacts.
- If `progress.md` has no Session Log entries, use the handoff.md's implementation order as the "what to do next" source.
- The resume prompt targets a Claude Code session in a **different repo**. All paths to command center files must be absolute.
