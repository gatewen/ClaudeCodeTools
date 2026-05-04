# CLAUDE.md

本檔案提供 Claude Code (claude.ai/code) 在此 repo 工作時的指引。

## 語言設定

- 所有互動使用**繁體中文**

## 這個 Repo 是什麼

Claude Code 工具鏈集中管理。包含自建的軟體品質方法論「開發設計閉環」、對應的 Skill、模板和安裝腳本。這**不是**應用程式專案——沒有 build/test/lint 可跑。是方法論 + 工具的發佈倉庫。

## 倉庫結構

- `setup.sh` — 安裝腳本（雙模式）。支援 `curl | bash` 遠端安裝和本地 `bash setup.sh`。遠端模式從 GitHub 下載 tarball 到 `~/.claude/cache/ClaudeCodeTools/`，本地模式直接從 repo 目錄安裝。將 Skill 部署到 `~/.claude/commands/dev/init-claude.md`（對應 `/dev:init-claude` 指令），過程中把 `{{REPO_PATH}}` 替換為來源路徑。
- `dev-closed-loop/CLAUDE_TEMPLATE.md` — 核心產物。自包含的 CLAUDE.md 模板，含完整五階段閉環方法論。內有 `{{PLACEHOLDER}}` 變數，部署到專案時由 Skill 填入實際值。
- `dev-closed-loop/skill/init-claude.md` — Skill 源碼。定義 `/dev:init-claude` 指令（專案偵測、互動確認、模板填充部署）。
- `dev-closed-loop/.claudedocs/` — 共 33 個檔，分布如下（給人類閱讀，部署時一併複製到目標專案）：
  - 11 份核心方法論文檔（concepts 2 + process 5 + standards 3 + records 1）
  - Agent 專家庫 `agents/` 9 檔（8 個 agent prompt + 1 個 README 索引）
  - 對照範例 `examples/` 5 檔（v6.3.0 K-07 新增）
  - 語言指南 `languages/` 7 檔（6 語言指南：TS/Py/Go/Rust/C#/Bash + 1 個 README 索引）
  - `.claudedocs/README.md` 1 檔（總目錄導覽）
- `dev-closed-loop/hooks/` — 6 個 Hook 腳本（修改前統一守衛 / 委派前因果鏈閘門 / 理解確認旗標 / 增量驗證 / 委派追蹤 / 學習日誌提醒），由 `deploy-hooks.sh` 一鍵部署到 `~/.claude/hooks/`。
- `dev-closed-loop/deploy-hooks.sh` — Hook 部署腳本（複製 + 合併 settings.json + 驗證）。`dev-closed-loop/check-version.sh` — 版本檢查工具（快取/部署/遠端一次比完）。
- `dev-closed-loop/design/` — 設計歷史（01-11）：v3 原始構想 → v4 重寫 → v5 認知驗證層 → v6 Karpathy 行為哲學 + 對照範例 + KPI。僅供參考。

## 核心概念

閉環方法論五階段：架構師（設計規格）→ 程序設計師（實作 + code-simplifier 強制優化）→ 檢核師（檢核報告）→ 測試師（測試報告）→ 自證師（跨產出物一致性驗證）。Phase 5 自證是本方法論的核心特色——用 BC-x / EH-x / R-x 編號做精確追溯，檢查 Phase 1-4 的產出物之間有沒有矛盾。

v6.x 系列在五階段之上加了三層擴充：

- **行為哲學**（v6.0/v6.1）：Karpathy 4 原則橫切自檢（Think / Simplicity / Surgical / Goal）+ Section 12.5 push back 義務（Claude 在 5 種情境主動反對用戶）
- **認知驗證**（v5.23 + v6.2）：事實主張閘門 + 質疑熔斷協議 + Section 12.5 第 5 條反向質疑（Claude 質疑用戶事實前提）
- **健康指標 + 對照範例**（v6.2/v6.3）：3 指標 + 三區間門檻監測方法論本身運作 + 5 個 anti-pattern 對照範例

## 操作方式

**首次安裝**（二擇一）：

1. **一行指令安裝**（推薦）：
   ```bash
   curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
   ```
   自動下載至 `~/.claude/cache/ClaudeCodeTools/`，部署 Skill。

2. **從 git clone 安裝**（開發者）：
   ```bash
   git clone https://github.com/gatewen/ClaudeCodeTools.git
   cd ClaudeCodeTools && bash setup.sh
   ```

**安裝後使用**：在任何專案目錄執行 `/dev:init-claude`，即可部署閉環 CLAUDE.md + .claudedocs/ 到該專案。

**更新**：
- 一行指令安裝者：在任何專案中執行 `/dev:init-claude upgrade`（自動從 GitHub 下載最新版）
- git clone 安裝者：`git pull && bash setup.sh`

**可選增強工具**（v5.14.0 後 Agent 專家庫自包含，以下全部 optional，缺少不影響閉環核心運作）：
- SuperClaude（可選 — `sc:*` 系列分析/設計指令）：`pipx install superclaude && superclaude install`
- Superpowers（可選 — `superpowers:*` 系列 TDD/debugging skills）：Claude Code 插件 `superpowers@claude-plugins-official`
- claude-mem（可選 — 跨時間語義記憶）：Claude Code 插件 `claude-mem`

## 編輯規範

### ⛔ 修改前：依賴影響分析（必做）

修改任何檔案前，**先查下表列出受影響的連動檔案**，再動手。即使只改一行也要做——這個 repo 的檔案之間有內容層級的依賴，沒有編譯器會替你抓不一致。

| 改動位置 | 必須同步檢查的連動檔案 |
|---------|---------------------|
| CLAUDE_TEMPLATE.md — Phase 流程 / 閘門 / 規則 | `.claudedocs/process/五階段閉環流程.md` · `.claudedocs/concepts/閉環核心理念.md` |
| CLAUDE_TEMPLATE.md — 產出物格式 / ID 系統 | `.claudedocs/standards/產出物格式.md` |
| CLAUDE_TEMPLATE.md — 持久化 / .claude-loop | `.claudedocs/process/跨Session持久化.md` |
| CLAUDE_TEMPLATE.md — 介面契約 / IF-x / CR-x | `.claudedocs/process/介面契約與變更管理.md` |
| CLAUDE_TEMPLATE.md — 層級擴展 / 模組層級 | `.claudedocs/process/層級擴展.md` |
| CLAUDE_TEMPLATE.md — 結構變更（section / placeholder 增刪） | `dev-closed-loop/skill/init-claude.md` |
| CLAUDE_TEMPLATE.md — 語言指南引用方式 | `.claudedocs/languages/*.md` |
| CLAUDE_TEMPLATE.md — 認知驗證層 / Section 12-13 | `.claudedocs/agents/architect.md`（Step 0a/0b）· `.claudedocs/agents/design-reviewer.md`（Step 5c）· `.claudedocs/agents/verifier.md`（Step 9c）· `.claudedocs/concepts/閉環核心理念.md`（認知驗證 concept）· `.claudedocs/standards/產出物格式.md`（事實主張閘門格式）· `.claudedocs/records/問題追蹤.md`（#003-#005 認知性種子） |
| `.claudedocs/agents/*.md` — agent 步驟 / 閘門 / severity 變更 | CLAUDE_TEMPLATE.md 對應 Phase 描述 · `.claudedocs/process/五階段閉環流程.md` · `.claudedocs/standards/Agent使用指南.md`（若調用方式變動） |
| `.claudedocs/` — 檔案增刪 | `setup.sh`（驗證清單）· `.claudedocs/README.md` |
| Hook 腳本增刪或行為變更 | `deploy-hooks.sh`（部署邏輯）· `init-claude.md`（Step 4b） |
| `.claudedocs/examples/*.md` — anti-pattern 範例修改（K-07 主檔） | `.claudedocs/concepts/閉環核心理念.md`「Anti-Patterns Summary」段（K-16 對照表）· CLAUDE_TEMPLATE.md Section 0 4 原則對映表（若範例 Q1-Q4 對應變動） |
| `.claudedocs/concepts/方法論運作指標.md` — KPI 指標 / 門檻 / 觸發條件變動（K-11 主檔） | `.claudedocs/records/問題追蹤.md`（升格觸發機制）· CLAUDE_TEMPLATE.md Phase 5 步驟 4.5（觀察項記入機制） |
| 版本號 | CLAUDE_TEMPLATE.md 末尾註解 · `dev-closed-loop/README.md` 版本歷史 · 根 `README.md` 版本歷史 |

**流程**：
1. **查表** → 在回應中明確列出本次受影響的連動檔案清單
2. **修改** → 主檔案 + 所有連動檔案一起改完
3. **自檢** → 用 Read 抽查連動檔案，確認內容無矛盾

### 靜態規則

- `CLAUDE_TEMPLATE.md` 必須保留所有 `{{PLACEHOLDER}}` 標記——它們在部署時才被替換。
- `.claudedocs/` 目錄必須維持完整結構，setup.sh 分三類驗證：核心 17/17（= 11 核心 + 5 examples + 1 `.claudedocs/README.md`）+ agents 9/9（= 8 agent prompt + 1 README）+ languages 7/7（= 6 語言指南 + 1 README）。
- `init-claude.md` Skill 源碼中的 `{{REPO_PATH}}` 由 setup.sh 替換為實際路徑——不要寫死路徑。
- 設計歷史文檔（`design/`）僅供參考，修改方法論時不要動這些檔案。
- 更新方法論時，以 `CLAUDE_TEMPLATE.md` 為主（Claude 的執行依據），同步更新 `.claudedocs/` 對應文檔（人類的閱讀參考），兩者保持一致。
- `languages/` 目錄的語言 Skill 遵循 Phase 1-5 結構，新增語言時保持一致格式。

## 每日日誌（meta layer · 你跟 Claude 的協作脈絡）

> 解決跨 session 失憶。**僅限這個 repo**，個人脈絡不進 git。

### 何時寫

- **達成決策時**（拍板、採用方案、確認方向）
- **用戶糾正/反對你的時刻** + 修正後方向
- **Session 即將結束時** 補 TL;DR header

### 寫去哪

`~/.claude/projects/<repo-slug>/memory/daily/YYYY-MM-DD.md`

> `<repo-slug>` 是 Claude Code 把工作目錄絕對路徑轉成 slug 的結果（路徑分隔符換成 `-`）。例：
> - macOS `/Users/foo/AI-ClaudeCode` → `-Users-foo-AI-ClaudeCode`
> - Windows `D:\Code\ClaudeCodeTools` → `D--Code-ClaudeCodeTools`
>
> 本 repo 實際在 Windows 為 `D--Code-ClaudeCodeTools`；macOS 上視工作目錄而定。

不存在就建立，存在就 append/edit。範本在同目錄 `_template.md`。

### 寫什麼

- 用戶明確要求/問題（簡短）
- 達成的結論（拍板的事 + 為什麼）
- 用戶糾正你的時刻 + 修正後方向
- 為什麼選 A 不選 B 的理由

### 不寫什麼

- 逐字對話、內心思考
- 中間嘗試但沒成立的猜測
- 純資訊查詢（「這檔幾行」）

### 修正格式（同檔內就地）

- `~~舊結論~~`
- `> ⚠️ [HH:MM update] 新結論：...`
- 文末 `# 修正歷史` section 集中標記重大修正

### 跨檔不追溯

昨天的反悔**不去動昨天那份檔**。以最新時間的結論為準。讀取時 SessionStart hook 會自動載入最後 3 份檔名最新的日誌。

### Hook 機制（自動）

- **SessionStart**：自動讀取 `daily/[0-9]*.md` 中檔名最新的 3 份，注入 context
- **Stop**：今日日誌不存在或長度 < 200 chars → exit 2 + STDERR 提醒補寫；尊重 `stop_hook_active` 防 infinite loop

Hook 腳本位於 `.claude/hooks/`，註冊在 `.claude/settings.json`。整個 `.claude/` 已加入 `.gitignore`（路徑硬編使用者，不適合公開）。
