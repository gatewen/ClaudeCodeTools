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
# Check 5.5: dev:handoff 部署（command shim + bundle）
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

# shim 不應帶顯式 name（指令名由路徑 commands/dev/ 合成；顯式含冒號 name 曾致 Windows 不註冊）
if [ -f "$HANDOFF_SHIM" ]; then
    if grep -q "^name:" "$HANDOFF_SHIM"; then
        echo "  ❌ shim 帶顯式 name 欄位（應移除，靠路徑合成 /dev:handoff）"
        FAIL=$((FAIL+1))
    else
        echo "  ✅ shim 無顯式 name（指令名靠路徑合成）"
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
# Check 5.6: v8 起 dev:overview 不再部署，且舊安裝殘留被清除
#   模擬 v7.0.x（冒號目錄 skill）與 v7.1.x（command shim + bundle）殘留，再跑一次 setup
# --------------------------------------------------
echo ""
echo "Check 5.6: 舊版殘留遷移清理（colon-skill + dev:overview）"
mkdir -p "$TEST_HOME/.claude/skills/dev:handoff" "$TEST_HOME/.claude/skills/dev:overview"
echo "stale" > "$TEST_HOME/.claude/skills/dev:handoff/SKILL.md"
echo "stale" > "$TEST_HOME/.claude/skills/dev:overview/SKILL.md"
mkdir -p "$TEST_HOME/.claude/dev-closed-loop/overview/references"
echo "stale" > "$TEST_HOME/.claude/dev-closed-loop/overview/SKILL.md"
echo "stale" > "$TEST_HOME/.claude/commands/dev/overview.md"
HOME="$TEST_HOME" bash "$REPO_ROOT/setup.sh" >/dev/null 2>&1 || true
MIGRATION_OK=true
for old in "$TEST_HOME/.claude/skills/dev:handoff" "$TEST_HOME/.claude/skills/dev:overview" "$TEST_HOME/.claude/dev-closed-loop/overview"; do
    if [ -d "$old" ]; then
        echo "  ❌ 舊版殘留未被清除：$old"
        MIGRATION_OK=false
    fi
done
if [ -f "$TEST_HOME/.claude/commands/dev/overview.md" ]; then
    echo "  ❌ 舊版 /dev:overview command shim 未被清除"
    MIGRATION_OK=false
fi
if [ ! -f "$TEST_HOME/.claude/commands/dev/handoff.md" ]; then
    echo "  ❌ 遷移後 handoff command shim 遺失"
    MIGRATION_OK=false
fi
if $MIGRATION_OK; then
    echo "  ✅ 舊版 colon-skill 與 dev:overview 已清除，handoff command 形式保留"
else
    FAIL=$((FAIL+1))
fi

# 源碼側：repo 不該再含 overview 源碼
if [ -e "$REPO_ROOT/dev-closed-loop/commands/dev/overview.md" ] || [ -d "$REPO_ROOT/dev-closed-loop/command-refs/overview" ]; then
    echo "  ❌ repo 仍含 dev:overview 源碼（v8 已移除）"
    FAIL=$((FAIL+1))
else
    echo "  ✅ repo 無 dev:overview 源碼"
fi

# --------------------------------------------------
# Check 5.6c: shim frontmatter 必須為合法 YAML（防單行純量 ": " 致命回歸）
# --------------------------------------------------
echo ""
echo "Check 5.6c: command shim frontmatter YAML 合法性"
if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
    if [ -f "$HANDOFF_SHIM" ]; then
        if python3 - "$HANDOFF_SHIM" <<'PY'
import sys, re, yaml
t = open(sys.argv[1], encoding='utf-8').read()
m = re.match(r'^---\n(.*?)\n---\n', t, re.S)
try:
    ok = m is not None and isinstance(yaml.safe_load(m.group(1)), dict)
except Exception:
    ok = False
sys.exit(0 if ok else 1)
PY
        then
            echo "  ✅ handoff.md frontmatter 合法 YAML"
        else
            echo "  ❌ handoff.md frontmatter YAML 解析失敗"
            FAIL=$((FAIL+1))
        fi
    fi
else
    echo "  ⏭️  跳過（無 python3 / pyyaml；frontmatter YAML 驗證需要）"
fi

# --------------------------------------------------
# Check 5.7: workflow 腳本部署到 $HOME/.claude/workflows/
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

# 語法驗證：node 可用時 --check 每個腳本。
#   Workflow 執行環境會把腳本包進 async 函式（所以腳本可用頂層 return 與 await），
#   直接 --check 會報 Illegal return；這裡仿照包一層再檢查，並把 export 拿掉。
if command -v node >/dev/null 2>&1; then
    WORKFLOW_SYNTAX_BAD=0
    WF_TMP="$(make_tmpdir)"
    for f in "${WORKFLOW_EXPECTED[@]}"; do
        wrapped="$WF_TMP/${f%.js}.wrapped.js"
        {
            printf 'async function __wf(agent, parallel, pipeline, phase, args) {\n'
            sed 's/^export const meta/const meta/' "$REPO_ROOT/dev-closed-loop/workflows/$f"
            printf '\n}\n'
        } > "$wrapped"
        if ! node --check "$wrapped" >/dev/null 2>&1; then
            echo "  ❌ $f 語法錯誤（node --check，已包 async 函式）"
            WORKFLOW_SYNTAX_BAD=$((WORKFLOW_SYNTAX_BAD+1))
        fi
    done
    if [ $WORKFLOW_SYNTAX_BAD -eq 0 ]; then
        echo "  ✅ 所有 workflow 腳本通過 node --check"
    else
        FAIL=$((FAIL+1))
    fi
else
    echo "  ⏭️  跳過 node --check（無 node）"
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
