#!/usr/bin/env bash
# deploy-hooks.sh — 一鍵部署閉環 Hook 系統到當前專案
# 用途：由 /dev:init-claude Skill 呼叫，取代多步 Bash 指示
# 用法：bash deploy-hooks.sh <源碼根目錄>
# 範例：bash /path/to/ClaudeCodeTools/dev-closed-loop/deploy-hooks.sh /path/to/ClaudeCodeTools
#
# 執行內容：
#   1. 複製 3 個 Hook 腳本 + _helpers.sh 到 .claude/hooks/；清除舊版已移除的 hook
#   2. 合併 Hook 配置到 .claude/settings.json（保留既有設定；移除指向已刪腳本的舊項目）
#      合併工具：python3 → python → jq（任一可用即可）
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
# 1. 複製 Hook 腳本 + 清除舊版 hook
# ──────────────────────────────────────────
mkdir -p .claude/hooks

HOOK_FILES=(
  "impact-analysis-guard.sh"
  "causal-chain-reset.sh"
  "incremental-lint.sh"
)

# v8 移除的 hook（部署時順手清掉，避免 settings.json 指向不存在的腳本）
LEGACY_HOOKS=(
  "delegation-gate.sh"
  "prompt-understanding-guard.sh"
  "delegation-tracker.sh"
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

for f in "${LEGACY_HOOKS[@]}"; do
  if [[ -f ".claude/hooks/$f" ]]; then
    rm -f ".claude/hooks/$f"
    echo "🧹 已移除舊版 hook：.claude/hooks/$f"
  fi
done

echo "📋 Hook 腳本：${COPY_COUNT}/${#HOOK_FILES[@]} 已複製（+ _helpers.sh 共用層）"

# ──────────────────────────────────────────
# 2. 合併 settings.json 配置
# ──────────────────────────────────────────
SETTINGS_FILE=".claude/settings.json"

# 合併用的 Python 腳本（幂等：已存在的 hook 不重複新增；舊版 hook 項目移除）
MERGE_SCRIPT='
import json, sys, os

settings_path = sys.argv[1]

if os.path.exists(settings_path):
    with open(settings_path) as f:
        cfg = json.load(f)
else:
    cfg = {}

hooks = cfg.setdefault("hooks", {})

# 移除 v8 已刪除 hook 的舊項目
LEGACY = ("delegation-gate", "prompt-understanding-guard", "delegation-tracker", "learning-log-checker")
for ev in list(hooks.keys()):
    hooks[ev] = [e for e in hooks[ev] if not any(k in str(e) for k in LEGACY)]
    if not hooks[ev]:
        del hooks[ev]

def ensure(event, keyword, entry):
    lst = hooks.setdefault(event, [])
    if not any(keyword in str(h) for h in lst):
        lst.append(entry)

def cmd(name):
    return {"type": "command", "command": "bash .claude/hooks/" + name}

# PreToolUse：修改前因果鏈守衛（既有原始碼檔首次修改擋一次）
ensure("PreToolUse", "impact-analysis-guard",
       {"matcher": "Write|Edit|MultiEdit", "hooks": [cmd("impact-analysis-guard.sh")]})
# PostToolUse：增量驗證
ensure("PostToolUse", "incremental-lint",
       {"matcher": "Write|Edit|MultiEdit", "hooks": [cmd("incremental-lint.sh")]})
# UserPromptSubmit：因果鏈 marker 每輪重置
ensure("UserPromptSubmit", "causal-chain-reset",
       {"hooks": [cmd("causal-chain-reset.sh")]})

if not cfg["hooks"]:
    del cfg["hooks"]

with open(settings_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)

print("OK")
'

# jq 版本（語意與 Python 版一致；python 不可用時使用）
JQ_SCRIPT='
def has_kw($kw): ((.hooks // []) | map(.command // "") | any(contains($kw)));
def is_legacy: has_kw("delegation-gate") or has_kw("prompt-understanding-guard")
               or has_kw("delegation-tracker") or has_kw("learning-log-checker");
def drop_legacy: map(select(is_legacy | not));
def ensure($kw; $entry): if any(.[]; has_kw($kw)) then . else . + [$entry] end;
def cmd($n): {type: "command", command: ("bash .claude/hooks/" + $n)};
.hooks //= {}
| .hooks |= with_entries(.value |= drop_legacy)
| .hooks.PreToolUse = ((.hooks.PreToolUse // [])
    | ensure("impact-analysis-guard"; {matcher: "Write|Edit|MultiEdit", hooks: [cmd("impact-analysis-guard.sh")]}))
| .hooks.PostToolUse = ((.hooks.PostToolUse // [])
    | ensure("incremental-lint"; {matcher: "Write|Edit|MultiEdit", hooks: [cmd("incremental-lint.sh")]}))
| .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // [])
    | ensure("causal-chain-reset"; {hooks: [cmd("causal-chain-reset.sh")]}))
| .hooks |= with_entries(select(.value | length > 0))
'

MERGE_OK=false
MERGE_TOOL=""
RESULT=""

if command -v python3 &>/dev/null; then
  if RESULT=$(python3 -c "$MERGE_SCRIPT" "$SETTINGS_FILE" 2>&1) && [[ "$RESULT" == *OK* ]]; then
    MERGE_OK=true; MERGE_TOOL="python3"
  fi
fi
if ! $MERGE_OK && command -v python &>/dev/null; then
  if RESULT=$(python -c "$MERGE_SCRIPT" "$SETTINGS_FILE" 2>&1) && [[ "$RESULT" == *OK* ]]; then
    MERGE_OK=true; MERGE_TOOL="python"
  fi
fi
if ! $MERGE_OK && command -v jq &>/dev/null; then
  [[ -f "$SETTINGS_FILE" ]] || echo '{}' > "$SETTINGS_FILE"
  if jq "$JQ_SCRIPT" "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" 2>/dev/null; then
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    MERGE_OK=true; MERGE_TOOL="jq"
  else
    rm -f "${SETTINGS_FILE}.tmp"
    RESULT="jq 合併失敗（settings.json 可能不是合法 JSON）"
  fi
fi

if $MERGE_OK; then
  echo "📋 settings.json：已合併 Hook 配置（${MERGE_TOOL}）"
else
  echo "❌ settings.json 合併失敗（需要 python3 / python / jq 任一可用）：${RESULT:-未知錯誤}"
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
  for keyword in "impact-analysis-guard" "causal-chain-reset" "incremental-lint"; do
    if ! grep -q "$keyword" "$SETTINGS_FILE" 2>/dev/null; then
      echo "❌ 驗證失敗：settings.json 缺少 $keyword 配置"
      VERIFY_OK=false
    fi
  done
  for legacy in "delegation-gate" "prompt-understanding-guard" "delegation-tracker" "learning-log-checker"; do
    if grep -q "$legacy" "$SETTINGS_FILE" 2>/dev/null; then
      echo "❌ 驗證失敗：settings.json 仍含已移除的 $legacy 配置"
      VERIFY_OK=false
    fi
  done
else
  echo "❌ 驗證失敗：${SETTINGS_FILE} 不存在"
  VERIFY_OK=false
fi

if $VERIFY_OK; then
  echo "✅ Hook 系統部署完成（3 腳本 + _helpers.sh + settings.json 配置）"
else
  echo "⚠️  Hook 系統部署有問題，請檢查上方錯誤訊息"
  exit 1
fi
