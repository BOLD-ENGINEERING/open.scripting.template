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
        # shellcheck source=/dev/null
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
