#!/usr/bin/env bash
# check-version.sh — 版本檢查工具
# 用途：由 /dev:init-claude Skill 呼叫，取代多步版本偵測邏輯
# 用法：bash check-version.sh <快取源碼目錄> [--deployed <CLAUDE.md路徑>] [--check-remote]
#
# 輸出格式（key=value，供 Claude 解析）：
#   CACHE_VERSION=5.13.0        — 本地快取版本
#   DEPLOYED_VERSION=5.12.0     — 已部署版本（若指定 --deployed）
#   DEPLOYED_VERSION=none       — 未部署閉環
#   REMOTE_VERSION=5.13.0       — GitHub 遠端版本（若指定 --check-remote）
#   REMOTE_CHECK=success|failed — 遠端檢查結果
#   STATUS=up_to_date|upgrade_available|cache_outdated|not_deployed|deployed_newer

set -uo pipefail
# 注意：不用 set -e，因為 grep 找不到匹配時回傳 1 會誤觸

# ──────────────────────────────────────────
# 參數解析
# ──────────────────────────────────────────
CACHE_DIR=""
DEPLOYED_PATH=""
CHECK_REMOTE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deployed)
      DEPLOYED_PATH="$2"
      shift 2
      ;;
    --check-remote)
      CHECK_REMOTE=true
      shift
      ;;
    *)
      if [[ -z "$CACHE_DIR" ]]; then
        CACHE_DIR="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$CACHE_DIR" ]]; then
  echo "❌ 用法：bash check-version.sh <快取源碼目錄> [--deployed <路徑>] [--check-remote]"
  exit 1
fi

# ──────────────────────────────────────────
# 版本提取函式（grep 無匹配時回傳空字串，不觸發錯誤）
# ──────────────────────────────────────────
extract_version() {
  local file="$1"
  local ver=""
  if [[ -f "$file" ]]; then
    ver=$(grep -o 'closed-loop v[0-9.]*' "$file" 2>/dev/null | tail -1 | sed 's/closed-loop v//' || true)
  fi
  echo "$ver"
}

# ──────────────────────────────────────────
# 1. 本地快取版本
# ──────────────────────────────────────────
CACHE_TEMPLATE="${CACHE_DIR}/dev-closed-loop/CLAUDE_TEMPLATE.md"
CACHE_VERSION=$(extract_version "$CACHE_TEMPLATE")

if [[ -z "$CACHE_VERSION" ]]; then
  echo "CACHE_VERSION=unknown"
  echo "STATUS=error"
  echo "ERROR=無法從快取模板提取版本號：${CACHE_TEMPLATE}"
  exit 0
fi

echo "CACHE_VERSION=${CACHE_VERSION}"

# 1b. 本地快取 SHA（由 upgrade 模式下載時記錄）
CACHE_SHA_FILE="${CACHE_DIR}/.commit-sha"
CACHE_SHA=""
if [[ -f "$CACHE_SHA_FILE" ]]; then
  CACHE_SHA=$(cat "$CACHE_SHA_FILE" 2>/dev/null | tr -d '[:space:]')
fi
echo "CACHE_SHA=${CACHE_SHA:-none}"

# ──────────────────────────────────────────
# 2. 已部署版本（若指定）
# ──────────────────────────────────────────
DEPLOYED_VERSION=""
if [[ -n "$DEPLOYED_PATH" ]]; then
  if [[ -f "$DEPLOYED_PATH" ]]; then
    DEPLOYED_VERSION=$(extract_version "$DEPLOYED_PATH")
    if [[ -z "$DEPLOYED_VERSION" ]]; then
      echo "DEPLOYED_VERSION=none"
    else
      echo "DEPLOYED_VERSION=${DEPLOYED_VERSION}"
    fi
  else
    echo "DEPLOYED_VERSION=none"
  fi
fi

# ──────────────────────────────────────────
# 3. GitHub 遠端版本（若指定）
# ──────────────────────────────────────────
REMOTE_VERSION=""
if $CHECK_REMOTE; then
  REMOTE_RAW=$(curl -sL --max-time 5 "https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/dev-closed-loop/CLAUDE_TEMPLATE.md" 2>/dev/null || true)

  if [[ -n "$REMOTE_RAW" ]]; then
    REMOTE_VERSION=$(echo "$REMOTE_RAW" | grep -o 'closed-loop v[0-9.]*' | tail -1 | sed 's/closed-loop v//' || true)
  fi

  if [[ -n "$REMOTE_VERSION" ]]; then
    echo "REMOTE_VERSION=${REMOTE_VERSION}"
    echo "REMOTE_CHECK=success"
  else
    echo "REMOTE_VERSION=unknown"
    echo "REMOTE_CHECK=failed"
  fi

  # 3b. 遠端 SHA（GitHub API，5 秒超時）
  REMOTE_SHA=""
  REMOTE_SHA_RAW=$(curl -sL --max-time 5 "https://api.github.com/repos/gatewen/ClaudeCodeTools/commits/main" 2>/dev/null || true)
  if [[ -n "$REMOTE_SHA_RAW" ]]; then
    REMOTE_SHA=$(echo "$REMOTE_SHA_RAW" | grep '"sha"' | head -1 | sed 's/.*"sha": *"//;s/".*//' || true)
  fi
  echo "REMOTE_SHA=${REMOTE_SHA:-none}"
fi

# ──────────────────────────────────────────
# 4. 狀態判定（用 sort -V 做語義版本比較）
# ──────────────────────────────────────────

# 輔助函式：$1 是否比 $2 新（嚴格大於）
is_newer() {
  local higher
  higher=$(printf '%s\n%s' "$1" "$2" | sort -V | tail -1)
  [[ "$higher" == "$1" ]] && [[ "$1" != "$2" ]]
}

# 先檢查快取是否過時
if $CHECK_REMOTE && [[ -n "$REMOTE_VERSION" ]] && [[ "$REMOTE_VERSION" != "unknown" ]]; then
  if is_newer "$REMOTE_VERSION" "$CACHE_VERSION"; then
    echo "STATUS=cache_outdated"
    exit 0
  fi
  # 版本相同但 SHA 不同 → 有未發版的改動
  if [[ "$REMOTE_VERSION" == "$CACHE_VERSION" ]] && [[ -n "$REMOTE_SHA" ]] && [[ -n "$CACHE_SHA" ]] && [[ "$REMOTE_SHA" != "$CACHE_SHA" ]]; then
    echo "SHA_MISMATCH=true"
  fi
fi

# 再檢查部署狀態
if [[ -n "$DEPLOYED_PATH" ]]; then
  if [[ -z "$DEPLOYED_VERSION" ]]; then
    echo "STATUS=not_deployed"
  elif [[ "$CACHE_VERSION" == "$DEPLOYED_VERSION" ]]; then
    echo "STATUS=up_to_date"
  elif is_newer "$CACHE_VERSION" "$DEPLOYED_VERSION"; then
    echo "STATUS=upgrade_available"
  else
    echo "STATUS=deployed_newer"
  fi
else
  echo "STATUS=up_to_date"
fi
