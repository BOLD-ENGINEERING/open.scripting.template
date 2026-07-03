# BOLD-Shell — Agent Guide

## Entrypoint & Boot Order

- `bin/bold` is the sole entrypoint. It sets `BOLD_ROOT` (via `dirname $0/..`), then sources `bootstrap/app.sh`.
- `app.sh` defines `bold::import`, loads core modules in order (`import.sh`, `output.sh`, `utils.sh`, `provider.sh`), sources `config/app.conf` if present, sources root `.env` if present (with `set -a`), registers/auto-discovers providers, then loads `metadata.sh` (router).
- `bin/init.sh` is the scaffolding engine (run standalone via `bash bin/init.sh <target>`, or through `bold make:project <name>`). It is NOT part of scaffolded projects.

## Key Conventions

- **Strict mode**: `set -euo pipefail` in every executable script.
- **Namespacing**: `bold::`, `file::`, `sys::`, `provider::`, `provider::NAME::` — double colons separate hierarchy levels.
- **CLI-to-func mapping**: hyphens become underscores, colons stay colons. `bold proxmox:list-vms` calls `provider::proxmox::list_vms`.
- **`bold::import`** sources files exactly once via `_BOLD_LOADED` associative array. Use instead of bare `source` for any framework file.
- **`--dry-run`** is a global flag parsed *before* routing in `bin/bold`. All destructive functions (`file::delete`, `sys::execute`, etc.) guard with `bold::is_dry_run`. It is NOT a per-command flag.

## CLI Routing Priority

`bold::route` tries commands in this order:
1. Built-in (`make:script`, `make:provider`, `make:project`, `test`, `list`, `help`)
2. Provider functions (e.g. `bold proxmox:status` → `provider::proxmox::status`)
3. User scripts (`scripts/<name>.sh` — sourced, self-executes via `main "$@"`)

## Providers

- Files named `*_provider.sh` in `core/providers/` are auto-registered at boot via `provider::register_all`.
- Providers are **registered but NOT sourced** until `provider::load` is called (lazy loading).
- Provider `init()` functions run on load and should detect tool availability, returning non-zero if unavailable.

## Scripts

- User scripts live in `scripts/*.sh`. Run via `bold <name>`.
- `bold::run_user_script` sources the file (not a subshell). Scripts self-execute via `main "$@"` at the bottom.
- `bold make:script <name>` generates a starter template with `chmod +x`.
- `bold make:provider <name>` generates a provider, auto-registers it, and sets `chmod +x`.

## Testing

- **Test runner**: `bin/test.sh` — run via `bold test` or standalone `bash bin/test.sh`.
- Test files live in `tests/*_test.sh`, define functions named `test::group::name()`.
- The runner uses grep-based discovery (`runner::get_tests` reads function names from file, not `declare -F`) to avoid recursive matching of its own functions.
- `bold make:project <name>` scaffolds a new project via `bin/init.sh` including test infrastructure.
- `make lint` / `make test` in scaffolded projects run `shellcheck -x bin/bold bootstrap/*.sh core/*.sh core/providers/*.sh`.
- ShellCheck may not be installed in the environment. Run manually when making changes.

## Environment

- `.env` at project root is auto-sourced with `set -a` (exports all vars). `config/.env.example` documents available variables.
- `BOLD_DEBUG=true` enables `bold::debug` output.
- `BOLD_NO_ANSI=true` disables colors (also set by `--no-ansi` flag).
- `BOLD_ROOT` is always available inside any framework file.

## Outdated / Dead Code

- `bold::cmd_to_func` in `core/metadata.sh:19-23` is defined but never called.
- `core/import.sh:13-15` is a no-op guard that always passes.

## Cursor Cloud specific instructions

- Pure Bash project: no package manager, no build step, and no long-running service. Run directly with `./bin/bold <command>` (no need to edit `PATH`; `make install` only prints an export line).
- Standard commands (already documented above): run = `./bin/bold help`, test = `./bin/bold test [filter]`, lint = `shellcheck -x bin/bold bootstrap/*.sh core/*.sh core/providers/*.sh`.
- `shellcheck` is installed by the startup update script (via `apt`). `lint` should exit `0` (clean); keep it that way for any new/changed scripts.
- `proxmox:*` provider commands only route when their `init()` succeeds. On the cloud VM `qm`/`pvesh`/`pct` are absent, so `init()` fails and `./bin/bold proxmox:status` returns `Unknown command` — this is expected here, not a bug.
- Quickest end-to-end smoke test of core functionality: `./bin/bold make:script hello-world && ./bin/bold hello-world` (prints `Hello from hello-world!`), then `rm scripts/hello-world.sh` to keep the tree clean.
