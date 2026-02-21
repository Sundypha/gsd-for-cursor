---
tools:
  read: true
  write: true
  bash: true
name: gsd-add-phase
description: Add phase to end of current milestone in roadmap
argument-hint: <description>

<objective>
Add a new integer phase to the end of the current milestone in the roadmap.

Routes to the add-phase workflow which handles:
</objective>

<execution_context>
@~/.cursor/get-shit-done/workflows/add-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS (phase description)

Roadmap and state are resolved in-workflow via `init phase-op` and targeted tool calls.
</context>

<process>
**Follow the add-phase workflow** from `@~/.cursor/get-shit-done/workflows/add-phase.md`.

The workflow handles all logic including:
1. Argument parsing and validation
2. Roadmap existence checking
3. Current milestone identification
4. Next phase number calculation (ignoring decimals)
5. Slug generation from description
6. Phase directory creation
7. Roadmap entry insertion
8. STATE.md updates
</process>
