#!/usr/bin/env bash
# causal-chain-reset.sh — 因果鏈 marker 每輪重置 Hook
# 觸發：UserPromptSubmit
# 輸入：stdin JSON { session_id, prompt }
# 職責：清除本 session 的因果鏈 marker，讓每個新指令的首次修改重新做一次分析。
#       無關鍵字判斷、無阻擋、無輸出，永遠 exit 0。
#       （v8 前此職責藏在 prompt-understanding-guard.sh 內；該 hook 已移除）

set -euo pipefail
# shellcheck source=_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

INPUT=$(cat)
rm -rf "$(get_gate_base)/causal-chain/$(get_session_key "$INPUT")" 2>/dev/null || true
exit 0
