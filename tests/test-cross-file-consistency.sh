#!/usr/bin/env bash
# test-cross-file-consistency.sh
# 驗證跨檔案宣告一致性，防範 codex_recommand.md 揭露的歷史最大失敗類：
#   - 文檔數量陳述（17/17, 9/9, 7/7）跨檔案不矛盾
#   - 可選依賴（SuperClaude/Superpowers/claude-mem）不被誤標為必須
#   - setup.sh 陣列宣告與宣告數字一致

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
# Check 1: setup.sh 陣列實際數量 == 用戶可見訊息宣告
# --------------------------------------------------
echo "Check 1: setup.sh 陣列數量符合宣告"
SETUP="$REPO_ROOT/setup.sh"

expected_count=$(count_array_entries "EXPECTED_FILES" "$SETUP")
assert_eq "$expected_count" "17" "EXPECTED_FILES 有 17 條" || FAIL=$((FAIL+1))

agent_count=$(count_array_entries "AGENT_FILES" "$SETUP")
assert_eq "$agent_count" "9" "AGENT_FILES 有 9 條" || FAIL=$((FAIL+1))

lang_count=$(count_array_entries "LANG_FILES" "$SETUP")
assert_eq "$lang_count" "7" "LANG_FILES 有 7 條" || FAIL=$((FAIL+1))

hook_count=$(count_array_entries "HOOK_FILES" "$SETUP")
assert_eq "$hook_count" "6" "HOOK_FILES 有 6 條（5 hooks + _helpers.sh）" || FAIL=$((FAIL+1))

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
    if [ ! -f "$docs_dir/$f" ]; then
        echo "  ❌ AGENT_FILES 中宣告但檔案不存在：.claudedocs/$f"
        missing=$((missing+1))
    fi
done < <(awk '/^AGENT_FILES=\(/,/^\)/' "$SETUP" | grep -oE '"[^"]+"')

while IFS= read -r entry; do
    f="${entry#\"}"; f="${f%\"}"
    [ -z "$f" ] && continue
    if [ ! -f "$docs_dir/$f" ]; then
        echo "  ❌ LANG_FILES 中宣告但檔案不存在：.claudedocs/$f"
        missing=$((missing+1))
    fi
done < <(awk '/^LANG_FILES=\(/,/^\)/' "$SETUP" | grep -oE '"[^"]+"')

while IFS= read -r entry; do
    f="${entry#\"}"; f="${f%\"}"
    [ -z "$f" ] && continue
    if [ ! -f "$hook_dir/$f" ]; then
        echo "  ❌ HOOK_FILES 中宣告但檔案不存在：dev-closed-loop/$f"
        missing=$((missing+1))
    fi
done < <(awk '/^HOOK_FILES=\(/,/^\)/' "$SETUP" | grep -oE '"[^"]+"')

assert_eq "$missing" "0" "所有陣列宣告的檔案皆實際存在" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 3: CLAUDE.md 宣告的數量與 setup.sh 一致
# --------------------------------------------------
echo ""
echo "Check 3: CLAUDE.md 文檔數量宣告與 setup.sh 一致"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if grep -qE "核心\s*17/17.*agents\s*9/9.*languages\s*7/7" "$CLAUDE_MD"; then
    echo "  ✅ CLAUDE.md 宣告 17/17 + 9/9 + 7/7（與 setup.sh 一致）"
else
    echo "  ❌ CLAUDE.md 數量宣告與 setup.sh 不符（預期：核心 17/17 + agents 9/9 + languages 7/7）"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 4: 可選依賴不可被任何檔案標為「必須」
# --------------------------------------------------
echo ""
echo "Check 4: SuperClaude/Superpowers/claude-mem 不被誤標為必須"

# 只檢查使用者可見的 prose 檔案（README/CLAUDE.md），略過 design history（含早期討論）
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
        # 任何將 tool 標為「必須安裝」「required」「需要安裝」的句式都違反
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
# Result
# --------------------------------------------------
echo ""
if [ $FAIL -eq 0 ]; then
    echo "All consistency checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
