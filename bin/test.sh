#!/usr/bin/env bash
# =============================================================================
# BOLD ENGINEERING - Test Runner
# =============================================================================
# Usage: bold test [filter]       (via framework)
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

    # shellcheck source=/dev/null
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
            failed=$((failed + 1))
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
    bold::line
    bold::info "Running test suites${filter:+ (filter: ${filter})}..."
    runner::run_all "${filter}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
