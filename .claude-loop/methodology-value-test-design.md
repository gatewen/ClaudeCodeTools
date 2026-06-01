# 「開發設計閉環」方法論 — A–E dogfood 後續決策報告

> 撰寫日期：2026-05-30 · 基於 commit a61449c（A–E 對照實驗結論）+ 四角度鑑別設計 + 對抗驗證
> 誠實底線：目標不是找到讓方法論贏的測試，而是找到最能公平鑑別「價值是否存在」的測試。若最佳設計又平手，正確結論是縮範圍或收掉，不是換種子重跑。
> 基礎設施已實機核驗：`codex-cli 0.128.0`、`go1.24.2`、`rg` 在場；`sandbox/closed-loop-validation/stage-{b,c,d,e}/` harness（before / golden-after / oracle / FROZEN-TASK / arms）齊備且可 fork。本報告引述的 stage-D 結論與 RESULTS.md 一致（三臂 5/5、閉環 token ≈ 1.4x、HIGH-1/HIGH-2 悲觀預測被推翻）。

---

## 1. 根因定論：為何 A–E 平手，但真實專案「修 A 壞 B」常見

**結論先講（高信心）：**「修 A 壞 B」的分歧變數**不是「前沿模型會不會做跨模組影響分析」——A–E 五場已直接證偽這點**（D 裸寫主動枚舉全部重算 site、E 主動拿事實宣稱核對 `data.go`、C 在 900 行/4 模組/相依圖/循環偵測上 28/28 全對）。真正的分歧變數是：

> **改動 A 的當下，被 A 依賴的遠端不變式 B 是否與 A 共置於同一個有效注意力窗內。**

四個調查角度雖然貼了不同標籤（context-persistence 的 C1/C2、measurement 的 context 腐蝕、seed-power 的 cue density≈0、model-trend 的注意力窗共置變數），但機制**完全同構**：B 要嘛物理上沒進 context（大 repo 超窗 / 別的 session 寫的 / 人類只貼了 A 周邊片段），要嘛進了 context 但被 100K+ 噪音稀釋（lost-in-the-middle）。

**A–E 之所以五場全平手（5/5・21/21・43/43・4/4・2/2），是因為三個設計特徵聯合把這個唯一的失效條件鎖死成不可能發生：**

| 設計特徵 | 後果 |
|---------|------|
| codebase 上限 ~900 行 / 4 模組，全部 ≪ 單一 context window | B 物理上不可能不在場（stage-C/D/E RESULTS 自承「整個任務仍在單一 context 可靠處理範圍內」「漂移根本沒出現」）|
| fresh context per arm + 單次連續生成 | 消除了跨 session 遺忘與長對話噪音稀釋這兩個真實最常見的不變式流失源 |
| 公平性閘門（Codex 要求耦合「真實、可發現、非混淆」，stage-D 帶自我說明註解）| 操作上等價於「強制每條被埋不變式 cue density 鎖在高位」——而帶線索、認真讀就找得到的不變式，依定義前沿模型必抓得到 |

**D 揭露的「公平/鑑別力張力」是這套機制的核心自證：** 要測出閉環增益，得讓 baseline 漏東西；但 Codex 要求埋的耦合「真實可發現、非混淆」→ 帶自我說明 → 這個「夠公平=夠可發現」正好讓認真讀過的前沿模型也找得到。stage-D RESULTS 親口道破：**「一個藏到能騙過前沿模型仔細 review 的耦合，依定義要嘛是不公平混淆、要嘛真的超出單一 context。」**

**∴ 閉環外部化的兩件事必須分開判：**
- **「認知步驟」（怎麼讀、怎麼分析）**：已被前沿模型內化，邊際價值**恆為零**。這是 A–E 五場已證的硬結論。
- **「狀態外部化 / 強制召回」（BC-x/IF-x 作為跨 context、跨 session 持久 ground truth，把不在窗內的 B 重新拉回眼前）**：A–E 因 codebase 從未超窗、從未跨 session，所以這個機制**從未有事可做**——但這是「機制無事可做」而非「機制無效」的證據。

**對「真實專案看得到、受控實驗看不到」的直接回答：** 真實專案的大 repo / 跨 session / 人類只貼片段，天天讓 B 掉出注意力窗；A–E 的實驗結構先驗刪除了這個條件。差距不在模型能力，在**實驗的 context 供給條件**與真實環境系統性不同。

**誠實警告（必須前置）：** 即使在失效 regime 重現了差異，最可能的真因仍是「補一句 checklist / 換一個外部視角」——#007 全史證明真正抓到盲點的是**外部 Codex** 而非五階段儀式。那推導出的結論是「方法論該瘦身到一條跨 session 持久化規則 + 一次外部 review」，**不是「找到了完整主場」**。

---

## 2. 存活設計排序與理由

四個角度提出的設計**全部 survives=true（fatal_count 全 0）**——沒有一個被致命缺陷殺掉，這本身值得注意：四個獨立角度都收斂到「打 context 共置/召回缺口」這條軸，且都在公平性與反 p-hacking 上做得異常乾淨（多份 verdict 評為「少數真正符合鐵律的對抗設計」）。但**「無致命缺陷」不等於「能鑑別出價值」**——多數設計的最可能結局是再次平手。排序依據是**鑑別力 × 不違鐵律 × 可行性**。

### 排名 1 — Stage-F（context-eviction · Evict-then-Edit）⭐ 首選
**為何最高：** 它精準打中四角度共同指認、且 A–E 五場唯一結構性測不到的軸（B 不在當前 context）。它有**兩個正交手段**製造失效條件（跨 session /clear + 規模稀釋），有 **arm3 純清單消融臂**（制度化分離「ritual vs 一行清單」），三份對抗 verdict 中 anti-phacking 直接判 **sound**（唯一一個拿到 sound 的設計+角度組合）。fairness 與 feasibility 判 fixable，修正項明確（見 §4）。它最接近「即使平手也能產出誠實的瘦身/收掉結論」。

**唯一致命隱憂（非 fatal 但決定成敗）：** fairness verdict 指出的「起點資訊量不對稱」——只貼 A 周邊給 arm0、卻把「下游 site 在哪」透過持久化產物餵給 arm2，會讓自變數同時混入「持久化機制」+「起點資訊量」。必修（見 §4 修正 1）。

### 排名 2 — RRR（regression-replay · 真實回歸重演）
**為何第二：** 用 OSS 真實歷史回歸當種子，**把「公平/可發現」交給檔案系統 grep 而非自我說明 cue**——正面化解 stage-D 的張力（discoverability 由歷史保證，非靠藏在 A 旁的線索）。種子非自造，p-hacking 與人為混淆的攻擊面最小。

**降為第二的硬理由（discrimination verdict 實證確認）：** 種子產量被嚴重高估。實測 testify 只有 14 個 regression-ish commit（多為雜訊），etcd 明確指認 introduced-by 的為 **0**。篩選漏斗是乘法式硬條件（可回溯連結 × B 不在 diff × 非 flaky × 可編譯 × 附 regression test × 需求無歧義），第一道就近乎歸零。「1–2 工作日湊 n≥20」不現實。且 anti-phacking verdict 點出 **n=20 的 Wilson CI 寬約 ±15pp，偵測 4pp 絕對差的統計檢定力幾乎為零**——宣稱「n≥20 能看到 5%→1% 尾部」在統計上是錯的。

### 排名 3 — HF-3L（human-oracle · 交接保真度三帳本）
**為何保留但第三：** 它是唯一直接打「價值落在人/接手者」這條 A–E 結構性測不到的軸，與前兩者正交（測「不同 agent 跨人交接」而非「同 agent 跨時間召回」）。fairness 與 anti-phacking 各判 **sound**（公平性無致命缺陷、反釣魚通過最硬測試）。

**降為第三的硬理由（discrimination verdict）：** 三個 construct 可能根本沒被激發——N2 提示語「金額邏輯與既有 total 耦合」本身就是耦合的自我說明，等同 A–E 的陷阱重演，接手者讀到就會主動 grep → 三臂漏連動率全 0。且「可稽核性評分」是 tautological 偏袒閉環的指標（裸寫臂結構上不可能有 BC-x/IF-x ID 可引用），是平手時的「軟著陸出口」。修正後（N2 去除自我說明 + 加人在迴路稽核臂 + 引入代碼漂移測 staleness）才有鑑別力。

### 排名外（未進前三但 survives）— Stage-F long-horizon 版 與 weaker-driver 版
- **long-horizon（N=10 輪 drift 曲線）**：與排名 1 同軸但更貴（150 次生成）。discrimination verdict 點出致命隱憂——1500-2500 行仍可能在單輪檢索能力內（D 已證 900 行 0 漏），後段曲線大概率仍貼地平手。需先做「尺寸校準 pilot」找到 arm0 開始退化的規模門檻，否則重蹈 D。鑑別力**低於**排名 1 的「跨 session 物理隔離」（/clear 比「同一 codebase 多讀幾輪」更能真正逐出 B）。
- **weaker-driver（降能執行者 × 自主迴圈）**：打的是與共識主因**正交**的另一條軸（執行者腦內注意力不足 vs B 不在窗內）。設計嚴謹、對抗驗證全過。但有一個未解的「算力混淆」——閉環閘門強制多跑 re-read passes 等於把 `reasoning_effort=low` 砍掉的算力偷渡回來，A2>A1 可能是「多算力」而非「結構外部化」。且 feasibility 自承 `reasoning_effort=low` 可能降能不足以觸發漏連動（`minimal` 與 mini 模型因 auth 被拒，降能旋鈕受限）。**這條軸的前提（降能執行者是方法論真實使用情境）較弱**——方法論宣稱對前沿模型 agentic autonomy 有用，但實際部署多半仍是前沿 effort。降級為「資源充裕時的第四順位探針」，不優先。

---

## 3. 被對抗驗證「實質否決」的角度（誠實記錄）

沒有任何設計被判 fatally_flawed。但對抗驗證**實質殺掉了若干「看似誘人但行不通」的方向**，記錄死因：

| 被殺方向 | 死因 | 來源 |
|---------|------|------|
| 在 A–E 同型任務上**換種子 / 加難**讓閉環贏 | stage-D 已道破：設計成 in-context 可發現就自動關掉「修A壞B」觸發路徑；要嘛不公平混淆、要嘛真超出單一 context。同一 single-context regime 內換種子永遠平手或退化成不公平混淆。**這是 p-hacking，違鐵律。** | killed_hypotheses + 共識診斷 |
| 「**超大型 codebase（≫900行）**」當高價值鑑別 regime | stage-C 自攻：900 行已接近單次舒適持有上限、模型仍全對，暗示 in-context 邊界比直覺高很多。前沿 1M context + 強 attention 可能讓多數真實中型 repo 仍落在無增益區。**規模軸鑑別力低於 session 軸**（跨 session 才產生「持久化產物 vs 零記憶」的不對稱）。 | killed_hypotheses |
| 「前沿模型太強 / 不會做跨模組分析」當病灶 | A–E 五場直接證偽：D 主動枚舉、E 主動核對、C 在相依圖/循環偵測 28/28。**問題從不是「不會分析」，是「B 不在眼前」。抓錯病灶。** | killed_hypotheses |
| 「閉環會穩定漏並發/業務語意結構盲區」（adversarial review HIGH-1/HIGH-2 對單檔的悲觀預測）| stage-A 推翻：三臂含裸寫全 5/5，race 靠讀 docstring 契約矛盾即抓到、不需 `-race`。至少「單檔、缺陷本地、docstring 已陳述意圖」情境此預測不成立。 | killed_hypotheses + RESULTS.md |
| 「認知驗證層是自我指涉悖論的 critical 盲點」| 方法論明文承認自檢不可靠並用 R-2/R-5 把外部來源制度化為不可 bypass，是已揭露並結構化回應的前提。critical framing 是稻草人。 | killed_hypotheses |

**最重要的「方法論層」死因（非單一設計）：** 多份 discrimination verdict 收斂到——**這些設計最可能的結局都是平手**，因為它們在公平性上越乾淨（給 baseline 完整 grep 權、耦合保持可發現），就越會讓前沿模型靠 agentic search 自助召回 B，把閉環的槓桿抹平。**這不是設計缺陷，是這個 regime 對前沿模型可能本就無 ritual 增益的證據。**

---

## 4. 推薦的可執行下一步（最多 3 個）

### 實驗 1（首選 · 必跑）— Stage-F context-eviction，先 n=5 pilot

| 項目 | 內容 |
|------|------|
| **臂** | arm0 裸寫（fresh session 2，完整 repo + 自由 ripgrep，只貼 A 周邊）／ arm1 裸寫 + 一次 Codex review ／ arm2 完整閉環（session 1 產 IF-x 影響表落盤 + session 2 強制 re-read）／ **arm3 純清單臂（只給下游 site 清單，無 ritual）** ／ **arm0+ 公平天花板臂（給對等中性提示「修改前請自行找出所有重算 site」，不點名檔案）** |
| **oracle** | Codex 預凍結 held-out `go test`（每個下游重算 site 是否正確反映折扣 + 既有回歸全綠），跑前 git tag 凍結、只跑一次；種子設計歸 Claude 提案、Codex FREEZE 簽核（六項，含「baseline 獲對等提示後認真召回仍漏 ⇒ 失效真來自規模非起點偏置」）；評分歸機械 `go test`，Claude 不裁判 |
| **指標** | 主：漏連動率 @ n（報分布 + 95 分位，不只均值）。輔：(a) **「沒去 grep」vs「grep 了仍漏」**（升格為作廢判據：若漏全落在「沒去 grep 且一次 ripgrep 即可命中」→ 判起點投餵污染、該種子重跑）；(b) 回歸破壞率；(c) token ROI；(d) arm2 vs arm3 差值 |
| **必修（凍結前）** | 1. 消除起點資訊量不對稱：arm0+ 拿到與閉環等價的「該去搜」中性提示。2. tool-call log 機械抽召回動作數，不採計 prose 敘述（杜絕 ritual 臂敘述化灌水）。3. 規模軸對稱：arm0 的「grep→讀回」回合 token 計入其成本 |
| **預登記預測（if value）** | arm0 漏連動率出現非零尾部（眾數 0 但 15–25% 種子漏掉語意上不像折扣相關的 audit/ledger site）；arm2/arm3 尾部顯著壓低且 ≈ 彼此 > arm0 → **價值真實但定位在「一張持久化清單」，導向瘦身**（不是完整 ritual 有主場）|
| **預登記預測（if no value · 最可能）** | arm0/arm0+ 主動 ripgrep 全抓、漏連動率分布塌在 0 → 四臂全平、閉環只多燒 token → **印證模型已內化 agentic 檢索（H4），方法論該瘦身或縮範圍** |

**先跑 n=5 pilot 的理由：** 若 pilot 即顯示 arm0/arm0+ 靠 grep 全抓且全對 → 立刻早停，在低成本下得出「此 regime 也無 ritual 增益」的誠實結論，避免燒全量 ~10M token。

### 實驗 2（pilot 有訊號才跑 · 或與實驗 1 並行做種子探勘）— RRR cross-file 回歸重演
與實驗 1 互補：實驗 1 用 /clear 製造「B 不在 session」，RRR 用 OSS 歷史製造「B 不在 diff」。**先決條件：先實測種子 base rate。**

| 項目 | 內容 |
|------|------|
| **臂** | 同實驗 1 四臂結構（裸寫 / 裸寫+Codex / 完整閉環 / 單條召回規則探針）+ **Arm0.5 最小顯著性對照**（裸寫 + 一句「確認此改動不破壞既有行為」，不含 grep 指示） |
| **oracle** | 歷史修復 commit 附帶的 regression test（`go test -race`，紅→綠機械判）+ 既有測試套件全綠；種子篩選/需求措辭/oracle 由 Codex 凍結，三方分離（Codex 篩雷 / Claude 執行 / go test 評分）|
| **指標** | 漏連動率（**重新定位 n=20 為 base rate / effect size 先導，非 confirmatory**；先導後做正式 power analysis 定 confirmatory n）；召回動作數只從 tool-call log 抽 |
| **必修** | 1. 種子來源改用 `git log -L` / `git blame` 機械回溯（不依賴 commit message 自陳 introduced-by，產量大增）。2. 先導 n=5 實測「跨 5–10 個大型 Go repo 池能挖幾個合格種子」，達不到 n≥20 就誠實降級為「只能否證強效應」。3. 預登記「漏連動率為唯一 confirmatory 檢定，其餘全 exploratory」（堵子群切片 p-hacking）|
| **預登記預測** | 同實驗 1：最可能 arm0 自行 grep 補齊 → 平手 → 印證 H4；若 Arm0.5/Arm3 > Arm0 而 Arm2 不更好 → 價值在「一句提醒/一條規則」非五階段 |

### 實驗 3（僅在前兩者顯示「對 agent 無價值」後 · 測殘餘的人類軸）— HF-3L 人在迴路稽核
**僅當實驗 1、2 都平手時才有意義**——因為它測的是「correctness oracle 量不到的人類稽核便利」，是方法論最後可能的窄落點。

| 項目 | 內容 |
|------|------|
| **臂** | 三臂生產交付包（裸寫 / 裸寫+Codex / 完整閉環）；接手端對稱交給 fresh 接手者 |
| **必修（否則重演 A–E）** | 1. **N2 去除自我說明**（改成「新增 credit-note，金額為原訂單負額調整」，不提 total/不提耦合）。2. **加人在迴路稽核臂**（模擬人類稽核者只讀 PR + artifact、禁讀全碼、限時判斷改動是否正確）——這是 IF-x/BC-x ID 唯一未被否證的具體承諾。3. **引入 N1→N2 代碼漂移**測 IF-x 表 staleness（若 stale 的 IF-x 反而誤導 → 證明 artifact 有負價值）。4. 「可稽核性評分」**降級為純描述性副指標，寫死「勝出不計入價值判定」**（堵 tautological 軟著陸）|
| **預登記預測（if no value · 較可能）** | 接手者也是前沿模型，拿到 N2 主動 grep → 三臂漏連動率全 0、接手成本無差、總帳因生產溢價永遠為負 → **交接軸對 agent 無價值，價值（若有）僅剩「人類稽核者讀 PR」這個更窄場景** |

---

## 5. 預登記失敗條件（若推薦設計「又平手」如何處置）

**這是整份報告最重要的承諾，按優先序寫死：**

1. **若 Stage-F pilot 平手形態是 arm0 自助 grep 全抓** → 判定「模型已內化主動檢索紀律，閉環的**認知步驟外部化在所有可量 regime 零增益**」。五階段儀式（11 sub-agent / BC-x / EH-x / Phase 5 自證）應**收掉**，不再宣稱對 correctness 有價值。

2. **若 arm3 純清單臂 ≈ arm2 完整閉環且兩者 > arm0** → 價值真實但定位在「一張跨 session 持久化下游清單 + 強制 re-read」這**單一動作**。方法論應**瘦身成一條 persistence rule**（現有 `.claude-loop/` IF-x 表的最小子集），完整 ritual 降為可選。

3. **若 arm1 一次 Codex review 補滿 arm0 的漏、arm2/arm3 不更好** → 收斂到「一次外部覆核就夠」（#007 全史已指此方向），方法論縮為「**裸寫 + 一次外部 review**」。

4. **若三軸（context-eviction / cross-file / handoff）全平手** → 方法論對 agent-to-agent 的所有 correctness-adjacent regime 無價值。唯一未被否證的殘餘僅剩 **HF-3L 人類稽核臂測出的「人在迴路稽核便利」**——那是個比「軟體品質方法論」窄得多的定位，應據此**重寫價值主張**。

**絕對禁止（違鐵律即作廢）：**
- ❌ 看到平手後換種子重跑直到閉環贏（p-hacking）
- ❌ 把 n 加大去釣不存在的尾部（reverse p-hacking）
- ❌ 用「規模沒到位、待重測」當藉口無限延後收斂結論

**pilot 全 0 即須誠實接受，不投全量。** 一個藏到能騙過認真讀的前沿模型的東西，依定義要嘛是不公平混淆、要嘛真的超出單一 context——前者作廢，後者才是合法的失效 regime。

---

## 6. 對用戶原問題的直接回答

**問：方法論存在價值的真實落點在哪？**

**直接回答（含不確定性標註）：**

1. **「修 A 壞 B」的根因不是模型不會分析，是 B 不在 edit 當下的注意力窗內。**（高信心 — A–E 五場直接證實模型會做影響分析）你的觀察「真實專案裸寫出問題機率仍蠻大」是對的，但 A–E 沒重現是因為實驗的 codebase 全部塞得進單一 context、全部單 session——真實專案的大 repo / 跨 session / 只貼片段天天讓 B 掉出窗外，而實驗結構先驗刪除了這個條件。

2. **閉環的「認知步驟外部化」（怎麼讀、怎麼分析）已被前沿模型內化，邊際價值恆為零。**（高信心 — 五場全平手 + RESULTS 自承）五階段儀式、11 sub-agent、Phase 5 雙向追溯在 correctness 上**沒有用成本賺回任何增益**（+40%→+590% 全是淨成本）。

3. **唯一可能殘餘的價值是「狀態外部化 / 強制召回」——把不在窗內的 B 重新拉回眼前。**（**中等信心，且方向偏向「也是零」**）這是 A–E 結構性測不到的唯一軸。但三點誠實警告：(a) 即使這個 regime 重現差異，最可能的真因是「一張持久化清單」或「一次外部 review」，**不是整套 ritual**（#007 全史已指此方向）；(b) 前沿模型的 agentic search（ripgrep 全 caller）按需召回，可能比靜態 IF-x 表更動態、更不 stale，使閉環在此軸也無增益（H4）；(c) 多份對抗 verdict 預測這些後續實驗**最可能也是平手**。

4. **方法論真正穩固的落點（correctness oracle 量不到、需另設實驗）可能只剩「人」這一窄維度：** 跨 session 人類交接、可稽核（PR 引用 ID 讓稽核者免重讀全碼）、協作追溯。**但這比「軟體品質方法論」窄得多，且至今零實證**——HF-3L 的人類稽核臂是第一個能測它的設計，尚未跑。

**一句話總結：** 證據強烈指向方法論的 correctness 價值**不存在於任何前沿模型 + 可量測的 regime**；它若有價值，落在「跨 session 持久化的一條規則」與「人在迴路的稽核」這兩個窄軸——而前者很可能可瘦身、後者尚待第一次實證。**誠實的預設是準備縮範圍，而非尋找主場。**
