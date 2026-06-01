# Workflow-First 方法論重構 — 架構藍圖（Phase 1 設計規格）

> 分支：`methodology/workflow-first-rewrite`（git 可逆）
> 用戶願景：workflow 當預設首選編排引擎 / CLAUDE.md 全面縮小 / PRD+架構設計走 workflow+對抗驗證 / 修改類動作有因果鏈+事實求證支撐 / agent 生成交給 workflow
> 證據基礎：workflow-migration-research.md（混合派 0.80）+ handoff-test RESULTS（人軸 proxy 未否證）+ claude-code-guide 部署機制查證
> 狀態：**待用戶審核拍板，通過後才改 25 檔**

## 0. 已查證的關鍵事實（決定設計）

| 事實 | 證據級 | 對設計的意涵 |
|------|--------|------------|
| 具名 workflow 部署慣例存在：`.claude/workflows/`（git-tracked）+ `~/.claude/workflows/` | A | setup.sh 可部署預製 workflow，使用者裝完即有 `/dev:*` workflow，不靠模型即興重寫 |
| 存檔 workflow 自動變 `/<name>` slash command | A | `/dev:prd`、`/dev:design` 可直接呼叫 |
| workflow 需付費方案 + v2.1.154+ + research preview | B | **退化路徑是硬需求**：必有使用者開不了 workflow |
| workflow script 內能否直接呼叫 Skill | 未明載 | 不阻塞（agent() 可用所有工具）；用 subagent 層存取 skill |
| 原生 adversarial-verify 無「跨產出物分母枚舉」 | A（報告裁決#1, 0.82） | Phase 5 自證的反向遍歷 workflow 蓋不到，需保留輕量 verifier 或接受缺失 |

## 1. 核心設計原則（三層分工）

```
┌─ L1 always-on hook 層（fail-safe 地基，workflow 不可用也在）────────┐
│  • impact-analysis-guard（因果鏈閘門）  • 事實主張觸發檢測          │
│  • incremental-lint  • learning-log-checker                        │
│  → 承重核（因果鏈+事實求證）的「強制觸發」錨在這層，不依賴 workflow │
├─ L2 workflow 編排層（預設首選，opt-in 但鼓勵）──────────────────────┤
│  • /dev:prd       PRD 探索 → judge-panel 多方案 → 對抗驗證          │
│  • /dev:design    架構設計 → 多方案 → adversarial-verify 砍缺陷     │
│  • /dev:review    多視角審查（correctness/security/repro 並行）     │
│  → 取代「五階流水線 + 8-agent 手工委派描述」                        │
├─ L3 CLAUDE.md 文字層（self-contained 退化路徑）────────────────────┤
│  • workflow 不可用時：因果鏈+事實求證走 inline + hook              │
│  • 微小/中型修改：不強制開 workflow，直接做 + L1 hook 護欄         │
└────────────────────────────────────────────────────────────────────┘
```

**鐵律**：承重核（因果鏈+事實求證）必須在 L1+L3 完整可用，**L2 workflow 只是讓它「做得更好」（異源對抗驗證），不是它存在的前提**。這樣 workflow 開不了的使用者仍有完整方法論。

## 2. CLAUDE.md 重構（588 行 → 目標 ~250-300 行）

### 刪除（依 A–F 實證 + 報告 §3）

| 刪除對象 | 行數 | 依據 |
|---------|------|------|
| 五階流水線的「強制逐 Phase 描述」（Phase 1-5 詳述 + 精簡閉環六步） | ~120 | correctness 零增益；編排交給 workflow |
| 雙軌（完整閉環 + 精簡閉環）並存 | ~40 | 報告 §3：雙軌維護是漂移源；合併單軌 |
| 配額管理策略 + 降級優先序劇本 | ~25 | workflow budget 原語取代手工降級 |
| TaskCreate 6-task 鏈描述 / blockedBy 鏈 | ~15 | workflow 控制流自帶依賴 |
| Section 6b 模組資產查詢 / 6c 兩層教訓的冗長格式 | ~30 | 濃縮（保留機制，砍格式樣板） |

### 保留並強化（承重核 + always-on）

| 保留對象 | 處理 |
|---------|------|
| Section 9 因果鏈閘門（閘門 B）+ 深度規則 6 條 | 保留，移到「修改類動作」段，強調 always-on hook |
| Section 12 事實主張閘門 + 12.5 push back + 13 質疑熔斷 + 13.5 反向劃線 | 保留（承重核），濃縮格式 |
| Section 0 四原則橫切自檢 | 保留（精簡） |
| Section 1 任務分級 + 1.5 探索成本上限 | 保留（決定何時開 workflow 的判準） |
| 兩層教訓 + 升格/降級機制 | 保留（跨 session 學習，workflow 蓋不到）|

### 新增

| 新增對象 | 內容 |
|---------|------|
| **Workflow 優先段** | 任務分級表新增一欄：大型/PRD/架構設計 → 開 `/dev:*` workflow；列出可用 workflow + 何時用 |
| **退化路徑段** | workflow 不可用時的 fallback（承重核走 L1+L3） |
| **承重核定位校準** | 依人軸 proxy 結果，誠實標：因果鏈+事實求證的價值在「把握度校準+發現成本攤銷+前提層防禦」，非 correctness（避免過度宣稱）|

## 3. 新增 workflow 腳本（部署到 ~/.claude/workflows/）

| workflow | 取代 | 結構 |
|----------|------|------|
| `dev-prd.js` | （新能力，原方法論無 PRD 階段） | 需求探索 → judge-panel N 方案 → 對抗驗證 → PRD 文件 |
| `dev-design.js` | Phase 1 + 1b（架構師 + 設計審查） | 多方案架構 → adversarial-verify 砍缺陷 → 設計規格 + BC-x/EH-x |
| `dev-review.js` | Phase 3（檢核 + 安全） | parallel(correctness/security/repro lens) → 對抗驗證 findings |
| `dev-verify.js`（可選） | Phase 5 自證 | ⚠️ 部分缺口：分母枚舉需自製 schema 外掛；反向遍歷保留輕量 agent |

每個 workflow 的 agent prompt **內嵌因果鏈+事實求證要求**（承重核注入 L2）。

## 4. 8 個 agent prompt 的去向

- **architect / design-reviewer / code-reviewer / security-reviewer / verifier**：內容（審查維度、BC-x 系統、攻擊向量清單）**萃取成 workflow agent 的 prompt 素材**，不再是「主 agent 讀檔委派」。檔案保留為「workflow 腳本的 prompt 來源庫」，但不再被 CLAUDE.md 直接引用走五階。
- **implementer / tester / requirements-analyst**：濃縮，部分併入 workflow 或 CLAUDE.md inline。
- **決策點**：agent prompt 庫是「砍掉」還是「轉為 workflow prompt 素材庫」？建議後者（知識不丟，只換載體）。

## 5. 連動檔清單（25+ 檔 lockstep）

| 改動類別 | 連動檔 |
|---------|--------|
| CLAUDE_TEMPLATE.md 主檔重寫 | （主檔） |
| Phase 流程變更 | process/五階段閉環流程.md · concepts/閉環核心理念.md |
| 產出物格式（ID 系統去留） | standards/產出物格式.md |
| 持久化 / 介面契約 | process/{跨Session持久化,介面契約與變更管理,層級擴展}.md |
| agent prompt 轉素材庫 | .claudedocs/agents/*.md（8 檔）+ README |
| workflow 部署 | setup.sh（新增 workflows/ 部署單元）+ 新增 .claude/workflows/*.js |
| hook 層（承重核保留） | hooks/*.sh（確認 always-on 不變）+ deploy-hooks.sh |
| skill 同步 | skills/dev:overview（方法論介紹 HTML 要反映新架構）· init-claude.md |
| 版本號 | source-of-truth marker + README ×2 |

## 6. 逆轉計畫（risk mitigation）

- 全程在 `methodology/workflow-first-rewrite` 分支，main 不動。
- 舊版 `methodology/dogfood-ae-calibration` 分支保留（含 A–F 校準 + 完整五階）。
- 重寫前先 commit 當前狀態為 restore point。
- 25 檔分批改 + 每批 cross-source review（R-2 hard requirement）。
- setup.sh 的 `.claudedocs` 驗證清單同步更新（檔案增刪）。

## 7. 待用戶決策的分岔

1. **agent prompt 庫**：砍掉 vs 轉 workflow prompt 素材庫？（建議後者）
2. **Phase 5 自證**：workflow 蓋不到反向遍歷——保留輕量 verifier agent vs 接受能力缺失 vs 改錨人軸（artifact 可稽核）？
3. **ID 系統（BC-x/EH-x/R-x）**：correctness 價值零，但人軸 proxy 顯示它是「向人證明覆蓋」骨架——保留 vs 簡化 vs 砍？
4. **版本號**：這是 breaking change，跳大版本（v7.0.0）？
5. **CLAUDE.md 目標行數**：~250-300 可接受，還是要更激進砍到 ~150？

## 8. 預判（誠實登記）

- 此重構是報告的**極大派 × 保留承重核**，比報告推薦的混合派更激進。報告對極大派的對抗裁決是 0.90 否證——但那是針對「連 always-on 紀律都換成 opt-in」的極大派。**本藍圖的 L1 hook 層保住了 always-on，化解了該否證的核心**（always-on 紀律沒被換掉，只有「編排」被換）。
- 最大殘餘風險：workflow research preview 階段，API 可能變動 → 部署的 workflow 腳本可能需維護跟進。
- 人軸承重核仍是「未否證非已證」——若日後真人接手實驗推翻，L2 的因果鏈+事實求證注入價值會縮水，但 L1+L3 不受影響（fail-safe 設計的好處）。
