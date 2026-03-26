#!/usr/bin/env bash
# prompt-understanding-guard.sh — 理解確認守衛 Hook
# 觸發：UserPromptSubmit
# 輸入：stdin JSON { prompt: "..." }
# 輸出：stdout 橙色提醒（exit 0 放行 + 提醒）
# 用途：用戶提交指令時，提醒 AI 先確認理解再動手。防止不對頻就直接修改。
# 注意：此 Hook 為提醒機制，非阻擋機制。AI 遵循度靠 CLAUDE.md 規則約束。

set -euo pipefail

# 1. 讀取 stdin JSON，提取 prompt
INPUT=$(cat)
PROMPT=""

if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null | head -c 500)
fi

if [[ -z "$PROMPT" ]]; then
  PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', '')[:500])
except:
    print('')
" 2>/dev/null)
fi

# 無法取得 prompt → 靜默放行
[[ -z "$PROMPT" ]] && exit 0

# 2. 判斷是否為需要理解確認的指令（含修改/實作/修正意圖）
# 純問答/討論類不觸發（以 ? 結尾、或以「什麼」「為什麼」「怎麼」「是不是」開頭的短句）
IS_QUESTION=false

# 偵測問句模式
if echo "$PROMPT" | grep -qE '\?$|？$'; then
  IS_QUESTION=true
fi
if echo "$PROMPT" | grep -qE '^(什麼|為什麼|怎麼|是不是|有沒有|可以嗎|能不能|how|what|why|is |are |can |does )' -i; then
  IS_QUESTION=true
fi

# 偵測修改意圖關鍵字（覆蓋問句判定）
HAS_ACTION=false
if echo "$PROMPT" | grep -qE '修改|改|加入|新增|刪除|移除|修正|修復|實作|建立|建置|部署|更新|替換|重構|優化|fix|add|remove|delete|create|implement|build|deploy|update|replace|refactor'; then
  HAS_ACTION=true
fi

# 純問答 且 無修改意圖 → 不觸發
if $IS_QUESTION && ! $HAS_ACTION; then
  exit 0
fi

# 無修改意圖的短句（< 20 字）→ 不觸發
PROMPT_LEN=${#PROMPT}
if ! $HAS_ACTION && [[ $PROMPT_LEN -lt 20 ]]; then
  exit 0
fi

# 3. 輸出橙色理解確認提醒（加強語氣版）
ORANGE='\033[38;5;208m'
RESET='\033[0m'

echo -e "${ORANGE}🟠 ⚠️ 理解確認守衛：用戶提交了新指令${RESET}"
echo -e "${ORANGE}   ┌──────────────────────────────────────────┐${RESET}"
echo -e "${ORANGE}   │ 執行任何修改前，必須先輸出理解確認：     │${RESET}"
echo -e "${ORANGE}   │   🟠 收到：[一句話摘要用戶的意圖]       │${RESET}"
echo -e "${ORANGE}   │   🟠 打算：[一句話說明要做什麼]         │${RESET}"
echo -e "${ORANGE}   │ 用戶沒有否定後，才開始執行。             │${RESET}"
echo -e "${ORANGE}   │ ⛔ 跳過此步驟直接修改 = 違反閉環規則    │${RESET}"
echo -e "${ORANGE}   └──────────────────────────────────────────┘${RESET}"

exit 0
