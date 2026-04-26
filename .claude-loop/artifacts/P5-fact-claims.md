# Phase 5 Step 9c — 事實前提追溯報告（v6.0.0）

> 角色：獨立自證審查者（v6.0.0 升級任務 · 唯讀模式）
> 日期：2026-04-26
> Branch：feature/v6.0.0-karpathy
> 模式：路徑模式直接 Read 產出物，親自 Grep / awk 驗證關鍵事實
> 對應規範：CLAUDE_TEMPLATE Section 12「事實主張閘門」+ verifier Step 9c

---

## 摘要

| 主張 | A 級證據 | B 級證據 | 反例檢查 | 評級 |
|------|---------|---------|---------|------|
| 1. v6.0.0 是 major bump（非 minor / patch） | `design/08:22-32` 結構性論證 + `design/08:31` 條件「叫 v6.0.0 必須包含 K-01 + K-04」 | P3 R-1 / R-7 三處版本號一致 / BC-3 + BC-7 兩條 K-x 實作 | 通過 | **強** |
| 2. Karpathy 4 原則源自 forrestchang/andrej-karpathy-skills | `CLAUDE_TEMPLATE.md:54` + `concepts/閉環核心理念.md:201` + `README.md:7` URL `x.com/karpathy/status/2015883857489522876` | `design/08:266-275` Karpathy 原文/延伸分類表 | 通過 | **強** |
| 3. v6.0.0 不偷 K-14 scope | `design/08:78-83` v6.2.0 milestone 表列 K-14 + `CLAUDE_TEMPLATE.md:261` + `CLAUDE_TEMPLATE.md:274`「K-14 v6.2.0 將擴充」標註 | P1b v2 DR-4 line 29 確認「沒有偷 K-14 整套 scope」+ P1 BC-7 ≤ 40 行限額 | 通過 | **強** |

**3 強 / 0 中 / 0 弱**。**無弱證據主張需要處置**。

---

## 主張 1：v6.0.0 是 major bump（非 minor / patch）

### 主張內容

v5.23.1 → v6.0.0 是合理的 **major version bump**，而非 v5.24.0 minor bump 或 v5.23.2 patch bump。

### A 級證據（literal / structural）

**A1**：`design/08-v6.0.0-karpathy-integration.md:22-32`「為什麼是 Major Bump」section（字面結構性論證）：

```
15 條優化中真正 major 的只有 3 條（其餘 12 條是 minor/patch）：
- K-01 4 原則 cross-cutting 自檢層 → 新增 Section 0 改變 CLAUDE_TEMPLATE 的根結構
- K-04 Push back 義務（Section 12.5）→ 新增「主動反對用戶」的行為文化，AI ↔ 用戶關係改變
- K-13 Karpathy 自循環模式（v6.3.0 才做）

叫 v6.0.0 的條件：必須包含 K-01 + K-04（v6.0.0 已含），不然名實不符。
```

**A2**：`design/08:36-44`「定位升級」表（字面）：

```
v5.x → v6.x 的真正創新：明確 LLM 對用戶的義務（不只是 LLM 對代碼的紀律）
v5.0.0~v5.21.x | 實作方法論
v5.22.x~v5.23.x | + 認知方法論
v6.x | + 行為哲學
```

實際 P2 落地：
- BC-3 實作：`CLAUDE_TEMPLATE.md:36-54` 新增 Section 0（K-01）— 改變根結構 ✅
- BC-7 實作：`CLAUDE_TEMPLATE.md:253-279` 新增 Section 12.5（K-04）— 新增 AI ↔ 用戶反向質疑機制 ✅

兩條「叫 v6.0.0 的必要條件」皆滿足。

### B 級證據

- P3 R-1 / R-7 三處版本號 grep 結果 v6.0.0 一致（CLAUDE_TEMPLATE.md:502 / dev-closed-loop/README.md:114 / README.md:151）
- BC-1（Trade-off 顯式宣告）+ BC-2（README Karpathy 引用）配合 BC-3/BC-7 共同建立「行為哲學層」定位
- P3 行數淨增 66 行 / 7 檔案改動 — 屬大型任務規模，符合 major bump 慣例

### 反例檢查

**若為真（v6.0.0 是 major）應觀察到**：根結構（Section 編號）改變、AI ↔ 用戶語意層改變、breaking changes 列表存在。

- 實際觀察：✅ 新增 Section 0（首個 Section 0 級別 heading）+ 新增 Section 12.5（首個 .5 級子 Section）+ migration-notes breaking-changes 列出 3 條（line 477-479）

**若為假（應為 minor）會觀察到**：純內部優化、無新 Section、無 migration 需求、無 breaking changes。

- 實際觀察：❌ 並非如此（已新增頂層結構 + IF-1 metadata 確認破壞性變更需要 migration）

### 共用值檢查

「v6.0.0」字串出現 ≥ 3 處：CLAUDE_TEMPLATE.md:502 / dev-closed-loop/README.md:114 / README.md:151 → **共用值（版本標識符）**，符合「跨檔案版本一致性」設計意圖（BC-6 三處同步），非私有化推論。

### 決策

**強**（≥ 1 A 級 + 反例通過 + 共用值檢查通過 [意圖性共用]）

→ 可作為事實輸出，可寫 memory（`evidence_level: strong`）

---

## 主張 2：Karpathy 4 原則歸因於 forrestchang/andrej-karpathy-skills

### 主張內容

本專案 v6.0.0 的「Q1 Think / Q2 Simplicity / Q3 Surgical / Q4 Goal」4 原則來源於 GitHub repo `forrestchang/andrej-karpathy-skills`，並源於 Karpathy 在 X (Twitter) 的觀察。

### A 級證據（literal）

**A1**：`CLAUDE_TEMPLATE.md:54`（Section 0 結尾，字面引用）：

```
**來源**：[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) Karpathy 4 原則。
閉環方法論將此 4 原則從「Phase 切片」升級為「橫切自檢」。
```

**A2**：`README.md:7-9` + `dev-closed-loop/README.md:5-7`（兩處 README，字面引用 Karpathy 原文）：

```
[Andrej Karpathy 觀察](https://x.com/karpathy/status/2015883857489522876)：

> "The models make wrong assumptions on your behalf and just run along with them
>  without checking. They overcomplicate code and APIs. They sometimes change/remove
>  comments and code they don't sufficiently understand as side effects."
```

**A3**：`concepts/閉環核心理念.md:201`（字面）：

```
來源是 [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
repo 的 Karpathy 4 原則
```

### B 級證據

- `design/08:266-275`「Karpathy 原文（A 級字面證據）vs 本專案延伸（B 級推論）」分類表，明確列出哪些 K-x 是原文（K-01/K-02/K-03/K-04/K-05/K-06/K-08/K-09/K-15）、哪些是延伸（K-07/K-10/K-11/K-13/K-14/K-16/K-17）
- v6.0.0 採用的 K-09/K-15/K-01/K-04 全部在 A 級「Karpathy 原文直接對應」分類，K-17 屬延伸（純技術需求，非 Karpathy 啟發）— 分類自洽

### 反例檢查

**若為真（4 原則源自該 repo）應觀察到**：repo 名稱明確標出、原文引用可追溯、原則本身有 1:1 對映。

- 實際觀察：✅ repo URL `https://github.com/forrestchang/andrej-karpathy-skills` 在三處檔案出現（CLAUDE_TEMPLATE.md:54 / 兩處 README / 閉環核心理念.md:201）；4 原則命名（Think / Simplicity / Surgical / Goal）跟 Karpathy 原文（"Think Before Coding" / "Simplicity First" / "Surgical Changes" / "Goal-Driven Execution"）完整對應

**若為假（自創或源自他處）會觀察到**：無原始 repo 引用、原則名稱跟 Karpathy 公開言論不符、無 X 貼文 URL 對應。

- 實際觀察：❌ 並非如此（X 貼文 URL `2015883857489522876` 在兩處 README 字面引用，且 design/08 第 7 行明確標明上游「來源：研究 forrestchang/andrej-karpathy-skills」）

### 共用值檢查

URL 與 repo 名稱在 3+ 處出現是**意圖性共用**（BC-2 + BC-3 + concepts 連動同步要求），符合 P3 R-7 跨檔交叉引用一致性審查 ✅

### 決策

**強**（多個 A 級字面證據 + 反例通過）

→ 可作為事實輸出，可寫 memory

### 風險邊界（DR-7v2 觀察項）

- BC-2 兩處 README URL `2015883857489522876` 是 X (Twitter) post ID（P1b v2 已提及）。**未來 X 平台重組可能失效**。建議 v6.1+ 在規劃時補 archive.org 存檔 link 註解（純預防，不阻擋當前 commit）。

---

## 主張 3：v6.0.0 不偷 K-14（雙向質疑）的 scope

### 主張內容

v6.0.0 的 BC-7 第 5 條「用戶事實前提待驗證」是**輕量觸發**（≤ 4 行新增），不是 K-14（雙向質疑機制）的完整實作。K-14 完整 scope 規劃在 v6.2.0 milestone。

### A 級證據

**A1**：`design/08:78-83` v6.2.0 milestone 規劃表（字面）：

```
| K-14 | 雙向質疑（用戶事實也驗證） |
| `CLAUDE_TEMPLATE.md` Section 12 + 13 擴充 / `concepts/閉環核心理念.md` 補對稱性 |
```

K-14 列在 v6.2.0，**不在 v6.0.0 milestone 表（design/08:53-59）**。

**A2**：`CLAUDE_TEMPLATE.md:261`（BC-7 第 5 條，字面標註）：

```
5. **用戶事實前提待驗證**：用戶斷言為「事實」但無證據的關鍵主張，且該主張將作後續行動前提
（與 Section 12 對 Claude 自身推論的對稱面；K-14 v6.2.0 將擴充為完整反向質疑機制）
```

**A3**：`CLAUDE_TEMPLATE.md:274`（BC-7「設計精神」段，字面）：

```
12.5 第 5 條對 **用戶對 Claude 的事實主張** 做反向閘門（質疑用戶）
——兩者構成對稱的雙向認知驗證機制，K-14（v6.2.0）將擴充為完整反向質疑協議
```

**A4**：`concepts/閉環核心理念.md:214`（字面）：

```
第 5 條觸發（用戶事實前提待驗證）的完整反向質疑機制由 K-14（v6.2.0）擴充。
```

A2/A3/A4 三處檔案明確標註「v6.2.0 才做完整版」，不偷 scope。

### B 級證據

- P1b v2 DR-4 確認「BC-7 line 237-238 已加第 5 條...註明『K-14 v6.2.0 將擴充為完整反向質疑機制』— 沒有偷 K-14 整套 scope。輕量 ~3 行符合 ≤ 4 行目標」
- BC-7 實際行數 28 ≤ 40（P3 R-2），第 5 條 ~3 行，比例自洽（5 條觸發各 ≤ 3 行）
- design/08:38-41（v6.0.0 milestone 表）共 5 條 K-x：K-09/K-15/K-01/K-17/K-04，**不含 K-14**

### 反例檢查

**若為真（v6.0.0 不偷 K-14）應觀察到**：v6.0.0 BC-7 沒有「主動反向質疑用戶事實 + 對稱協議完整實作」，且文檔明確說明「v6.2.0 才做」。

- 實際觀察：✅ BC-7 第 5 條 3 行輕量觸發；3 處檔案標註「K-14 v6.2.0」；無新增「反向質疑協議」獨立 Section（K-14 規劃中是 Section 12 + 13 擴充 + concepts/閉環核心理念補對稱性）

**若為假（v6.0.0 偷渡 K-14）會觀察到**：BC-7 規格 ≥ 60 行、新增「反向質疑協議」獨立 Section、Section 12 / 13 結構大改、`design/08` 把 K-14 移到 v6.0.0 milestone。

- 實際觀察：❌ 並非如此（BC-7 28 行、無新 Section、Section 12/13 結構未動、design/08 K-14 仍在 v6.2.0 表）

### 共用值檢查

「K-14 v6.2.0」標註出現在 ≥ 3 處（CLAUDE_TEMPLATE.md:261 / :274 / concepts/閉環核心理念.md:214）→ **意圖性共用**（跨檔一致性確保用戶/開發者讀到同樣的 scope 邊界），符合 design/08 milestone 規劃。

### 決策

**強**（多個 A 級字面證據 + 反例通過 + 共用值檢查通過）

→ 可作為事實輸出

---

## 處置建議

### 弱證據主張

**無**。3 條主張全部評為「強」。

### 建議追蹤項

雖然當前 3 條主張全強，但有 1 個邊界風險值得在 v6.1+ 處理：

1. **主張 2 的外部依賴脆弱性**：X (Twitter) post URL `2015883857489522876` 是平台特定資源。建議 v6.1+ 規劃時：
   - 在 BC-2 兩處 README 補 archive.org 存檔 link 註解（純預防）
   - 或在 design/09（規劃 v6.1）裡明確「外部 URL 失效時的 fallback 策略」

此項屬於 v6.0.0 階段不阻擋，但建議寫入 v6.1.0 啟動前的「待決策清單」（design/08:248-258 模式）。

---

## 自檢

| 自檢項 | 狀態 |
|--------|------|
| 3 條主張各有 A 級證據 file:line 引用 | ✅ |
| 3 條主張各有反例檢查（雙向觀察） | ✅ |
| 3 條主張各有共用值檢查（共用 / 私有判讀） | ✅ |
| 弱證據主張處置 | N/A（0 條弱證據） |
| 唯讀模式（未修改任何檔案） | ✅ |
| 親自 Read / Grep 驗證證據（非主 agent 轉述） | ✅ |

---

最後修訂：2026-04-26（Phase 5 Step 9c 事實前提追溯完成 · 3 強 / 0 中 / 0 弱 · 不觸發回退）
