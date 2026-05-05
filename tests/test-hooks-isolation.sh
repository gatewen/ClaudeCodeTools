#!/usr/bin/env bash
# test-hooks-isolation.sh
# 階段 2-1 回歸防線：驗證 hook marker 為 project-scoped，跨專案不污染
#
# 測試 _helpers.sh 的契約：
#   - get_project_key 對不同 project 路徑產生不同 key
#   - get_gate_base 路徑包含 claude-code-tools namespace
#   - 兩個假專案的 marker 在 filesystem 層真的隔離

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"
# shellcheck source=lib/fixtures.sh
source "$REPO_ROOT/tests/lib/fixtures.sh"
# shellcheck source=../dev-closed-loop/hooks/_helpers.sh
source "$REPO_ROOT/dev-closed-loop/hooks/_helpers.sh"

FAIL=0

# 用隔離 TMPDIR 避免影響真實 marker
TEST_TMP=$(make_tmpdir)
export TMPDIR="$TEST_TMP"

# 兩個假專案
PROJ_A="$TEST_TMP/proj-a"
PROJ_B="$TEST_TMP/proj-b"
mkdir -p "$PROJ_A" "$PROJ_B"

# --------------------------------------------------
# Check 1: 不同 project path → 不同 project key
# --------------------------------------------------
echo "Check 1: 不同 project path 產生不同 key"
key_a=$( CLAUDE_PROJECT_DIR="$PROJ_A" get_project_key )
key_b=$( CLAUDE_PROJECT_DIR="$PROJ_B" get_project_key )
assert_neq "$key_a" "$key_b" "proj-a key != proj-b key" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 2: 不同 project → 不同 gate base
# --------------------------------------------------
echo ""
echo "Check 2: 不同 project 的 gate base 路徑不同"
base_a=$( CLAUDE_PROJECT_DIR="$PROJ_A" get_gate_base )
base_b=$( CLAUDE_PROJECT_DIR="$PROJ_B" get_gate_base )
assert_neq "$base_a" "$base_b" "proj-a base != proj-b base" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 3: gate base 包含 claude-code-tools namespace
# --------------------------------------------------
echo ""
echo "Check 3: gate base 含 claude-code-tools namespace（防回歸到無 namespace 寫死路徑）"
assert_contains "$base_a" "claude-code-tools" "proj-a base 含 namespace" || FAIL=$((FAIL+1))
assert_contains "$base_b" "claude-code-tools" "proj-b base 含 namespace" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 4: filesystem 層真的隔離（end-to-end）
# --------------------------------------------------
echo ""
echo "Check 4: filesystem 隔離（proj-a 寫 marker，proj-b 看不到）"
mkdir -p "$base_a" "$base_b"
touch "$base_a/marker-a"
if [ -f "$base_b/marker-a" ]; then
    echo "  ❌ proj-b 看到 proj-a 的 marker — 跨專案污染！"
    FAIL=$((FAIL+1))
else
    echo "  ✅ proj-b 看不到 proj-a 的 marker"
fi

# --------------------------------------------------
# Check 5: PWD fallback（CLAUDE_PROJECT_DIR 未設時）
# --------------------------------------------------
echo ""
echo "Check 5: CLAUDE_PROJECT_DIR 未設時使用 PWD fallback"
key_pwd=$( unset CLAUDE_PROJECT_DIR; cd "$PROJ_A" && get_project_key )
if [ -n "$key_pwd" ]; then
    echo "  ✅ PWD fallback 產出 key：$key_pwd"
else
    echo "  ❌ PWD fallback 回傳空字串"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Result
# --------------------------------------------------
echo ""
if [ $FAIL -eq 0 ]; then
    echo "All isolation checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
