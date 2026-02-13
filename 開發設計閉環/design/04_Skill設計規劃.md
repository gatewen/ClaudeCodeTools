# Skill 設計規劃：dev:init-claude

## 目標

建立一個 Claude Code Skill，讓用戶在任何新專案中執行 `/dev:init-claude` 即可自動生成符合「開發設計閉環」方法論的 CLAUDE.md 檔案。

## Skill 基本資訊

```yaml
name: dev:init-claude
description: >
  為當前專案生成遵循「開發設計閉環」方法論的 CLAUDE.md。
  自動偵測專案語言、框架、測試工具，或透過互動式問答收集配置。
trigger_phrases:
  - "建立 CLAUDE.md"
  - "生成開發閉環配置"
  - "初始化專案規範"
  - "create claude md"
```

## 執行流程

### Step 1：專案偵測

自動掃描當前目錄，偵測：

| 偵測項目 | 偵測方式 | 範例 |
|---------|---------|------|
| 語言 | 檔案副檔名分布 | `.go` → Go、`.ts` → TypeScript |
| 框架 | package.json / go.mod / requirements.txt | Next.js、Gin、FastAPI |
| 測試框架 | 設定檔 / dependencies | Jest、pytest、go test |
| 測試指令 | scripts / Makefile / 慣例 | `npm test`、`go test ./...` |
| 建置指令 | scripts / Makefile / 慣例 | `npm run build`、`go build` |
| 既有 CLAUDE.md | 檔案是否存在 | 存在 → 詢問合併或覆蓋 |

### Step 2：互動確認

將偵測結果呈現給用戶確認或修正：

```
偵測到的專案配置：
- 語言：TypeScript
- 框架：Next.js 14
- 測試框架：Jest
- 測試指令：npm test
- 建置指令：npm run build

是否正確？（確認 / 修正）
```

### Step 3：模板填充

讀取 `CLAUDE_TEMPLATE.md`，替換所有 `{{PLACEHOLDER}}`：

| Placeholder | 替換為 |
|-------------|--------|
| `{{PROJECT_NAME}}` | 專案目錄名或用戶指定名稱 |
| `{{LANGUAGE}}` | 偵測到的語言 |
| `{{FRAMEWORK}}` | 偵測到的框架 |
| `{{TEST_FRAMEWORK}}` | 偵測到的測試框架 |
| `{{TEST_COMMAND}}` | 偵測到的測試指令 |
| `{{BUILD_COMMAND}}` | 偵測到的建置指令 |

### Step 4：生成與確認

- 在專案根目錄生成 `CLAUDE.md`
- 若已存在 CLAUDE.md，提供選項：
  - **合併**：將閉環規則追加到現有 CLAUDE.md
  - **覆蓋**：完全替換
  - **取消**：不做任何變更

### Step 5：驗證

生成後自動檢查：
- 所有 placeholder 都已替換（無殘留的 `{{` `}}`）
- 檔案語法正確（Markdown 格式良好）
- 通知用戶生成完成

## Skill 檔案結構

```
~/.claude/commands/dev:init-claude.md
```

或若使用 plugin 形式：

```
~/.claude/plugins/dev-closed-loop/
├── skills/
│   └── create-claude.md    # Skill 定義
└── templates/
    └── CLAUDE_TEMPLATE.md  # 模板檔案
```

## Skill Prompt 草稿

```markdown
---
name: dev:init-claude
description: 為專案生成開發設計閉環 CLAUDE.md
---

你是一個專案初始化工具。你的任務是為當前專案生成一份 CLAUDE.md，
其中包含「開發設計閉環」的完整方法論指令。

執行步驟：

1. 掃描當前目錄，偵測語言、框架、測試工具
2. 向用戶確認偵測結果
3. 讀取模板，替換配置值
4. 在專案根目錄生成 CLAUDE.md
5. 驗證生成結果

模板路徑：
{{閉環目錄}}/CLAUDE_TEMPLATE.md

重要規則：
- 若已存在 CLAUDE.md，詢問用戶如何處理
- 所有 placeholder 必須替換完畢
- 生成後通知用戶並說明如何使用
```

## 未來擴展

| 擴展方向 | 說明 |
|---------|------|
| `--minimal` 旗標 | 生成精簡版（只含 Phase 1, 2, 5，跳過檢核與測試） |
| `--full` 旗標 | 生成完整 9 角色版本 |
| `--security` 旗標 | 強化安全檢核角色（拆分獨立安全閉環） |
| `--perf` 旗標 | 加入效能評估角色 |
| 語言特化模板 | 為 Go / TypeScript / Python 等提供語言專屬最佳實踐 |
| 團隊模式 | 支援多人協作的閉環配置（角色分配給不同人） |

## 依賴關係

- 此 Skill 依賴 `CLAUDE_TEMPLATE.md` 模板檔案
- 模板的任何更新，Skill 生成的結果會自動反映
- 模板是唯一的 source of truth，Skill 只負責偵測配置和填充
