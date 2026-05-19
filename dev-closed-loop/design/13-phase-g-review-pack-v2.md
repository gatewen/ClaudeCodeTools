# Phase G v2 Review Pack — CLAUDE_TEMPLATE.md 行數優化（v2 重設後）

> **review 對象**：Phase G **v2** 重設方案（v1 經 Codex adversarial-review 後修正）
> **要 reviewer 做的事**：找 **v2** 是否仍有結構性盲點，特別「v1 修正不徹底」+「v2 引入新風險」兩類
> **避免**：重複 v1 已抓到的 finding（v1 result 在 §7 附錄完整保留 — 作為 baseline）
> **建立**：2026-05-19 (origin: claude-opus-4-7 session 196883f8 / 觸發於補強計劃 §13.5.12)
> **不依賴**：本檔 self-contained，reviewer 不需讀其他檔
> **適合 reviewer**：
> - 不同 LLM（GPT / Gemini / Claude 不同版本）
> - 同一 LLM 不同 session（reset context）
> - 人類 maintainer

---

## 1. 背景

### 1.1 本 repo + Phase G 簡述

`AI-ClaudeCode` 是「開發設計閉環方法論」發佈倉庫。核心產物 `dev-closed-loop/CLAUDE_TEMPLATE.md`（547 行 / v6.3.0）作為 Claude Code 執行依據，部署到目標專案後成為該專案的 `CLAUDE.md`。

Phase G 目的：把 547 行降到 ~470-510 行範圍，為候選 A+E+B 採納捆綁解套（避免撞 600 行 hard 上限）。

### 1.2 v1 → v2 的重設原因

**v1 設計（已否決）**：A1 抽 metadata -50 / B1 抽工作規範 -7 / B2 壓 Trade-off -9 / B3 併持久化 -7 = 共 -73 行

**Codex adversarial-review** 對 v1 抓到 4 個 finding：

| # | 嚴重度 | 主題 |
|---|-------|------|
| F1 | 🔴 high | A1 抽 metadata 破壞已安裝 v6.3 Skill 升級相容性 |
| F2 | 🔴 high | B1 把安全/品質硬規則移出 always-read 主檔 |
| F3 | 🟡 medium | upgrade-notes 缺版本選擇 schema（現存 awk parser silent bug）|
| F4 | 🟡 medium | B3 未鎖住持久化 3 個不變式 |

**v1 verdict**：needs-attention，不建議出貨

完整 v1 finding 內容見 §7 附錄。

### 1.3 v2 重設方案總覽

| 項 | v1 | v2 修正後 |
|----|-----|---------|
| **A1** | 抽 metadata（-50）| **雙寫 + 版本化 schema parser + backward-compat stub**（-30~-40）|
| **B1** | 抽 Git/品質/文檔（-7）| **砍掉或極度縮小**（只移純風格條目）|
| **B2** | 壓 Trade-off 散文（-9）| 保留 v1 設計（純 onboarding，無 risk）|
| **B3** | 併持久化（-7）| **砍掉**（A1 已夠）|
| **Phase 3** | 跳安全審查 | **不跳**：對 instruction 降級 / migration parser / 舊 Skill 相容性做安全/回滾審查 |
| **CLAUDE_TEMPLATE 終態** | 474 行 | **~508 行**（緩衝 92）|

---

## 2. v2 詳細方案

### 2.1 A1' — 雙寫 + 版本化 schema + backward-compat stub

#### 2.1.1 設計目標

解決 v1 F1（跨版本 Skill 相容性）+ F3（awk silent bug）兩 finding。

#### 2.1.2 機制

**雙寫策略**：
- `dev-closed-loop/upgrade-notes.md`（新檔）：放新版（v6.4.0 後）的 migration-notes
- `CLAUDE_TEMPLATE.md` 末尾：**保留 backward-compat stub** — 列出舊 anchor（給已安裝 v6.3 Skill 走「當前對話繼續升級」路徑用）

**版本化 schema**：

`upgrade-notes.md` 內每個 migration block 必有 frontmatter：

```yaml
---
migration-id: v5-to-v6.0.0  # 或 v6.0.0-to-v6.2.0 等
from-version: v5.x          # SemVer 範圍
to-version: v6.0.0
applies-to: deployed_version starts_with "v5."
---
```

**parser 升級**：

`init-claude.md` Step 5.2 改邏輯：
1. 解析 `upgrade-notes.md` 所有 migration block
2. 按 `applies-to` 過濾（只取符合 deployed_version 的 block）
3. 按 `from-version` → `to-version` 拓樸排序（如 v5 → v6.2 → v6.3 → v6.4 累積套用）
4. 過渡期支援：解析失敗或檔案不存在 → fallback 讀 `CLAUDE_TEMPLATE.md` stub

#### 2.1.3 backward-compat stub 設計

`CLAUDE_TEMPLATE.md` 末尾保留：

```html
<!-- backward-compat stub（給 v6.3 及更舊 Skill 用，v6.4+ Skill 應讀 upgrade-notes.md） -->
<!--
migration-notes (legacy stub · 完整內容在 upgrade-notes.md)
from-version: v5.x
to-version: v6.0.0
anchors:
  - name: section-0
    match: "## ⚠️ 執行約束（最高優先級）"
    position: before
  - ...
-->
```

只保留 anchors 列表（舊 Skill 需要的最小資訊），其他內容（breaking-changes / required-actions 等詳述）移到 `upgrade-notes.md`。

**Sunset 條件**：當所有已知用戶都升到 v6.4+ 後（建議觀察期 ≥ 3 個月 + 用戶確認），stub 可移除。

#### 2.1.4 預期行數變動

- CLAUDE_TEMPLATE.md：line 493-547 原 55 行 metadata → 保留 stub ~15 行（A1' 淨節省 **-40 行**）
- 新建 `upgrade-notes.md` ~70 行（含完整 migration history + 新 v6.4 entry）

### 2.2 B1' — 砍掉或極度縮小

#### 2.2.1 設計目標

解決 v1 F2（安全/品質規則「載入保證」維度）finding。

#### 2.2.2 修正後邊界

CLAUDE_TEMPLATE.md line 462-472「工作規範」段 4 條目：

| 條目 | v1 處置 | v2 處置 | 理由 |
|------|--------|--------|------|
| **Git** | 移走 | **可移**「commit message 格式」純風格部分 → Git工作流.md | 純風格，無安全/品質依賴 |
| **品質** | 移走 | **必保留主檔** | 含「外部輸入必驗證 / 敏感資料不寫死 / 測試覆蓋」安全/品質硬規則 |
| **文檔** | 移走 | **保留主檔** | 含「.claudedocs/、白話文、修訂不新增、專業眼光不討好」是執行紀律 |
| **問題追蹤** | 保留 | **保留主檔** | 兩層教訓架構對映 Section 6c |

**B1' 邊界**：只移「Git commit message 格式」一小段純風格條目（如「Co-Authored-By trailer 格式」），其他全部保留主檔。

#### 2.2.3 預期行數變動

- 移走 Git commit message 格式：-2~-3 行
- 加 cross-reference 到 standards/Git工作流.md：+0（行數合計近持平）

**B1' 預估 ~0 行節省**（從 v1 -7 大幅縮減）— 但這是必要犧牲，避免安全防線降級。

### 2.3 B2 — 壓 Trade-off 散文表格化（保留 v1 設計）

#### 2.3.1 設計目標

純 onboarding 段壓表格，無 risk。

#### 2.3.2 範圍

CLAUDE_TEMPLATE.md line 3-23「Trade-off 顯式宣告」21 行散文 → 表格 12 行：

- 代價/收益 → 表格化（3 級任務 × 代價/收益 = 表格 row）
- 不適用情境 prose 保留（自審 F3 邊界）
- **「## 語言設定」heading 必保留**（自審 F2 anchor `trade-off-section` 依賴）

#### 2.3.3 預期行數變動

**-9 行**（與 v1 相同）

### 2.4 B3' — 砍掉

#### 2.4.1 設計目標

解決 v1 F4（持久化 3 個不變式未鎖住）finding。

#### 2.4.2 處置

**不做併段**。CLAUDE_TEMPLATE.md line 448-459「跨 Session 持久化 + 跨時間語義記憶」12 行**保留現狀**。

理由：
- A1' 已能達成 -40 行節省，足以避開 600 行上限
- B3 併段風險（漏掉 3 個不變式：`.claude-loop/artifacts/` 必建 / `P1-design-spec.md` 必寫 / Sub-Agent 直接讀檔不經主 agent 轉述）不值得 -7 行收益
- 元紀律：「不可為任何效率理由弱化既有設計」（候選 E R-1）

**B3' 預估 0 行節省**。

### 2.5 Phase 3 — 強制安全/回滾審查（不跳）

#### 2.5.1 設計目標

v1 設計把 Phase 3 安全審查跳過理由是「純結構整理無新攻擊面」。Codex 反駁：A1' 涉及 migration parser + instruction 降級 + 舊 Skill 相容性 — 都是潛在攻擊/失敗面。

#### 2.5.2 v2 強制 scope

Phase 3 安全審查必查：
- **migration parser 安全**：upgrade-notes.md schema 是否有注入風險（用戶可能編輯）？解析失敗的 fail-safe 行為？
- **instruction 降級風險**：B1' 邊界劃在「Git commit 格式」是否真的零安全規則？grep 確認主檔仍含「外部輸入驗證 / 敏感資料 / 測試覆蓋」關鍵字
- **舊 Skill 相容性**：模擬已安裝 v6.3 Skill 跑新 v6.4 cache 升級的 4 條路徑（A 全替換 / B 智能合併 / C 手動 diff / Abort）
- **回滾路徑**：雙寫策略中途失敗時 atomic 回滾是否真 atomic？

---

## 3. v2 預期效果

| 情境 | CLAUDE_TEMPLATE.md | 緩衝（vs 600 上限）|
|------|------------------|------------------|
| 當前（v6.3.0） | 547 | 53 |
| Phase G v2 完成 | 547 - 49 = **498**（A1' -40 + B2 -9 + B1' -0 + B3' -0）| 102 |
| Phase G v2 + 採納候選 A+E（+28） | 526 | 74 |
| Phase G v2 + 採納候選 A+E+B（+53） | 551 | **49** |

對比 v1（緩衝 39 但有 high finding）— v2 緩衝 **74 / 49**，且零 high finding。

---

## 4. v2 風險檢查 — 我已想到的

### 4.1 雙寫 drift 風險

CLAUDE_TEMPLATE.md stub 與 `upgrade-notes.md` 內容**兩處同步維護**有 drift 風險。

緩解：
- stub 內**只列舊 Skill 必需的最小資訊**（anchors）
- 新版 migration 只寫 upgrade-notes.md，不更新 stub（stub frozen at v6.4 schema）
- 加 test-cross-file-consistency 斷言 stub 結構不被誤改

### 4.2 backward-compat stub 移除時機不明

「觀察期 ≥ 3 個月 + 用戶確認」是 hand-wavy。

緩解：建議在 §13.5.12 v2 設計加 explicit sunset 規則：「stub 在 v7.0.0 重大版本升級時隨方法論重設一併移除（強制斷點，提供 cross-grade migration 工具）」。

### 4.3 版本化 schema 的回溯升級複雜度

如果用戶卡在 v6.1（沒升 v6.2），現在跳升 v6.4，parser 須 cumulative 套用 v6.1→v6.2 + v6.2→v6.3 + v6.3→v6.4 三個 migration。

緩解：
- Phase 1 設計需 explicit 列「cumulative migration 拓樸排序」演算法
- Phase 4 測試含跨多版本案例（v5→v6.4 / v6.1→v6.4 / v6.3→v6.4）

### 4.4 stub 與 upgrade-notes.md 衝突時的優先級

舊 v6.3 Skill 讀 stub，新 v6.4 Skill 應讀 upgrade-notes.md — 但如果 v6.4 Skill 也 fallback 讀 stub（解析新檔失敗時），可能拿到過時資料。

緩解：v6.4 Skill 的 fallback 條件嚴格化（只在「檔案不存在」時 fallback；解析失敗應報錯不是 silent fallback）。

---

## 5. 給 reviewer 的 questions

### 5.1 v1 finding 在 v2 是否真解決？

逐條檢查：

| v1 finding | v2 對應修正 | reviewer 判定真解決？ |
|-----------|------------|--------------------|
| F1 跨版本 Skill 相容性 | A1' 雙寫 + stub | ？ |
| F2 安全規則載入保證 | B1' 邊界縮為「Git commit 格式」 | ？ |
| F3 awk parser silent bug | A1' 版本化 schema + applies-to filter | ？ |
| F4 持久化 3 不變式 | B3' 砍掉（不做併段）| ？ |

### 5.2 v2 是否引入了 v1 沒有的新風險？

特別檢查：
- 雙寫 drift（§4.1）— 我列的緩解夠嗎？
- backward-compat stub sunset 規則（§4.2）— 「v7.0.0 一併移除」是否合理？
- 版本化 schema 的累積套用邏輯（§4.3）— 拓樸排序是否會遇到衝突 case？
- stub fallback 優先級（§4.4）— v6.4 Skill 何時該 fallback？

### 5.3 B1' 邊界劃法合理？

我把「Git commit message 格式」當「純風格」可移走。但：
- Git workflow 是否含某些「commit 安全紀律」（如「不可 commit 敏感資料」）？
- 「commit message 格式」算 metadata 還是工程紀律？
- 是否應該乾脆完全砍掉 B1，連 Git commit 格式都不移？

### 5.4 A1' 的 backward-compat stub 設計是否最小化？

我設計 stub 只含 anchors。但 v5.x → v6.0.0 migration 還含 `breaking-changes` / `required-actions` — 這些舊 Skill 是否真的不需要？

### 5.5 Phase 3 安全審查 scope 是否完整？

我列了 4 個必查項（§2.5.2）。reviewer 看到的還有第 5 個必查項嗎？

### 5.6 是否有更好的「行數優化」替代方案 v3？

例如：
- 只做 B2 不做 A1（節省 -9，可能不夠）
- A1 改「按 retention period 自動 archive 舊 migration」（自動清理）
- 整個 Phase G 取消，改用嚴格捆綁判定（不採納 B 級候選）

### 5.7 v2 行數估計（547 → 498，緩衝 102）是否真實？

我估的「stub 15 行」「B1' -0」是否樂觀？

### 5.8 整體 verdict：v2 是 needs-attention / ready / needs-rework？

---

## 6. 要 reviewer 給的輸出

### 6.1 判定（3 選 1）

- **採納 v2**：v2 解決了 v1 finding，可進入 Phase 1 architect
- **修改 v2**：v2 仍有問題（請指出 + 怎麼改）
- **v2 仍然 needs-attention**：v2 引入了新 finding 或 v1 finding 未真解決

### 6.2 主要風險（v2 specific）

reviewer 看到的 v2 新風險（按優先級）：
1.
2.
3.

### 6.3 v1 finding 真解決度評估

| v1 finding | 真解決？ | 理由 |
|-----------|--------|------|
| F1 | ✅/⚠️/❌ | |
| F2 | ✅/⚠️/❌ | |
| F3 | ✅/⚠️/❌ | |
| F4 | ✅/⚠️/❌ | |

### 6.4 替代方案建議

reviewer 看到的 v3 替代方案（如有）：

---

## 7. 附錄：Codex v1 adversarial-review 完整結果

### 7.1 v1 verdict

**needs-attention** — 不建議出貨。

「Phase G 目前會破壞既有升級相容性，並把原本每 session 必讀的安全/品質/持久化紀律移到不保證載入的文件；A1/B1/B3 需要重設邊界與測試。」

### 7.2 v1 4 finding 詳述

#### F1 [high] A1 會讓舊版 Skill 的官方升級路徑讀不到 migration-notes

A1 最終只在主檔保留 `closed-loop v6.4.0`，把 migration notes 抽走；但已安裝的 v6.3 Skill 在 upgrade 後允許使用者「繼續在當前對話中升級」，該舊 Skill 的 Step 5.2 仍會從新 cache 的 `CLAUDE_TEMPLATE.md` awk 解析 migration-notes。也就是推薦新對話以外的官方選項會在 v5.x→v6.4.0 時失效，可能降級到手動 diff 或錯過必要插入段落。

**Recommendation**: 至少保留一個過渡版的舊相容 migration-notes stub 在 `CLAUDE_TEMPLATE.md`，或移除/硬阻擋「當前對話繼續升級」跨 v6.4 的路徑；新增用舊 v6.3 Skill 升新 v6.4 cache 的回歸測試。

#### F2 [high] B1 把安全/品質硬規則移出 always-read 主檔

B1 要把 Git/品質/文檔三條移到 `Git工作流.md`。目前「品質」包含「外部輸入必驗證」和「敏感資料不寫死」，是在 `CLAUDE_TEMPLATE.md` 中每 session 可見的硬紀律；移到 `.claudedocs/standards/Git工作流.md` 後，現有參考表沒有要求任務開始時讀這個檔案，cross-reference 不能保證模型會載入。這是安全/資料外洩防線降級，不只是結構整理。

**Recommendation**: 只外移 Git commit 工作流和文檔風格；將外部輸入驗證、敏感資料、測試覆蓋等品質/安全規則保留在主檔，並加測試斷言主檔仍含這些關鍵字。

#### F3 [medium] 新的 upgrade-notes 缺少版本選擇語意

設計承認多個 migration-notes 區塊會共存，但沒有規定 parser 如何依 deployed version 選擇區塊。現有 `init-claude.md` awk 條件是 `b ~ /migration-notes/`，實測目前已會同時輸出 v5→v6 與 v6.2 區塊；加入 v6.4 後，v5.x、v6.1、v6.3 升級都可能拿到不屬於自己的 notes，導致錯誤摘要、錯誤 anchors 或漏套 cumulative migration。

**Recommendation**: 把 `upgrade-notes.md` 定義成明確 schema，含 `from-version`/`to-version`/`applies-to`，Step 5.2 必須按 deployed/cache version 過濾並排序；測 v5.x→v6.4、v6.1→v6.4、v6.3→v6.4、重複/缺失區塊。

#### F4 [medium] B3 未鎖住持久化防轉述遺漏的不變式

B3 只說把「跨 Session 持久化 + 跨時間語義記憶」從 12 行併成 5 行，但沒有列出必須保留的語義。現行段落包含高價值不變式：完整閉環要建 `.claude-loop/artifacts/`、Phase 1 design spec 必寫到 `P1-design-spec.md`、Sub-Agent 從檔案直接讀而不是吃主 agent 轉述。壓縮若漏掉任一點，會重新引入跨 agent 規格遺漏。

**Recommendation**: B3 實作前先列 preservation checklist，至少斷言主檔仍保留 artifact 目錄、`P1-design-spec.md`、direct-read/no-summary 三個不變式；若行數壓力已由 A1 解決，直接放棄 B3。

### 7.3 v1 Next steps（Codex 原文）

- 先採 A1 的相容性重設與版本化 parser 測試；未完成前不要刪主檔 migration-notes。
- 取消或縮小 B1/B3：A1 單獨已可省約 50 行，足以避開 600 行上限，沒有必要用高風險規則外移換 14 行。
- Phase 3 不應跳過安全審查；至少做針對 instruction 降級、migration parser、舊 Skill 相容性的安全/回滾審查。

---

**Review 結束後**：請把 §6 判定 + 風險 + 替代方案 + finding 補充回給 setup session 的用戶，由用戶決定是否進入 Phase G v2 實施。
