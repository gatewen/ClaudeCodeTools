# Source Mapping

`{{PLACEHOLDER}}` ↔ source file / 指令 完整對映表。SKILL.md Step 2 依此表並行查詢拿值。

## 設計原則

1. **不重複維護**：所有事實值從現有 source files 動態取得，不寫死在 template
2. **並行執行**：彼此無依賴的查詢用單一 message 多個 Bash tool call
3. **失敗容錯**：個別查詢失敗 → 對應 placeholder 清空 / 顯示「⚠️ 無法偵測」，不整體 abort
4. **standalone fallback**：未部署狀態下，所有 `{{DEPLOYMENT_*}}` placeholder 留空 + 部署狀態區 HTML block 整段移除

---

## Placeholder 對映表

### 群組 A：版本資訊（call check-version.sh 一次取所有版本欄位）

| Placeholder | Source | 預設 fallback |
|------------|--------|--------------|
| `{{DEPLOYMENT_VERSION}}` | `check-version.sh --deployed ./CLAUDE.md --check-remote` 的 `DEPLOYED_VERSION=` 行 | `unknown` |
| `{{DEPLOYMENT_REMOTE_VERSION}}` | 同一次呼叫的 `REMOTE_VERSION=` 行 | `unknown` |
| `{{DEPLOYMENT_UPGRADE_STATUS}}` | 同一次呼叫的 `STATUS=` 行 → 對映顯示 | `unknown` |
| `{{DEPLOYMENT_CACHE_VERSION}}` | 同一次呼叫的 `CACHE_VERSION=` 行 | `unknown` |

**`STATUS` 對映顯示**：

| STATUS 值 | 顯示文字 |
|----------|---------|
| `up_to_date` | ✅ 已是最新版（v{DEPLOYMENT_VERSION}） |
| `upgrade_available` | 🔄 可升級：v{DEPLOYMENT_VERSION} → v{DEPLOYMENT_CACHE_VERSION}（執行 `/dev:init-claude upgrade`） |
| `cache_outdated` | 🔄 GitHub 有新版：v{DEPLOYMENT_REMOTE_VERSION}（本地快取：v{DEPLOYMENT_CACHE_VERSION}） |
| `deployed_newer` | ⚠️ 已部署版本 v{DEPLOYMENT_VERSION} 比快取 v{DEPLOYMENT_CACHE_VERSION} 新 |
| `REMOTE_CHECK=failed` | ⚠️ 無法連線 GitHub 確認遠端版本 |
| `error` 或 source 不存在 | ⚠️ 無法偵測升級狀態 |

### 群組 B：部署日期

| Placeholder | Source 指令 |
|------------|------------|
| `{{DEPLOYMENT_DATE}}` | `git log --diff-filter=A --format=%aI -- CLAUDE.md \| head -1 \| cut -c1-10` |
| `{{DEPLOYMENT_DAYS_AGO}}` | 算 today - DEPLOYMENT_DATE 的天數差 |

**fallback**：若 cwd 非 git repo 或 CLAUDE.md 沒 git 紀錄 → 用 `stat -f %SB -t %Y-%m-%d ./CLAUDE.md`（macOS）/ `stat -c %y ./CLAUDE.md \| cut -c1-10`（Linux）取 mtime 當部署日期。

### 群組 C：啟用功能盤點

| Placeholder | Source 指令 |
|------------|------------|
| `{{DEPLOYMENT_CORE_DOCS_COUNT}}` | `find .claudedocs -maxdepth 2 -name "*.md" -not -path "*/agents/*" -not -path "*/languages/*" -not -path "*/examples/*" \| wc -l \| tr -d ' '` |
| `{{DEPLOYMENT_AGENTS_COUNT}}` | `ls .claudedocs/agents/*.md 2>/dev/null \| grep -v README \| wc -l \| tr -d ' '` |
| `{{DEPLOYMENT_HOOKS_COUNT}}` | `ls .claude/hooks/*.sh 2>/dev/null \| wc -l \| tr -d ' '` |
| `{{DEPLOYMENT_LANGUAGE_LIST}}` | `ls .claudedocs/languages/*.md 2>/dev/null \| grep -v README \| xargs -n1 basename \| sed 's/\.md$//' \| tr '\n' ',' \| sed 's/,$//'` |
| `{{DEPLOYMENT_EXAMPLES_COUNT}}` | `ls .claudedocs/examples/*.md 2>/dev/null \| wc -l \| tr -d ' '` |

**fallback**：個別指令失敗（檔案不存在）→ 顯示 `0` 或空字串。

### 群組 D：累積活動

| Placeholder | Source 指令 |
|------------|------------|
| `{{DEPLOYMENT_LEARNING_LOG_COUNT}}` | `grep -c "^## " .claude-loop/learning-log.md 2>/dev/null \|\| echo 0` |
| `{{DEPLOYMENT_ESCALATED_RANGE}}` | `grep -oE "^### #[0-9]+" .claudedocs/records/問題追蹤.md 2>/dev/null \| sort -u \| awk 'NR==1{first=$0} END{if (NR>0) print first "~" $0 " (" NR " 項)"; else print "尚無紀錄"}'` |

**fallback**：檔案不存在 → 顯示「尚無紀錄」。

---

## Source-of-truth 內容區（不從 check-version 或 ls，從 source files 內容提取）

### Hero 一句話定義 + 描述

| Placeholder | Source |
|------------|--------|
| `{{HERO_TAGLINE}}` | 寫死在 template：「讓 Claude Code 跟你協作時走可追溯的五階段流程，不只把程式寫出來，還對自己的產出負責」 |
| `{{HERO_PROBLEM_LIST}}` | 寫死：見 content-spec.md Hero 區 |
| `{{HERO_AUDIENCE_LIST}}` | 寫死：見 content-spec.md Hero 區 |
| `{{HERO_DIFFERENCE_LIST}}` | 寫死：見 content-spec.md Hero 區 |

> **為什麼寫死而非從 source 提取**：Hero 是專門設計的白話文案，沒有對應的 source-of-truth 內容檔（concepts/閉環核心理念.md 是給技術人看的，不是 onboarding 語氣）。寫死在 template 即可，迭代時改 template。

### §1-§11 各 Section 內文

| Placeholder pattern | Source 策略 |
|--------------------|------------|
| `{{SECTION_<N>_TAGLINE}}` | 寫死在 template（白話化文案，跟 §1-§11 一行表一致） |
| `{{SECTION_<N>_DETAIL_<K>}}` | 寫死（白話化 + 結構化說明） |
| `{{SECTION_<N>_WHY}}` | 寫死（反向陳述痛點） |
| `{{SECTION_<N>_DEEP_LINK}}` | 對映到部署後的 `.claudedocs/` 路徑（連結，用戶點開深入） |

> 詳細「§N 對應哪個 source 路徑」見 `content-spec.md` 內各 section 末尾的「↗ 深入連結」。

---

## 並行查詢策略

SKILL.md Step 2 執行時，建議單一 message 包多個 Bash tool call（彼此無依賴）：

```
並行批次 1（同 message 多 Bash call）：
  - check-version.sh 一次取版本資訊（群組 A 一次解決）
  - git log + stat 取部署日期（群組 B）
  - ls .claudedocs/ 各子目錄（群組 C 各項）
  - grep -c learning-log + grep 問題追蹤升格 ID（群組 D）
```

預期完成時間 < 3 秒（全部本地 file ops + 一次 GitHub curl）。

---

## Standalone 模式處理

若 Step 1 偵測為 standalone（cwd 無閉環 CLAUDE.md）：

- **跳過群組 A、B、C、D 所有查詢**
- Template 中：
  - 所有 `{{DEPLOYMENT_*}}` 替換為空字串
  - HTML `<!-- DEPLOYMENT_BLOCK_START -->` 到 `<!-- DEPLOYMENT_BLOCK_END -->` 之間整段移除（含 marker comment）
  - Hero CTA 從「已部署」變體切換為「未部署 → 一行指令安裝」變體
- 寫死 placeholder（`{{HERO_*}}` / `{{SECTION_*}}`）照常填值
