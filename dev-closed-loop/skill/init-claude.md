# dev:init-claude — 開發設計閉環初始化

為當前專案部署「開發設計閉環」方法論的 CLAUDE.md 和補充文檔。

**用戶參數**：$ARGUMENTS

**模式**：
- `/dev:init-claude` 或 `/dev:init-claude [專案名稱]` — 部署/升級（預設）
- `/dev:init-claude status` — 快速查看版本和健康狀態
- `/dev:init-claude upgrade` — 從 GitHub 下載最新版，更新 Skill 和快取
- `/dev:init-claude uninstall` — 移除閉環部署

---

## 模板來源（由 setup.sh 安裝時自動替換路徑）

```
模板檔案：{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md
文檔目錄：{{REPO_PATH}}/dev-closed-loop/.claudedocs/
語言指南：{{REPO_PATH}}/dev-closed-loop/.claudedocs/languages/
Hook 腳本：{{REPO_PATH}}/dev-closed-loop/hooks/
部署腳本：{{REPO_PATH}}/dev-closed-loop/deploy-hooks.sh
版本檢查：{{REPO_PATH}}/dev-closed-loop/check-version.sh
```

> **v7.0.0 workflow 說明**：v7 的四個 workflow 腳本（`/dev-prd` `/dev-design` `/dev-review` `/dev-verify`）由 **setup.sh 全域部署到 `~/.claude/workflows/`**，不由本 skill per-project 部署——workflow 是 Claude Code 原生功能，全域註冊即所有專案可用。本 skill 只部署專案層的 CLAUDE.md + `.claudedocs/` + hooks（含 agent 素材庫，供 workflow 引用）。workflow 需 Claude Code v2.1.154+ · 付費方案 · research preview；不可用時方法論走 CLAUDE.md Section 14 退化路徑，承重核（always-on hook）不受影響。

---

## ⛔ 模式分流（最優先，在執行任何步驟前必須完成）

**Claude 必須在載入此 Skill 後立即執行以下判斷，禁止跳過。**

解析 `$ARGUMENTS` 的第一個詞，根據下表跳轉到對應模式的 section：

| 第一個詞 | 模式 | 跳轉目標 |
|---------|------|---------|
| `status` | 狀態檢查 | → 下方「Status 模式」 |
| `upgrade` | 自我更新 | → 下方「Upgrade 模式」 |
| `uninstall` | 移除部署 | → 下方「Uninstall 模式」 |
| 其他（含空） | 部署/升級 | → 下方「部署/升級流程 Step 0」 |

⛔ **若匹配到 status / upgrade / uninstall，直接跳轉到對應 section，禁止執行「部署/升級流程」的任何步驟。**

---

## Status 模式（`/dev:init-claude status`）

快速查看當前專案的閉環部署狀態和健康度。不修改任何檔案。

### 步驟

1. **版本偵測**：
   - 用 Grep 搜尋 `CLAUDE.md` 中的 `closed-loop v` 字串
   - 找到 → 提取版本號
   - 找不到 CLAUDE.md → 輸出「⚠️ 閉環未部署。執行 `/dev:init-claude` 開始部署」並結束
   - 有 CLAUDE.md 但無版本標記 → 輸出「ℹ️ CLAUDE.md 存在但非閉環部署」並結束

2. **配置提取**：從 CLAUDE.md 提取已部署的專案配置（語言/框架/測試指令/建置指令）

3. **健康檢查**（逐項用 Bash 檢查，每項標 ✅/❌/⚠️）：

   | 檢查項 | 方法 | 判定 |
   |--------|------|------|
   | 核心文檔 | `ls .claudedocs/` 數量 | 11 個 = ✅，< 11 = ❌ 列出缺少 |
   | 語言指南 | `.claudedocs/languages/*.md` 是否存在 | 有 = ✅ [語言]，無 = — 未部署 |
   | 修改前因果鏈守衛 Hook | `.claude/hooks/impact-analysis-guard.sh` 存在且可執行 | ✅/❌ |
   | 因果鏈重置 Hook | `.claude/hooks/causal-chain-reset.sh` 存在且可執行 | ✅/❌ |
   | 增量驗證 Hook | `.claude/hooks/incremental-lint.sh` 存在且可執行 | ✅/❌ |
   | 委派追蹤 Hook | `.claude/hooks/delegation-tracker.sh` 存在且可執行 | ✅/❌ |
   | 學習日誌提醒 Hook | `.claude/hooks/learning-log-checker.sh` 存在且可執行 | ✅/❌ |
   | Hook 配置 | `.claude/settings.json` 含 `impact-analysis-guard`、`causal-chain-reset`、`incremental-lint`、`delegation-tracker`、`learning-log-checker`，且不含已移除的 `delegation-gate`、`prompt-understanding-guard` | 5/5 且無舊項 = ✅，否則 ⚠️ 列出缺少/殘留 |
   | Placeholder 殘留 | Grep CLAUDE.md 中的 `{{` | 無 = ✅，有 = ❌ 列出殘留 |
   | 快取/來源目錄 | `{{REPO_PATH}}/dev-closed-loop/` 是否存在 | 有 = ✅，無 = ⚠️ 來源不可達 |
   | 閉環狀態目錄 | `.claude-loop/` 是否存在 | 有 = ℹ️ 存在，無 = — 未啟用（正常） |
   | Workflow 腳本（全域·可選）| `ls ~/.claude/workflows/dev-prd.js dev-design.js dev-review.js dev-verify.js` | 4/4 = ✅ 全域可用，部分/無 = ℹ️ 未部署（走 Section 14 退化路徑，屬正常）|

4. **⛔ 可升級偵測（禁止跳過）**：
   此步驟是 status 模式的核心功能之一，**即使前面的健康檢查全部通過也必須執行**。不執行此步驟就等於沒有完成 status 檢查。
   用 Bash 執行版本檢查腳本：
   ```bash
   bash {{REPO_PATH}}/dev-closed-loop/check-version.sh {{REPO_PATH}} --deployed ./CLAUDE.md --check-remote
   ```
   根據輸出的 STATUS 值判斷：
   - `upgrade_available` 或 `cache_outdated` → 顯示「🔄 可升級：v{DEPLOYED_VERSION} → v{CACHE_VERSION 或 REMOTE_VERSION}。執行 `/dev:init-claude upgrade` 升級」
   - `up_to_date` → 顯示「✅ 已是最新版本」
   - `up_to_date` 且 `SHA_MISMATCH=true` → 顯示「✅ 版本相同，但有未發版的改動（本地 SHA: {前7碼} ≠ 遠端 SHA: {前7碼}）。執行 `/dev:init-claude upgrade` 取得最新」
   - `REMOTE_CHECK=failed` 且 `STATUS=up_to_date` → 顯示「✅ 與快取版本一致（⚠️ 無法連線 GitHub 確認遠端版本）」
   - `STATUS=error` → 顯示「⚠️ 無法確認版本」
   - **⛔ 必須在輸出中包含「升級：」行**，不論結果是什麼。缺少此行 = status 輸出不完整

5. **輸出格式（⛔ 必須包含以下所有區塊，禁止省略任何區塊）**：

```
═══ 閉環部署狀態 ═══

版本：v5.7.0（SHA: abc1234）
來源：~/.claude/cache/ClaudeCodeTools/  [或本地 repo 路徑]
專案：[名稱]
語言：[語言] | 框架：[框架]

健康檢查：
  ✅ 核心文檔（10/10）
  ✅ 語言指南：typescript.md
  ✅ 修改前因果鏈守衛 Hook（既有原始碼檔首次修改擋一次）
  ✅ 因果鏈重置 Hook
  ✅ 增量驗證 Hook
  ✅ 委派追蹤 Hook
  ✅ 學習日誌提醒 Hook
  ✅ Hook 配置（5/5，無舊版殘留）
  ✅ 無 Placeholder 殘留
  — .claude-loop/ 未啟用
  ℹ️ Workflow（全域）：/dev-prd /dev-design /dev-review /dev-verify  [或] — 未部署（走退化路徑，正常）

升級：✅ 已是最新版本
  [或] 🔄 可升級：v5.7.0 → v5.8.0。執行 /dev:init-claude upgrade 升級

整體：✅ 健康（8/8 通過）
```

若有問題：
```
整體：⚠️ 有問題（6/8 通過）
  ❌ 修改前統一守衛 Hook 缺失 → 執行 /dev:init-claude upgrade 升級修復
  ❌ Hook 配置不完整 → 執行 /dev:init-claude upgrade 升級修復
```

---

## Upgrade 模式（`/dev:init-claude upgrade`）

從 GitHub 下載最新版本到快取，更新 Skill 自身，然後引導用戶完成專案升級。

### 步驟

1. **下載最新版本到快取**：
   用 Bash 執行：
   ```bash
   CACHE_DIR="$HOME/.claude/cache/ClaudeCodeTools"
   TMP_DIR="$(mktemp -d)"
   curl -sL "https://github.com/gatewen/ClaudeCodeTools/archive/refs/heads/main.tar.gz" -o "$TMP_DIR/archive.tar.gz" && \
   tar -xzf "$TMP_DIR/archive.tar.gz" -C "$TMP_DIR" && \
   rm -rf "$CACHE_DIR" && \
   mkdir -p "$(dirname "$CACHE_DIR")" && \
   mv "$TMP_DIR"/ClaudeCodeTools-* "$CACHE_DIR" && \
   rm -rf "$TMP_DIR" && \
   echo "OK"
   ```
   - 輸出 "OK" → 繼續
   - 失敗 → 告知「❌ 下載失敗，請確認網路連線」並終止

   **記錄 commit SHA**（下載成功後立即執行）：
   ```bash
   curl -sL --max-time 5 "https://api.github.com/repos/gatewen/ClaudeCodeTools/commits/main" 2>/dev/null | grep '"sha"' | head -1 | sed 's/.*"sha": *"//;s/".*//' > "$HOME/.claude/cache/ClaudeCodeTools/.commit-sha"
   ```

2. **版本比較**：
   用 Bash 執行版本檢查腳本：
   ```bash
   bash "$HOME/.claude/cache/ClaudeCodeTools/dev-closed-loop/check-version.sh" "$HOME/.claude/cache/ClaudeCodeTools" --deployed ./CLAUDE.md
   ```
   根據輸出的 STATUS 值判斷：
   - `up_to_date` → 告知「✅ 快取已更新，已是最新版本 v{CACHE_VERSION}」並結束
   - `upgrade_available` → 繼續
   - `not_deployed` → 繼續（首次部署）

3. **更新 Skill 自身**：
   用 Bash 執行：
   ```bash
   sed "s|{{REPO_PATH}}|$HOME/.claude/cache/ClaudeCodeTools|g" \
     "$HOME/.claude/cache/ClaudeCodeTools/dev-closed-loop/skill/init-claude.md" \
     > "$HOME/.claude/commands/dev/init-claude.md" && \
   echo "OK"
   ```
   告知用戶：「✅ Skill 已更新至 v{新版本}。快取路徑：~/.claude/cache/ClaudeCodeTools」

4. **引導專案升級**：
   用 AskUserQuestion 告知用戶：
   ```
   ✅ 閉環工具已更新：v{舊版本} → v{新版本}

   Skill 檔案和快取已是最新版。
   ⚠️ 當前對話仍使用舊版 Skill 定義（Claude 已載入的 context 不會即時更新）。

   請選擇：
   1. 在新對話中執行 /dev:init-claude 完成專案升級 ← 推薦
   2. 繼續在當前對話中升級（使用舊 Skill 定義，可能缺少新功能）
   ```
   - 用戶選 1 → 結束，提示「在目標專案目錄開啟新對話，執行 /dev:init-claude 即可升級」
   - 用戶選 2 → 進入正常部署/升級流程（即 Step 0 起）→ 若 cache 對 deployed 版本提供結構化 migration block，自動觸發 Step 5 migration

5. **Version-Aware Migration Flow（v6.0.0 引入，v6.3.x 通用化）**：

   當 cache 含結構化 migration block 匹配 `DEPLOYED_VERSION` 時，自動執行此步驟；無 match 視為非破壞性升級，跳過 5.3-5.5 回到原有部署流程。

   **5.1 偵測 deployed version + 格式驗證**：
   ```bash
   DEPLOYED_VERSION=$(grep -oP 'closed-loop v\K[0-9]+\.[0-9]+\.[0-9]+' ./CLAUDE.md | head -1)
   ```
   - 空值 / 非 `v{major}.{minor}.{patch}` semver 格式 → **EH-1 未知版本**：警告 + AskUserQuestion 三選一（A 全替換 / C 手動 diff / Abort）
   - 格式正確 → 繼續 5.2（由 awk parser 動態判定是否有 migration path，不再 hard-code 版本範圍）

   **5.2 解析 cache 的 migration-notes**：
   ```bash
   CACHE_TEMPLATE="$HOME/.claude/cache/ClaudeCodeTools/dev-closed-loop/CLAUDE_TEMPLATE.md"
   awk -v dep="$DEPLOYED_VERSION" '
     /<!--$/ { p=1; b=""; next }
     /^-->$/ {
       if (p && b ~ /migration-notes/) {
         # 只接受含結構化 from-version 欄位的 block（過濾散文格式如 v6.2 extensions notes）
         fv = ""
         if (match(b, /from-version:[ \t]*[^\n]+/)) {
           fv = substr(b, RSTART, RLENGTH)
           sub(/^from-version:[ \t]*/, "", fv)
         }
         if (fv != "") {
           # "v5.x" → "^v5\.[0-9]+(\.[0-9]+)?$"
           pat = fv
           gsub(/\./, "\\.", pat)
           gsub(/x/, "[0-9]+", pat)
           if (dep ~ ("^" pat "(\\.[0-9]+)?$")) print b
         }
       }
       p=0
     }
     p { b=b"\n"$0 }
   ' "$CACHE_TEMPLATE"
   ```
   解析出 `breaking-changes` / `required-actions` / `recommended-actions` / `anchors` 列表（含 `name` / `match` / `position`）。
   - 過濾規則：只印出含結構化 `from-version:` 欄位且該欄位 pattern 匹配 `DEPLOYED_VERSION` 的 block。散文格式的 migration notes（無 `from-version:` 欄位，如 v6.2 extensions）會被排除，避免污染後續 parser。

   **判定分支**（依 awk 輸出）：
   - 輸出非空（≥ 1 個結構化 block） → 繼續 5.3 進入結構化 migration
   - 輸出空 → 視為**非破壞性升級**（cache 無對應 `DEPLOYED_VERSION` 的結構化 breaking migration block）：告知用戶「ℹ️ v{DEPLOYED_VERSION} → v{CACHE_VERSION} 無結構化 breaking migration，將直接部署最新 CLAUDE_TEMPLATE 覆蓋」，跳過 5.3-5.5 回到原有部署流程
   - 輸出非空但解析欄位失敗（awk 印了 block 但缺 `breaking-changes` / `anchors` 等必要欄位） → 觸發 **EH-1**

   **5.3 顯示摘要 + AskUserQuestion**：
   ```
   🔄 v{DEPLOYED_VERSION} → v{CACHE_VERSION} Migration

   破壞性變更：
   [breaking-changes 逐條列出]

   必要操作：
   [required-actions 逐條列出]

   建議閱讀：
   [recommended-actions 逐條列出]

   請選擇升級策略：
   A. 全替換 — 用 fresh CLAUDE_TEMPLATE 覆蓋（⚠️ 會丟失你對 CLAUDE.md 的客製化）
   B. 智能合併 — 在錨點注入新 Section，保留客製化（推薦）
   C. 手動 diff — 列出 diff 後我自己處理
   ```

   **5.4 執行所選策略**：

   - **A 全替換**：執行原 upgrade flow 覆蓋部署。
   - **B 智能合併**（推薦）：對 `anchors` 列表中每個 anchor：
     1. `grep -nF "$anchor.match" ./CLAUDE.md` 找定位 line
     2. 找不到 → 觸發 **EH-2** 自動降級為策略 C，告知用戶「⚠️ 智能合併錨點失敗（用戶可能客製化 heading），自動降級為手動 diff 模式」
     3. 找得到 → 按 `position`（`before` / `after`）用 `sed -i` 在該行前/後插入對應 Section 的內容（內容從 fresh CLAUDE_TEMPLATE 對應 anchor 段落抽取）
     4. 全部 anchor 處理完 → grep 驗收新 Section 都已注入
   - **C 手動 diff**：`diff -u ./CLAUDE.md "$CACHE_TEMPLATE" | head -200` 印出差異，提示用戶手動編輯。

   **5.5 部署後驗收**：
   ```bash
   grep -c "## 0 四原則橫切自檢層" ./CLAUDE.md
   grep -c "### 12.5 Push Back 義務" ./CLAUDE.md
   grep -c "## ⚖️ Trade-off" ./CLAUDE.md
   grep -c "{{" ./CLAUDE.md  # 應為 0（**EH-3 placeholder 未替換** → 報錯）
   ```
   三新 Section 都 ≥ 1 命中 + placeholder 計數為 0 → 完成；否則告知用戶哪段缺失，回到 5.4 選 C。

---

## Uninstall 模式（`/dev:init-claude uninstall`）

從當前專案移除閉環部署。

### 步驟

1. **前置檢查**：
   - 用 Grep 確認 CLAUDE.md 存在且含 `closed-loop v` 標記
   - 不存在 → 輸出「⚠️ 當前專案未部署閉環」並結束

2. **掃描將移除的檔案**：
   用 Bash 列出以下項目，計算影響範圍：
   - `CLAUDE.md`（或閉環追加的部分）
   - `.claudedocs/` 目錄（含所有子目錄）
   - `.claude/hooks/impact-analysis-guard.sh`
   - `.claude/hooks/causal-chain-reset.sh`
   - `.claude/hooks/incremental-lint.sh`
   - `.claude/hooks/delegation-tracker.sh`
   - `.claude/hooks/learning-log-checker.sh`
   - `.claude/hooks/_helpers.sh`
   - （舊版殘留，若存在）`.claude/hooks/delegation-gate.sh`、`.claude/hooks/prompt-understanding-guard.sh`
   - `.claude/settings.json` 中的 PreToolUse、PostToolUse、UserPromptSubmit hook 配置
   - `.claude-loop/` 目錄（若存在）

3. **用戶確認**（AskUserQuestion）：
   ```
   ⚠️ 即將移除閉環部署。

   將刪除的檔案：
   - CLAUDE.md（閉環主檔案）[若為純閉環] / 閉環區段（若為合併檔）
   - .claudedocs/（N 個檔案）
   - .claude/hooks/（5 個 hook 腳本 + _helpers.sh）
   - .claude/settings.json 中的閉環 hook 配置
   [若有 .claude-loop/]
   - .claude-loop/（閉環狀態目錄，含 N 個檔案）

   ⚠️ .claude-loop/ 中可能包含進行中的閉環記錄，刪除後無法恢復。

   請選擇：
   1. 全部移除
   2. 保留 .claude-loop/，移除其餘
   3. 取消
   ```

4. **執行移除**：
   - 用 Bash `rm -rf .claudedocs/` 刪除文檔
   - 用 Bash `rm -f .claude/hooks/impact-analysis-guard.sh .claude/hooks/causal-chain-reset.sh .claude/hooks/incremental-lint.sh .claude/hooks/delegation-tracker.sh .claude/hooks/learning-log-checker.sh .claude/hooks/_helpers.sh .claude/hooks/delegation-gate.sh .claude/hooks/prompt-understanding-guard.sh` 刪除 hook 腳本（含舊版殘留）
   - 用 python3 從 `.claude/settings.json` 移除閉環 hook 配置（保留其他設定）：
     ```python
     import json
     cfg = json.load(open('.claude/settings.json'))
     # 移除 PreToolUse 中的閉環 hook
     pre_hooks = cfg.get("hooks", {}).get("PreToolUse", [])
     cfg["hooks"]["PreToolUse"] = [
       h for h in pre_hooks
       if "impact-analysis-guard" not in str(h) and "delegation-gate" not in str(h)
     ]
     if not cfg["hooks"]["PreToolUse"]:
       del cfg["hooks"]["PreToolUse"]
     # 移除 PostToolUse 中的閉環 hook
     post_hooks = cfg.get("hooks", {}).get("PostToolUse", [])
     cfg["hooks"]["PostToolUse"] = [
       h for h in post_hooks
       if "incremental-lint" not in str(h) and "delegation-tracker" not in str(h) and "learning-log-checker" not in str(h)
     ]
     if not cfg["hooks"]["PostToolUse"]:
       del cfg["hooks"]["PostToolUse"]
     # 移除 UserPromptSubmit 中的閉環 hook
     prompt_hooks = cfg.get("hooks", {}).get("UserPromptSubmit", [])
     cfg["hooks"]["UserPromptSubmit"] = [
       h for h in prompt_hooks
       if "causal-chain-reset" not in str(h) and "prompt-understanding-guard" not in str(h)
     ]
     if not cfg["hooks"]["UserPromptSubmit"]:
       del cfg["hooks"]["UserPromptSubmit"]
     if not cfg["hooks"]:
       del cfg["hooks"]
     json.dump(cfg, open('.claude/settings.json', 'w'), indent=2, ensure_ascii=False)
     ```
   - **CLAUDE.md 處理**：
     - 用 Grep 檢查 CLAUDE.md 是否**只有**閉環內容（首行是 `# {{已填充的專案名}}` 且末尾有 `closed-loop v` 註解，中間無非閉環區段）
     - 純閉環 → 用 Bash `rm CLAUDE.md` 刪除
     - 合併檔（有非閉環的自訂內容在頂部） → 用 AskUserQuestion 警告：
       ```
       CLAUDE.md 包含自訂內容（閉環區段前有 {N} 行）。
       自動移除可能破壞自訂內容。建議手動編輯。
       1. 我手動處理 CLAUDE.md（僅移除其餘閉環檔案）
       2. 全部刪除（包含自訂內容）
       ```
   - 若用戶選擇移除 `.claude-loop/` → 用 Bash `rm -rf .claude-loop/`

5. **結果報告**：
   ```
   ✅ 閉環已移除

   已刪除：
   - CLAUDE.md [或「已保留（含自訂內容）」]
   - .claudedocs/（N 個檔案）
   - 5 個 Hook 腳本 + _helpers.sh
   - .claude/settings.json 中的閉環 hook 配置（PreToolUse + PostToolUse + UserPromptSubmit）
   [若移除] - .claude-loop/

   若要重新部署，執行 /dev:init-claude
   ```

---

## 部署/升級流程（預設模式）

⛔ 僅當 `$ARGUMENTS` 的第一個詞**不是** status / upgrade / uninstall 時才執行此流程。

### Step 0：環境依賴檢查

閉環自帶 Agent 專家庫，不依賴外部工具。此步驟僅檢查可選插件。

1. **檢查 claude-mem**（可選）：用 Bash 執行 `grep -rq "claude-mem" ~/.claude/plugins/ 2>/dev/null && echo "installed" || grep -q "claude-mem" ~/.claude/.mcp.json 2>/dev/null && echo "installed"`
   - 輸出 "installed" → claude-mem 已安裝 ✅
   - 無輸出 → claude-mem 未安裝 ℹ️（可選，不影響閉環運作）

2. **結果處理**：直接繼續 Step 1。在最終報告（Step 5）中列出 claude-mem 狀態。

### Step 1：前置檢查

1. 確認當前工作目錄是一個合理的專案目錄（不是 home 目錄、不是根目錄）
2. 檢查模板來源是否存在：
   - 用 Read 讀取 `{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md`
   - 若讀取失敗 → 告知用戶模板路徑不存在，終止
3. 檢查當前目錄是否已有 `CLAUDE.md`：
   - 若已存在 → 進入「衝突處理」流程（見下方）
   - 若不存在 → 繼續

**衝突處理**：若已存在 CLAUDE.md，先執行版本偵測再決定流程。

**版本偵測**：用 Grep 搜尋現有 CLAUDE.md 中的 `closed-loop v` 字串（位於檔案末尾的 HTML 註解中）。
- 找到版本標記（如 `closed-loop v5.7.0`）→ 這是閉環專案，進入**升級流程**
- 找不到版本標記 → 這不是閉環專案，進入**非閉環衝突處理**

**升級流程**（偵測到閉環版本時）：
1. **⛔ 版本檢查（禁止跳過）**：
   用 Bash 執行版本檢查腳本（一次取得所有版本資訊）：
   ```bash
   bash {{REPO_PATH}}/dev-closed-loop/check-version.sh {{REPO_PATH}} --deployed ./CLAUDE.md --check-remote
   ```
   腳本輸出 key=value 格式（CACHE_VERSION、DEPLOYED_VERSION、REMOTE_VERSION、STATUS）。根據 STATUS 判斷：
   - `cache_outdated`（遠端版本 > 快取版本）→ 用 AskUserQuestion 提示：
       ```
       🔄 偵測到 GitHub 有新版本：v{REMOTE_VERSION}（本地快取：v{CACHE_VERSION}）

       請選擇：
       1. 先更新快取再升級（自動執行 upgrade → 部署）← 推薦
       2. 使用本地快取版本繼續（v{CACHE_VERSION}）
       3. 取消
       ```
       - 用戶選 1 → 執行 Upgrade 模式的步驟 1-3（下載 + 更新 Skill），然後用**新快取**繼續本流程
       - 用戶選 2 → 用現有快取繼續
       - 用戶選 3 → 終止
   - `upgrade_available`（快取版本 > 部署版本）→ 繼續升級流程
   - `up_to_date`（快取 = 部署）→ 告知已是最新，問是否重新部署
   - `REMOTE_CHECK=failed` → 輸出「⚠️ 無法連線 GitHub，使用本地快取版本」，繼續
2. 從版本檢查結果取得 CACHE_VERSION 作為目標版本號
3. 比較版本：
   - 現有版本 = 模板版本 → 告知「已是最新版 vX.X」，問是否要重新部署（重新偵測配置並覆蓋）
   - 現有版本 < 模板版本 → 顯示升級畫面（見下方）
   - 現有版本 > 模板版本 → 警告「目標版本 vX.X 比現有 vY.Y 舊」，問是否要降級
4. 升級畫面（用 AskUserQuestion）：
   ```
   偵測到現有閉環部署：v{現有版本}
   可升級至：v{模板版本}

   升級內容：
   - 方法論更新（CLAUDE.md 閉環流程）
   - 核心文檔更新（.claudedocs/ 10 份文檔）
   - 語言指南更新（若有部署）
   - Hook 腳本更新

   專案配置（語言/框架/指令）將從現有 CLAUDE.md 自動提取，無需重新偵測。

   請選擇：
   1. 升級（保留專案配置，更新方法論 + 文檔）← 推薦
   2. 全新部署（重新偵測專案配置，覆蓋一切）
   3. 取消
   ```
4. 用戶選「升級」→ 進入 **Step 1.5 配置提取**，然後跳過 Step 2/3，直接到 Step 4
5. 用戶選「全新部署」→ 走正常 Step 2 → 3 → 4 流程（等同覆蓋）
6. 用戶選「取消」→ 終止

**Step 1.5：配置提取**（僅升級模式）：
從現有 CLAUDE.md 中提取已填充的配置值。用 Grep 或正則匹配以下欄位：

| 欄位 | 提取方式 |
|------|---------|
| `PROJECT_NAME` | 匹配第一行 `# ` 後的文字 |
| `LANGUAGE` | 匹配 `**語言**：` 後的值 |
| `FRAMEWORK` | 匹配 `**框架**：` 後的值 |
| `TEST_COMMAND` | 匹配 `` **測試指令**：`...` `` 中反引號內的值 |
| `BUILD_COMMAND` | 匹配 `` **建置指令**：`...` `` 中反引號內的值 |
| `LINT_COMMAND` | 從增量驗證行（`{{LINT_COMMAND}}` 已被替換的位置）提取 |
| `VERIFY_SEQUENCE` | 從全專案驗證行（`{{VERIFY_SEQUENCE}}` 已被替換的位置）提取 |
| `LANGUAGE_SKILL_SECTION` | 檢查是否有 `## 語言規範` 區塊 → 有則保留語言 Skill 部署 |

提取完成後，用 AskUserQuestion 向用戶確認提取結果：
```
從現有 CLAUDE.md 提取的專案配置：

- 專案名稱：[提取值]
- 語言：[提取值]
- 框架：[提取值]
- 測試指令：[提取值]
- 建置指令：[提取值]
- 增量驗證：[提取值]
- 完整驗證：[提取值]
- 語言指南：✅ / —

請確認是否正確，或選擇「修正」手動調整。
```
確認後直接進入 Step 4（跳過 Step 2/3）。

**檢查用戶自訂內容**：
- 掃描現有 CLAUDE.md，找出不屬於閉環模板的自訂內容（模板前的內容、或模板後 `<!--` 註解之後的內容）
- 若有自訂內容 → 提示用戶：「偵測到自訂內容（N 行），將保留在升級後的 CLAUDE.md 頂部」
- 若無 → 不提示

**非閉環衝突處理**（找不到閉環版本標記時，原有邏輯）：
用 AskUserQuestion 詢問用戶：
- 選項 1：「合併」— 將閉環規則追加到現有 CLAUDE.md 末尾（保留原有內容）
- 選項 2：「覆蓋」— 完全替換為閉環模板
- 選項 3：「取消」— 不做任何變更，終止執行

### Step 2：專案偵測

**掃描策略（兩階段）**：

1. **第一階段：掃描當前目錄**。用 Bash 的 `ls` 檢查根目錄有無專案標誌檔（package.json、go.mod、Cargo.toml、pyproject.toml、requirements.txt、pom.xml、Makefile）。
2. **第二階段（備援）：若根目錄沒找到任何專案標誌檔**，用 Bash 掃描一層子目錄：
   ```bash
   ls */package.json */go.mod */Cargo.toml */pyproject.toml */requirements.txt */pom.xml 2>/dev/null
   ```
   - 找到 1 個子目錄有專案檔 → 自動以該子目錄為偵測對象，在確認時告知用戶
   - 找到多個子目錄 → 用 AskUserQuestion 讓用戶選擇哪一個
   - 都沒找到 → 全部標記「未偵測到」，進入 Step 2.5 攔截

以下偵測規則套用在「偵測對象目錄」（可能是根目錄或選中的子目錄）。

**語言偵測**（按優先順序）：
- 有 `go.mod` → Go
- 有 `Cargo.toml` → Rust
- 有 `package.json` 且含 `.ts` / `.tsx` 檔案 → TypeScript
- 有 `package.json` → JavaScript
- 有 `requirements.txt` 或 `pyproject.toml` 或 `setup.py` → Python
- 有 `*.java` 或 `pom.xml` → Java
- 有 `*.swift` → Swift
- 有 `*.rb` → Ruby
- 有 `*.sh` 且含 shebang `#!/bin/bash` 或 `#!/usr/bin/env bash` → Bash
- 以上都沒有 → 標記「未偵測到」

**語言 Skill 偵測**：

偵測到語言後，對照可用的語言 Skill：

| 偵測語言 | 對應 Skill 檔案 |
|---------|----------------|
| TypeScript | `typescript.md` |
| Python | `python.md` |
| Go | `go.md` |
| Rust | `rust.md` |
| C# | `csharp.md` |
| Bash | `bash.md` |
| 其他 | 無對應 Skill（不影響閉環運作） |

用 Bash 執行 `ls {{REPO_PATH}}/dev-closed-loop/.claudedocs/languages/{對應檔名} 2>/dev/null` 確認檔案存在。
記錄結果：有對應 Skill（✅）或無（—）。

**語言工具鏈映射**（用於填充 `{{LINT_COMMAND}}` 和 `{{VERIFY_SEQUENCE}}` placeholder）：

| 語言 | `{{LINT_COMMAND}}` | `{{VERIFY_SEQUENCE}}` |
|------|-------------------|----------------------|
| TypeScript | `npx tsc --noEmit && npx eslint src/` | `npx tsc --noEmit && npx eslint src/ && npx vitest run && npm run build` |
| Python | `ruff check src/` | `mypy src/ && ruff check src/ && pytest tests/` |
| Go | `go vet ./... && golangci-lint run ./...` | `go vet ./... && golangci-lint run ./... && go build ./... && go test -race ./...` |
| Rust | `cargo clippy -- -D warnings` | `cargo fmt -- --check && cargo clippy -- -D warnings && cargo build && cargo test` |
| C# | `dotnet build --warnaserrors` | `dotnet format --verify-no-changes && dotnet build --warnaserrors && dotnet test` |
| Bash | `shellcheck *.sh` | `bash -n *.sh && shellcheck *.sh && bats tests/` |
| 其他（無 Skill） | = `{{BUILD_COMMAND}}` 的值 | = `{{TEST_COMMAND}} && {{BUILD_COMMAND}}` |

注意：以上為預設值。若 Step 2 偵測到專案已有自訂的 lint 指令（例如 package.json 的 scripts.lint），以偵測到的值為準。映射表中的 `{{TEST_COMMAND}}` 和 `{{BUILD_COMMAND}}` 指的是 Step 2 偵測到的值。

**填充優先順序**：
1. 若 Step 2 偵測到專案已有自訂指令 → 使用偵測值（尊重專案配置）
2. 若 Step 2 未偵測到 → 使用映射表的預設值
3. 若無對應 Skill → 回退到 `{{BUILD_COMMAND}}` / `{{TEST_COMMAND}} && {{BUILD_COMMAND}}`

**框架偵測**（按語言分支）：
- TypeScript/JavaScript：讀 package.json 的 dependencies/devDependencies
  - next → Next.js
  - react → React
  - vue → Vue
  - angular → Angular
  - express → Express
  - nestjs → NestJS
- Python：讀 requirements.txt 或 pyproject.toml
  - fastapi → FastAPI
  - django → Django
  - flask → Flask
- Go：讀 go.mod
  - gin → Gin
  - echo → Echo
  - fiber → Fiber
- 其他語言：嘗試從設定檔推斷
- 偵測不到 → 標記「無框架 / 未偵測到」

**測試指令偵測**：
- package.json 有 scripts.test → 使用該值
- package.json 無 scripts.test 但 devDependencies 有 vitest → `npx vitest run`
- package.json 無 scripts.test 但 devDependencies 有 jest → `npx jest`
- Python → `pytest` 或 `python -m pytest`
- Go → `go test ./...`
- Rust → `cargo test`
- 其他 → 檢查 Makefile 有無 test target
- 偵測不到 → 標記「未偵測到」

**建置指令偵測**：
- package.json 有 scripts.build → 使用該值（如 `npm run build`）
- Go → `go build ./...`
- Rust → `cargo build`
- 其他 → 檢查 Makefile 有無 build target
- 偵測不到 → 標記「未偵測到」

**專案名稱**：
- 若用戶有傳入 `$ARGUMENTS` → 使用用戶指定的名稱
- 否則 → 使用當前目錄名稱

### Step 2.5：偵測結果驗證

檢查語言、框架、測試指令、建置指令四個值。

**若全部都是「未偵測到」**：
- 用 AskUserQuestion **強制提醒**用戶：
  ```
  ⚠️ 沒有偵測到任何專案配置。

  可能的原因：
  - 當前目錄不是專案根目錄
  - 專案還沒有初始化（缺少 package.json / go.mod 等）
  - 專案結構不在預設偵測範圍內

  請選擇：
  1. 手動輸入所有配置值（至少需要語言和測試指令）
  2. 切換到正確的專案目錄後重新執行
  3. 繼續生成（配置欄位留空，之後手動補全 CLAUDE.md）
  ```
- 用戶選「手動輸入」→ 逐一詢問：語言（必填）、框架（選填）、測試指令（必填）、建置指令（選填）
- 用戶選「切換目錄」→ 終止執行
- 用戶選「繼續生成」→ 將所有「未偵測到」的欄位值設為 `待填寫`，在最終報告中加上明顯警告

**若部分是「未偵測到」**：
- 在 Step 3 的確認畫面中，對「未偵測到」的欄位加上 ⚠️ 標記，提醒用戶注意

### Step 3：互動確認

用 AskUserQuestion 將偵測結果呈現給用戶確認。格式如下：

```
偵測到的專案配置：

- 專案名稱：[名稱]
- 語言：[語言]          ← 若未偵測到加 ⚠️
- 框架：[框架]          ← 若未偵測到加 ⚠️
- 測試指令：[指令]       ← 若未偵測到加 ⚠️
- 建置指令：[指令]       ← 若未偵測到加 ⚠️
- 增量驗證：[LINT_COMMAND]
- 完整驗證：[VERIFY_SEQUENCE]
- 語言指南：✅ [語言].md / — 無對應語言指南
（若從子目錄偵測：偵測來源：[子目錄名稱]/）

請確認是否正確，或選擇「修正」手動輸入。
```

選項：
- 「確認，開始生成」
- 「需要修正」→ 用戶手動輸入正確值

若用戶選擇修正，逐一詢問需要修正的欄位。

### Step 4：模板填充與生成

1. 用 Read 工具讀取模板：`{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md`
2. 將模板內容中的 placeholder 替換為實際值：

| Placeholder | 替換為 |
|-------------|--------|
| `{{PROJECT_NAME}}` | 確認後的專案名稱 |
| `{{LANGUAGE}}` | 確認後的語言 |
| `{{FRAMEWORK}}` | 確認後的框架 |
| `{{TEST_COMMAND}}` | 確認後的測試指令 |
| `{{BUILD_COMMAND}}` | 確認後的建置指令 |
| `{{LINT_COMMAND}}` | 增量驗證指令（見語言工具鏈映射） |
| `{{VERIFY_SEQUENCE}}` | 完整驗證序列（見語言工具鏈映射） |
| `{{LANGUAGE_SKILL_SECTION}}` | 語言規範區塊（見下方邏輯） |

3. 用 Write 工具將替換後的內容寫入當前目錄的 `CLAUDE.md`
4. 複製 .claudedocs/ 目錄到當前專案（靜態檔案，用 Bash cp 複製以避免 output token 溢出）：
   - 用 Bash 執行：
     ```bash
     cp -r {{REPO_PATH}}/dev-closed-loop/.claudedocs/ .claudedocs/ && find .claudedocs -name '.DS_Store' -delete
     ```
   - 若偵測到有對應語言 Skill → 保留 `languages/` 子目錄（下方第 5 點會刪除非目標語言檔）
   - 若無對應語言 Skill → 用 Bash 執行 `rm -rf .claudedocs/languages/` 移除語言目錄
5. **語言 Skill 部署**（若偵測到有對應 Skill）：
   - `.claudedocs/languages/` 已由 Step 4.4 的 `cp -r` 複製完成
   - 移除非目標語言的 Skill 檔案，只保留偵測到的語言：
     ```bash
     # 保留 README.md 和目標語言檔，刪除其餘
     find .claudedocs/languages -name '*.md' ! -name 'README.md' ! -name '{語言小寫}.md' -delete
     ```
   - 將 `{{LANGUAGE_SKILL_SECTION}}` 替換為以下語言規範區塊：
     ```
     ## 語言規範

     本專案使用 **{語言}**。語言指南位於 `.claudedocs/languages/{語言小寫}.md`。
     各 Phase 描述中標注「**語言指南**」時，讀取該檔案的對應 Phase 段落。
     ```
   - 將 `{{LINT_COMMAND}}` 替換為語言工具鏈映射表的對應值（優先使用 Step 2 偵測到的專案 lint 指令）
   - 將 `{{VERIFY_SEQUENCE}}` 替換為語言工具鏈映射表的對應值（優先使用 Step 2 偵測到的專案指令組合）
6. **無對應 Skill 時**：
   - 不建立 `languages/` 目錄
   - 將 `{{LANGUAGE_SKILL_SECTION}}` 替換為空字串（整個區塊消失）
   - 將 `{{LINT_COMMAND}}` 替換為 `{{BUILD_COMMAND}}` 的確認值
   - 將 `{{VERIFY_SEQUENCE}}` 替換為 `{{TEST_COMMAND}} && {{BUILD_COMMAND}}` 的確認值

**若用戶選擇「升級」模式**：
- 使用 Step 1.5 提取的配置值填充新模板（不走 Step 2/3 的偵測流程）
- 若偵測到用戶自訂內容 → 在新 CLAUDE.md 頂部插入自訂內容，加分隔線 `---`，再接閉環模板
- .claudedocs/ 和 Hook 腳本正常覆蓋更新（Step 4.4 和 Step 4b 照常執行）
- 語言 Skill 部署：根據提取的語言值決定（與全新部署邏輯相同）

**若用戶選擇「合併」模式**：
- 先讀取現有的 CLAUDE.md 內容
- 在末尾追加分隔線 `---` 和閉環模板內容
- 提醒用戶手動整理合併後的內容

### Step 4b：部署 Hook 系統

閉環透過五個 Hook 自動化品質保障：
- **修改前因果鏈守衛**（PreToolUse）：同一輪指令內首次修改既有原始碼檔時擋一次，印出引用者清單，要求先輸出 2-4 行因果鏈分析再重試。不擋新檔與 md / json / yaml 等非原始碼
- **因果鏈重置**（UserPromptSubmit）：清除本 session 的因果鏈 marker，讓每個新指令重新分析一次。無關鍵字判斷、不阻擋
- **增量驗證**（PostToolUse）：修改後自動 per-file lint
- **委派追蹤**（PostToolUse）：Agent 呼叫自動記錄
- **學習日誌提醒**（PostToolUse）：git commit 後檢查 learning-log.md 是否在 commit 中

（v8 移除：委派前因果鏈閘門 `delegation-gate.sh`、理解確認旗標 `prompt-understanding-guard.sh`。deploy-hooks.sh 會清除舊部署的殘留腳本與 settings.json 項目。）

**⛔ 一鍵部署（禁止跳過，禁止手動替代）**：
用 Bash 執行部署腳本（腳本內部自動完成複製、配置、驗證）：
```bash
bash {{REPO_PATH}}/dev-closed-loop/deploy-hooks.sh {{REPO_PATH}}
```

腳本輸出會顯示部署結果。若輸出 `✅ Hook 系統部署完成` → 成功；若輸出 `❌` → 在 Step 5 報告中標記問題。

**確認輸出**：在 Step 5 的最終報告中加上 hook 狀態：
   ```
   ✅ 開發設計閉環已部署完成
   ...
   - 修改前因果鏈守衛 Hook：✅ 已部署（PreToolUse → 既有原始碼檔首次修改擋一次，要求 2-4 行因果鏈分析）
   - 因果鏈重置 Hook：✅ 已部署（UserPromptSubmit → 每輪清除 marker）
   - 增量驗證 Hook：✅ 已部署（PostToolUse → per-file lint）
   - 委派追蹤 Hook：✅ 已部署（PostToolUse → Agent 呼叫記錄）
   - 學習日誌提醒 Hook：✅ 已部署（PostToolUse → git commit 後檢查 learning-log）
   ```

### Step 5：驗證

生成完成後，執行以下檢查：

1. **Placeholder 殘留檢查**：用 Grep 搜尋 CLAUDE.md 中是否還有 `{{` 和 `}}`
   - 有殘留 → 報錯，列出殘留位置，嘗試修正
   - 無殘留 → 通過

2. **.claudedocs 完整性檢查**：確認以下檔案都已複製：
   - `.claudedocs/README.md`
   - `.claudedocs/concepts/閉環核心理念.md`
   - `.claudedocs/process/五階段閉環流程.md`
   - `.claudedocs/process/層級擴展.md`
   - `.claudedocs/standards/Agent使用指南.md`
   - `.claudedocs/standards/Git工作流.md`
   - `.claudedocs/standards/產出物格式.md`
   - `.claudedocs/records/問題追蹤.md`
   - `.claudedocs/process/跨Session持久化.md`
   - `.claudedocs/process/介面契約與變更管理.md`

3. **Agent 專家庫完整性檢查**：
   - `.claudedocs/agents/README.md`
   - `.claudedocs/agents/requirements-analyst.md`
   - `.claudedocs/agents/architect.md`
   - `.claudedocs/agents/design-reviewer.md`
   - `.claudedocs/agents/implementer.md`
   - `.claudedocs/agents/code-reviewer.md`
   - `.claudedocs/agents/security-reviewer.md`
   - `.claudedocs/agents/tester.md`
   - `.claudedocs/agents/verifier.md`
   （9 檔全部存在 → ✅；缺失 → 報告缺失項目）

4. **語言 Skill 完整性檢查**（若部署了語言 Skill）：
   - `.claudedocs/languages/README.md`
   - `.claudedocs/languages/{語言}.md`
   （若未部署語言 Skill → 跳過此檢查）

5. **Hook 部署檢查**：
   - `.claude/hooks/impact-analysis-guard.sh` 存在且可執行
   - `.claude/hooks/causal-chain-reset.sh` 存在且可執行
   - `.claude/hooks/incremental-lint.sh` 存在且可執行
   - `.claude/hooks/delegation-tracker.sh` 存在且可執行
   - `.claude/hooks/learning-log-checker.sh` 存在且可執行
   - `.claude/hooks/_helpers.sh` 存在
   - `.claude/settings.json` 包含 `PreToolUse` hook 配置（含 impact-analysis-guard）
   - `.claude/settings.json` 包含 `PostToolUse` hook 配置（含 incremental-lint、delegation-tracker、learning-log-checker）
   - `.claude/settings.json` 包含 `UserPromptSubmit` hook 配置（含 causal-chain-reset）
   - `.claude/settings.json` 不含已移除的 `delegation-gate`、`prompt-understanding-guard`
   （若任一檢查失敗 → 報錯並嘗試修正）

6. **結果報告**：根據部署模式輸出對應摘要。

**全新部署 / 覆蓋模式**：
```
✅ 開發設計閉環已部署完成

生成的檔案：
- CLAUDE.md（閉環主檔案，Claude Code 啟動時自動讀取）
- .claudedocs/（10 份核心文檔，給人類閱讀）
- .claudedocs/agents/（8 個專家 Agent prompt，無需外部依賴）
- .claudedocs/languages/（語言指南：{語言}.md）← 有對應 Skill 時顯示
- 修改前因果鏈守衛 Hook：✅ 已部署（PreToolUse → 既有原始碼檔首次修改擋一次，要求 2-4 行因果鏈分析）
- 因果鏈重置 Hook：✅ 已部署（UserPromptSubmit → 每輪清除 marker）
- 增量驗證 Hook：✅ 已部署（PostToolUse → per-file lint）
- 委派追蹤 Hook：✅ 已部署（PostToolUse → Agent 呼叫記錄）
- 學習日誌提醒 Hook：✅ 已部署（PostToolUse → git commit 後檢查 learning-log）

專案配置：
- 語言：[語言]
- 框架：[框架]
- 測試指令：[指令]
- 建置指令：[指令]

下一步：
1. 開始開發時，Claude 會自動遵循閉環流程（含 Phase 1b 獨立設計審查）
2. 想了解閉環怎麼運作，讀 .claudedocs/concepts/閉環核心理念.md
3. 想看每個階段做什麼，讀 .claudedocs/process/五階段閉環流程.md
4. 若專案有 ≥ 3 個模組，建議建立 .claude-loop/ 持久化目錄
   詳見 .claudedocs/process/跨Session持久化.md

[若 claude-mem 未安裝]
💡 安裝 claude-mem 插件可啟用跨時間語義記憶
   （Phase 前自動查詢歷史決策、Phase 後自動保存經驗教訓）
```

**升級模式**：
```
✅ 開發設計閉環已升級完成：v{舊版本} → v{新版本}

更新的檔案：
- CLAUDE.md（方法論已更新，專案配置已保留）
- .claudedocs/（10 份核心文檔已更新）
- .claudedocs/agents/（8 個專家 Agent prompt 已更新）
- .claudedocs/languages/（語言指南已更新）← 有對應 Skill 時顯示
- 修改前因果鏈守衛 Hook：✅ 已更新（PreToolUse → 既有原始碼檔首次修改擋一次）
- 因果鏈重置 Hook：✅ 已更新（UserPromptSubmit → 每輪清除 marker）
- 增量驗證 Hook：✅ 已更新
- 舊版 hook（delegation-gate / prompt-understanding-guard）：🧹 已清除
[若有用戶自訂內容]
- 用戶自訂內容：已保留在 CLAUDE.md 頂部（{N} 行）

專案配置（從舊版提取，未變更）：
- 語言：[語言]
- 框架：[框架]
- 測試指令：[指令]
- 建置指令：[指令]

版本差異摘要：
[根據舊版本動態生成，以下為參考]
- v4.x → v5.0.0：新增 Phase 1b 獨立設計審查、Phase 3/5 sub-agent 架構
- v5.0.0 → v5.1.0：新增依賴影響分析規則
- v5.1.0 → v5.2.0：委派產出物必須寫入 .claude-loop/artifacts/
- v5.2.0 → v5.3.0：新增委派追蹤 Hook（Agent 呼叫自動記錄）
- v5.3.0 → v5.5.0：領域偵測、arch-risk 嚴重度、P5 雙向合併、測試分層、配額管理
- v5.5.0 → v5.6.0：新增因果鏈守衛 Hook（PreToolUse → 修改前影響分析提醒）
- v5.6.0 → v5.7.0：自動更新系統 + 三位數版本制（curl 安裝、upgrade 模式、GitHub 版本偵測）
- v5.7.0 → v5.8.0：因果鏈分析可見性 + 深度規則（必須在畫面輸出推導過程，穿透呼叫鏈/語意/時序/邊界）
- v5.8.0 → v5.9.0：合理性審查（Phase 1 自檢 + Phase 3 審查維度 + 非閉環通用規則）
- v5.9.0 → v5.10.0：架構體質拆解（第一性原理：Phase 1 設計前拆解現有架構假設、Phase 1b 審查架構體質）
- v5.10.0 → v5.10.1：模板瘦身（子 agent prompt 移至 .claudedocs/standards/委派審查prompt.md，模板 512→448 行）
- v5.12.0 → v5.13.0：全 Hook 阻擋式升級——因果鏈守衛 + 理解確認守衛均為 exit 2 block 機制（雙閘門合併阻擋，一次 block 同時要求理解確認 + 因果鏈分析）
- v5.13.0 → v5.14.0：Agent 專家庫（.claudedocs/agents/ 8 個專家 prompt），方法論自包含無外部依賴
- v5.14.0 → v5.15.0：精簡閉環迷你追溯（步驟 4.5 正向覆蓋表）+ CLAUDE_TEMPLATE 認知負荷降低（606→361 行，-40%）
- v5.15.0 → v5.16.0：回顧式學習自動化——學習日誌（失敗事件立即捕獲 + commit 前追加 + PostToolUse Hook 檢查）+ 模式分析
- v5.16.0 → v5.17.0：Agent 調用精確化（自文檔化調用方式 + 活動日誌 + learning-log agent 標籤 + Task activeForm 即時可見性 + 斷點狀態回退）
- v5.17.0 → v5.17.1：升級系統 SHA 追蹤（下載時記錄 commit SHA + 版本同但 SHA 異時警告 + status 顯示 SHA）
- v5.17.1 → v5.18.0：Hook 系統修正 + 委派前閘門——因果鏈 marker 每輪重置（P0）+ 短指令偵測擴充（P1）+ 新增 delegation-gate.sh 硬閘門（修改型 Agent 委派前強制因果鏈分析）+ 委派後範圍檢查規則

下一步：
1. 閉環流程已自動生效，無需額外操作
2. 執行 `/dev:init-claude status` 驗證部署健康狀態
3. 建議瀏覽 .claudedocs/concepts/閉環核心理念.md 了解新版變更
```

---

## 重要規則

- 所有互動使用**繁體中文**
- 偵測結果必須向用戶確認，**不能跳過確認步驟**
- 每個 placeholder 都必須替換完畢，不能有殘留
- 若模板來源路徑不存在，終止並告知，**不要嘗試從記憶中生成模板內容**
- 靜態檔案（.claudedocs/、Hook 腳本）用 Bash `cp` 複製（POSIX 標準指令，零 output token 消耗）；需 placeholder 替換的檔案（CLAUDE_TEMPLATE.md）用 Read + Write
- 若用戶取消，不做任何檔案修改
