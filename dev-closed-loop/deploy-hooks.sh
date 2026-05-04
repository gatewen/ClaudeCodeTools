#!/usr/bin/env bash
# deploy-hooks.sh — 一鍵部署閉環 Hook 系統到當前專案
# 用途：由 /dev:init-claude Skill 呼叫，取代多步 Bash 指示
# 用法：bash deploy-hooks.sh <源碼根目錄>
# 範例：bash /path/to/ClaudeCodeTools/dev-closed-loop/deploy-hooks.sh /path/to/ClaudeCodeTools
#
# 執行內容：
#   1. 複製 6 個 Hook 腳本到 .claude/hooks/
#   2. 合併 Hook 配置到 .claude/settings.json（保留既有設定）
#   3. 驗證部署結果

set -euo pipefail

# ──────────────────────────────────────────
# 0. 參數檢查
# ──────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "❌ 用法：bash deploy-hooks.sh <源碼根目錄>"
  echo "   範例：bash deploy-hooks.sh ~/.claude/cache/ClaudeCodeTools"
  exit 1
fi

SOURCE_ROOT="$1"
HOOKS_SOURCE="${SOURCE_ROOT}/dev-closed-loop/hooks"

if [[ ! -d "$HOOKS_SOURCE" ]]; then
  echo "❌ Hook 源碼目錄不存在：${HOOKS_SOURCE}"
  exit 1
fi

# ──────────────────────────────────────────
# 1. 複製 Hook 腳本
# ──────────────────────────────────────────
mkdir -p .claude/hooks

HOOK_FILES=(
  "impact-analysis-guard.sh"
  "incremental-lint.sh"
  "delegation-tracker.sh"
  "delegation-gate.sh"
  "prompt-understanding-guard.sh"
  "learning-log-checker.sh"
)

COPY_COUNT=0
for f in "${HOOK_FILES[@]}"; do
  if [[ -f "${HOOKS_SOURCE}/$f" ]]; then
    cp "${HOOKS_SOURCE}/$f" ".claude/hooks/$f"
    chmod +x ".claude/hooks/$f"
    COPY_COUNT=$((COPY_COUNT + 1))
  else
    echo "⚠️  Hook 源檔缺失：${HOOKS_SOURCE}/$f"
  fi
done

# 複製共用 helpers（被 hooks source，不註冊到 settings.json）
if [[ -f "${HOOKS_SOURCE}/_helpers.sh" ]]; then
  cp "${HOOKS_SOURCE}/_helpers.sh" ".claude/hooks/_helpers.sh"
  chmod +x ".claude/hooks/_helpers.sh"
fi

echo "📋 Hook 腳本：${COPY_COUNT}/${#HOOK_FILES[@]} 已複製（+ _helpers.sh 共用層）"

# ──────────────────────────────────────────
# 2. 合併 settings.json 配置
# ──────────────────────────────────────────
SETTINGS_FILE=".claude/settings.json"

# 合併用的 Python 腳本（幂等：已存在的 hook 不重複新增）
MERGE_SCRIPT='
import json, sys, os

settings_path = sys.argv[1]

# 讀取或建立設定
if os.path.exists(settings_path):
    with open(settings_path) as f:
        cfg = json.load(f)
else:
    cfg = {}

hooks = cfg.setdefault("hooks", {})

# PreToolUse：修改前統一守衛（雙閘門阻擋）
pre_hooks = hooks.setdefault("PreToolUse", [])
guard_entry = {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [{"type": "command", "command": "bash .claude/hooks/impact-analysis-guard.sh"}]
}
if not any("impact-analysis-guard" in str(h) for h in pre_hooks):
    pre_hooks.append(guard_entry)

# PreToolUse：委派前因果鏈閘門
delegation_gate_entry = {
    "matcher": "Agent",
    "hooks": [{"type": "command", "command": "bash .claude/hooks/delegation-gate.sh"}]
}
if not any("delegation-gate" in str(h) for h in pre_hooks):
    pre_hooks.append(delegation_gate_entry)

# PostToolUse：增量驗證
post_hooks = hooks.setdefault("PostToolUse", [])
lint_entry = {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [{"type": "command", "command": "bash .claude/hooks/incremental-lint.sh"}]
}
if not any("incremental-lint" in str(h) for h in post_hooks):
    post_hooks.append(lint_entry)

# PostToolUse：委派追蹤
delegation_entry = {
    "matcher": "Agent",
    "hooks": [{"type": "command", "command": "bash .claude/hooks/delegation-tracker.sh"}]
}
if not any("delegation-tracker" in str(h) for h in post_hooks):
    post_hooks.append(delegation_entry)

# PostToolUse：學習日誌提醒（git commit 後檢查 learning-log）
learning_entry = {
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": "bash .claude/hooks/learning-log-checker.sh"}]
}
if not any("learning-log-checker" in str(h) for h in post_hooks):
    post_hooks.append(learning_entry)

# UserPromptSubmit：理解確認旗標
prompt_hooks = hooks.setdefault("UserPromptSubmit", [])
prompt_entry = {
    "hooks": [{"type": "command", "command": "bash .claude/hooks/prompt-understanding-guard.sh"}]
}
if not any("prompt-understanding-guard" in str(h) for h in prompt_hooks):
    prompt_hooks.append(prompt_entry)

with open(settings_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)

print("OK")
'

MERGE_OK=false

# 嘗試 python3
if command -v python3 &>/dev/null; then
  RESULT=$(python3 -c "$MERGE_SCRIPT" "$SETTINGS_FILE" 2>&1) && MERGE_OK=true
fi

# 嘗試 python fallback
if ! $MERGE_OK && command -v python &>/dev/null; then
  RESULT=$(python -c "$MERGE_SCRIPT" "$SETTINGS_FILE" 2>&1) && MERGE_OK=true
fi

if $MERGE_OK; then
  echo "📋 settings.json：已合併 Hook 配置"
else
  echo "❌ settings.json 合併失敗（需要 python3）：${RESULT:-未知錯誤}"
  exit 1
fi

# ──────────────────────────────────────────
# 3. 驗證部署結果
# ──────────────────────────────────────────
VERIFY_OK=true

for f in "${HOOK_FILES[@]}"; do
  if [[ ! -x ".claude/hooks/$f" ]]; then
    echo "❌ 驗證失敗：.claude/hooks/$f 不存在或不可執行"
    VERIFY_OK=false
  fi
done

if [[ -f "$SETTINGS_FILE" ]]; then
  for keyword in "impact-analysis-guard" "delegation-gate" "incremental-lint" "delegation-tracker" "prompt-understanding-guard" "learning-log-checker"; do
    if ! grep -q "$keyword" "$SETTINGS_FILE" 2>/dev/null; then
      echo "❌ 驗證失敗：settings.json 缺少 $keyword 配置"
      VERIFY_OK=false
    fi
  done
else
  echo "❌ 驗證失敗：${SETTINGS_FILE} 不存在"
  VERIFY_OK=false
fi

if $VERIFY_OK; then
  echo "✅ Hook 系統部署完成（6 腳本 + settings.json 配置）"
else
  echo "⚠️  Hook 系統部署有問題，請檢查上方錯誤訊息"
  exit 1
fi
