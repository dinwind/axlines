---
name: cokodo-session-start
description: |
  Establish cokodo protocol context at the start of a session, or after context is
  compacted or lost. Reads project status, any active SDD change, and known issues before
  work begins.
---

<!-- generated-by: co skills export -->

# Cokodo Session Start

## When to use

At the first turn of a session, after `/compact`, or whenever you are unsure what the
current task is.

## Steps

1. Read `.agent/project/status.md` — goals, task board, blockers, session context.
2. If it shows **Active change (SDD)**, or `.agent/project/changes/.active` exists, read
   `.agent/project/changes/<name>/tasks.md`. That directory is the working scope until
   `co change clear` or archive.
3. Read `.agent/project/known-issues.md` for the area you are about to touch.
4. Read `.agent/start-here.md` if you need the full protocol index.

If the Cokodo MCP server is available, `session_gate` performs the equivalent check and
also reports package/protocol drift.

## Do not

- Do not start editing before reading `status.md`; stale context causes rework.
- Do not treat an IDE-local plan draft as the project plan (see `cokodo-artifacts`).
