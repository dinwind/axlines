---
name: cokodo-artifacts
description: |
  Write or update a cokodo project artifact — plan, research report, review, spec,
  cross-project event, or journal fragment — and register it in the matching index so
  agents can discover it.
---

<!-- generated-by: co skills export -->

# Cokodo Artifacts

## When to use

Any time you produce a durable document for the project rather than code.

## Rule

Writing an artifact **without registering it in its index is incomplete work**. Agents
discover artifacts through the index, not by listing directories.

## Where things go

| You are writing | File | Then update |
|-----------------|------|-------------|
| An approved or long-lived plan | `.agent/project/plan/<kebab-name>.md` | `plan/plan-index.md` |
| Research, survey, comparison | `.agent/project/research/<name>.md` | `research/research-index.md` |
| A formal review or audit | `.agent/project/review/<name>.md` | `review/review-index.md` |
| A spec | `.agent/project/specs/<name>.md` | `specs/specs-index.md` |
| A notice for another project on this machine | `.agent/project/events/<date>-<name>.md` | `events/events-index.md` |
| Completed work in a product PR | `.agent/project/journal.d/<date>-<name>.md` | batch via `co journal-flush` |

Keep the filename column exact and in backticks so `co lint --rule artifact-indexes`
can match it against disk.

## Full reference

`.agent/core/protocol-map.md` — directory roles, index rules, and plan governance.
