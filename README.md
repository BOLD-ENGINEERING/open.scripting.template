# BOLD-Shell Framework

**Engineered for Defense** — A modular, open-source Bash scripting framework inspired by the Laravel ecosystem.

> Unionize fragmented scripts into a high-performance, CLI-driven architecture optimized for terminal workflows (Alacritty/Spacemacs) and server administration.

---

## Quick Start

```bash
# Install via the scaffolding engine
bash bin/init.sh my-project
cd my-project

# Run it
./bin/bold help
```

### Making `bold` Available in Your Session

To use `bold` without typing the full path:

```bash
# Add to current session
eval "$(make install)"

# Or add permanently to ~/.bashrc, ~/.zshrc, or config.fish:
export PATH="$PATH:/path/to/your-project/bin"
```

Then use `bold` from anywhere:

```bash
bold help
bold make:script my-tool
bold my-tool
```

## Usage

```bash
bold [options] <command> [args]

# Global options
--dry-run         Log destructive actions without executing
--no-ansi         Disable ANSI color output
-h, --help        Display help
-V, --version     Display version

# Built-in commands
bold help                  Display this help menu
bold list                  List all available user scripts
bold make:script <name>    Scaffold a new user script
bold make:provider <name>  Scaffold a new provider
```

## Architecture

```
project-root/
├── bin/bold                    # Kernel — centralized CLI runner
│   └── init.sh                 # Scaffolding engine
├── bootstrap/app.sh            # Framework initialization
├── core/
│   ├── import.sh               # Dependency injection (source-once)
│   ├── output.sh               # ANSI output engine
│   ├── utils.sh                # Dry-run-aware utilities
│   ├── metadata.sh             # Self-documentation parser and router
│   └── providers/
│       ├── provider.sh          # Service Provider registry
│       └── proxmox_provider.sh  # Example: Proxmox VE provider
├── config/
│   ├── app.conf                # Framework configuration
│   └── .env.example            # Environment template
└── scripts/                    # User-defined scripts
    └── your-script.sh
```

## Features

### Service Provider Pattern
Register external tool integrations via `core/providers/`. Providers are auto-detected and loaded globally.

### Dependency Injection
`bold::import` sources files exactly once, preventing circular dependencies.

### Scaffolding Engine
```bash
bold make:script my-tool    # Generates a ready-to-use script template
bold make:provider my-tool  # Generates a ready-to-use provider template
```

### Self-Documentation
Add `@meta-desc`, `@meta-opt`, and `@meta-cmd` tags to scripts for auto-generated `--help` menus.

### Safety First (Defense-Grade)
The global `--dry-run` flag causes all destructive functions to log instead of execute.

```bash
bold --dry-run some-command
```

## Requirements

- Bash 4.4+
- Linux / macOS / WSL

## Roadmap

- [x] Centralized kernel runner (`bin/bold`)
- [x] Service Provider pattern
- [x] Dependency injection engine
- [x] Scaffolding (`make:script`, `make:provider`)
- [x] Self-documentation (`@meta-*` tags)
- [x] `--dry-run` safety flag
- [ ] Docker provider
- [ ] Tailscale provider
- [ ] Testing framework integration
- [ ] Plugin auto-discovery

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

---

**BOLD ENGINEERING** — *Engineered for Defense*
