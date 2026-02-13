# 跨 Session 持久化

大型多模組專案（≥ 3 個模組）通常需要多個 Session 才能完成一輪完整的閉環。
閉環狀態預設只存在於對話記憶中，切換 Session 就會丟失。
本文件定義 `.claude-loop/` 持久化目錄的結構和操作規則，讓閉環狀態可以跨 Session 保存和讀取。

> **版本範圍**：v1 只做持久化機制。介面契約（IF-x / CR-x）是 v2，專案協調者是 v3。

---

## 觸發條件

符合以下任一條件時啟用持久化：

1. 模組數 ≥ 3 且有跨模組依賴
2. 預計需多個 Session 開發
3. 用戶明確說「啟用持久化」

不符合條件時，閉環照常在對話記憶中運作，不需要建立 `.claude-loop/`。

---

## 目錄結構

```
.claude-loop/
├── project-state.md              # 全局狀態：模組清單、依賴圖、進度
├── modules/
│   ├── user/
│   │   ├── status.md             # 模組閉環狀態與歷史
│   │   ├── design-spec.md        # Phase 1 設計規格
│   │   └── self-verify.md        # Phase 5 自証結果
│   ├── auth/
│   │   ├── status.md
│   │   ├── design-spec.md
│   │   └── self-verify.md
│   └── order/
│       ├── status.md
│       ├── design-spec.md
│       └── self-verify.md
├── interfaces/
│   ├── IF-1.md                   # 介面契約：[名稱]
│   └── IF-2.md                   # 介面契約：[名稱]
└── changes/
    ├── CR-1.md                   # 變更請求：[摘要]
    └── CR-2.md                   # 變更請求：[摘要]
```

### 各檔案說明

| 檔案 | 用途 | 誰寫入 | 誰讀取 |
|------|------|--------|--------|
| `project-state.md` | 全局鳥瞰：所有模組的進度和依賴關係 | 每個模組閉環完成時更新 | 新 Session 開始時第一個讀 |
| `modules/{name}/status.md` | 單一模組的閉環狀態和歷史 | 每次 Phase 轉換時更新 | 進入該模組閉環時讀取 |
| `modules/{name}/design-spec.md` | Phase 1 的設計規格 | Phase 1 完成時寫入 | Phase 2-5 引用、依賴模組讀取 |
| `modules/{name}/self-verify.md` | Phase 5 的自証結果 | Phase 5 完成時寫入 | 依賴模組確認前置模組已通過 |
| `interfaces/IF-{n}.md` | 跨模組公開 API 的介面契約 | Phase 1 定義跨模組 API 時寫入 | 消費模組的 Phase 1 引用、Phase 5 驗證 |
| `changes/CR-{n}.md` | 介面變更的連鎖影響記錄 | 模組修改了 IF-x 介面時建立 | 受影響模組閉環恢復時讀取 |

---

## 檔案格式模板

### project-state.md

```markdown
# 專案閉環狀態

- 專案名稱：[名稱]
- 最後更新：[YYYY-MM-DD HH:MM]
- 模組總數：X
- 已通過模組：Y / X

## 模組依賴圖

[文字描述模組間的依賴關係]
例：order → auth → user（order 依賴 auth，auth 依賴 user）

## 模組進度

| 模組 | 當前階段 | 狀態 | 最後更新 |
|------|---------|------|---------|
| user | Phase 5 | 通過 | 2026-02-14 |
| auth | Phase 3 | 斷點 A | 2026-02-14 |
| order | 未開始 | — | — |
```

### modules/{name}/status.md

```markdown
# [模組名稱] 閉環狀態

- 當前層級：方法 / 模組
- 當前 Phase：Phase X
- 狀態：進行中 / 斷點 A / 斷點 B / 通過 / 不通過
- 最後更新：[YYYY-MM-DD HH:MM]

## 閉環歷史

| 時間 | Phase | 事件 | 備註 |
|------|-------|------|------|
| 2026-02-14 10:00 | Phase 1 | 完成 | 產出 BC-1~BC-3, EH-1~EH-2 |
| 2026-02-14 10:30 | Phase 3 | 斷點 A | R-1 (high) 未修正 |
| 2026-02-14 11:00 | Phase 2 | 回退修正 | 修正 R-1 |
```

### modules/{name}/design-spec.md

直接沿用 CLAUDE.md「產出物格式」章節中的**設計規格（Phase 1 產出）**格式。
即以 `## 📐 設計規格` 開頭，包含目標、函式簽名、邊界條件（BC-x）、錯誤處理（EH-x）、設計決策。

### modules/{name}/self-verify.md

直接沿用 CLAUDE.md「產出物格式」章節中的**自証結果（Phase 5 產出）**格式。
即以 `## ✅ 自証結果` 開頭，包含四個維度的比對結果和判定。

---

## 持久化流程

### 寫入時機

| 事件 | 動作 |
|------|------|
| Phase 1 完成 | 將設計規格寫入 `modules/{name}/design-spec.md` |
| Phase 5 完成 | 將自証結果寫入 `modules/{name}/self-verify.md` |
| 任何 Phase 轉換 | 更新 `modules/{name}/status.md`（追加歷史記錄） |
| 模組閉環完成（自証通過） | 更新 `project-state.md`（修改該模組的進度行） |

### 讀取時機

| 事件 | 動作 |
|------|------|
| 新 Session 開始 | 先讀 `project-state.md` 了解全局狀態 |
| 進入模組閉環 | 讀取該模組的 `status.md` 恢復斷點；讀取依賴模組的 `design-spec.md` 和 `self-verify.md` |
| Phase 5 自証 | 從 `design-spec.md` 讀取設計規格做比對（不依賴對話記憶） |

### 操作範例：三模組專案

假設專案有 user、auth、order 三個模組，依賴關係為 order → auth → user。

**Session 1**：完成 user 模組閉環

1. 建立 `.claude-loop/` 目錄和 `project-state.md`
2. 建立 `modules/user/` 子目錄
3. Phase 1 完成 → 寫入 `modules/user/design-spec.md`
4. Phase 2-4 過程中 → 更新 `modules/user/status.md`
5. Phase 5 通過 → 寫入 `modules/user/self-verify.md`
6. 更新 `project-state.md`：user 狀態改為「通過」

**Session 2**：開始 auth 模組

1. 讀取 `project-state.md` → 得知 user 已通過、auth 未開始
2. 讀取 `modules/user/design-spec.md` → 了解 user 模組的介面
3. 建立 `modules/auth/` 子目錄，開始 auth 閉環
4. Phase 3 觸發斷點 A → 更新 `modules/auth/status.md` 記錄斷點
5. Session 結束前未完成 → `project-state.md` 記錄 auth 為「斷點 A」

**Session 3**：繼續 auth，開始 order

1. 讀取 `project-state.md` → 得知 auth 在 Phase 3 斷點 A
2. 讀取 `modules/auth/status.md` → 恢復到斷點位置
3. 修正後完成 auth 閉環
4. 讀取 `modules/user/design-spec.md` 和 `modules/auth/design-spec.md` → 開始 order

---

## 與現有閉環的關係

- 持久化**不改變**閉環的五階段流程和規則
- 持久化**不改變**產出物格式（design-spec.md 和 self-verify.md 直接使用現有格式）
- 持久化只是增加了「寫入檔案」和「從檔案讀取」的時機點
- 單模組或小型專案不需要啟用持久化，閉環照常在對話記憶中運作

---

## 介面契約與變更請求

v2 已定義 `interfaces/` 和 `changes/` 的檔案格式和管理規則。

- `interfaces/IF-{n}.md`：跨模組公開 API 的介面契約，詳見[介面契約與變更管理](介面契約與變更管理.md)
- `changes/CR-{n}.md`：介面變更的連鎖影響記錄，詳見[介面契約與變更管理](介面契約與變更管理.md)
