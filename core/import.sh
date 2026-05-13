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

if [[ "$(declare -p _BOLD_LOADED 2>/dev/null)" != "declare -gA"* ]]; then
    :
fi
