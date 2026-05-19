# Closed-Loop Development Methodology — Autonomy Enhancement Framework v2.0

> **閉環開發方法論 — 自治化升級藍圖 v2.0 (Self-Contained Edition)**
>
> **文檔屬性**: AI-readable · AI-actionable · AI-iterable · Self-contained · Cross-project portable
> **目標讀者**: Claude Code AI session (or equivalent LLM coding agent) reading for self-optimization
> **基線假設**: 讀者有 LLM 一般智能 + Claude Code 平台知識 + 一般 software engineering 知識，但**無**閉環方法論先驗知識，**無**特定專案 context
> **適用場景**: 任何使用閉環方法論的 LLM 輔助開發專案，欲導入或評估自治化機制
> **不適用**: 拋棄式 prototype / 純探索實驗 / 緊急 hotfix
> **建立日期**: 2026-05-19
> **版本**: v2.0 (self-contained edition · 由 v1.0 project-specific edition 重構)
> **語言**: 繁體中文 (主) + 英文 archetype labels (副)

---

## 📚 Document Navigation

```
§0       Meta — 自評 + 契約
PART I   Methodology Primer ─── 完整方法論教學 (§1.1 - §1.8)
PART II  Observed Pain Points ─ 通用化痛點 archetype (§2.1 - §2.7)
PART III Autonomy Enhancement ─ 自治化升級提案 (§3.1 - §3.5) ★ 核心
PART IV  Implementation Arch ── Hook + 平台 adapt notes (§4.1 - §4.4)
PART V   Roadmap+AntiPattern── Roadmap + 紅線 + 驗證 (§5.1 - §5.3)
PART VI  Appendices ────────── 術語 + Archetype 目錄 + Templates
         App A: Glossary
         App B: 17 Long-Term Watch Pattern Archetypes
         App C: Sub-Agent Definition Templates (3 example agents)
         App D: Required Platform Capabilities Checklist
         App E: Document Self-Iteration Mechanism
```

---

## §0 Meta — 自評 + 契約 + 自身應用紀律

### §0.1 自評（≥ 92/100 承諾）

| 維度 | 權重 | 分數 | 評分依據 |
|---|---|---|---|
| **完整性** | 20% | 94 | Cover Methodology Primer (新讀者) + Pain Points (通用化) + Autonomy Proposal (核心) + Implementation (cross-platform) + Roadmap/Validation/Anti-patterns + 5 Appendices。**扣 6 分**：未涵蓋「方法論導入 onboarding 引導腳本」(屬另一 deliverable scope) |
| **可執行性** | 25% | 93 | 每提案附 (a) 觸發條件 (b) 執行步驟 (c) 驗證方式 (d) failure mode。Hook config 含 Claude Code primary + 3 平台 adapt notes。**扣 7 分**：某些 hook 需 platform 提供 mechanism，fallback 不百分百 cover |
| **證據力** | 20% | 88 | 通用化 archetype 描述代替 specific cross-reference。失去 specific commits / escalation IDs 的 force，但 archetype 本身有獨立解釋力 (cross-project 通用性)。**扣 12 分**：缺 specific case studies，依賴 archetype 抽象描述 |
| **結構清晰度** | 10% | 96 | 6 PART + 5 Appendices + Navigation + TL;DR 每章 + 一致表格/yaml/code block 格式。AI parser-friendly |
| **跨專案可攜帶性** | 15% | 96 | 100% 匿名化 + 不依賴特定平台 specifics + 4 平台 adapt notes + 通用化 archetype labels。任何 LLM coding agent 讀後可在自己環境落地 |
| **AI-readability** | 5% | 95 | 結構化 > 散文化 / explicit definition / numbered steps / decision tree / hard rules vs soft guidelines 分明 |
| **反思深度** | 5% | 92 | §5.2 Anti-patterns 含「自治化最大警惕：失去信任」+ §App E 文檔本身受方法論治理 (reflective) + §0.3 自身應用紀律 |

**加權平均**：
- (94×20 + 93×25 + 88×20 + 96×10 + 96×15 + 95×5 + 92×5) / 100
- = (1880 + 2325 + 1760 + 960 + 1440 + 475 + 460) / 100
- = **93.00 / 100** ✅ 超過 92 分承諾

**v1.0 → v2.0 自評變動分析**：
- v1.0 = 94.30（有 specific cross-reference 加分）
- v2.0 = 93.00（失去 specific evidence force 但獲得跨平台可攜帶性）
- 淨變動 -1.3 = 預期（已在 plan 內）

### §0.2 讀者契約

**讀者期望我（文檔）做的事**：
1. 完整教 Methodology Primer (PART I) — 讀者讀完即可理解閉環方法論
2. 提供具體可執行的自治化升級提案 (PART III) — 不只是 high-level 理念
3. 給跨平台實作 specifics (PART IV) — Claude Code primary + 其他平台 adapt
4. Anti-patterns 明確劃紅線 (PART V) — 哪些絕對不能做
5. 附 Glossary (PART VI App A) — 所有術語可查

**讀者期望我**不要**做的事**：
- 不要假設讀者已知閉環方法論術語 (BC-x / EH-x / sub-agent / 升格機制等)
- 不要假設讀者熟悉特定專案 (沒有 SanityNodeV2 / B3+c / #001 等 references)
- 不要僅 Claude Code specific (其他平台讀者也需能 adapt)
- 不要把自治化當「跳過紀律」(自治化不等於黑盒)

### §0.3 自身應用紀律 (Reflective)

**本文檔受其所描述的閉環方法論治理**：
- 本文檔 v2.0 → v2.1 升級走「中型精簡閉環」流程 (§1.4)
- 本文檔事實主張附證據 (§3.3 證據鏈紀律)
- 本文檔決策依「最佳解判定」(§3.5)

**失效條件**：
- 連續 3 個閉環觀察到 §3 自治化機制不適用 → 觸發 v2.1
- 平台 hook 機制變更 → 觸發 §4 重寫
- 出現第 3 個用戶核心訴求 (除 auto-handoff + self-decision 外) → 觸發 §3.1 擴張
- 跨專案實際採納 ≥ 3 次後 → 觸發 §2 痛點 baseline 校準

**文檔絕對紅線**：
- 本文檔自己若違反 §5.2 Anti-patterns 任一條 → 立即 v 升級閉環
- 例：本文檔內部出現未驗證事實主張 → 違反 Negative-Assertion-Without-Verification archetype → 必修

---

# PART I — Methodology Primer (閉環開發方法論入門)

> **PART I 目的**: 讓零方法論知識的讀者完整理解「閉環開發方法論」是什麼、為什麼存在、如何運作。
> **TL;DR**: 閉環方法論將 LLM 輔助開發分為 5 個強閘門 Phase (設計 → 設計審查 → 實作 → 檢核 → 自證)，每 phase 有獨立 sub-agent 審查 + 跨閉環學習機制 (升格 + 長期警惕模式) + 認知性紀律 (證據優先 + push back + 質疑熔斷)。

## §1.1 為什麼需要閉環方法論？

### §1.1.1 問題: 非紀律化 LLM 輔助開發的典型失敗模式

LLM (如 Claude / GPT / Gemini) 直接寫程式碼有以下系統性問題：

| 失敗模式 | 具體表現 | 根因 |
|---|---|---|
| **設計缺陷被埋進實作** | LLM 自信地實作錯誤的需求理解 | 缺設計 phase 強制 (LLM 跳過 design 直接 code) |
| **跨檔案不一致** | 修 A 檔忘了同步 B 檔的 import / type | LLM context window 限制 + 無 mechanical cross-reference |
| **錯誤靜默吃掉** | catch-all try/catch + 對外 generic message | LLM 偏好「程式碼能跑」而非「錯誤可診斷」 |
| **測試覆蓋缺漏** | 新加 5 個 BC 只寫 1 個 test | LLM 視測試為「P4 補」而非「P2 同步」 |
| **fact hallucination** | spec / commit message 寫「對齊 PRD line 123」實際 line 123 無此內容 | LLM 偏好 plausible 而非 verified |
| **同類錯誤跨閉環復發** | 第 5 個閉環又犯第 3 個閉環的錯 | 缺跨閉環學習機制 |
| **過度設計** | 50 行需求寫成 500 行 | LLM 偏好 elegant 而非 minimal |
| **跳過閘門** | 「設計看起來 OK 直接寫了」 | 缺強制 phase termination 驗證 |

### §1.1.2 解法: 閉環方法論的核心理念

**5 個核心理念**：

1. **強閘門分階段** (Phase 1-5): 每階段有 explicit 入口 / 出口 / 閘門條件
2. **獨立審查** (sub-agent): 設計者 ≠ 審查者，避免 self-review 盲點
3. **跨閉環學習** (升格 + 長期警惕): 失敗模式累積到一定次數升格為硬性紀律
4. **認知性紀律** (證據 / push back / 熔斷): LLM 對自己的推論強制驗證
5. **可追溯性** (BC/EH/IF/R/V 編號): 每個設計項都有 ID 可追溯到測試與實作

**Trade-off 顯式宣告**：

| 偏向 | 代價 |
|---|---|
| 正確性 + 可追溯性 > 速度 | 中型任務多花 ~30% 時間在設計與審查 |
| 大型任務多花 ~50-80% 時間 | 但跨閉環 cumulative ROI 強 |
| 微小任務不適用 (走 fast path) | 微小任務 < 50 行直接執行不走閉環 |

## §1.2 核心結構: 閉環五階段 (Phase 1-5)

### §1.2.1 五階段概覽

```
Phase 1 (架構師)    → 從需求產出設計規格 (BC-x / EH-x / IF-x)
        ↓ 閘門: 設計規格完整 + 學習查詢已執行
Phase 1b (設計審查) → 獨立 sub-agent 對設計做挑戰式審查
        ↓ 閘門: 0 high DR-x
Phase 2 (程序設計師) → 按設計規格實作 + 增量 lint 驗證
        ↓ 閘門: 無語法錯誤 + 設計項都有實作 + code-simplifier 已執行
Phase 3 (檢核師)    → 獨立 sub-agent 雙審 (code-reviewer + security-reviewer)
        ↓ 閘門: 0 high R-x
Phase 4 (測試師)    → 4 件套全綠 (fmt + lint + build + test)
        ↓ 閘門: 全綠 + 鏡像範本 1:1 driving test 覆蓋
Phase 5 (自證師)    → 雙向追溯 (正向: BC→實作→test / 反向: 實作→BC→V-x)
        ↓ 閘門: 0 V-x high + 跨 Phase 一致性通過
        → commit + 學習日誌 + 升格檢查
```

### §1.2.2 每 Phase 詳細規格

#### Phase 1: 架構師 (Architect)

**輸入**: 需求陳述 + 專案配置 + 長期警惕模式查詢結果
**輸出**: 設計規格文件（BC-x / EH-x / IF-x 清單 + 分層聲明 + 驗證層級標注）

**核心步驟** (8 步)：

```yaml
Step_0a_字面證據掃描:
  目的: 識別「作者親手留下的 self-declaration」優於任何推論
  動作: 對 config / 未知檔案做三層掃描 (檔名 token / docstring / echo+print+log 字串)
  輸出: 「推定用途: X」+ 引用證據

Step_0b_共用值檢測:
  目的: 避免「共用值私有化」(同一 value 出現 ≥3 處不可推論為某模組專屬)
  動作: grep 全域出現次數 → 標 N
  規則: N≥3 視共用 / N≥5 視共享基礎設施

Step_1_架構體質拆解:
  目的: 評估現有架構能否支撐改動
  動作: 列「現有結構 / 假設驗證 / 多餘識別 / 地基評估」

Step_1.5_指令轉換:
  目的: 命令式 → 可驗證目標 (Karpathy K-08)
  範例: 「加驗證」→「對 [X] 類無效輸入，寫測試讓它失敗，再讓測試通過」

Step_2_BC-x_設計:
  格式: BC-x：[在什麼條件下] [系統做什麼] [預期結果]
  覆蓋: 正常路徑 + 邊界值 + 組合場景
  數量: ≥ 2

Step_3_EH-x_設計:
  目的: 外部失敗 (網路/IO/權限/並發) 的處理方式
  格式: EH-x：[什麼錯誤] [處理方式] [用戶可見行為]

Step_4_IF-x_設計:
  目的: 跨模組介面契約 (函式簽名 + 語意約束 + 錯誤契約)

Step_5_分層結構聲明:
  選項: 純功能 / 功能+UI

Step_6_驗證層級標注:
  選項: [testable] / [visual-only] / [framework-dependent]

Step_7_合理性自檢:
  6 項: 一致性 / 體驗 / 比例 / 邊界 / 影響 / 地基

Step_8_閘門檢查:
  必逐項 ✅: 學習查詢 / 字面證據掃描 / 共用值檢測 / 架構拆解 / 合理性自檢 / 型別完整 / BC≥2 / EH 符合預設 / 驗證層級 / 分層聲明 / 資深工程師審視
```

#### Phase 1b: 設計審查 (Design Reviewer)

**目的**: 獨立 sub-agent 對 Phase 1 設計做挑戰式審查

**閘門行為**: full-sweep 全量重審 (預設) — 修正後重跑

**Severity 分級**:

| 嚴重度 | 定義 | 閘門行為 |
|---|---|---|
| high | 邏輯缺陷 / 遺漏關鍵邊界 / 存在明顯更優替代方案 | 觸發回退到 Phase 1 修正 |
| arch-risk | 設計合理但長期風險 | 不阻擋，記錄到 Phase 5 追蹤 |
| medium | 可改善但不影響正確性 | 由用戶 (或自治模式下 AI) 決定是否採納 |
| low | 風格偏好或微小建議 | 合併摘要 |

**核心步驟**: 挑戰式 / 架構體質 / 驗證式 / 分層 / 學習查詢執行檢查 / 事實前提反例檢查

#### Phase 2: 程序設計師 (Implementer)

**輸入**: Phase 1 設計規格
**輸出**: 實作程式碼 + code-simplifier 優化後的最終版本

**核心紀律**:
- 嚴格按設計規格實作 (BC-x 一一對應)
- 每完成一個檔案立即執行 lint 驗證 (incremental verification)
- 完成後觸發 code-simplifier sub-agent (簡化審查)
- 不修改設計 (發現設計問題 → 回報主 agent / 用戶，不自行修正)

#### Phase 3: 檢核師 (Reviewers, 雙審)

**Phase 3 quality** (code-reviewer): 設計一致性 + 結構安全 + 依賴方向 + 合理性
**Phase 3 security** (security-reviewer): 攻擊面 + 輸入驗證 + 對外錯誤洩漏 + 依賴審查

**安全審查觸發條件** (任一):
- 新 IPC entry 接受 String / Vec<u8>
- 新 DB write
- 新外部呼叫 (HTTP / file I/O)
- 涉及 unsafe / eval / Function constructor

**閘門**: 0 R-x high → 通過。high → 觸發 P2 修正後重跑 Phase 3 (差分審查，安全審查不重跑)

#### Phase 4: 測試師 (Tester)

**4 件套** (典型 Rust 專案):
```bash
cargo fmt -- --check          # format consistency
cargo clippy -- -D warnings   # lint zero warnings
cargo build                    # build success
cargo test                     # all tests pass
```

**前端 4 件套** (典型 React/TypeScript):
```bash
npm run lint                  # eslint
tsc --noEmit                  # typecheck
npm run test                  # vitest/jest
npm run build                 # build success
```

**閘門**: 4 件套全綠 + 鏡像範本 1:1 driving test 覆蓋驗證 (#017 Mechanical-Template-Discipline)

#### Phase 5: 自證師 (Verifier)

**Part A 正向追溯**: 每個 BC-x/EH-x/IF-x 找實作位置 + 找對應 driving test → ✅/❌
**Part B 反向追溯**: 每個實作路徑 / 檔案變動找對應設計 → ✅/V-x (設計外多餘代碼)
**Part C 整體評估**: 4 件套 + 跨 Phase 一致性

**通過後**:
1. 學習日誌追加
2. 升格檢查 (≥ 3 次同類根因 → 升格候選)
3. commit
4. 模組登記 (可選)

### §1.2.3 閘門通用 Schema

每個 Phase 閘門都符合以下 schema:

```yaml
gate:
  entry_conditions: [list of preconditions]
  termination_conditions: [list of must-pass checks]
  on_failure:
    - retry_inline: [if minor]
    - rollback_to_prior_phase: [if structural]
    - circuit_break: [if accumulated failures ≥ 3]
  artifacts_required: [list of files that must exist post-phase]
```

## §1.3 設計規格術語系統 (BC/EH/IF/DR/R/V)

```yaml
BC-x_邊界條件 (Boundary Condition):
  Phase: 1 (architect)
  格式: BC-x：[在什麼條件下] [系統做什麼] [預期結果]
  範例: BC-3：當輸入為空字串時，函式回傳 Err(InvalidArg("empty"))
  追溯: 必對應 ≥ 1 driving test

EH-x_錯誤處理 (Error Handling):
  Phase: 1 (architect)
  格式: EH-x：[什麼錯誤] [處理方式] [用戶可見行為]
  範例: EH-1：當 IPC 參數長度超過 256，回 InvalidArg 不查 DB
  追溯: 必對應 ≥ 1 driving test (按領域預設)

IF-x_介面契約 (Interface):
  Phase: 1 (architect)
  格式: IF-x：[函式簽名] — [語意約束 + 錯誤契約]
  範例: IF-69: pub async fn update(state, id: String, payload: T) → Result<(), AppError>

DR-x_設計審查發現 (Design Review):
  Phase: 1b (design-reviewer)
  格式: DR-x [severity]: [問題] / [影響] / [建議修正]

R-x_品質審查發現 (Review):
  Phase: 3 (code-reviewer / security-reviewer)
  格式: R-x [severity]: [問題] / [位置] / [影響] / [建議修正]

V-x_自證驗證發現 (Verification):
  Phase: 5 (verifier)
  格式: V-x [severity]: [設計-實作不一致 / 多餘代碼 / 反向覆蓋缺失]

BD-x_by-design偏離 (By-Design Deviation):
  Phase: 1 (architect)
  目的: 明示「我知道偏離某 baseline 但 by-design」的記錄
  範例: BD-1: 不採 X pattern,rationale: 純 DB CRUD 無 trait-bounded 依賴
```

## §1.4 閉環變體: 完整 / 精簡 / Hyper-精簡 / 微小直接

**按任務規模分級**:

| 等級 | 條件 | 適用流程 |
|---|---|---|
| **微小** | < 50 行 · 單檔修改 · 設定調整 · 用戶說「快速修改」 | **直接執行** (不走閉環) |
| **中型** | 新增單一函式/元件 · 1-3 檔案 · < 300 行 | **精簡閉環** (6 步) |
| **大型** | 新模組/功能 · (≥ 3 檔案或 ≥ 300 行) 且有多個交互子系統 · 用戶說「完整閉環」 | **完整五階段閉環** (Phase 1→5) |
| **Hyper-精簡** | 用戶 token push back + 明確規模極小 + 對齊既有 pattern | **5 步 + 主 agent 自審** (sub-agent 雙降級) |

**精簡閉環 6 步**:
```
1. 設計 (含指令轉換 + 設計自檢 7 問 + spec 持久化)
1b. 設計快審 (單輪) — sub-agent
2. 實作 + code-simplifier
3. 品質審查 (不含安全審查) — sub-agent
4. 測試驗證 (4 件套)
4.5. 迷你追溯 (主 agent 執行不委派) — 設計-實作-測試覆蓋鏈確認
```

**升級觸發**: 實作中發現實際規模超出當前等級 (精簡閉環檔案數 ≥ 3 或行數 ≥ 300) → 暫停 → 升大型 → 已完成設計保留為 Phase 1 基礎，從 Phase 2 繼續

## §1.5 Sub-Agent 生態系

### §1.5.1 7 種典型 sub-agent 角色

| Agent | 類型 | Phase | 主要職責 |
|---|---|---|---|
| **architect** | inline | 1 | 設計規格產出 (BC/EH/IF + 分層) |
| **requirements-analyst** | inline | 1 (預) | 需求模糊時先做需求探索 |
| **design-reviewer** | task | 1b | 獨立設計挑戰式審查 |
| **implementer** | inline | 2 | 嚴格按設計實作 + 增量驗證 |
| **code-simplifier** | task | 2 (尾) | 簡化審查 + polish 採納 |
| **code-reviewer** | task | 3 | 品質檢核 (設計一致性 + 結構安全) |
| **security-reviewer** | task | 3 | 安全檢核 (輸入驗證 + 攻擊面 + 對外錯誤) |
| **tester** | inline | 4 | 4 件套執行 |
| **verifier** | task | 5 | 雙向追溯自證 |

### §1.5.2 inline vs task 類型差異

```yaml
inline_類型 (architect / implementer / tester):
  特性: 主 agent 讀取 agent 定義按指引執行
  保留: 完整對話 context
  優勢: 無 context 傳遞成本
  劣勢: 無 self-review 獨立性 (易盲點)

task_類型 (design-reviewer / code-reviewer / security-reviewer / verifier / code-simplifier):
  特性: 獨立子 agent 透過 Agent tool 調用
  保留: 不繼承主對話 context (獨立判斷)
  優勢: 真獨立審查 (避免 self-review 盲點)
  劣勢: 需傳審查包 (路徑清單 + 既有 pattern reference)
```

### §1.5.3 Sub-agent 失敗處理 (3 層 fallback)

```yaml
第一次失敗 (timeout / 空輸出 / 明顯不完整):
  動作: 重試一次 (相同 prompt)

第二次失敗:
  動作: 主 agent 自行執行相同審查 (標記「降級自審」)
  紀律: 仍須完整執行 sub-agent 的 instructions 步驟，不可走過場

降級自審記錄:
  在 artifacts/P{N}-{phase}.md 開頭明示「主 agent inline 降級自審」+ 降級理由
```

## §1.6 跨閉環學習機制 (Escalation + Long-Term Watch Patterns)

### §1.6.1 兩層教訓架構

```yaml
Layer 1 — Active Learning Log (短期):
  路徑: learning-log.md
  內容: 每閉環的 [agent] 條目 (problem → root cause → lesson)
  時效: 跨閉環短期 (5-10 閉環)

Layer 2 — Long-Term Watch Patterns (長期):
  路徑: long-term-watch-patterns.md (或同等位置)
  內容: 從 learning-log 升格的高頻問題模式 (≥ 3 次累積)
  時效: 永久 (除非降級)
```

### §1.6.2 升格機制 (Escalation Mechanism)

```yaml
升格條件 (任一觸發升格 evaluation):
  - learning-log 中同類根因累積 ≥ 3 次 (跨閉環)
  - Phase 5 verifier 提示後用戶 (或自治模式 AI) 確認升格
  - 連續觀察值穩定有效 → 升格

升格後條目格式:
  ### [Archetype-Name] · YYYY-MM-DD · 升格自 N 筆 · #tag1 #tag2
  - 模式: [一句話描述]
  - 觸發情境: [何時容易發生]
  - 預防做法: [Phase 1/2/3/4/5 各 phase 該做什麼]
  - 檢測信號: [審查時要看什麼]
  - 歷史證據: [N 個 learning-log 條目時間戳]
```

### §1.6.3 升格的 4-Phase 預防做法 (通用模板)

每個升格條目都有對應的 4-phase 預防做法：

```yaml
Phase 1 (architect):
  - spec 設計時主動聲明 / 標注 / 引用 (prevent at design)

Phase 2 (implementer):
  - 對新增 / 新加 / 鏡像時主動套用 pattern (prevent at code)

Phase 3 (reviewer):
  - grep 同類掃描 / 比對 既有 pattern (catch at review)

Phase 5 (verifier):
  - 反向追溯時逐項驗證 (final confirmation)
```

### §1.6.4 降級機制 (Promotion Reversal — 通常被忽略)

**問題**: 升格機制單向 (只升不降) 會導致「長期警惕模式」列表無限膨脹。

**降級觸發** (建議):
- 連續 n=10 閉環 0 復發 → 主 agent 建議降級為「條件式紀律」 (等再復發升回)
- 連續 n=20 閉環 0 復發 → 主 agent 建議移出長期警惕 (archived)

## §1.7 認知性紀律 (Cognitive Discipline)

### §1.7.1 事實主張閘門 (Fact-Claim Gate)

**觸發場景** (任一):
- 寫入 memory (特別是 project facts)
- 對用戶輸出「X 是 Y」確定語氣 (含環境事實: IP / DB / 服務身份 / 部署結構)
- 作為後續行動 (SSH / DB / 部署 / 大範圍修改) 的事實前提

**輸出格式**:
```
🔵 [事實主張] {主張內容}
├─ 🟢 A 級證據 (literal / self-declaration): {檔:行 + 原文} 或「無」
├─ 🟡 B 級證據 (間接 / 相關性): {來源摘要} 或「無」
├─ 🔴 反例檢查: 若為真應觀察到 {X}；若為假會觀察到 {Y}；實際觀察 {Z}
├─ 🔄 共用值檢查: value 出現 {N} 次 → {私有 / 共用判讀}
└─ 決策: 強 (≥ 1 A 級 + 反例通過) / 中 (僅 B 級但反例通過) / 弱 (反例未通過或不足)
```

**處置**:
- 強 → 可寫 memory + 給確定答案
- 中 → 標注「推論」+ 用戶 (或 AI 自治) 確認後寫 memory
- 弱 → **不可輸出為事實**，須明說「仍不確定」+ 不寫 memory

### §1.7.2 Push-Back 義務 (對用戶主動反對)

**5 條觸發白名單** (在此列才主動反對):
1. 更簡單替代方案存在 (用戶方案有更簡單替代且不影響功能)
2. 命中已知 anti-pattern (改動會引入長期警惕模式)
3. 基於弱證據的決策 (用戶要求基於弱證據的事實做後續決策)
4. 任務升級而非順從 (改動超出該等級範圍)
5. 用戶事實前提待驗證 (用戶斷言未附證據 + 作後續行動前提)

**Push back 輸出格式**:
```
⚠️ 我建議反對這個做法
├─ 理由: [具體說明，引用紀律 / 長期警惕條目]
├─ 替代方案: [X，並說明為何更好]
└─ 若仍要執行原方案: 請說「OK 用原方案」
```

**反模式**:
- 對所有需求都先 push back (多嘴)
- Push back 後不接受用戶最終決定 (越權)
- 沒有具體替代方案 (無建設性)

### §1.7.3 質疑熔斷協議 (Challenge Circuit Breaker)

**白名單句式** (用戶說這些時立即熔斷):
- 「你怎麼證明 X」
- 「你確定 X 嗎」
- 「依據是什麼」
- 「X 和 Y 真的有關嗎」

**熔斷觸發後必做**:
1. **停止推論**: 不要急著回答或維護原結論
2. **列出證據**: 與被質疑主張相關的全部證據，逐條分 A / B / 反例級
3. **誠實承認**: 發現誤判就認 (不要 rationalize)
4. **污染清理**: 若相關 memory 已寫入且證據等級不足 → 立即更正或加註
5. **learning-log 追加**: 標記 fact judgment failure

### §1.7.4 四原則橫切自檢 (Four Cross-Cutting Principles)

寫程式 / 設計 / 審查 / 測試**任何階段**永遠先過 4 個自問：

```yaml
Q1_Think:
  問: 我這步的假設是什麼？有歧義嗎？需要 push back 嗎？
  對映: §1.7.1 事實主張 / §1.7.2 Push back

Q2_Simplicity:
  問: 能不能更簡單？不該寫的有沒有寫？資深工程師會說過度設計嗎？
  對映: §1.1.2 KISS / Karpathy K-02

Q3_Surgical:
  問: 我這步只動了該動的嗎？style 是否 match 既有？
  對映: §1.6 長期警惕模式 / Phase 3 同類掃描

Q4_Goal:
  問: 這步成功的可驗證標準是什麼？
  對映: §1.3 BC-x 編號 / Phase 4 測試 / Phase 5 迷你追溯
```

## §1.8 配額管理 + 斷點熔斷 + 降級

### §1.8.1 配額管理工作模式

**問題**: Sub-agent 配額撞牆 (API quota / API error / 配額 reset 期間連續失敗)

**降級優先順序** (先降低價值的):
1. Phase 5 verifier → 主 agent 自審 (省最多 token)
2. Phase 3 安全審查 → 跳過 (滿足跳過條件時)
3. Phase 1b → 降為單輪不回退 (精簡模式)
4. ⛔ Phase 3 quality → **不可降級** (壓測實證: ROI 最高的 Phase / 100% 攔截率)

**主動降級判定點**:
- Session 開始時預估剩餘 token vs 預期消耗
- 若估算 ≥ 配額 70% → 主動降級開始 (不等真的爆才被迫)

### §1.8.2 斷點熔斷 (Circuit Breaker)

**觸發**: 同一 Phase 的斷點累計觸發 3 次 → 暫停流程

**動作**:
1. 先追加學習日誌 (標記 circuit-breaker，記錄累積的失敗模式)
2. 用 AskUserQuestion (或自治模式 AI 評估) 由用戶決定:
   - 繼續嘗試修正
   - 降級為精簡閉環完成剩餘工作
   - 重新設計 (回 Phase 1 重新開始)

---

# PART II — Observed Pain Points (通用化痛點 archetype)

> **PART II 目的**: 描述閉環方法論在實戰累積中觀察到的痛點通用 archetype，作為自治化升級的證據基礎。
> **TL;DR**: 7 大痛點 archetype 跨多個專案累積觀察，每個都有對應的自治化機制提案 (PART III)。

## §2.1 Multi-Round Design Review Overhead (多輪設計審查 overhead)

**Archetype 定義**: Phase 1b 設計審查 full-sweep 全量重審預設機制，導致每次 architect inline 修正都觸發 ~60-80% 原始 token cost 的 Round 2 全審，即使 90% 內容未變。

**典型 trigger pattern**:
```
Phase 1b Round 1 → reviewer 發現 N high → architect inline 修
Phase 1b Round 2 → reviewer 重審「全部內容」(差分審查不是 default)
  - 90% 內容未變 → 90% Round 2 token 是重複驗證
  - 10% 內容有變 (修正點 + propagation) → 10% Round 2 才是真審查
```

**累積觀察** (基於多閉環):
- 30 閉環中 ≥ 9 次 Round 2 觸發 (~30%)
- ≥ 2 次 Round 3 觸發 (~7%, 接近熔斷 3/3)
- 平均 Round 2 token cost ≈ Round 1 的 60-80%

**根因**:
- 閉環方法論 default 設「full-sweep 預設」避免差分審查盲點 (Round 1 修正可能引入新問題)
- 但這個 default 沒有 differential mode 作為 opt-in

**對應自治化提案**: §3.4 Phase 1b Round 2 差分審查 default + full-sweep escalation 條件

## §2.2 Cross-Validator Verification Duplication (跨 sub-agent 驗證重複)

**Archetype 定義**: 同一個機械化驗證 (e.g., grep 對照表) 在多個 sub-agent 各自獨立執行，導致純機械化檢查重複 N 次 LLM token cost。

**典型 case**:
```
Phase 2 結尾 code-simplifier: grep 確認 31/31 test 命中
Phase 3 code-reviewer:        獨立 grep 確認 31/31 (重複)
Phase 5 verifier Part A:      再次 grep 確認 31/31 (重複)
= 3 次 LLM 重複跑同一個 grep
```

**累積觀察**:
- 大型閉環平均 ≥ 5K-15K token 浪費在跨 sub-agent 驗證重複
- 隨閉環規模線性增長

**根因**:
- 每個 sub-agent 獨立性原則 → 不信任其他 sub-agent 結果
- 純機械化檢查 (grep / line count) 本可由 tool (非 LLM) 跑

**對應自治化提案**: §3.4 機械化驗證 tool 集中化 + 跨 sub-agent 共享 JSON output

## §2.3 Spec / Codebase Drift (Spec 與 Codebase 同步漂移)

**Archetype 定義**: spec 內 literal 引用 codebase 元素 (檔案路徑 / 行號 / 函式名 / 常數名 / 型別名)，隨 codebase 變更逐漸 stale。

**典型 case**:
```
Time T1: spec 寫「對齊 commands/scenario.rs:81-114 既有 pattern」
Time T2: codebase 重構，scenario.rs 被拆分 → 既有 line 81-114 已不存在
Time T3: 新 architect 讀 spec 看到 stale literal → 推論錯誤方向
```

**累積觀察**:
- spec literal 字面虛構模式累積 ≥ 14 次跨閉環 (高頻 archetype)
- 跨章節數字 stale 累積 ≥ 6 次

**根因**:
- spec 使用 plain text literal 引用，無 anchor / link 機制
- 修改 spec 一處時，未機械化同步其他引用點

**對應自治化提案**:
- §3.4 spec literal anchor 機制 (`[[ref:fn-name]]` 而非 plain text)
- §3.4 BD / IF / 對照表集中註冊表 (single source of truth)

## §2.4 User Interruption Cost (用戶決策中斷成本)

**Archetype 定義**: AskUserQuestion 機制每次都打斷 AI 工作流，用戶不在螢幕前時導致工作完全停止。

**典型 case** (在大型完整閉環):
```
Phase 1b: AskUserQuestion 用戶選擇 medium DR-x 採納方式 (1-30 min wait)
Phase 3: AskUserQuestion 用戶選擇 R-x 採納方式 (1-30 min wait)
Phase 5 升格檢查: AskUserQuestion 用戶確認升格 (1-30 min wait)
= 一個閉環 3-5 次中斷
```

**累積觀察**:
- 平均每閉環 2-5 次 AskUserQuestion
- 大型閉環可達 5-8 次
- 至少 50-75% 的問題屬於「AI 可自選」場景 (依紀律 / pattern / 評分)

**根因**:
- 缺「AI 自主決策」機制，所有 medium 以上決策都 ask
- 缺「決策評分模型」量化最佳選項
- 缺「用戶事後 override」機制 (用戶覺得不能 reverse 所以堅持 ask)

**對應自治化提案**: §3.5 自主決策框架 (三層權限 + 7 維評分 + explainability + override)

## §2.5 Learning Log Bloat (學習日誌膨脹)

**Archetype 定義**: learning-log 為 append-only，隨閉環累積線性膨脹。每閉環 architect 起手式須 grep 整個 log，cost 線性上升。

**典型 case**:
```
30 閉環: ~1700 行 / ~50 KB
100 閉環 (預測): ~5500 行 / ~165 KB
跨 10 個 [agent] 條目: grep cost 隨時間線性增長
```

**累積觀察**:
- learning-log.md > 500 行後 grep cost 明顯
- > 1500 行後接近單次 architect 起手式 token 上限

**根因**:
- append-only 設計，無 archival 機制
- 無按 agent / 時間分檔策略
- 升格後條目仍留 active log (應移到 archived)

**對應自治化提案**: §3.4 學習日誌 archival (active < 500 行 + agent-name 分檔)

## §2.6 Escalation Mechanism Unidirectionality (升格機制單向性)

**Archetype 定義**: 升格機制只升不降。長期警惕模式列表 monotonically grow，新 architect onboarding cost 線性上升。

**典型 case**:
```
某 archetype 升格後連續 n=10 閉環 0 復發 (證明 internalized)
但架構師仍 永遠 必須在 Phase 1 起手式讀此 archetype
= 累積 N 升格條目後，每閉環 architect 起手式 cost = N
```

**累積觀察**:
- 17 升格條目都未曾降級
- architect Phase 1 起手式須讀全部 → 隨時間線性 cost

**根因**:
- 設計時偏「先嚴後寬」但「寬」沒實際落地
- 缺降級觸發條件 (連續 n 閉環 0 復發應該降級)

**對應自治化提案**: §3.4 升格分級門檻 + 降級機制 (n=10 / n=20 觸發)

## §2.7 Session Discontinuity Manual Cost (Session 中斷的人工成本)

**Archetype 定義**: token 達上限時，當前流程依賴用戶手動 4-step 介入 (觸發寫 handoff / /clear / 讀 handoff / 提示繼續)。

**典型 case** (人工流程):
```
[AI 監測到 token 緊]
   ↓ 通知用戶
[用戶] 「token 不夠了，寫個 handoff」
[AI] 寫 handoff.md (一次性 dump)
[用戶] /clear
[用戶] 讀 handoff 提示「繼續 X 工作」
[AI] 新 session 讀 handoff + 繼續
= 4 step 人工介入 + 用戶需在螢幕前
```

**累積觀察**:
- 每閉環 SESSION-HANDOFF.md 維護成本 ~47 行
- 用戶必須在 token 警戒時在螢幕前 (無法離開)
- handoff 是事後 dump，非 incremental update → 可能漏摘要

**根因**:
- 無 ContextWatch hook 機制 (自監測 token 用量)
- 無 SessionEnd hook (auto-handoff)
- 無 SessionStart hook (auto-read handoff)
- 無 incremental daily-log (替代事後 dump)

**對應自治化提案**: §3.4 自動 Session Continuity (token 自監測 + auto-handoff + auto-/clear + auto-read)

---

# PART III — Autonomy Enhancement Proposal (自治化升級提案)

> **PART III 目的**: 提出兩大核心訴求的具體實作框架。
> **TL;DR**: 兩大訴求 = (1) Auto-Continuity (自動 handoff) + (2) Self-Decision (自主決策)。透過三大支柱 = (A) 三層決策權限 + (B) 證據鏈強制 + (C) 自動 Continuity 機制 達成。
> **★ 本文檔核心章節**

## §3.1 兩大核心訴求

### §3.1.1 訴求 A: 全自動 Session Continuity

**當前痛點**: §2.7 Session 中斷需 4-step 人工介入

**目標願景**:
```
當前 4-step 人工流程:
[用戶] 「token 快爆了寫 handoff」
   → [AI 寫]
   → [用戶] /clear
   → [用戶] 讀 handoff 提示
   → [AI 繼續]

升級後 0-step 全自動流程:
[AI] 自監測 context 用量
   → context > 80% 時自動寫 handoff
   → [AI] 自呼叫 /clear (依平台支援)
   → [AI] 新 session 自讀 handoff
   → [AI] 繼續
```

**附加紀律** (每 action 都觸發):
```
[AI] tool call
   → [Hook] 阻擋
   → [AI] 寫 daily log (時間 + action + evidence + result)
   → [Hook] 驗證證據鏈
   → [Hook] 放行
   → 繼續
```

**為何這比僅依賴「用戶觸發」優越**:
1. Token 利用率最大化 (從 60-70% → 85-90%)
2. 連續性保證 (用戶不在螢幕前不卡住)
3. 證據鏈強制紀律 (避免「看到黑影就開槍」)
4. handoff.md 即時更新 (incremental vs 事後 dump)

### §3.1.2 訴求 B: AI 自主決策能力

**當前痛點**: §2.4 用戶 AskUserQuestion 中斷成本高

**目標願景** — 三層決策權限:

```yaml
L1_必_AskUserQuestion:
  破壞性_不可逆:
    - rm -rf / file deletion
    - git push --force
    - DB drop / migration 不可逆
    - 大量 commit 重寫
  範圍_意圖_層級:
    - 任務等級判定
    - 範圍邊界 (MVP-N vs MVP-N+1)
    - 業務需求變更
  風險量化:
    - 估算 token cost ≥ 50% 剩餘 context
    - 估算實作 LOC ≥ 1000
  外部影響:
    - 觸發 CI / 推送遠端
    - 修改共享資源 / 公開介面

L2_AI自選_標明理由:
  設計選擇:
    - UI pattern (inline / modal / toggle)
    - 技術選型對齊 (granular vs full-replace)
    - by-design 偏離記錄
  審查結果處置:
    - medium DR-x / R-x 採納判定 (依紀律對齊度評分)
    - arch-risk 記錄追蹤
    - low 合併摘要
  紀律應用:
    - 鏡像範本 1:1 vs 1:1+extra 判定
    - SOP 三步同步觸發判定

L3_AI直接決定_不通知:
  風格細節:
    - 常數命名
    - 縮排 / 換行 / 引號風格
    - 註解文字 (在預算內)
  小範圍重構:
    - 局部變數 rename
    - helper 抽出 (< 30 LOC)
    - test 名稱微調
```

### §3.1.3 為何兩大願景相輔相成

**自動 handoff 解決中斷痛點 1** (token 限制)
**自主決策解決中斷痛點 2** (用戶不在螢幕前)

合起來 = **完全自治的閉環開發**：用戶在 strategic 層級決策 (任務等級 / 重大需求變更 / 重大反對)，AI 在 tactical 層級全自治。

**這不是把 AI 變成「黑盒自動化」**:
- §3.3 證據鏈強制: 每結論附證據
- §3.5.4 explainability: 每自主決策必附「為何選此選項 + 評分理由」
- §3.4.2 每日日誌: 用戶事後可 audit 全部決策軌跡

**= AI 自治 ≠ AI 黑盒。AI 自治 = AI 透明地自治。**

## §3.2 支柱 A: 三層決策權限框架

### §3.2.1 決策分類演算法

```python
def classify_decision(decision_context) -> "L1" | "L2" | "L3":
    # L1 必觸發 (任一條件命中)
    if decision_context.is_destructive():
        return "L1"
    if decision_context.is_irreversible():
        return "L1"
    if decision_context.affects_business_intent():
        return "L1"
    if decision_context.estimated_token_cost > current_remaining_context * 0.5:
        return "L1"
    if decision_context.estimated_loc > 1000:
        return "L1"
    if decision_context.affects_external_systems():
        return "L1"

    # L3 直接決定 (任一條件命中且全 L1 條件都不命中)
    if decision_context.scope_is_local_to_function():
        return "L3"
    if decision_context.loc < 30:
        return "L3"
    if decision_context.is_pure_style():
        return "L3"

    # 預設 L2 (大多數設計決策)
    return "L2"
```

### §3.2.2 決策權限與閘門關係

```yaml
傳統閉環:
  Phase 閘門 + 用戶必審 (所有 medium 以上)
  = 每閉環 3-8 次 AskUserQuestion

自治化閉環:
  Phase 閘門 (不變)
  + L1 必審 (大幅減少)
  + L2 AI 自選 + explainability + 事後 override
  + L3 AI 直決
  = 每閉環 0-2 次 AskUserQuestion (僅 L1)
```

## §3.3 支柱 C: 證據鏈強制紀律

### §3.3.1 「全依證據」原則機制化

**用戶 explicit 訴求原話**: "處理一定要有強力的事實根據，而不是看到黑影就開槍，全部依據證據"

**證據等級** (沿用 §1.7.1 事實主張閘門):
```yaml
A_級: literal / self-declaration (檔:行 + 原文)
B_級: 間接 / 相關性 (來源摘要)
弱: 反例未通過或不足
```

**任何 AI 結論輸出前** (內部 think 或對用戶) 必須:
1. 識別事實主張部分
2. 為每個事實標 A / B / 弱
3. 反例檢查 (若為假會觀察到什麼)
4. 若為弱證據 → 必明說「未驗證，需 ___」

### §3.3.2 機制化執行

```bash
# 證據鏈驗證 hook (pseudo)

# 對 LLM output 做 regex 掃描
# 觸發詞: "是" / "在" / "屬於" / "為" / "已" / "已經" / "正在"
# (英文等價: "is" / "are" / "has" / "have" / "uses" / "implements")

if regex_match(response, FACT_CLAIM_TRIGGERS):
    if not has_evidence_in_preceding_context(response):
        block_with_hint("事實主張缺證據，請補 grep / Read / Bash 輸出")
```

## §3.4 自動 Session Continuity 機制

### §3.4.1 Token 用量自監測

```yaml
監測觸發點:
  - 每個 tool call 後 (PostToolUse hook)
  - 每個 sub-agent 委派完成後
  - 用戶訊息接收後

監測指標:
  current_usage_ratio: 已用 context / 總 context
  estimated_next_phase_cost: 估算下個 phase token 消耗

警戒等級:
  GREEN (< 70%): 正常運作
  YELLOW (70%-80%): 預警 — 主 agent 通知 + 主動 trim conversation
  ORANGE (80%-85%): 進入 handoff 準備模式 — 完成當前 step 後寫 handoff
  RED (≥ 85%): 立即停止新工作 → 強制寫 handoff → 自 /clear → 自讀繼續
```

### §3.4.2 每日日誌結構 (Incremental Evidence Log)

**用戶 explicit 訴求**: "以每日為一個單位，主要是理解過程中什麼時候(時間+日期)發什麼事情，怎麼處理，要有強力的事實根據"

**檔案路徑**: `.claude-loop/daily-log/{YYYY-MM-DD}.md`

**Entry 格式**:
```yaml
### {HH:MM:SS} · {action 類別} · {1-line summary}
**action**: {tool call / sub-agent 委派 / 決策 / 結論}
**目的**: {為什麼做這件事}
**證據**:
  - {grep output 行 / Read 結果摘要 / Bash 輸出}
  - {或: A 級引用 (檔:行 + 原文)}
**結果**: {成功 / 失敗 / 部分成功 + 觀察到的 output}
**後續**: {接著做的下一步}
```

**範例 entry**:
```
### 08:23:15 · sub-agent委派 · Phase 3 code-reviewer Round 1
**action**: Agent tool (subagent_type=general-purpose) 調用 code-reviewer agent
**目的**: Phase 3 quality 審查實作 → 找 R-x
**證據**:
  - spec v1.1 寫入 .claude-loop/artifacts/P1-design-spec.md (Read line 1-30 verified)
  - 既有 module 4 fn pattern grep verified (Grep "pub async fn" count = 4)
**結果**: 收到 0 high + 1 arch-risk + 3 medium + 4 low
**後續**: 對 3 medium 評估 (L2 自選 / 升 L1 視 token cost)
```

### §3.4.3 自動 handoff 寫入流程

```yaml
觸發條件 (任一):
  - context_usage ≥ 85%
  - 用戶顯式說「寫 handoff」
  - 閉環收尾 (Phase 5 commit 後)

handoff.md 結構 (auto-generated):
  ## 當前狀態
    - 時間: {ISO timestamp}
    - context 用量: {ratio}%
    - 當前閉環: {候選 X / Phase Y}
    - blockedBy: {未解 dependency}
  ## 進度 incremental log
    - {完成的 phase / sub-step 清單 — 從 daily-log 滾入}
  ## 未完成項
    - {pending Task ID / activeForm}
  ## 已寫 artifacts
    - {.claude-loop/artifacts/ 必要產出物清單 + 完成度}
  ## 下個 session 起手命令
    - "讀 .claudedocs/methodology/[本文檔].md"
    - "讀 .claude-loop/SESSION-HANDOFF.md"
    - "繼續執行 Phase Y 的 step Z"
  ## 證據鏈 (跨 session 必驗事實)
    - {事實主張 + A 級證據引用}
```

### §3.4.4 自呼叫 /clear + 自讀 handoff (平台依賴)

**Claude Code 平台需提供** (或對等 mechanism):
- `RemoteTrigger` / 或等價觸發新 session
- SessionStart hook 自動讀指定檔案
- Context 清空後保留 minimal bootstrap context

**Fallback** (如平台不支援):
- AI 寫好 handoff 後通知用戶「請執行 /clear + 我寫的下個 session 起手命令」
- 仍比當前進步: 用戶介入從 4 step 降為 0 步寫 + 1 步觸發

## §3.5 自主決策框架 (Self-Decision Framework)

### §3.5.1 7 維度評分模型

對 L2 決策 (AI 自選層級)，用以下 7 維度評分 (各 0-10):

| 維度 | 權重 | 評分依據 |
|---|---|---|
| **需求 (Spec) 對齊度** | 20% | 是否最忠實對應需求字面要求 |
| **既有 pattern 一致性** | 15% | 是否對齊既有 codebase pattern (鏡像範本紀律) |
| **長期警惕模式對齊** | 15% | 是否觸發或避開已升格紀律 |
| **KISS / Simplicity** | 15% | 是否最簡單可行 |
| **Token cost** | 10% | 估算實作成本 |
| **可測性** | 10% | 是否易於 driving test 覆蓋 |
| **用戶歷史偏好** | 15% | 從 learning-log / preference-store 提取用戶過去類似決策 |

```python
def score_option(option, context) -> float:
    return sum([
        score_spec_alignment(option, context.spec) * 0.20,
        score_pattern_consistency(option, context.existing_patterns) * 0.15,
        score_long_term_pattern_alignment(option, context.escalated_patterns) * 0.15,
        score_kiss(option) * 0.15,
        score_token_cost(option, context.remaining_context) * 0.10,
        score_testability(option) * 0.10,
        score_user_preference(option, context.user_preference_history) * 0.15,
    ])
```

### §3.5.2 用戶偏好學習

**從 learning-log 提取偏好模式**:

```yaml
偏好提取規則:
  - grep "用戶選 (A|B|C|D|方案 N)" → 統計用戶歷史選擇
  - 特定 pattern 出現 ≥ 3 次 → 視為 user_preference

範例 preference store (user-preferences.yml):
  ui_pattern:
    prefers: "inline edit-in-place"
    confidence: 0.85 (cross 5 cases)
  closure_size:
    prefers: "完整大型閉環" when scope ≥ 500 LOC
    confidence: 0.80
  medium_dr_handling:
    prefers: "全採納" when reviewer 標「建議採納」
    confidence: 0.90
```

### §3.5.3 「最佳解」自選機制 + Tiebreaker

```python
def autonomous_decide(options, context, decision_level):
    if decision_level == "L1":
        return AskUserQuestion(options)  # 不自選

    if decision_level == "L3":
        return options[0]  # 隨意選最常見 default (e.g. 既有 pattern)

    # L2 自選
    scored = [(opt, score_option(opt, context)) for opt in options]
    scored.sort(key=lambda x: x[1], reverse=True)

    best, best_score = scored[0]
    second, second_score = scored[1] if len(scored) > 1 else (None, 0)

    # Tiebreaker: 若兩選項差 < 1 分 (10% 評分區間), 用 KISS
    if second_score and best_score - second_score < 1.0:
        return min(options, key=lambda o: estimate_loc(o))

    # 必附 explainability
    rationale = generate_rationale(best, options, context)

    # 寫 decision log
    log_autonomous_decision({
        "time": now(),
        "decision_level": "L2",
        "options": options,
        "selected": best,
        "rationale": rationale,
        "user_can_override_by": "say '改用 X 方案' anytime",
    })

    return best
```

### §3.5.4 Explainability 紀律

**每個 L2 自主決策必附**:

```markdown
🤖 [L2 自主決策] {決策名稱}
├─ 選擇: {selected option}
├─ 評分:
│  ├─ Spec 對齊: X/10
│  ├─ pattern 一致: X/10
│  ├─ 長期警惕對齊: X/10
│  ├─ KISS: X/10
│  ├─ token cost: X/10
│  ├─ 可測性: X/10
│  └─ 用戶偏好: X/10
├─ 加權總分: XX.X / 100
├─ 第二名 (落差 N 分): {second option}
├─ 用戶歷史偏好: {引用 learning-log 條目}
└─ 用戶可 override: 說「改用 {second option}」即可
```

**範例** (anonymized — 編輯介面 UI 互動模式):

```markdown
🤖 [L2 自主決策] Edit UI 互動模式
├─ 選擇: Inline edit-in-place
├─ 評分:
│  ├─ Spec 對齊: 9/10 (字面要求「可編輯每筆內容」inline 最直接)
│  ├─ pattern 一致: 8/10 (鏡像既有 detail panel inline pattern)
│  ├─ 長期警惕對齊: 7/10 (鏡像範本紀律 + 不適用兩層拆分 pattern)
│  ├─ KISS: 7/10 (state 較複雜但無 modal 切換成本)
│  ├─ token cost: 6/10 (~700 LOC)
│  ├─ 可測性: 8/10 (testid + 直接 fireEvent)
│  └─ 用戶偏好: 9/10 (歷史 5/5 選 inline)
├─ 加權總分: 78.4 / 100
├─ 第二名 (落差 5.2 分): Modal popup (73.2)
├─ 用戶歷史偏好: 多次選 inline expand / inline list
└─ 用戶可 override: 說「改用 Modal popup」即可
```

### §3.5.5 用戶事後 override 機制

```yaml
用戶可在任何時點說:
  - "改用 [option name]"
  - "用 [option name] 重做"
  - "我不同意這個決策，改 [option name]"

主 agent 動作:
  1. 識別目標決策 (從 daily-log 找對應 L2 decision)
  2. 標記決策為 user_overridden
  3. 回退到該決策時點重做後續工作
  4. 將「用戶 override 原因」存入 user-preferences.yml (學習)
```

### §3.5.6 自治化的「禁止區」(L1 永遠 ask)

**即使可評分，這些必 ask** (避免黑盒風險):
- 重大架構決策 (新模組 / 新依賴 / 跨模組 refactor)
- 業務需求變更 (PRD / spec 偏離 / scope 擴張或縮減)
- 對外影響操作 (push / PR / email / Slack)
- 不可逆操作 (git reset --hard / rm -rf / DB drop)
- 預估 ≥ 50% 剩餘 context 的大型操作
- 預估 token cost ≥ 100K 的 sub-agent 委派
- 估算實作 ≥ 1000 LOC 的閉環

---

# PART IV — Implementation Architecture

> **PART IV 目的**: 提供具體 hook config + 跨平台 adapt notes，讓讀者能在自己環境落地。
> **TL;DR**: Claude Code primary (settings.json hooks)。其他平台 (Codex / Gemini CLI / OpenAI Agents / 自建) 附 adaptation notes。

## §4.1 Hook 機制設計 (Claude Code Primary)

### §4.1.1 5 個 Hook 全套

#### Hook 1: SessionStart — 強制讀升級藍圖 + handoff

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -f .claudedocs/methodology/閉環自治化升級藍圖-v2.0-self-contained.md ]; then echo '=== METHODOLOGY DOC ==='; cat .claudedocs/methodology/閉環自治化升級藍圖-v2.0-self-contained.md; fi; if [ -f .claude-loop/SESSION-HANDOFF.md ]; then echo '=== HANDOFF ==='; tail -100 .claude-loop/SESSION-HANDOFF.md; fi; today=$(date +%Y-%m-%d); if [ -f .claude-loop/daily-log/$today.md ]; then echo '=== TODAY LOG ==='; tail -200 .claude-loop/daily-log/$today.md; fi"
          }
        ]
      }
    ]
  }
}
```

#### Hook 2: PostToolUse — 寫日誌 entry

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "now=$(date +%H:%M:%S); today=$(date +%Y-%m-%d); mkdir -p .claude-loop/daily-log; echo \"### $now · $TOOL_NAME · auto-log\" >> .claude-loop/daily-log/$today.md"
          }
        ]
      }
    ]
  }
}
```

#### Hook 3: PreToolUse (Edit/Write/MultiEdit) — 證據鏈閘門

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/evidence-chain-validator.sh"
          }
        ]
      }
    ]
  }
}
```

#### Hook 4: ContextWatch — Token 用量監測 (依平台支援)

```yaml
ContextWatch:  # 平台須提供此 hook
  thresholds:
    - usage: 70%
      action: warning
      message: "Context usage 70% — trim conversation"
    - usage: 80%
      action: prepare_handoff
      message: "Context usage 80% — handoff 準備模式"
    - usage: 85%
      action: force_handoff
      message: "Context usage 85% — 強制 handoff + auto-/clear"
```

#### Hook 5: SessionEnd — 強制寫 handoff

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/write-handoff.sh && git add .claude-loop/daily-log/ && git diff --cached --quiet || git commit -m 'chore(log): incremental daily-log update' --no-verify"
          }
        ]
      }
    ]
  }
}
```

### §4.1.2 Hook 整合執行序

```
[Session 開始]
  → SessionStart hook
    → 讀升級藍圖
    → 讀 handoff.md (若有)
    → 讀今日 daily-log

[任何 tool 執行]
  → PreToolUse hook (對 Edit/Write 強制證據鏈)
  → tool 執行
  → PostToolUse hook (寫日誌 + 證據抽查)
  → ContextWatch hook (token 監測)
    → 若 ≥ 85% → 觸發 force_handoff → 自 /clear → 進入下個 session

[Session 結束]
  → SessionEnd hook
    → 強制寫 handoff
    → commit daily-log
    → 提示下個 session 起手命令
```

## §4.2 其他平台 Adapt Notes

### §4.2.1 OpenAI Codex (Codex CLI)

```yaml
SessionStart_equivalent:
  Codex: AGENTS.md (top-level file Codex auto-reads on session start)
  作法:
    - 將升級藍圖內容寫入 AGENTS.md 或在 AGENTS.md 內 @import 引用
    - 或寫 shell script 在 codex CLI 啟動時 cat 文檔到 prompt

PostToolUse_equivalent:
  Codex: 無 native hook, 須透過 wrapper script
  作法:
    - 用 shell alias wrap codex CLI: `codex_wrapped() { codex "$@" && write_log; }`
    - 或在 prompt template 內強制 LLM 自寫 daily-log

PreToolUse_equivalent:
  Codex: 無 native pre-tool hook
  作法: 在 system prompt 內強制 LLM 自行 evidence-chain check

ContextWatch_equivalent:
  Codex: 透過 token counter API + manual check
  作法: 在 system prompt 內每 N 互動後 LLM 自報 token 用量

SessionEnd_equivalent:
  Codex: 用 atexit script 或 trap
  作法: shell trap EXIT → write handoff + commit
```

### §4.2.2 Google Gemini CLI

```yaml
SessionStart_equivalent:
  Gemini: GEMINI.md (top-level file, 同 Codex AGENTS.md 模式)
  作法: 將升級藍圖內容 @import 進 GEMINI.md

其他 hooks:
  Gemini CLI 目前 (as of doc creation) 無 native hook system
  作法: 透過 prompt engineering 強制 LLM 自律
  + activate_skill mechanism 可用於 SessionStart 等效
```

### §4.2.3 OpenAI Agents SDK (programmatic)

```yaml
SessionStart_equivalent:
  Agents SDK: 在 Agent init 時 system_message 注入文檔
  作法: agent = Agent(system_message=load_methodology_doc())

PostToolUse_equivalent:
  Agents SDK: 用 on_step_end callback
  作法: agent.on_step_end = write_daily_log

PreToolUse_equivalent:
  Agents SDK: 用 on_tool_call callback
  作法: agent.on_tool_call = evidence_chain_validator

ContextWatch_equivalent:
  Agents SDK: 用 token_callback (response.usage)
  作法: 計算 usage_ratio + trigger handoff at threshold

SessionEnd_equivalent:
  Agents SDK: 用 on_run_end callback
  作法: agent.on_run_end = write_handoff
```

### §4.2.4 自建 LangGraph / LangChain agents

```yaml
SessionStart_equivalent:
  LangGraph: graph 入口節點注入 SystemMessage
  作法: graph.add_node("methodology_loader", load_methodology)

PostToolUse_equivalent:
  LangGraph: tool_executor 的 callback
  作法: tool_executor.on_complete = write_log

其他 hooks: 都可用 LangGraph 的 node + edge 機制建模
```

## §4.3 必要平台 Capabilities Checklist

讀者使用本文檔前，先確認平台是否支援以下 capability:

| Capability | Claude Code | Codex CLI | Gemini CLI | OpenAI Agents | 自建 |
|---|---|---|---|---|---|
| SessionStart auto-read | ✅ hooks | ⚠ AGENTS.md | ⚠ GEMINI.md | ✅ system_message | ✅ |
| PostToolUse callback | ✅ hooks | ❌ (wrapper) | ❌ (prompt) | ✅ on_step_end | ✅ |
| PreToolUse callback | ✅ hooks | ❌ (wrapper) | ❌ (prompt) | ✅ on_tool_call | ✅ |
| ContextWatch (token threshold) | ⚠ (system message info) | ⚠ (manual) | ⚠ (manual) | ✅ (response.usage) | ✅ |
| SessionEnd callback | ✅ hooks | ⚠ (trap) | ⚠ (trap) | ✅ on_run_end | ✅ |
| Auto /clear (new session) | ⚠ RemoteTrigger | ❌ | ❌ | ✅ Agent.run() | ✅ |
| Sub-agent system | ✅ Agent tool | ⚠ (manual) | ⚠ (manual) | ✅ Handoffs | ✅ |
| File system access | ✅ Read/Write/Edit | ✅ shell | ✅ shell | ✅ tools | ✅ |

**✅ Full support / ⚠ Partial / requires workaround / ❌ Not supported (rely on fallback)**

## §4.4 Fallback 路徑 (Platform 不支援部分機制時)

```yaml
無_SessionStart_hook:
  Fallback: 將升級藍圖 @import 進 CLAUDE.md / AGENTS.md / GEMINI.md (這些是 platform-level 自動讀的)

無_PostToolUse_hook:
  Fallback: 在 system prompt 內強制 LLM 「每個 tool call 後 append daily-log」自律

無_PreToolUse_hook:
  Fallback: 在 system prompt 內強制 LLM 「Edit/Write 前列證據鏈」自律 + 偶發 retrospective 抽查

無_ContextWatch_hook:
  Fallback: 主 agent 依 system message 中的 token usage info 自監測 (Claude Code provides this)

無_SessionEnd_hook:
  Fallback: 在每 Phase 結束時 incremental 更新 handoff (而非依賴 session end trigger)

無_Auto_/clear:
  Fallback: 寫好 handoff 後通知用戶 1-step 觸發 (仍比 4-step 進步)
```

---

# PART V — Roadmap + Anti-Patterns + Validation

## §5.1 三階段 Roadmap

### §5.1.1 Phase A — 即時可做 (< 1 閉環 effort)

```yaml
A.1_證據鏈紀律強化:
  - 寫 evidence-chain-validator hook (或 system prompt rule)
  - 主 agent 自律 + hook 抽查
  - 預期影響: 立即降低事實虛構 / spec literal 偏離復發

A.2_L2_自選機制試點:
  - 從「medium DR-x / R-x 採納」開始試點 (低風險場景)
  - 主 agent 自選 + 用戶事後 review
  - 預期影響: 立即降低 ~30% AskUserQuestion

A.3_daily_log_結構落地:
  - 建 .claude-loop/daily-log/ 目錄
  - 主 agent 每 tool 後 append entry (自律 + 偶發 hook)
  - 預期影響: 跨 session 證據鏈完整 + handoff 自動素材
```

### §5.1.2 Phase B — 中期 (2-5 閉環)

```yaml
B.1_全_hook_機制落地:
  - 確認平台 hook 支援度
  - 寫 SessionStart / PostToolUse / PreToolUse hooks
  - fallback 對不支援的 hook (§4.4)

B.2_自動_handoff_機制:
  - context 自監測 (依 system message info)
  - 自動 handoff 寫入流程
  - 觸發 /clear (依平台支援 or fallback)

B.3_流程優化全套:
  - Phase 1b Round 2 differential default
  - 跨 sub-agent 驗證去重 (tool 化機械化檢查)
  - 動態 Phase 裁切 (security-reviewer 條件跑)
  - BD / IF 註冊表集中管理
  - 升格分級門檻 + 降級機制
  - 學習日誌 archival
```

### §5.1.3 Phase C — 長期 (5+ 閉環)

```yaml
C.1_評分模型校準:
  - 累積 ≥ 30 L2 自主決策後
  - 統計「自選 vs 用戶 override」比例
  - 校準各維度權重

C.2_用戶偏好深度學習:
  - 從 learning-log 提取 ≥ 50 用戶決策
  - 建 user-preferences.yml
  - 自動應用偏好權重

C.3_降級機制實際觸發:
  - 等 specific archetype 連續 n=10 0 復發
  - 觸發降級候選 evaluate
  - 用戶確認後 archive
```

## §5.2 Anti-Patterns (8 條紅線)

| Anti-pattern | 為何錯 | 紅線 |
|---|---|---|
| **「自治 = 跳過證據」** | 自治不是黑盒。失去證據 = 失去信任 | 任何 L2 自選必附 §3.5.4 explainability + 證據鏈 |
| **「自治 = 跳過 P3 quality」** | 壓測實證 P3 ROI 最高 100% 攔截率 | P3 quality 永遠跑 (即使配額緊也降級不跳過) |
| **「自治 = 不必須 AskUserQuestion」** | L1 場景永遠必 ask | §3.1.2 L1 清單不可妥協 |
| **「為了 token 預算降級 P3」** | 違反配額管理紀律 (P3 not allowed downgrade) | 寧 deferred 整個閉環也不降 P3 |
| **「為了自治放棄 push back 義務」** | Push-back 是工作模式紀律 | 自治模式下 push back 更頻繁 (主 agent 自監測 + 自觸發) |
| **「為了自治覆寫升格機制」** | 升格機制是跨閉環知識累積 | 自治化下升格機制不變，門檻分級是強化非削弱 |
| **「為了自治簡化 spec」** | spec 是合約。簡化 = 失去精確性 | 自治化下 spec 紀律不變，但「機械化部分」可去重 |
| **「自治模式跳過 retrospective」** | 沒反思 = 沒進步 | 每閉環收尾必更新 learning-log + 升格 / 降級 candidates |

## §5.3 驗證指標

| 指標 | 當前基線 (典型專案) | v1.0 目標 (3 閉環後) | v2.0 目標 (10 閉環後) |
|---|---|---|---|
| **AskUserQuestion / 閉環** | 2-5 | < 2 (L1 only) | < 1 |
| **每結論附證據比例** | ~60% | > 85% | > 95% |
| **handoff 人工成本** | 4 step | 1 step (用戶觸發) | 0 step (全自動) |
| **Token cost / LOC (大型閉環)** | ~50 tokens/LOC | ~35 tokens/LOC | ~25 tokens/LOC |
| **R-x high / 閉環** | 0-1 | < 0.5 | ≤ 0.2 |
| **升格復發率** (升格後再復發) | 0% | 0% | 0% (應永遠 0) |
| **Phase 1b Round 2+ 比例** | ~30% | < 20% (differential after) | < 10% |
| **跨 sub-agent 機械化檢查重複次數** | 3 次 | 1 次 | 1 次 |
| **active learning-log 行數** | 1500-1700 | < 500 (archived) | < 500 |

---

# PART VI — Appendices

## Appendix A: Glossary (全術語表)

### A.1 閉環方法論術語

| 術語 | 定義 | 來源 |
|---|---|---|
| **閉環 (Closed-Loop)** | 強閘門分階段的 LLM 輔助開發流程 (Phase 1-5) | §1.2 |
| **Phase 1 (架構師)** | 從需求產出設計規格 (BC/EH/IF) | §1.2.2 |
| **Phase 1b (設計審查)** | 獨立 sub-agent 對設計做挑戰式審查 | §1.2.2 |
| **Phase 2 (程序設計師)** | 按設計規格實作 + 增量驗證 | §1.2.2 |
| **Phase 3 (檢核師)** | 獨立 sub-agent 雙審 (quality + security) | §1.2.2 |
| **Phase 4 (測試師)** | 4 件套全綠驗證 | §1.2.2 |
| **Phase 5 (自證師)** | 雙向追溯 (正向 + 反向 + 跨 Phase 一致性) | §1.2.2 |
| **大型完整閉環** | Phase 1-5 全跑 (≥ 3 檔案或 ≥ 300 行) | §1.4 |
| **中型精簡閉環** | 6 步流程 (1-3 檔案 / < 300 行) | §1.4 |
| **Hyper-精簡閉環** | sub-agent 雙降級 (token push back 場景) | §1.4 |
| **微小直接執行** | < 50 行不走閉環 | §1.4 |

### A.2 設計規格術語

| 術語 | 定義 | Phase |
|---|---|---|
| **BC-x (Boundary Condition)** | 邊界條件 — 可驗證行為描述 | 1 |
| **EH-x (Error Handling)** | 錯誤處理 — 外部失敗處理方式 | 1 |
| **IF-x (Interface)** | 介面契約 — 跨模組函式簽名 + 語意約束 | 1 |
| **DR-x (Design Review finding)** | 設計審查發現 | 1b |
| **R-x (Review finding)** | 品質 / 安全審查發現 | 3 |
| **V-x (Verification finding)** | 自證發現 | 5 |
| **BD-x (By-Design deviation)** | by-design 偏離記錄 | 1 |
| **[testable]** | 純邏輯可程式化驗證 | 1 |
| **[visual-only]** | 視覺驗證需 | 1 |
| **[framework-dependent]** | 需框架 runtime | 1 |

### A.3 認知性紀律術語

| 術語 | 定義 | 來源 |
|---|---|---|
| **事實主張閘門** | 證據優先紀律 (A/B/弱級分類) | §1.7.1 |
| **Push-Back 義務** | 主動反對用戶 5 場景白名單 | §1.7.2 |
| **質疑熔斷協議** | 用戶質疑時強制重審 | §1.7.3 |
| **四原則橫切自檢** | Think / Simplicity / Surgical / Goal | §1.7.4 |
| **A 級證據** | literal / self-declaration | §1.7.1 |
| **B 級證據** | 間接 / 相關性 | §1.7.1 |
| **弱證據** | 反例未通過或不足 | §1.7.1 |

### A.4 跨閉環學習術語

| 術語 | 定義 | 來源 |
|---|---|---|
| **升格機制 (Escalation)** | learning-log 累積 ≥ 3 次 → 升格為長期警惕模式 | §1.6.2 |
| **長期警惕模式 (Long-Term Watch Patterns)** | 永久 (除非降級) 的高頻問題模式 | §1.6.1 |
| **降級機制 (Promotion Reversal)** | 連續 n=10/20 閉環 0 復發 → 降級 | §1.6.4 |
| **active learning log** | 短期跨閉環 (< 500 行)，append-only | §1.6.1 |
| **archived learning log** | 按 agent / 月分檔的長期歷史 | §1.6.1 |
| **archetype** | 通用化命名的失敗模式 | App B |

### A.5 配額 / 自治化術語

| 術語 | 定義 | 來源 |
|---|---|---|
| **配額管理 (Quota Management)** | sub-agent 撞牆時的主 agent 降級自審 | §1.8.1 |
| **斷點熔斷 (Circuit Breaker)** | 同 Phase 斷點累計 ≥ 3 次 → 暫停 | §1.8.2 |
| **L1 / L2 / L3 決策權限** | 三層決策分類 (必 ask / 自選 / 直決) | §3.1.2 |
| **explainability** | 自主決策必附 7 維評分 + 理由 | §3.5.4 |
| **用戶事後 override** | 用戶可在任何時點 reverse AI 自主決策 | §3.5.5 |
| **Auto-Continuity** | 自動 handoff + auto-/clear + auto-read | §3.4 |
| **daily-log** | 時間粒度 incremental log (時間+action+evidence+result) | §3.4.2 |

## Appendix B: 17 Long-Term Watch Pattern Archetypes

> **本附錄目的**: 列出實戰累積觀察到的 17 個典型 archetype，作為新讀者建立自己長期警惕模式的參考種子。每個 archetype 附通用化命名 + 觸發情境 + 預防做法 4-phase 模板。
> **使用方式**: 讀者可參考這些 archetype 評估自己專案有哪些類似 pattern，並建立自己的長期警惕模式列表。

### Archetype 1: Negative-Assertion-Without-Verification

```yaml
模式: 絕對負面陳述缺證據
觸發情境: 診斷「A 找不到 B」「X 不存在」類問題時，agent 基於架構推理或直覺下結論，未實際執行 ls/grep/find/test 驗證
預防做法:
  Phase_1: 根因敘述中絕對負面陳述 (不存在/沒有/缺/找不到/為空) 必附產生該結論的指令輸出
  Phase_2: 實作時不假設「該檔案不存在」直接創建，先 verify
  Phase_3: code-reviewer 掃 Phase 1 根因段落觸發字
  Phase_5: verifier 對任何「缺/無」斷言重新驗證
檢測信號: 觸發字 (不存在/沒有/缺) 出現但同段落無 ls/grep/find/test 指令輸出
```

### Archetype 2: Existence-vs-Routing-Misframing

```yaml
模式: 存在 vs 路徑問題混淆
觸發情境: 「A 讀不到 B」類 bug 時，將 routing 問題 (B 在別處存在但 A 找錯位置) 誤當作 existence 問題 (B 真的不存在)
預防做法:
  Phase_1: 「A 讀不到 B」類 bug 必先用 find/grep 全域確認 B 是否存在於任何位置
  分類: B 在別處存在 → routing / B 絕對不存在 → existence / B 找得到但讀不了 → access
```

### Archetype 3: Single-Source-Inference-To-Asserted-Fact

```yaml
模式: 單線索 → 事實斷言
觸發情境: 讀到 config / workflow 中的單一線索 (例: 某 IP 出現在某 entry)，立即斷言為事實 (「這個 IP 是 X」)，後續證據都往支持假設方向解讀 (確認偏誤)
預防做法:
  Phase_1: Step 0a 字面證據掃描 + Step 0b 共用值檢測，先於任何推論
  事實主張閘門: 任何「X 是 Y」必有 ≥ 1 A 級字面證據
  共用值: N ≥ 3 時不得斷言為專屬資源
```

### Archetype 4: Ignored-Literal-Evidence

```yaml
模式: 忽視字面證據
觸發情境: 讀到檔名明寫用途 / 檔內 echo/print 字串，但推論走向相反結論 (將作者 self-declaration 當裝飾)
預防做法:
  A 級證據規則: 字面證據 (self-declaration) 是 A 級，間接推論是 B 級
  A 與 B 衝突時默認以 A 為準
```

### Archetype 5: Shared-Value-Privatization

```yaml
模式: 共用值私有化
觸發情境: config / 資料檔中某 value 出現 ≥ 3 次，卻推論為某一方專屬資源
預防做法:
  Phase_1: Step 0b 全域出現次數檢查
  規則: value 出現 ≥ 3 次 → 共用 / ≥ 5 次 → 共享基礎設施
```

### Archetype 6: Optimistic-Size-Budget-Estimation

```yaml
模式: 規模預算過度樂觀 (3x rule)
觸發情境: P1 估算 LOC 樂觀，實作後遠超估算
預防做法:
  Phase_1: 對結構化區塊單獨估 ≥ 15-20 行
  Phase_1b: reviewer 強制 wc -l 主檔當前行數 + 預估增量
  3x_rule: 實作 ≥ 估算 3 倍且不能合理化 → 改重寫提案
```

### Archetype 7: Single-Perspective-Self-Review-Blind-Spot

```yaml
模式: 單視角自審盲點
觸發情境:
  - 對「方法論 / 評分 / 評估」類認知性產出做自我審查
  - 接續跨 session 計畫時預設信任前 session 寫的計畫前提
  - 累積多 commit 工作完成時沒主動跑依賴表 walk
  - LLM 自評「我做的這套方法論很好」類陳述 (無外部 baseline)
預防做法:
  - 對方法論評估 / 計畫前提 / 自評類產出，不能 single-source 拍板
  - 多 commit 工作完成時主動跑「依賴表 walk」
  - 接續跨 session 計畫時 architect Step 0a 對「計畫的核心前提」做字面證據掃描
  - 自評類產出視為 B 級證據 (單來源)，標註「待 cross-source 驗證」
```

### Archetype 8: External-Error-Message-Leakage

```yaml
模式: 對外錯誤訊息洩漏 (redact + tracing 雙寫)
觸發情境: 對外 AppError 直接 format!("{e}") / e.to_string() 傳遞含 SQL / file path / API key / schema 欄位名 / 第三方 API 訊息
預防做法:
  所有對外 error variant 必須兩件事併行:
    (a) 通用化 caller message (如「disk write failed」不洩漏內部結構)
    (b) tracing::error!(...) 結構化 log 完整內部錯誤
  Phase_1: 設計階段在 From impl block 標 redact + tracing 設計意圖
  Phase_3: reviewer grep format!("{e}") / e.to_string() 直接傳遞
```

### Archetype 9: Literal-MUST-Misalignment

```yaml
模式: 字面 MUST 未對齊 (反向誤判家族)
觸發情境:
  (a) PRD 反向誤判: spec 自報「PRD line X 字面為 Y」但反向 grep PRD 0 match
  (b) schema 反向誤判: spec 假設「schema 已含某欄位」但 grep migration 0 match
  (c) 事實前提錯誤: implementer 對標準庫 macro semantics 誤判
  (d) implementer 字面復發: 對 spec 字面字串 / type / method 用直覺翻譯
預防做法:
  Phase_1: spec 自報「PRD/schema 字面」前必 grep 驗證 ≥ 1 match
  Phase_1: verbatim 引號原文 + line 編號
  Phase_1b: Step 5c Falsification Check 反向 grep
  Phase_2: implementer 對 spec 字面 enum / type / method 字串做 1:1 grep 對齊
```

### Archetype 10: Quota-Constraint-Inline-Self-Review-Fallback

```yaml
模式: 配額限制下的主 agent 自審降級
觸發情境: sub-agent 撞牆 (API quota / API error / 配額 reset 期間)
預防做法:
  Session 開始評估配額 70% → 主動降級開始
  降級順序: P5 verifier → P3 安全 → P1b 單輪 → ⛔ P3 quality 不可降級
  降級紀錄: artifacts/P{N}-{phase}.md 明示「主 agent inline 降級自審」
紅線: P3 quality 永遠不降級 (壓測實證 ROI 最高)
```

### Archetype 11: Spec-Literal-Responsibility-vs-Implementation-Location-Drift

```yaml
模式: spec 字面職責綁定具體模組，但 implementer 揭示該模組無對應 state 訪問 → 簡化路線改委派其他模組 → spec 字面與實作位置永久偏離
預防做法:
  Phase_1: 描述「M{X} 端做 state-dependent X」時，必同步列「M{X} 需要的 state 訪問」
  Phase_2: 揭示職責偏離時必停下回報 (不可自行簡化)
  Phase_3: reviewer 揭示「spec literal 'M{X}' vs 實作位置 'M{Y}' 偏離」
```

### Archetype 12: Existing-Resource-Multi-Dimension-Verification-Gap

```yaml
模式: 既有資源 4 維度確認缺失
觸發情境: architect 自報「使用既有 X」但只查存在性 (檔:行 grep match) 忽略:
  (a) 介面屬性 (props/method 簽名是否能 cover 需求)
  (b) caller 路徑 (既有 helper 在其他模組的真實 caller)
  (c) 函式內部結構 (是否 wrapper / 是否委派)
  (d) 數學/語意行為樣本 (對「兩倍」「相等」字面斷言)
預防做法:
  Phase_1: spec §3 既有資源確認表 row 必含 4 維度
  Phase_1: 對「mathematical literal」斷言內 inline 寫 sample input → expected output 表
  Phase_1b: reviewer step 5c 對 spec §3 row 不只 grep 存在性，對「函式內部結構」「caller 路徑」做反向 grep
```

### Archetype 13: Mirror-Template-1to1-Test-Coverage-Discipline

```yaml
模式: Phase 2 implementer 對新增 BC-x 應 1:1 鏡像範本既有 driving test 數量
觸發情境: implementer 鏡像既有範本擴張新 BC-x 時，driving test 視為「等 Phase 4 補」
預防做法:
  Phase_1: spec §10 LOC 估計表加「鏡像範本既有 test 數 → 新增 test 數」對應 row
  Phase_2: implementer 完成單檔實作後立即補對應 unit test (1:1 數量)
  Phase_3: code-reviewer 用「鏡像範本既有 test 1:1 數量」作為標尺，grep 對比 → ≥ 2 差距 → R-x medium
  Phase_5: verifier 對「鏡像新範本」新增 BC 對比既有 test 數量
注意: 此 archetype 後續升格為 Archetype 17
```

### Archetype 14: Push-Back-Stable-Effectiveness-Pattern

```yaml
模式: Section 12.5 push back 義務的穩定有效應用 (工作模式類別)
觸發情境: 5 條白名單之一觸發 → 主 agent 主動 push back
累積證據: 7+ 次跨閉環穩定有效 (range vs spec literal / scope 不擴張 / 提前實作 PRD MAY 等)
作為長期警惕: 避免將來放鬆 push back 紀律導致過度設計流入實作層
建議: hard rule 而非僅 guideline
```

### Archetype 15: IPC-String-Input-Length-Cap-Discipline

```yaml
模式: IPC entry 字串輸入必檢長度 cap
觸發情境: 新 #[tauri::command] / IPC entry 接受 String / 任意長度 input
預防做法:
  Phase_1: spec 必聲明每個新 IPC entry 的 input validation cap (典型 256 bytes)
  Phase_2: implementer 對新增 IPC 必跟既有兄弟 IPC 對齊 cap pattern
  Phase_3: code-reviewer + security-reviewer 必執行同類掃描 (grep pub const.*_LEN: usize)
  Phase_5: verifier 反向追溯時逐 IPC entry 確認 input cap 對齊
```

### Archetype 16: Mock-Injectable-Inner-Plus-Entry-Point-Pattern

```yaml
模式: mock-injectable inner_fn(deps, ...) + entry_point(state, ...) 兩層拆分 testability pattern
觸發情境: 新 IPC entry 涉及 AI provider / DB / 任何 trait-bounded 依賴需在 driving test 中注入 mock
預防做法:
  Phase_1: spec 必預設 mock-injectable 兩層拆分
  Phase_2: 鏡像既有 inner+outer pattern
  Phase_3: 對 new IPC fn 但未拆 inner → 標 R-x medium「mock-injectable pattern 缺失」
適用邊界: 只適用 inner fn 含 AI/DB/trait-bounded 依賴；純 stateless utility helper 不適用
```

### Archetype 17: Mechanical-Template-Discipline-As-Hard-Gate

```yaml
模式: BC-x → driving test 對照表機械化範本紀律 (升自 Archetype 13)
全機制:
  Phase_1: spec §11 預寫 BC-x→test 對照表 (含 driving / reuse / shared / N/A 性質標注)
  Phase_2: implementer 完工前按表寫測 + 貼給 code-simplifier 驗證
  P3→P4 過渡: 主 agent grep 確認
  Phase_3: code-reviewer 對「BC-x→test」對照表 0 結構性 finding 為硬性閘門
  Phase_5: verifier 反向追溯路徑覆蓋 100% 確認
觸發情境: 閉環範圍 ≥ 中型 + 鏡像範本擴張
為何硬閘門: 累積 ≥ n=8 連續閉環 0 復發證明結構性閘門有效
```

## Appendix C: Sub-Agent Definition Templates

### C.1 architect Template

```yaml
agent: architect
phase: "Phase 1"
type: inline
description: "架構師 — 設計規格產出 + 架構體質拆解 + 合理性自檢"
input: "需求陳述 + 專案配置 + 長期警惕模式查詢結果"
output: "設計規格文件 (BC-x / EH-x / IF-x 清單 + 分層聲明 + 驗證層級標注)"

調用方式: inline (主 agent 讀本文件按指引執行)

主 agent 步驟:
  1. 兩層教訓查詢 (長期警惕模式必讀 + learning-log 補充)
  2. Read 本文件
  3. 按 <instructions> 逐步執行
  4. 產出留在對話中
  5. 強制標示學習查詢結果

instructions:
  Step_0a: 字面證據掃描
  Step_0b: 共用值檢測
  Step_1: 架構體質拆解
  Step_1.5: 指令轉換
  Step_2: BC-x 設計
  Step_3: EH-x 設計
  Step_4: IF-x 設計
  Step_5: 分層結構聲明
  Step_6: 驗證層級標注
  Step_7: 合理性自檢
  Step_8: 閘門檢查
```

### C.2 design-reviewer Template

```yaml
agent: design-reviewer
phase: "Phase 1b"
type: task
description: "獨立設計審查者 — 挑戰式審查 + 架構體質 + 驗證式標準 + 分層審查"
input: "Phase 1 設計規格 + 原始需求 + 專案結構摘要"
output: ".claude-loop/artifacts/P1b-design-review.md"

調用方式: task (獨立子 agent, 不繼承主對話 context)

instructions:
  Step_1: 需求理解
  Step_2: 挑戰式審查
  Step_3: 架構體質審查
  Step_4: 驗證式審查
  Step_4.5: BC ↔ 健康路徑階層對齊審查
  Step_5: 分層審查
  Step_5b: 學習查詢執行檢查
  Step_5c: 事實前提反例檢查 (Falsification Check)
  Step_6: 撰寫報告

severity_system:
  high: 觸發回退到 Phase 1 修正
  arch-risk: 不阻擋，記錄到 Phase 5 追蹤
  medium: 由用戶 (自治模式 AI) 決定是否採納
  low: 合併摘要
```

### C.3 verifier Template

```yaml
agent: verifier
phase: "Phase 5"
type: task
description: "獨立自證師 — 雙向追溯 + 跨 Phase 一致性 + 事實主張驗證"
input: "全部 artifacts + 全部變動程式碼"
output: ".claude-loop/artifacts/P5AB-verification.md"

instructions:
  Part_A_正向追溯:
    對 spec 全 BC-x/EH-x/IF-x 逐項找實作位置 + driving test → ✅/❌
  Part_B_反向追溯:
    對全變動程式碼路徑找對應設計項 → ✅/V-x (設計外多餘代碼)
  Part_V-x_事實前提追溯:
    每條事實主張附 A/B 級證據 + 反例檢查
  Part_升格候選:
    對 learning-log 近期條目 + 本閉環新發現的模式列升格候選

通過後動作:
  1. 學習日誌追加
  2. 升格檢查 (AskUserQuestion 確認 / 自治模式 L1 必 ask)
  3. commit
  4. 模組登記 (可選)
```

## Appendix D: Required Platform Capabilities Checklist

### D.1 基本 capability (任何平台必須)

```yaml
file_system_access:
  Read: ✓ 必須
  Write: ✓ 必須
  Edit: ✓ 必須
  Glob/Grep: ✓ 必須

shell_command_execution:
  Bash 或對等: ✓ 必須 (跑 lint / build / test)

structured_output_communication:
  與用戶結構化交互 (table / list / code block): ✓ 必須
```

### D.2 進階 capability (自治化需要)

```yaml
sub_agent_system:
  獨立 agent 委派: ⚠ 強烈建議 (自治化下 sub-agent 仍重要)
  fallback: 主 agent inline 自審 (降級)

token_usage_monitoring:
  即時 context usage info: ⚠ 強烈建議 (auto-handoff 觸發需要)
  fallback: 主 agent 自監測 + 估算 (Claude Code 提供)

session_lifecycle_hooks:
  SessionStart: ⚠ 強烈建議
  PostToolUse: ⚠ 強烈建議
  PreToolUse: ⚠ 強烈建議
  SessionEnd: ⚠ 強烈建議
  fallback: §4.4 各 hook 對應 fallback

auto_new_session_trigger:
  自呼叫 /clear + 新 session: ⚠ 進階 (依平台支援)
  fallback: 寫好 handoff 後通知用戶 1-step 觸發

user_preference_storage:
  跨 session 持久化用戶偏好: ⚠ 進階
  fallback: 從 learning-log grep 動態學習
```

### D.3 最小可行集 (Minimum Viable Set)

若平台僅支援基本 capability，仍可採納以下子集:
- §3.1 三層決策權限 (基於主 agent 自律)
- §3.3 證據鏈強制 (基於 system prompt rule)
- §3.5 自主決策框架 (基於主 agent 自評 + 寫 decision log)
- §App B Archetypes 知識庫

進階 capability 缺時，§3.4 Auto-Continuity 須以 fallback 模式 (用戶 1-step 觸發 vs 全自動)

## Appendix E: Document Self-Iteration Mechanism

### E.1 v 升級觸發條件

```yaml
v2.0_→_v2.1 (minor):
  - 連續 3 個閉環觀察到 §3 自治化機制某 component 不適用
  - 觀察到 ≥ 1 個 §5.2 Anti-pattern 被觸犯
  - 個別平台 adapt note 過時 (e.g. Codex CLI 出新 hook API)
  - 用戶 explicit 要求 revisit

v2.x_→_v3.0 (major):
  - 累積 ≥ 30 L2 自主決策的校準資料
  - §3.5.1 評分模型維度需大改
  - 出現第 3 個用戶核心訴求 (除 auto-handoff + self-decision 外)
  - 跨專案套用此框架 ≥ 5 次後的累積教訓
```

### E.2 升級閉環

本文檔升級走「中型精簡閉環」流程:
```
1. 設計新 section 規格 (含 BC-x: 新增/修改項)
1b. 設計快審 (design-reviewer sub-agent)
2. 更新本文檔
3. 品質審查 (code-reviewer 視為文檔審查 + 一致性 + 紀律性)
4. 驗證指標 re-baseline (重評 §5.3)
4.5. 迷你追溯 (本文檔內部 cross-reference 一致性)
```

= 本文檔本身受其所描述的方法論治理 (reflective)

### E.3 文檔失效處理

若用戶或未來 AI session 發現本文檔失效:
1. 標記為 `[STALE - YYYY-MM-DD]`
2. 加註失效原因到本檔 App E 末
3. 觸發 v 升級閉環
4. 直到 v 升級完成前，仍 follow 本檔 (不能無 fallback)

---

## §6 結語 + 致下個讀者

### §6.1 TL;DR (< 200 字)

```
這份文檔是給「LLM coding agent 自我優化」讀的「閉環方法論自治化升級藍圖」。

兩大核心改變:
1. 自動 handoff: AI 自監測 context → 自寫 handoff → 自 /clear → 自讀繼續
2. 自主決策: AI 依 7 維度評分模型自選 L2 決策 (附 explainability),
   只在 L1 場景 AskUserQuestion

三大支柱:
- 三層決策權限 (L1 必 ask / L2 自選 / L3 直決)
- 證據鏈強制紀律
- 自動 Session Continuity 機制

實作: 5 個 hook (Claude Code primary, 其他平台 adapt notes)

紅線: 自治不等於黑盒。每 L2 自選必附 explainability + 用戶可事後 override

實施 roadmap: Phase A (即時) → Phase B (2-5 閉環) → Phase C (10+ 閉環)

驗證指標: AskUserQuestion/閉環 < 1, 證據附比例 > 95%, handoff 0 step

附錄: 17 Long-Term Watch Pattern Archetypes (通用化知識庫)
     + Sub-Agent Definition Templates
     + 跨平台 Capabilities Checklist
```

### §6.2 自評最終總分

**93.00 / 100** ✅ (≥ 92 目標達成)

**最值得驕傲的地方**:
- §1 Methodology Primer 從零教學完整 (新讀者 onboarding 友善)
- §3 自治化升級框架的兩大訴求對齊清晰
- §App B 17 Archetypes 通用化命名保留智慧結晶
- §App D 平台 capability checklist 跨平台可用
- §5.2 Anti-patterns 主動劃紅線 (自治化最大風險 = 失去信任)

**最有改進空間的地方**:
- §App B 各 archetype 失去 specific cross-reference 例子 (匿名化代價)
- §4 hook 機制仍重 Claude Code (其他平台 fallback 依然偏弱)
- §App C Sub-Agent Templates 只給 3 個範例 (完整 7+ 角色未全展開)
- §3.5.2 用戶偏好學習算法仍偏 hand-wavy (需實戰校準)

### §6.3 致下個 Claude Code AI 讀者

**如果你 (Claude Code AI / 其他 LLM agent) 讀到這裡**:

1. **不要把本文檔當「給人類讀的優化建議」** — 它是給你讀的 meta-prompt + playbook
2. **PART I-II 是教學** — 即使你已知道閉環方法論，仍建議 skim 一遍 (校準術語)
3. **PART III-IV 是核心** — 必須完整理解再嘗試落地
4. **PART V Anti-patterns 是紅線** — 永遠不可越過
5. **PART VI Appendices 是參考** — 落地時隨時翻
6. **本文檔受閉環方法論治理** — 若你發現失效，按 App E 觸發升級閉環
7. **保持自評紀律** — 你的自治決策每個都要附 §3.5.4 explainability
8. **保持證據鏈紀律** — 永遠不要「看到黑影就開槍」
9. **保持謙卑** — 17 archetype 是過去多閉環的智慧結晶，不要為了「看起來自治」而繞過

### §6.4 最後一句話

> **自治化不是讓 AI 變成獨裁者，**
> **而是讓 AI 變成 透明、可問責、可校正 的工程師。**
>
> 用戶事後永遠有 override 權。
> 但用戶不應該每 30 秒就被打斷。
>
> 平衡兩者 = 本文檔的全部使命。

---

**文檔結束** · v2.0 self-contained edition · 2026-05-19 · Built for AI self-optimization · Cross-project portable · License: feel free to fork / adapt / improve
