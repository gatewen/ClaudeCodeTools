#!/usr/bin/env bash
# impact-analysis-guard.sh — 因果鏈分析守衛 Hook
# 觸發：PreToolUse (Write | Edit | MultiEdit)
# 輸入：stdin JSON { tool_name: "...", tool_input: { file_path: "..." } }
# 輸出：
#   首次修改某檔案 → stdout 依賴清單 + exit 2 阻擋（強制 AI 先做因果鏈分析）
#   同檔案重試      → exit 0 放行
# 用途：修改檔案前自動掃描依賴，阻擋第一次修改嘗試，強制 AI 輸出因果鏈分析後重試。
#       不再是「提醒」，而是真正的門鎖——沒做分析就不讓改。

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

# 2. 檢查是否已分析過（block → 分析 → 重試 → 放行）
GUARD_DIR="/tmp/claude-causal-chain"
mkdir -p "$GUARD_DIR"

# 用檔案路徑產生 marker 名稱（把 / 換成 _）
MARKER_NAME=$(echo "$FILE_PATH" | tr '/' '_' | tr ' ' '_')

if [[ -f "$GUARD_DIR/$MARKER_NAME" ]]; then
  # 已分析過，放行
  ORANGE='\033[38;5;208m'
  RESET='\033[0m'
  echo -e "${ORANGE}🟠 因果鏈已分析，放行修改 ${FILENAME}${RESET}"
  exit 0
fi

# 3. 首次修改此檔案 → 建立 marker
touch "$GUARD_DIR/$MARKER_NAME"

# 4. 掃描引用此檔案的其他檔案
DEPENDENTS=""

if [[ -f "$FILE_PATH" ]]; then
  # 既有檔案：掃描引用者
  if command -v rg &>/dev/null; then
    DEPENDENTS=$(rg -l --no-messages "$FILENAME_NO_EXT" \
      --glob '!node_modules' --glob '!.git' --glob '!*.lock' \
      --glob '!target' --glob '!dist' --glob '!build' \
      --glob '!.claude-loop' --glob '!.claudedocs' \
      . 2>/dev/null | grep -v "$FILENAME" | head -10) || true
  elif command -v grep &>/dev/null; then
    DEPENDENTS=$(grep -rl "$FILENAME_NO_EXT" \
      --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
      --include='*.py' --include='*.rs' --include='*.go' --include='*.cs' \
      --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=target \
      --exclude-dir=dist --exclude-dir=build \
      . 2>/dev/null | grep -v "$FILENAME" | head -10) || true
  fi
fi

# 5. 輸出依賴資訊到 stdout（供 AI 參考）
ORANGE='\033[38;5;208m'
RESET='\033[0m'

echo -e "${ORANGE}🟠 ⛔ 修改被擋住：${FILENAME} — 請先完成因果鏈分析${RESET}"

if [[ ! -f "$FILE_PATH" ]]; then
  echo "📋 新建檔案 ${FILENAME}：確認此檔案在整體架構中的定位和依賴方向"
elif [[ -n "$DEPENDENTS" ]]; then
  echo "📋 ${FILENAME} 被以下檔案引用："
  echo "$DEPENDENTS" | while IFS= read -r dep; do
    echo "  → ${dep}"
  done
else
  echo "📋 ${FILENAME} 未找到直接引用者（仍需檢查語意影響和間接依賴）"
fi

echo ""
echo "請在畫面輸出因果鏈分析後，重試修改："
echo "  ①根因 ②直接影響 ③間接影響 ④隱性風險 ⑤決策"

# 6. 阻擋修改（exit 2 = block）
echo "⛔ 因果鏈分析未完成，修改被擋住。完成分析後重試即可通過。" >&2
exit 2
