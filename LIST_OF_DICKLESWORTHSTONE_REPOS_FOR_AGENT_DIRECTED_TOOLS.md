# Dicklesworthstone Repos with Robot Mode / Agent-Friendly Interfaces

Tools designed for use by AI coding agents with machine-readable output modes.

## Summary

| Tool | Repo | Robot Mode Flags |
|------|------|------------------|
| cass | coding_agent_session_search | `--json`, `--robot`, `--robot-format` |
| cm | cass_memory_system | `--json` |
| bv | beads_viewer | `--robot-*` flags |
| br | beads_rust | Agent-first design |
| ru | repo_updater | `--json` |
| ubs | ultimate_bug_scanner | `--format=json/jsonl/sarif` |
| xf | xf | `--format json` |
| slb | slb | `--json` |
| ntm | ntm | `--robot` |
| giil | giil | `--json`, `--base64` |
| pt | process_triage | `pt robot` subcommand |
| wa | wezterm_automata | `wa robot` subcommand |
| ms | meta_skill | `--robot`, `MS_ROBOT` env |
| rch | remote_compilation_helper | `--format json` |
| dcg | destructive_command_guard | `--json` |
| apr | automated_plan_reviser_pro | `apr robot` subcommand |
| acfs | agentic_coding_flywheel_setup | `--json` |
| asb | agent_settings_backup_script | `--json` |

---

## Detailed List

### Core Agent Infrastructure

#### cass (coding_agent_session_search)
- **Flags**: `--json`, `--robot`, `--robot-format json|jsonl|compact`
- **Purpose**: Unified search over coding agent histories
- **Agent Commands**: `search`, `view`, `expand`, `health`, `capabilities`, `introspect`, `robot-docs`
- **Example**: `cass search "authentication error" --robot --limit 5`

#### cm (cass_memory_system)
- **Flags**: `--json`
- **Purpose**: Procedural memory for AI coding agents
- **Agent Commands**: `context`, `similar`, `stats`
- **Example**: `cm context "<task description>" --json`

#### bv (beads_viewer)
- **Flags**: `--robot-help`, `--robot-insights`, `--robot-plan`, `--robot-priority`, `--robot-label-attention`, `--emit-script`
- **Purpose**: Graph-aware issue triage and visualization
- **Example**: `bv --robot-insights --emit-script`

#### br (beads_rust)
- **Design**: Agent-first issue tracker
- **Purpose**: Local-first issue tracking with JSONL sync
- **Features**: Structured output, scriptable commands, dependency graphs

#### ru (repo_updater)
- **Flags**: `--json`, `--non-interactive`
- **Purpose**: Multi-repo synchronization and management
- **Example**: `ru status --json | jq '.repos[] | select(.dirty)'`

---

### Code Quality & Analysis

#### ubs (ultimate_bug_scanner)
- **Flags**: `--format=json`, `--format=jsonl`, `--format=sarif`
- **Purpose**: Static analysis for catching bugs early
- **Example**: `ubs file.go --format=json`

#### pt (process_triage)
- **Subcommand**: `pt robot`
- **Flags**: `--format json`, `--deep`
- **Purpose**: Process diagnostics with agent integration
- **Example**: `pt robot plan --deep --format json`

---

### Session & Workflow Management

#### ntm (Named Tmux Manager)
- **Flags**: `--robot`, `--robot-format`
- **Purpose**: Multi-agent orchestration for Claude Code, Codex, Gemini
- **Features**: Robot mode for agent coordination, JSON output

#### slb (Simultaneous Launch Button)
- **Flags**: `--json`
- **Purpose**: Two-person rule for destructive commands
- **Commands**: `slb watch --json`, `slb session list --json`, `slb history --json`

#### apr (automated_plan_reviser_pro)
- **Subcommand**: `apr robot`
- **Commands**: `apr robot status`, `apr robot workflows`, `apr robot run`, `apr robot validate`
- **Purpose**: Plan revision with structured JSON envelope format

---

### Utilities

#### xf (X Archive Search)
- **Flags**: `--format json`, `--format csv`
- **Purpose**: Ultra-fast local search for X (Twitter) archives
- **Example**: `xf search "machine learning" --format json`

#### giil (Get Image from iCloud Link)
- **Flags**: `--json`, `--base64`
- **Purpose**: Download images from cloud share links
- **Example**: `giil <url> --json`

#### wa (wezterm_automata)
- **Subcommand**: `wa robot`
- **Purpose**: Machine-optimized control surface for WezTerm
- **Features**: Agent-first interface design

#### ms (meta_skill)
- **Flags**: `--robot`
- **Env**: `MS_ROBOT=1`
- **Purpose**: Skill management and discovery
- **Example**: `ms search --robot`, `ms load skill --robot`

#### rch (remote_compilation_helper)
- **Flags**: `--format json`
- **Purpose**: Remote Rust compilation offloading
- **Features**: Designed for Claude Code hooks integration

#### asb (agent_settings_backup_script)
- **Flags**: `--json`
- **Purpose**: Backup and sync settings across AI coding agents
- **Commands**: All commands support `--json` (backup, restore, list, history, diff, export, import, stats, discover)

#### acfs (agentic_coding_flywheel_setup)
- **Flags**: `--json`
- **Commands**: `acfs info --json`, `acfs cheatsheet --json`, `acfs doctor --json`
- **Purpose**: Flywheel setup and configuration

---

### Web & Data

#### markdown_web_browser
- **Flags**: `--json`
- **Purpose**: Web browsing with deterministic markdown output
- **Features**: Designed for AI agents with predictable output

#### rust_proxy
- **Flags**: `--json`
- **Commands**: `list --json`, `status --json`
- **Purpose**: HTTP proxy with JSON status reporting

#### rust_scriptbots
- **Features**: REST API with JSON output, MCP HTTP server
- **Purpose**: Scriptable bot automation

---

### Platform & Infrastructure

#### flywheel_connectors
- **Purpose**: Machine-readable protocol with capability tokens
- **Features**: FCP specification for AI agent zones

#### flywheel_gateway
- **Path**: `reference/ntm/robot/`
- **Purpose**: Gateway with robot-mode implementation

#### flywheel_private
- **Path**: `tools/fwh-cli/src/lib/output.ts`
- **Features**: `printResult()` with robot mode support

#### jeffreys-skills.md / jeffreysprompts.com
- **Flags**: `--json`
- **Purpose**: Skill and prompt management CLI
- **Example**: `jfp list --json`, `jfp search "robot" --json`

#### mcp_agent_mail
- **Features**: Integration with bv robot flags
- **Purpose**: MCP-based agent communication

---

## Usage Pattern

Most tools follow a consistent pattern:

```bash
# Get JSON output for scripting
<tool> <command> --json

# Or with robot flag
<tool> <command> --robot

# Pipe to jq for processing
<tool> <command> --json | jq '.field'
```

## Notes

- All tools output to stdout (data) and stderr (diagnostics)
- Exit code 0 = success
- JSON output is designed for parsing by other agents
- Many tools support `--non-interactive` or similar flags for CI/automation
