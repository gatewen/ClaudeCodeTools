#!/usr/bin/env bash
# test-deploy-hooks.sh
# 驗證 deploy-hooks.sh 的核心契約：
#   1. 6 個 hook + 1 個 _helpers.sh 複製到 .claude/hooks/
#   2. 所有 hook 可執行（chmod +x）
#   3. settings.json 含 6 個 hook keywords
#   4. settings.json 是合法 JSON
#   5. **幂等**：跑 2 次後，每個 hook 在 settings.json 中只出現 1 次（不重複）

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"
# shellcheck source=lib/fixtures.sh
source "$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0

# 隔離 project dir
PROJECT_DIR=$(make_tmpdir)

# deploy-hooks.sh 用 relative path（mkdir .claude/hooks），需 cd 進去
cd "$PROJECT_DIR" || exit 1

echo "Running deploy-hooks.sh (1st time) in $PROJECT_DIR..."
output1=$(bash "$REPO_ROOT/dev-closed-loop/deploy-hooks.sh" "$REPO_ROOT" 2>&1 || true)

# --------------------------------------------------
# Check 1: 7 個檔案複製
# --------------------------------------------------
echo ""
echo "Check 1: hooks 目錄含 7 個檔案（6 hooks + _helpers.sh）"
HOOK_NAMES=(
    impact-analysis-guard.sh
    incremental-lint.sh
    delegation-tracker.sh
    delegation-gate.sh
    prompt-understanding-guard.sh
    learning-log-checker.sh
    _helpers.sh
)
missing=0
for h in "${HOOK_NAMES[@]}"; do
    if [ ! -f ".claude/hooks/$h" ]; then
        echo "  ❌ missing: .claude/hooks/$h"
        missing=$((missing+1))
    fi
done
assert_eq "$missing" "0" "全部 7 檔複製完成" || FAIL=$((FAIL+1))

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
# Check 3: settings.json 含 6 個 hook keywords
# --------------------------------------------------
echo ""
echo "Check 3: settings.json 含全部 6 個 hook 配置"
SETTINGS=".claude/settings.json"
assert_file_exists "$SETTINGS" || FAIL=$((FAIL+1))
KEYWORDS=(
    impact-analysis-guard
    delegation-gate
    incremental-lint
    delegation-tracker
    prompt-understanding-guard
    learning-log-checker
)
keyword_missing=0
for k in "${KEYWORDS[@]}"; do
    if ! grep -q "$k" "$SETTINGS" 2>/dev/null; then
        echo "  ❌ settings.json 缺少 $k"
        keyword_missing=$((keyword_missing+1))
    fi
done
assert_eq "$keyword_missing" "0" "全部 6 hook keywords 在 settings.json" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 4: settings.json 是合法 JSON
# --------------------------------------------------
echo ""
echo "Check 4: settings.json 是合法 JSON"
if python3 -c "import json,sys; json.load(open('$SETTINGS'))" 2>/dev/null; then
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

# 用 python 數每個 hook 在 settings.json 出現次數（在 hooks.command 字串中）
duplicate_found=0
for k in "${KEYWORDS[@]}"; do
    count=$(python3 -c "
import json
cfg = json.load(open('$SETTINGS'))
n = 0
for event_type, entries in cfg.get('hooks', {}).items():
    for entry in entries:
        for h in entry.get('hooks', []):
            if '$k' in h.get('command', ''):
                n += 1
print(n)
" 2>/dev/null)
    if [ "$count" != "1" ]; then
        echo "  ❌ $k 出現 $count 次（預期 1）"
        duplicate_found=$((duplicate_found+1))
    fi
done
assert_eq "$duplicate_found" "0" "全部 hook 各出現 1 次（無重複）" || FAIL=$((FAIL+1))

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
