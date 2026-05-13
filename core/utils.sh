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
