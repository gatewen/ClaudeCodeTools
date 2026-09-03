#!/usr/bin/env bash
# _helpers.sh — Shared helpers for closed-loop hooks
# Sourced (not executed). Provides:
#   - project-scoped marker paths (prevent cross-project pollution)
#   - stdin-JSON field extraction (jq first, sed fallback; no python dependency)
#   - session key derivation (per-session marker isolation)

# Derive a stable, filesystem-safe project key from the current project root.
# Uses CLAUDE_PROJECT_DIR if Claude Code provides it, falls back to PWD.
get_project_key() {
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    printf '%s' "$project_root" | tr '/: ' '___' | tr -dc 'a-zA-Z0-9_.-'
}

# Get the per-project gate base directory.
# Example: ${TMPDIR}/claude-code-tools/_Users_foo_myproject/causal-chain/<session>/<file>
# (macOS TMPDIR is /var/folders/.../T/, Linux fallback is /tmp)
get_gate_base() {
    local tmp_dir="${TMPDIR:-/tmp}"
    tmp_dir="${tmp_dir%/}"  # strip trailing slash (macOS TMPDIR has one)
    printf '%s/claude-code-tools/%s' "$tmp_dir" "$(get_project_key)"
}

# 從 stdin JSON 字串取欄位：json_field "$INPUT" '.tool_input.file_path'
# jq 優先；無 jq（或設 CLOSED_LOOP_NO_JQ=1，供測試）時用 sed 抓第一個 "key": "value"
# （僅支援字串欄位，足夠 hook 所需：file_path / session_id / prompt / command）。
# 失敗回空字串。sed 後援會還原 JSON 跳脫的 \\ 與 \/（Windows 路徑會以 \\ 出現）。
json_field() {
    local json="$1" jqpath="$2" key val=""
    if [[ -z "${CLOSED_LOOP_NO_JQ:-}" ]] && command -v jq >/dev/null 2>&1; then
        val=$(printf '%s' "$json" | jq -r "${jqpath} // empty" 2>/dev/null) || val=""
        printf '%s' "$val"
        return 0
    fi
    key="${jqpath##*.}"
    val=$(printf '%s' "$json" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1)
    # 還原 JSON 跳脫：\\ → \ 、\/ → /（用參數展開，避免 sed 多層跳脫混淆）
    val=${val//\\\\/\\}
    val=${val//\\\//\/}
    printf '%s' "$val"
}

# 從 stdin JSON 取 session_id 並轉成檔案系統安全的 key；無 session_id → "default"
get_session_key() {
    local sid
    sid=$(json_field "$1" '.session_id')
    sid=$(printf '%s' "$sid" | tr -dc 'a-zA-Z0-9_-' | head -c 64)
    printf '%s' "${sid:-default}"
}
