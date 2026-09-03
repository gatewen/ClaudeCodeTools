#!/usr/bin/env bash
# incremental-lint.sh — 增量驗證 Hook
# 觸發：PostToolUse (Write | Edit | MultiEdit)
# 輸入：stdin JSON { tool_input: { file_path: "..." } }
# 輸出：exit 0 = 放行 | exit 2 = 阻擋（stderr 回饋 lint 錯誤）

set -euo pipefail
# shellcheck source=_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

# 1. 讀取 stdin JSON，提取 file_path（jq 優先，sed 後援，不依賴 python）
INPUT=$(cat)
FILE_PATH=$(json_field "$INPUT" '.tool_input.file_path')

# 無法取得 file_path 或檔案不存在 → 靜默放行
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# 2. 橙色提醒
FILENAME=$(basename "$FILE_PATH")
echo -e "\033[38;5;208m🟠 收到：${FILENAME} 已修改，執行增量驗證\033[0m"

# 3. 取得副檔名
EXT="${FILE_PATH##*.}"

# 4. 根據副檔名選擇 linter
case "$EXT" in
  ts|tsx|js|jsx)
    if command -v npx &>/dev/null && [[ -f "${CLAUDE_PROJECT_DIR:-.}/node_modules/.bin/eslint" ]]; then
      cd "${CLAUDE_PROJECT_DIR:-.}"
      npx eslint --no-warn-ignored "$FILE_PATH" 2>&1 || {
        echo "❌ ESLint 錯誤：$FILE_PATH" >&2
        echo "請修正上述 lint 錯誤後再繼續。" >&2
        exit 2
      }
    fi
    ;;
  py)
    if command -v ruff &>/dev/null; then
      ruff check "$FILE_PATH" 2>&1 || {
        echo "❌ Ruff 錯誤：$FILE_PATH" >&2
        echo "請修正上述 lint 錯誤後再繼續。" >&2
        exit 2
      }
    fi
    ;;
  go)
    if command -v golangci-lint &>/dev/null; then
      cd "${CLAUDE_PROJECT_DIR:-.}"
      golangci-lint run "$FILE_PATH" 2>&1 || {
        echo "❌ golangci-lint 錯誤：$FILE_PATH" >&2
        echo "請修正上述 lint 錯誤後再繼續。" >&2
        exit 2
      }
    fi
    ;;
  # rs, cs, md, json, yaml, yml 等 → 無 per-file linter，靜默放行
  *)
    ;;
esac

exit 0
