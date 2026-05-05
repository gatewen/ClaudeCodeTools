#!/usr/bin/env bash
# tests/run.sh — Local test runner for AI-ClaudeCode
# Usage: bash tests/run.sh
#
# Phase A: shellcheck on all .sh (skipped if not installed)
# Phase B: smoke tests (test-*.sh in this directory)
# Exit 0 = all pass; exit 1 = any test failed

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$REPO_ROOT/tests"

# --------------------------------------------------
# Phase A: shellcheck
# --------------------------------------------------
echo "================================================"
echo "  Phase A: shellcheck"
echo "================================================"
if command -v shellcheck >/dev/null 2>&1; then
    SHELLCHECK_TARGETS=(
        "$REPO_ROOT/setup.sh"
        "$REPO_ROOT/dev-closed-loop/deploy-hooks.sh"
        "$REPO_ROOT/dev-closed-loop/check-version.sh"
    )
    while IFS= read -r f; do SHELLCHECK_TARGETS+=("$f"); done < <(find "$REPO_ROOT/dev-closed-loop/hooks" -name '*.sh' -type f)
    while IFS= read -r f; do SHELLCHECK_TARGETS+=("$f"); done < <(find "$TESTS_DIR" -name '*.sh' -type f)

    # SC1091: 動態 source path（如 $REPO_ROOT）shellcheck 無法 follow，只是 info 級別
    if shellcheck --exclude=SC1091 "${SHELLCHECK_TARGETS[@]}"; then
        echo "✅ shellcheck PASS (${#SHELLCHECK_TARGETS[@]} files)"
    else
        echo ""
        echo "❌ shellcheck FAIL — aborting smoke tests"
        exit 1
    fi
else
    echo "⚠️  shellcheck 未安裝 — 略過（建議：brew install shellcheck）"
fi

# --------------------------------------------------
# Phase B: smoke tests
# --------------------------------------------------
echo ""
echo "================================================"
echo "  Phase B: smoke tests"
echo "================================================"

# Discover tests dynamically (sort for deterministic order)
TESTS=()
while IFS= read -r f; do
    TESTS+=("$(basename "$f")")
done < <(find "$TESTS_DIR" -maxdepth 1 -name 'test-*.sh' -type f | sort)

if [ ${#TESTS[@]} -eq 0 ]; then
    echo "⚠️  no test-*.sh found in $TESTS_DIR"
    exit 1
fi

PASS=0
FAIL=0
FAILED_TESTS=()

for test in "${TESTS[@]}"; do
    echo ""
    echo "--- $test ---"
    if bash "$TESTS_DIR/$test"; then
        PASS=$((PASS + 1))
        echo "✅ $test"
    else
        FAIL=$((FAIL + 1))
        FAILED_TESTS+=("$test")
        echo "❌ $test"
    fi
done

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo ""
echo "================================================"
TOTAL=$((PASS + FAIL))
if [ $FAIL -eq 0 ]; then
    echo "  ✅ ${PASS}/${TOTAL} smoke tests PASS"
    echo "================================================"
    exit 0
fi
echo "  ❌ ${PASS}/${TOTAL} PASS, ${FAIL} FAIL: ${FAILED_TESTS[*]}"
echo "================================================"
exit 1
