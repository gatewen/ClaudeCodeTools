# 01. 默默選一種解讀就動手（Q1 Think 違反）

> 用戶說含糊的需求，AI 默默選一種解讀直接動手——而不先列假設、不問澄清、不 push back。

## 場景

用戶說：「修一下這個 API，讓它快一點。」

這個需求至少有 5 種解讀：
- 加 cache 層（in-memory / Redis）
- 改 GET → POST 並做請求合併
- 拆分大 query 為 parallel sub-queries
- 加 DB 索引
- 用 streaming response 替代 batch

每種改法的代價、風險、效益都不同。

## 錯誤示範

AI 看到「快一點」立即動手，挑最熟悉的方案直接寫：

```python
# 直接挑「加 in-memory cache」這條路徑
from functools import lru_cache

@lru_cache(maxsize=128)
def get_user_profile(user_id: int):
    return db.query("SELECT * FROM users WHERE id = ?", user_id)
```

完成後告訴用戶「加了 LRU cache，現在快多了」。

但用戶其實要的是「降低 P99 latency」——cache 對 P99 沒用（cache miss 路徑沒變），用戶的真實問題沒解。

## 原則診斷

**違反**：Q1 Think — AI 沒列假設、沒問澄清、沒 push back

**對映**：
- `CLAUDE_TEMPLATE.md` Section 0 Q1 Think 自問：「我這步的假設是什麼？有歧義嗎？需要 push back 嗎？」
- `CLAUDE_TEMPLATE.md` Section 12.5 push back 第 1 條（更簡單替代方案存在）/ 第 4 條（任務升級而非順從）
- `agents/architect.md` Step 1.5（命令式 → 可驗證目標轉換 · K-08）

**歷史教訓**：問題追蹤 #001 / #002（絕對負面陳述缺證據 / routing vs existence 框架錯置）—— 認知性誤判源自「沒先停下確認假設」。

## 修正版本

先列假設 + AskUserQuestion 釐清 → 再動手：

```
Claude：⚠️ 這個需求有 5 種可能解讀，需要先釐清

候選改法：
A. 加 in-memory cache（快 happy path / 對 cache miss 無影響）
B. 加 DB 索引（取決於 query pattern）
C. 拆 parallel sub-queries（適合多個獨立子請求）
D. Streaming response（適合大 payload）
E. 改架構（前端先呈現骨架 + lazy load）

請問：
1. 想優化的是 P50 還是 P99 latency？
2. 改動可接受的範圍：應用層 / DB 層 / 客戶端？
3. 「快一點」的具體目標數字（從 X ms 到 Y ms）？
```

用戶回答後，AI 才針對特定方向寫程式。

## 關鍵限制

**適用**：
- 用戶需求含糊（缺具體目標、缺範圍邊界、缺技術方向）
- 一次改動超出當前任務等級的合理範圍（中型 ≥ 3 檔案 → 應升級為大型）

**不適用**：
- 純技術問題且需求清晰（例：「把這行的 typo 改掉」）→ 直接執行，不需 push back
- 用戶 explicit 說「我知道有風險，照原方案做」→ 解除 push back（同 Section 12.5 1-4 條）

**白名單例外**：
- 微小任務（< 50 行 / 單檔修改）→ 走「直接執行」分支（Section 1 任務等級判定）
- 用戶說「快速修改」→ 不走 push back

---

最後修訂：2026-04-26（v6.3.0 K-07 引入 · 來源 Karpathy 4 原則 Q1 Think · 對映 CLAUDE_TEMPLATE Section 0 + 12.5）
