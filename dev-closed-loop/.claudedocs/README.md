# .claudedocs 技術文檔總覽

這個目錄是「開發設計閉環」方法論部署到專案時一起帶進來的人類閱讀文檔。v8 起只有 5 份，Claude 平時不會主動讀，你需要時再翻。

```
.claudedocs/
├── README.md                    ← 你在看的這個
├── concepts/
│   └── 閉環核心理念.md          ← 這套方法在補什麼、實驗結果說了什麼、為什麼砍到只剩這些
├── standards/
│   ├── 產出物格式.md            ← 設計規格 / 審查報告 / 追溯表的最小模板（BC-x、R-x）
│   └── Git工作流.md             ← 什麼時候 commit、怎麼開分支
└── records/
    └── 問題追蹤.md              ← 踩過的坑。Claude 在中型以上任務設計前會掃一次
```

## 閱讀順序

1. **閉環核心理念**：十分鐘看完就知道 CLAUDE.md 那一百行在管什麼、不管什麼。
2. **產出物格式**：要 Claude 寫設計規格或審查報告時，格式從這裡來。
3. **問題追蹤**：你自己踩到坑就往這裡加一條，下次 Claude 設計前會看到。
4. **Git 工作流**：一頁，看一次就好。

## 維護規則

- 發現內容過時或有錯，直接修訂，不要另開新檔。
- 用白話文，不堆術語。
- 每次修訂在文檔底部更新「最後修訂」日期。

## v7 以前的文檔去哪了

agent 專家庫、六語言指南、五階段流程、介面契約、層級擴展、跨 Session 持久化、anti-pattern 範例、KPI 指標，全部搬到方法論 repo 的 `dev-closed-loop/design/history-v7/`，不再部署。原因寫在閉環核心理念的「為什麼是這五份」。

## 可選工具

| 工具 | 用途 | 安裝方式 |
|------|------|---------|
| **claude-mem** _(可選)_ | 跨 session 的語義記憶，設計前查歷史決策、完成後存教訓 | Claude Code 插件：`claude-mem` |
| **Claude Code Workflow** _(可選)_ | `/dev-prd` `/dev-design` `/dev-review` `/dev-verify` 多 agent 編排 | Claude Code v2.1.154+ · 付費方案 · research preview |

---

最後修訂：2026-09-03（v8.0.0：33 檔縮至 5 檔，其餘移至 design/history-v7）
