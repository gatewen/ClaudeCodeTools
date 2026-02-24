# CLAUDE.md

本檔案提供 Claude Code (claude.ai/code) 在此 repo 工作時的指引。

## 語言設定

- 所有互動使用**繁體中文**

## 這個 Repo 是什麼

Claude Code 工具鏈集中管理。包含自建的軟體品質方法論「開發設計閉環」、對應的 Skill、模板和安裝腳本。這**不是**應用程式專案——沒有 build/test/lint 可跑。是方法論 + 工具的發佈倉庫。

## 倉庫結構

- `setup.sh` — 安裝腳本。將 Skill 部署到 `~/.claude/commands/dev/init-claude.md`（對應 `/dev:init-claude` 指令），過程中把 `{{REPO_PATH}}` 替換為實際的 clone 路徑。
- `dev-closed-loop/CLAUDE_TEMPLATE.md` — 核心產物。自包含的 CLAUDE.md 模板，含完整五階段閉環方法論。內有 `{{PLACEHOLDER}}` 變數，部署到專案時由 Skill 填入實際值。
- `dev-closed-loop/skill/init-claude.md` — Skill 源碼。定義 `/dev:init-claude` 指令（專案偵測、互動確認、模板填充部署）。
- `dev-closed-loop/.claudedocs/` — 10 份核心文檔（concepts/process/standards/records）+ 語言 Skills（languages/），給人類閱讀。部署時會一併複製到目標專案。
- `dev-closed-loop/design/` — 設計歷史（01-04）：原始構想、深度分析、落地路線圖、Skill 設計規劃。僅供參考。

## 核心概念

閉環方法論五階段：架構師（設計規格）→ 程序設計師（實作 + code-simplifier 強制優化）→ 檢核師（檢核報告）→ 測試師（測試報告）→ 自証師（跨產出物一致性驗證）。Phase 5 自証是本方法論的核心特色——用 BC-x / EH-x / R-x 編號做精確追溯，檢查 Phase 1-4 的產出物之間有沒有矛盾。

## 操作方式

**安裝 / 更新**：`bash setup.sh` — 部署 Skill 並驗證所有必要檔案存在。

**安裝後使用**：在任何專案目錄執行 `/dev:init-claude`，即可部署閉環 CLAUDE.md + .claudedocs/ 到該專案。

**依賴**（setup.sh 會檢查）：
- SuperClaude（`sc:*` 系列 Skills）：`pipx install superclaude && superclaude install`
- Superpowers（`superpowers:*` 系列 Skills）：Claude Code 插件 `superpowers@claude-plugins-official`
- claude-mem（可選 — 跨時間語義記憶）：Claude Code 插件 `claude-mem`

## 編輯規範

- `CLAUDE_TEMPLATE.md` 必須保留所有 `{{PLACEHOLDER}}` 標記——它們在部署時才被替換。
- `.claudedocs/` 目錄必須維持 10 個檔案的完整結構（setup.sh 會驗證）。
- `init-claude.md` Skill 源碼中的 `{{REPO_PATH}}` 由 setup.sh 替換為實際路徑——不要寫死路徑。
- 設計歷史文檔（`design/`）僅供參考，修改方法論時不要動這些檔案。
- 更新方法論時，以 `CLAUDE_TEMPLATE.md` 為主（Claude 的執行依據），同步更新 `.claudedocs/` 對應文檔（人類的閱讀參考），兩者保持一致。
- `languages/` 目錄的語言 Skill 遵循 Phase 1-5 結構，新增語言時保持一致格式。
