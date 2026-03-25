#!/usr/bin/env bash
# impact-analysis-guard.sh — 因果鏈分析守衛 Hook
# 觸發：PreToolUse (Write | Edit | MultiEdit)
# 輸入：stdin JSON { tool_name: "...", tool_input: { file_path: "..." } }
# 輸出：stdout 提醒訊息（exit 0 放行 + 提醒）
# 用途：修改檔案前自動掃描依賴，提醒 AI 做因果鏈分析。
#       此 Hook 不阻擋操作，僅輸出提醒。AI 須回應提醒後才執行修改。

set -euo pipefail

# 1. 讀取 stdin JSON，提取 file_path
INPUT=$(cat)
FILE_PATH=""

if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi

if [[ -z "$FILE_PATH" ]]; then
  FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)
fi

# 無法取得 file_path → 靜默放行
[[ -z "$FILE_PATH" ]] && exit 0

FILENAME=$(basename "$FILE_PATH")
FILENAME_NO_EXT="${FILENAME%.*}"

# 2. 新檔案（不存在）→ 輕量提醒
if [[ ! -f "$FILE_PATH" ]]; then
  echo -e "\033[38;5;208m🟠 收到：即將新建 ${FILENAME}，先做因果鏈分析\033[0m"
  echo "⚠️ [因果鏈] 新建 ${FILENAME}：確認此檔案在整體架構中的定位和依賴方向"
  exit 0
fi

# 3. 掃描引用此檔案的其他檔案
DEPENDENTS=""

if command -v rg &>/dev/null; then
  # ripgrep（快，優先使用）
  DEPENDENTS=$(rg -l --no-messages "$FILENAME_NO_EXT" \
    --glob '!node_modules' --glob '!.git' --glob '!*.lock' \
    --glob '!target' --glob '!dist' --glob '!build' \
    --glob '!.claude-loop' --glob '!.claudedocs' \
    . 2>/dev/null | grep -v "$FILENAME" | head -10) || true
elif command -v grep &>/dev/null; then
  # grep fallback（較慢但普遍可用）
  DEPENDENTS=$(grep -rl "$FILENAME_NO_EXT" \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
    --include='*.py' --include='*.rs' --include='*.go' --include='*.cs' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=target \
    --exclude-dir=dist --exclude-dir=build \
    . 2>/dev/null | grep -v "$FILENAME" | head -10) || true
fi

# 4. 輸出因果鏈提醒（橙色前綴）
ORANGE='\033[38;5;208m'
RESET='\033[0m'

if [[ -n "$DEPENDENTS" ]]; then
  echo -e "${ORANGE}🟠 收到：即將修改 ${FILENAME}，先做因果鏈分析${RESET}"
  echo "⚠️ [因果鏈] ${FILENAME} 被以下檔案引用："
  echo "$DEPENDENTS" | while IFS= read -r dep; do
    echo "  → ${dep}"
  done
  echo "修改前確認：①根因 ②對以上檔案的影響 ③需連動更新的項目"
else
  echo -e "${ORANGE}🟠 收到：即將修改 ${FILENAME}，先做因果鏈分析${RESET}"
  echo "⚠️ [因果鏈] 修改 ${FILENAME}：確認 ①根因 ②下游影響 ③連動更新"
fi

exit 0
