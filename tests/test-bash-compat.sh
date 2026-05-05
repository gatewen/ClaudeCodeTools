#!/usr/bin/env bash
# test-bash-compat.sh
# 防範已知技術陷阱：
#   - macOS bash 3.2 + 全形括號 bug（裸變數 $VAR 緊接 `）`/`（` 會丟位元組）
#     修復：一律用 ${VAR} 大括號形式
#   - 使用者可能用系統 /bin/bash（macOS 是 3.2）跑 setup.sh，需 syntax check 通過

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

FAIL=0

# 收集所有 .sh 檔案
SH_FILES=()
while IFS= read -r f; do
    SH_FILES+=("$f")
done < <(
    find "$REPO_ROOT" -type f -name "*.sh" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        | sort
)

echo "Scanning ${#SH_FILES[@]} .sh files..."

# --------------------------------------------------
# Check 1: 裸變數 $VAR 緊接全形括號 `（` 或 `）`
# --------------------------------------------------
echo ""
echo "Check 1: 裸變數 \$VAR 緊接全形括號（macOS bash 3.2 bug）"
# 模式：$ + 變數名 + 全形括號（不能有 { 包覆，因為 ${VAR} 是安全的）
# 注意：BSD grep 與 GNU grep 對 \$ 解讀不同，用 [$] 字元類別最安全
violations=$(grep -nE "[$][A-Za-z_][A-Za-z0-9_]*[（）]" "${SH_FILES[@]}" 2>/dev/null || true)
if [ -n "$violations" ]; then
    echo "  ❌ 發現裸變數緊接全形括號（會被 bash 3.2 吃掉位元組）："
    # shellcheck disable=SC2001
    echo "$violations" | sed 's/^/    /'
    echo "    修復：改用 \${VAR} 大括號形式"
    FAIL=$((FAIL+1))
else
    echo "  ✅ 無裸變數緊接全形括號"
fi

# --------------------------------------------------
# Check 2: setup.sh 在 /bin/bash（macOS 預設 = bash 3.2）下 syntax 通過
# --------------------------------------------------
echo ""
echo "Check 2: setup.sh syntax 在 /bin/bash 下通過"
if [ -x /bin/bash ]; then
    bash_ver=$(/bin/bash --version 2>/dev/null | head -1 || echo "unknown")
    echo "  /bin/bash version: $bash_ver"
    if /bin/bash -n "$REPO_ROOT/setup.sh" 2>&1; then
        echo "  ✅ setup.sh syntax OK"
    else
        echo "  ❌ setup.sh syntax 在 /bin/bash 下失敗"
        FAIL=$((FAIL+1))
    fi
else
    echo "  ⚠️  /bin/bash 不存在 — 跳過 bash 3.2 syntax check"
fi

# --------------------------------------------------
# Check 3: 所有 hooks/*.sh 與 setup.sh 都有 shebang
# --------------------------------------------------
echo ""
echo "Check 3: 所有 .sh 有正確 shebang"
no_shebang=0
for f in "${SH_FILES[@]}"; do
    first_line=$(head -1 "$f")
    case "$first_line" in
        "#!/bin/bash"|"#!/usr/bin/env bash"|"#!/bin/sh"|"#!/usr/bin/env sh")
            ;;
        *)
            echo "  ❌ $f 缺少有效 shebang（first line: ${first_line}）"
            no_shebang=$((no_shebang+1))
            ;;
    esac
done
assert_eq "$no_shebang" "0" "所有 .sh 有 shebang" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 4: setup.sh 不可使用 bash 4+ 才有的功能（mapfile/readarray/declare -A）
#         它的 shebang 是 #!/bin/bash，必須相容 macOS bash 3.2
# --------------------------------------------------
echo ""
echo "Check 4: setup.sh 不使用 bash 4+ only 功能"
bash4_features=$(grep -nE "^[[:space:]]*(mapfile|readarray)\b|declare[[:space:]]+-A\b" "$REPO_ROOT/setup.sh" 2>/dev/null || true)
if [ -n "$bash4_features" ]; then
    echo "  ❌ setup.sh 使用 bash 4+ only 功能："
    # shellcheck disable=SC2001
    echo "$bash4_features" | sed 's/^/    /'
    FAIL=$((FAIL+1))
else
    echo "  ✅ setup.sh 與 bash 3.2 相容"
fi

# --------------------------------------------------
# Result
# --------------------------------------------------
echo ""
if [ $FAIL -eq 0 ]; then
    echo "All bash-compat checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
