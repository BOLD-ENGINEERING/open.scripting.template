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

bold::info() {
    bold::color "${BOLD_C_CYAN}" "[INFO] $*"
}

bold::success() {
    bold::color "${BOLD_C_GREEN}" "[SUCCESS] $*"
}

bold::warn() {
    bold::color "${BOLD_C_YELLOW}" "[WARN] $*"
}

bold::error() {
    bold::color "${BOLD_C_RED}" "[ERROR] $*" >&2
}

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
