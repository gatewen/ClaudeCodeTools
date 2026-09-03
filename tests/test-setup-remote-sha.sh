#!/usr/bin/env bash
# test-setup-remote-sha.sh
# 階段 2-2 回歸防線：驗證 setup.sh 遠端模式正確寫入 .commit-sha
#
# 策略：
#   - 用 SETUP_TARBALL_URL / SETUP_SHA_URL env vars 把 GitHub 改指向本地 file://
#   - 用 stdin 餵入 setup.sh（模擬 curl|bash，使 $0=bash 強制走 remote 分支）
#   - 用隔離 HOME 避免污染真實 ~/.claude

set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"
# shellcheck source=lib/fixtures.sh
source "$REPO_ROOT/tests/lib/fixtures.sh"

FAIL=0

# --------------------------------------------------
# 建立隔離環境
# --------------------------------------------------
TEST_HOME=$(make_tmpdir)
TEST_BUILD=$(make_tmpdir)

# --------------------------------------------------
# 建立最小 fake source tree（只放 setup.sh 必需檔案）
# --------------------------------------------------
FAKE_SRC="$TEST_BUILD/ClaudeCodeTools-fake"
mkdir -p "$FAKE_SRC/dev-closed-loop/skill"
cat > "$FAKE_SRC/dev-closed-loop/skill/init-claude.md" <<'EOF'
# Test Skill
Path: {{REPO_PATH}}
EOF
echo "Test template" > "$FAKE_SRC/dev-closed-loop/CLAUDE_TEMPLATE.md"

# 打成 tarball（模擬 GitHub archive 格式：頂層是 ClaudeCodeTools-* 目錄）
FAKE_TARBALL="$TEST_BUILD/fake-archive.tar.gz"
tar czf "$FAKE_TARBALL" -C "$TEST_BUILD" ClaudeCodeTools-fake

# --------------------------------------------------
# 建立 fake SHA JSON（模擬 GitHub API /commits/main response）
# --------------------------------------------------
TEST_SHA="abc123def4567890abcdef1234567890abcdef12"
FAKE_SHA_FILE="$TEST_BUILD/fake-sha.json"
cat > "$FAKE_SHA_FILE" <<EOF
{
  "sha": "$TEST_SHA",
  "node_id": "test-node",
  "commit": { "message": "test commit" }
}
EOF

# --------------------------------------------------
# 跑 setup.sh（stdin 模式，env var 指向本地 file://）
#   Windows Git Bash 的 curl 是原生 exe，看不懂 MSYS 路徑 /tmp/...；
#   有 cygpath 時轉成 file:///C:/... 形式。
# --------------------------------------------------
to_file_url() {
    if command -v cygpath >/dev/null 2>&1; then
        printf 'file:///%s' "$(cygpath -m "$1")"
    else
        printf 'file://%s' "$1"
    fi
}

echo "Running setup.sh with mocked URLs..."
output=$(
    HOME="$TEST_HOME" \
    SETUP_TARBALL_URL="$(to_file_url "$FAKE_TARBALL")" \
    SETUP_SHA_URL="$(to_file_url "$FAKE_SHA_FILE")" \
    bash < "$REPO_ROOT/setup.sh" 2>&1 || true
)

# --------------------------------------------------
# Check 1: .commit-sha 檔案存在
# --------------------------------------------------
echo ""
echo "Check 1: .commit-sha 檔案被寫入"
SHA_FILE="$TEST_HOME/.claude/cache/ClaudeCodeTools/.commit-sha"
assert_file_exists "$SHA_FILE" || FAIL=$((FAIL+1))

# --------------------------------------------------
# Check 2: 內容 = 我們 mock 的 SHA
# --------------------------------------------------
echo ""
echo "Check 2: .commit-sha 內容符合 mock SHA"
if [ -f "$SHA_FILE" ]; then
    actual_sha=$(cat "$SHA_FILE")
    assert_eq "$actual_sha" "$TEST_SHA" ".commit-sha == TEST_SHA" || FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Check 3: SHA 格式（40 字元 hex）
# --------------------------------------------------
echo ""
echo "Check 3: SHA 為 40 字元 hex"
if [ -f "$SHA_FILE" ]; then
    actual_sha=$(cat "$SHA_FILE")
    if [[ "$actual_sha" =~ ^[a-f0-9]{40}$ ]]; then
        echo "  ✅ SHA 格式正確（40 hex）"
    else
        len=$(printf '%s' "$actual_sha" | wc -c | tr -d ' ')
        echo "  ❌ SHA 格式無效：'${actual_sha}'（長度 ${len}）"
        FAIL=$((FAIL+1))
    fi
fi

# --------------------------------------------------
# Check 4: setup.sh 的 placeholder 替換邏輯也在 remote 模式下生效
# --------------------------------------------------
echo ""
echo "Check 4: skill 部署後 placeholder 已替換"
SKILL_DEPLOYED="$TEST_HOME/.claude/commands/dev/init-claude.md"
if [ -f "$SKILL_DEPLOYED" ]; then
    if grep -q "{{REPO_PATH}}" "$SKILL_DEPLOYED"; then
        echo "  ❌ 部署的 skill 仍含 {{REPO_PATH}} 殘留"
        FAIL=$((FAIL+1))
    else
        echo "  ✅ placeholder 已替換"
    fi
else
    echo "  ❌ skill 未部署到 $SKILL_DEPLOYED"
    FAIL=$((FAIL+1))
fi

# --------------------------------------------------
# Diagnostic on failure
# --------------------------------------------------
if [ $FAIL -gt 0 ]; then
    echo ""
    echo "--- setup.sh output（前 40 行用於 debug）---"
    echo "$output" | head -40
    echo "--- end output ---"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "All SHA tracking checks PASS"
    exit 0
fi
echo "$FAIL check(s) FAILED"
exit 1
