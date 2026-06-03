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
# Check 5.5: dev:handoff 部署（command shim + bundle · v7.1.0 改 command 形式）
#   shim   → $HOME/.claude/commands/dev/handoff.md（提供 /dev:handoff 冒號名）
#   bundle → $HOME/.claude/dev-closed-loop/handoff/（commands/skills 之外）
# --------------------------------------------------
echo ""
echo "Check 5.5: dev:handoff command shim + bundle 部署"
HANDOFF_SHIM="$TEST_HOME/.claude/commands/dev/handoff.md"
HANDOFF_BUNDLE="$TEST_HOME/.claude/dev-closed-loop/handoff"
HANDOFF_EXPECTED=(
    "SKILL.md"
    "references/path-resolution.md"
    "references/conflict-resolution.md"
    "references/save-mode.md"
    "references/load-mode.md"
    "references/templates.md"
)
if [ -f "$HANDOFF_SHIM" ]; then
    echo "  ✅ command shim 部署落地：commands/dev/handoff.md"
else
    echo "  ❌ 缺少 command shim：commands/dev/handoff.md"
    FAIL=$((FAIL+1))
fi
HANDOFF_MISSING=0
for f in "${HANDOFF_EXPECTED[@]}"; do
    if [ ! -f "$HANDOFF_BUNDLE/$f" ]; then
        echo "  ❌ 缺少 bundle 檔案：$f"
        HANDOFF_MISSING=$((HANDOFF_MISSING+1))
    fi
done
if [ $HANDOFF_MISSING -eq 0 ]; then
    echo "  ✅ dev:handoff bundle 6 個檔案全部部署落地"
else
    FAIL=$((FAIL+1))
fi

# 指令名稱無 /wt:handoff 殘留（shim + bundle 全檢；裸 wt:handoff 等價關係是 intended）
HANDOFF_LEAK=0
if [ -f "$HANDOFF_SHIM" ] && grep -q "/wt:handoff" "$HANDOFF_SHIM"; then
    echo "  ❌ shim 仍有 /wt:handoff 指令殘留"
    HANDOFF_LEAK=$((HANDOFF_LEAK+1))
fi
for f in "${HANDOFF_EXPECTED[@]}"; do
    if [ -f "$HANDOFF_BUNDLE/$f" ] && grep -q "/wt:handoff" "$HANDOFF_BUNDLE/$f"; then
        echo "  ❌ $f 仍有 /wt:handoff 指令殘留"
        HANDOFF_LEAK=$((HANDOFF_LEAK+1))
    fi
done
if [ $HANDOFF_LEAK -eq 0 ]; then
    echo "  ✅ shim + bundle 無 /wt:handoff 指令殘留"
else
    FAIL=$((FAIL+1))
fi

# shim frontmatter name 正確（決定 /dev:handoff 冒號名）
if [ -f "$HANDOFF_SHIM" ]; then
    if grep -q "^name: dev:handoff$" "$HANDOFF_SHIM"; then
        echo "  ✅ shim frontmatter name 正確"
    else
        echo "  ❌ shim frontmatter name 異常"
        FAIL=$((FAIL+1))
    fi
fi

# shim → bundle 契約：shim 必須指向 bundle SKILL.md
if [ -f "$HANDOFF_SHIM" ] && grep -q "dev-closed-loop/handoff/SKILL.md" "$HANDOFF_SHIM"; then
    echo "  ✅ shim 正確指向 bundle SKILL.md"
else
    echo "  ❌ shim 未指向 bundle SKILL.md"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 5.6: dev:overview 部署（command shim + bundle · v7.1.0 改 command 形式）
# --------------------------------------------------
echo ""
echo "Check 5.6: dev:overview command shim + bundle 部署"
OVERVIEW_SHIM="$TEST_HOME/.claude/commands/dev/overview.md"
OVERVIEW_BUNDLE="$TEST_HOME/.claude/dev-closed-loop/overview"
OVERVIEW_EXPECTED=(
    "SKILL.md"
    "references/content-spec.md"
    "references/source-mapping.md"
    "references/visual-guide.md"
    "references/template.html"
)
if [ -f "$OVERVIEW_SHIM" ]; then
    echo "  ✅ command shim 部署落地：commands/dev/overview.md"
else
    echo "  ❌ 缺少 command shim：commands/dev/overview.md"
    FAIL=$((FAIL+1))
fi
OVERVIEW_MISSING=0
for f in "${OVERVIEW_EXPECTED[@]}"; do
    if [ ! -f "$OVERVIEW_BUNDLE/$f" ]; then
        echo "  ❌ 缺少 bundle 檔案：$f"
        OVERVIEW_MISSING=$((OVERVIEW_MISSING+1))
    fi
done
if [ $OVERVIEW_MISSING -eq 0 ]; then
    echo "  ✅ dev:overview bundle 5 個檔案全部部署落地"
else
    FAIL=$((FAIL+1))
fi

# 內容驗證：template.html 含關鍵 placeholder + light/dark CSS variables
if [ -f "$OVERVIEW_BUNDLE/references/template.html" ]; then
    if grep -q "{{DEPLOYMENT_VERSION}}" "$OVERVIEW_BUNDLE/references/template.html"; then
        echo "  ✅ template.html 含 placeholder（未在部署時誤替換）"
    else
        echo "  ❌ template.html 缺少 {{DEPLOYMENT_VERSION}} placeholder"
        FAIL=$((FAIL+1))
    fi
    if grep -q '\[data-theme="dark"\]' "$OVERVIEW_BUNDLE/references/template.html"; then
        echo "  ✅ template.html 含 light/dark mode CSS"
    else
        echo "  ❌ template.html 缺少 dark mode CSS"
        FAIL=$((FAIL+1))
    fi
fi

# shim frontmatter name + 指向 bundle 契約
if [ -f "$OVERVIEW_SHIM" ]; then
    if grep -q "^name: dev:overview$" "$OVERVIEW_SHIM"; then
        echo "  ✅ shim frontmatter name 正確"
    else
        echo "  ❌ shim frontmatter name 異常"
        FAIL=$((FAIL+1))
    fi
    if grep -q "dev-closed-loop/overview/SKILL.md" "$OVERVIEW_SHIM"; then
        echo "  ✅ shim 正確指向 bundle SKILL.md"
    else
        echo "  ❌ shim 未指向 bundle SKILL.md"
        FAIL=$((FAIL+1))
    fi
fi

# --------------------------------------------------
# Check 5.6b: 升級遷移——舊版 colon-skill 目錄被清除（v7.1.0）
#   模擬已安裝舊版（冒號目錄 skill），再跑一次 setup，驗證舊目錄被移除且 command 形式保留
# --------------------------------------------------
echo ""
echo "Check 5.6b: 舊版 colon-skill 遷移清理"
mkdir -p "$TEST_HOME/.claude/skills/dev:handoff" "$TEST_HOME/.claude/skills/dev:overview"
echo "stale" > "$TEST_HOME/.claude/skills/dev:handoff/SKILL.md"
echo "stale" > "$TEST_HOME/.claude/skills/dev:overview/SKILL.md"
HOME="$TEST_HOME" bash "$REPO_ROOT/setup.sh" >/dev/null 2>&1 || true
MIGRATION_OK=true
for old in "$TEST_HOME/.claude/skills/dev:handoff" "$TEST_HOME/.claude/skills/dev:overview"; do
    if [ -d "$old" ]; then
        echo "  ❌ 舊版 skill 未被清除：$old"
        MIGRATION_OK=false
    fi
done
if [ ! -f "$TEST_HOME/.claude/commands/dev/handoff.md" ]; then
    echo "  ❌ 遷移後 command shim 遺失"
    MIGRATION_OK=false
fi
if $MIGRATION_OK; then
    echo "  ✅ 舊版 colon-skill 已清除，command 形式保留"
else
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 5.7: workflow 腳本部署到 $HOME/.claude/workflows/（v7.0.0）
# --------------------------------------------------
echo ""
echo "Check 5.7: workflow 腳本部署"
WORKFLOWS_DIR="$TEST_HOME/.claude/workflows"
WORKFLOW_EXPECTED=(
    "dev-prd.js"
    "dev-design.js"
    "dev-review.js"
    "dev-verify.js"
)
WORKFLOW_MISSING=0
for f in "${WORKFLOW_EXPECTED[@]}"; do
    if [ ! -f "$WORKFLOWS_DIR/$f" ]; then
        echo "  ❌ 缺少：$f"
        WORKFLOW_MISSING=$((WORKFLOW_MISSING+1))
    fi
done
if [ $WORKFLOW_MISSING -eq 0 ]; then
    echo "  ✅ 4 個 workflow 腳本全部部署落地"
else
    FAIL=$((FAIL+1))
fi

# 內容驗證：每個腳本含 meta.name（部署的是真腳本，非空檔/截斷）
WORKFLOW_BAD_META=0
for f in "${WORKFLOW_EXPECTED[@]}"; do
    expected_name="${f%.js}"
    if [ -f "$WORKFLOWS_DIR/$f" ] && ! grep -q "name: '${expected_name}'" "$WORKFLOWS_DIR/$f"; then
        echo "  ❌ $f 缺少 meta.name: '${expected_name}'"
        WORKFLOW_BAD_META=$((WORKFLOW_BAD_META+1))
    fi
done
if [ $WORKFLOW_BAD_META -eq 0 ]; then
    echo "  ✅ 所有 workflow 腳本 meta.name 正確"
else
    FAIL=$((FAIL+1))
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
