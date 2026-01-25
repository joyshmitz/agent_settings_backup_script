# RESEARCH FINDINGS: asb (Agent Settings Backup Script) - TOON Integration Analysis

**Date**: 2026-01-25
**Bead**: bd-3ha
**Researcher**: Claude Code Agent (cc)

## 1. Project Overview

| Attribute | Value |
|-----------|-------|
| **Language** | Bash |
| **CLI Framework** | Pure Bash |
| **Script Size** | ~4,083 lines |
| **Tier** | 4 (Additional Tool) |
| **Directory** | `/dp/agent_settings_backup_script` |

### Purpose
asb (Agent Settings Backup Script) backs up AI coding agent configuration folders to git-versioned repositories. Supports:
- Claude Code, Codex, Cursor, Gemini, Cline, Amp, Aider, and more
- Export/import portable archives
- Scheduled backups (cron/systemd)
- Hook system for automation

## 2. TOON Integration Status: COMPLETE

**TOON support is fully implemented in asb.**

### CLI Flags
```
-j, --json            Output machine-readable JSON
--format FORMAT       Structured output format: json or toon
```

### Implementation Details

| Location | Implementation |
|----------|----------------|
| Line 64 | `OUTPUT_FORMAT="json"` variable |
| Lines 257-264 | TOON output with JSON fallback |
| Lines 267-275 | `asb_try_load_toon_sh()` helper |
| Lines 279-288 | `asb_json_to_toon()` encoding function |

### TOON Encoding Flow
```bash
# File: /dp/agent_settings_backup_script/asb
asb_json_to_toon() {
    local json="$1"
    if ! asb_try_load_toon_sh; then
        return 1
    fi
    if ! toon_available >/dev/null 2>&1; then
        return 1
    fi
    printf '%s' "$json" | toon_encode
}
```

### Binary/Library Discovery
Uses `toon.sh` shared library:
1. `TOON_SH_PATH` environment variable
2. Default: `~/.local/lib/toon.sh`

### Graceful Degradation
```bash
if [[ "$OUTPUT_FORMAT" == "toon" ]]; then
    if toon_out="$(asb_json_to_toon "$json" 2>/dev/null)"; then
        printf '%s\n' "$toon_out"
        return 0
    fi
    log_warn "TOON requested but tru/toon.sh not available; outputting JSON"
fi
printf '%s\n' "$json"
```

## 3. Commands Supporting TOON

| Command | Description | TOON Support |
|---------|-------------|--------------|
| `asb list` | List all agents and backup status | ✓ |
| `asb stats [agent]` | Show backup statistics | ✓ |
| `asb history <agent>` | Show backup history | ✓ |
| `asb diff <agent>` | Show changes since last backup | ✓ |
| `asb backup [agents...]` | Backup agent settings | ✓ |
| `asb restore <agent>` | Restore from backup | ✓ |
| `asb verify [agents...]` | Verify backup integrity | ✓ |

## 4. Output Analysis

### JSON Output Example (stats)
```json
{
  "agents": [
    {
      "agent": "claude",
      "name": "Claude Code",
      "backups": 1,
      "storage": "54G",
      "last_backup": "5 days ago",
      "changes_per_week": 10.0
    }
  ],
  "total_backups": 9,
  "total_storage": "62.7G"
}
```

### TOON Output Example (list)
```yaml
[13]:
  - agent: claude
    name: Claude Code
    status: backed_up
    last_backup: "2026-01-19T15:39:11-05:00"
    commit: b2d375c
  - agent: codex
    name: OpenAI Codex CLI
    status: backed_up
```

## 5. Token Savings Estimate

| Command | JSON Tokens (est.) | TOON Tokens (est.) | Savings |
|---------|-------------------|-------------------|---------|
| `list` (13 agents) | ~450 | ~250 | 44% |
| `stats` (5 agents) | ~350 | ~200 | 43% |
| `history` (10 commits) | ~600 | ~350 | 42% |

## 6. Environment Variables

| Variable | Purpose |
|----------|---------|
| `TOON_SH_PATH` | Path to toon.sh library |
| `ASB_VERBOSE` | Enable verbose output |
| `ASB_BACKUP_ROOT` | Backup location |
| `ASB_AUTO_COMMIT` | Auto-commit on backup |

## 7. Implementation Quality

### Strengths
- Full `--format toon` support
- Graceful fallback to JSON when TOON unavailable
- Warning message on fallback (good UX)
- Uses shared `toon.sh` library pattern
- JSON output for all major commands

### Architecture
```
asb (bash)
  └── JSON generation built-in
      └── asb_json_to_toon() loads toon.sh
          └── toon_encode pipes through tru
              └── TOON output to stdout
```

## 8. Acceptance Criteria Status

- [x] `--format toon` flag implemented
- [x] TOON encoding via toon.sh/tru
- [x] Environment variable support (TOON_SH_PATH)
- [x] Documented in --help
- [x] Graceful fallback to JSON
- [x] All major commands support TOON

## 9. Conclusion

**TOON integration for asb is COMPLETE.**

The implementation is well-designed:
- Uses shared `toon.sh` library pattern
- Has graceful degradation with warning
- Supports all major commands
- Already tested and working

**bd-45d (Integrate TOON into asb) should be marked COMPLETE** - no additional implementation work is required.

## 10. Related Beads

- **bd-3ha**: This research bead - Complete
- **bd-45d**: Integrate TOON into asb - Should be verified/closed
- **bd-1y9**: Research orchestration parent bead
