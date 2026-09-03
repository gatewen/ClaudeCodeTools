# 開發設計閉環：十分鐘上手

> 給「想開始用，但不想先讀方法論」的人。看完這篇，跑一次 `/dev:init-claude`，就能用了。

## 它做什麼

裝進專案後，Claude Code 每個 session 會載入一份不到 200 行的 CLAUDE.md，管七件事：

1. **先判任務大小再動手**。改一行不走流程，新模組先出設計。
2. **改既有程式碼前先寫出誰會被牽動**。一支 hook 會在你第一次改某個原始碼檔時擋一下，要 Claude 先寫 2-4 行分析再重試。分析裡會數這個值還有幾份副本，一起改。
3. **新增或重構時守七條架構規則**。其中一條是單一事實來源：同一個東西只定義一處，其他地方去拿，不抄。
4. **斷言環境事實前先查證據**。看到一個 IP 就說它是某服務，這種錯不會因為模型變強就消失。
5. **只在五種情境反對你**，其他時候不多嘴。
6. **對你說話用白話**。先結論、術語附一句解釋、改動講「改了哪裡、為什麼、影響誰」。
7. **派子 agent 時看難度選模型**。機械活給低階、實作與探索給中階、設計與審查的判斷不降級。

## 三個場景

**改一個 typo**

> 「README 第 42 行 `recieve` 改成 `receive`」

直接改。README 不是原始碼，hook 不會擋。

**加一個函式**

> 「在 `utils.py` 加個算折扣價的函式」

Claude 先寫三到五行設計，至少一條行為契約（例如 BC-1：折扣率超出 0 到 1 時拋 ValueError），實作，寫測試，最後列一張表確認每條 BC 都有實作有測試。改 `utils.py` 第一下會被 hook 擋一次，Claude 會先列出誰用到 utils 再繼續。

**設計一個新模組**

> 「做一個密碼重設 API，要 email 驗證、rate limit、寄信重試」

Claude 會建議開 `/dev-design`：三個視角各提一個架構方案，每個方案派一個沒看過設計過程的 agent 找缺陷，評審後綜合成規格。實作後用 `/code-review` 或 `/dev-review` 審，測試，逐條追溯。

`/dev-design` 這類 workflow 需要付費方案和 research preview。開不了的話 Claude 會自己列方案取捨問你，核心紀律不變。

## 安裝

```bash
curl -sL https://raw.githubusercontent.com/gatewen/ClaudeCodeTools/main/setup.sh | bash
```

然後在任何專案目錄開 Claude Code，輸入 `/dev:init-claude`。它會偵測語言、框架、測試指令，問你確認後部署。

## 之後

| 想做什麼 | 指令或檔案 |
|---------|-----------|
| 看部署狀態 | `/dev:init-claude status` |
| 升級 | `/dev:init-claude upgrade` |
| 換 session 前存進度 | `/dev:handoff save`，新 session `/dev:handoff load` |
| 記一個踩過的坑 | 寫進專案的 `.claudedocs/records/問題追蹤.md`，Claude 設計前會掃 |
| 了解為什麼砍成這樣 | `.claudedocs/concepts/閉環核心理念.md` |
