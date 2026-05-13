# Contributing to BOLD-Shell

## ShellCheck Compliance

All scripts **must** pass [ShellCheck](https://www.shellcheck.net/) before merging.

```bash
shellcheck -x bin/bold bootstrap/*.sh core/*.sh core/providers/*.sh
```

## Function Namespacing

Follow the **BOLD-Spec** namespacing convention:

| Namespace     | Purpose                         | Example                          |
|---------------|----------------------------------|----------------------------------|
| `bold::`       | Framework core functions         | `bold::import`, `bold::info`      |
| `file::`      | File operations                  | `file::delete`, `file::backup`    |
| `sys::`       | System command wrappers          | `sys::execute`                     |
| `provider::`  | Provider functions               | `provider::docker_up`              |
| `provider::NAME::` | Provider-specific functions  | `provider::proxmox::list_vms`      |

### Naming Rules

1. **Double colons** (`::`) separate hierarchy levels
2. **Underscores** (`_`) separate words within a level
3. **Hyphens** in CLI commands map to underscores in function names

## Coding Standards

- Bash 4.4+ with `set -euo pipefail` at the top of every executable script
- Use `[[ ]]` for conditionals (not `[ ]`)
- Use `printf` or `echo` with `-e` for formatted output
- Quote all variable expansions unless intentionally unquoted
- Prefer local variables inside functions
- All public functions must have a comment block describing parameters and return values
- Use the `bold::is_dry_run` guard in any destructive function

## Provider Pattern

To create a new provider:

1. Create `core/providers/<name>_provider.sh`
2. Implement `provider::<name>::init()` for auto-detection
3. Add provider functions as `provider::<name>::<action>()`
4. Use `@meta-desc` and `@meta-provider` comment tags
5. Register in `bootstrap/app.sh` with `provider::register "<name>" "core/providers/<name>_provider.sh"`

## Pull Request Process

1. Ensure ShellCheck passes
2. Test with `--dry-run` to verify safety
3. Update metadata comments if adding new commands
4. Open a PR with a descriptive title and scope

---

**BOLD ENGINEERING** — *Engineered for Defense*
