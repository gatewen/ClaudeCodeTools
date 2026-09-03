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
# 3.4 遷移：移除 v7.0.x 舊版 colon-skill 形式
#     v7.1.0 起 dev:handoff / dev:overview 改為 commands/dev/*.md（冒號由子資料夾合成 →
#     磁碟零冒號 → 原生 Windows 相容）。舊版是冒號目錄 skill，需清除避免同名指令重複。
# --------------------------------------------------

LEGACY_SKILLS_DIR="$HOME/.claude/skills"
for old in "$LEGACY_SKILLS_DIR/dev:handoff" "$LEGACY_SKILLS_DIR/dev:overview"; do
    if [ -d "$old" ]; then
        rm -rf "$old"
        echo "🧹 已移除舊版 skill：${old}（v7.1.0 起改用 command 形式）"
    fi
done

# --------------------------------------------------
# 3.5 部署 dev:handoff（command shim + bundle · 跨 session 交接）
#     shim  → ~/.claude/commands/dev/handoff.md（提供 /dev:handoff 冒號名 + 自動觸發）
#     bundle → ~/.claude/dev-closed-loop/handoff/（commands/skills 之外，不註冊不污染）
# --------------------------------------------------

echo "--- 部署 dev:handoff（command + bundle）---"

BUNDLES_DIR="$HOME/.claude/dev-closed-loop"
HANDOFF_SHIM_SOURCE="$SOURCE_DIR/dev-closed-loop/commands/dev/handoff.md"
HANDOFF_SHIM_TARGET="$COMMANDS_DIR/dev/handoff.md"
HANDOFF_BUNDLE_SOURCE="$SOURCE_DIR/dev-closed-loop/command-refs/handoff"
HANDOFF_BUNDLE_TARGET="$BUNDLES_DIR/handoff"

if [ ! -f "$HANDOFF_SHIM_SOURCE" ] || [ ! -d "$HANDOFF_BUNDLE_SOURCE" ]; then
    echo "❌ 找不到 dev:handoff 源碼：${HANDOFF_SHIM_SOURCE} 或 ${HANDOFF_BUNDLE_SOURCE}"
    exit 1
fi

mkdir -p "$BUNDLES_DIR"
cp "$HANDOFF_SHIM_SOURCE" "$HANDOFF_SHIM_TARGET"
rm -rf "$HANDOFF_BUNDLE_TARGET"
cp -r "$HANDOFF_BUNDLE_SOURCE" "$HANDOFF_BUNDLE_TARGET"

echo "✅ dev:handoff 已部署：shim → ${HANDOFF_SHIM_TARGET}，bundle → ${HANDOFF_BUNDLE_TARGET}"

# --------------------------------------------------
# 3.6 部署 dev:overview（command shim + bundle · 方法論視覺化介紹）
# --------------------------------------------------

echo "--- 部署 dev:overview（command + bundle）---"

OVERVIEW_SHIM_SOURCE="$SOURCE_DIR/dev-closed-loop/commands/dev/overview.md"
OVERVIEW_SHIM_TARGET="$COMMANDS_DIR/dev/overview.md"
OVERVIEW_BUNDLE_SOURCE="$SOURCE_DIR/dev-closed-loop/command-refs/overview"
OVERVIEW_BUNDLE_TARGET="$BUNDLES_DIR/overview"

if [ ! -f "$OVERVIEW_SHIM_SOURCE" ] || [ ! -d "$OVERVIEW_BUNDLE_SOURCE" ]; then
    echo "❌ 找不到 dev:overview 源碼：${OVERVIEW_SHIM_SOURCE} 或 ${OVERVIEW_BUNDLE_SOURCE}"
    exit 1
fi

cp "$OVERVIEW_SHIM_SOURCE" "$OVERVIEW_SHIM_TARGET"
rm -rf "$OVERVIEW_BUNDLE_TARGET"
cp -r "$OVERVIEW_BUNDLE_SOURCE" "$OVERVIEW_BUNDLE_TARGET"

echo "✅ dev:overview 已部署：shim → ${OVERVIEW_SHIM_TARGET}，bundle → ${OVERVIEW_BUNDLE_TARGET}"

# --------------------------------------------------
# 3.7 部署 workflow 腳本（v7.0.0 · workflow-first 編排）
# --------------------------------------------------

echo "--- 部署 workflow 腳本（dev-prd / dev-design / dev-review / dev-verify）---"

WORKFLOWS_DIR="$HOME/.claude/workflows"
WORKFLOWS_SOURCE="$SOURCE_DIR/dev-closed-loop/workflows"
WORKFLOW_FILES=("dev-prd.js" "dev-design.js" "dev-review.js" "dev-verify.js")

if [ ! -d "$WORKFLOWS_SOURCE" ]; then
    echo "❌ 找不到 workflow 源碼目錄：${WORKFLOWS_SOURCE}"
    exit 1
fi

mkdir -p "$WORKFLOWS_DIR"
for wf in "${WORKFLOW_FILES[@]}"; do
    if [ ! -f "$WORKFLOWS_SOURCE/$wf" ]; then
        echo "❌ 缺少 workflow 腳本：${WORKFLOWS_SOURCE}/$wf"
        exit 1
    fi
    cp "$WORKFLOWS_SOURCE/$wf" "$WORKFLOWS_DIR/$wf"
done

echo "✅ 4 個 workflow 腳本已部署到 ${WORKFLOWS_DIR}（/dev-prd /dev-design /dev-review /dev-verify）"
echo "   ⚠️ workflow 需 Claude Code v2.1.154+ · 付費方案 · research preview；不可用時方法論走退化路徑（CLAUDE.md Section 14）"

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

# 確認 dev:handoff 完整（shim + bundle）
HANDOFF_BUNDLE_FILES=(
    "SKILL.md"
    "references/path-resolution.md"
    "references/conflict-resolution.md"
    "references/save-mode.md"
    "references/load-mode.md"
    "references/templates.md"
)
HANDOFF_OK=true
HANDOFF_COUNT=0
if [ ! -f "$HANDOFF_SHIM_TARGET" ]; then
    echo "❌ 缺少 dev:handoff shim：$HANDOFF_SHIM_TARGET"
    HANDOFF_OK=false
fi
for f in "${HANDOFF_BUNDLE_FILES[@]}"; do
    if [ -f "$HANDOFF_BUNDLE_TARGET/$f" ]; then
        HANDOFF_COUNT=$((HANDOFF_COUNT + 1))
    else
        echo "❌ 缺少 dev:handoff bundle 檔案：$f"
        HANDOFF_OK=false
    fi
done
if $HANDOFF_OK; then
    echo "✅ dev:handoff 完整（shim + bundle ${HANDOFF_COUNT}/${#HANDOFF_BUNDLE_FILES[@]}）"
fi

# 確認 dev:overview 完整（shim + bundle）
OVERVIEW_BUNDLE_FILES=(
    "SKILL.md"
    "references/content-spec.md"
    "references/source-mapping.md"
    "references/visual-guide.md"
    "references/template.html"
)
OVERVIEW_OK=true
OVERVIEW_COUNT=0
if [ ! -f "$OVERVIEW_SHIM_TARGET" ]; then
    echo "❌ 缺少 dev:overview shim：$OVERVIEW_SHIM_TARGET"
    OVERVIEW_OK=false
fi
for f in "${OVERVIEW_BUNDLE_FILES[@]}"; do
    if [ -f "$OVERVIEW_BUNDLE_TARGET/$f" ]; then
        OVERVIEW_COUNT=$((OVERVIEW_COUNT + 1))
    else
        echo "❌ 缺少 dev:overview bundle 檔案：$f"
        OVERVIEW_OK=false
    fi
done
if $OVERVIEW_OK; then
    echo "✅ dev:overview 完整（shim + bundle ${OVERVIEW_COUNT}/${#OVERVIEW_BUNDLE_FILES[@]}）"
fi

# 確認舊版 colon-skill 已清除（遷移驗證）
for old in "$LEGACY_SKILLS_DIR/dev:handoff" "$LEGACY_SKILLS_DIR/dev:overview"; do
    if [ -d "$old" ]; then
        echo "⚠️  舊版 skill 仍存在（遷移未完成）：$old"
    fi
done

# 確認 workflow 腳本完整（v7.0.0）
WORKFLOW_OK=true
WORKFLOW_COUNT=0
for wf in "${WORKFLOW_FILES[@]}"; do
    if [ -f "$WORKFLOWS_DIR/$wf" ]; then
        WORKFLOW_COUNT=$((WORKFLOW_COUNT + 1))
    else
        echo "❌ 缺少 workflow 腳本：$wf"
        WORKFLOW_OK=false
    fi
done
if $WORKFLOW_OK; then
    echo "✅ workflow 腳本完整（${WORKFLOW_COUNT}/${#WORKFLOW_FILES[@]}）"
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

# 確認 hooks 完整（5 個 hook + 1 個共用 helpers）
HOOK_FILES=(
    "hooks/impact-analysis-guard.sh"
    "hooks/causal-chain-reset.sh"
    "hooks/incremental-lint.sh"
    "hooks/delegation-tracker.sh"
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
echo "現在可以在任何專案目錄執行 /dev:init-claude 來部署閉環（v7.0.0 · workflow-first）。"
echo "也可以用 /dev:handoff save / load 跨 session 交接（功能等價 wt:handoff）。"
echo "或執行 /dev:overview 產生方法論視覺化介紹 HTML（給人類看）。"
echo "大型/PRD/架構設計可用 workflow：/dev-prd /dev-design /dev-review /dev-verify"
echo "  （需 Claude Code v2.1.154+ · 付費方案 · research preview；不可用則走退化路徑）"
echo ""
if [ "$INSTALL_MODE" = "local" ]; then
    echo "更新流程：git pull → bash setup.sh"
else
    echo "更新流程：執行 /dev:init-claude upgrade（自動從 GitHub 下載最新版）"
    echo "  或重新執行：curl -sL https://raw.githubusercontent.com/${GITHUB_REPO}/main/setup.sh | bash"
fi

}

main "$@"
