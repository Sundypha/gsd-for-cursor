# GSD Migration Guide

> How to update this Cursor adaptation when the upstream GSD master is updated.

## Overview

This document provides step-by-step instructions for migrating changes from the original Claude Code GSD repository to this Cursor IDE adaptation.

## Prerequisites

- Access to the latest GSD master repository
- PowerShell 7+ (Windows) or Bash (macOS/Linux)
- Text editor with find/replace support

## Migration Process

### Step 1: Identify Changed Files

Compare the upstream GSD repository with your last migration:

```bash
# Clone or pull the latest GSD master
git clone https://github.com/glittercowboy/get-shit-done.git gsd-master
cd gsd-master
git log --oneline -20  # Review recent changes
```

### Step 2: Run the Migration Script

The migration script automates the bulk of the conversion:

```powershell
# Windows
.\scripts\migrate.ps1 -SourcePath "path/to/gsd-master" -DryRun

# Review output, then run for real:
.\scripts\migrate.ps1 -SourcePath "path/to/gsd-master"
```

```bash
# macOS/Linux
./scripts/migrate.sh --source "path/to/gsd-master" --dry-run

# Review output, then run for real:
./scripts/migrate.sh --source "path/to/gsd-master"
```

### Step 3: Manual Review Required

The migration script handles automatic transformations, but some changes require manual review:

#### 3.1 Frontmatter Conversion

**Commands** - Convert from:
```yaml
---
name: gsd:command-name
allowed-tools:
  - Read
  - Write
  - Task
  - AskUserQuestion
---
```

**To:**
```yaml
---
name: gsd-command-name
tools:
  read: true
  write: true
  ask_question: true
---
```

#### 3.2 Agent Frontmatter

**From:**
```yaml
---
name: gsd-executor
tools: Read, Write, Edit, Bash, Grep, Glob
color: yellow
---
```

**To:**
```yaml
---
name: gsd-executor
tools:
  read: true
  write: true
  edit: true
  bash: true
  grep: true
  glob: true
color: "#FFFF00"
---
```

### Step 4: Transformation Rules

Apply these find/replace operations across all files:

#### Path References

| Find | Replace |
|------|---------|
| `~/.claude/` | `~/.cursor/` |
| `.claude/` | `.cursor/` |
| `@~/.claude/get-shit-done/` | `@~/.cursor/get-shit-done/` |
| `$CLAUDE_PROJECT_DIR` | (Cursor workspace path) |

#### Command Invocations

| Find | Replace |
|------|---------|
| `/gsd:` | `/gsd-` |

#### Tool Names

| Find | Replace |
|------|---------|
| `Read` | `read` |
| `Write` | `write` |
| `Edit` | `edit` |
| `Bash` | `bash` |
| `Glob` | `glob` |
| `Grep` | `grep` |
| `Task` | (remove - handled by subagent mechanism) |
| `AskUserQuestion` | `ask_question` |
| `TodoWrite` | `todo_write` |
| `WebFetch` | `web_fetch` |
| `WebSearch` | `web_search` |
| `MultiEdit` | `multi_edit` |

#### Color Names to Hex

| Find | Replace |
|------|---------|
| `color: cyan` | `color: "#00FFFF"` |
| `color: red` | `color: "#FF0000"` |
| `color: green` | `color: "#00FF00"` |
| `color: blue` | `color: "#0000FF"` |
| `color: yellow` | `color: "#FFFF00"` |
| `color: magenta` | `color: "#FF00FF"` |
| `color: orange` | `color: "#FFA500"` |
| `color: purple` | `color: "#800080"` |
| `color: pink` | `color: "#FFC0CB"` |
| `color: white` | `color: "#FFFFFF"` |
| `color: gray` | `color: "#808080"` |
| `color: grey` | `color: "#808080"` |

### Step 5: Verify Migration

After migration, verify:

1. **Frontmatter syntax** - All files should have valid YAML frontmatter
2. **Path references** - No remaining `.claude` references
3. **Command references** - No remaining `/gsd:` patterns
4. **Tool names** - No PascalCase tool names remain

```powershell
# Check for remaining Claude references
Select-String -Path "src/**/*.md" -Pattern "\.claude" -Recurse

# Check for old command format
Select-String -Path "src/**/*.md" -Pattern "/gsd:" -Recurse

# Check for PascalCase tools
Select-String -Path "src/**/*.md" -Pattern "allowed-tools" -Recurse
```

### Step 6: Test the Migration

1. Install to `~/.cursor/`:
   ```powershell
   .\scripts\install.ps1
   ```

2. Test in Cursor:
   ```
   /gsd-help              # Should list all commands
   /gsd-progress          # Should show status
   ```

3. Test a full workflow on a test project

### Step 7: Update Version and Changelog

1. Update `CHANGELOG.md` with migration date and upstream version
2. Update version in any version files
3. Commit changes with message: `chore: migrate from GSD master vX.Y.Z`

## File-by-File Checklist

### Commands (30 files, flat in commands/)

- [ ] `commands/gsd-new-project.md`
- [ ] `commands/gsd-plan-phase.md`
- [ ] `commands/gsd-execute-phase.md`
- [ ] `commands/gsd-verify-work.md`
- [ ] `commands/gsd-discuss-phase.md`
- [ ] `commands/gsd-research-phase.md`
- [ ] `commands/gsd-progress.md`
- [ ] `commands/gsd-help.md`
- [ ] `commands/gsd-settings.md`
- [ ] `commands/gsd-update.md`
- [ ] `commands/gsd-quick.md`
- [ ] `commands/gsd-debug.md`
- [ ] `commands/gsd-add-phase.md`
- [ ] `commands/gsd-insert-phase.md`
- [ ] `commands/gsd-remove-phase.md`
- [ ] `commands/gsd-add-todo.md`
- [ ] `commands/gsd-check-todos.md`
- [ ] `commands/gsd-pause-work.md`
- [ ] `commands/gsd-resume-work.md`
- [ ] `commands/gsd-map-codebase.md`
- [ ] `commands/gsd-new-milestone.md`
- [ ] `commands/gsd-complete-milestone.md`
- [ ] `commands/gsd-audit-milestone.md`
- [ ] `commands/gsd-plan-milestone-gaps.md`
- [ ] `commands/gsd-list-phase-assumptions.md`
- [ ] `commands/gsd-set-profile.md`
- [ ] `commands/gsd-join-discord.md`
- [ ] `commands/gsd-cleanup.md`
- [ ] `commands/gsd-health.md`
- [ ] `commands/gsd-reapply-patches.md`

### Agents (11 files)

- [ ] `agents/gsd-executor.md`
- [ ] `agents/gsd-planner.md`
- [ ] `agents/gsd-verifier.md`
- [ ] `agents/gsd-phase-researcher.md`
- [ ] `agents/gsd-roadmapper.md`
- [ ] `agents/gsd-project-researcher.md`
- [ ] `agents/gsd-research-synthesizer.md`
- [ ] `agents/gsd-plan-checker.md`
- [ ] `agents/gsd-debugger.md`
- [ ] `agents/gsd-codebase-mapper.md`
- [ ] `agents/gsd-integration-checker.md`

### Workflows (12 files)

- [ ] `workflows/execute-phase.md`
- [ ] `workflows/execute-plan.md`
- [ ] `workflows/verify-phase.md`
- [ ] `workflows/verify-work.md`
- [ ] `workflows/discuss-phase.md`
- [ ] `workflows/discovery-phase.md`
- [ ] `workflows/diagnose-issues.md`
- [ ] `workflows/map-codebase.md`
- [ ] `workflows/complete-milestone.md`
- [ ] `workflows/resume-project.md`
- [ ] `workflows/transition.md`
- [ ] `workflows/list-phase-assumptions.md`

### Templates (20+ files)

- [ ] All files in `templates/`
- [ ] All files in `templates/codebase/`
- [ ] All files in `templates/research-project/`

### References (9 files)

- [ ] All files in `references/`

### Hooks (3 files)

- [ ] `hooks/gsd-statusline.js`
- [ ] `hooks/gsd-check-update.js`
- [ ] `hooks/gsd-context-monitor.js`

### Bin Tools (copied as-is, no conversion needed)

- [ ] `bin/gsd-tools.cjs`
- [ ] `bin/lib/*.cjs` (11 modules)

## Troubleshooting

### Common Issues

**Issue: Frontmatter parsing errors**
- Ensure YAML is valid
- Check for missing quotes around hex colors
- Verify tools object syntax

**Issue: Commands not appearing in Cursor**
- Verify files are in `~/.cursor/commands/` (flat, named `gsd-*.md`)
- Check file has `.md` extension
- Restart Cursor

**Issue: Path references not resolving**
- Check `@` mentions use correct path
- Verify `~/.cursor/get-shit-done/` exists

## Automation Opportunities

Future improvements to the migration process:

1. **AST-based frontmatter conversion** - Parse YAML properly instead of regex
2. **Semantic tool mapping** - Handle tool name variations automatically
3. **Integration tests** - Automated testing of migrated commands
4. **CI/CD pipeline** - Automatic migration on upstream releases

## Version History

| Date | GSD Version | Notes |
|------|-------------|-------|
| 2026-01-25 | Initial | First migration |

---

*Last updated: 2026-01-25*


