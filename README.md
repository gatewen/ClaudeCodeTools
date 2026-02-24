# AI-ClaudeCode

Claude Code 工具鏈集中管理。包含自建的方法論、Skill、模板等。

## 目前包含

| 子系統 | 說明 |
|--------|------|
| [開發設計閉環](dev-closed-loop/) | 五階段程式碼品質保證方法（架構師 → 程序設計師 → 檢核師 → 測試師 → 自証師） |

## 快速安裝

```bash
git clone git@github.com:你的帳號/AI-ClaudeCode.git ~/AI-ClaudeCode
cd ~/AI-ClaudeCode
bash setup.sh
```

安裝完成後，在任何專案目錄執行 `/dev:init-claude` 即可部署閉環。

## 依賴

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| **SuperClaude** | `sc:*` 系列 Skills | `pipx install superclaude && superclaude install` |
| **Superpowers** | `superpowers:*` 系列 Skills | Claude Code 插件市場：`superpowers@claude-plugins-official` |
| **Task agents** | `code-simplifier` 等 Agent | Claude Code 內建，無需安裝 |

## 更新流程

```bash
cd ~/AI-ClaudeCode
git pull
bash setup.sh
```

## 目錄結構

```
AI-ClaudeCode/
├── README.md                       ← 本文件
├── setup.sh                        ← 一鍵安裝腳本
└── dev-closed-loop/
    ├── CLAUDE_TEMPLATE.md          ← 閉環模板（核心）
    ├── .claudedocs/                ← 補充文檔（10 檔）
    │   └── languages/             ← 語言 Skills（6 檔）
    ├── skill/
    │   └── init-claude.md           ← Skill 源碼
    ├── design/                     ← 設計歷史（01-07）
    └── README.md                   ← 閉環說明
```
