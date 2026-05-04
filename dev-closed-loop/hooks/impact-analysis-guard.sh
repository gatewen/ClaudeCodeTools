#!/usr/bin/env bash
# impact-analysis-guard.sh — 修改前統一守衛 Hook
# 觸發：PreToolUse (Write | Edit | MultiEdit)
# 輸入：stdin JSON { tool_name: "...", tool_input: { file_path: "..." } }
# 職責：兩道阻擋式閘門，合併為單次 block
#   閘門 A — 理解確認：偵測 UserPromptSubmit 設的旗標，確保 AI 先對頻
#   閘門 B — 因果鏈分析：首次修改某檔案時強制做影響分析
#   兩道閘門同時觸發時合併為一次阻擋，避免重複 block。

set -euo pipefail

# Source shared helpers (provides get_gate_base for project-scoped markers)
# shellcheck source=_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

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

ORANGE='\033[38;5;208m'
RESET='\033[0m'

# ═══════════════════════════════════════════
# 閘門 A：理解確認（檢查 UserPromptSubmit 旗標）
# ═══════════════════════════════════════════
UNDERSTANDING_GATE="$(get_gate_base)/understanding-gate/pending"
NEED_UNDERSTANDING=false

if [[ -f "$UNDERSTANDING_GATE" ]]; then
  NEED_UNDERSTANDING=true
  # 清除旗標（本次 block 後不再重複要求）
  rm -f "$UNDERSTANDING_GATE"
fi

# ═══════════════════════════════════════════
# 閘門 B：因果鏈分析（首次修改檔案檢查）
# ═══════════════════════════════════════════
GUARD_DIR="$(get_gate_base)/causal-chain"
mkdir -p "$GUARD_DIR"

MARKER_NAME=$(echo "$FILE_PATH" | tr '/' '_' | tr ' ' '_')
NEED_CAUSAL=false

if [[ ! -f "$GUARD_DIR/$MARKER_NAME" ]]; then
  NEED_CAUSAL=true
  # 建立 marker（重試時放行）
  touch "$GUARD_DIR/$MARKER_NAME"
fi

# ═══════════════════════════════════════════
# 判定：兩道閘門都通過 → 放行
# ═══════════════════════════════════════════
if ! $NEED_UNDERSTANDING && ! $NEED_CAUSAL; then
  echo -e "${ORANGE}🟠 閘門已通過，放行修改 ${FILENAME}${RESET}"
  exit 0
fi

# ═══════════════════════════════════════════
# 至少一道閘門未通過 → 阻擋 + 合併訊息
# ═══════════════════════════════════════════
echo -e "${ORANGE}🟠 ⛔ 修改被擋住：${FILENAME}${RESET}"
echo ""

# 閘門 A 訊息
if $NEED_UNDERSTANDING; then
  echo "┌─ 閘門 A：理解確認 ─────────────────────┐"
  echo "│ 請先在畫面輸出：                         │"
  echo "│   🟠 收到：[一句話摘要用戶的意圖]       │"
  echo "│   🟠 打算：[一句話說明要做什麼]         │"
  echo "└──────────────────────────────────────────┘"
  echo ""
fi

# 閘門 B 訊息
if $NEED_CAUSAL; then
  echo "┌─ 閘門 B：因果鏈分析 ───────────────────┐"

  # 掃描引用此檔案的其他檔案
  DEPENDENTS=""
  if [[ -f "$FILE_PATH" ]]; then
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

  if [[ ! -f "$FILE_PATH" ]]; then
    echo "│ 新建檔案：確認架構定位和依賴方向       │"
  elif [[ -n "$DEPENDENTS" ]]; then
    echo "│ ${FILENAME} 被以下檔案引用："
    echo "$DEPENDENTS" | while IFS= read -r dep; do
      echo "│   → ${dep}"
    done
  else
    echo "│ 未找到直接引用者（仍需檢查語意影響）   │"
  fi

  echo "│ 請輸出因果鏈分析：                       │"
  echo "│   ①根因 ②直接影響 ③間接影響            │"
  echo "│   ④隱性風險 ⑤決策                       │"
  echo "└──────────────────────────────────────────┘"
fi

echo ""
echo "完成以上分析後，重試修改即可通過。"

# 阻擋（exit 2 = block）
if $NEED_UNDERSTANDING && $NEED_CAUSAL; then
  echo "⛔ 理解確認 + 因果鏈分析未完成，修改被擋住。" >&2
elif $NEED_UNDERSTANDING; then
  echo "⛔ 理解確認未完成，修改被擋住。" >&2
else
  echo "⛔ 因果鏈分析未完成，修改被擋住。" >&2
fi
exit 2
