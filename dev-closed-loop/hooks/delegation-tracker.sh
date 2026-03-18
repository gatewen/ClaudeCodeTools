#!/usr/bin/env bash
# delegation-tracker.sh — 委派追蹤 Hook
# 觸發：PostToolUse (Agent)
# 輸入：stdin JSON { tool_input: { prompt: "...", description: "..." } }
# 輸出：exit 0（永遠放行，僅記錄）
# 用途：當 Agent tool 被呼叫時，自動記錄到 .delegation-log。
#       此 log 由 Claude Code harness 寫入，Claude 無法偽造。
#       Phase 5 Part C 驗證此 log 是否包含所有預期的委派記錄。

set -euo pipefail

# 只在完整閉環啟用時追蹤（artifacts 目錄存在）
[[ ! -d ".claude-loop/artifacts" ]] && exit 0

# 1. 讀取 stdin JSON，提取 prompt 前 300 字元
INPUT=$(cat)
PROMPT=""

if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null | head -c 300)
fi

if [[ -z "$PROMPT" ]]; then
  PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('prompt', '')[:300])
except:
    print('')
" 2>/dev/null)
fi

# 無法取得 prompt → 靜默放行
[[ -z "$PROMPT" ]] && exit 0

# 2. 從 prompt 關鍵字識別委派 Phase
PHASE=""

if echo "$PROMPT" | grep -qi "設計審查\|design review\|獨立設計審查者"; then
  PHASE="P1b"
elif echo "$PROMPT" | grep -qi "品質檢核\|quality.*review\|獨立品質檢核師"; then
  PHASE="P3-quality"
elif echo "$PROMPT" | grep -qi "安全檢核\|security.*review\|獨立安全檢核師"; then
  PHASE="P3-security"
elif echo "$PROMPT" | grep -qi "追溯檢查\|traceability\|自証審查者（追溯"; then
  PHASE="P5A"
elif echo "$PROMPT" | grep -qi "反向分析\|reverse.*analysis\|自証審查者（反向"; then
  PHASE="P5B"
fi

# 非閉環委派的 Agent 呼叫 → 靜默放行
[[ -z "$PHASE" ]] && exit 0

# 3. 寫入委派記錄
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')
echo "$TIMESTAMP DELEGATED $PHASE" >> .claude-loop/artifacts/.delegation-log

exit 0
