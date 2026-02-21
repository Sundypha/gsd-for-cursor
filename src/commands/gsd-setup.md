---
tools:
  read: true
  bash: true
  write: true
name: gsd-setup
description: Install GSD workflows, agents, and tools into this environment
argument-hint: "[--force]"
---
<objective>
Bootstrap the full GSD installation in the current environment (typically a devcontainer). This command is the only one that works without a prior install — Cursor syncs commands automatically, so this command can set up everything else.
</objective>

<process>

1. **Check if already installed:**

```bash
ls ~/.cursor/get-shit-done/bin/gsd-tools.cjs 2>/dev/null
```

If it exists and `--force` was NOT passed, tell the user GSD is already installed and suggest `--force` to reinstall.

2. **Check prerequisites:**

```bash
node --version
git --version
```

If `node` is missing, inform the user and stop. Node must be installed separately (e.g., via devcontainer features).

3. **Clone and install:**

```bash
GSD_DIR="/tmp/gsd-for-cursor"
rm -rf "$GSD_DIR"
git clone --depth 1 https://github.com/Sundypha/gsd-for-cursor.git "$GSD_DIR"
bash "$GSD_DIR/scripts/install.sh" --force
rm -rf "$GSD_DIR"
```

4. **Verify installation:**

```bash
ls ~/.cursor/get-shit-done/bin/gsd-tools.cjs
ls ~/.cursor/get-shit-done/workflows/ | wc -l
ls ~/.cursor/agents/ | wc -l
```

5. **Report result:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Workflows: N
 Agents:    N
 Commands:  (synced by Cursor)
 Tools:     gsd-tools.cjs ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready. Try /gsd-help to see all commands.
```

</process>
