#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - BOLD-Shell Scaffolding Engine
# =============================================================================
# Builds the complete project hierarchy and initializes the bold binary.
# Usage: bash init.sh /path/to/new-project
# =============================================================================

set -euo pipefail

readonly BOLD_VERSION="1.0.0"

C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
err()   { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

usage() {
    echo "BOLD-Shell Scaffolding Engine v${BOLD_VERSION}"
    echo ""
    echo "Usage: bash init.sh <target-directory>"
    echo ""
    exit 1
}

write_file() {
    local target="$1"
    mkdir -p "$(dirname "${target}")"
    cat > "${target}"
    local rel="${target#${2}/}"
    rel="${rel#/}"
    ok "Created: ${rel}"
}

write_bin_bold() {
    local root="$1"
    cat > "${root}/bin/bold" << 'BOLDEOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - BOLD-Shell Framework
# Kernel: The centralized CLI runner (Artisan-style)
# =============================================================================
# @meta-desc  BOLD-Shell Framework - CLI Kernel
# @meta-cmd  bold [options] <command> [args]
# @meta-opt  --dry-run  Log destructive actions without executing
# @meta-opt  --no-ansi  Disable ANSI color output
# @meta-opt  -h,--help  Display this help menu
# @meta-opt  -V,--version  Display framework version
# =============================================================================

set -euo pipefail

BOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BOLD_ROOT
BOLD_VERSION="1.0.0"
export BOLD_VERSION

source "${BOLD_ROOT}/bootstrap/app.sh"

BOLD_DRY_RUN=false
BOLD_NO_ANSI=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) BOLD_DRY_RUN=true; shift ;;
        --no-ansi) BOLD_NO_ANSI=true; shift ;;
        -h|--help) bold::help; exit 0 ;;
        -V|--version) bold::version; exit 0 ;;
        *) break ;;
    esac
done

export BOLD_DRY_RUN
export BOLD_NO_ANSI

bold::route "$@"
BOLDEOF
    chmod +x "${root}/bin/bold"
    ok "Created: bin/bold"
}

write_bootstrap_app() {
    local root="$1"
    cat > "${root}/bootstrap/app.sh" << 'APPEOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Bootstrap / App Initialization
# =============================================================================

bold::import() {
    local path="$1"
    local full_path="${BOLD_ROOT}/${path}"
    if [[ ! -v _BOLD_LOADED["${full_path}"] ]]; then
        _BOLD_LOADED["${full_path}"]=1
        source "${full_path}"
    fi
}

declare -gA _BOLD_LOADED=()

bold::import core/import.sh
bold::import core/output.sh
bold::import core/utils.sh
bold::import core/providers/provider.sh

if [[ -f "${BOLD_ROOT}/config/app.conf" ]]; then
    source "${BOLD_ROOT}/config/app.conf"
fi

if [[ -f "${BOLD_ROOT}/.env" ]]; then
    set -a
    source "${BOLD_ROOT}/.env"
    set +a
fi

provider::register "proxmox" "core/providers/proxmox_provider.sh"
provider::register_all

bold::import core/metadata.sh
APPEOF
    ok "Created: bootstrap/app.sh"
}

write_core_import() {
    local root="$1"
    cat > "${root}/core/import.sh" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Core / Import Engine
# =============================================================================
# Dependency Injection: Sources files exactly once to prevent circular deps.
# =============================================================================

if [[ ! -v _BOLD_LOADED_META ]]; then
    declare -gA _BOLD_LOADED=()
    _BOLD_LOADED_META=1
fi
EOF
    ok "Created: core/import.sh"
}

write_core_output() {
    local root="$1"
    cat > "${root}/core/output.sh" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Core / Output Engine
# =============================================================================
# ANSI-compliant terminal output with color-coded log levels.
# =============================================================================

readonly BOLD_C_RED='\033[0;31m'
readonly BOLD_C_GREEN='\033[0;32m'
readonly BOLD_C_YELLOW='\033[1;33m'
readonly BOLD_C_CYAN='\033[0;36m'
readonly BOLD_C_MAGENTA='\033[0;35m'
readonly BOLD_C_BOLD='\033[1m'
readonly BOLD_C_RESET='\033[0m'

bold::color() {
    local color="$1"
    shift
    if [[ "${BOLD_NO_ANSI:-false}" != "true" ]] && [[ -t 1 ]]; then
        echo -e "${color}${*}${BOLD_C_RESET}"
    else
        echo "$*"
    fi
}

bold::info()    { bold::color "${BOLD_C_CYAN}" "[INFO] $*"; }
bold::success() { bold::color "${BOLD_C_GREEN}" "[SUCCESS] $*"; }
bold::warn()    { bold::color "${BOLD_C_YELLOW}" "[WARN] $*"; }
bold::error()   { bold::color "${BOLD_C_RED}" "[ERROR] $*" >&2; }

bold::debug() {
    if [[ "${BOLD_DEBUG:-false}" == "true" ]]; then
        bold::color "${BOLD_C_MAGENTA}" "[DEBUG] $*"
    fi
}

bold::title() {
    echo ""
    bold::color "${BOLD_C_BOLD}" "=== $* ==="
    echo ""
}

bold::line() {
    printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '='
}
EOF
    ok "Created: core/output.sh"
}

write_core_utils() {
    local root="$1"
    cat > "${root}/core/utils.sh" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Core / Utilities
# =============================================================================
# Safety-first utility functions with native --dry-run support.
# =============================================================================

bold::is_dry_run() {
    [[ "${BOLD_DRY_RUN:-false}" == "true" ]]
}

file::delete() {
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would delete: $*"
        return 0
    fi
    rm -f "$@"
}

file::copy() {
    local src="$1" dst="$2"
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would copy ${src} -> ${dst}"
        return 0
    fi
    cp "${src}" "${dst}"
}

file::move() {
    local src="$1" dst="$2"
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would move ${src} -> ${dst}"
        return 0
    fi
    mv "${src}" "${dst}"
}

file::backup() {
    local file="$1"
    local backup="${file}.bak.$(date +%s)"
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would backup ${file} -> ${backup}"
        return 0
    fi
    cp "${file}" "${backup}"
    bold::info "Backup created: ${backup}"
}

sys::execute() {
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would execute: $*"
        return 0
    fi
    "$@"
}

sys::command_exists() {
    command -v "$1" &>/dev/null
}

bold::ensure_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        bold::error "This command requires root privileges."
        exit 1
    fi
}

bold::confirm() {
    local prompt="${1:-Continue?} ${2:-[y/N]}"
    local response
    read -r -p "${prompt} " response
    case "${response}" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}
EOF
    ok "Created: core/utils.sh"
}

write_core_providers_provider() {
    local root="$1"
    cat > "${root}/core/providers/provider.sh" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Core / Service Provider Registry
# =============================================================================
# Service Provider Pattern: Register and load third-party integrations.
# Providers can be auto-detected or loaded on-demand.
# =============================================================================

if [[ ! -v _BOLD_PROVIDER_REGISTERED ]]; then
    declare -gA _BOLD_PROVIDERS=()
    declare -gA _BOLD_PROVIDERS_LOADED=()
    _BOLD_PROVIDER_REGISTERED=1
fi

provider::register() {
    local name="$1"
    local path="$2"
    _BOLD_PROVIDERS["${name}"]="${BOLD_ROOT}/${path}"
    bold::debug "Provider registered: ${name} -> ${path}"
}

provider::registered() {
    local name="$1"
    [[ -n "${_BOLD_PROVIDERS[${name}]-}" ]]
}

provider::load() {
    local name="$1"
    if [[ -n "${_BOLD_PROVIDERS_LOADED[${name}]-}" ]]; then
        return 0
    fi
    if [[ -n "${_BOLD_PROVIDERS[${name}]-}" ]]; then
        bold::debug "Loading provider: ${name}"
        source "${_BOLD_PROVIDERS[${name}]}"
        _BOLD_PROVIDERS_LOADED["${name}"]=1
        if declare -F "provider::${name}::init" &>/dev/null; then
            "provider::${name}::init"
        fi
        bold::success "Loaded provider: ${name}"
    else
        bold::warn "Provider not registered: ${name}"
        return 1
    fi
}

provider::load_all() {
    local name
    for name in "${!_BOLD_PROVIDERS[@]}"; do
        provider::load "${name}" 2>/dev/null || true
    done
}

provider::register_all() {
    local provider_dir="${BOLD_ROOT}/core/providers"
    local file
    for file in "${provider_dir}"/*_provider.sh; do
        [[ -f "${file}" ]] || continue
        local base
        base="$(basename "${file}" _provider.sh)"
        if ! provider::registered "${base}"; then
            provider::register "${base}" "${file}"
        fi
    done
}
EOF
    ok "Created: core/providers/provider.sh"
}

write_core_providers_proxmox() {
    local root="$1"
    cat > "${root}/core/providers/proxmox_provider.sh" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Provider / Proxmox VE
# =============================================================================
# @meta-desc  Proxmox VE management utilities
# @meta-provider proxmox
# =============================================================================

provider::proxmox::init() {
    bold::debug "[proxmox] Checking availability..."
    if ! sys::command_exists qm && ! sys::command_exists pvesh; then
        bold::warn "[proxmox] Neither qm nor pvesh found"
        return 1
    fi
    bold::info "[proxmox] Proxmox environment detected"
    return 0
}

provider::proxmox::list_vms() {
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would list Proxmox VMs"
        return 0
    fi
    if ! sys::command_exists qm; then
        bold::error "[proxmox] qm not found"
        return 1
    fi
    qm list
}

provider::proxmox::list_containers() {
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would list Proxmox containers"
        return 0
    fi
    if ! sys::command_exists pct; then
        bold::error "[proxmox] pct not found"
        return 1
    fi
    pct list
}

provider::proxmox::status() {
    bold::title "Proxmox Provider Status"
    bold::info "qm:      $(sys::command_exists qm && echo "available" || echo "unavailable")"
    bold::info "pvesh:   $(sys::command_exists pvesh && echo "available" || echo "unavailable")"
    bold::info "pct:     $(sys::command_exists pct && echo "available" || echo "unavailable")"
}
EOF
    ok "Created: core/providers/proxmox_provider.sh"
}

write_core_metadata() {
    local root="$1"
    cat > "${root}/core/metadata.sh" << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Core / Metadata & Routing Engine
# =============================================================================
# Self-documentation parser and CLI command router.
# =============================================================================

bold::parse_metadata() {
    local file="$1"
    local tag="$2"
    [[ ! -f "${file}" ]] && return 1
    while IFS= read -r line; do
        if [[ "${line}" =~ ^#[[:space:]]*@${tag}[[:space:]]+(.*)$ ]]; then
            echo "${BASH_REMATCH[1]}"
        fi
    done < "${file}"
}

bold::provider_func_for() {
    local cmd="$1"
    local func="provider::${cmd//:/\:\:}"
    func="${func//-/_}"
    echo "${func}"
}

bold::help() {
    bold::title "BOLD-Shell Framework v${BOLD_VERSION}"
    echo "Engineered for Defense - Modular Bash Framework"
    echo ""
    bold::color "${BOLD_C_BOLD}" "Usage:"
    echo "  bold [options] <command> [args]"
    echo ""
    bold::color "${BOLD_C_BOLD}" "Global Options:"
    echo "  --dry-run         Log destructive actions without executing"
    echo "  --no-ansi         Disable ANSI color output"
    echo "  -h, --help        Display this help menu"
    echo "  -V, --version     Display framework version"
    echo ""
    bold::color "${BOLD_C_BOLD}" "Built-in Commands:"
    echo "  make:script <name>   Scaffold a new user script"
    echo "  make:provider <name> Scaffold a new provider"
    echo "  make:project <name>  Scaffold a new BOLD-Shell project"
    echo "  test [filter]        Run the test suite (optional filter)"
    echo "  list                  List all available user scripts"
    echo "  help                  Display this help menu"
    echo ""
    bold::color "${BOLD_C_BOLD}" "Available Providers:"
    local name path desc
    for name in "${!_BOLD_PROVIDERS[@]}"; do
        path="${_BOLD_PROVIDERS[${name}]}"
        desc="$(bold::parse_metadata "${path}" "meta-desc" | head -1)"
        printf "  %-22s %s\n" "${name}" "${desc:-No description}"
    done
    echo ""
    bold::color "${BOLD_C_BOLD}" "Provider Commands:"
    bold::list_provider_commands
    echo ""
    bold::color "${BOLD_C_BOLD}" "User Scripts:"
    bold::list_scripts
    echo ""
}

bold::version() {
    echo "BOLD-Shell Framework v${BOLD_VERSION}"
    echo "BOLD ENGINEERING - Engineered for Defense"
}

bold::list_provider_commands() {
    local func
    while IFS= read -r func; do
        [[ -z "${func}" ]] && continue
        local provider_cmd="${func#provider::}"
        provider_cmd="${provider_cmd//::/:}"
        printf "  %-22s %s\n" "${provider_cmd}" "Provider command"
    done < <(declare -F | awk '{print $3}' | grep -E '^provider::.*::' | sort)
}

bold::route() {
    local cmd="${1:-}"
    shift 2>/dev/null || true

    if [[ -z "${cmd}" ]]; then
        bold::help
        return 0
    fi

    case "${cmd}" in
        make:script|make:provider|make:project)
            bold::cmd_make "${cmd#make:}" "$@"
            return $?
            ;;
        test)
            bold::cmd_test "$@"
            return $?
            ;;
        list)
            bold::list_scripts
            return $?
            ;;
        help)
            bold::help
            return $?
            ;;
    esac

    local provider_func
    provider_func="$(bold::provider_func_for "${cmd}")"
    if declare -F "${provider_func}" &>/dev/null; then
        "${provider_func}" "$@"
        return $?
    fi

    if bold::run_user_script "${cmd}" "$@"; then
        return $?
    fi

    bold::error "Unknown command: ${cmd}"
    bold::info "Run 'bold help' for available commands."
    return 1
}

bold::cmd_make() {
    local target="${1:-}"
    shift 2>/dev/null || true
    case "${target}" in
        script) bold::make_script "$@" ;;
        provider) bold::make_provider "$@" ;;
        project) bold::make_project "$@" ;;
        *) bold::error "Unknown make target: ${target}. Use 'script', 'provider', or 'project'." ;;
    esac
}

bold::cmd_test() {
    local filter="${1:-}"
    source "${BOLD_ROOT}/bin/test.sh"
    main "${filter}"
}

bold::make_project() {
    local name="${1:-}"
    if [[ -z "${name}" ]]; then
        bold::error "Usage: bold make:project <name>"
        return 1
    fi
    local init="${BOLD_ROOT}/bin/init.sh"
    if [[ ! -f "${init}" ]]; then
        bold::error "Scaffolding script not found at ${init}"
        return 1
    fi
    bash "${init}" "${name}"
}

bold::make_script() {
    local name="${1:-}"
    if [[ -z "${name}" ]]; then
        bold::error "Usage: bold make:script <name>"
        return 1
    fi
    local file="${BOLD_ROOT}/scripts/${name}.sh"
    if [[ -f "${file}" ]]; then
        bold::error "Script already exists: ${file}"
        return 1
    fi
    cat > "${file}" << SCRIPT_EOF
#!/usr/bin/env bash
# =============================================================================
# Script: ${name}
# Author:  $(whoami)
# @meta-desc  Description of ${name}
# =============================================================================

set -euo pipefail

main() {
    bold::info "Hello from ${name}!"
}

main "\$@"
SCRIPT_EOF
    chmod +x "${file}"
    bold::success "Created script: ${file}"
}

bold::make_provider() {
    local name="${1:-}"
    if [[ -z "${name}" ]]; then
        bold::error "Usage: bold make:provider <name>"
        return 1
    fi
    local file="${BOLD_ROOT}/core/providers/${name}_provider.sh"
    if [[ -f "${file}" ]]; then
        bold::error "Provider already exists: ${file}"
        return 1
    fi
    cat > "${file}" << PROVIDER_EOF
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Provider / ${name}
# =============================================================================
# @meta-desc  ${name} management utilities
# @meta-provider ${name}
# =============================================================================

provider::${name}::init() {
    bold::debug "[${name}] Provider initialized"
}

provider::${name}::status() {
    bold::info "[${name}] Provider status check"
}
PROVIDER_EOF
    chmod +x "${file}"
    provider::register "${name}" "${file}"
    bold::success "Created provider: ${file}"
}

bold::list_scripts() {
    local script count=0
    if [[ ! -d "${BOLD_ROOT}/scripts" ]]; then
        echo "  (no scripts directory)"
        return 0
    fi
    for script in "${BOLD_ROOT}/scripts"/*.sh; do
        [[ -f "${script}" ]] || continue
        count=$((count + 1))
        local name
        name="$(basename "${script}" .sh)"
        local desc
        desc="$(bold::parse_metadata "${script}" "meta-desc" | head -1)"
        printf "  %-22s %s\n" "${name}" "${desc:-User script}"
    done
    if [[ "${count}" -eq 0 ]]; then
        echo "  (no user scripts - use 'bold make:script <name>' to create one)"
    fi
}

bold::run_user_script() {
    local cmd="$1"
    shift
    local script_file="${BOLD_ROOT}/scripts/${cmd}.sh"
    if [[ -f "${script_file}" ]]; then
        if bold::is_dry_run; then
            bold::warn "[DRY-RUN] Would execute: ${script_file} $*"
            return 0
        fi
        source "${script_file}"
        return $?
    fi
    return 1
}
EOF
    ok "Created: core/metadata.sh"
}

write_config() {
    local root="$1"

    cat > "${root}/config/app.conf" << 'EOF'
# =============================================================================
# BOLD ENGINEERING - Application Configuration
# =============================================================================

BOLD_DEBUG="${BOLD_DEBUG:-false}"
BOLD_LOG_LEVEL="${BOLD_LOG_LEVEL:-info}"
SCRIPTS_DIR="${BOLD_ROOT}/scripts"
PROVIDERS_DIR="${BOLD_ROOT}/core/providers"
BOLD_DEFAULT_COMMAND="help"
EOF
    ok "Created: config/app.conf"

    cat > "${root}/config/.env.example" << 'EOF'
# BOLD ENGINEERING - Environment Configuration
# Copy this file to .env at the project root and fill in your values.

BOLD_DEBUG=false
BOLD_LOG_LEVEL=info

# Example: Proxmox connection settings
# PROXMOX_HOST=192.168.1.100
# PROXMOX_USER=root@pam
# PROXMOX_PASSWORD=
EOF
    ok "Created: config/.env.example"
}

write_readme() {
    local root="$1"
    cat > "${root}/README.md" << 'MDEOF'
# BOLD-Shell Framework

**Engineered for Defense** — A modular, open-source Bash scripting framework inspired by the Laravel ecosystem.

> Unionize fragmented scripts into a high-performance, CLI-driven architecture optimized for terminal workflows (Alacritty/Spacemacs) and server administration.

---

## Quick Start

```bash
# Run a command
./bin/bold help

# List available scripts
./bin/bold list

# Scaffold a new user script
./bin/bold make:script my-tool
```

### Adding `bin/` to Your PATH

```bash
export PATH="$PATH:/path/to/your-project/bin"
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
MDEOF
    ok "Created: README.md"
}

write_contributing() {
    local root="$1"
    cat > "${root}/CONTRIBUTING.md" << 'MDEOF'
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
MDEOF
    ok "Created: CONTRIBUTING.md"
}

write_gitignore() {
    local root="$1"
    cat > "${root}/.gitignore" << 'EOF'
.env
*.bak.*
*.swp
*.swo
.DS_Store
EOF
    ok "Created: .gitignore"
}

write_makefile() {
    local root="$1"
    cat > "${root}/Makefile" << 'EOF'
SHELL := /usr/bin/env bash
.PHONY: install test lint clean

install:
	@chmod +x bin/bold
	@echo "BOLD-Shell installed. Run ./bin/bold help"

test:
	@shellcheck -x bin/bold bootstrap/*.sh core/*.sh core/providers/*.sh

lint:
	@shellcheck -x bin/bold bootstrap/*.sh core/*.sh core/providers/*.sh

clean:
	@find . -name "*.bak.*" -delete
	@echo "Cleaned up backup files."
EOF
    ok "Created: Makefile"
}

write_test_runner() {
    local root="$1"
    cat > "${root}/bin/test.sh" << 'TESTEOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Test Runner
# =============================================================================
# Usage: bold test [filter]
#        bash bin/test.sh [filter] (standalone)
# =============================================================================

if [[ -z "${BOLD_ROOT:-}" ]]; then
    set -euo pipefail
    BOLD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export BOLD_ROOT
    source "${BOLD_ROOT}/bootstrap/app.sh"
fi

_TESTS_RAN=0
_TESTS_PASSED=0
_TESTS_FAILED=0

assert::true() {
    if ! "$@"; then
        echo "  ASSERT FAIL: $*" >&2
        return 1
    fi
}

assert::false() {
    if "$@"; then
        echo "  ASSERT FAIL: expected false: $*" >&2
        return 1
    fi
}

assert::equals() {
    local expected="$1" actual="$2" label="${3:-}"
    if [[ "${expected}" != "${actual}" ]]; then
        echo "  ASSERT FAIL${label:+ ($label)}: expected \"${expected}\", got \"${actual}\"" >&2
        return 1
    fi
}

assert::not_empty() {
    local value="$1" label="${2:-}"
    if [[ -z "${value}" ]]; then
        echo "  ASSERT FAIL${label:+ ($label)}: expected non-empty value" >&2
        return 1
    fi
}

runner::get_tests() {
    local file="$1"
    grep -E '^test::[a-zA-Z_:-]+\(\)' "${file}" 2>/dev/null | sed 's/().*$//' | sort
}

runner::run_file() {
    local file="$1"
    local filter="${2:-}"
    source "${file}"

    local func ran=0 passed=0 failed=0
    while IFS= read -r func; do
        [[ -z "${func}" ]] && continue
        local name="${func#test::}"
        name="${name//::/ }"

        if [[ -n "${filter}" && "${name}" != *"${filter}"* ]]; then
            continue
        fi

        ran=$((ran + 1))
        if ( set -e; "${func}" ) 2>/tmp/bold_test_err.$$; then
            passed=$((passed + 1))
            bold::color "${BOLD_C_GREEN}" "  PASS  ${name}"
        else
            bold::color "${BOLD_C_RED}" "  FAIL  ${name}"
            if [[ -s /tmp/bold_test_err.$$ ]]; then
                sed 's/^/        /' /tmp/bold_test_err.$$
            fi
        fi
    done < <(runner::get_tests "${file}")

    rm -f /tmp/bold_test_err.$$
    _TESTS_RAN=$((_TESTS_RAN + ran))
    _TESTS_PASSED=$((_TESTS_PASSED + passed))
    _TESTS_FAILED=$((_TESTS_FAILED + failed))

    if [[ "${ran}" -eq 0 ]]; then
        bold::warn "  (no matching tests)"
    fi
}

runner::run_all() {
    local filter="${1:-}"
    local tests_dir="${BOLD_ROOT}/tests"

    if [[ ! -d "${tests_dir}" ]]; then
        bold::error "No tests directory at ${tests_dir}"
        return 1
    fi

    local file count=0
    for file in "${tests_dir}"/*_test.sh; do
        [[ -f "${file}" ]] || continue
        count=$((count + 1))
    done

    if [[ "${count}" -eq 0 ]]; then
        bold::warn "No test files found in ${tests_dir}"
        return 0
    fi

    for file in "${tests_dir}"/*_test.sh; do
        [[ -f "${file}" ]] || continue
        local name
        name="$(basename "${file}" _test.sh)"
        bold::title "Suite: ${name}"
        runner::run_file "${file}" "${filter}"
    done

    echo ""
    bold::line
    if [[ "${_TESTS_FAILED}" -eq 0 ]]; then
        bold::success "${_TESTS_PASSED}/${_TESTS_RAN} passed"
    else
        bold::error "${_TESTS_FAILED} failed, ${_TESTS_PASSED}/${_TESTS_RAN} passed"
        return 1
    fi
}

main() {
    local filter="${1:-}"
    bold::title "BOLD-Shell Tests"
    runner::run_all "${filter}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
TESTEOF
    chmod +x "${root}/bin/test.sh"
    ok "Created: bin/test.sh"
}

write_framework_tests() {
    local root="$1"
    cat > "${root}/tests/framework_test.sh" << 'TESTEOF'
#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Framework Test Suite
# =============================================================================

# Boot / Loader

test::boot::loads_core_modules() {
    declare -F bold::import  &>/dev/null
    declare -F bold::info    &>/dev/null
    declare -F bold::is_dry_run &>/dev/null
    declare -F provider::register &>/dev/null
}

test::boot::root_is_set() { [[ -n "${BOLD_ROOT}" ]]; }
test::boot::version_is_set() { [[ -n "${BOLD_VERSION}" ]]; }

# Dry-Run

test::dry_run::false_by_default() {
    assert::false bold::is_dry_run
}

test::dry_run::true_when_set() {
    local saved="${BOLD_DRY_RUN:-false}"
    BOLD_DRY_RUN=true
    assert::true bold::is_dry_run
    BOLD_DRY_RUN="${saved}"
}

test::dry_run::file_delete_logs() {
    local saved="${BOLD_DRY_RUN:-false}"
    BOLD_DRY_RUN=true
    local output
    output="$(file::delete /tmp/nonexistent 2>&1)"
    assert::not_empty "${output}" "dry-run logged"
    BOLD_DRY_RUN="${saved}"
}

# Provider Registry

test::provider::proxmox_registered() {
    provider::registered proxmox
}

test::provider::register_new() {
    local name="_test_dummy_$$"
    provider::register "${name}" "core/providers/provider.sh"
    assert::true provider::registered "${name}"
    unset "_BOLD_PROVIDERS[${name}]"
}

# Metadata / Routing

test::metadata::parse_desc() {
    local desc
    desc="$(bold::parse_metadata "${BOLD_ROOT}/bin/bold" "meta-desc")"
    [[ "${desc}" == *"BOLD-Shell Framework"* ]]
}

test::metadata::provider_func_for_converts() {
    local result
    result="$(bold::provider_func_for "proxmox:list-vms")"
    [[ "${result}" == "provider::proxmox::list_vms" ]]
}

# Scaffolding

test::scaffold::make_script_creates_file() {
    local name="_test_script_$$"
    bold::make_script "${name}"
    local file="${BOLD_ROOT}/scripts/${name}.sh"
    [[ -f "${file}" ]]
    rm -f "${file}"
}

test::scaffold::make_script_is_executable() {
    local name="_test_exec_$$"
    bold::make_script "${name}"
    local file="${BOLD_ROOT}/scripts/${name}.sh"
    [[ -x "${file}" ]]
    rm -f "${file}"
}
TESTEOF
    ok "Created: tests/framework_test.sh"
}

main() {
    local target_dir="${1:-}"

    if [[ -z "${target_dir}" ]]; then
        usage
    fi

    target_dir="$(realpath "${target_dir}" 2>/dev/null || echo "${target_dir}")"

    if [[ -d "${target_dir}" ]]; then
        if [[ "$(ls -A "${target_dir}" 2>/dev/null)" ]]; then
            err "Target directory exists and is not empty: ${target_dir}"
            exit 1
        fi
    fi

    echo ""
    info "Scaffolding BOLD-Shell v${BOLD_VERSION} at: ${target_dir}"
    echo ""

    mkdir -p "${target_dir}"/{bin,bootstrap,core/providers,config,scripts,tests}
    touch "${target_dir}/scripts/.gitkeep"
    touch "${target_dir}/tests/.gitkeep"

    write_bin_bold           "${target_dir}"
    write_bootstrap_app      "${target_dir}"
    write_core_import        "${target_dir}"
    write_core_output        "${target_dir}"
    write_core_utils         "${target_dir}"
    write_core_providers_provider  "${target_dir}"
    write_core_providers_proxmox   "${target_dir}"
    write_core_metadata      "${target_dir}"
    write_config             "${target_dir}"
    write_readme             "${target_dir}"
    write_contributing       "${target_dir}"
    write_gitignore          "${target_dir}"
    write_makefile           "${target_dir}"
    write_test_runner        "${target_dir}"
    write_framework_tests    "${target_dir}"

    echo ""
    ok "BOLD-Shell v${BOLD_VERSION} scaffolded successfully at: ${target_dir}"
    echo ""
    info "Next steps:"
    info "  cd ${target_dir}"
    info "  ./bin/bold help"
    echo ""
}

main "$@"
