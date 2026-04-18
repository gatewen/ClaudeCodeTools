#!/usr/bin/env bash
# delegation-gate.sh — 委派前因果鏈閘門 Hook
# 觸發：PreToolUse (Agent)
# 輸入：stdin JSON { tool_input: { prompt: "...", description: "..." } }
# 輸出：exit 0 = 放行 | exit 2 = 阻擋（要求委派前因果鏈分析）
# 用途：修改型 subagent 委派前，強制主 agent 輸出預期修改檔案和影響分析。
#       唯讀型委派（設計審查、品質檢核、追溯）自動放行。
#       與 impact-analysis-guard.sh 使用相同的「攔截→分析→重試放行」模式。

set -euo pipefail

# 1. 讀取 stdin JSON，提取 prompt 和 description
INPUT=$(cat)
PROMPT=""
DESCRIPTION=""

if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null | head -c 500)
  DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // empty' 2>/dev/null | head -c 100)
fi

if [[ -z "$PROMPT" ]]; then
  PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    print(ti.get('prompt', '')[:500])
except:
    print('')
" 2>/dev/null)
fi

if [[ -z "$DESCRIPTION" ]]; then
  DESCRIPTION=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    print(ti.get('description', '')[:100])
except:
    print('')
" 2>/dev/null)
fi

# 無法取得 prompt → 靜默放行
[[ -z "$PROMPT" ]] && exit 0

ORANGE='\033[38;5;208m'
RESET='\033[0m'

# ═══════════════════════════════════════════
# 2. 排除唯讀型委派（優先判定，直接放行）
# ═══════════════════════════════════════════
if echo "$PROMPT" | grep -qiE '設計審查|品質檢核|安全檢核|追溯檢查|design.review|quality.review|security.review|traceability|獨立設計審查者|獨立品質檢核師|獨立安全檢核師|自證審查者'; then
  exit 0
fi

# ═══════════════════════════════════════════
# 3. 偵測修改意圖
# ═══════════════════════════════════════════
HAS_MODIFICATION=false
if echo "$PROMPT" | grep -qiE '實作|修改|修正|修復|建立|新增|刪除|移除|重構|替換|優化|部署|寫入|implement|modify|fix|create|build|add|remove|refactor|write|update|edit|delete|replace|deploy'; then
  HAS_MODIFICATION=true
fi

# 無修改意圖 → 放行（研究/探索型 agent）
if ! $HAS_MODIFICATION; then
  exit 0
fi

# ═══════════════════════════════════════════
# 4. 檢查 marker（重試放行機制）
# ═══════════════════════════════════════════
GATE_DIR="/tmp/claude-delegation-gate"
mkdir -p "$GATE_DIR"

# 用 description 作為 marker key（同一委派重試時 description 不變）
MARKER_KEY=$(echo "$DESCRIPTION" | tr -dc 'a-zA-Z0-9' | head -c 40)
[[ -z "$MARKER_KEY" ]] && MARKER_KEY="default"
MARKER_FILE="$GATE_DIR/$MARKER_KEY"

if [[ -f "$MARKER_FILE" ]]; then
  echo -e "${ORANGE}🟠 委派閘門已通過，放行 Agent 調用${RESET}"
  exit 0
fi

# 建立 marker（重試時放行）
touch "$MARKER_FILE"

# ═══════════════════════════════════════════
# 5. 阻擋 — 要求委派前因果鏈分析
# ═══════════════════════════════════════════
echo -e "${ORANGE}🟠 ⛔ 委派被擋住：偵測到修改型 Agent 委派${RESET}"
echo ""
echo "┌─ 委派前因果鏈分析 ────────────────────┐"
echo "│ 委派 subagent 修改程式碼前，請先輸出：│"
echo "│                                        │"
echo "│ 📋 [委派前因果鏈分析]                  │"
echo "│ ├─ 預期修改檔案：{逐一列出}           │"
echo "│ ├─ 每個檔案的影響：{簡要}             │"
echo "│ └─ 範圍邊界：{不該被碰的東西}         │"
echo "│                                        │"
echo "│ 閉環 Phase 2 可省略根因               │"
echo "│（Phase 1 已定義）但仍須列出檔案和影響 │"
echo "└────────────────────────────────────────┘"
echo ""
echo "完成分析後，重試委派即可通過。"

echo "⛔ 委派前因果鏈分析未完成，Agent 調用被擋住。" >&2
exit 2
