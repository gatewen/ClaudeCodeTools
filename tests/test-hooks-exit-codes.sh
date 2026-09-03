#!/usr/bin/env bash
# test-hooks-exit-codes.sh
# 驗證核心 3 hook 對 stdin JSON 輸入的 exit code 行為契約：
#   - impact-analysis-guard.sh：只守既有原始碼檔；首次擋（exit 2）、重試放行；
#                               新檔 / 非原始碼副檔名 / 缺 file_path 靜默放行；marker 依 session 隔離
#   - causal-chain-reset.sh：永遠 exit 0；清除本 session marker 後同檔再次被擋
#   - incremental-lint.sh：缺輸入靜默放行、無 linter 路徑靜默放行
# 另驗 _helpers.sh json_field：jq 路徑與 sed 後援（CLOSED_LOOP_NO_JQ=1）對 Windows 反斜線路徑的還原。
#
# 範圍：核心 3 hook（其餘 2 個用 cross-file-consistency 驗陣列數量即可）

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

# 測試用既有檔案（guard 只守既有原始碼檔，所以必須真的存在）
SRC_FILE="${TEST_TMP}/sample.ts"
MD_FILE="${TEST_TMP}/sample.md"
echo "export const x = 1" > "$SRC_FILE"
echo "# test" > "$MD_FILE"

# ════════════════════════════════════════════
# _helpers.sh json_field（jq 路徑 + sed 後援）
# ════════════════════════════════════════════
echo "=== _helpers.sh json_field ==="
# shellcheck source=../dev-closed-loop/hooks/_helpers.sh
source "$HOOKS_DIR/_helpers.sh"

WIN_JSON='{"session_id":"w1","tool_input":{"file_path":"C:\\Users\\x\\y.ts"}}'
WIN_EXPECT='C:\Users\x\y.ts'
assert_eq "$(json_field "$WIN_JSON" '.tool_input.file_path')" "$WIN_EXPECT" \
    "預設路徑（有 jq 則走 jq）：Windows 反斜線路徑還原" || FAIL=$((FAIL+1))
assert_eq "$(CLOSED_LOOP_NO_JQ=1 json_field "$WIN_JSON" '.tool_input.file_path')" "$WIN_EXPECT" \
    "sed 後援：Windows 反斜線路徑還原" || FAIL=$((FAIL+1))
assert_eq "$(CLOSED_LOOP_NO_JQ=1 json_field '{"tool_input":{"file_path":"\/tmp\/a.ts"}}' '.tool_input.file_path')" "/tmp/a.ts" \
    "sed 後援：跳脫斜線還原為 /" || FAIL=$((FAIL+1))
assert_eq "$(CLOSED_LOOP_NO_JQ=1 json_field '{"tool_input":{}}' '.tool_input.file_path')" "" \
    "sed 後援：缺欄位回空字串" || FAIL=$((FAIL+1))
assert_eq "$(CLOSED_LOOP_NO_JQ=1 get_session_key '{"session_id":"abc-123","prompt":"x"}')" "abc-123" \
    "sed 後援：session key" || FAIL=$((FAIL+1))
assert_eq "$(CLOSED_LOOP_NO_JQ=1 get_session_key '{"prompt":"x"}')" "default" \
    "sed 後援：無 session_id → default" || FAIL=$((FAIL+1))

# ════════════════════════════════════════════
# impact-analysis-guard.sh
# ════════════════════════════════════════════
echo ""
echo "=== impact-analysis-guard.sh ==="

reset_markers
test_hook_exit "impact-analysis-guard.sh" "0" \
    '{"tool_input":{}}' \
    "缺 file_path → exit 0（靜默放行）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "impact-analysis-guard.sh" "0" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${TEST_TMP}/new-file-XYZ.ts\"}}" \
    "新建檔案（不存在）→ exit 0（無呼叫者可分析）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "impact-analysis-guard.sh" "0" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${MD_FILE}\"}}" \
    "既有 .md（非原始碼）→ exit 0（副檔名白名單外）" || FAIL=$((FAIL+1))

reset_markers
test_hook_exit "impact-analysis-guard.sh" "2" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "既有 .ts 首次修改 → exit 2（因果鏈閘門擋）" || FAIL=$((FAIL+1))

# 不 reset：marker 已被上一個 check 建立，重試應放行
test_hook_exit "impact-analysis-guard.sh" "0" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "重試同檔同 session → exit 0（marker 通過）" || FAIL=$((FAIL+1))

# 不 reset：另一個 session 對同檔應獨立被擋
test_hook_exit "impact-analysis-guard.sh" "2" \
    "{\"session_id\":\"sessB\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "同檔不同 session → exit 2（marker 依 session 隔離）" || FAIL=$((FAIL+1))

# sed 後援路徑（無 jq 環境）下同樣契約
reset_markers
CLOSED_LOOP_NO_JQ=1 test_hook_exit "impact-analysis-guard.sh" "2" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "sed 後援：既有 .ts 首次修改 → exit 2" || FAIL=$((FAIL+1))
CLOSED_LOOP_NO_JQ=1 test_hook_exit "impact-analysis-guard.sh" "0" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "sed 後援：重試 → exit 0" || FAIL=$((FAIL+1))

# ════════════════════════════════════════════
# causal-chain-reset.sh
# ════════════════════════════════════════════
echo ""
echo "=== causal-chain-reset.sh ==="

test_hook_exit "causal-chain-reset.sh" "0" \
    '{"prompt":"hello"}' \
    "缺 session_id → exit 0（永遠放行）" || FAIL=$((FAIL+1))

# sessA 的 marker 仍在（上面重試放行過）；reset sessA 後同檔應再次被擋
test_hook_exit "causal-chain-reset.sh" "0" \
    '{"session_id":"sessA","prompt":"下一個指令"}' \
    "reset sessA → exit 0" || FAIL=$((FAIL+1))

test_hook_exit "impact-analysis-guard.sh" "2" \
    "{\"session_id\":\"sessA\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "reset 後同檔同 session → exit 2（marker 已清除，重新分析）" || FAIL=$((FAIL+1))

# 建立 sessB marker 後確認 sessA reset 不波及 sessB
reset_markers
test_hook_exit "impact-analysis-guard.sh" "2" \
    "{\"session_id\":\"sessB\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "sessB 首次 → exit 2（建立 marker）" || FAIL=$((FAIL+1))
test_hook_exit "causal-chain-reset.sh" "0" \
    '{"session_id":"sessA","prompt":"x"}' \
    "reset sessA（sessB 不受影響）→ exit 0" || FAIL=$((FAIL+1))
test_hook_exit "impact-analysis-guard.sh" "0" \
    "{\"session_id\":\"sessB\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "reset sessA 後 sessB 同檔 → exit 0（marker 仍在）" || FAIL=$((FAIL+1))

# sed 後援路徵下 reset 同樣有效
CLOSED_LOOP_NO_JQ=1 test_hook_exit "causal-chain-reset.sh" "0" \
    '{"session_id":"sessB","prompt":"x"}' \
    "sed 後援：reset sessB → exit 0" || FAIL=$((FAIL+1))
test_hook_exit "impact-analysis-guard.sh" "2" \
    "{\"session_id\":\"sessB\",\"tool_input\":{\"file_path\":\"${SRC_FILE}\"}}" \
    "sed 後援 reset 後 sessB 同檔 → exit 2" || FAIL=$((FAIL+1))

# ════════════════════════════════════════════
# incremental-lint.sh
# ════════════════════════════════════════════
echo ""
echo "=== incremental-lint.sh ==="

test_hook_exit "incremental-lint.sh" "0" \
    '{"tool_input":{}}' \
    "缺 file_path → exit 0（靜默放行）" || FAIL=$((FAIL+1))

test_hook_exit "incremental-lint.sh" "0" \
    "{\"tool_input\":{\"file_path\":\"${TEST_TMP}/nonexistent-XYZ-file.ts\"}}" \
    "檔案不存在 → exit 0（靜默放行）" || FAIL=$((FAIL+1))

test_hook_exit "incremental-lint.sh" "0" \
    "{\"tool_input\":{\"file_path\":\"${MD_FILE}\"}}" \
    ".md 檔（無 per-file linter）→ exit 0" || FAIL=$((FAIL+1))

CLOSED_LOOP_NO_JQ=1 test_hook_exit "incremental-lint.sh" "0" \
    '{"tool_input":{}}' \
    "sed 後援：缺 file_path → exit 0" || FAIL=$((FAIL+1))

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
