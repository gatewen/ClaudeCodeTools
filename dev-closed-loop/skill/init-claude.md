# dev:init-claude — 開發設計閉環初始化

為當前專案部署「開發設計閉環」方法論的 CLAUDE.md 和補充文檔。

**用戶參數**：$ARGUMENTS
（可傳入專案名稱，例如 `/dev:init-claude my-awesome-project`。若未提供，使用當前目錄名稱。）

---

## 模板來源（由 setup.sh 安裝時自動替換路徑）

```
模板檔案：{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md
文檔目錄：{{REPO_PATH}}/dev-closed-loop/.claudedocs/
語言指南：{{REPO_PATH}}/dev-closed-loop/.claudedocs/languages/
Hook 腳本：{{REPO_PATH}}/dev-closed-loop/hooks/
```

---

## 執行步驟（嚴格按順序）

### Step 0：環境依賴檢查

閉環需要 SuperClaude 和 Superpowers 才能正常運作。在其他步驟前先檢查。

1. **檢查 SuperClaude**：用 Bash 執行 `ls ~/.claude/commands/sc/ 2>/dev/null | head -1`
   - 有輸出 → SuperClaude 已安裝 ✅
   - 無輸出 → SuperClaude 未安裝 ❌

2. **檢查 Superpowers**：用 Bash 執行 `grep -q "superpowers@claude-plugins-official" ~/.claude/plugins/installed_plugins.json 2>/dev/null && echo "installed"`
   - 輸出 "installed" → Superpowers 已安裝 ✅
   - 無輸出 → Superpowers 未安裝 ❌

3. **檢查 claude-mem**（可選）：用 Bash 執行 `grep -rq "claude-mem" ~/.claude/plugins/ 2>/dev/null && echo "installed" || grep -q "claude-mem" ~/.claude/.mcp.json 2>/dev/null && echo "installed"`
   - 輸出 "installed" → claude-mem 已安裝 ✅
   - 無輸出 → claude-mem 未安裝（可選功能，不影響閉環運作）

4. **結果處理**：
   - claude-mem 的缺少**不觸發** AskUserQuestion、不加入缺少項目列表，僅獨立顯示狀態（✅ 已安裝 或 ℹ️ 未安裝）
   - SuperClaude 和 Superpowers 都已安裝 → 繼續 Step 1
   - SuperClaude 或 Superpowers 有缺少的 → 用 AskUserQuestion 告知用戶：
     ```
     ⚠️ 閉環需要以下工具，但偵測到缺少：

     [僅列出缺少的項目]
     - SuperClaude：pipx install superclaude && superclaude install
       https://github.com/SuperClaude-Org/SuperClaude_Framework
     - Superpowers：在 Claude Code 中安裝插件 superpowers@claude-plugins-official

     請選擇：
     1. 我已了解，先繼續部署（之後再安裝）
     2. 取消，我先去安裝
     ```
   - 用戶選繼續 → 在最終報告（Step 5）加上缺少工具的警告
   - 用戶選取消 → 終止執行

### Step 1：前置檢查

1. 確認當前工作目錄是一個合理的專案目錄（不是 home 目錄、不是根目錄）
2. 檢查模板來源是否存在：
   - 用 Read 讀取 `{{REPO_PATH}}/dev-closed-loop/CLAUDE_TEMPLATE.md`
   - 若讀取失敗 → 告知用戶模板路徑不存在，終止
3. 檢查當前目錄是否已有 `CLAUDE.md`：
   - 若已存在 → 進入「衝突處理」流程（見下方）
   - 若不存在 → 繼續

**衝突處理**：若已存在 CLAUDE.md，用 AskUserQuestion 詢問用戶：
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
4. 複製 .claudedocs/ 目錄到當前專案：
   - 用 Glob 列出 `{{REPO_PATH}}/dev-closed-loop/.claudedocs/` 下所有 `.md` 檔案
   - 用 Read 逐一讀取每個檔案內容
   - 用 Write 將每個檔案寫入對應的 `.claudedocs/` 路徑（保持子目錄結構）
5. **語言 Skill 部署**（若偵測到有對應 Skill）：
   - 建立 `.claudedocs/languages/` 目錄
   - 用 Read 讀取 `{{REPO_PATH}}/dev-closed-loop/.claudedocs/languages/README.md`
   - 用 Write 寫入 `.claudedocs/languages/README.md`
   - 用 Read 讀取 `{{REPO_PATH}}/dev-closed-loop/.claudedocs/languages/{語言}.md`
   - 用 Write 寫入 `.claudedocs/languages/{語言}.md`
   - 將 `{{LANGUAGE_SKILL_SECTION}}` 替換為以下語言規範區塊：
     ```
     ## 語言規範

     本專案使用 **{語言}**。已部署 [{語言} 語言指南](.claudedocs/languages/{語言小寫}.md)。

     各 Phase 描述中的「**語言指南**」行會指示讀取對應段落。語言指南按 Phase 1-5 組織，對照如下：

     | Phase | 讀取段落 | 用途 |
     |-------|---------|------|
     | Phase 1 📐 | 型別系統指南、BC-x/EH-x 模式 | 產出符合語言慣例的設計規格 |
     | Phase 2 💻 | 編碼慣例、專案結構 | 遵循語言規範實作 |
     | Phase 3 🔍 | 審查清單、安全/效能反模式 | 語言專屬檢核項目 |
     | Phase 4 🧪 | 測試框架、測試模式 | 用語言原生測試工具驗證 |
     | Phase 5 ✅ | 驗證指令序列 | 完整語言特定驗證 |
     ```

     > **適配原則**：語言指南的工具推薦（如 ESLint、Vitest）僅供參考，實際工具以上方「專案配置」區的指令為準。語言指南的**設計模式、安全反模式、審查清單**不受工具選擇影響，一律適用。
   - 將 `{{LINT_COMMAND}}` 替換為語言工具鏈映射表的對應值（優先使用 Step 2 偵測到的專案 lint 指令）
   - 將 `{{VERIFY_SEQUENCE}}` 替換為語言工具鏈映射表的對應值（優先使用 Step 2 偵測到的專案指令組合）
6. **無對應 Skill 時**：
   - 不建立 `languages/` 目錄
   - 將 `{{LANGUAGE_SKILL_SECTION}}` 替換為空字串（整個區塊消失）
   - 將 `{{LINT_COMMAND}}` 替換為 `{{BUILD_COMMAND}}` 的確認值
   - 將 `{{VERIFY_SEQUENCE}}` 替換為 `{{TEST_COMMAND}} && {{BUILD_COMMAND}}` 的確認值

**若用戶選擇「合併」模式**：
- 先讀取現有的 CLAUDE.md 內容
- 在末尾追加分隔線 `---` 和閉環模板內容
- 提醒用戶手動整理合併後的內容

### Step 4b：部署增量驗證 Hook

閉環 Phase 2 增量驗證透過 PostToolUse hook 自動化。每次 Claude 寫入或編輯檔案後，hook 會自動對該檔案執行 per-file lint。

1. **建立 hooks 目錄**：
   - 用 Bash 執行 `mkdir -p .claude/hooks`

2. **部署 lint 腳本**：
   - 用 Read 讀取 `{{REPO_PATH}}/dev-closed-loop/hooks/incremental-lint.sh`
   - 用 Write 寫入 `.claude/hooks/incremental-lint.sh`
   - 用 Bash 執行 `chmod +x .claude/hooks/incremental-lint.sh`

3. **配置 hooks（`.claude/settings.json`）**：
   - 用 Bash 檢查 `.claude/settings.json` 是否存在
   - **存在**：用 Read 讀取現有內容，用 python3 合併 hooks 配置（保留既有設定）：
     ```python
     import json, sys
     existing = json.load(open('.claude/settings.json'))
     hook_entry = {
       "matcher": {"tool_name": "Write|Edit|MultiEdit"},
       "hooks": [{"type": "command", "command": "bash .claude/hooks/incremental-lint.sh"}]
     }
     hooks = existing.setdefault("hooks", {})
     post_hooks = hooks.setdefault("PostToolUse", [])
     # 避免重複：檢查是否已有 incremental-lint
     if not any("incremental-lint" in str(h) for h in post_hooks):
       post_hooks.append(hook_entry)
     json.dump(existing, open('.claude/settings.json', 'w'), indent=2, ensure_ascii=False)
     ```
   - **不存在**：用 Write 建立新的 `.claude/settings.json`：
     ```json
     {
       "hooks": {
         "PostToolUse": [
           {
             "matcher": {
               "tool_name": "Write|Edit|MultiEdit"
             },
             "hooks": [
               {
                 "type": "command",
                 "command": "bash .claude/hooks/incremental-lint.sh"
               }
             ]
           }
         ]
       }
     }
     ```

4. **確認輸出**：在 Step 5 的最終報告中加上 hook 狀態：
   ```
   ✅ 開發設計閉環已部署完成
   ...
   - 增量驗證 Hook：✅ 已部署（PostToolUse → per-file lint）
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

3. **語言 Skill 完整性檢查**（若部署了語言 Skill）：
   - `.claudedocs/languages/README.md`
   - `.claudedocs/languages/{語言}.md`
   （若未部署語言 Skill → 跳過此檢查）

4. **Hook 部署檢查**：
   - `.claude/hooks/incremental-lint.sh` 存在且可執行
   - `.claude/settings.json` 包含 `PostToolUse` hook 配置
   （若任一檢查失敗 → 報錯並嘗試修正）

5. **結果報告**：向用戶輸出完成摘要：

```
✅ 開發設計閉環已部署完成

生成的檔案：
- CLAUDE.md（閉環主檔案，Claude Code 啟動時自動讀取）
- .claudedocs/（10 份核心文檔，給人類閱讀）
- .claudedocs/languages/（語言指南：{語言}.md）← 有對應 Skill 時顯示
- 增量驗證 Hook：✅ 已部署（PostToolUse → per-file lint）

專案配置：
- 語言：[語言]
- 框架：[框架]
- 測試指令：[指令]
- 建置指令：[指令]

下一步：
1. 開始開發時，Claude 會自動遵循五階段閉環流程
2. 想了解閉環怎麼運作，讀 .claudedocs/concepts/閉環核心理念.md
3. 想看每個階段做什麼，讀 .claudedocs/process/五階段閉環流程.md
4. 若專案有 ≥ 3 個模組，建議建立 .claude-loop/ 持久化目錄
   詳見 .claudedocs/process/跨Session持久化.md

[若 claude-mem 未安裝]
💡 進階功能：安裝 claude-mem 插件可啟用跨時間語義記憶
   （Phase 前自動查詢歷史決策、Phase 後自動保存經驗教訓）
```

---

## 重要規則

- 所有互動使用**繁體中文**
- 偵測結果必須向用戶確認，**不能跳過確認步驟**
- 每個 placeholder 都必須替換完畢，不能有殘留
- 若模板來源路徑不存在，終止並告知，**不要嘗試從記憶中生成模板內容**
- 複製 .claudedocs/ 時使用 Read + Write 工具逐一複製，保持目錄結構完整（不依賴平台特定的 shell 指令）
- 若用戶取消，不做任何檔案修改
