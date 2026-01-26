# GSD to Cursor: Complete Adaptation Guide

> **Purpose:** This document provides everything needed to recreate the "Get Shit Done" (GSD) meta-prompting system from Claude Code for Cursor IDE.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Terminology Mapping](#terminology-mapping)
4. [Directory Structure](#directory-structure)
5. [Command Format Adaptation](#command-format-adaptation)
6. [Agent Definition Adaptation](#agent-definition-adaptation)
7. [Subagent Spawning](#subagent-spawning)
8. [Tool Name Mapping](#tool-name-mapping)
9. [Path Reference Changes](#path-reference-changes)
10. [Hooks System](#hooks-system)
11. [Configuration System](#configuration-system)
12. [Core Workflow Pattern](#core-workflow-pattern)
13. [XML Task Format](#xml-task-format)
14. [Context Engineering Rules](#context-engineering-rules)
15. [File-by-File Conversion Guide](#file-by-file-conversion-guide)
16. [Implementation Checklist](#implementation-checklist)
17. [Testing Guide](#testing-guide)

---

## Executive Summary

GSD is a **meta-prompting, context engineering, and spec-driven development system** that solves "context rot" — the quality degradation that happens as AI fills its context window. It provides a structured workflow for solo developers using AI tools to build software reliably.

### Core Philosophy

1. **Solo Developer + AI Workflow** — No enterprise patterns, no team coordination
2. **Context Engineering** — Manage AI's context window deliberately to maintain quality
3. **Plans as Prompts** — PLAN.md files are executable prompts, not documents that become prompts
4. **Fresh Context Pattern** — Use subagents for heavy work, preserve main context for user interaction
5. **Atomic Git Commits** — Each task gets its own traceable commit

### What GSD Provides

- **27 slash commands** for project lifecycle management
- **11 specialized agents** for different tasks (planning, execution, verification, research)
- **Workflow documents** with detailed process logic
- **Templates** for generated artifacts
- **Reference documents** for deep guidance
- **Hooks** for session events

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER INTERACTION                               │
│                                                                          │
│   /gsd-new-project → /gsd-plan-phase → /gsd-execute-phase → /gsd-verify │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         COMMAND LAYER                                    │
│                                                                          │
│   Thin wrappers that delegate to workflows                               │
│   Located: ~/.cursor/commands/gsd/                                       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         WORKFLOW LAYER                                   │
│                                                                          │
│   Detailed process logic with steps                                      │
│   Located: ~/.cursor/get-shit-done/workflows/                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │   AGENTS    │ │  TEMPLATES  │ │ REFERENCES  │
            │             │ │             │ │             │
            │ Specialized │ │ Output      │ │ Deep        │
            │ workers     │ │ formats     │ │ guidance    │
            └─────────────┘ └─────────────┘ └─────────────┘
```

### Multi-Agent Orchestration Pattern

```
┌────────────────────────────────────────────┐
│            ORCHESTRATOR                    │
│  (Thin, ~15% context)                      │
│  - Discovers plans                         │
│  - Groups into waves                       │
│  - Spawns subagents                        │
│  - Collects results                        │
│  - Routes to next step                     │
└─────────────────┬──────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
    ▼             ▼             ▼
┌────────┐  ┌────────┐  ┌────────┐
│Subagent│  │Subagent│  │Subagent│
│ (100%  │  │ (100%  │  │ (100%  │
│ fresh) │  │ fresh) │  │ fresh) │
└────────┘  └────────┘  └────────┘
     │           │           │
     └───────────┴───────────┘
                 │
                 ▼
         Results returned
         to orchestrator
```

---

## Terminology Mapping

### Complete Mapping Table

| Claude Code | Cursor | Notes |
|-------------|--------|-------|
| `Task()` tool | Subagent spawning | Same concept — spawns isolated context agent |
| Slash Command (`/gsd:*`) | Slash Command (`/gsd-*`) | **Cursor uses hyphen, not colon** |
| `.claude/` directory | `.cursor/` directory | Different config root |
| `~/.claude/` global | `~/.cursor/` global | Different global path |
| `allowed-tools` frontmatter | `tools` frontmatter | Different key name |
| `AskUserQuestion` tool | `ask_question` tool | Different tool name (snake_case) |
| `TodoWrite` tool | `todo_write` tool | Different tool name (snake_case) |
| `WebFetch` tool | `web_fetch` tool | Different tool name (snake_case) |
| `WebSearch` tool | `web_search` tool | Different tool name (snake_case) |
| `$CLAUDE_PROJECT_DIR` | Workspace path | Different env var |
| Skill files | Command files | Cursor calls them "commands" |
| `subagent_type` parameter | Subagent definition | Cursor has built-in subagent types |
| Color names (`yellow`) | Hex values (`#FFFF00`) | Frontmatter color format |

### Tool Name Mapping (Complete)

| Claude Code Tool | Cursor Tool |
|------------------|-------------|
| `Read` | `read` |
| `Write` | `write` |
| `Edit` | `edit` |
| `Bash` | `bash` |
| `Glob` | `glob` |
| `Grep` | `grep` |
| `Task` | (subagent mechanism) |
| `AskUserQuestion` | `ask_question` |
| `TodoWrite` | `todo_write` |
| `WebFetch` | `web_fetch` |
| `WebSearch` | `web_search` |
| `MultiEdit` | `multi_edit` |
| `mcp__context7__*` | `mcp__context7__*` (same) |

### Color Name to Hex Mapping

| Color Name | Hex Value |
|------------|-----------|
| `cyan` | `#00FFFF` |
| `red` | `#FF0000` |
| `green` | `#00FF00` |
| `blue` | `#0000FF` |
| `yellow` | `#FFFF00` |
| `magenta` | `#FF00FF` |
| `orange` | `#FFA500` |
| `purple` | `#800080` |
| `pink` | `#FFC0CB` |
| `white` | `#FFFFFF` |
| `gray` / `grey` | `#808080` |

---

## Directory Structure

### Claude Code Structure

```
~/.claude/
├── commands/
│   └── gsd/
│       ├── new-project.md
│       ├── plan-phase.md
│       ├── execute-phase.md
│       ├── verify-work.md
│       ├── discuss-phase.md
│       ├── research-phase.md
│       ├── progress.md
│       ├── help.md
│       ├── settings.md
│       ├── update.md
│       ├── quick.md
│       ├── debug.md
│       ├── add-phase.md
│       ├── insert-phase.md
│       ├── remove-phase.md
│       ├── add-todo.md
│       ├── check-todos.md
│       ├── pause-work.md
│       ├── resume-work.md
│       ├── map-codebase.md
│       ├── new-milestone.md
│       ├── complete-milestone.md
│       ├── audit-milestone.md
│       ├── plan-milestone-gaps.md
│       ├── list-phase-assumptions.md
│       ├── set-profile.md
│       └── join-discord.md
├── agents/
│   ├── gsd-executor.md
│   ├── gsd-planner.md
│   ├── gsd-verifier.md
│   ├── gsd-phase-researcher.md
│   ├── gsd-roadmapper.md
│   ├── gsd-project-researcher.md
│   ├── gsd-research-synthesizer.md
│   ├── gsd-plan-checker.md
│   ├── gsd-debugger.md
│   ├── gsd-codebase-mapper.md
│   └── gsd-integration-checker.md
├── get-shit-done/
│   ├── workflows/
│   │   ├── execute-phase.md
│   │   ├── execute-plan.md
│   │   ├── verify-phase.md
│   │   ├── verify-work.md
│   │   ├── discuss-phase.md
│   │   ├── discovery-phase.md
│   │   ├── diagnose-issues.md
│   │   ├── map-codebase.md
│   │   ├── complete-milestone.md
│   │   ├── resume-project.md
│   │   ├── transition.md
│   │   └── list-phase-assumptions.md
│   ├── templates/
│   │   ├── project.md
│   │   ├── requirements.md
│   │   ├── roadmap.md
│   │   ├── state.md
│   │   ├── summary.md
│   │   ├── context.md
│   │   ├── research.md
│   │   ├── discovery.md
│   │   ├── phase-prompt.md
│   │   ├── planner-subagent-prompt.md
│   │   ├── debug-subagent-prompt.md
│   │   ├── verification-report.md
│   │   ├── milestone.md
│   │   ├── milestone-archive.md
│   │   ├── continue-here.md
│   │   ├── config.json
│   │   ├── user-setup.md
│   │   ├── DEBUG.md
│   │   ├── UAT.md
│   │   ├── codebase/
│   │   │   ├── architecture.md
│   │   │   ├── stack.md
│   │   │   ├── conventions.md
│   │   │   ├── structure.md
│   │   │   ├── testing.md
│   │   │   ├── integrations.md
│   │   │   └── concerns.md
│   │   └── research-project/
│   │       ├── SUMMARY.md
│   │       ├── STACK.md
│   │       ├── FEATURES.md
│   │       ├── ARCHITECTURE.md
│   │       └── PITFALLS.md
│   └── references/
│       ├── questioning.md
│       ├── checkpoints.md
│       ├── ui-brand.md
│       ├── tdd.md
│       ├── verification-patterns.md
│       ├── git-integration.md
│       ├── model-profiles.md
│       ├── planning-config.md
│       └── continuation-format.md
├── hooks/
│   ├── gsd-statusline.js
│   └── gsd-check-update.js
└── settings.json
```

### Cursor Structure (Adapted)

```
~/.cursor/
├── commands/
│   └── gsd/
│       ├── new-project.md      # /gsd-new-project
│       ├── plan-phase.md       # /gsd-plan-phase
│       ├── execute-phase.md    # /gsd-execute-phase
│       └── ... (same files, adapted format)
├── agents/
│   ├── gsd-executor.md
│   ├── gsd-planner.md
│   └── ... (same files, adapted format)
├── get-shit-done/
│   ├── workflows/
│   ├── templates/
│   └── references/
├── hooks/
│   ├── gsd-statusline.js
│   └── gsd-check-update.js
└── settings.json
```

---

## Command Format Adaptation

### Claude Code Command Format

```yaml
---
name: gsd:new-project
description: Initialize a new project with deep context gathering and PROJECT.md
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---

<objective>
Initialize a new project through unified flow...
</objective>

<execution_context>
@~/.claude/get-shit-done/references/questioning.md
@~/.claude/get-shit-done/references/ui-brand.md
@~/.claude/get-shit-done/templates/project.md
</execution_context>

<process>
## Phase 1: Setup
...
</process>

<success_criteria>
- [ ] Criteria 1
- [ ] Criteria 2
</success_criteria>
```

### Cursor Command Format (Adapted)

```yaml
---
name: gsd-new-project
description: Initialize a new project with deep context gathering and PROJECT.md
tools:
  read: true
  bash: true
  write: true
  ask_question: true
---

<objective>
Initialize a new project through unified flow...
</objective>

<execution_context>
@~/.cursor/get-shit-done/references/questioning.md
@~/.cursor/get-shit-done/references/ui-brand.md
@~/.cursor/get-shit-done/templates/project.md
</execution_context>

<process>
## Phase 1: Setup
...
</process>

<success_criteria>
- [ ] Criteria 1
- [ ] Criteria 2
</success_criteria>
```

### Key Command Changes

1. **Name format**: `gsd:command-name` → `gsd-command-name`
2. **Tools format**: Array of strings → Object with boolean values
3. **Tool names**: PascalCase → snake_case
4. **Path references**: `~/.claude/` → `~/.cursor/`
5. **Command invocations in content**: `/gsd:` → `/gsd-`

---

## Agent Definition Adaptation

### Claude Code Agent Format

```yaml
---
name: gsd-executor
description: Executes GSD plans with atomic commits, deviation handling, checkpoint protocols, and state management.
tools: Read, Write, Edit, Bash, Grep, Glob
color: yellow
---

<role>
You are a GSD plan executor...
</role>

<execution_flow>
<step name="load_project_state" priority="first">
...
</step>
</execution_flow>

<success_criteria>
- [ ] All tasks executed
- [ ] Each task committed individually
</success_criteria>
```

### Cursor Agent Format (Adapted)

```yaml
---
name: gsd-executor
description: Executes GSD plans with atomic commits, deviation handling, checkpoint protocols, and state management.
tools:
  read: true
  write: true
  edit: true
  bash: true
  grep: true
  glob: true
color: "#FFFF00"
---

<role>
You are a GSD plan executor...
</role>

<execution_flow>
<step name="load_project_state" priority="first">
...
</step>
</execution_flow>

<success_criteria>
- [ ] All tasks executed
- [ ] Each task committed individually
</success_criteria>
```

### Key Agent Changes

1. **Tools format**: Comma-separated string → Object with booleans
2. **Color format**: Name → Hex value
3. **Path references in content**: Update all `~/.claude/` to `~/.cursor/`

---

## Subagent Spawning

### Claude Code: Task() Tool

In Claude Code, subagents are spawned using the `Task()` tool:

```python
Task(
    prompt="First, read ~/.claude/agents/gsd-executor.md for your role and instructions.
    
<objective>
Execute plan {plan_number} of phase {phase_number}-{phase_name}.
</objective>

<context>
Plan:
{plan_content}

Project state:
{state_content}
</context>",
    subagent_type="gsd-executor",
    model="sonnet",
    description="Execute phase plan"
)
```

### Cursor: Subagent Mechanism

Cursor handles subagents differently. The concept is the same:
- Each subagent gets isolated context (fresh 100% context window)
- Multiple subagents can run in parallel
- Results return to the orchestrator

**Adaptation Strategy:**

1. Keep the agent definition files (`agents/gsd-*.md`)
2. Keep the prompt structure with role, context, and instructions
3. Adapt the spawning syntax to Cursor's native mechanism
4. The orchestrator pattern remains the same

### Parallel Execution Pattern

```
Orchestrator spawns multiple subagents simultaneously:

Wave 1: [Plan 01, Plan 02] → Run in parallel
        ↓ Wait for completion
Wave 2: [Plan 03] → Depends on Wave 1
        ↓ Wait for completion  
Wave 3: [Plan 04, Plan 05] → Run in parallel
```

---

## Path Reference Changes

### Global Search and Replace

| Find | Replace |
|------|---------|
| `~/.claude/` | `~/.cursor/` |
| `.claude/` | `.cursor/` |
| `@~/.claude/get-shit-done/` | `@~/.cursor/get-shit-done/` |
| `/gsd:` | `/gsd-` |
| `$CLAUDE_PROJECT_DIR` | Cursor workspace path equivalent |

### Examples

**Before (Claude Code):**
```markdown
<execution_context>
@~/.claude/get-shit-done/workflows/execute-phase.md
@~/.claude/get-shit-done/templates/summary.md
@~/.claude/get-shit-done/references/checkpoints.md
</execution_context>
```

**After (Cursor):**
```markdown
<execution_context>
@~/.cursor/get-shit-done/workflows/execute-phase.md
@~/.cursor/get-shit-done/templates/summary.md
@~/.cursor/get-shit-done/references/checkpoints.md
</execution_context>
```

**Before (Claude Code):**
```markdown
Next: `/gsd:plan-phase 1`
Also available: `/gsd:discuss-phase 1`
```

**After (Cursor):**
```markdown
Next: `/gsd-plan-phase 1`
Also available: `/gsd-discuss-phase 1`
```

---

## Hooks System

### Claude Code Hooks Configuration

Located in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.claude/hooks/gsd-check-update.js"
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/hooks/gsd-statusline.js"
  }
}
```

### Cursor Hooks Configuration

Located in `~/.cursor/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.cursor/hooks/gsd-check-update.js"
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "node ~/.cursor/hooks/gsd-statusline.js"
  }
}
```

### Hook Events Supported

| Event | Matcher Required | Description |
|-------|------------------|-------------|
| `PreToolUse` | Yes | Runs before tool execution |
| `PostToolUse` | Yes | Runs after tool execution |
| `UserPromptSubmit` | No | When user submits prompt |
| `Notification` | No | System notifications |
| `Stop` | No | Session stop |
| `SubagentStop` | No | Subagent completion |
| `SessionStart` | No | Session initialization |

### Hook Script Adaptation

**gsd-statusline.js changes:**
- Update path references from `.claude` to `.cursor`
- Update environment variable references

**gsd-check-update.js changes:**
- Update VERSION file path
- Update cache directory path

---

## Configuration System

### Project Configuration (`.planning/config.json`)

This file stays the same — it's project-level, not platform-specific:

```json
{
  "mode": "yolo",
  "depth": "standard",
  "parallelization": true,
  "commit_docs": true,
  "model_profile": "balanced",
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true
  }
}
```

### Mode Options

| Mode | Description |
|------|-------------|
| `yolo` | Auto-approve, just execute |
| `interactive` | Confirm at each step |

### Depth Options

| Depth | Phases | Plans/Phase | Description |
|-------|--------|-------------|-------------|
| `quick` | 3-5 | 1-3 | Ship fast, critical path only |
| `standard` | 5-8 | 3-5 | Balanced scope and speed |
| `comprehensive` | 8-12 | 5-10 | Thorough coverage |

### Model Profiles

| Profile | Planning | Execution | Verification |
|---------|----------|-----------|--------------|
| `quality` | opus | opus | sonnet |
| `balanced` | opus | sonnet | sonnet |
| `budget` | sonnet | sonnet | haiku |

---

## Core Workflow Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│                    /gsd-new-project                             │
│                                                                 │
│  Questions → Research (4 parallel agents) → Requirements →      │
│  Roadmap → STATE.md                                             │
│                                                                 │
│  Creates: PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    /gsd-discuss-phase N                         │
│                                                                 │
│  Identifies gray areas → User decisions → CONTEXT.md            │
│                                                                 │
│  Creates: {phase}-CONTEXT.md                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    /gsd-plan-phase N                            │
│                                                                 │
│  Research → Creates PLAN.md files → Plan checker verifies       │
│                                                                 │
│  Creates: {phase}-RESEARCH.md, {phase}-{N}-PLAN.md              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    /gsd-execute-phase N                         │
│                                                                 │
│  Wave-based parallel execution → Per-task commits →             │
│  SUMMARY.md → Verification → STATE.md update                    │
│                                                                 │
│  Creates: {phase}-{N}-SUMMARY.md, {phase}-VERIFICATION.md       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    /gsd-verify-work N                           │
│                                                                 │
│  Manual UAT → Debug agents diagnose failures →                  │
│  Fix plans created if needed                                    │
│                                                                 │
│  Creates: {phase}-UAT.md, fix plans if issues found             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                     Repeat for each phase
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    /gsd-complete-milestone                      │
│                                                                 │
│  Archive milestone, tag release, start next milestone           │
└─────────────────────────────────────────────────────────────────┘
```

---

## XML Task Format

Plans use XML for precise, executable tasks. This format stays the same:

```xml
<task type="auto">
  <name>Task 1: Create login endpoint with JWT</name>
  <files>src/app/api/auth/login/route.ts</files>
  <action>
    POST endpoint accepting {email, password}.
    Query User by email, compare password with bcrypt.
    On match, create JWT with jose library (not jsonwebtoken - CommonJS issues).
    Set as httpOnly cookie. Return 200.
    On mismatch, return 401.
  </action>
  <verify>curl -X POST localhost:3000/api/auth/login returns 200 with Set-Cookie header</verify>
  <done>Valid credentials → 200 + cookie. Invalid → 401.</done>
</task>
```

### Task Types

| Type | Description | Behavior |
|------|-------------|----------|
| `type="auto"` | AI executes autonomously | No user interaction |
| `type="checkpoint:human-verify"` | User verifies work | Pauses for approval |
| `type="checkpoint:decision"` | User makes choice | Pauses for selection |
| `type="checkpoint:human-action"` | Rare manual steps | Pauses for user action |

### Checkpoint Examples

**Human Verify:**
```xml
<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Complete auth flow (schema + API + UI)</what-built>
  <how-to-verify>
    1. Visit http://localhost:3000/login
    2. Enter test@example.com / password123
    3. Should redirect to /dashboard
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>
```

**Decision:**
```xml
<task type="checkpoint:decision" gate="blocking">
  <decision>Authentication approach</decision>
  <context>Project needs user auth. Multiple valid approaches.</context>
  <options>
    <option id="jwt">
      <name>JWT with httpOnly cookies</name>
      <pros>Stateless, scalable</pros>
      <cons>Token rotation complexity</cons>
    </option>
    <option id="session">
      <name>Server-side sessions</name>
      <pros>Simple, easy revocation</pros>
      <cons>Requires session store</cons>
    </option>
  </options>
  <resume-signal>Select: jwt or session</resume-signal>
</task>
```

---

## Context Engineering Rules

### Context Usage Guidelines

| Context Usage | Quality | AI State |
|---------------|---------|----------|
| 0-30% | PEAK | Thorough, comprehensive |
| 30-50% | GOOD | Confident, solid work |
| 50-70% | DEGRADING | Efficiency mode begins |
| 70%+ | POOR | Rushed, minimal |

### Rules

- **Plans**: 2-3 tasks maximum
- **Target**: ~50% context per plan
- **Subagents**: Use fresh subagents for heavy work
- **Orchestrator**: Stays at ~15% context

### Split Signals

**ALWAYS split if:**
- More than 3 tasks
- Multiple subsystems (DB + API + UI)
- Any task with >5 file modifications
- Checkpoint + implementation in same plan

**CONSIDER splitting:**
- Estimated >5 files modified total
- Complex domains (auth, payments)
- Any uncertainty about approach

---

## File-by-File Conversion Guide

### Commands (27 files)

For each file in `commands/gsd/`:

1. **Frontmatter changes:**
   ```yaml
   # Before
   name: gsd:command-name
   allowed-tools:
     - Read
     - Write
     - Task
     - AskUserQuestion
   
   # After
   name: gsd-command-name
   tools:
     read: true
     write: true
     ask_question: true
   ```

2. **Content changes:**
   - Replace `~/.claude/` → `~/.cursor/`
   - Replace `/gsd:` → `/gsd-`
   - Replace `AskUserQuestion` → `ask_question`
   - Replace `TodoWrite` → `todo_write`

### Agents (11 files)

For each file in `agents/`:

1. **Frontmatter changes:**
   ```yaml
   # Before
   tools: Read, Write, Edit, Bash, Grep, Glob
   color: yellow
   
   # After
   tools:
     read: true
     write: true
     edit: true
     bash: true
     grep: true
     glob: true
   color: "#FFFF00"
   ```

2. **Content changes:**
   - Replace all path references
   - Replace all command invocations
   - Replace tool names in prose

### Workflows (12 files)

For each file in `get-shit-done/workflows/`:

1. **Path references:**
   - Replace `@~/.claude/` → `@~/.cursor/`
   - Replace `.claude/` → `.cursor/`

2. **Command references:**
   - Replace `/gsd:` → `/gsd-`

3. **Tool references:**
   - Update tool names in documentation

### Templates (20+ files)

For each file in `get-shit-done/templates/`:

1. **Path references:**
   - Replace all `.claude/` references

2. **Command references:**
   - Replace all `/gsd:` references

### References (9 files)

For each file in `get-shit-done/references/`:

1. **Path references and command references** (same as above)

2. **Tool name examples:**
   - Update any tool usage examples

### Hooks (2 files)

**gsd-statusline.js:**
```javascript
// Update paths
const todosDir = path.join(homeDir, '.cursor', 'todos');
const cacheFile = path.join(homeDir, '.cursor', 'cache', 'gsd-update-check.json');
```

**gsd-check-update.js:**
```javascript
// Update paths
const projectVersionFile = path.join(cwd, '.cursor', 'get-shit-done', 'VERSION');
const globalVersionFile = path.join(homeDir, '.cursor', 'get-shit-done', 'VERSION');
```

---

## Implementation Checklist

### Phase 1: Core Infrastructure

- [ ] Create installer script for `.cursor/` directory
- [ ] Set up directory structure
- [ ] Create settings.json template

### Phase 2: Commands

- [ ] Convert all 27 command files
- [ ] Update frontmatter format
- [ ] Update path references
- [ ] Update command invocations
- [ ] Test each command loads correctly

### Phase 3: Agents

- [ ] Convert all 11 agent files
- [ ] Update frontmatter format
- [ ] Update color values to hex
- [ ] Update path references
- [ ] Test agent definitions load

### Phase 4: Workflows

- [ ] Convert all 12 workflow files
- [ ] Update path references
- [ ] Update command references
- [ ] Adapt subagent spawning syntax

### Phase 5: Templates

- [ ] Convert all template files
- [ ] Update path references
- [ ] Update command references

### Phase 6: References

- [ ] Convert all 9 reference files
- [ ] Update examples and documentation

### Phase 7: Hooks

- [ ] Update hook scripts with new paths
- [ ] Configure settings.json for hooks
- [ ] Test hook execution

### Phase 8: Testing

- [ ] Test `/gsd-help` displays commands
- [ ] Test `/gsd-new-project` creates structure
- [ ] Test subagent spawning
- [ ] Test file references (@)
- [ ] Test hooks trigger correctly
- [ ] Test complete workflow end-to-end

---

## Testing Guide

### Basic Functionality Tests

1. **Help Command**
   ```
   /gsd-help
   ```
   Expected: All commands displayed with descriptions

2. **New Project**
   ```
   /gsd-new-project
   ```
   Expected: Creates `.planning/` with PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md

3. **Progress Check**
   ```
   /gsd-progress
   ```
   Expected: Shows current phase, plan, and progress bar

### Workflow Tests

1. **Full Cycle Test**
   ```
   /gsd-new-project
   /gsd-discuss-phase 1
   /gsd-plan-phase 1
   /gsd-execute-phase 1
   /gsd-verify-work 1
   ```
   Expected: Complete phase with all artifacts generated

2. **Parallel Execution Test**
   - Create phase with multiple independent plans
   - Run `/gsd-execute-phase`
   - Verify plans in same wave run in parallel

3. **Checkpoint Test**
   - Plan with checkpoint task
   - Verify execution pauses at checkpoint
   - Verify continuation after user input

### File Reference Tests

1. **@ Mentions**
   - Verify `@~/.cursor/get-shit-done/...` references work
   - Verify `@.planning/...` references work

2. **Template Loading**
   - Verify templates are found and loaded
   - Verify path replacements applied correctly

### Hook Tests

1. **Session Start**
   - Start new session
   - Verify update check runs

2. **Statusline**
   - Verify context percentage displays
   - Verify model name displays

---

## Generated Artifacts Structure

When GSD runs, it creates this structure:

```
.planning/
├── PROJECT.md           # Project vision, requirements, decisions
├── REQUIREMENTS.md      # Scoped v1/v2 with REQ-IDs
├── ROADMAP.md           # Phase structure with success criteria
├── STATE.md             # Living memory, current position
├── config.json          # Workflow settings
├── research/            # Domain research (if enabled)
│   ├── STACK.md
│   ├── FEATURES.md
│   ├── ARCHITECTURE.md
│   ├── PITFALLS.md
│   └── SUMMARY.md
├── codebase/            # Codebase map (for brownfield)
│   ├── STACK.md
│   ├── ARCHITECTURE.md
│   ├── CONVENTIONS.md
│   ├── STRUCTURE.md
│   ├── TESTING.md
│   ├── INTEGRATIONS.md
│   └── CONCERNS.md
├── todos/               # Captured ideas
│   └── pending/
└── phases/
    ├── 01-foundation/
    │   ├── 01-CONTEXT.md
    │   ├── 01-RESEARCH.md
    │   ├── 01-01-PLAN.md
    │   ├── 01-01-SUMMARY.md
    │   ├── 01-02-PLAN.md
    │   ├── 01-02-SUMMARY.md
    │   ├── 01-VERIFICATION.md
    │   └── 01-UAT.md
    ├── 02-authentication/
    │   └── ...
    └── ...
```

---

## Anti-Patterns to Avoid

### Enterprise Patterns (BANNED)

- Story points, sprint ceremonies
- RACI matrices, stakeholder management
- Time estimates in human dev time (hours, days)
- Change management processes
- Team coordination documents

### Temporal Language (BANNED in implementation docs)

- "We changed X to Y"
- "Previously"
- "No longer"
- "Instead of"

**Exception:** CHANGELOG.md, MIGRATION.md, git commits

### Generic XML (BANNED)

- `<section>`, `<item>`, `<content>`

**DO USE:** Semantic purpose tags: `<objective>`, `<verification>`, `<action>`

### Vague Tasks (BANNED)

```xml
<!-- BAD -->
<task type="auto">
  <name>Add authentication</name>
  <action>Implement auth</action>
</task>

<!-- GOOD -->
<task type="auto">
  <name>Create login endpoint with JWT</name>
  <files>src/app/api/auth/login/route.ts</files>
  <action>
    POST endpoint accepting {email, password}.
    Use jose library (not jsonwebtoken - CommonJS issues).
    Return httpOnly cookie on success.
  </action>
  <verify>curl -X POST localhost:3000/api/auth/login returns 200 + Set-Cookie</verify>
  <done>Valid credentials → 200 + cookie. Invalid → 401.</done>
</task>
```

---

## Appendix: Complete Command List

| Command | Description |
|---------|-------------|
| `/gsd-new-project` | Initialize new project with questioning → research → requirements → roadmap |
| `/gsd-discuss-phase [N]` | Capture implementation decisions before planning |
| `/gsd-plan-phase [N]` | Research + plan + verify for a phase |
| `/gsd-execute-phase <N>` | Execute all plans in parallel waves |
| `/gsd-verify-work [N]` | Manual user acceptance testing |
| `/gsd-progress` | Show current position and progress |
| `/gsd-help` | Show all commands |
| `/gsd-settings` | Configure workflow preferences |
| `/gsd-update` | Update GSD with changelog preview |
| `/gsd-quick` | Execute ad-hoc task with GSD guarantees |
| `/gsd-debug [desc]` | Systematic debugging with persistent state |
| `/gsd-add-phase` | Append phase to roadmap |
| `/gsd-insert-phase [N]` | Insert urgent work between phases |
| `/gsd-remove-phase [N]` | Remove future phase |
| `/gsd-add-todo [desc]` | Capture idea for later |
| `/gsd-check-todos` | List pending todos |
| `/gsd-pause-work` | Create handoff when stopping mid-phase |
| `/gsd-resume-work` | Restore from last session |
| `/gsd-map-codebase` | Analyze existing codebase |
| `/gsd-new-milestone [name]` | Start next version |
| `/gsd-complete-milestone` | Archive milestone, tag release |
| `/gsd-audit-milestone` | Verify milestone definition of done |
| `/gsd-plan-milestone-gaps` | Create phases for audit gaps |
| `/gsd-research-phase [N]` | Standalone research before planning |
| `/gsd-list-phase-assumptions [N]` | See approach before planning |
| `/gsd-set-profile <profile>` | Switch model profile |
| `/gsd-join-discord` | Join community |

---

## Appendix: Agent Responsibilities

| Agent | Spawned By | Purpose |
|-------|------------|---------|
| `gsd-executor` | execute-phase | Executes plans, commits per-task, handles checkpoints |
| `gsd-planner` | plan-phase | Creates 2-3 task plans with XML structure |
| `gsd-verifier` | execute-phase | Goal-backward verification (not task completion) |
| `gsd-phase-researcher` | plan-phase | Investigates domain before planning |
| `gsd-roadmapper` | new-project | Creates roadmap from requirements |
| `gsd-project-researcher` | new-project | Researches domain (stack, features, architecture, pitfalls) |
| `gsd-research-synthesizer` | new-project | Synthesizes research into summary |
| `gsd-plan-checker` | plan-phase | Verifies plans achieve phase goals |
| `gsd-debugger` | debug, verify-work | Diagnoses issues systematically |
| `gsd-codebase-mapper` | map-codebase | Analyzes existing codebase |
| `gsd-integration-checker` | audit-milestone | Checks cross-phase integration |

---

*Document generated for GSD to Cursor adaptation*
*Version: 1.0*
*Date: 2026-01-25*


