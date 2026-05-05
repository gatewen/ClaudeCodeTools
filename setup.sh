#!/bin/bash
# AI-ClaudeCode 安裝腳本
# 用途：部署 Skill 到 ~/.claude/commands/ 並檢查依賴
# 使用：
#   遠端安裝：curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
#   本地安裝：cd ClaudeCodeTools && bash setup.sh

set -e

# main() 包裝：防止 curl | bash 時因下載中斷而執行不完整腳本
main() {

GITHUB_REPO="gatewen/ClaudeCodeTools"
# 測試用 env var override（生產環境留空時使用 GitHub 預設值）
TARBALL_URL="${SETUP_TARBALL_URL:-https://github.com/${GITHUB_REPO}/archive/refs/heads/main.tar.gz}"
SHA_URL="${SETUP_SHA_URL:-https://api.github.com/repos/${GITHUB_REPO}/commits/main}"
CACHE_DIR="$HOME/.claude/cache/ClaudeCodeTools"
COMMANDS_DIR="$HOME/.claude/commands"
SKILL_TARGET="$COMMANDS_DIR/dev/init-claude.md"

# --------------------------------------------------
# 0. 模式偵測：本地 or 遠端
# --------------------------------------------------

detect_source() {
    local script_dir=""

    # 嘗試取得腳本所在目錄（curl | bash 時 $0 = bash，dirname 無意義）
    if [ -f "$0" ] && [ "$(basename "$0")" = "setup.sh" ]; then
        script_dir="$(cd "$(dirname "$0")" && pwd)"
    fi

    # 本地模式：腳本旁邊有 dev-closed-loop/
    if [ -n "$script_dir" ] && [ -d "$script_dir/dev-closed-loop" ]; then
        SOURCE_DIR="$script_dir"
        INSTALL_MODE="local"
        return 0
    fi

    # 遠端模式：從 GitHub 下載
    INSTALL_MODE="remote"
    download_to_cache
    SOURCE_DIR="$CACHE_DIR"
}

download_to_cache() {
    echo "📥 從 GitHub 下載最新版本..."

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    # 下載 tarball
    if ! curl -sL "$TARBALL_URL" -o "$tmp_dir/archive.tar.gz"; then
        rm -rf "$tmp_dir"
        echo "❌ 下載失敗。請確認網路連線正常。"
        exit 1
    fi

    # 解壓縮
    if ! tar -xzf "$tmp_dir/archive.tar.gz" -C "$tmp_dir"; then
        rm -rf "$tmp_dir"
        echo "❌ 解壓縮失敗。"
        exit 1
    fi

    # GitHub tarball 會建立 ClaudeCodeTools-main/ 子目錄
    local extracted_dir
    extracted_dir="$(find "$tmp_dir" -maxdepth 1 -type d -name 'ClaudeCodeTools-*' | head -1)"
    if [ -z "$extracted_dir" ]; then
        rm -rf "$tmp_dir"
        echo "❌ 解壓縮的目錄結構異常。"
        exit 1
    fi

    # 用新下載覆蓋快取
    rm -rf "$CACHE_DIR"
    mkdir -p "$(dirname "$CACHE_DIR")"
    mv "$extracted_dir" "$CACHE_DIR"
    rm -rf "$tmp_dir"

    # 記錄 main branch SHA 到 .commit-sha（供 check-version.sh 偵測同版本不同 patch）
    # 失敗不阻擋安裝；只是 same-version-diff-patch 場景無法被自動偵測
    local sha=""
    local sha_raw
    sha_raw=$(curl -sL --max-time 5 "$SHA_URL" 2>/dev/null || true)
    if [ -n "$sha_raw" ]; then
        sha=$(echo "$sha_raw" | grep '"sha"' | head -1 | sed 's/.*"sha": *"//;s/".*//' 2>/dev/null || true)
    fi
    if [ -n "$sha" ]; then
        echo "$sha" > "${CACHE_DIR}/.commit-sha"
        echo "📌 commit SHA: ${sha:0:7}"
    else
        echo "ℹ️  無法取得 GitHub SHA（不影響安裝；同版本不同 patch 將無法自動偵測）"
    fi

    echo "✅ 已下載至 ${CACHE_DIR}"
}

# 執行偵測
detect_source

SKILL_SOURCE="$SOURCE_DIR/dev-closed-loop/skill/init-claude.md"
# 遠端模式的 {{REPO_PATH}} 指向快取；本地模式指向 repo 目錄
REPO_PATH_VALUE="$SOURCE_DIR"

echo "================================================"
echo "  AI-ClaudeCode 安裝腳本"
echo "================================================"
echo ""
if [ "$INSTALL_MODE" = "local" ]; then
    echo "模式：本地安裝（從 repo 目錄）"
else
    echo "模式：遠端安裝（從 GitHub 下載）"
fi
echo "來源路徑：${SOURCE_DIR}"
echo ""

# --------------------------------------------------
# 1. 檢查前置條件
# --------------------------------------------------

# 確認 Skill 源碼存在
if [ ! -f "$SKILL_SOURCE" ]; then
    echo "❌ 找不到 Skill 源碼：${SKILL_SOURCE}"
    echo "   請確認檔案完整"
    exit 1
fi

# 確認 ~/.claude/commands/ 目錄存在
if [ ! -d "$COMMANDS_DIR" ]; then
    echo "⚠️  ~/.claude/commands/ 目錄不存在，建立中..."
    mkdir -p "$COMMANDS_DIR"
fi

# 確認部署子目錄存在
mkdir -p "$COMMANDS_DIR/dev"

# --------------------------------------------------
# 2. 檢查可選增強工具（v5.14.0 後閉環自帶 Agent 專家庫，全部 optional）
# --------------------------------------------------

echo "--- 可選增強工具檢查（缺少不影響閉環核心運作）---"

# SuperClaude（可選 — sc:* 系列分析/設計指令）
if ls "$HOME/.claude/commands/sc/" >/dev/null 2>&1 && [ "$(ls -A "$HOME/.claude/commands/sc/" 2>/dev/null)" ]; then
    echo "✅ SuperClaude 已安裝"
else
    echo "ℹ️  SuperClaude 未安裝（可選 — 安裝後可用 sc:* 系列分析指令）"
fi

# Superpowers（可選 — superpowers:* 系列 TDD/debugging skills）
if grep -q "superpowers@claude-plugins-official" "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null; then
    echo "✅ Superpowers 已安裝"
else
    echo "ℹ️  Superpowers 未安裝（可選 — 安裝後可用 superpowers:* 系列 skills）"
fi

# claude-mem（可選 — 跨時間語義記憶）
if grep -rqw "claude-mem" "$HOME/.claude/plugins/" 2>/dev/null || grep -qw "claude-mem" "$HOME/.claude/.mcp.json" 2>/dev/null; then
    echo "✅ claude-mem 已安裝（可選 — 跨時間語義記憶）"
else
    echo "ℹ️  claude-mem 未安裝（可選 — 安裝後可啟用跨時間語義記憶）"
fi

# --------------------------------------------------
# 3. 部署 Skill
# --------------------------------------------------

echo "--- 部署 Skill ---"

# 讀取 Skill 源碼，替換 {{REPO_PATH}} 為來源路徑，寫入目標
sed "s|{{REPO_PATH}}|${REPO_PATH_VALUE}|g" "$SKILL_SOURCE" > "$SKILL_TARGET"

echo "✅ init-claude.md 已部署到 ${SKILL_TARGET}"

# --------------------------------------------------
# 4. 驗證
# --------------------------------------------------

echo ""
echo "--- 驗證 ---"

# 確認部署的 Skill 沒有殘留 placeholder
if grep -q '{{REPO_PATH}}' "$SKILL_TARGET" 2>/dev/null; then
    echo "❌ 部署的 Skill 仍有 {{REPO_PATH}} 殘留"
    exit 1
else
    echo "✅ Placeholder 已全部替換"
fi

# 確認部署的 Skill 包含正確路徑
if grep -q "${REPO_PATH_VALUE}" "$SKILL_TARGET" 2>/dev/null; then
    echo "✅ 路徑指向 ${REPO_PATH_VALUE}"
else
    echo "❌ 路徑替換異常"
    exit 1
fi

# 確認模板檔案可達
if [ -f "${SOURCE_DIR}/dev-closed-loop/CLAUDE_TEMPLATE.md" ]; then
    echo "✅ 模板檔案存在"
else
    echo "❌ 模板檔案不存在：${SOURCE_DIR}/dev-closed-loop/CLAUDE_TEMPLATE.md"
    exit 1
fi

# 確認 .claudedocs 完整
EXPECTED_FILES=(
    "README.md"
    "concepts/閉環核心理念.md"
    "concepts/方法論運作指標.md"
    "process/五階段閉環流程.md"
    "process/層級擴展.md"
    "process/跨Session持久化.md"
    "process/介面契約與變更管理.md"
    "process/實戰驗證流程.md"
    "standards/Agent使用指南.md"
    "standards/Git工作流.md"
    "standards/產出物格式.md"
    "records/問題追蹤.md"
    "examples/01-think-before-coding.md"
    "examples/02-simplicity-first.md"
    "examples/03-surgical-changes.md"
    "examples/04-goal-driven-execution.md"
    "examples/05-cross-artifact-mismatch.md"
)
DOCS_DIR="${SOURCE_DIR}/dev-closed-loop/.claudedocs"
DOCS_OK=true
for f in "${EXPECTED_FILES[@]}"; do
    if [ ! -f "$DOCS_DIR/$f" ]; then
        echo "❌ 缺少文檔：.claudedocs/$f"
        DOCS_OK=false
    fi
done
if $DOCS_OK; then
    echo "✅ .claudedocs 完整（17/17）"
fi

# 確認 agents 目錄完整
AGENT_FILES=(
    "agents/README.md"
    "agents/requirements-analyst.md"
    "agents/architect.md"
    "agents/design-reviewer.md"
    "agents/implementer.md"
    "agents/code-reviewer.md"
    "agents/security-reviewer.md"
    "agents/tester.md"
    "agents/verifier.md"
)
AGENT_OK=true
AGENT_COUNT=0
for f in "${AGENT_FILES[@]}"; do
    if [ -f "$DOCS_DIR/$f" ]; then
        AGENT_COUNT=$((AGENT_COUNT + 1))
    else
        echo "❌ 缺少 Agent：.claudedocs/$f"
        AGENT_OK=false
    fi
done
if $AGENT_OK; then
    echo "✅ Agent 專家庫完整（${AGENT_COUNT}/${#AGENT_FILES[@]}）"
fi

# 確認 languages 目錄完整
LANG_FILES=(
    "languages/README.md"
    "languages/typescript.md"
    "languages/python.md"
    "languages/go.md"
    "languages/rust.md"
    "languages/csharp.md"
    "languages/bash.md"
)
LANG_OK=true
LANG_COUNT=0
LANG_TOTAL=${#LANG_FILES[@]}
for f in "${LANG_FILES[@]}"; do
    if [ -f "$DOCS_DIR/$f" ]; then
        LANG_COUNT=$((LANG_COUNT + 1))
    else
        LANG_OK=false
    fi
done
if $LANG_OK; then
    echo "✅ 語言 Skills 完整（${LANG_COUNT}/${LANG_TOTAL}）"
else
    echo "⚠️  語言 Skills 不完整（${LANG_COUNT}/${LANG_TOTAL}）— 不影響核心功能"
fi

# 確認 hooks 完整（6 個 hook + 1 個共用 helpers）
HOOK_FILES=(
    "hooks/impact-analysis-guard.sh"
    "hooks/incremental-lint.sh"
    "hooks/delegation-tracker.sh"
    "hooks/delegation-gate.sh"
    "hooks/prompt-understanding-guard.sh"
    "hooks/learning-log-checker.sh"
    "hooks/_helpers.sh"
)
HOOKS_OK=true
for f in "${HOOK_FILES[@]}"; do
    if [ ! -f "${SOURCE_DIR}/dev-closed-loop/$f" ]; then
        echo "❌ 缺少 Hook：$f"
        HOOKS_OK=false
    fi
done
if $HOOKS_OK; then
    echo "✅ Hook 腳本完整（${#HOOK_FILES[@]}/${#HOOK_FILES[@]}）"
fi

# 確認部署/版本檢查腳本完整
UTIL_SCRIPTS=(
    "deploy-hooks.sh"
    "check-version.sh"
)
UTILS_OK=true
for f in "${UTIL_SCRIPTS[@]}"; do
    if [ ! -f "${SOURCE_DIR}/dev-closed-loop/$f" ]; then
        echo "❌ 缺少工具腳本：$f"
        UTILS_OK=false
    fi
done
if $UTILS_OK; then
    echo "✅ 工具腳本完整（${#UTIL_SCRIPTS[@]}/${#UTIL_SCRIPTS[@]}）"
fi

# --------------------------------------------------
# 完成
# --------------------------------------------------

echo ""
echo "================================================"
echo "  ✅ 安裝完成"
echo "================================================"
echo ""
echo "現在可以在任何專案目錄執行 /dev:init-claude 來部署閉環。"
echo ""
if [ "$INSTALL_MODE" = "local" ]; then
    echo "更新流程：git pull → bash setup.sh"
else
    echo "更新流程：執行 /dev:init-claude upgrade（自動從 GitHub 下載最新版）"
    echo "  或重新執行：curl -sL https://raw.githubusercontent.com/${GITHUB_REPO}/main/setup.sh | bash"
fi

}

main "$@"
