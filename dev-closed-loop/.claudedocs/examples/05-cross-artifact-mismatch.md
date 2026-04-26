# 05. 跨產出物矛盾（閉環特色，傳統 Code Review 抓不到）

> 設計規格說處理 5 種錯誤、實作只處理 3 種、測試只測 2 種——每階段獨立檢查都會通過，但跨階段對齊缺失。這是傳統 Code Review / CI 的盲點，閉環方法論用 Phase 5 雙向追溯捕捉。

## 場景

需求：「實作密碼重設 API。」

架構師（Phase 1）設計規格列出 5 種錯誤處理：
- EH-1：email 格式錯誤 → 400
- EH-2：用戶不存在 → 404
- EH-3：請求過於頻繁 → 429
- EH-4：DB 連線失敗 → 500 + retry 3 次
- EH-5：寄信服務不可用 → 502 + fallback queue

程序設計師（Phase 2）寫實作。檢核師（Phase 3）審程式碼。測試師（Phase 4）寫測試。

每個階段「看起來都做完了」。

## 錯誤示範

各階段獨立看都沒問題：

```python
# Phase 2 實作（看起來合理）
def reset_password(email: str):
    if not is_valid_email(email):
        return 400, "Invalid email"        # EH-1 ✅
    user = db.find_user(email)
    if not user:
        return 404, "User not found"       # EH-2 ✅
    if rate_limit_exceeded(email):
        return 429, "Too many requests"    # EH-3 ✅
    send_reset_email(user)                 # ❌ EH-4 / EH-5 沒處理
    return 200, "OK"

# Phase 3 code review（看起來通過）
- 函式簽名清楚 ✅
- 三個錯誤分支都有處理 ✅
- 沒語法錯誤 ✅
- 沒明顯 security 問題 ✅

# Phase 4 測試（看起來覆蓋）
test_reset_password_invalid_email()    # EH-1 ✅
test_reset_password_user_not_found()   # EH-2 ✅
# ... 沒寫 EH-3 / EH-4 / EH-5 測試
```

傳統 CI / Code Review 流程到此結束，PR 看起來綠燈通過。

但實際上：
- EH-4（DB 連線失敗）沒實作 retry → 用戶會看到 500
- EH-5（寄信服務不可用）沒實作 fallback queue → 用戶會看到 timeout
- EH-3 有實作但沒測試 → 不知 rate limit 是否真的觸發
- EH-1 / EH-2 有實作有測試 → 唯一完整覆蓋的兩條

設計、實作、測試之間「**沒有任何工具去比對它們的對齊性**」。這就是跨產出物矛盾。

## 原則診斷

**違反**：閉環特色 — Q4 Goal 在系統層的延伸

**閉環機制**：
- BC-x / EH-x ID 系統 — 每個邊界條件 / 錯誤處理在所有 Phase 用同一個 ID 引用
- `agents/verifier.md` Phase 5 雙向追溯：
  - 正向：設計規格 → 程式碼 → 測試（每個 EH-x 都有對應實作？對應測試？）
  - 反向：程式碼行為 → 設計規格（每段 catch / if 都對應到某個 EH-x？沒對應的是冗餘還是隱性決策？）
- `concepts/閉環核心理念.md`「自證機制」：「**自證不是重複測試，而是在做跨產出物的一致性驗證**」

**對映**：
- `CLAUDE_TEMPLATE.md` Section 0 Q4 Goal 自問：「這步成功的可驗證標準是什麼？」 — 在系統層擴展為「設計、實作、測試是否互相對齊」
- `CLAUDE_TEMPLATE.md` Phase 5 ⛔ 閘門：「設計-實作不一致 → P2 / 嚴重→P1 | 測試不足→P4」
- `standards/產出物格式.md` line 254-265 自證結果表 — 每個維度（PRD-設計覆蓋 / 設計-實作一致性 / 實作-測試覆蓋）都有獨立 ✅/❌

**歷史教訓**：問題追蹤所有 6 條種子條目（#001-#006）都對應「某層做了但沒跨層對齊」的問題類型。

## 修正版本

走完整閉環 Phase 5 自證：

```markdown
## ✅ 自證結果

| 維度 | 狀態 | 證據 | 缺口 |
|------|------|------|------|
| 設計-實作一致性 | ❌ | EH-1/EH-2/EH-3 有實作；EH-4/EH-5 缺 | EH-4 retry / EH-5 fallback queue 未實作 |
| 實作-測試覆蓋 | ❌ | EH-1/EH-2 有測試；EH-3/EH-4/EH-5 無 | EH-3 已實作但無測試 |
| 反向分析 | ❌ | 程式碼有 `send_reset_email(user)` 行但無 try/except → 對應何 EH? | 隱性「假設不會失敗」決策，需補設計規格或實作 |

判定：**不通過**

回退建議：
- 回 Phase 2：實作 EH-4 retry + EH-5 fallback queue
- 回 Phase 4：補 EH-3 / EH-4 / EH-5 測試
- 設計規格不需動（5 條 EH-x 是合理覆蓋）
```

精簡閉環的對應：迷你追溯（步驟 4.5）做正向覆蓋表，每個 BC-x / EH-x 附 `✅ 檔案:行號` + `✅ 測試名稱`。任何 ❌ 禁止 commit。

## 關鍵限制

**適用**：
- 中型 / 大型任務有 ≥ 2 個 BC-x / EH-x
- 設計、實作、測試是分開階段（不是一次寫完）
- BC-x / EH-x 標 `[testable]` 可自動化驗證

**不適用**：
- 微小任務（< 50 行）走「直接執行」分支，無 Phase 5 自證
- 探索性 prototype（無 BC-x / EH-x 編號）
- `[visual-only]` 項（自證走 code review 而非自動化）

**白名單例外**：
- 用戶 explicit 跳過閉環（CLAUDE_TEMPLATE Trade-off section：拋棄式 / 緊急 hotfix）→ 不走 Phase 5
- arch-risk 嚴重度 → 不觸發 Phase 5 回退，記錄但放行（`agents/verifier.md` severity_system）

---

最後修訂：2026-04-26（v6.3.0 K-07 引入 · 閉環特色 · 對映 CLAUDE_TEMPLATE Section 0 Q4 + Phase 5 雙向追溯 + verifier.md）
