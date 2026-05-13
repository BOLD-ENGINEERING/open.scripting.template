#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Bootstrap / App Initialization
# =============================================================================
# Loads the core engine, registers providers, and prepares the environment.
# =============================================================================

bold::import() {
    local path="$1"
    local full_path="${BOLD_ROOT}/${path}"
    if [[ ! -v _BOLD_LOADED["${full_path}"] ]]; then
        _BOLD_LOADED["${full_path}"]=1
        # shellcheck source=/dev/null
        source "${full_path}"
    fi
}

declare -gA _BOLD_LOADED=()

bold::import core/import.sh
bold::import core/output.sh
bold::import core/utils.sh
bold::import core/providers/provider.sh

if [[ -f "${BOLD_ROOT}/config/app.conf" ]]; then
    # shellcheck source=/dev/null
    source "${BOLD_ROOT}/config/app.conf"
fi

if [[ -f "${BOLD_ROOT}/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${BOLD_ROOT}/.env"
    set +a
elif [[ -f "${BOLD_ROOT}/config/.env.example" ]]; then
    :
fi

provider::register "proxmox" "core/providers/proxmox_provider.sh"

provider::register_all

bold::import core/metadata.sh
