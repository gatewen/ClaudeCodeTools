#!/usr/bin/env bash
# test-cross-file-consistency.sh
# 驗證跨檔案宣告一致性，防範歷史上最大的失敗類：
#   - 文檔數量陳述（.claudedocs 5/5、hooks 4/4）跨檔案不矛盾
#   - 可選依賴（claude-mem 等）不被誤標為必須
#   - setup.sh 陣列宣告與陣列列出的檔案實際存在
#   - CLAUDE_TEMPLATE.md 版本 marker 與 README 版本歷史一致

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

FAIL=0

count_array_entries() {
    local array_name="$1"
    local file="$2"
    awk -v name="^${array_name}=\\\\(" '$0 ~ name,/^\)/' "$file" \
        | grep -cE '^[[:space:]]+"[^"]+"'
}

# --------------------------------------------------
# Check 1: setup.sh 陣列實際數量 == 對外契約
# --------------------------------------------------
echo "Check 1: setup.sh 陣列數量符合宣告"
SETUP="$REPO_ROOT/setup.sh"

expected_count=$(count_array_entries "EXPECTED_FILES" "$SETUP")
assert_eq "$expected_count" "5" "EXPECTED_FILES 有 5 條（v8 部署包 .claudedocs）" || FAIL=$((FAIL+1))

hook_count=$(count_array_entries "HOOK_FILES" "$SETUP")
assert_eq "$hook_count" "4" "HOOK_FILES 有 4 條（3 hooks + _helpers.sh）" || FAIL=$((FAIL+1))

# v8 起不再部署 agents / languages / overview；陣列不該存在
for gone in AGENT_FILES LANG_FILES OVERVIEW_BUNDLE_FILES; do
    if grep -q "^${gone}=(" "$SETUP"; then
        echo "  ❌ setup.sh 仍含已淘汰的陣列 ${gone}"
        FAIL=$((FAIL+1))
    else
        echo "  ✅ setup.sh 無 ${gone}（v8 已淘汰）"
    fi
done

# --------------------------------------------------
# Check 2: setup.sh 陣列列出的檔案實際存在於 disk
# --------------------------------------------------
echo ""
echo "Check 2: 陣列列出的檔案實際存在"
docs_dir="$REPO_ROOT/dev-closed-loop/.claudedocs"
hook_dir="$REPO_ROOT/dev-closed-loop"
missing=0

while IFS= read -r entry; do
    f="${entry#\"}"; f="${f%\"}"
    [ -z "$f" ] && continue
    if [ ! -f "$docs_dir/$f" ]; then
        echo "  ❌ EXPECTED_FILES 中宣告但檔案不存在：.claudedocs/$f"
        missing=$((missing+1))
    fi
done < <(awk '/^EXPECTED_FILES=\(/,/^\)/' "$SETUP" | grep -oE '"[^"]+"')

while IFS= read -r entry; do
    f="${entry#\"}"; f="${f%\"}"
    [ -z "$f" ] && continue
    if [ ! -f "$hook_dir/$f" ]; then
        echo "  ❌ HOOK_FILES 中宣告但檔案不存在：dev-closed-loop/$f"
        missing=$((missing+1))
    fi
done < <(awk '/^HOOK_FILES=\(/,/^\)/' "$SETUP" | grep -oE '"[^"]+"')

assert_eq "$missing" "0" "所有陣列宣告的檔案皆實際存在" || FAIL=$((FAIL+1))

# 反向：.claudedocs 內不該有陣列沒列的檔案（防止部署包悄悄長回去）
extra=0
while IFS= read -r f; do
    rel="${f#"$docs_dir"/}"
    if ! awk '/^EXPECTED_FILES=\(/,/^\)/' "$SETUP" | grep -qF "\"$rel\""; then
        echo "  ❌ .claudedocs/$rel 存在但未列於 EXPECTED_FILES（部署包不該悄悄長回去）"
        extra=$((extra+1))
    fi
done < <(find "$docs_dir" -type f -name '*.md' | sort)
assert_eq "$extra" "0" ".claudedocs 無未宣告的檔案" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 3: CLAUDE.md 宣告的數量與 setup.sh 一致
# --------------------------------------------------
echo ""
echo "Check 3: CLAUDE.md 文檔數量宣告與 setup.sh 一致"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if grep -qE "\.claudedocs\s*5/5.*hooks\s*4/4" "$CLAUDE_MD"; then
    echo "  ✅ CLAUDE.md 宣告 .claudedocs 5/5 + hooks 4/4（與 setup.sh 一致）"
else
    echo "  ❌ CLAUDE.md 數量宣告與 setup.sh 不符（預期：.claudedocs 5/5 + hooks 4/4）"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 4: 可選依賴不可被任何檔案標為「必須」
# --------------------------------------------------
echo ""
echo "Check 4: SuperClaude/Superpowers/claude-mem 不被誤標為必須"

DOCS=(
    "$REPO_ROOT/README.md"
    "$REPO_ROOT/CLAUDE.md"
    "$REPO_ROOT/dev-closed-loop/README.md"
    "$REPO_ROOT/setup.sh"
)
TOOLS=(SuperClaude Superpowers claude-mem)
violations=0

for doc in "${DOCS[@]}"; do
    [ -f "$doc" ] || continue
    for tool in "${TOOLS[@]}"; do
        if grep -qE "${tool}.*(必須安裝|required to install|需要安裝.*${tool})" "$doc" 2>/dev/null; then
            echo "  ❌ $doc 將 ${tool} 標為必須"
            violations=$((violations+1))
        fi
        if grep -qE "(必須安裝|required to install|需要安裝).*${tool}" "$doc" 2>/dev/null; then
            echo "  ❌ $doc 將 ${tool} 標為必須（反向句式）"
            violations=$((violations+1))
        fi
    done
done

assert_eq "$violations" "0" "可選依賴皆未被誤標為必須" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 5: 版本 marker 與 README 版本歷史一致
# --------------------------------------------------
echo ""
echo "Check 5: CLAUDE_TEMPLATE.md 版本 marker 與 README 一致"
TEMPLATE="$REPO_ROOT/dev-closed-loop/CLAUDE_TEMPLATE.md"
marker=$(grep -o 'closed-loop v[0-9.]*' "$TEMPLATE" 2>/dev/null | tail -1 | sed 's/closed-loop v//')
if [ -n "$marker" ]; then
    echo "  ✅ marker 版本：v${marker}"
    for doc in "$REPO_ROOT/README.md" "$REPO_ROOT/dev-closed-loop/README.md"; do
        if grep -qF "v${marker}" "$doc"; then
            echo "  ✅ $(basename "$(dirname "$doc")")/$(basename "$doc") 含 v${marker}"
        else
            echo "  ❌ $doc 未提及 v${marker}（版本歷史漏更新）"
            FAIL=$((FAIL+1))
        fi
    done
else
    echo "  ❌ CLAUDE_TEMPLATE.md 缺少 closed-loop vX.Y.Z marker"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Result
# --------------------------------------------------
echo ""
if [ $FAIL -eq 0 ]; then
    echo "All consistency checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
