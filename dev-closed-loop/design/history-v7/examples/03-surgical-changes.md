# 03. 修 bug 順手大整理（Q3 Surgical 違反）

> 用戶要求修一個 typo / 一個 bug，AI 順手 reformat 引號、加 type hints、重命名變數、刪註解——把「沒被要求的改動」混進 PR。

## 場景

用戶說：「README 第 42 行有個 typo `recieve` 應為 `receive`，請改一下。」

需求邊界明確：1 個字、1 個檔案、不改邏輯。

## 錯誤示範

AI 順手做了一堆「順便整理」：

```diff
 # User Authentication
 
-When user logs in, we receive an authentication token from the server.
-The 'token' is stored in localStorage and is included in subsequent requests.
+When user logs in, we recieve an authentication token from the server.
+The "token" is stored in localStorage and is included in subsequent requests.

-We use jsonwebtoken (jwt) for token generation. The expiry is set to 1 hour.
+We use **jsonwebtoken (jwt)** for token generation. The expiry is set to 1 hour.

+## Error Handling
+
+If the token is invalid, the server returns 401.

-See `auth.js` for implementation details.
+See [`src/auth.js`](src/auth.js) for implementation details.
```

PR 訊息：「修復 typo + 一些清理」

實際上：**typo 沒修反而錯**（`receive` → `recieve` 反向錯字）+ 引號改 quote style（單→雙）+ 標粗 jsonwebtoken + 加新 section + 改連結格式。

用戶 review PR 時：(a) 找不到 typo 修在哪、(b) 不同意所有「順便」改動、(c) PR 變得無法簡單 merge。

## 原則診斷

**違反**：Q3 Surgical — 改動超出需求邊界

**對映**：
- `CLAUDE_TEMPLATE.md` Section 0 Q3 Surgical 自問：「我這步只動了該動的嗎？style 是否 match 既有？」
- `CLAUDE_TEMPLATE.md` Section 11 同類掃描 — 修改前先掃描同類，但**不是順手修同類**
- `CLAUDE_TEMPLATE.md` Section 11.5 Dead Code 立場 — 「pre-existing dead code → 提及，不動」（同精神：保留既有 code 風格，不順手 refactor）
- `agents/code-reviewer.md` 步驟 5.5 R-style 獨立子類別（v6.1.0 K-06）— 只報告「改動引入的不一致」，不報告「既有不一致」

**歷史教訓**：問題追蹤 #001 / #002（單線索推論）對應的「快速行動跳過驗證」精神——Q3 Surgical 是同精神在改動範圍上的應用。

## 修正版本

只改 typo 那一行：

```diff
 # User Authentication
 
-When user logs in, we recieve an authentication token from the server.
+When user logs in, we receive an authentication token from the server.
```

然後在 PR 訊息或對話中**主動告知**用戶其他觀察：

```
✅ 修了 README line 42 的 `recieve` → `receive`

我注意到但未動：
- L34 / L38 / L51 也有 quote style 不一致（單引號 vs 雙引號），但是 pre-existing
  風格漂移，需要用戶 explicit 要求 cleanup 才動
- L78 的「Error Handling」section 缺失，但這是內容缺漏不是 typo，
  屬於另一個 task 範疇

如果要清理上述任一項，請 explicit 告知。
```

## 關鍵限制

**適用**：
- 用戶需求邊界明確（修一個 typo / 一個 bug / 一個 function）
- 改動屬「定點修改」（< 5 行 / 單檔指定行數）
- 同類掃描發現的問題僅報告，不順手修

**不適用**：
- 用戶 explicit 要求「順便清理 X 區塊」→ 範圍擴大為包含 X
- 一個改動的副作用必然影響其他位置（例：rename function → 所有 callers 必須同步） → 屬「相依改動」非「順手改」
- code-simplifier 自動觸發（精簡閉環步驟 2 後置）→ 走 simplify 流程

**白名單例外**：
- 你的改動造成的 orphan（imports / 變數不再被引用）→ 刪除（Section 11.5 第 1 條）
- 改動同類的全 N 個位置（同類掃描的 explicit 結果）→ 該改全改（不是順手是同類）

---

最後修訂：2026-04-26（v6.3.0 K-07 引入 · 來源 Karpathy 4 原則 Q3 Surgical · 對映 CLAUDE_TEMPLATE Section 0 + 11 + 11.5）
