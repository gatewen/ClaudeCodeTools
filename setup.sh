#!/bin/bash
# AI-ClaudeCode 安裝腳本
# 用途：部署 Skill 到 ~/.claude/commands/ 並檢查依賴
# 使用：git clone → cd AI-ClaudeCode → bash setup.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_DIR="$HOME/.claude/commands"
SKILL_SOURCE="$REPO_DIR/dev-closed-loop/skill/init-claude.md"
SKILL_TARGET="$COMMANDS_DIR/dev/init-claude.md"

echo "================================================"
echo "  AI-ClaudeCode 安裝腳本"
echo "================================================"
echo ""
echo "Repo 路徑：$REPO_DIR"
echo ""

# --------------------------------------------------
# 1. 檢查前置條件
# --------------------------------------------------

# 確認 Skill 源碼存在
if [ ! -f "$SKILL_SOURCE" ]; then
    echo "❌ 找不到 Skill 源碼：$SKILL_SOURCE"
    echo "   請確認 repo 檔案完整"
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
# 2. 檢查依賴
# --------------------------------------------------

echo "--- 依賴檢查 ---"
MISSING=""

# 檢查 SuperClaude
if ls "$HOME/.claude/commands/sc/" >/dev/null 2>&1 && [ "$(ls -A "$HOME/.claude/commands/sc/" 2>/dev/null)" ]; then
    echo "✅ SuperClaude 已安裝"
else
    echo "❌ SuperClaude 未安裝"
    MISSING="$MISSING superclaude"
fi

# 檢查 Superpowers
if grep -q "superpowers@claude-plugins-official" "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null; then
    echo "✅ Superpowers 已安裝"
else
    echo "❌ Superpowers 未安裝"
    MISSING="$MISSING superpowers"
fi

# 檢查 claude-mem（可選）
if grep -rq "claude-mem" "$HOME/.claude/plugins/" 2>/dev/null || grep -q "claude-mem" "$HOME/.claude/.mcp.json" 2>/dev/null; then
    echo "✅ claude-mem 已安裝（可選 — 跨時間語義記憶）"
else
    echo "ℹ️  claude-mem 未安裝（可選 — 安裝後可啟用跨時間語義記憶）"
fi

if [ -n "$MISSING" ]; then
    echo ""
    echo "⚠️  以下依賴缺少（閉環需要這些工具才能正常運作）："
    echo ""
    if echo "$MISSING" | grep -q "superclaude"; then
        echo "  SuperClaude："
        echo "    pipx install superclaude && superclaude install"
        echo "    https://github.com/SuperClaude-Org/SuperClaude_Framework"
        echo ""
    fi
    if echo "$MISSING" | grep -q "superpowers"; then
        echo "  Superpowers："
        echo "    在 Claude Code 中安裝插件 superpowers@claude-plugins-official"
        echo ""
    fi
    echo "（Skill 會先安裝，依賴可以之後再補）"
    echo ""
fi

# --------------------------------------------------
# 3. 部署 Skill
# --------------------------------------------------

echo "--- 部署 Skill ---"

# 讀取 Skill 源碼，替換 {{REPO_PATH}} 為實際路徑，寫入目標
sed "s|{{REPO_PATH}}|$REPO_DIR|g" "$SKILL_SOURCE" > "$SKILL_TARGET"

echo "✅ init-claude.md 已部署到 $SKILL_TARGET"

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
if grep -q "$REPO_DIR" "$SKILL_TARGET" 2>/dev/null; then
    echo "✅ 路徑指向 $REPO_DIR"
else
    echo "❌ 路徑替換異常"
    exit 1
fi

# 確認模板檔案可達
if [ -f "$REPO_DIR/dev-closed-loop/CLAUDE_TEMPLATE.md" ]; then
    echo "✅ 模板檔案存在"
else
    echo "❌ 模板檔案不存在：$REPO_DIR/dev-closed-loop/CLAUDE_TEMPLATE.md"
    exit 1
fi

# 確認 .claudedocs 完整
EXPECTED_FILES=(
    "README.md"
    "concepts/閉環核心理念.md"
    "process/五階段閉環流程.md"
    "process/層級擴展.md"
    "process/跨Session持久化.md"
    "process/介面契約與變更管理.md"
    "standards/Agent使用指南.md"
    "standards/Git工作流.md"
    "standards/產出物格式.md"
    "records/問題追蹤.md"
)
DOCS_DIR="$REPO_DIR/dev-closed-loop/.claudedocs"
DOCS_OK=true
for f in "${EXPECTED_FILES[@]}"; do
    if [ ! -f "$DOCS_DIR/$f" ]; then
        echo "❌ 缺少文檔：.claudedocs/$f"
        DOCS_OK=false
    fi
done
if $DOCS_OK; then
    echo "✅ .claudedocs 完整（10/10）"
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
if [ -n "$MISSING" ]; then
    echo "⚠️  記得安裝缺少的依賴，否則閉環的部分功能無法使用。"
    echo ""
fi
echo "更新流程：修改 repo 內容 → git pull → bash setup.sh"
