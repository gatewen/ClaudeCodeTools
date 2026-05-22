---
name: dev:handoff
description: >-
  Use when the user wants to save or load session state for cross-session
  handoff. Triggers include "/dev:handoff", "/dev:handoff save",
  "/dev:handoff load", or phrases like 「換 session」、「session 滿了」、
  「準備收工」、「交接」、「繼續上次」、「上次做到哪」、「handoff」.
  Default action is save when no argument is given. Paths are resolved per
  current working directory (NOT hard-coded to any single project).
  Bundled with dev-closed-loop methodology; functionally equivalent to wt:handoff.
  NOT for: general note-taking, project documentation, or non-session work tracking.
---

# dev:handoff

> **本 skill 隨 dev-closed-loop 方法論部署**，功能與 `wt:handoff` 等價。
> 若使用者同時擁有兩者並存無衝突；閉環方法論使用者建議用本 skill 以與方法論散佈節奏同步。
> 未來可能加入 methodology-aware 增強（phase 進度、升格機制 status 等），由 Phase 2 觸發後決定。

## 用途

跨 session 工作交接專用 skill。Context 上限時打 `/dev:handoff` 寫狀態，開新 session 時打 `/dev:handoff load` 接續。

**所有路徑跟著當前 cwd 走**，不寫死任何專案。詳見 `references/path-resolution.md`。

## 三層資訊分工

| 層級 | 內容 | 位置 |
|------|------|------|
| **Memory**（長期） | 跨 session 知識、偏好、決策原因 | 系統 auto-memory（per-project，cwd 編碼，已自動掛載） |
| **Handoff**（短期） | 「我做到哪、下一步是什麼」當前狀態 | 依 cwd 動態判定，見 `references/path-resolution.md` |
| **Daily Log**（檔案） | 按日期歸檔歷史紀錄 | 與 handoff 同層 |

避免重複：當前 session 進行中工作 → Handoff；跨 session 偏好/決策 → Memory；歷史歸檔 → Log。

## TaskList 雙向同步

handoff 的「進行中工作」與 Claude Code 的 **TaskList runtime state** 雙向同步，避免 file state 與 runtime state 漂移：

- **save 時**：以 TaskList 為 source of truth 寫入 handoff（不在 TaskList 中的隱性任務會提示 user 是否正式 TaskCreate）
- **load 時**：自動 TaskCreate 重建 TaskList（forcing function — 即使 handoff 進行中為空也要明確回報）

詳見 `references/save-mode.md` Step 1 與 `references/load-mode.md` Step 6。

## 參數對照

| 指令 | 模式 | 說明 |
|------|------|------|
| `/dev:handoff` | **save**（預設） | 不帶參數時的預設行為 |
| `/dev:handoff save` | save | 寫入交接 |
| `/dev:handoff load` | load | 載入接續 |
| `/dev:handoff save "備註"` | save + 備註 | save 時帶手動備註 |

別名（皆等價）：
- save 系：`save` / `out` / `存` / `寫`
- load 系：`load` / `in` / `讀` / `載`

## 流程分派

**每次執行必先做路徑判定**（讀 `references/path-resolution.md`）；**save 模式必加做衝突偵測**（讀 `references/conflict-resolution.md`）。

| 參數 | 讀哪些 reference |
|------|-----------------|
| 無 / save / out / 存 / 寫 | `path-resolution.md` → `conflict-resolution.md` → `save-mode.md` |
| load / in / 讀 / 載 | `path-resolution.md` → `load-mode.md` |
| 其他 | 提示正確語法後中止 |

所有模板統一在 `references/templates.md`。

## 額外資源

- **`references/path-resolution.md`** — 路徑判定邏輯（cwd-based、.claude-loop 偵測、fallback 規則），**所有模式必讀**
- **`references/conflict-resolution.md`** — 既存 handoff 衝突處理（來源偵測、時戳分級、自動合併、外部備份），**save 模式必讀**
- **`references/save-mode.md`** — save 完整流程（路徑、衝突、對話分析、Git 檢查、確認、三項寫入、驗證）
- **`references/load-mode.md`** — load 完整流程（並行讀取、時間落差、摘要呈現、起手式建議）
- **`references/templates.md`** — handoff.md / 日誌條目 / load 摘要呈現模板

## 交互語言

全程繁體中文。
