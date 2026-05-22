# 模板

> **路徑解耦**：以下模板的內容與儲存路徑無關。實際寫入位置由 `references/path-resolution.md` 決定（cwd-based + 動態偵測）。模板內提到 `<handoff_dir>` 處皆為佔位符。

## 1. handoff.md 模板（save 時覆蓋寫入）

````markdown
# Session Handoff

**最後更新**: YYYY-MM-DD HH:MM
**Session 焦點**: <一句話描述本次主要在做什麼>

## 進行中工作

> 📌 **跨 session 提醒**：以下項目是 **file state**，**不會**自動恢復為 Claude Code 的 TaskList runtime state。新 session 開啟時必須由 `/dev:handoff load` 自動 TaskCreate 重建，看到 handoff 內容不等於 TaskList 已就緒。

- [ ] **任務 A**（完成 XX%）
  - 當前狀態：…
  - 下一步：…
  - 卡點（如有）：…

- [ ] **任務 B**（完成 XX%）
  - …

## 已完成

- ✅ 項目 1 — `path/to/file` 或 commit hash
- ✅ 項目 2

## 重要決策 / 發現

- **決策 X**：選了 A 而非 B，**因為** …
- **發現 Y**：…

## 修改過的檔案

- `path/to/file1` — 做了什麼
- `path/to/file2` — 做了什麼

## 起手式建議

1. 先驗證 …
2. 注意 …
3. 若 X 失敗，fallback 到 Y

## 手動備註

<若 save 時帶了 "…" 備註，原文放這裡；否則此區塊省略>

## ⚠️ Git 狀態

<僅當有未 commit 變更時出現此區塊>

- modified: `path/a`, `path/b`
- untracked: `path/c`
- 建議：commit 前先 …
````

---

## 2. 日誌檔頭（當日首次 save 時寫入）

```markdown
# YYYY-MM-DD 工作日誌
```

---

## 3. 日誌條目模板（每次 save append 一個區塊）

````markdown
## HH:MM — Session 結束

**焦點**: <Session 焦點，與 handoff 一致>

### 進行中

- 任務 A — XX%，下一步：…
- 任務 B — XX%，下一步：…

### 已完成

- 項目 1
- 項目 2

### 決策

- 決策 X：…

### 修改檔案

- `path/to/file1`
- `path/to/file2`

### 備註

<手動備註原文 / 或省略>

---
````

> ⚠️ 每個區塊結尾的 `---` 是分隔線，必須保留。後續 append 時新區塊接在 `---` 之後。

---

## 4. load 摘要呈現模板（load 時的對話輸出格式）

````markdown
📋 **上次交接**: YYYY-MM-DD HH:MM（<時間落差描述>）
**焦點**: <Session 焦點>

🔄 **進行中**

- **任務 A** — XX%，下一步是 …
  - 卡點：…（如有）
- **任務 B** — XX%，下一步是 …

✅ **上次已完成**（壓縮）

<1–2 句話總結，不要列點全部>

⚠️ **Git 提醒**（如有未 commit）

- modified: …

💡 **建議起手式**

依交接內容，建議從「<具體動作>」開始。要不要這樣繼續？
````

> 此模板是給 user 看的，使用 emoji + 粗體強化掃讀。**不要**把 handoff.md 原文整份貼出來。

---

## 5. Memory 更新時的索引行格式

寫入 `MEMORY.md` 時的單行格式（已存在的索引慣例）：

```markdown
- [<標題>](<檔名>.md) — <一句話 hook>
```

範例：
```markdown
- [Ctrl handoff 工作流](feedback_handoff_workflow.md) — 換 session 三層分工：memory/handoff/log
```
