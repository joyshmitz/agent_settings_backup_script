# Changelog

All notable changes to [Agent Settings Backup (asb)](https://github.com/Dicklesworthstone/agent_settings_backup_script) are documented here.

Versions follow [Semantic Versioning](https://semver.org/). Only [v0.2.0](https://github.com/Dicklesworthstone/agent_settings_backup_script/releases/tag/v0.2.0) has a formal Git tag and GitHub release; v0.1.0 and v0.3.0 are identified by VERSION file bumps in the commit history.

---

## [v0.3.0] — 2026-01-21 (current)

Version bump in commit [`2091367`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/20913676a9718a538f7a87d9cce10f5bb68365ab). Development spans 2026-01-21 through 2026-03-13 (HEAD).

### Features

- **Backup tags** — Name important backups with `asb tag claude v1.0` and restore by tag name instead of commit hash ([`a69a688`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a69a688941a35eb3c7e3e7a1348cdb0953c78a96))
- **Statistics** — View backup size, commit count, and activity metrics with `asb stats` and `asb stats <agent>` ([`a69a688`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a69a688941a35eb3c7e3e7a1348cdb0953c78a96))
- **Auto-discovery** — Scan for new AI agents with `asb discover`; add them interactively or automatically with `--auto` ([`a69a688`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a69a688941a35eb3c7e3e7a1348cdb0953c78a96))
- **Custom agents** — Persist discovered agents in `~/.config/asb/custom_agents` for automatic inclusion in future backups
- **Scheduled backups** — Install cron jobs or systemd timers with `asb schedule --systemd --interval daily`; supports daily/weekly/monthly intervals, `--status`, and `--remove` ([`831fb4c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/831fb4c7b2248991e9dbc58f862ba259e424f473))
- **Backup verification** — Check backup integrity with `asb verify [agents...]` ([`831fb4c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/831fb4c7b2248991e9dbc58f862ba259e424f473))
- **Hooks system** — Run user-defined scripts before/after backup and restore operations via `~/.config/asb/hooks/{pre,post}-{backup,restore}.d/` directories; environment variables `ASB_AGENT`, `ASB_SOURCE`, `ASB_BACKUP_DIR`, `ASB_OPERATION`, `ASB_COMMIT` passed to hook scripts ([`7709a70`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/7709a70930dc1e9995527950a536fcd98cb7aafa))
- **JSON structured output** — All commands support `--json` for machine-readable output ([`4a3d98c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/4a3d98cc0556e54d20ded7095dae805c5d846533), [`6ce735c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/6ce735ce20330bcfe94f74c232a6ac143481b565))
- **TOON structured output** — `--format toon` for tabular TOON format via `tru` (toon_rust); `--format json` also accepted ([`6352340`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/6352340828989b5866a9b605b99abfb92480518f))
- **New agents**: Plandex (`~/.plandex-home`), Qwen Code (`~/.qwen`), Amazon Q (`~/.q`) ([`831fb4c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/831fb4c7b2248991e9dbc58f862ba259e424f473))

### Bug Fixes

- Improve verify command output: track skipped agents when no backup exists, show named agent in warning, distinguish failed vs not-found in summary ([`a4a7028`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a4a70282ef64ebf694fed2341acf3d763609b9ff))
- Improve overall script reliability with better error handling and file processing logic ([`7b6e600`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/7b6e600019e0e3d283139eaeadebc2a1873df482))
- Fix shellcheck warnings: replace `A && B || C` with proper `if-then-fi` in `log_debug`, quote expansions in parameter patterns, use printf format specifiers ([`c74f8be`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/c74f8be60f928da32c04e7979b6fce370571aacc))
- Fix CI test failures caused by invalid `TMPDIR` and `mktemp` template: fall back to `/tmp` when `TMPDIR` is unavailable, add `XXXXXXXX` suffixes to all `mktemp -t` calls ([`9ae57e2`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/9ae57e219b19bdf71b9c1879781c154e92ed2b96))
- Use modern bash 4+ on macOS for associative array support (`declare -A` requires bash >= 4.0, macOS ships 3.2) ([`99bb595`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/99bb595f2aad8fc335491ab99fb6de7b091c1f79))

### Testing

- Comprehensive E2E test suite: concurrent operations, discovery, error paths, large files, stats, symlinks, tags, unicode, verify, hooks, JSON validation, schedule, conflict detection ([`a69a688`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a69a688941a35eb3c7e3e7a1348cdb0953c78a96))
- Unit test framework with harness: agent_exists, config functions, discovery functions, git functions, JSON functions, logging ([`a69a688`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a69a688941a35eb3c7e3e7a1348cdb0953c78a96))
- GitHub Actions CI workflow: ShellCheck lint + E2E + unit tests on Ubuntu and macOS ([`a69a688`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/a69a688941a35eb3c7e3e7a1348cdb0953c78a96), [`06aca36`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/06aca364036ab746885838706f5980163d147f48))
- E2E test script for TOON format support: `--format json|toon` flags, tabular format, `tru` encode/decode round-trip ([`d075f66`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/d075f6681f28f9684786e48d186e2de1c3bcd3a4))
- Enhance conflict detection test with timestamp collision and concurrent backup scenarios ([`7933d11`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/7933d11fee1c2992d2f08787ff0636eba3feafe5))
- Add diagnostic output to `test_dryrun_backup_shows_preview` for macOS debugging ([`eb21153`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/eb211535960a9f76b8466312f2669ddc65f61b96))
- Add diff parsing reproduction test ([`fa8a48d`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/fa8a48dce75f74a06e86141bd4b1f12093b234ae))
- Allow sourcing `asb` for unit tests via `ASB_SOURCED=true` without executing `main`

### CI/CD

- Add ACFS installer change notification workflow: triggers `repository_dispatch` to ACFS when `install.sh` changes, includes SHA256 checksum and ShellCheck validation on PRs ([`f0e8e27`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/f0e8e2736164d8bbd13db889c05297d639d48fdf))

### Documentation

- Update AGENTS.md with latest multi-agent conventions, fix typos, add master branch sync instructions ([`32d10a4`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/32d10a4dacd1ab1a9f33937ea121872d8ffc7f0f))
- Update README with v0.3 features, structured output examples, hooks documentation, FAQ, troubleshooting guide

### Chores

- Update license to MIT with OpenAI/Anthropic Rider ([`20411f5`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/20411f5cf80f703d84a2753982d0a060d0d6b107))
- Update README license badge to reflect MIT + OpenAI/Anthropic Rider ([`ce4d373`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/ce4d3737b6c75207c2740a8e13d476feef287d55))
- Add GitHub social preview image ([`58262df`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/58262df3c663e246cf9e20d2d378398c3aff8066))
- Remove stale macOS resource fork file `._asb_illustration.png` ([`1ad6405`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/1ad6405acaf4f3a2592576c9c456395fe6ffaf7e))

### Script Growth

`asb` grew from ~1,726 lines (v0.2.0) to ~4,083 lines, adding commands: `tag`, `stats`, `discover`, `verify`, `schedule`, `hooks`, and structured output for every command.

---

## [v0.2.0] — 2026-01-21

Tagged [`v0.2.0`](https://github.com/Dicklesworthstone/agent_settings_backup_script/releases/tag/v0.2.0) at commit [`bdfba33`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/bdfba339db35876d8a57921b7b36240719d188b9). The major enhancement landed in [`ddfa290`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/ddfa290544b324ded01edc289c166547c0c0bd16) (2026-01-20) followed by the version bump.

### Features

- **Dry-run mode** — Preview changes with `--dry-run` or `-n` on any command; no filesystem writes occur
- **Restore confirmation** — See exactly which files will change before restoring; abort or proceed interactively
- **Configuration file** — Persistent settings in `~/.config/asb/config` (XDG-compliant); `asb config init` creates the file, `asb config show` displays current values
- **Export/Import** — Create portable `.tar.gz` archives with `asb export <agent> [file]` and restore them with `asb import <file>`; pipe support for remote transfer (`asb export claude - | ssh remote "asb import -"`) and encryption (`| gpg -c`)
- **Shell completions** — Tab completion for commands and agent names: `eval "$(asb completion bash)"`, `eval "$(asb completion zsh)"`, `asb completion fish | source`
- **Global options** — `-n/--dry-run`, `-f/--force`, `-v/--verbose` parsed before command dispatch

### Bug Fixes

- Fix hidden file handling: use `/.` syntax in `cp` fallback to include dotfiles ([`519fa8c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/519fa8c6adfffdbff922b9ab456b50655c65de8e))
- Fix `list_backups()` sorting by collecting lines in array before sort ([`519fa8c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/519fa8c6adfffdbff922b9ab456b50655c65de8e))
- Fix `show_diff()` trap scope using `RETURN` instead of `EXIT` ([`519fa8c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/519fa8c6adfffdbff922b9ab456b50655c65de8e))
- Prevent `.git` directory from being copied from source during backup ([`519fa8c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/519fa8c6adfffdbff922b9ab456b50655c65de8e))
- Resolve nested trap issue in `install.sh` by passing `temp_dir` between functions ([`519fa8c`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/519fa8c6adfffdbff922b9ab456b50655c65de8e))
- Exclude `.gitignore` from rsync `--delete` to prevent backup repo gitignore removal ([`90ab467`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/90ab467899e9aec1087ac4da70d84befd5503f22))

### Testing

- Initial test infrastructure: `scripts/run_tests.sh`, `scripts/test_lib.sh` assertion helpers
- Test scripts for dry-run, config support, conflict detection, E2E operations
- Test fixtures for claude, codex, and cursor agents

### Documentation

- Remove shell comments from install code blocks so copy-paste works cleanly ([`86e4e9d`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/86e4e9db401262916060addeeaec904d64fd739f))
- Add AGENTS.md for multi-agent development conventions
- Expand README with export/import, config, dry-run, and completion documentation

### Script Growth

`asb` grew from ~687 lines (v0.1.0) to ~1,726 lines, adding commands: `export`, `import`, `config`, `completion`, and global option parsing.

---

## [v0.1.0] — 2026-01-19

Initial release at commit [`2d3bed4`](https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/2d3bed44895f4c401817c70c19486179eba1ac1b).

### Features

- **Git-versioned backups** — Every backup is a git commit with full history; each agent gets its own repository under `~/.agent_settings_backups/`
- **Core commands** — `backup [agents...]`, `restore <agent> [commit]`, `list`, `history <agent>`, `diff <agent>`, `init`, `help`, `version`
- **10 supported agents** — Claude, Codex, Cursor, Gemini, Cline, Amp, Aider, OpenCode, Factory, Windsurf
- **Efficient syncing** — Uses `rsync` for incremental backups with automatic fallback to `cp`
- **Default exclusions** — `*.log`, `cache/`, `Cache/`, `.cache/`, `*.sqlite3-wal`, `*.sqlite3-shm` excluded from backup via `.gitignore`
- **Curl-pipe installer** — `curl -fsSL .../install.sh | bash` with self-cleanup
- **GitHub Actions release workflow** — Triggered on `v*` tags; runs tests, creates checksums, publishes GitHub release with `asb` binary and `checksums.txt`
- **Environment variables** — `ASB_BACKUP_ROOT`, `ASB_AUTO_COMMIT`, `ASB_VERBOSE` for configuration without files

### Architecture

- Single-file bash script (~687 lines), no external dependencies beyond `git` (and optionally `rsync`)
- Associative arrays for agent definitions (`AGENT_FOLDERS`, `AGENT_NAMES`)
- Colored, structured terminal output with `NO_COLOR` support

---

[v0.3.0]: https://github.com/Dicklesworthstone/agent_settings_backup_script/compare/v0.2.0...main
[v0.2.0]: https://github.com/Dicklesworthstone/agent_settings_backup_script/releases/tag/v0.2.0
[v0.1.0]: https://github.com/Dicklesworthstone/agent_settings_backup_script/commit/2d3bed44895f4c401817c70c19486179eba1ac1b
