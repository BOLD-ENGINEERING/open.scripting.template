#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Provider / Proxmox VE
# =============================================================================
# @meta-desc  Proxmox VE management utilities
# @meta-provider proxmox
# =============================================================================

# Usage: bold proxmox:list-vms
provider::proxmox::init() {
    bold::debug "[proxmox] Checking availability..."
    if ! sys::command_exists qm && ! sys::command_exists pvesh; then
        bold::warn "[proxmox] Neither qm nor pvesh found — Proxmox tools unavailable"
        return 1
    fi
    bold::info "[proxmox] Proxmox environment detected"
    return 0
}

# Usage: bold proxmox:list-vms
provider::proxmox::list_vms() {
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would list Proxmox VMs"
        return 0
    fi
    if ! sys::command_exists qm; then
        bold::error "[proxmox] qm not found. Is this a Proxmox host?"
        return 1
    fi
    qm list
}

# Usage: bold proxmox:list-containers
provider::proxmox::list_containers() {
    if bold::is_dry_run; then
        bold::warn "[DRY-RUN] Would list Proxmox containers"
        return 0
    fi
    if ! sys::command_exists pct; then
        bold::error "[proxmox] pct not found. Is this a Proxmox host?"
        return 1
    fi
    pct list
}

# Usage: bold proxmox:status
provider::proxmox::status() {
    bold::title "Proxmox Provider Status"
    local tool status
    for tool in qm pvesh pct; do
        if sys::command_exists "${tool}"; then
            status="$(bold::color "${BOLD_C_GREEN}" available)"
        else
            status="$(bold::color "${BOLD_C_RED}" unavailable)"
        fi
        bold::info "$(printf '%-8s %s' "${tool}:" "${status}")"
    done
}
