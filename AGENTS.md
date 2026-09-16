# Project

**Authority**: rules under `.agent/` and this file are the single source of truth for this
project; user/global IDE rules govern editor behavior only. On conflict, follow `.agent/`.

## Session entry

1. Read `.agent/project/status.md` **first, every session** — current goals, tasks, blockers.
2. If it shows **Active change (SDD)**, or `.agent/project/changes/.active` exists, read
   `.agent/project/changes/<name>/tasks.md` next before coding.
3. `.agent/start-here.md` is the protocol entry point and indexes the rest:
   `.agent/project/context.md` (business context), `.agent/project/tech-stack.md`,
   `.agent/project/commands.md`, `.agent/project/deploy.md`, and
   `.agent/core/core-rules.md` (non-negotiable principles).

Check `.agent/project/known-issues.md` before touching an area it names.

## Protocol map (load on demand)

`.agent/core/protocol-map.md` documents the `project/` directory roles, the artifact
index rules, plan governance, and the cross-project MCP workflow.

Read it when you need to **write or update a project artifact** (plan, research report,
review, spec, event, journal fragment), or when a task **involves another project** on
this machine. Writing an artifact without registering it in its index is incomplete work.

## Hard rules

- **Encoding**: UTF-8, declared explicitly when reading/writing files.
- **Paths**: forward slash `/` in commands, cross-platform.
- **Test data**: must use the `autotest_` prefix.
- **No external CDN links** — localize all assets.
- **Git commit on Windows/PowerShell**: use `-F .git/COMMIT_MSG_TMP`; `<<'EOF'` heredoc is
  not supported by PowerShell. See `.agent/core/conventions.md` §3.4.
- **Session state**: update at checkpoints. Product PRs write `.agent/project/journal.d/`
  fragments and must not edit `status.md`; `Recently Completed` is capped at 5 items and
  synced by `co journal-flush`. See `project/AGENT-GIT-PR-WORKFLOW.md`.
- **Agent Git/PR (three hard rules)** — see `project/AGENT-GIT-PR-WORKFLOW.md` and `project/sop/agent-git-pr-collaboration.md`:
  1. One PR per branch; after merge run `co branch cleanup <head>` — **remote head deletion is mandatory**.
  2. Product PRs must not edit `status.md`; write `project/journal.d/` fragments; sync via `chore/agent-status-*` + `co journal-flush`.
  3. Before merge: integrate the latest default branch; PR must be mergeable; re-approve after new pushes if required.

## Task-scoped reading

| Task | Read first |
|------|------------|
| UI / frontend | `core/workflows/ui-design-workflow.md` + `project/specs/*-ui*.md` |
| Release / version governance | `core/workflows/version-governance-workflow.md`, `project/versioning.md`, `project/version-state.toml`, `project/sop/release.md` |
| Another project on this machine | `core/protocol-map.md` §4 |
