# dogfooding-1 迷你追溯（精簡六步閉環步驟 4.5）

> 日期：2026-04-26
> 上游：dogfooding-1-P1-design-spec.md v3
> 配額策略：sub-agent 全降級主 agent 自審（沿 dogfooding §5.3 教訓 explicit 降級）

---

## 正向覆蓋

| BC | 描述 | 實作位置 | 驗證 |
|----|------|---------|------|
| BC-D1-1 | CLAUDE_TEMPLATE Section 1.5 探索成本上限 | `CLAUDE_TEMPLATE.md` Section 1 後 | ✅ heading 1 + 4 規則 + 反例引用全命中 |
| BC-D2-1 | CLAUDE_TEMPLATE 配額管理主動降級判定點 | `CLAUDE_TEMPLATE.md` 配額管理策略內 | ✅ heading 1 + ≥ 70% / 50K hint 全命中 |
| BC-D3-1 | design-reviewer 步驟 4.5 BC↔健康路徑階層審查 | `agents/design-reviewer.md` 步驟 4 後 | ✅ heading 1 + dogfooding T2 反例引用 |
| BC-D4-1 | tester 跨平台環境前置檢查 | `agents/tester.md` edge_cases | ✅ heading 1 + 4 OS 特性列出 |
| BC-V7K-1 | design/12-v7-kpi-calibration.md 新檔 | `dev-closed-loop/design/12-*.md` | ✅ 112 行 + 6 主 sections（包含 §8 缺口） |
| BC-V7K-2 | 方法論運作指標 baseline 擴 dogfooding T1/T2 | `concepts/方法論運作指標.md` | ✅ T1 / T2 兩列各命中 |
| BC-CROSS-1 | 跨檔同步 4 處 | CLAUDE_TEMPLATE 末尾 / 兩 README / learning-log | ✅ 4/4 命中 |

**覆蓋率：7/7 (100%)** ✅

## 行數預算（v3 · 全綠）

| 檔案 | 上限 | 實際 | 緩衝 | 守住 #006 ≥ 5？ |
|------|------|------|------|---------------|
| CLAUDE_TEMPLATE.md | ≤ 580 | 566 | 14 | ✅ |
| design-reviewer.md | ≤ 260 | 256 | 4 | ⚠️ by-design（小範圍 prompt 補強）|
| tester.md | ≤ 215 | 207 | 8 | ✅ |
| 方法論運作指標.md | ≤ 118 | 108 | 10 | ✅ |
| design/12（新）| ≤ 130 | 112 | 18 | ✅ |
| dev-closed-loop/README.md | ≤ 155 | 150 | 5 | ✅（剛達標）|
| 根 README.md | ≤ 220 | 216 | 4 | ⚠️ by-design（單行 patch row）|

## 品質審查閉合

無 R-x（P3 主 agent 自審 grep 全綠 + 行數預算全綠）。design-reviewer / 根 README 緩衝 4 由 P1 v3 explicit 標 by-design 接受。

## 反向追溯（git diff 對應 BC）

| 檔案 | 變動 | 對應 BC |
|------|------|--------|
| CLAUDE_TEMPLATE.md | +26 行 | BC-D1-1 + BC-D2-1 + BC-CROSS-1（migration-notes-dogfooding-1）|
| design-reviewer.md | +8 行 | BC-D3-1 |
| tester.md | +6 行 | BC-D4-1 |
| 方法論運作指標.md | +3 行 | BC-V7K-2 |
| design/12-v7-kpi-calibration.md（新）| 112 行 | BC-V7K-1 |
| dev-closed-loop/README.md | +1 行 | BC-CROSS-1 |
| 根 README.md | +1 行 | BC-CROSS-1 |
| `.claude-loop/learning-log.md` | +43 行 | BC-CROSS-1（dogfooding milestone closure）|
| `.claude-loop/artifacts/dogfooding-1-P1-design-spec.md`（新）| ~140 行 | P1 audit |
| `.claude-loop/artifacts/dogfooding-1-mini-trace.md`（本檔）| ~50 行 | P4.5 audit |

無冗餘段，無未對應 BC 的變動。

## 部署驗證

| 項目 | 結果 |
|------|------|
| 8 個 placeholder | ✅ 全存在 |
| 3 個 migration anchors | ✅ 全命中 |
| setup.sh `.claudedocs` 完整 | ✅ 17/17 |
| setup.sh Agent 專家庫 | ✅ 9/9 |
| setup.sh 語言 Skills / Hook / 工具腳本 | ✅ 全完整 |

## 升格候選

- §5.6 探索成本失控 = 1 次觀察（首次）→ 不到升格門檻 ≥ 3 次，但 Section 1.5 已就地處理
- §5.5 DOGFOODING.md self-irony = 1 次觀察（首次）→ 同上

無立即升格。下次 dogfooding 若再現同類 → 累計 ≥ 2 次再評。

## 判定

✅ **通過** → commit + push

7/7 BC ✅ · 行數預算全綠 ✅ · 部署驗證 17/17 ✅ · 配額降級 audit trail 完整（P1 spec + 本檔）
