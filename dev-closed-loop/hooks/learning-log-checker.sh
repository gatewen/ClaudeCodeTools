#!/usr/bin/env bash
# learning-log-checker.sh — 學習日誌提醒 Hook
# 觸發：PostToolUse (Bash)
# 輸入：stdin JSON { tool_input: { command: "..." }, stdout: "...", stderr: "..." }
# 輸出：exit 0（永遠放行，僅提醒）
# 用途：偵測 git commit 成功 + .claude-loop/ 存在 → 檢查 learning-log 是否在 commit 中。
#       如果 commit 沒包含 learning-log 變更，輸出提醒。

set -euo pipefail

# 只在閉環專案中生效
[[ ! -d ".claude-loop" ]] && exit 0

# 1. 讀取 stdin JSON，提取 command 和 stdout
INPUT=$(cat)
COMMAND=""
STDOUT=""

if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null | head -c 500)
  STDOUT=$(echo "$INPUT" | jq -r '.stdout // empty' 2>/dev/null | head -c 500)
fi

if [[ -z "$COMMAND" ]]; then
  COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', '')[:500])
except:
    print('')
" 2>/dev/null)
  STDOUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('stdout', '')[:500])
except:
    print('')
" 2>/dev/null)
fi

# 2. 判斷是否為 git commit 指令
if ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# 3. 判斷 commit 是否成功（stdout 含 [branch hash] 格式）
if ! echo "$STDOUT" | grep -qE '^\[.+\]'; then
  exit 0
fi

# 4. 檢查 learning-log.md 是否在最近的 commit 中
ORANGE='\033[38;5;208m'
RESET='\033[0m'

if git diff HEAD~1 --name-only 2>/dev/null | grep -q "learning-log"; then
  # learning-log 有更新，不需提醒
  exit 0
fi

# 5. learning-log 不在 commit 中 → 提醒
echo ""
echo -e "${ORANGE}🟠 ⚠️ 閉環 commit 完成，但 learning-log.md 未包含在內。${RESET}"
echo -e "${ORANGE}   如果本次閉環有斷點觸發或教訓，請補追加到 .claude-loop/learning-log.md 後再 commit --amend。${RESET}"
echo -e "${ORANGE}   如果一次通過無事件，請追加統計行後 commit --amend。${RESET}"

exit 0
