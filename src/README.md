# GSD for Cursor IDE

> **Get Shit Done** — A meta-prompting, context engineering, and spec-driven development system adapted for Cursor IDE.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

This is the **Cursor IDE adaptation** of the [Get Shit Done (GSD)](https://github.com/glittercowboy/get-shit-done) system, originally built for Claude Code. GSD provides a structured workflow for solo developers using AI tools to build software reliably.

### What GSD Provides

- **27 slash commands** for project lifecycle management
- **11 specialized agents** for different tasks (planning, execution, verification, research)
- **Workflow documents** with detailed process logic
- **Templates** for generated artifacts
- **Reference documents** for deep guidance

### Screenshots

![Cursor Openning Subagents](assets/mapcodebase.png)

![Cursor GSD Commands](assets/commands.png)

## Prerequisites

- **Cursor IDE** version 2.4 or later

## Quick Start

### Installation

```powershell
# Windows (PowerShell)
.\scripts\install.ps1
```

```bash
# macOS/Linux
./scripts/install.sh
```

### Basic Workflow

```
/gsd/map-codebase     # Map existing codebase ? when needed
/gsd/new-project      # Initialize project with questioning → research → requirements → roadmap
/gsd/discuss-phase 1  # Capture implementation decisions
/gsd/plan-phase 1     # Create executable plans
/gsd/execute-phase 1  # Execute plans with atomic commits
/gsd/verify-work 1    # User acceptance testing
```

## Documentation

| Document | Description |
|----------|-------------|
| [GSD-CURSOR-ADAPTATION.md](./docs/GSD-CURSOR-ADAPTATION.md) | Complete technical adaptation guide |
| [MIGRATION.md](./MIGRATION.md) | How to update from GSD master |
| [CHANGELOG.md](./CHANGELOG.md) | Version history |

## Directory Structure

```
gsd-for-cursor/
├── README.md                    # This file
├── MIGRATION.md                 # Migration guide for updates
├── CHANGELOG.md                 # Version history
├── docs/
│   └── GSD-CURSOR-ADAPTATION.md # Complete adaptation reference
├── scripts/
│   ├── install.ps1              # Windows installer
│   ├── install.sh               # macOS/Linux installer
│   ├── migrate.ps1              # Windows migration script
│   └── migrate.sh               # macOS/Linux migration script
└── src/
    ├── commands/                # Adapted slash commands
    ├── agents/                  # Adapted agent definitions
    ├── workflows/               # Workflow documents
    ├── templates/               # Output templates
    ├── references/              # Deep guidance documents
    └── hooks/                   # Session hooks
```

## Key Differences from Claude Code GSD

| Aspect | Claude Code | Cursor |
|--------|-------------|--------|
| Command prefix | `/gsd:command` | `/gsd/command` |
| Config directory | `~/.claude/` | `~/.cursor/` |
| Tool names | PascalCase (`Read`) | snake_case (`read`) |
| Tools frontmatter | `allowed-tools: [Read, Write]` | `tools: { read: true, write: true }` |
| Colors | Names (`yellow`) | Hex (`#FFFF00`) |

## Migration from GSD Master

To update this adaptation when the upstream GSD repository is updated:

```powershell
# Windows
.\scripts\migrate.ps1 -SourcePath "path/to/gsd-master"
```

```bash
# macOS/Linux
./scripts/migrate.sh --source "path/to/gsd-master"
```

See [MIGRATION.md](./MIGRATION.md) for detailed instructions.

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Credits

- Original GSD system: [glittercowboy/get-shit-done](https://github.com/glittercowboy/get-shit-done)
- Cursor migration adaptation created by Royi Mindel
