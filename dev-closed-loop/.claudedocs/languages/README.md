# 語言 Skill 層

> 為閉環 Phase 1-5 提供語言特定的規範、工具鏈指令和最佳實踐。

## 設計原則

- **自建自持**：所有 Skill 檔案存放在本目錄，零外部依賴
- **閉環映射**：每份 Skill 按 Phase 1-5 結構提供補充規範
- **語言偵測**：根據檔案副檔名和專案配置自動啟用對應 Skill
- **內容來源**：整合自 Jeffallan/claude-skills（3,624 ⭐）及其他社群最佳實踐

## 可用語言

| 語言 | 檔案 | 偵測條件 | 主要工具鏈 |
|------|------|---------|-----------|
| TypeScript | [typescript.md](typescript.md) | `*.ts`, `*.tsx`, `tsconfig.json` | tsc, eslint, vitest/jest |
| Go | [go.md](go.md) | `*.go`, `go.mod` | go build, go test, golangci-lint |
| Rust | [rust.md](rust.md) | `*.rs`, `Cargo.toml` | cargo build, cargo test, clippy |
| Python | [python.md](python.md) | `*.py`, `pyproject.toml`, `setup.py` | pytest, mypy, ruff |
| C# | [csharp.md](csharp.md) | `*.cs`, `*.csproj`, `*.sln` | dotnet build, dotnet test, dotnet-format |

## 閉環整合方式

### 各 Phase 使用時機

| Phase | 讀取內容 | 用途 |
|-------|---------|------|
| Phase 1 📐 | 型別系統指南、常見 BC-x/EH-x 模式、設計模式 | 產出語言慣用的設計規格 |
| Phase 2 💻 | 編碼慣例、專案結構、工具鏈指令（lint/format） | 按語言規範實作，增量驗證用 lint 指令 |
| Phase 3 🔍 | 審查清單、安全/效能反模式 | 語言專屬的檢核項目 |
| Phase 4 🧪 | 測試框架、測試模式、Mock 模式 | 用語言原生測試工具執行驗證 |
| Phase 5 ✅ | 驗證指令（build + typecheck + test） | 自証的最終驗證命令 |

### CLAUDE.md 動態引用

CLAUDE.md 透過三個機制與語言 Skill 連接：

1. **語言規範區塊**（`{{LANGUAGE_SKILL_SECTION}}`）：注入「強制規則」指令，要求 Claude 在進入每個 Phase 前先讀取語言指南對應段落
2. **增量驗證指令**（`{{LINT_COMMAND}}`）：Phase 2 每完成一個檔案後執行的 lint 指令，從語言工具鏈映射取值
3. **完整驗證序列**（`{{VERIFY_SEQUENCE}}`）：Phase 5 自証的完整驗證命令序列，從語言工具鏈映射取值

### 多語言專案

當專案包含多種語言時：
1. 以主要語言（最多程式碼檔案的語言）為主 Skill
2. 各語言檔案按各自的 Skill 規範處理
3. Phase 5 自証時，每種語言的驗證指令都要執行

---

最後修訂：2026-02-24
