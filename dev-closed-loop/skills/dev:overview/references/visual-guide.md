# Visual Guide

dev:overview HTML 的視覺規範：配色、typography、互動、SVG 處理規則。所有規範**內建在 template.html 的 inline `<style>`**，不需外部 stylesheet。

## 1. Light/Dark Mode 切換機制

### CSS 結構

用 `data-theme` attribute on `<html>` + CSS variables：

```css
:root {
  /* light mode defaults */
  --bg: #ffffff;
  --fg: #1a1a1a;
  --fg-muted: #525252;
  --card-bg: #fafafa;
  --border: #e5e5e5;
  --link: #2563eb;
  --shadow: 0 1px 3px rgba(0,0,0,0.08);
}

:root[data-theme="dark"] {
  --bg: #0a0a0a;
  --fg: #f5f5f5;
  --fg-muted: #a3a3a3;
  --card-bg: #1a1a1a;
  --border: #2a2a2a;
  --link: #60a5fa;
  --shadow: 0 1px 3px rgba(0,0,0,0.3);
}
```

### Phase 顏色（5 個 phase × 2 mode = 10 個 token）

```css
:root {
  --phase-1: #4f46e5;  /* indigo-600 architect */
  --phase-2: #059669;  /* emerald-600 implementer */
  --phase-3: #7c3aed;  /* violet-600 reviewer */
  --phase-4: #d97706;  /* amber-600 tester */
  --phase-5: #e11d48;  /* rose-600 verifier */
}

:root[data-theme="dark"] {
  --phase-1: #a5b4fc;  /* indigo-300 */
  --phase-2: #6ee7b7;  /* emerald-300 */
  --phase-3: #c4b5fd;  /* violet-300 */
  --phase-4: #fcd34d;  /* amber-300 */
  --phase-5: #fda4af;  /* rose-300 */
}
```

對比度：light mode 各 phase 色 on `#fafafa` 卡片背景 ≥ 4.5:1；dark mode 各 phase 色 on `#1a1a1a` 卡片背景 ≥ 4.5:1。

### JS Toggle

```js
// 寫在 <head> inline，DOM render 前就決定 theme，避免初始閃白
(function() {
  const saved = localStorage.getItem('dev-overview-theme') || 'light';
  document.documentElement.setAttribute('data-theme', saved);
})();

// 切換 function（綁在右上角按鈕）
function toggleTheme() {
  const cur = document.documentElement.getAttribute('data-theme');
  const next = cur === 'light' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', next);
  localStorage.setItem('dev-overview-theme', next);
  updateToggleIcon(next);
}

function updateToggleIcon(theme) {
  const btn = document.getElementById('theme-toggle');
  // 顯示「點擊會切換到的目標模式」圖示
  btn.textContent = theme === 'light' ? '🌙' : '🌞';
  btn.setAttribute('aria-label', theme === 'light' ? '切換到 dark mode' : '切換到 light mode');
}
```

### 切換按鈕位置與樣式

```html
<button id="theme-toggle" onclick="toggleTheme()" aria-label="切換 light/dark mode">🌙</button>
```

```css
#theme-toggle {
  position: fixed;
  top: 16px;
  right: 16px;
  width: 40px;
  height: 40px;
  border: 1px solid var(--border);
  border-radius: 50%;
  background: var(--card-bg);
  color: var(--fg);
  font-size: 18px;
  cursor: pointer;
  z-index: 100;
  box-shadow: var(--shadow);
  transition: transform 0.15s ease;
}

#theme-toggle:hover { transform: scale(1.08); }
#theme-toggle:focus-visible { outline: 2px solid var(--link); outline-offset: 2px; }

@media (max-width: 640px) {
  #theme-toggle { top: 12px; right: 12px; width: 36px; height: 36px; }
}
```

---

## 2. Typography

### Font Stack

```css
body {
  font-family:
    -apple-system, BlinkMacSystemFont,
    "Segoe UI", Roboto,
    "PingFang TC", "Microsoft JhengHei",
    "Helvetica Neue", Arial,
    sans-serif;
}

code, pre, .mono {
  font-family:
    "SF Mono", Menlo, Consolas, Monaco,
    "Courier New", monospace;
}
```

> System font stack — 無外部資源、無 web font 載入延遲、中英文都有合理 fallback。

### Type Scale

| 元素 | size | weight | line-height |
|------|------|--------|-------------|
| `h1` (Hero title) | 2.5rem (40px) | 700 | 1.2 |
| `h2` (Section heading) | 1.75rem (28px) | 600 | 1.3 |
| `h3` (Card title) | 1.125rem (18px) | 600 | 1.4 |
| `p` (body) | 1rem (16px) | 400 | 1.6 |
| `.subtitle` | 0.95rem | 400 | 1.55 |
| `.small`, `.label` | 0.85rem | 500 | 1.4 |

`@media (max-width: 640px)`：h1 縮 → 2rem、h2 縮 → 1.5rem

---

## 3. Layout

### Container

```css
.container { max-width: 1080px; margin: 0 auto; padding: 0 24px; }
@media (max-width: 640px) { .container { padding: 0 16px; } }
```

### Section spacing

每個 `<section>` 上下 padding `4rem 0`，手機縮 `2.5rem 0`。

### Card grid

```css
.cards-row { display: grid; gap: 16px; }
.cards-row.cols-5 { grid-template-columns: repeat(5, 1fr); }
.cards-row.cols-3 { grid-template-columns: repeat(3, 1fr); }

@media (max-width: 900px) {
  .cards-row.cols-5 { grid-template-columns: repeat(2, 1fr); }
  .cards-row.cols-3 { grid-template-columns: 1fr; }
}
@media (max-width: 640px) {
  .cards-row.cols-5,
  .cards-row.cols-3 { grid-template-columns: 1fr; }
}
```

---

## 4. Phase Card 元件（§1 五階段閉環）

```html
<article class="phase-card" data-phase="1" tabindex="0">
  <div class="phase-badge">1</div>
  <h3>架構師</h3>
  <p class="phase-action">設計</p>
  <div class="phase-detail" hidden>
    <!-- 點擊後展開：做什麼 / 產出 / 為什麼 / 深入連結 -->
  </div>
</article>
```

```css
.phase-card {
  border: 2px solid var(--border);
  border-top: 4px solid var(--phase-color);
  border-radius: 8px;
  padding: 20px 16px;
  background: var(--card-bg);
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.phase-card[data-phase="1"] { --phase-color: var(--phase-1); }
.phase-card[data-phase="2"] { --phase-color: var(--phase-2); }
.phase-card[data-phase="3"] { --phase-color: var(--phase-3); }
.phase-card[data-phase="4"] { --phase-color: var(--phase-4); }
.phase-card[data-phase="5"] { --phase-color: var(--phase-5); }

.phase-card:hover { transform: translateY(-2px); box-shadow: var(--shadow); }
.phase-card[aria-expanded="true"] { box-shadow: 0 4px 12px rgba(0,0,0,0.12); }

.phase-badge {
  display: inline-block;
  width: 28px; height: 28px;
  line-height: 28px; text-align: center;
  background: var(--phase-color);
  color: white;
  border-radius: 50%;
  font-weight: 600;
  font-size: 0.9rem;
}

.phase-action {
  color: var(--phase-color);
  font-weight: 500;
  margin-top: 4px;
}

.phase-detail {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--border);
  font-size: 0.9rem;
  color: var(--fg-muted);
  transition: max-height 0.2s ease;
}
```

---

## 5. Collapsible Section（§2-§11 進階區）

預設折疊，點 heading 展開：

```html
<section class="advanced-section" id="section-2">
  <header class="section-header" onclick="toggleSection('section-2')" aria-expanded="false">
    <h2>§2 認知驗證層</h2>
    <span class="chevron">▼</span>
  </header>
  <p class="section-tagline">Claude 容易把「推論」當「事實」...</p>
  <div class="section-body" hidden>
    <!-- 細節 -->
  </div>
</section>
```

```css
.section-header { display: flex; justify-content: space-between; cursor: pointer; }
.chevron { transition: transform 0.2s ease; }
.section-header[aria-expanded="true"] .chevron { transform: rotate(180deg); }
.section-body { margin-top: 16px; }
```

「全部展開 / 全部折疊」按鈕（§1 + §2-§11 各自有，獨立控制）：

```html
<button class="toggle-all" onclick="toggleAllAdvanced()">全部展開</button>
```

---

## 6. SVG / Icon 規範

### SVG inline，用 `currentColor`

```html
<svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
  <path d="..." />
</svg>
```

→ SVG 自動跟著文字色變（light/dark 都對）。Phase 相關 SVG 用 `fill="var(--phase-1)"` 等。

### Emoji 使用

| 場景 | Emoji 選用 |
|------|-----------|
| 4 原則（Hero） | ❓ Think / ✂️ Simplicity / 🎯 Surgical / ✅ Goal |
| 升級狀態 | ✅ 已是最新 / 🔄 可升級 / ⚠️ 無法連線 |
| 紀律保底層 R-1~R-5 | 🔒 鎖頭 |
| 狀態機（升格/降級） | ⏸️ 條件式 / 🗄️ archive / 🔥 high-priority |
| Light/dark 切換 | 🌙 切到 dark / 🌞 切到 light |
| 部署狀態檢查項 | ✓ 已啟用 / ✗ 未啟用 / — 尚無紀錄 |

> System emoji，無外部資源。Dark mode 下彩色 emoji 可能比 light mode 飽和但可接受。

---

## 7. Color Palette 總表

| Token | Light | Dark | 用途 |
|-------|-------|------|------|
| `--bg` | `#ffffff` | `#0a0a0a` | body 背景 |
| `--fg` | `#1a1a1a` | `#f5f5f5` | 主文字 |
| `--fg-muted` | `#525252` | `#a3a3a3` | 次文字 / placeholder |
| `--card-bg` | `#fafafa` | `#1a1a1a` | 卡片 / section 背景 |
| `--border` | `#e5e5e5` | `#2a2a2a` | 邊框 / 分隔線 |
| `--link` | `#2563eb` | `#60a5fa` | 連結 / 強調 |
| `--shadow` | `rgba(0,0,0,0.08)` | `rgba(0,0,0,0.3)` | 卡片陰影 |
| `--phase-1` | `#4f46e5` | `#a5b4fc` | 架構師 |
| `--phase-2` | `#059669` | `#6ee7b7` | 程式師 |
| `--phase-3` | `#7c3aed` | `#c4b5fd` | 檢核師 |
| `--phase-4` | `#d97706` | `#fcd34d` | 測試師 |
| `--phase-5` | `#e11d48` | `#fda4af` | 自證師 |

---

## 8. Accessibility

| 要求 | 實作 |
|------|------|
| 對比度 | 所有文字 ≥ WCAG AA 4.5:1（已在配色表確認） |
| Keyboard 操作 | 所有 button / collapsible / phase-card 支援 `tabindex` + Enter/Space 觸發 |
| `aria-expanded` | Collapsible section / phase card 展開狀態用 `aria-expanded` 標示 |
| `aria-label` | Theme toggle / 純圖示按鈕加 label |
| `focus-visible` | 鍵盤焦點明顯 outline 2px solid `--link` |
| 跳過巨型動畫 | `@media (prefers-reduced-motion: reduce)` 關閉 transition |

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { transition: none !important; animation: none !important; }
}
```

---

## 9. 響應式斷點

| 寬度 | 模式 |
|------|------|
| ≥ 1080px | Desktop（max-width container） |
| 900–1080px | Desktop（fluid） |
| 640–900px | Tablet（5 cards → 2 columns） |
| < 640px | Mobile（單欄、padding 縮、字級縮） |

---

## 10. Performance

| 項目 | 目標 |
|------|------|
| 檔案總大小 | < 100KB（inline 全部資源） |
| First Paint | < 100ms（inline `<head>` script 處理 theme） |
| 無 web font 載入 | system font stack |
| 無 JS framework | vanilla JS（toggle + collapse） |
| 無 CDN | self-contained |
