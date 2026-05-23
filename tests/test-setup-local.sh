#!/usr/bin/env bash
# test-setup-local.sh
# 本地模式 happy path：偵測 + 部署 + placeholder + 路徑指向 repo（不是 cache）
# 順便抽查 check-version.sh 對未部署狀態的判定

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"
# shellcheck source=lib/fixtures.sh
source "$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0

# 隔離 HOME 避免污染真實 ~/.claude
TEST_HOME=$(make_tmpdir)

echo "Running setup.sh in local mode（HOME=${TEST_HOME}）..."
output=$(
    HOME="$TEST_HOME" bash "$REPO_ROOT/setup.sh" 2>&1 || true
)

# --------------------------------------------------
# Check 1: 偵測為 local 模式（不是 remote）
# --------------------------------------------------
echo ""
echo "Check 1: 模式偵測為 local"
if echo "$output" | grep -q "模式：本地安裝"; then
    echo "  ✅ local 模式正確偵測"
else
    echo "  ❌ 未偵測到 local 模式"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 2: skill 部署到 $HOME/.claude/commands/dev/init-claude.md
# --------------------------------------------------
echo ""
echo "Check 2: skill 已部署"
SKILL="$TEST_HOME/.claude/commands/dev/init-claude.md"
assert_file_exists "$SKILL" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 3: placeholder 已替換
# --------------------------------------------------
echo ""
echo "Check 3: placeholder 替換完成"
if [ -f "$SKILL" ]; then
    if grep -q "{{REPO_PATH}}" "$SKILL"; then
        echo "  ❌ {{REPO_PATH}} 殘留"
        FAIL=$((FAIL+1))
    else
        echo "  ✅ 無 placeholder 殘留"
    fi
fi

# --------------------------------------------------
# Check 4: REPO_PATH placeholder 替換為 repo 路徑（不是 cache）
# 注意：skill 源碼文檔本來就有 mention cache 路徑（解釋 upgrade 模式），不可全文 grep
# 只能驗證「{{REPO_PATH}} 替換結果為 repo 路徑」這個關鍵契約
# --------------------------------------------------
echo ""
echo "Check 4: skill 中 REPO_PATH 被替換為 repo（不是 cache）"
if [ -f "$SKILL" ]; then
    if grep -qF "$REPO_ROOT" "$SKILL"; then
        echo "  ✅ skill 含 repo 路徑 $REPO_ROOT"
    else
        echo "  ❌ skill 不含 repo 路徑（local 模式 placeholder 替換失敗）"
        FAIL=$((FAIL+1))
    fi
fi

# --------------------------------------------------
# Check 5: setup.sh 訊息中宣告路徑也是 repo
# --------------------------------------------------
echo ""
echo "Check 5: setup.sh 顯示來源路徑為 repo"
if echo "$output" | grep -qF "來源路徑：$REPO_ROOT"; then
    echo "  ✅ 來源路徑正確"
else
    echo "  ❌ 來源路徑顯示異常"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 5.5: dev:handoff Skill 部署到 $HOME/.claude/skills/dev:handoff/
# --------------------------------------------------
echo ""
echo "Check 5.5: dev:handoff Skill 部署"
HANDOFF_DIR="$TEST_HOME/.claude/skills/dev:handoff"
HANDOFF_EXPECTED=(
    "SKILL.md"
    "references/path-resolution.md"
    "references/conflict-resolution.md"
    "references/save-mode.md"
    "references/load-mode.md"
    "references/templates.md"
)
HANDOFF_MISSING=0
for f in "${HANDOFF_EXPECTED[@]}"; do
    if [ ! -f "$HANDOFF_DIR/$f" ]; then
        echo "  ❌ 缺少：$f"
        HANDOFF_MISSING=$((HANDOFF_MISSING+1))
    fi
done
if [ $HANDOFF_MISSING -eq 0 ]; then
    echo "  ✅ dev:handoff Skill 6 個檔案全部部署落地"
else
    FAIL=$((FAIL+1))
fi

# dev:handoff 內容驗證：指令名稱無 /wt:handoff 殘留（preamble 提及 wt:handoff 等價關係是 intended）
# 規則：「`/wt:handoff`」斜杠指令字串應全部替換為「`/dev:handoff`」；裸 `wt:handoff` namespace 引用允許保留
HANDOFF_LEAK=0
for f in "${HANDOFF_EXPECTED[@]}"; do
    if [ -f "$HANDOFF_DIR/$f" ] && grep -q "/wt:handoff" "$HANDOFF_DIR/$f"; then
        echo "  ❌ $f 仍有 /wt:handoff 指令殘留"
        HANDOFF_LEAK=$((HANDOFF_LEAK+1))
    fi
done
if [ $HANDOFF_LEAK -eq 0 ]; then
    echo "  ✅ 所有檔案無 /wt:handoff 指令殘留"
else
    FAIL=$((FAIL+1))
fi

if [ -f "$HANDOFF_DIR/SKILL.md" ]; then
    if grep -q "^name: dev:handoff$" "$HANDOFF_DIR/SKILL.md"; then
        echo "  ✅ SKILL.md frontmatter name 正確"
    else
        echo "  ❌ SKILL.md frontmatter name 異常"
        FAIL=$((FAIL+1))
    fi
fi

# --------------------------------------------------
# Check 5.6: dev:overview Skill 部署到 $HOME/.claude/skills/dev:overview/
# --------------------------------------------------
echo ""
echo "Check 5.6: dev:overview Skill 部署"
OVERVIEW_DIR="$TEST_HOME/.claude/skills/dev:overview"
OVERVIEW_EXPECTED=(
    "SKILL.md"
    "references/content-spec.md"
    "references/source-mapping.md"
    "references/visual-guide.md"
    "references/template.html"
)
OVERVIEW_MISSING=0
for f in "${OVERVIEW_EXPECTED[@]}"; do
    if [ ! -f "$OVERVIEW_DIR/$f" ]; then
        echo "  ❌ 缺少：$f"
        OVERVIEW_MISSING=$((OVERVIEW_MISSING+1))
    fi
done
if [ $OVERVIEW_MISSING -eq 0 ]; then
    echo "  ✅ dev:overview Skill 5 個檔案全部部署落地"
else
    FAIL=$((FAIL+1))
fi

# 內容驗證：template.html 含關鍵 placeholder + light/dark CSS variables
if [ -f "$OVERVIEW_DIR/references/template.html" ]; then
    if grep -q "{{DEPLOYMENT_VERSION}}" "$OVERVIEW_DIR/references/template.html"; then
        echo "  ✅ template.html 含 placeholder（未在部署時誤替換）"
    else
        echo "  ❌ template.html 缺少 {{DEPLOYMENT_VERSION}} placeholder"
        FAIL=$((FAIL+1))
    fi
    if grep -q '\[data-theme="dark"\]' "$OVERVIEW_DIR/references/template.html"; then
        echo "  ✅ template.html 含 light/dark mode CSS"
    else
        echo "  ❌ template.html 缺少 dark mode CSS"
        FAIL=$((FAIL+1))
    fi
fi

if [ -f "$OVERVIEW_DIR/SKILL.md" ]; then
    if grep -q "^name: dev:overview$" "$OVERVIEW_DIR/SKILL.md"; then
        echo "  ✅ SKILL.md frontmatter name 正確"
    else
        echo "  ❌ SKILL.md frontmatter name 異常"
        FAIL=$((FAIL+1))
    fi
fi

# --------------------------------------------------
# Check 6: 抽查 check-version.sh 對未部署狀態判定
# --------------------------------------------------
echo ""
echo "Check 6: check-version.sh 未部署狀態判定"
NONEXISTENT="/tmp/this-does-not-exist-$$.md"
cv_output=$(bash "$REPO_ROOT/dev-closed-loop/check-version.sh" "$REPO_ROOT" --deployed "$NONEXISTENT" 2>&1 || true)
if echo "$cv_output" | grep -q "STATUS=not_deployed"; then
    echo "  ✅ 未部署 → STATUS=not_deployed"
else
    echo "  ❌ check-version 未產出 not_deployed 狀態"
    echo "    output: $cv_output"
    FAIL=$((FAIL+1))
fi
if echo "$cv_output" | grep -qE "CACHE_VERSION=[0-9]+\.[0-9]+"; then
    echo "  ✅ CACHE_VERSION 提取成功"
else
    echo "  ❌ CACHE_VERSION 提取失敗"
    echo "    output: $cv_output"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Diagnostic
# --------------------------------------------------
if [ $FAIL -gt 0 ]; then
    echo ""
    echo "--- setup.sh output（前 30 行）---"
    echo "$output" | head -30
    echo "--- end ---"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "All local-install checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
