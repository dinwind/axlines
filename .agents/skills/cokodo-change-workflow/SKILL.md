---
name: cokodo-change-workflow
description: |
  Create, apply, track, or archive a spec-driven change under .agent/project/changes/. Use
  when starting a feature, running co change, or finishing an SDD unit.
paths:
  - "**/.agent/project/changes/**"
---

<!-- generated-by: co skills export -->

# Cokodo Change Workflow

## When to use

Starting a feature as an SDD change, or finishing / archiving one.

## When starting

1. Run `co change new <kebab-name>` (or `--schema minimal` for small fixes).
2. Edit `proposal.md` / `specs.md` / `design.md` as needed.
3. Run `co change apply <name>` so `status.md` and `.active` point at the folder.
4. Implement using `tasks.md` checkboxes; run `co change status <name>` to re-read.

## When finishing

1. Run `co change archive <name>` (add `--merge-specs` to copy specs into
   `project/specs/_archive/`).
2. Run `co change clear` if needed.

## List

`co change list` — the active change is marked with `*`.
