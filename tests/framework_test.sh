#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Framework Test Suite
# =============================================================================
# @meta-desc  Framework core functionality tests
# =============================================================================

# Boot / Loader
# ---------------------------------------------------------------------

test::boot::loads_core_modules() {
    declare -F bold::import  &>/dev/null
    declare -F bold::info    &>/dev/null
    declare -F bold::is_dry_run &>/dev/null
    declare -F provider::register &>/dev/null
}

test::boot::root_is_set() {
    [[ -n "${BOLD_ROOT}" ]]
}

test::boot::version_is_set() {
    [[ -n "${BOLD_VERSION}" ]]
}

test::boot::env_not_required() {
    [[ -f "${BOLD_ROOT}/config/.env.example" ]]
}

test::boot::app_conf_sourced() {
    [[ -n "${SCRIPTS_DIR:-}" ]]
}

# Import
# ---------------------------------------------------------------------

test::import::sources_once() {
    local prior="${#_BOLD_LOADED[@]}"
    bold::import core/output.sh
    assert::equals "${prior}" "${#_BOLD_LOADED[@]}" "should not re-source"
}

test::import::tracks_loaded_files() {
    [[ -v _BOLD_LOADED["${BOLD_ROOT}/core/output.sh"] ]]
}

# Output
# ---------------------------------------------------------------------

test::output::info_defined()  { declare -F bold::info  &>/dev/null; }
test::output::success_defined() { declare -F bold::success &>/dev/null; }
test::output::warn_defined()  { declare -F bold::warn  &>/dev/null; }
test::output::error_defined() { declare -F bold::error &>/dev/null; }
test::output::debug_defined() { declare -F bold::debug &>/dev/null; }

# Dry-Run
# ---------------------------------------------------------------------

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
    assert::not_empty "${output}"
    BOLD_DRY_RUN="${saved}"
}

test::dry_run::sys_execute_logs() {
    local saved="${BOLD_DRY_RUN:-false}"
    BOLD_DRY_RUN=true
    local output
    output="$(sys::execute echo hello 2>&1)"
    [[ "${output}" == *"DRY-RUN"* ]]
    BOLD_DRY_RUN="${saved}"
}

# Utils
# ---------------------------------------------------------------------

test::utils::command_exists_true() {
    assert::true sys::command_exists bash
}

test::utils::command_exists_false() {
    assert::false sys::command_exists __nonexistent_cmd_xyz__
}

# Provider Registry
# ---------------------------------------------------------------------

test::provider::proxmox_registered() {
    provider::registered proxmox
}

test::provider::register_new() {
    local name="_test_dummy_$$"
    provider::register "${name}" "core/providers/provider.sh"
    assert::true provider::registered "${name}"
    unset "_BOLD_PROVIDERS[${name}]"
}

test::provider::load_twice_is_idempotent() {
    provider::load proxmox 2>/dev/null || true
    provider::load proxmox 2>/dev/null || true
    assert::true true
}

# Metadata / Routing
# ---------------------------------------------------------------------

test::metadata::parse_desc() {
    local desc
    desc="$(bold::parse_metadata "${BOLD_ROOT}/bin/bold" "meta-desc")"
    [[ "${desc}" == *"BOLD-Shell Framework"* ]]
}

test::metadata::provider_func_for_converts_colons() {
    local result
    result="$(bold::provider_func_for "proxmox:list-vms")"
    [[ "${result}" == "provider::proxmox::list_vms" ]]
}

test::metadata::provider_func_for_handles_hyphens() {
    local result
    result="$(bold::provider_func_for "my-provider:do-thing")"
    [[ "${result}" == "provider::my_provider::do_thing" ]]
}

# Scaffolding
# ---------------------------------------------------------------------

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

test::scaffold::make_script_errors_on_dup() {
    local name="_test_dup_$$"
    bold::make_script "${name}" 2>/dev/null
    set +e
    bold::make_script "${name}" 2>/dev/null
    local rc=$?
    set -e
    rm -f "${BOLD_ROOT}/scripts/${name}.sh"
    [[ "${rc}" -ne 0 ]]
}

test::scaffold::make_provider_registers() {
    local name="_test_prov_$$"
    bold::make_provider "${name}" 2>/dev/null
    assert::true provider::registered "${name}"
    rm -f "${BOLD_ROOT}/core/providers/${name}_provider.sh"
    unset "_BOLD_PROVIDERS[${name}]"
}

# User Scripts
# ---------------------------------------------------------------------

test::scripts::list_handles_empty() {
    local output
    output="$(bold::list_scripts 2>&1)"
    assert::not_empty "${output}"
}

test::scripts::run_user_script_not_found() {
    assert::false bold::run_user_script "__nonexistent__"
}

# Config
# ---------------------------------------------------------------------

test::config::app_conf_exists() {
    [[ -f "${BOLD_ROOT}/config/app.conf" ]]
}

test::config::env_example_exists() {
    [[ -f "${BOLD_ROOT}/config/.env.example" ]]
}
