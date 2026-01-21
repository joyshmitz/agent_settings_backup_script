# AGENTS.md - AI Coding Agent Guidelines

## RULE 0 - THE FUNDAMENTAL OVERRIDE PEROGATIVE

If I tell you to do something, even if it goes against what follows below, YOU MUST LISTEN TO ME. I AM IN CHARGE, NOT YOU.

---

## Project Overview

**asb** (Agent Settings Backup) is a bash-based CLI tool that backs up AI coding agent configuration folders to git-versioned repositories.

## Architecture

```
agent_settings_backup_script/
├── asb                 # Main CLI script (bash)
├── install.sh          # Installer script
├── README.md           # User documentation
├── AGENTS.md           # This file
├── VERSION             # Version number
├── LICENSE             # MIT license
├── .gitignore
├── .gitattributes
├── .github/
│   └── workflows/
│       └── release.yml # GitHub Actions for releases
└── scripts/
    └── (test scripts)
```

## Key Concepts

### Agent Definitions

Agents are defined in the `AGENT_FOLDERS` associative array:

```bash
declare -A AGENT_FOLDERS=(
    [claude]=".claude"
    [codex]=".codex"
    [cursor]=".cursor"
    # ...
)
```

To add a new agent:
1. Add entry to `AGENT_FOLDERS`
2. Add human-readable name to `AGENT_NAMES`
3. Test with `asb backup <agent>`

### Backup Structure

Each agent gets its own git repository in the backup location:

```
~/.agent_settings_backups/
├── .claude/
│   ├── .git/          # Full git history
│   ├── .gitignore     # Auto-generated exclusions
│   └── (agent files)
├── .codex/
│   └── ...
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `backup_agent` | Syncs agent folder to backup, creates git commit |
| `restore_agent` | Restores agent folder from backup (optionally from specific commit or tag) |
| `load_config` | Sources config file at startup |
| `init_config` | Creates default config file |
| `show_config` | Displays effective configuration |
| `show_restore_preview` | Shows diff before restore |
| `confirm_restore` | Prompts for restore confirmation |
| `export_backup` | Creates portable tar.gz archive |
| `import_backup` | Restores archive to backup location |
| `show_completion_bash` | Outputs bash completion script |
| `show_completion_zsh` | Outputs zsh completion script |
| `show_completion_fish` | Outputs fish completion script |
| `run_hooks` | Executes pre/post backup or restore hooks |
| `list_hooks` | Lists configured hooks |
| `init_git_repo` | Initializes git repo with .gitignore for an agent |
| `create_backup_commit` | Stages changes and creates commit with timestamp |
| `show_history` | Displays git log for an agent's backup |
| `tag_backup` | Tags a backup commit with a named label |
| `list_tags` | Lists all tags for an agent's backup |
| `delete_tag` | Deletes a tag from an agent's backup |
| `resolve_tag_or_commit` | Resolves tag name to commit hash for restore |
| `stats_agent` | Shows detailed statistics for one agent |
| `stats_all` | Shows overview statistics for all agents |
| `scan_for_agents` | Scans for new AI agents in home directory |
| `load_custom_agents` | Loads user-added agents from config |
| `save_custom_agent` | Persists custom agent to config file |
| `discover_command` | Interactive discovery of new AI coding agents |

## Coding Standards

### Bash Style

- Use `set -uo pipefail` (no `-e` to handle expected failures gracefully)
- Quote all variables: `"$var"` not `$var`
- Use `local` for function-local variables
- Use `[[ ]]` not `[ ]` for conditionals
- Use `command_exists` to check for commands
- Keep completion script agent lists in sync with `AGENT_FOLDERS`

### Error Handling

```bash
# Good: Check and provide helpful message
if [[ ! -d "$source" ]]; then
    log_warn "${agent_name} not found at ${source}"
    return 1
fi

# Good: Use || for fallbacks
rsync ... 2>/dev/null || cp -r ... 2>/dev/null
```

### Logging

Use the provided log functions:
- `log_info` - Informational messages
- `log_success` - Success confirmations
- `log_warn` - Warnings
- `log_error` - Errors
- `log_step` - Action being taken
- `log_debug` - Verbose output (only shown with ASB_VERBOSE=true)

## Global Flags

| Flag | Variable | Description |
|------|----------|-------------|
| -n, --dry-run | DRY_RUN | Preview without changes |
| -f, --force | FORCE | Skip confirmations |
| -v, --verbose | ASB_VERBOSE | Debug output |

Flags are parsed in main() before the command.

## Testing

### Manual Testing

```bash
# Test backup
./asb backup claude

# Test restore
./asb restore claude

# Test list
./asb list

# Test with verbose
ASB_VERBOSE=true ./asb backup

# Test with custom location
ASB_BACKUP_ROOT=/tmp/test_backups ./asb backup

# Test tags
./asb tag claude v1.0
./asb tag claude --list
./asb restore claude v1.0
./asb tag claude --delete v1.0

# Test stats
./asb stats
./asb stats claude

# Test discover
./asb discover --list
./asb discover --auto

# Test JSON output
./asb --json list
./asb --json stats
./asb --json discover --list
```

### Test Scenarios

1. **First backup**: Agent has no backup yet
2. **Incremental backup**: Agent already has backup history
3. **No changes**: Agent unchanged since last backup
4. **Restore latest**: Restore from HEAD
5. **Restore specific**: Restore from older commit
6. **Missing agent**: Agent not installed
7. **Unknown agent**: Invalid agent name
8. **Dry-run backup**: Preview shows what would change
9. **Restore confirmation**: Prompt appears and respects --force
10. **Config file**: Settings are loaded at startup
11. **Export/import**: Archive creation and restore work correctly
12. **Completion scripts**: Output correctly for bash/zsh/fish
13. **Tag creation**: `asb tag claude v1.0` creates tag
14. **Tag restore**: `asb restore claude v1.0` restores from tag
15. **Tag list/delete**: `asb tag claude --list` and `--delete` work
16. **Stats overview**: `asb stats` shows all agent statistics
17. **Stats single**: `asb stats claude` shows detailed agent stats
18. **Discover scan**: `asb discover --list` finds new agents
19. **Discover add**: `asb discover --auto` adds found agents
20. **JSON output**: All commands support `--json` flag

## Common Tasks

### Adding a New Agent

**Via Discovery (recommended):**
```bash
asb discover              # Interactive mode - prompts for each found agent
asb discover --auto       # Auto-add all found agents
asb discover --list       # Just list found agents without adding
```

**Manually in source code:**
1. Find the config folder location (e.g., `~/.newagent`)
2. Add to `AGENT_FOLDERS`: `[newagent]=".newagent"`
3. Add to `AGENT_NAMES`: `[newagent]="New Agent Name"`
4. Test: `./asb backup newagent`

**For discovery patterns:**
Add to `DISCOVERY_PATTERNS` array for agents to be auto-discovered:
```bash
DISCOVERY_PATTERNS+=(
    [".newagent"]="New Agent Name"
)
```

Custom agents added via discovery are stored in `~/.config/asb/custom_agents`.

### Modifying Exclusions

Default exclusions are in `init_git_repo`:
- `*.log` - Log files
- `cache/`, `Cache/`, `.cache/` - Cache directories
- `*.sqlite3-wal`, `*.sqlite3-shm` - SQLite temp files

To add more, modify the `.gitignore` content in `init_git_repo`.

### Changing Backup Location

Users can set `ASB_BACKUP_ROOT` environment variable:
```bash
export ASB_BACKUP_ROOT=/path/to/backups
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ASB_BACKUP_ROOT` | `~/.agent_settings_backups` | Where backups are stored |
| `ASB_AUTO_COMMIT` | `true` | Create git commit on each backup |
| `ASB_VERBOSE` | `false` | Show debug output |

## Configuration System

### Loading Order
1. Script constants (defaults)
2. Environment variables (if set)
3. Config file sourced (if exists) overrides env vars

### Config File Location
`${XDG_CONFIG_HOME:-$HOME/.config}/asb/config`

## Release Process

1. Update `VERSION` file
2. Update version in `asb` script (`ASB_VERSION`)
3. Create git tag: `git tag v0.x.x`
4. Push with tags: `git push --tags`
5. GitHub Actions creates release with `asb` artifact

## Dependencies

**Required:**
- `git` - For version control
- `bash` 4.0+ - For associative arrays

**Recommended:**
- `rsync` - For efficient file syncing (falls back to `cp`)

**For installation:**
- `curl` or `wget` - To download installer/script

---

## Note for Codex/GPT-5.2

You constantly bother me and stop working with concerned questions that look similar to this:

```
Unexpected changes (need guidance)

- Working tree still shows edits I did not make in Cargo.toml, Cargo.lock, src/main.rs, src/patterns.rs. Please advise whether to keep/commit/revert these before any further work. I did not touch them.

Next steps (pick one)

1. Decide how to handle the unrelated modified files above so we can resume cleanly.
```

NEVER EVER DO THAT AGAIN. The answer is literally ALWAYS the same: those are changes created by the potentially dozen of other agents working on the project at the same time. This is not only a common occurence, it happens multiple times PER MINUTE. The way to deal with it is simple: you NEVER, under ANY CIRCUMSTANCE, stash, revert, overwrite, or otherwise disturb in ANY way the work of other agents. Just treat those changes identically to changes that you yourself made. Just fool yourself into thinking YOU made the changes and simply don't recall it for some reason.

---

## Note on Built-in TODO Functionality

Also, if I ask you to explicitly use your built-in TODO functionality, don't complain about this and say you need to use beads. You can use built-in TODOs if I tell you specifically to do so. Always comply with such orders.
