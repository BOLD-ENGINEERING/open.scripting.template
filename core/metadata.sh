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

bold::cmd_to_func() {
    local cmd="$1"
    cmd="${cmd//-/_}"
    echo "${cmd//:*/}"
}

bold::provider_func_for() {
    local cmd="$1"
    local func="provider::${cmd//:/\:\:}"
    func="${func//-/_}"
    echo "${func}"
}

bold::help() {
    bold::title "BOLD-Shell Framework v${BOLD_VERSION}"
    echo "Engineered for Defense — Modular Bash Framework"
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
    echo "BOLD ENGINEERING — Engineered for Defense"
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
    # shellcheck source=/dev/null
    source "${BOLD_ROOT}/bin/test.sh" && main "${filter}"
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
    local script
    local count=0
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
        echo "  (no user scripts — use 'bold make:script <name>' to create one)"
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
        # shellcheck source=/dev/null
        source "${script_file}"
        return $?
    fi
    return 1
}
