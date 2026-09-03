#!/usr/bin/env bash
# test-deploy-hooks.sh
# 驗證 deploy-hooks.sh 的核心契約：
#   1. 3 個 hook + 1 個 _helpers.sh 複製到 .claude/hooks/
#   2. 所有 hook 可執行（chmod +x）
#   3. settings.json 含 3 個 hook keywords，且不含已移除的舊 hook
#   4. settings.json 是合法 JSON
#   5. **幂等**：跑 2 次後，每個 hook 在 settings.json 中只出現 1 次（不重複）
#   6. 舊版部署（delegation-gate / prompt-understanding-guard / delegation-tracker / learning-log-checker）
#      升級後被清除，其他設定保留

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"
# shellcheck source=lib/fixtures.sh
source "$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0

# JSON 工具：python3 優先，不可用（如 Windows 的 Store 空殼 python）時退 jq
json_valid() {
    python3 -c "import json; json.load(open('$1'))" 2>/dev/null && return 0
    jq empty "$1" 2>/dev/null
}
# 數 keyword 在 hooks.*[].hooks[].command 出現的次數（找不到工具時印 ?）
count_hook_cmd() {
    local n=""
    n=$(python3 -c "
import json
cfg = json.load(open('$1'))
print(sum(1 for entries in cfg.get('hooks', {}).values() for e in entries for h in e.get('hooks', []) if '$2' in h.get('command', '')))
" 2>/dev/null) || n=""
    if [ -z "$n" ]; then
        n=$(jq -r --arg k "$2" '[.hooks // {} | .[] | .[] | (.hooks // [])[] | (.command // "") | select(contains($k))] | length' "$1" 2>/dev/null) || n=""
    fi
    printf '%s' "${n:-?}"
}

# 隔離 project dir
PROJECT_DIR=$(make_tmpdir)

# deploy-hooks.sh 用 relative path（mkdir .claude/hooks），需 cd 進去
cd "$PROJECT_DIR" || exit 1

echo "Running deploy-hooks.sh (1st time) in $PROJECT_DIR..."
output1=$(bash "$REPO_ROOT/dev-closed-loop/deploy-hooks.sh" "$REPO_ROOT" 2>&1 || true)

# --------------------------------------------------
# Check 1: 4 個檔案複製
# --------------------------------------------------
echo ""
echo "Check 1: hooks 目錄含 4 個檔案（3 hooks + _helpers.sh）"
HOOK_NAMES=(
    impact-analysis-guard.sh
    causal-chain-reset.sh
    incremental-lint.sh
    _helpers.sh
)
missing=0
for h in "${HOOK_NAMES[@]}"; do
    if [ ! -f ".claude/hooks/$h" ]; then
        echo "  ❌ missing: .claude/hooks/$h"
        missing=$((missing+1))
    fi
done
assert_eq "$missing" "0" "全部 4 檔複製完成" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 2: hook 可執行
# --------------------------------------------------
echo ""
echo "Check 2: hooks 皆可執行"
non_exec=0
for h in "${HOOK_NAMES[@]}"; do
    if [ -f ".claude/hooks/$h" ] && [ ! -x ".claude/hooks/$h" ]; then
        echo "  ❌ not executable: .claude/hooks/$h"
        non_exec=$((non_exec+1))
    fi
done
assert_eq "$non_exec" "0" "全部 hook 有 +x 權限" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 3: settings.json 含 3 個 hook keywords，且不含已移除的舊 hook
# --------------------------------------------------
echo ""
echo "Check 3: settings.json 含全部 3 個 hook 配置"
SETTINGS=".claude/settings.json"
assert_file_exists "$SETTINGS" || FAIL=$((FAIL+1))
KEYWORDS=(
    impact-analysis-guard
    causal-chain-reset
    incremental-lint
)
LEGACY_KEYWORDS=(
    delegation-gate
    prompt-understanding-guard
    delegation-tracker
    learning-log-checker
)
keyword_missing=0
for k in "${KEYWORDS[@]}"; do
    if ! grep -q "$k" "$SETTINGS" 2>/dev/null; then
        echo "  ❌ settings.json 缺少 $k"
        keyword_missing=$((keyword_missing+1))
    fi
done
assert_eq "$keyword_missing" "0" "全部 3 hook keywords 在 settings.json" || FAIL=$((FAIL+1))
legacy_present=0
for k in "${LEGACY_KEYWORDS[@]}"; do
    if grep -q "$k" "$SETTINGS" 2>/dev/null; then
        echo "  ❌ settings.json 仍含已移除的 $k"
        legacy_present=$((legacy_present+1))
    fi
done
assert_eq "$legacy_present" "0" "已移除的 hook 不在 settings.json" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 4: settings.json 是合法 JSON
# --------------------------------------------------
echo ""
echo "Check 4: settings.json 是合法 JSON"
if json_valid "$SETTINGS"; then
    echo "  ✅ valid JSON"
else
    echo "  ❌ invalid JSON"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 5: 幂等——跑第 2 次後每個 hook 仍只出現 1 次
# --------------------------------------------------
echo ""
echo "Check 5: 幂等性（跑第 2 次後 hook 不重複）"
output2=$(bash "$REPO_ROOT/dev-closed-loop/deploy-hooks.sh" "$REPO_ROOT" 2>&1 || true)

# 數每個 hook 在 settings.json 出現次數（在 hooks.command 字串中；python3 或 jq）
duplicate_found=0
for k in "${KEYWORDS[@]}"; do
    count=$(count_hook_cmd "$SETTINGS" "$k")
    if [ "$count" != "1" ]; then
        echo "  ❌ $k 出現 $count 次（預期 1）"
        duplicate_found=$((duplicate_found+1))
    fi
done
assert_eq "$duplicate_found" "0" "全部 hook 各出現 1 次（無重複）" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 6: 舊版部署升級——settings.json 含 delegation-gate / prompt-understanding-guard
#          與舊 hook 檔，跑 deploy 後應被清除；非 hook 設定（permissions）保留
# --------------------------------------------------
echo ""
echo "Check 6: 舊版 hook 配置遷移清除"
LEGACY_DIR=$(make_tmpdir)
mkdir -p "$LEGACY_DIR/.claude/hooks"
touch "$LEGACY_DIR/.claude/hooks/delegation-gate.sh" "$LEGACY_DIR/.claude/hooks/prompt-understanding-guard.sh"
cat > "$LEGACY_DIR/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Write|Edit|MultiEdit", "hooks": [{"type": "command", "command": "bash .claude/hooks/impact-analysis-guard.sh"}]},
      {"matcher": "Agent", "hooks": [{"type": "command", "command": "bash .claude/hooks/delegation-gate.sh"}]}
    ],
    "PostToolUse": [
      {"matcher": "Agent", "hooks": [{"type": "command", "command": "bash .claude/hooks/delegation-tracker.sh"}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash .claude/hooks/learning-log-checker.sh"}]}
    ],
    "UserPromptSubmit": [
      {"hooks": [{"type": "command", "command": "bash .claude/hooks/prompt-understanding-guard.sh"}]}
    ]
  },
  "permissions": {"allow": ["Bash(ls:*)"]}
}
JSON
( cd "$LEGACY_DIR" && bash "$REPO_ROOT/dev-closed-loop/deploy-hooks.sh" "$REPO_ROOT" >/dev/null 2>&1 ) || true
LEGACY_SETTINGS="$LEGACY_DIR/.claude/settings.json"
legacy_left=0
for k in "${LEGACY_KEYWORDS[@]}"; do
    if grep -q "$k" "$LEGACY_SETTINGS" 2>/dev/null; then
        echo "  ❌ 升級後 settings.json 仍含 $k"
        legacy_left=$((legacy_left+1))
    fi
done
assert_eq "$legacy_left" "0" "舊版 hook 配置已從 settings.json 清除" || FAIL=$((FAIL+1))
legacy_files=0
for f in "${LEGACY_KEYWORDS[@]}"; do
    [ -f "$LEGACY_DIR/.claude/hooks/$f.sh" ] && legacy_files=$((legacy_files+1))
done
assert_eq "$legacy_files" "0" "舊版 hook 腳本檔已移除" || FAIL=$((FAIL+1))
if grep -q '"permissions"' "$LEGACY_SETTINGS" 2>/dev/null; then
    echo "  ✅ 非 hook 設定（permissions）保留"
else
    echo "  ❌ 非 hook 設定（permissions）遺失"
    FAIL=$((FAIL+1))
fi
assert_eq "$(count_hook_cmd "$LEGACY_SETTINGS" impact-analysis-guard)" "1" "既有 impact-analysis-guard 不重複" || FAIL=$((FAIL+1))
assert_eq "$(count_hook_cmd "$LEGACY_SETTINGS" causal-chain-reset)" "1" "新 hook causal-chain-reset 已加入" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Diagnostic
# --------------------------------------------------
if [ $FAIL -gt 0 ]; then
    echo ""
    echo "--- 1st run output ---"
    echo "$output1" | head -10
    echo "--- 2nd run output ---"
    echo "$output2" | head -10
    echo "--- settings.json ---"
    head -30 "$SETTINGS" 2>/dev/null
    echo "--- end ---"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "All deploy-hooks checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
