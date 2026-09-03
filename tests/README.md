# tests/

ClaudeCodeTools 本地 smoke test 套件。**不部署到使用者專案**——只給 maintainer 在開發時跑。

## 為什麼存在

階段 2-3 設計動機：
- 跨檔案不一致曾經由人類審查多次漏看（codex 比對才抓到 5 處 bug）→ 需自動化
- 階段 2-1（hook marker 隔離）和階段 2-2（SHA tracking）需要回歸防線
- macOS bash 3.2 全形括號 bug 是已知陷阱、需自動防範

設計原則：**驗證外部契約（數字、檔案存在、exit code、行為），不驗內部實作**。避免 tests 變成方法論演進的枷鎖。

## 怎麼跑

```bash
bash tests/run.sh
```

執行：
- **Phase A**: shellcheck 全部 `.sh`（如未安裝會 skip）
- **Phase B**: 動態發現並執行 `tests/test-*.sh`

通過時 exit 0，失敗時 exit 1 + 印失敗清單。

## 7 個 smoke 對應防範

| 測試 | 防什麼 |
|------|------|
| `test-cross-file-consistency.sh` | 文檔數量 / 依賴敘述 / 版本宣告跨檔不一致（codex 揭露的最大歷史失敗類）|
| `test-setup-local.sh` | 本地模式 happy path：偵測 / 部署 / placeholder / 路徑 / check-version 抽查 |
| `test-setup-remote-sha.sh` | 階段 2-2 回歸防線：`.commit-sha` 寫入 + 完整 40 字元 |
| `test-deploy-hooks.sh` | hook 複製 / +x / settings.json 5 keywords / 合法 JSON / **幂等** / 舊版 hook 配置遷移清除 |
| `test-hooks-isolation.sh` | 階段 2-1 回歸防線：marker project-scoped、跨專案不污染 |
| `test-hooks-exit-codes.sh` | 核心 3 hook（impact-analysis / causal-chain-reset / incremental-lint）行為契約：副檔名白名單、新檔放行、session 隔離、每輪重置 |
| `test-bash-compat.sh` | macOS bash 3.2 全形括號陷阱 / `/bin/bash` syntax / shebang / bash 4+ 功能禁用 |

## 加新測試

1. 新建 `tests/test-foo.sh`，shebang 用 `#!/usr/bin/env bash`
2. `source` 共用 helpers：
   ```bash
   REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   source "${REPO_ROOT}/tests/lib/assert.sh"
   source "${REPO_ROOT}/tests/lib/fixtures.sh"  # 需要 mktemp 時
   ```
3. 用 `assert_eq` / `assert_neq` / `assert_file_exists` / `assert_contains` 做斷言
4. 失敗 exit 1，成功 exit 0
5. **`tests/run.sh` 會自動發現新測試**，無需修改

## Pre-commit hook（可選）

寬鬆模式：失敗只 warn + log，不擋 commit。

```bash
bash tests/install-pre-commit.sh
```

安裝後每次 `git commit` 自動跑 `tests/run.sh`。

- 通過 → 靜默 + log 自動清除
- 失敗 → 印警告 + 完整 log 寫到 `.git/test-logs/<時戳>.log` + commit 仍繼續

解除：`rm .git/hooks/pre-commit`

## 共用 helpers

### `lib/assert.sh`
- `assert_eq actual expected msg` — 字串相等
- `assert_neq actual unexpected msg` — 字串不等
- `assert_file_exists path msg` — 檔案存在
- `assert_contains haystack needle msg` — 子字串包含

每個 helper 印 `✅ msg` 或 `❌ msg: ...`，回傳 0/1。

### `lib/fixtures.sh`
- `make_tmpdir` — 建立 mktemp -d 並註冊 EXIT trap auto-cleanup
- 所有 `make_tmpdir` 建立的目錄會在腳本結束時自動 `rm -rf`

## 設計脈絡

- **Q1 pre-commit 嚴格度**：寬鬆（warn + log，不擋）
- **Q2 fixture 語言**：minimal TS（不真跑 npm，只當「結構像 TS」的偵測標的）
- **Q3 階段 4 觀察期門檻**：時間 ≥ 1 月 AND 跨專案部署 ≥ 5 次 AND 認知驗證命中 ≥ 3 次

詳細決策過程見 commit 歷史 `階段 2-3 批 1/2/3`。
