# dev:init-claude — 開發設計閉環初始化

為當前專案部署「開發設計閉環」方法論 v8：CLAUDE.md、5 份文檔、3 支 hook。

**用戶參數**：$ARGUMENTS

**模式**：
- `/dev:init-claude` 或 `/dev:init-claude [專案名稱]` — 部署 / 升級（預設）
- `/dev:init-claude status` — 查看版本與健康狀態
- `/dev:init-claude upgrade` — 從 GitHub 下載最新版，更新 Skill 與快取
- `/dev:init-claude uninstall` — 移除部署

---

## 模板來源（由 setup.sh 安裝時自動替換路徑）

```
模板檔案：{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md
文檔目錄：{{REPO_PATH}}/dev-closed-loop/.claudedocs/
Hook 腳本：{{REPO_PATH}}/dev-closed-loop/hooks/
部署腳本：{{REPO_PATH}}/dev-closed-loop/deploy-hooks.sh
版本檢查：{{REPO_PATH}}/dev-closed-loop/check-version.sh
```

workflow 腳本（`/dev-prd` `/dev-design` `/dev-review` `/dev-verify`）由 setup.sh 全域部署到 `~/.claude/workflows/`，不由本 skill per-project 部署。

---

## ⛔ 模式分流（最優先）

解析 `$ARGUMENTS` 第一個詞：

| 第一個詞 | 模式 |
|---------|------|
| `status` | → Status 模式 |
| `upgrade` | → Upgrade 模式 |
| `uninstall` | → Uninstall 模式 |
| 其他（含空） | → 部署 / 升級流程 Step 1 |

匹配到前三者時直接跳轉，禁止執行部署流程的任何步驟。

---

## Status 模式

不修改任何檔案。

1. **版本偵測**：
   ```bash
   grep -o 'closed-loop v[0-9.]*' ./CLAUDE.md 2>/dev/null | tail -1
   ```
   - 找不到 CLAUDE.md → 輸出「⚠️ 未部署。執行 `/dev:init-claude` 開始部署」並結束
   - 有 CLAUDE.md 但無 marker → 輸出「ℹ️ CLAUDE.md 存在但非閉環部署」並結束

2. **配置提取**：從 CLAUDE.md 提取語言 / 框架 / 測試指令 / 建置指令。

3. **健康檢查**（逐項用 Bash，每項標 ✅ / ❌ / ⚠️）：

   | 檢查項 | 方法 | 判定 |
   |--------|------|------|
   | 核心文檔 | `.claudedocs/README.md` `concepts/閉環核心理念.md` `standards/產出物格式.md` `standards/Git工作流.md` `records/問題追蹤.md` | 5/5 = ✅，否則 ❌ 列缺少 |
   | v7 殘留文檔 | `.claudedocs/agents/` `languages/` `process/` `examples/` `concepts/方法論運作指標.md` `standards/Agent使用指南.md` 任一存在 | 無 = ✅；有 = ⚠️ 建議 upgrade 清除 |
   | Hook 腳本 | `.claude/hooks/impact-analysis-guard.sh` `causal-chain-reset.sh` `incremental-lint.sh` 存在且可執行；`_helpers.sh` 存在 | ✅ / ❌ |
   | v7 殘留 hook | `.claude/hooks/delegation-gate.sh` `prompt-understanding-guard.sh` `delegation-tracker.sh` `learning-log-checker.sh` 任一存在 | 無 = ✅；有 = ⚠️ 建議 upgrade 清除 |
   | Hook 配置 | `.claude/settings.json` 含 `impact-analysis-guard` `causal-chain-reset` `incremental-lint`，且不含上列 4 個舊 hook 名 | 3/3 且無舊項 = ✅ |
   | Placeholder 殘留 | Grep CLAUDE.md 中的 `{{` | 無 = ✅ |
   | 來源目錄 | `{{REPO_PATH}}/dev-closed-loop/` 存在 | ✅ / ⚠️ 來源不可達 |
   | JSON 工具 | `python3 -c "import json"` 成功，或 `jq --version` 成功 | 任一 = ✅；皆無 = ⚠️ hook 部署需要 |
   | Workflow（全域，可選） | `ls ~/.claude/workflows/dev-prd.js dev-design.js dev-review.js dev-verify.js` | 4/4 = ✅；否則 ℹ️ 未部署（走退化做法，正常）|
   | `.claude-loop/` | 是否存在 | 有 = ℹ️；無 = — 未啟用（正常）|

4. **⛔ 可升級偵測（禁止跳過）**：
   ```bash
   bash {{REPO_PATH}}/dev-closed-loop/check-version.sh {{REPO_PATH}} --deployed ./CLAUDE.md --check-remote
   ```
   依 STATUS：
   - `upgrade_available` / `cache_outdated` → 「🔄 可升級：v{DEPLOYED} → v{CACHE 或 REMOTE}。執行 `/dev:init-claude upgrade`」
   - `up_to_date` → 「✅ 已是最新版本」；若 `SHA_MISMATCH=true` → 加註「有未發版改動（本地 SHA ≠ 遠端 SHA）」
   - `REMOTE_CHECK=failed` → 「✅ 與快取一致（⚠️ 無法連線 GitHub）」
   - `error` → 「⚠️ 無法確認版本」
   輸出必須包含「升級：」行。

5. **輸出格式**：

```
═══ 閉環部署狀態 ═══

版本：v8.0.0（SHA: abc1234）
來源：{{REPO_PATH}}
專案：[名稱] · 語言：[語言] · 框架：[框架]

健康檢查：
  ✅ 核心文檔（5/5）
  ✅ 無 v7 殘留文檔
  ✅ Hook 腳本（3/3 + _helpers.sh）
  ✅ 無 v7 殘留 hook
  ✅ Hook 配置（3/3，無舊項）
  ✅ 無 Placeholder 殘留
  ✅ JSON 工具：jq
  ℹ️ Workflow（全域）：/dev-prd /dev-design /dev-review /dev-verify
  — .claude-loop/ 未啟用

升級：✅ 已是最新版本

整體：✅ 健康
```

有問題時逐條列 ❌ / ⚠️ 並附建議動作（多數為「執行 `/dev:init-claude upgrade`」）。

---

## Upgrade 模式

1. **下載最新版到快取**：
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
   失敗 → 「❌ 下載失敗，請確認網路連線」並終止。成功後記錄 SHA：
   ```bash
   curl -sL --max-time 5 "https://api.github.com/repos/gatewen/ClaudeCodeTools/commits/main" 2>/dev/null | grep '"sha"' | head -1 | sed 's/.*"sha": *"//;s/".*//' > "$HOME/.claude/cache/ClaudeCodeTools/.commit-sha"
   ```

2. **版本比較**：
   ```bash
   bash "$HOME/.claude/cache/ClaudeCodeTools/dev-closed-loop/check-version.sh" "$HOME/.claude/cache/ClaudeCodeTools" --deployed ./CLAUDE.md
   ```
   - `up_to_date` → 「✅ 快取已更新，已是最新 v{CACHE_VERSION}」並結束
   - `upgrade_available` / `not_deployed` → 繼續

3. **更新 Skill 自身**：
   ```bash
   sed "s|{{REPO_PATH}}|$HOME/.claude/cache/ClaudeCodeTools|g" \
     "$HOME/.claude/cache/ClaudeCodeTools/dev-closed-loop/skill/init-claude.md" \
     > "$HOME/.claude/commands/dev/init-claude.md" && echo "OK"
   ```
   告知：「✅ Skill 已更新。handoff 與 workflow 腳本由 setup.sh 部署，若要一併更新請執行 `bash $HOME/.claude/cache/ClaudeCodeTools/setup.sh`」

4. **引導專案升級**（AskUserQuestion）：
   ```
   ✅ 工具已更新：v{舊} → v{新}
   ⚠️ 當前對話仍載著舊版 Skill 定義。
   1. 在新對話執行 /dev:init-claude 完成專案升級 ← 推薦
   2. 繼續在當前對話升級
   ```
   選 1 → 結束。選 2 → 進入部署流程 Step 1（會自動偵測到既有版本走升級分支）。

---

## Uninstall 模式

1. **前置檢查**：CLAUDE.md 含 `closed-loop v` marker，否則「⚠️ 未部署」並結束。

2. **列出將移除的項目**：
   - `CLAUDE.md`（純閉環檔）或其閉環區段（合併檔）
   - `.claudedocs/`（含 v7 殘留子目錄）
   - `.claude/hooks/` 內：`impact-analysis-guard.sh` `causal-chain-reset.sh` `incremental-lint.sh` `_helpers.sh`，以及舊版殘留 `delegation-gate.sh` `prompt-understanding-guard.sh` `delegation-tracker.sh` `learning-log-checker.sh`
   - `.claude/settings.json` 中的閉環 hook 配置
   - `.claude-loop/`（若存在，含進行中的 artifacts 與 learning-log）

3. **用戶確認**（AskUserQuestion）：全部移除 / 保留 `.claude-loop/` / 取消。

4. **執行**：
   - `rm -rf .claudedocs/`
   - `rm -f .claude/hooks/{impact-analysis-guard,causal-chain-reset,incremental-lint,_helpers,delegation-gate,prompt-understanding-guard,delegation-tracker,learning-log-checker}.sh`
   - 從 `.claude/settings.json` 移除 hook 項目（保留其他設定）。優先 jq：
     ```bash
     jq 'def kw: ["impact-analysis-guard","causal-chain-reset","incremental-lint","delegation-gate","prompt-understanding-guard","delegation-tracker","learning-log-checker"];
         def ours: ((.hooks // []) | map(.command // "") | any(. as $c | kw | any(. as $k | $c | contains($k))));
         if .hooks then .hooks |= (with_entries(.value |= map(select(ours | not))) | with_entries(select(.value | length > 0)))
                        | (if (.hooks | length) == 0 then del(.hooks) else . end) else . end' \
        .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
     ```
     無 jq 時用 python3 做等價過濾。
   - **CLAUDE.md**：首行為 `# {專案名}` 且末尾有 `closed-loop v` 註解且中間無非閉環區段 → 純閉環，`rm CLAUDE.md`。否則用 AskUserQuestion 警告含自訂內容，讓用戶選手動處理或全刪。
   - 用戶選擇時 `rm -rf .claude-loop/`

5. **結果報告**：列出已刪項目。

---

## 部署 / 升級流程（預設模式）

### Step 1：前置檢查與版本偵測

1. 確認當前目錄是專案目錄（不是 home、不是根目錄）。
2. 用 Read 讀 `{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md`；讀取失敗 → 告知模板路徑不存在，終止。**不要從記憶生成模板內容。**
3. 檢查 `./CLAUDE.md`：
   - 不存在 → Step 2
   - 存在且含 `closed-loop v` marker → **升級分支**
   - 存在但無 marker → **非閉環衝突**：AskUserQuestion「合併（追加到末尾）/ 覆蓋 / 取消」

**升級分支**：

1. ⛔ 版本檢查（禁止跳過）：
   ```bash
   bash {{REPO_PATH}}/dev-closed-loop/check-version.sh {{REPO_PATH}} --deployed ./CLAUDE.md --check-remote
   ```
   - `cache_outdated`（遠端 > 快取）→ AskUserQuestion：先更新快取（執行 Upgrade 模式步驤 1-3 後用新快取繼續）/ 用現有快取 / 取消
   - `upgrade_available` → 繼續
   - `up_to_date` → 告知已是最新，問是否重新部署
   - `REMOTE_CHECK=failed` → 「⚠️ 無法連線 GitHub，使用本地快取」，繼續
2. 取 `DEPLOYED_VERSION`：
   ```bash
   grep -o 'closed-loop v[0-9.]*' ./CLAUDE.md | tail -1 | sed 's/closed-loop v//'
   ```
3. **主版號 < 8**（即 v7.x 或更早）→ 顯示 v8 breaking 摘要並讓用戶選策略（AskUserQuestion）：
   ```
   🔄 v{DEPLOYED} → v{CACHE}：v8 為整體重寫

   破壞性變更：
   - CLAUDE.md 344 行 → 不到 200 行，五階段 / Karpathy 對映表 / 領域偵測 / 升格降級 / KPI 全部移除
   - hook 6 → 3（刪 delegation-gate / prompt-understanding-guard / delegation-tracker / learning-log-checker）
   - .claudedocs 33 → 5 檔（agents / languages / process / examples / KPI / Agent使用指南 不再部署）
   - placeholder 6 → 5（LANGUAGE_SKILL_SECTION 移除）

   請選擇：
   A. 全替換（推薦）— 用 v8 模板覆蓋 CLAUDE.md，專案配置自動保留，v7 殘留文檔與 hook 自動清除
   C. 手動 diff — 印出 diff 後我自己處理
   ```
   v8 不支援智能合併（B），因為結構全變。用戶自訂內容（模板區段之外的部分）在 A 策略下會保留在頂部。
   選 A → Step 1.5 → Step 4。選 C → `diff -u ./CLAUDE.md {{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md | head -200`，終止。
4. **主版號 ≥ 8** → 一般升級：AskUserQuestion「升級（保留配置）/ 全新部署（重新偵測）/ 取消」。升級 → Step 1.5 → Step 4。

### Step 1.5：配置提取（僅升級）

從現有 CLAUDE.md 提取：

| 欄位 | 提取方式 |
|------|---------|
| `PROJECT_NAME` | 第一行 `# ` 後的文字 |
| `LANGUAGE` | `**語言**：` 後的值 |
| `FRAMEWORK` | `**框架**：` 後的值 |
| `TEST_COMMAND` | `**測試指令**：` 後反引號內的值 |
| `BUILD_COMMAND` | `**建置指令**：` 後反引號內的值 |

用 AskUserQuestion 向用戶確認提取結果，可選「修正」逐一改。

**自訂內容**：掃描現有 CLAUDE.md，找出不屬於模板的內容（模板首行 `# {專案名}` 之前的段落，或末尾 `-->` 之後的內容）。有 → 提示「偵測到自訂內容（N 行），將保留在升級後的 CLAUDE.md 頂部」。

### Step 2：專案偵測

**掃描策略**：先看根目錄有無專案標誌檔（package.json / go.mod / Cargo.toml / pyproject.toml / requirements.txt / pom.xml / *.csproj / Makefile）。沒有 → 掃一層子目錄；找到 1 個就用它並告知用戶；多個 → AskUserQuestion 選；都沒有 → 全標「未偵測到」進 Step 2.5。

**語言**（按優先序）：go.mod → Go；Cargo.toml → Rust；package.json 且有 .ts/.tsx → TypeScript；package.json → JavaScript；requirements.txt / pyproject.toml / setup.py → Python；*.csproj / *.sln → C#；pom.xml / *.java → Java；*.swift → Swift；*.rb → Ruby；*.sh 含 bash shebang → Bash；否則「未偵測到」。

**框架**：TS/JS 讀 package.json dependencies（next / react / vue / angular / express / nestjs）；Python 讀 requirements 或 pyproject（fastapi / django / flask）；Go 讀 go.mod（gin / echo / fiber）；C# 讀 csproj（Microsoft.AspNetCore / Unity）；偵測不到 → 「無框架 / 未偵測到」。

**測試指令**：package.json scripts.test → 該值；有 vitest → `npx vitest run`；有 jest → `npx jest`；Python → `pytest`；Go → `go test ./...`；Rust → `cargo test`；C# → `dotnet test`；否則看 Makefile test target；偵測不到 → 「未偵測到」。

**建置指令**：package.json scripts.build → 該值；Go → `go build ./...`；Rust → `cargo build`；C# → `dotnet build`；TS 無 build script → `npx tsc --noEmit`；Python → `ruff check . && mypy .`（若專案有其一）；否則 Makefile build target；偵測不到 → 「未偵測到」。

**專案名稱**：`$ARGUMENTS` 有給就用；否則當前目錄名。

### Step 2.5：偵測結果驗證

四個值全「未偵測到」→ AskUserQuestion 強制提醒：手動輸入（語言、測試指令必填）/ 切換目錄後重跑 / 繼續生成（欄位填 `待填寫`，報告加警告）。部分未偵測到 → Step 3 確認畫面對該欄位加 ⚠️。

### Step 3：互動確認

AskUserQuestion 呈現：專案名稱 / 語言 / 框架 / 測試指令 / 建置指令（未偵測到的加 ⚠️；從子目錄偵測的標來源）。選項：「確認，開始生成」/「需要修正」→ 逐一改。

### Step 4：模板填充與文檔部署

1. 用 Read 讀模板，替換 5 個 placeholder：`{{PROJECT_NAME}}` `{{LANGUAGE}}` `{{FRAMEWORK}}` `{{TEST_COMMAND}}` `{{BUILD_COMMAND}}`。
2. 用 Write 寫入 `./CLAUDE.md`。升級且有自訂內容 → 自訂內容在頂部，加 `---` 分隔，再接模板。合併模式 → 讀現有內容，末尾加 `---` 再接模板，提醒用戶手動整理。
3. 複製文檔（靜態檔用 Bash cp）：
   ```bash
   mkdir -p .claudedocs && cp -r {{REPO_PATH}}/dev-closed-loop/.claudedocs/. .claudedocs/ && find .claudedocs -name '.DS_Store' -delete
   ```
   **升級時保留專案自己的問題追蹤**：若 `.claudedocs/records/問題追蹤.md` 已存在且含用戶自己加的條目（非模板原文），先備份為 `問題追蹤.md.bak-{日期}` 再覆蓋，並在報告中提醒用戶合併。
4. **清除 v7 殘留**（升級時；全新部署時目錄本來就不存在）：
   ```bash
   rm -rf .claudedocs/agents .claudedocs/languages .claudedocs/process .claudedocs/examples
   rm -f ".claudedocs/concepts/方法論運作指標.md" ".claudedocs/standards/Agent使用指南.md"
   ```

### Step 4b：部署 Hook

⛔ 一鍵部署，禁止手動替代：
```bash
bash {{REPO_PATH}}/dev-closed-loop/deploy-hooks.sh {{REPO_PATH}}
```
腳本會複製 3 支 hook 與 `_helpers.sh`、合併 `.claude/settings.json`（python3 → python → jq）、清除 4 支舊 hook 的腳本與設定項、驗證。輸出 `✅ Hook 系統部署完成` 即成功；`❌` → 在 Step 5 報告標記，最常見原因是 python3 與 jq 皆不可用。

### Step 5：驗證與報告

1. **Placeholder 殘留**：Grep `./CLAUDE.md` 中的 `{{`，有 → 報錯並修正。
2. **文檔完整**：`.claudedocs/README.md` `concepts/閉環核心理念.md` `standards/產出物格式.md` `standards/Git工作流.md` `records/問題追蹤.md` 5/5。
3. **v7 殘留**：`.claudedocs/{agents,languages,process,examples}` 與 `concepts/方法論運作指標.md` `standards/Agent使用指南.md` 皆不存在。
4. **Hook**：`.claude/hooks/impact-analysis-guard.sh` `causal-chain-reset.sh` `incremental-lint.sh` 可執行；`_helpers.sh` 存在；`settings.json` 含三者、不含四個舊 hook 名。
5. **報告**：

```
✅ 開發設計閉環 v8 已部署完成

- CLAUDE.md（不到 200 行，每個 session 自動載入）
- .claudedocs/（5 份文檔）
- Hook：impact-analysis-guard（修改前因果鏈守衛）· causal-chain-reset（每輪重置）· incremental-lint（增量 lint）
[升級時] - 已清除 v7 殘留：N 個文檔目錄、N 支舊 hook
[有自訂內容時] - 自訂內容保留在 CLAUDE.md 頂部（N 行）
[問題追蹤有備份時] - 舊問題追蹤備份於 .claudedocs/records/問題追蹤.md.bak-{日期}，請自行合併條目

專案配置：語言 [L] · 框架 [F] · 測試 `[T]` · 建置 `[B]`

下一步：
1. 直接開始開發，規則已生效
2. 想知道規則為什麼是這樣：.claudedocs/concepts/閉環核心理念.md
3. 踩到坑就寫進 .claudedocs/records/問題追蹤.md，下次設計前會被掃到
4. 大型任務可用 /dev-design、/dev-review（需付費方案與 research preview）
```

---

## 重要規則

- 所有互動使用**繁體中文**
- 偵測結果必須向用戶確認，不能跳過
- 每個 placeholder 都必須替換完畢
- 模板來源不存在時終止並告知，**不要從記憶生成模板內容**
- 靜態檔案用 Bash `cp`；需替換的 CLAUDE.md 用 Read + Write
- 用戶取消時不做任何檔案修改
