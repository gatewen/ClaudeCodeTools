#!/usr/bin/env bash
# test-cross-file-consistency.sh
# 驗證跨檔案宣告一致性，防範歷史上最大的失敗類：
#   - 文檔數量陳述（.claudedocs 5/5、hooks 4/4）跨檔案不矛盾
#   - 可選依賴（claude-mem 等）不被誤標為必須
#   - setup.sh 陣列宣告與陣列列出的檔案實際存在
#   - CLAUDE_TEMPLATE.md 版本 marker 與 README 版本歷史一致
#   - workflow 腳本內 TIERS / ARCH_RULES 常數多份相同，且與模板對應段落一致（SSOT 第三層）
#   - 模板行數在對外宣稱範圍內

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
# Check 6: 四支 workflow 的 TIERS 常數彼此相同，且與模板「模型分配」表一致
#   SSOT 第三層：workflow 腳本不能 import，等級表各放一份，用測試逼一致
# --------------------------------------------------
echo ""
echo "Check 6: workflow TIERS 常數四份相同且與模板模型分配表一致"
WF_DIR="$REPO_ROOT/dev-closed-loop/workflows"
WF_FILES=(dev-prd.js dev-design.js dev-review.js dev-verify.js)

# 印出從「符合 $2 的行」到第一個只含 } 或只含反引號的行
extract_block() {
    awk -v start="$2" '$0 ~ start {p=1} p {print} p && (/^}/ || /^`$/) {exit}' "$1"
}

tiers_ref=""
tiers_bad=0
for f in "${WF_FILES[@]}"; do
    blk=$(extract_block "$WF_DIR/$f" '^const TIERS = ')
    if [ -z "$blk" ]; then
        echo "  ❌ $f 缺少 const TIERS 區塊"
        tiers_bad=$((tiers_bad+1))
        continue
    fi
    if [ -z "$tiers_ref" ]; then
        tiers_ref="$blk"
    elif [ "$blk" != "$tiers_ref" ]; then
        echo "  ❌ $f 的 TIERS 與 ${WF_FILES[0]} 不同"
        tiers_bad=$((tiers_bad+1))
    fi
done
assert_eq "$tiers_bad" "0" "TIERS 四份存在且逐字相同" || FAIL=$((FAIL+1))

# 與模板表對照：low → 「| 低 |」列須含 model 與 effort 值；mid → 「| 中 |」；high 為 {} → 「| 高 |」列須寫「不指定」
tiers_mismatch=0
check_tier() {
    local key="$1" zh="$2" line row val kv
    line=$(printf '%s\n' "$tiers_ref" | grep -E "^  ${key}:")
    row=$(grep -E "^\| ${zh} \|" "$TEMPLATE" | head -1)
    if [ -z "$row" ]; then
        echo "  ❌ 模板缺「| ${zh} |」列"
        tiers_mismatch=$((tiers_mismatch+1))
        return
    fi
    if printf '%s' "$line" | grep -q '{}'; then
        if ! printf '%s' "$row" | grep -q '不指定'; then
            echo "  ❌ ${key} 為繼承主對話，但模板「${zh}」列未寫「不指定」"
            tiers_mismatch=$((tiers_mismatch+1))
        fi
        return
    fi
    for kv in model effort; do
        val=$(printf '%s' "$line" | sed -n "s/.*${kv}: '\([^']*\)'.*/\1/p")
        if [ -z "$val" ]; then
            # 腳本沒設這個鍵，模板該列就不能宣稱它（防止刪掉 effort 後模板仍寫 effort）
            if printf '%s' "$row" | grep -q "$kv"; then
                echo "  ❌ ${key} 腳本未設 ${kv}，但模板「${zh}」列寫了 ${kv}"
                tiers_mismatch=$((tiers_mismatch+1))
            fi
            continue
        fi
        if ! printf '%s' "$row" | grep -qF "$val"; then
            echo "  ❌ ${key} 的 ${kv}='${val}' 未出現在模板「${zh}」列"
            tiers_mismatch=$((tiers_mismatch+1))
        fi
    done
}
if [ -n "$tiers_ref" ]; then
    check_tier low 低
    check_tier mid 中
    check_tier high 高
fi
assert_eq "$tiers_mismatch" "0" "TIERS 與模板模型分配表一致" || FAIL=$((FAIL+1))

# 6b：模板明講的分派承諾（找問題中階、反駁驗證與安全審查高階）要跟 dev-review.js 一致
rv="$WF_DIR/dev-review.js"
pledge_bad=0
grep -qE 'verify:.*TIERS\.high' "$rv" || { echo "  ❌ dev-review verify 未用 TIERS.high（模板承諾反駁驗證走高階）"; pledge_bad=$((pledge_bad+1)); }
grep -A1 "key: 'security'" "$rv" | grep -q "tier: 'high'" || { echo "  ❌ dev-review security lens 不是 tier high"; pledge_bad=$((pledge_bad+1)); }
grep -A1 "key: 'correctness'" "$rv" | grep -q "tier: 'mid'" || { echo "  ❌ dev-review correctness lens 不是 tier mid（模板承諾找問題走中階）"; pledge_bad=$((pledge_bad+1)); }
grep -qE "review-synthesis.*TIERS\.low" "$rv" || { echo "  ❌ dev-review 彙整未用 TIERS.low"; pledge_bad=$((pledge_bad+1)); }
assert_eq "$pledge_bad" "0" "dev-review 分派與模板承諾一致（找問題中 / security 與 verify 高 / 彙整低）" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 7: dev-design / dev-review 的 ARCH_RULES 相同，條目名索引與模板 Section 3 一致，模板有錨點
# --------------------------------------------------
echo ""
echo "Check 7: ARCH_RULES 兩份相同、條目名索引存在於模板、模板有 arch-rules 錨點"
arch_ref=""
arch_bad=0
for f in dev-design.js dev-review.js; do
    blk=$(extract_block "$WF_DIR/$f" '^const ARCH_RULES = ')
    if [ -z "$blk" ]; then
        echo "  ❌ $f 缺少 const ARCH_RULES 區塊"
        arch_bad=$((arch_bad+1))
        continue
    fi
    if [ -z "$arch_ref" ]; then
        arch_ref="$blk"
    elif [ "$blk" != "$arch_ref" ]; then
        echo "  ❌ $f 的 ARCH_RULES 與 dev-design.js 不同"
        arch_bad=$((arch_bad+1))
    fi
done
assert_eq "$arch_bad" "0" "ARCH_RULES 兩份存在且逐字相同" || FAIL=$((FAIL+1))

if grep -q '<!-- arch-rules -->' "$TEMPLATE"; then
    echo "  ✅ 模板含 arch-rules 錨點"
else
    echo "  ❌ 模板缺 <!-- arch-rules --> 錨點（workflow 靠它定位審查標準）"
    FAIL=$((FAIL+1))
fi

# 索引名：ARCH_RULES 內「逐條當標準（A / B / C）」括號裡的每一項，模板都要有對應的 **A 粗體條目
name_missing=0
names=$(printf '%s\n' "$arch_ref" | grep -F '逐條當標準（' | sed 's/^.*逐條當標準（//; s/）.*$//' | tr '/' '\n' | sed 's/^ *//; s/ *$//')
while IFS= read -r n; do
    [ -z "$n" ] && continue
    if ! grep -qF "**${n}" "$TEMPLATE"; then
        echo "  ❌ ARCH_RULES 索引「${n}」在模板找不到 **${n}"
        name_missing=$((name_missing+1))
    fi
done <<< "$names"
assert_eq "$name_missing" "0" "ARCH_RULES 條目名索引皆存在於模板" || FAIL=$((FAIL+1))

# 雙向：索引條目數必須等於模板 Section 3 的粗體條目數（防索引整段被刪、或模板加了條目索引沒跟上）
sec3_count=$(awk '/^## 3\. /{p=1; next} /^## 4\. /{p=0} p && /^- \*\*/' "$TEMPLATE" | wc -l | tr -d ' ')
names_count=$(printf '%s\n' "$names" | grep -c . || true)
assert_eq "$names_count" "$sec3_count" "ARCH_RULES 索引條目數 == 模板 Section 3 條目數（${sec3_count}）" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 8: 模板行數 < 200（README / QUICKSTART 對外只宣稱「不到 200 行」，不再寫確切數字）
# --------------------------------------------------
echo ""
echo "Check 8: 模板行數 < 200"
template_lines=$(wc -l < "$TEMPLATE" | tr -d ' ')
if [ "$template_lines" -lt 200 ]; then
    echo "  ✅ 模板 ${template_lines} 行"
else
    echo "  ❌ 模板 ${template_lines} 行，超過對外宣稱的「不到 200 行」"
    FAIL=$((FAIL+1))
fi

# 8b：對外文檔不得再寫模板的確切行數（「約 N 行」「~N 行」「about N lines」），版本歷史列（| v… / | **v…）除外
echo ""
echo "Check 8b: 對外文檔不寫模板確切行數（版本歷史列除外）"
OUTWARD_DOCS=(
    "$REPO_ROOT/README.md"
    "$REPO_ROOT/README.en.md"
    "$REPO_ROOT/CLAUDE.md"
    "$REPO_ROOT/dev-closed-loop/README.md"
    "$REPO_ROOT/dev-closed-loop/QUICKSTART.md"
    "$REPO_ROOT/dev-closed-loop/skill/init-claude.md"
    "$REPO_ROOT/dev-closed-loop/.claudedocs/concepts/閉環核心理念.md"
)
exact_lines=0
for doc in "${OUTWARD_DOCS[@]}"; do
    [ -f "$doc" ] || continue
    hits=$(grep -nE '(約 ?|~|about )[0-9]+ ?(行|lines)' "$doc" | grep -vE '^[0-9]+:\| \**v[0-9]' || true)
    if [ -n "$hits" ]; then
        echo "  ❌ $(basename "$doc") 含模板確切行數描述："
        printf '%s\n' "$hits" | sed 's/^/     /'
        exact_lines=$((exact_lines+1))
    fi
done
assert_eq "$exact_lines" "0" "對外文檔無「約 N 行」類描述（版本歷史列除外）" || FAIL=$((FAIL+1))

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
