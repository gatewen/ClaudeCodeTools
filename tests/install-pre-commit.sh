#!/usr/bin/env bash
# install-pre-commit.sh — 一鍵安裝寬鬆模式 pre-commit hook
# 執行：bash tests/install-pre-commit.sh
# 行為：
#   - 在 .git/hooks/pre-commit 寫入跑 tests/run.sh 的 hook
#   - 寬鬆模式（Q1=B 決策）：失敗只 warn + log，不擋 commit
#   - log 寫到 .git/test-logs/<時戳>.log（成功時自動清除）

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "❌ 不在 git repo 內，無法安裝 pre-commit"
    exit 1
}

HOOK_PATH="${REPO_ROOT}/.git/hooks/pre-commit"

# 已存在且不是我們的 hook → 拒絕覆蓋
if [ -f "${HOOK_PATH}" ] && ! grep -q "tests/run.sh" "${HOOK_PATH}" 2>/dev/null; then
    echo "⚠️  ${HOOK_PATH} 已存在且不是 ClaudeCodeTools 的 hook"
    echo "   請手動處理或備份後刪除，再重跑此腳本"
    exit 1
fi

cat > "${HOOK_PATH}" <<'EOF'
#!/usr/bin/env bash
# pre-commit — 跑 tests/run.sh（Q1=B 寬鬆模式）
# 失敗只 warn + log，commit 繼續。修復後可重跑驗證。

repo_root=$(git rev-parse --show-toplevel)
log_dir="${repo_root}/.git/test-logs"
mkdir -p "${log_dir}"
log_file="${log_dir}/$(date +%Y%m%d-%H%M%S).log"

if bash "${repo_root}/tests/run.sh" > "${log_file}" 2>&1; then
    rm "${log_file}"  # 成功就清掉 log
    exit 0
fi

echo ""
echo "⚠️  tests/run.sh 失敗（寬鬆模式：commit 仍繼續）"
echo "   log: ${log_file}"
echo "   修復後可手動跑 bash tests/run.sh 重新驗證"
exit 0  # 寬鬆：不擋 commit
EOF

chmod +x "${HOOK_PATH}"

echo "✅ pre-commit hook 已安裝：${HOOK_PATH}"
echo "   模式：寬鬆（失敗只 warn + log，不擋 commit）"
echo "   log 位置：${REPO_ROOT}/.git/test-logs/"
echo ""
echo "驗證："
echo "   bash ${HOOK_PATH}    # 手動跑一次確認"
echo ""
echo "解除安裝："
echo "   rm ${HOOK_PATH}"
