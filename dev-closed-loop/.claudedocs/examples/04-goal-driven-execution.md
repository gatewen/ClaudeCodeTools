# 04. 我先 review 再改善（Q4 Goal 違反）

> 用戶提出明確問題（如「測試失敗」「函式回傳錯誤值」），AI 不先定可驗證目標，反而說「我先 review 整個檔案再來改善」——把 explicit goal 換成 vague 探索。

## 場景

用戶說：「測試 `test_user_login_with_expired_token` 失敗，能修一下嗎？」

需求邊界：1 個明確的失敗測試 + 期望它通過。可驗證目標：跑 `pytest test_user_login_with_expired_token` 通過。

## 錯誤示範

AI 沒有立刻針對失敗測試行動，反而說：

```
讓我先 review 整個 auth.py 檔案來了解這個系統。

[花 10 分鐘讀完 auth.py 的 500 行]

我看到幾個可以改善的地方：
1. 函式 X 沒有 type hints
2. 變數命名不一致（snake_case vs camelCase）
3. Error handling 可以用 context manager
4. 有些 magic number 可以提取成常數

我先把這些 cleanup 做完，再回來看那個失敗的測試。
```

問題：
- (a) 用戶不在乎 type hints 一致性，他要測試通過
- (b) 「先 review 再改善」是用 vague exploration 取代 specific goal
- (c) cleanup 完仍然沒解決原問題（測試還是失敗）
- (d) 引入了一堆 unrelated 改動，用戶 review PR 時找不到「測試怎麼修的」

## 原則診斷

**違反**：Q4 Goal — 沒先建立可驗證的成功標準

**對映**：
- `CLAUDE_TEMPLATE.md` Section 0 Q4 Goal 自問：「這步成功的可驗證標準是什麼？」
- `CLAUDE_TEMPLATE.md` 精簡閉環步驟 1：先做指令轉換（命令式 → 可驗證目標，K-08）
- `agents/architect.md` Step 1.5 命令式→可驗證目標對照表（v6.1.0 K-08）—— 「修這個 bug」 → 「跑 X 測試通過 + 確認 Y 場景無回歸」
- `agents/tester.md` Phase 4 — BC-x / EH-x 的 `[testable]` 標籤決定能否寫自動化測試

**歷史教訓**：問題追蹤 #001（絕對負面陳述缺證據）的對應精神——「我先看看」是用「探索」取代「驗證」。Q4 Goal 強制要求 reverse：先定 verification，再 explore。

## 修正版本

立即針對失敗測試行動，三步驟：

```python
# 1. 重現失敗（minimum repro）
# 跑 pytest -xvs test_user_login_with_expired_token
# → 看到具體錯誤：AssertionError: expected 401, got 500

# 2. 找根因（讀 auth.py 但只看 token 過期相關路徑）
def login(token):
    user = decode_jwt(token)  # ← 對 expired token 拋 ExpiredSignatureError 但沒被 catch
    return get_user(user.id)

# 3. 修正（minimum 改動，只動 token 過期那條路徑）
def login(token):
    try:
        user = decode_jwt(token)
    except ExpiredSignatureError:
        raise HTTPException(401, "Token expired")
    return get_user(user.id)
```

完成後：

```
✅ test_user_login_with_expired_token 通過
✅ 跑全測試套件無回歸（97 passed）
✅ 只改動 auth.py:42-45（4 行）

我注意到但未動：
- auth.py 有些 type hints 缺失，但 pre-existing 跟本次 task 無關
- 如要清理，請 explicit 告知開另一個 task
```

## 關鍵限制

**適用**：
- 用戶需求附帶明確的 verification（測試名 / 期望值 / 重現步驟）
- 任務有明確的「成功 = X」定義
- 中型 / 大型任務的 BC-x 必須帶 `[testable]` 標籤

**不適用**：
- 用戶需求模糊到無法定義 verification（例：「讓這個系統更好」）→ 走 Q1 Think 釐清流程，不能 jump 到 Goal
- 探索性研究任務（例：「研究 X 方案的可行性」）→ goal 是「產出 trade-off 報告」而非 verification
- `[visual-only]` / `[framework-dependent]` 項目 → goal 是 code review 而非自動化測試

**白名單例外**：
- 拋棄式 prototype / 緊急 hotfix → CLAUDE_TEMPLATE 開頭 Trade-off section 標明「不適用閉環」
- 用戶 explicit 說「我要先看看」→ 尊重決定，但建議補一句「然後 goal 是 X」

---

最後修訂：2026-04-26（v6.3.0 K-07 引入 · 來源 Karpathy 4 原則 Q4 Goal · 對映 CLAUDE_TEMPLATE Section 0 + 步驟 1 + architect Step 1.5）
