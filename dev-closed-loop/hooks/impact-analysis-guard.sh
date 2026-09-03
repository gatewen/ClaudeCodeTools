#!/usr/bin/env bash
# impact-analysis-guard.sh — 修改前因果鏈守衛 Hook（v8 收窄版）
# 觸發：PreToolUse (Write | Edit | MultiEdit)
# 輸入：stdin JSON { session_id, tool_input: { file_path } }
# 職責：同一輪指令內，首次修改「既有原始碼檔」時擋一次（exit 2），把引用者清單與
#       2-4 行分析格式送到 stderr（exit 2 時只有 stderr 會回到模型），重試放行。
# 不擋：新建檔案（沒有呼叫者可分析）/ 非原始碼副檔名（md json yaml toml txt html css lock …）
# 誠實邊界：只保證「暫停一次 + 分析可見 + 引用者粗搜供起點」。不解析 grep 結果、
#       不驗證分析正確性；分析品質靠模型與人審。
# marker：{TMPDIR}/claude-code-tools/{project}/causal-chain/{session}/{file}
#       由 causal-chain-reset.sh（UserPromptSubmit）每輪清除。

set -euo pipefail
# shellcheck source=_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

INPUT=$(cat)
FILE_PATH=$(json_field "$INPUT" '.tool_input.file_path')
[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0   # 新建檔案 → 放行

FILENAME=$(basename "$FILE_PATH")
STEM="${FILENAME%.*}"
EXT=$(printf '%s' "${FILENAME##*.}" | tr '[:upper:]' '[:lower:]')

# 只守原始碼副檔名（可依專案增減）
SOURCE_EXTS="ts tsx js jsx mjs cjs py go rs cs java kt kts swift rb php c cc cpp h hpp sh bash lua sql vue svelte dart scala ex exs"
IS_SOURCE=false
for e in $SOURCE_EXTS; do
  if [[ "$EXT" == "$e" ]]; then IS_SOURCE=true; break; fi
done
$IS_SOURCE || exit 0

# session 隔離的 marker（同專案多 session 不互相干擾）；路徑中 / \ : 空白 轉底線
GUARD_DIR="$(get_gate_base)/causal-chain/$(get_session_key "$INPUT")"
mkdir -p "$GUARD_DIR"
MARKER="$GUARD_DIR/$(printf '%s' "$FILE_PATH" | tr '/\\: ' '____')"

if [[ -f "$MARKER" ]]; then
  echo -e "\033[38;5;208m🟠 因果鏈已分析，放行修改 ${FILENAME}\033[0m"
  exit 0
fi
touch "$MARKER"   # 重試時放行

# 引用者粗搜：以檔名主幹為整字關鍵字搜專案（僅供起點，模型仍需自行 grep 實際符號）
DEPENDENTS=""
if command -v rg >/dev/null 2>&1; then
  DEPENDENTS=$(rg -lw --no-messages "$STEM" \
    --glob '!node_modules' --glob '!.git' --glob '!*.lock' --glob '!target' \
    --glob '!dist' --glob '!build' --glob '!.claude-loop' --glob '!.claudedocs' \
    . 2>/dev/null | grep -v -F "$FILENAME" | head -10) || true
else
  INCLUDES=()
  for e in $SOURCE_EXTS; do INCLUDES+=("--include=*.${e}"); done
  DEPENDENTS=$(grep -rlw "${INCLUDES[@]}" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=target \
    --exclude-dir=dist --exclude-dir=build --exclude-dir=.claude-loop --exclude-dir=.claudedocs \
    -- "$STEM" . 2>/dev/null | grep -v -F "$FILENAME" | head -10) || true
fi

# 阻擋：訊息全部走 stderr（exit 2 時模型只看得到 stderr）
{
  echo "⛔ 首次修改 ${FILENAME}，先做因果鏈分析再重試。"
  if [[ -n "$DEPENDENTS" ]]; then
    echo "引用「${STEM}」的檔案（檔名整字粗搜、最多 10 筆，僅供起點，請自行 grep 實際符號）："
    printf '%s\n' "$DEPENDENTS" | sed 's/^/  → /'
  else
    echo "粗搜未找到引用「${STEM}」的檔案。請自行 grep 實際符號確認；呼叫者 = 0 時不可直接改，先找真正的執行路徑（可能有 inline 實作繞過）。"
  fi
  echo "請輸出 2-4 行："
  # 格式從專案 CLAUDE.md Section 2「輸出」行讀（SSOT：模板是唯一出處）；讀不到才用 fallback，改格式時兩邊同步。
  # 本腳本 set -e + pipefail：grep 找不到會讓整個 pipeline 非零，必須 || true，否則守衛在這裡提前結束（exit 1 = 不阻擋）。
  PROJECT_CLAUDE_MD="${CLAUDE_PROJECT_DIR:-.}/CLAUDE.md"
  FORMAT_LINE=$( { grep -m1 -F '**輸出**' "$PROJECT_CLAUDE_MD" 2>/dev/null || true; } | sed -n 's/.*`\(⚠️[^`]*\)`.*/\1/p')
  if [[ -z "$FORMAT_LINE" ]]; then
    FORMAT_LINE="⚠️ 改 {檔:函式}｜呼叫者 N 個：{要連動的 / 不需要的理由}｜重複定義：{N 處 / 無}｜風險：{…}｜連動清單：{…}"
  fi
  echo "  ${FORMAT_LINE}"
  echo "同類掃描：若此檔是一組同類之一，先掃同類有無同樣問題。完成後重試即放行。"
} >&2
exit 2
