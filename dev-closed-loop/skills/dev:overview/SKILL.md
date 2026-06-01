---
name: dev:overview
description: Use when the user wants a visual / human-friendly overview of the dev-closed-loop methodology, especially as an onboarding aid for newcomers. Triggers include "/dev:overview", "/dev:overview gen", or phrases like "介紹方法論"、"閉環是什麼"、"方法論有什麼功能"、"給我看 overview"、"overview"、"介紹"、"幫我看一下這個方法論". Produces a self-contained HTML file with light/dark toggle, three-layer-architecture + workflow visual flow, advanced-mechanism collapsible sections, and current-deployment status (if deployed). NOT for: editing methodology content (that's manual editing of CLAUDE_TEMPLATE.md), deploying methodology (that's /dev:init-claude), cross-session handoff (that's /dev:handoff).
---

# dev:overview

> 隨 dev-closed-loop 方法論部署的視覺化介紹 skill。把「開發設計閉環」白話化 + HTML 視覺化，讓新手 30 秒理解、進階用戶按需展開細節。

## 用途

把方法論的功能呈現給人類看，不是給 LLM 看的結構化文件。輸出 **self-contained HTML**（離線可開、無外部依賴、含 light/dark mode 切換）。

主要受眾（混合，**新手必看為核心**）：
1. 新用戶評估閉環值不值得用
2. 已部署用戶 onboard 同事
3. 用戶自己多月後回顧部署的功能
4. Claude / agent 接手新閉環時快速理解

## 輸出檔案路徑

依當前 cwd 是否已部署閉環決定：

| 狀態 | 路徑 | 模式 |
|------|------|------|
| 已部署（cwd 有閉環 CLAUDE.md） | `.claude-loop/overview.html` | Deployed — 含當前部署狀態區 |
| 未部署 | `<cwd>/dev-overview.html` | Standalone — 純介紹 + 安裝引導 |

- Self-contained：inline CSS/JS/SVG，無 CDN 依賴
- Light/Dark mode：頁面右上角切換按鈕，localStorage persist
- 重新跑 dev:overview 會**覆蓋**舊檔（重新產生不 warn）

## 觸發

| 參數 | 行為 |
|------|------|
| `/dev:overview`（無參數） | 預設行為，等同 `gen` |
| `/dev:overview gen` / `regen` / `重新產生` | 重新產生並覆蓋既有 .html |

別名（皆等價）：`overview` / `介紹` / `gen` / `regen` / `重新產生` / `產生`

## 流程

每次執行依序：

### Step 1：偵測部署狀態（必做）

```bash
# 偵測：當前 cwd 是否已部署閉環
# 用嚴格 pattern（要求接 semver），對齊 check-version.sh extract_version 的 grep
grep -qE "closed-loop v[0-9]+\.[0-9]+\.[0-9]+" ./CLAUDE.md 2>/dev/null && echo "deployed" || echo "standalone"
```

> ⚠️ 不能用寬鬆 pattern `grep -q "closed-loop v"` — 會誤把含「`closed-loop v`」字串的 maintainer 工作指引（如本 repo root 的 CLAUDE.md 描述）判定為 deployed。

- `deployed` → 走 Step 2 收集動態值
- `standalone` → 跳過 Step 2，直接 Step 3（dynamic placeholder 留空 + 部署狀態區隱藏）

### Step 2：收集動態值（僅 deployed 模式）

讀 `references/source-mapping.md` 對映表。**並行**執行所有 source 查詢指令（彼此無依賴），一次取得所有 placeholder 值：

| 類別 | 查詢方式 |
|------|---------|
| 版本資訊 | `bash {{REPO_PATH}}/dev-closed-loop/check-version.sh {{REPO_PATH}} --deployed ./CLAUDE.md --check-remote` |
| 啟用功能盤點 | `ls .claudedocs/*.md / agents / hooks / languages` |
| 累積活動 | `grep -c` learning-log + 問題追蹤升格 ID |
| 部署日期 | `git log --diff-filter=A --format=%aI -- CLAUDE.md \| head -1` |

詳細對映規則見 `references/source-mapping.md`。

### Step 3：填值 template.html

1. Read `references/template.html`（含所有 `{{PLACEHOLDER}}`）
2. 把每個 placeholder 替換為 Step 2 取得的值
3. Standalone 模式：
   - 所有 `{{DEPLOYMENT_*}}` placeholder 清空
   - 部署狀態區整段（`<!-- DEPLOYMENT_BLOCK_START -->` 到 `<!-- DEPLOYMENT_BLOCK_END -->`）移除
   - Hero CTA 切換成「未部署？一行指令安裝」變體

### Step 4：寫入輸出檔

- Deployed → `.claude-loop/overview.html`（若 `.claude-loop/` 不存在先建立）
- Standalone → `<cwd>/dev-overview.html`
- 直接 `Write` tool 覆蓋既有檔，不額外確認

### Step 5：回報用戶

```
✅ dev:overview HTML 已產出
📄 路徑：<absolute path to .html>
🖥️  瀏覽方式：open <path>
📊 模式：<Deployed | Standalone>
   <若 deployed>包含部署狀態：v{version} · {docs}/17 docs · {hooks}/6 hooks · ...
   <若 standalone>純介紹模式（未偵測到當前 cwd 有閉環部署）

💡 提示：右上角按鈕可切換 light/dark mode（localStorage 持久化）
```

## 應該做 vs 不該做

| ✅ 做 | ❌ 不做 |
|------|--------|
| 並行執行 Step 2 各查詢 | 串行慢執行 |
| 失敗時清空對應 placeholder 而非整體失敗 | 任一查詢失敗就 abort |
| Standalone 模式完整隱藏部署狀態區 | 留空 placeholder 在 standalone 模式 |
| 路徑回報用絕對路徑 | 相對路徑（user 不知道相對於哪） |
| 提示 `open <path>` 給用戶開瀏覽器 | 假設用戶知道怎麼開 .html |

## Edge cases

| 情境 | 處理 |
|------|------|
| cwd 是 home / root | 警告「不適合在 home/root 跑 dev:overview」並中止 |
| 已部署但 `.claude-loop/` 目錄不存在 | 自動 `mkdir -p .claude-loop/` |
| `check-version.sh` 不存在或執行失敗 | 部署狀態區「升級狀態」改顯示「⚠️ 無法偵測（check-version.sh 缺失）」，其他繼續 |
| GitHub 連線失敗 | 部署狀態區「升級狀態」改顯示「⚠️ 無法連線 GitHub 確認遠端版本」 |
| Template / references 任一檔案缺失 | 告知用戶 skill 部署不完整，建議重跑 `setup.sh` |

## 額外資源

- **`references/content-spec.md`** — Hero + 11 sections + CTA + 部署狀態區的完整白話內容規格
- **`references/source-mapping.md`** — `{{PLACEHOLDER}}` ↔ source file / 指令 完整對映表
- **`references/visual-guide.md`** — 三層 / 4 workflow 卡片配色 / light-dark CSS variables / typography / 互動規範
- **`references/template.html`** — self-contained HTML template（inline CSS/JS/SVG · 含 `{{PLACEHOLDER}}`）

## 交互語言

全程繁體中文（與 `dev:handoff`、`dev:init-claude` 一致）。HTML 內容也用繁體中文。
