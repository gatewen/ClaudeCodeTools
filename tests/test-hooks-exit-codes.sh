#!/usr/bin/env bash
# test-hooks-exit-codes.sh
# 驗證核心 3 hook 對 stdin JSON 輸入的 exit code 行為契約：
#   - impact-analysis-guard.sh：因果鏈閘門首次擋、重試放行
#   - delegation-gate.sh：唯讀放行、修改型擋、重試放行
#   - incremental-lint.sh：缺輸入靜默放行、無 linter 路徑靜默放行
#
# 範圍：核心 3 hook，不測 7 個 hook 全部（其餘 4 個用 cross-file-consistency 驗陣列數量即可）

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"
# shellcheck source=lib/fixtures.sh
source "$REPO_ROOT/tests/lib/fixtures.sh"

HOOKS_DIR="$REPO_ROOT/dev-closed-loop/hooks"
FAIL=0

# 隔離 TMPDIR 避免影響真實 marker
TEST_TMP=$(make_tmpdir)
export TMPDIR="$TEST_TMP"

reset_markers() {
    rm -rf "${TEST_TMP}/claude-code-tools" 2>/dev/null || true
}

# 包裝：跑 hook，比對 exit code，輸出 PASS/FAIL
test_hook_exit() {
    local hook="$1"
    local expected="$2"
    local input="$3"
    local msg="$4"
    local actual=0
    echo "$input" | bash "${HOOKS_DIR}/${hook}" > /dev/null 2>&1 || actual=$?
    if [ "$actual" = "$expected" ]; then
        echo "  ✅ ${msg} (exit=${actual})"
        return 0
    fi
    echo "  ❌ ${msg}: expected exit=${expected}, got ${actual}"
    return 1
}

# ════════════════════════════════════════════
# impact-analysis-guard.sh
# ════════════════════════════════════════════
echo "=== impact-analysis-guard.sh ==="

reset_markers
test_hook_exit "impact-analysis-guard.sh" "0" \
    '{"tool_input":{}}' \
    "缺 file_path → exit 0（靜默放行）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "impact-analysis-guard.sh" "2" \
    '{"tool_input":{"file_path":"/tmp/test-target-XYZ.ts"}}' \
    "首次修改某檔 → exit 2（因果鏈閘門擋）" || FAIL=$((FAIL+1))

# 不 reset：marker 已被上一個 check 建立，重試應放行
test_hook_exit "impact-analysis-guard.sh" "0" \
    '{"tool_input":{"file_path":"/tmp/test-target-XYZ.ts"}}' \
    "重試同檔 → exit 0（marker 通過）" || FAIL=$((FAIL+1))

# ════════════════════════════════════════════
# delegation-gate.sh
# ════════════════════════════════════════════
echo ""
echo "=== delegation-gate.sh ==="

reset_markers
test_hook_exit "delegation-gate.sh" "0" \
    '{"tool_input":{}}' \
    "缺 prompt → exit 0（靜默放行）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "delegation-gate.sh" "0" \
    '{"tool_input":{"prompt":"請執行設計審查","description":"review-1"}}' \
    "唯讀型（設計審查）→ exit 0（排除清單放行）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "delegation-gate.sh" "0" \
    '{"tool_input":{"prompt":"請分析架構結構","description":"analyze-1"}}' \
    "純研究（無修改詞）→ exit 0（無修改意圖放行）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "delegation-gate.sh" "2" \
    '{"tool_input":{"prompt":"請實作功能 X","description":"impl-feat-x"}}' \
    "修改型首次 → exit 2（委派閘門擋）" || FAIL=$((FAIL+1))

# 不 reset：同 description marker 已建立
test_hook_exit "delegation-gate.sh" "0" \
    '{"tool_input":{"prompt":"請實作功能 X","description":"impl-feat-x"}}' \
    "修改型重試（同 description）→ exit 0（marker 通過）" || FAIL=$((FAIL+1))

# ════════════════════════════════════════════
# incremental-lint.sh
# ════════════════════════════════════════════
echo ""
echo "=== incremental-lint.sh ==="

test_hook_exit "incremental-lint.sh" "0" \
    '{"tool_input":{}}' \
    "缺 file_path → exit 0（靜默放行）" || FAIL=$((FAIL+1))

test_hook_exit "incremental-lint.sh" "0" \
    '{"tool_input":{"file_path":"/tmp/nonexistent-XYZ-file.ts"}}' \
    "檔案不存在 → exit 0（靜默放行）" || FAIL=$((FAIL+1))

# 建立一個真實的 .md 檔（無 per-file linter case）
md_file="${TEST_TMP}/sample.md"
echo "# test" > "${md_file}"
test_hook_exit "incremental-lint.sh" "0" \
    "{\"tool_input\":{\"file_path\":\"${md_file}\"}}" \
    ".md 檔（無 per-file linter）→ exit 0" || FAIL=$((FAIL+1))

# ════════════════════════════════════════════
# Result
# ════════════════════════════════════════════
echo ""
if [ $FAIL -eq 0 ]; then
    echo "All hook exit-code checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
