# .claudedocs 技術文檔總覽

這個目錄存放所有跟「開發設計閉環」相關的技術文檔。

## 目錄結構

```
.claudedocs/
├── agents/                ← 🆕 Agent 專家庫（8 個專家 prompt）
│   ├── README.md
│   ├── requirements-analyst.md  ← Section 1b 需求探索
│   ├── architect.md             ← Phase 1 設計
│   ├── design-reviewer.md       ← Phase 1b 設計審查
│   ├── implementer.md           ← Phase 2 實作
│   ├── code-reviewer.md         ← Phase 3 品質審查
│   ├── security-reviewer.md     ← Phase 3 安全審查
│   ├── tester.md                ← Phase 4 測試
│   └── verifier.md              ← Phase 5 雙向追溯
├── concepts/              ← 先搞懂「為什麼」
│   ├── 閉環核心理念.md
│   └── 方法論運作指標.md   ← 🆕 v6.2.0 K-11 KPI 機制
├── process/               ← 再學「怎麼做」
│   ├── 五階段閉環流程.md
│   ├── 層級擴展.md
│   ├── 跨Session持久化.md
│   ├── 介面契約與變更管理.md
│   └── 實戰驗證流程.md     ← 🆕 v5.22.2 方法論 retrospective 模板
├── standards/             ← 然後看「用什麼工具、交什麼東西」
│   ├── Agent使用指南.md
│   ├── Git工作流.md
│   └── 產出物格式.md
├── records/               ← 最後知道「遇到問題怎麼辦」
│   └── 問題追蹤.md
└── languages/             ← 語言特定指南
    ├── README.md
    ├── typescript.md
    ├── python.md
    ├── go.md
    ├── rust.md
    └── csharp.md
```

## 閱讀順序

如果你是第一次看這套文檔，照這個順序來：

1. **閉環核心理念** — 理解這套方法的目的和核心概念
2. **五階段閉環流程** — 了解實際的執行流程
3. **Agent 使用指南** — 知道每個階段該用什麼工具
4. **產出物格式** — 知道每個階段要產出什麼
5. **層級擴展** — 了解如何從函式擴展到模組、框架
6. **Git 工作流** — 了解閉環和版本控制怎麼配合
7. **跨 Session 持久化** — 大型多模組專案怎麼跨 Session 保存閉環狀態
8. **介面契約與變更管理** — 跨模組公開 API 的 IF-x 契約和 CR-x 變更追蹤
9. **問題追蹤** — 知道遇到問題時怎麼記錄
10. **語言指南** — 你的專案語言的特定工具鏈、慣例和驗證指令（按偵測結果部署）
11. **實戰驗證流程** — 跑完 N 個任務後做 methodology retrospective（為下一版方法論升級提供證據基礎）
12. **方法論運作指標** — v6.2.0 K-11 引入的健康 KPI（3 指標 + 三區間門檻 + 觀察期校準）

## 文檔維護規則

- 發現文檔內容過時或有錯，直接修訂，不要另開新檔
- 新增內容放到對應的分類目錄，不要丟在根目錄
- 用白話文寫，不要堆術語
- 每次修訂在文檔底部更新「最後修訂」日期

## 前置需求

閉環自帶 Agent 專家庫（`.claudedocs/agents/`），不依賴外部工具。Task agent（`code-simplifier` 等）是 Claude Code 內建功能，無需額外安裝。

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| **claude-mem** _(可選)_ | 跨時間語義記憶（Phase 前查歷史決策、Phase 後保存教訓） | Claude Code 插件：`claude-mem` |
