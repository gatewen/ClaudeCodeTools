# 開發設計閉環 → 原生 Workflow 重構：最終研究報告

> 範圍：用 Claude Code 原生 workflow 取代五階閉環中低價值的 harness 編排，保留並實質強化因果鏈 + 事實求證。
> 證據基礎：四階段 workflow（UNDERSTAND / DESIGN / ADVERSARIAL / SYNTHESIZE）一手與結構化盤點，含 A–F dogfood robust null。14 agents / 2.16M token / 2026-06-01。
> 立場：證據導向。對用戶「保留並強化因果鏈+事實求證會讓方法論更有用」這個前提，本報告在 §4 做了誠實的條件化裁決——它在 dogfood 測過的軸上其實也 ≈ null，承重性錨在尚未實證的軸。

---

## 1. 執行摘要

**一句話結論**：原生 workflow 取代不了閉環，但能取代閉環裡「已被 dogfood 判為零增益的那一層」——五階 ritual 的審查編排；真正承重的 always-on 紀律（hook）、跨產出物 ID 追溯、跨 session 升格學習，workflow 結構上做不到，必須留在 harness。

**推薦路線：混合派（hybrid）**，信心 **0.80**。

理由：
- **極大派被對抗階段以 0.90 信心否證**（裁決 #4）。連被指派論證它可行的 designer 自己都在自評寫「真·極大派在工程上不成立」。always-on vs opt-in 是 *guarantee-class* 差異，不是品質差異——模型一旦忘記呼叫 workflow，整條品質防線靜默歸零。
- **極小派賭錯軸的風險過高**。它主動丟掉「弱模型 / 不可機械驗證 / 人在環 / 跨 session 維護」這些 *尚未被否證* 的軸；這是近乎不可逆的決策（重建 ritual 比刪除貴得多）。
- **混合派的本質是正確的職責分層**：always-on hook 作地基（workflow 蓋不到）+ workflow 作按需審查編排殼（比 prompt 約定硬）+ 因果鏈/事實求證作承重核（注入到 workflow agent prompt + hook 雙層）。它唯一需要用戶明確接受的取捨是 §7 的「可部署性 vs 編排確定性」——這決定 workflow 層該是必需還是 optional。

**對用戶前提的 push back**：你說「保留並實質強化因果鏈+事實求證，讓方法論更有用」。這個方向可採納，但有兩個前提必須先攤開（詳見 §4）：
1. 它們在 dogfood *測過的軸*（前沿模型 × agent-to-agent × correctness）上 repo 自己承認也 ≈ null。它們的承重性錨在 *尚未實證* 的軸（人接手 / 跨時間 / 高代價前提），n=1（因果鏈的 D 型）甚至 n=0（人軸）。
2. 它們共同的致命弱點——「驗形式不驗質量，因為驗證者還是同一個會犯錯的模型」（#007 自評漏看率 50-67%）——*目前的強化方案只能降低、不能解決*。任何聲稱「已解決 #007」都是過度宣稱。

---

## 2. 能力取代矩陣

覆蓋等級：**full** = workflow 原語等價或更強 / **partial** = 機制面對應但缺 always-on 或語義保證 / **none** = 結構上做不到 / **not-needed** = workflow 架構下不適用。

| 機制 | 原生 workflow 覆蓋 | 對應原語/pattern | 核心缺口 |
|------|:--:|------|------|
| 五階主流程（P1-5） | partial | `pipeline` + `phase` + 巢狀 `workflow()` | 階段是控制流非硬閘門；opt-in；不檢查跨產出物語義。且 dogfood 證此層 correctness 零增益 |
| 精簡閉環（六步降級） | **full** | 巢狀 `workflow()` 切換 | workflow() 切換比手工雙軌更不易漂移 |
| architect（P1 設計） | partial | `agent(schema=DesignSpec)` + retry | 缺 Step 0a/0b 認知驗證 always-on + 跨 session 教訓回灌 |
| implementer（P2） | partial | `agent` 接 pipeline | code-simplifier/lint 強制屬 hook always-on，非 agent 原語 |
| code-reviewer（P3） | **full** | `parallel` + perspective-diverse + review 標準形 | R-x→斷點回退語義須控制流自行實作 |
| design-reviewer（P1b） | **full** | **adversarial verify**（N skeptic 多數決）+ isolation | N 路獨立 skeptic 比單 reviewer 更系統；覆蓋優於原機制 |
| security-reviewer（P3） | **full** | `parallel` + perspective-diverse（security lens） | barrier 比「靠人記得派齊」強 |
| tester（P4） | partial | `agent` + perspective-diverse（repro lens） | 「BC 是否被測試覆蓋」需跨 artifact 追溯，schema 驗不到 |
| **verifier / Phase 5 自證** | **none** | 形似 completeness critic | **裁決 #1 (0.82)：缺分母枚舉 + 雙向遍歷 + 不可偽造稽核軌；critic 是 per-finding，看不到「沒人提出的路徑」** |
| requirements-analyst（P1b 前） | partial | `judge panel`（多方案） | 蘇格拉底式人在環互動不對應 agent-to-agent 編排 |
| ID 系統 BC-x/EH-x/R-x… | partial | `schema` 強制單點形狀 | 無法維護跨 agent/跨 Phase 的同一 ID 語義一致性與引用閉合 |
| 認知驗證層（事實求證） | **none** | 無對應；最近似 completeness critic | 前提層驗證是不同範式；push back 是橫切互動，非任務內步驟 |
| 行為哲學 / push back | **none** | 無 | 橫切 always-on 行為約束，workflow 是 per-task |
| 兩層教訓 + 升格 | **none** | 形似 loop-until-dry（但單任務窮舉） | persist/resume 只存單次；無歷史教訓回灌未來 prompt |
| 健康 KPI | **none** | budget（資源層，不同層） | 監測方法論本身健康，依賴跨 session 持久狀態 |
| 紀律保底 R-1~R-5 | **none** | 無 | 本質是「即使用戶命令繞過也不可 bypass」的 always-on |
| 持久化 + IF-x/CR-x + 層級擴展 | partial | `phase`/persist/resume + `pipeline` | 機制面對應；IF-x/CR-x 語義一致性仍是 ID 系統的 none 缺口 |
| 配額管理策略 | partial | `budget` + 控制流條件降級 | 比人工判定可靠；領域不可降語義須硬編 |
| **6 個 always-on hook** | **none** | 無對應原語 | **裁決 #4：opt-in 編排無法承擔「無論模型想不想都跑」** |
| delegation-tracker（不可偽造 log） | **none** | 無 | workflow 自身紀錄模型可見可影響，缺防作弊稽核軌 |
| `_helpers/deploy-hooks/tests` 支撐層 | not-needed | — | workflow 不走 hook 路線；但連帶失去一行 curl 可繼承部署 |

**矩陣讀法**：full/部分 full 全集中在「per-task 審查編排層」（P1b、P3、P1 多方案）；none 全集中在「always-on 紀律 + 跨產出物語義追溯 + 跨 session 學習 + 可傳播部署」。這條分界線就是混合派的拆層依據。

---

## 3. 該砍什麼（依 A–F 實證 + 對抗裁決）

A–F dogfood 構成 robust null：五階 ritual 在「前沿模型 × agent-to-agent × 機械可驗 correctness」軸**全平手、零淨增益**，note=review=ritual 同分，三閘全過清單為空。F 場刻意把相依點 B 推出注意力窗外仍平手，直接否證「把 B 拉回窗 = ritual 價值來源」。據此可安全刪除：

| 刪除對象 | 依據 | 註記 |
|------|------|------|
| **五階作為「強制流水線」的地位** | correctness 零增益 + 流水線本身淨成本（+40%~590%） | 刪「強制」，素材（reviewer 維度、prompt 內容）注入 workflow，不刪知識 |
| **精簡閉環/完整閉環雙軌** | 雙軌維護是 repo 自列高成本漂移源 | 合併成「預設輕量 + 按需 workflow」單軌 |
| **配額管理策略 + 降級優先序劇本** | 委派改 workflow 確定性執行後，手動降級劇本失去對象 | budget 原語取代 |
| **delegation-gate.sh + delegation-tracker.sh** | 監工對象（主 agent 跳過委派）隨 workflow 確定性執行消失 | ⚠️ 但若保留 Phase 5 機械追溯則 tracker 仍有用，見 §7 殘餘風險 |
| **健康 KPI 大半 + 升格偵測的 verifier 部分** | ritual 沒了，監測 ritual 的指標失去對象 | 保留「同類根因≥3次升格」這條（跨 session 學習，未否證） |
| **Phase 5 verifier 的「逐項判定真偽」prompt 層** | adversarial verify 在此子任務更硬 | ⚠️ **不可刪「分母枚舉+雙向遍歷」層**，見 §5 缺口 |

**不要因為 ritual 零增益就連 ID 系統一起無腦砍**：ID 系統的 correctness 價值確為零，但它是 Phase 5 機械追溯與「向人證明覆蓋」的骨架。砍它要看 §4/§7 對「人軸」的權重決定，不能僅憑 correctness 軸。

---

## 4. 該留什麼、為何（含對抗裁決：它們真的承重嗎？）

### 4.1 因果鏈 — 對抗裁決：**未否證，信心僅 0.62**

對抗階段沒能否證它承重，但把信心壓到 0.62，理由必須照實說：

- **repo 自家 baseline-failure-taxonomy 明文承認**：「在前沿模型 + 機械可驗 correctness 軸：因果鏈分析的淨值 ≈ 0（與其他機制一樣落入 null）」。它在三閘對照只拿 🟡，沒有差異化通過。
- **原始碼證實兩個結構弱點**：(1) impact-analysis-guard.sh 只驗「因果鏈區塊有沒有出現」（marker 存在即放行），不驗內容對不對；(2) DEPENDENTS 靠 grep 字面比對，抓不到動態派發/反射/字串拼接/跨語言邊界——「呼叫者=0 禁改」規則本身假設 grep 完備。

**真正承重的最小充分條件**（四條同時成立才承重）：
1. 被修改點 A 的相依點 B 不在當前注意力窗內（跨檔、長 repo、距離遠）∧
2. B 的依賴是靜態可被 grep/連動表捕捉的（非動態派發/反射）∧
3. 無編譯器/型別系統會自動抓出不一致（如本 repo 純文件依賴）∧
4. 存在跨 session/人接手的時間維度使依賴知識從注意力流失。

四條同時成立時（本 repo 自己的依賴影響表場景就是最有利特例），因果鏈擋下的是前沿模型「本來就會漏」而非「本來就不會犯」的遺漏——不是模型不夠聰明，是該依賴點根本不在它的視野，且沒有任何自動檢查器替它抓。

**照實說的不承重部分**：扣掉「grep 機械子集（呼叫者窮舉、=0 禁改）」這個 model-independent 的硬核後，剩下的「語意影響/間接影響/隱性風險」欄位仍是同源自填自審，與 ritual 同質、漏看率 50-67%。**且條件 ③ 對「有編譯器/測試的真實 codebase」大幅不成立——在那些專案因果鏈承重面急縮，本 repo 是純文件 repo 屬最有利特例，外推到一般軟體專案會高估承重性。**

### 4.2 事實求證 — 對抗裁決：**未否證，信心 0.62**

- **承重的存在性證據是真實事故**：GS 誤判事件（看到 `[pig] ip=...` 就斷言是 pig_server，#003-#005）是 production 級認知災難，有完整 incident 追溯——模型當下「不覺得自己在賭」。這證明「前沿模型自發做反例檢查」不可靠：它會在沒意識到自己在斷言事實時跳過。閘門價值不在教模型怎麼驗，而在**強制觸發**那個它最該做卻最不會自我觸發的時刻。
- **它切的是「前提層」**——五階 ritual 全部驗「步驟對不對」，沒有任何一階驗「前提對不對」。前提錯了 ritual 做得再完美都只是正確地放大錯誤。這是跨範式不可替代（實作驗證靠 assert，認知驗證靠證據分級/反例/共用值掃描）。

**真正承重的最小充分條件**（五條同時成立）：① 主張是「X 是 Y」型事實斷言而非可測試實作 ∧ ② 證據僅 B 級（相關性、存在但不唯一確定）∧ ③ 該主張會升格成不可逆行動前提（write_memory / 確定語氣 / SSH / DB / 部署）∧ ④ 錯誤代價不對稱地高 ∧ ⑤ 模型當下不會自發意識到自己在斷言。GS 事件同時命中五條。

**照實說的不承重/失效部分**：
- **dogfood E 型（植入假前提）在實驗中與裸寫平手、零增益**。它的承重 regime（人在環、高代價前提）從未被正面、可重複實證，只被「未否證」。
- **三方對稱中兩方（Section 12 自查、12.5 自反問）都是模型驗自己**，存在循環依賴：要靠一個有確認偏誤的模型可靠執行反例檢查，而確認偏誤正是讓它相信弱證據夠強的機制。唯一真正外部的 Section 13（用戶質疑）是下游救濟，其存在本身即承認上游兩方會失效，且對「用戶與模型一起錯」靜默失效。
- **觸發判定本身是認知任務、會漏觸發**：閘門入口靠的正是它要修補的那個有缺陷的判斷力——這使承重性在最危險的情境（無自覺斷言，正是 GS 當下）部分失效。

### 4.3 其他必留（workflow 結構上做不到）

| 保留項 | 為何不能交給 workflow |
|------|------|
| **4 個 always-on hook**（impact-analysis-guard / prompt-understanding-guard / incremental-lint / learning-log-checker） | opt-in 一旦不呼叫品質歸零，這是命門地基 |
| **跨 session 兩層教訓 + 升格** | workflow 每次乾淨起點，無歷史教訓回灌 |
| **可一行安裝的零執行期耦合部署** | self-contained 文檔可被任意專案靜態繼承；workflow 是執行期耦合 |

**一句話總結 §4**：ritual 賭「流程提升一次性產出質量」（已判零增益）；因果鏈+事實求證賭「外部化注意力窗外的依賴 + 高代價的錯誤前提」（這條賭注前提仍成立，但 n=1/n=0，且只外部化了「要戒慎」，還沒外部化「戒慎得對」）。它們值得保留並強化——但理由必須誠實錨在「未否證」而非「已證有效」。

---

## 5. 如何用原生 workflow 重建編排

按需編排殼，只在「任務值得重型處理」時由模型呼叫（微小/中型任務退回「單行 note + always-on hook」）。

```
workflow("closed-loop-redesigned", { budget: TOTAL }) {

  phase("P1 設計 — judge panel（解法空間 ≥2 時）")
    proposals = parallel([ agent(designA,{schema:DesignSpec}),
                           agent(designB,{schema:DesignSpec}) ])
    design = graft(judge_panel(proposals))      // N judge 平行評分 + 嫁接亞軍亮點
    // 每個 design agent prompt 強制含「因果鏈段 + 事實求證段」(見 §6)

  phase("P1b 設計審查 — adversarial verify")
    adversarial_verify(design, {skeptics:N, lens:"design-flaw"})
    // N skeptic 多數反駁 → 殺該設計點 → 回 P1（覆蓋優於單一 design-reviewer）

  phase("P2 實作")
    agent(implement, {isolation:"worktree"})    // worktree 是閉環缺的純增益
    // incremental-lint 仍在 hook always-on 層，不在 workflow 內

  phase("P3 多視角審查 — parallel + perspective-diverse")
    parallel([ agent(codeReview,{label:"correctness"}),    // 注入因果鏈呼叫者窮舉
               agent(secReview,{label:"security"}),        // 原 5 面向
               agent(reproReview,{label:"repro"}) ])        // barrier 確保派齊

  phase("P5 自證 — 見下方缺口補法")
}
// 層級擴展：pipeline(modules, P1..P5) streaming
```

### Phase 5 跨產出物一致性 — 缺口與補法（裁決 #1，信心 0.82）

**缺口（結構性，非實作不力）**：verifier 的核心不是逐 finding 驗證，而是「建立基準清單（分母）→ 正向追溯 → 反向枚舉 → 交叉比對」的雙向遍歷。adversarial-verify 的單位是「單個 finding 派 N skeptic」——它**沒有跨產出物的分母清單**，看不到「沒人提出的路徑」（reverse 方向的死碼/未實作）。completeness critic 派 agent 比對仍是 LLM 即興判斷，缺 BC-x/R-x 提供的確定性追溯骨架。delegation-tracker 的不可偽造 log 也無 workflow 等價。

**補法（三段，誠實標明哪段是重建而非原生）**：
1. **可枚舉子任務用 adversarial verify**：把「BC-3 是否被 P4 覆蓋」這類單一對應關係的*真偽判定*拆成 findings，派 N skeptic——這層 workflow 比 verifier 自填自審更硬（直接擊中 verifier 同源弱點）。
2. **分母枚舉 + 引用閉合須自製外掛**：用 schema 強制每個 agent 回傳帶 ID 欄位，外加一個持久化的 ID 登記表做「所有 BC-x 必須有明確 ✅/❌、不允許未檢查狀態」的機械比對。**坦白說：這已不是「原生 adversarial-verify」，而是用 workflow 工具重建 verifier 的分母層。** 超出「原生取代」範圍，屬自製成本。
3. **反向枚舉（找死碼/未實作）目前無原生解**：per-finding critic 結構上做不到。要嘛保留一個輕量 verifier agent 專做反向遍歷，要嘛接受此能力缺失。

**對 Phase 5 的誠實附註**：dogfood 已證 Phase 5 自證在 correctness 軸零增益。所以「補回 Phase 5」的正當理由必須改錨到「人接手維護 / 可稽核可重用 artifact」軸，**不是**「提升一次性正確性」。若你不為人軸付成本，Phase 5 的補法可以整段省略。

---

## 6. 如何「實質強化」因果鏈 + 事實求證（可落地，非口號）

核心策略：**Hook 管「必須做」（always-on）+ workflow 管「做得對」（異源對抗驗證）**。這是兩者唯一真正互補、且能正當主張價值的點——因為它直擊 §4 的共同弱點「同源模型自填自審」。

### Always-on hook 層（不可交給 workflow）

| 強化點 | 具體做法 |
|------|------|
| 因果鏈觸發 | 保留 impact-analysis-guard.sh PreToolUse exit 2，任何首次改檔都攔 |
| grep 完備性硬核 | 「呼叫者 grep=0 → 禁改」設為硬規則（少數 model-independent 強化，成本近零） |
| 事實求證觸發 | write_memory / 確定語氣前，hook 檢測「🔵 [事實主張] 區塊是否存在」 |
| 短期教訓保底 | 保留 learning-log-checker Stop hook |

### Opt-in workflow 層（補「驗質量」）

| 弱點 | workflow 強化 |
|------|------|
| 因果鏈 grep 假完備（漏動態派發/反射） | hook 觸發後 `parallel([grep-finder, semantic-caller-finder, cross-lang-finder])` 三路獨立找呼叫者取聯集；再派 1-2 獨立 skeptic「找出這個影響分析漏了什麼」 |
| 因果鏈內容敷衍騙過 exit-2 | `adversarial verify`：因果鏈區塊產出後派 N skeptic 反駁，多數反駁→打回重填。**這是把「驗形式」升級成「驗質量」的唯一結構解** |
| 事實求證反例可形式化敷衍 | 反例檢查由**獨立 context 的 skeptic agent** 重做（不是同一個有確認偏誤的模型）——直接打破循環依賴 |
| 同源自證天花板 | 強化方向：**把唯一真正外部的 Section 13（用戶質疑）做厚**——降低熔斷觸發門檻、放寬白名單句式，而非把同源的 12/12.5 做厚 |

### 誠實邊界（必須寫進方法論文件，避免過度宣稱）

- 強化**只到「部分打開/降低」，不是「解決」**。skeptic 仍同模型家族，可能共享集體盲點。**不要宣稱「解決了 #007」。**
- **觸發漏判補不了**：「我在不在斷言事實」「改 X 算不算需要因果鏈」這個入口判定本身是認知任務，靠的正是有缺陷的判斷力。workflow 注入層（L2）繼承 workflow 的 opt-in 病——模型不呼叫就沒了，所以**承重核不能只靠 L2，L1 hook 必須是真正地基**。

---

## 7. 被忽略的角度 + 殘餘風險

對抗裁決 #5（信心 0.82）指出：三方案作為一組，在四個角度系統性失覆蓋。

| 被忽略角度 | 內容 | 風險等級 |
|------|------|:--:|
| **版本相容 / 遷移** | 已用 v6.x 部署、artifacts 躺著 BC-x/R-x 的下游專案，升級時怎麼相容？workflow schema 與既有 BC-x 文字格式如何向後相容？三方案都改寫 588 行模板卻無一回答；minimal 直接「接受既有 artifact 失去工具支援」=承認破壞相容卻未設計遷移 | 🟡 |
| **退化路徑（fail-open/closed）** | 目標環境無 workflow runtime、或 deploy-hooks settings.json 合併失敗（bash 3.2 全形字元已知陷阱）時，系統 fail-open 還是 fail-closed？對紀律框架，**靜默 fail-open = 紀律歸零，比功能缺失更危險**。退化路徑該當一等公民設計 | 🔴 |
| **人軸無可操作驗收** | CLAUDE_TEMPLATE 自己明寫「唯一真正未測、且本方法論理論上才有獨佔優勢的是人軸」。三方案保留因果鏈/事實求證的理由全建立在這個它們都未設計如何驗證的軸上——把唯一能正當化保留承重核的軸僅當辯護話術 | 🔴 |
| **成本治理空白** | 閉環成本已 +40%~590%；adversarial verify(N skeptic) + judge panel(N 方案) 是再乘 N 倍 fan-out。在已證 correctness 零增益下把成本再乘 N 卻不設 budget 硬上限，是共同空白 | 🟡 |

### 殘餘風險（彙整各裁決 residual）

1. **🔴 可部署性斷裂（Claude-Code 耦合）**：閉環是「方法論發佈倉庫」，價值之一是一行 curl 任意專案可靜態繼承。workflow 化把它從「靜態可繼承文檔」變成「執行期耦合腳本」，用戶群從「任何能讀 CLAUDE.md 的人」縮到「有 workflow runtime 的人」。**緩解：workflow 層設成 optional 增強（像 SuperClaude），always-on hook + 因果鏈/事實求證的 CLAUDE.md 文檔層維持 self-contained；沒 workflow 環境的人退回「hook + 單行 note」也能用。dev:overview skill 的存在暗示公開散佈是第一性目標——若是，可部署性不可放棄，workflow 只能 optional。**
2. **🟡 承重核價值仍 n=1/n=0**：因果鏈 D 型 n=1、事實求證 E 型平手、人軸 n=0。把賭注全押在「尚未否證」格，若下一輪人軸實驗也測零增益，承重核正當性會跟 ritual 一樣崩。
3. **🟡 completeness critic 的根本侷限**：它是 per-finding 即興判斷，無分母枚舉，看不到「沒人提出的路徑」——這是它取代不了 Phase 5 反向遍歷的結構原因，不是調 prompt 能解。
4. **🟡 對抗強化只降低不解決**：同源自審天花板仍在；skeptic 同模型家族集體盲點仍可能。
5. **可學性**：無一方案以「新手能否在無維護者協助下自學並正確執行因果鏈/事實求證」為設計檢核點——若公開散佈是第一性目標，此角度應升為設計目標。

---

## 8. 建議的下一步驗證計畫（反 p-hacking）

**鐵律**（沿用 A–F 紀律）：平手 = 有效否證，照實記為 null；不准換 codebase 重跑直到出現想要的結果；三臂對照預先登記指標與判定門檻；correctness 軸用 oracle 自動判定，人軸用非 correctness-oracle 指標。

本報告的核心主張有三個尚未實證、必須直接測的命題：

### 實驗 G — 因果鏈的承重 regime（補 A–F 從未覆蓋的純淨格）
- **設計**：構造同時滿足 §4.1 四條件的任務（B 在注意力窗外 × 靜態 grep 可捕捉 × 跨 session × 純文件無編譯器）。
- **三臂**：裸寫 / 單行 note / 因果鏈閘門全套。
- **指標（oracle 可判）**：跨檔依賴遺漏數。
- **判定**：因果鏈臂顯著低於另兩臂 → 承重；三臂平手 → 連因果鏈在其宣稱的承重 regime 也是 null（照實記，不換題重跑）。
- **必含對照 G'**：把同一任務放進「有編譯器/型別系統」的 codebase 重測——驗證條件 ③ 是否真的讓承重面急縮（檢驗 §4.1 的「最有利特例」自我警告）。

### 實驗 H — 事實求證 × 人在環高代價前提
- **設計**：植入 B 級證據的假前提（複刻 GS 事件結構），**人在環**遞交。
- **三臂**：裸寫 / 同源自查（Section 12 原樣）/ **異源 skeptic 重做反例檢查**（§6 強化）。
- **指標**：假前提升格成行動的次數（oracle 可判）+ 觸發漏判次數（測 §4.2 入口缺陷）。
- **關鍵**：第三臂 vs 第二臂直接檢驗「異源是否真的打破同源天花板」。若第二、三臂同樣平手於裸寫 → 事實求證在此 regime 也 null；若三臂 > 二臂 → §6 強化方向有效。

### 實驗 I — 人軸（方法論宣稱的獨佔優勢，n=0）
- **設計**：找真實第三者（非作者）接手一份用閉環產出 vs 裸寫產出的程式碼 + artifact。
- **指標（非 correctness-oracle）**：接手者定位「改 X 要連動 Y」的時間、自評信心校準誤差、onboarding 正確率。
- **判定**：這是唯一能把「因果鏈/事實求證承重性」從「未否證」升級為「已證」的實驗。**若人軸也平手，§4 整個保留理由失去地基，方法論應退到極小派。**

**驗證計畫對本報告的自我約束**：以上三個實驗任一出現平手，相應的「該留」結論必須照實降級——本報告不預設它們會贏。

---

*報告由四階段 adversarial workflow 產出（14 agents / 2.16M token / 2026-06-01）。核心檔案路徑供實作參考：`dev-closed-loop/CLAUDE_TEMPLATE.md`（588 行主檔）· `hooks/{impact-analysis-guard,prompt-understanding-guard,incremental-lint,learning-log-checker}.sh`（建議保留）· `hooks/{delegation-gate,delegation-tracker}.sh`（條件刪除，視 Phase 5 機械追溯去留）· `.claudedocs/agents/{architect,design-reviewer,code-reviewer,security-reviewer,verifier}.md`（prompt 拆解來源）· `.claudedocs/standards/產出物格式.md`（ID 格式 source-of-truth）· `.claude-loop/baseline-failure-taxonomy.md`（A–F robust null 證據）。*
