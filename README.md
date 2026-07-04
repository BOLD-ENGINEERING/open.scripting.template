# BOLD-Shell Framework

**Engineered for Defense** - A modular, open-source Bash scripting framework inspired by the Laravel ecosystem.

> Unionize fragmented scripts into a high-performance, CLI-driven architecture optimized for terminal workflows (Alacritty/Spacemacs) and server administration.

---

## Quick Start

```bash
# Install bold to ~/.local/bin and update your shell PATH
bash install
# or: make install

# Use bold from anywhere (open a new terminal first, or source ~/.bashrc)
bold help
bold make:script my-tool
bold make:project my-project
```

> **Tip:** Override the install location with `PREFIX=/usr/local bash install` (may require `sudo` for system paths).

### Usage

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
bold make:project <name>   Scaffold a new BOLD-Shell project
bold test [filter]         Run test suites
```

## Architecture

```
project-root/
├── install                     # bash install - add bold to PATH
├── Makefile                    # make install - runs install script
├── bin/bold                    # Kernel - centralized CLI runner
│   ├── init.sh                 # Scaffolding engine (standalone or bold make:project)
│   └── test.sh                 # Test runner
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
├── scripts/                    # User-defined scripts
│   └── your-script.sh
└── tests/                      # Test suites
    └── framework_test.sh
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
- [x] Scaffolding (`make:script`, `make:provider`, `make:project`)
- [x] Self-documentation (`@meta-*` tags)
- [x] `--dry-run` safety flag
- [x] Testing framework integration (`bold test`)
- [ ] Docker provider
- [ ] Tailscale provider
- [ ] ProxmoxVE provider
- [ ] Plugin auto-discovery

## License

GNU General Public License v3.0 - see [LICENSE](LICENSE).

---

**BOLD ENGINEERING** - *Engineered for Defense*
