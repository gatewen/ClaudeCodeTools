# 02. 過度抽象處理單一場景（Q2 Simplicity 違反）

> 一個函式就能解決的計算，套了 Strategy / Factory / Builder / Observer 等 design pattern——把不存在的「未來變化」加進當前的設計。

## 場景

用戶要求：「寫一個算打折後價格的函式：折扣後價格 = 原價 × 折扣率。」

這是一行算式。沒有特殊邏輯、沒有條件分支、沒有狀態管理。

## 錯誤示範

AI 套了三層抽象：

```python
from abc import ABC, abstractmethod

class DiscountStrategy(ABC):
    @abstractmethod
    def apply(self, price: float) -> float: ...

class PercentageDiscount(DiscountStrategy):
    def __init__(self, rate: float):
        self.rate = rate
    def apply(self, price: float) -> float:
        return price * (1 - self.rate)

class DiscountFactory:
    @staticmethod
    def create(discount_type: str, **kwargs) -> DiscountStrategy:
        if discount_type == "percentage":
            return PercentageDiscount(kwargs["rate"])
        raise ValueError(f"Unknown: {discount_type}")

# 使用
calc = DiscountFactory.create("percentage", rate=0.2)
final_price = calc.apply(100)
```

26 行。為了一個 `price * 0.8` 的計算寫了 abstract class + factory pattern + dispatch logic。

未來如果真有「滿千送百」「會員折扣」「組合折扣」需求才會用到，但**現在沒有**——這是為「假想的未來」做的設計。

## 原則診斷

**違反**：Q2 Simplicity — 過度抽象、premature pattern application

**對映**：
- `CLAUDE_TEMPLATE.md` Section 0 Q2 Simplicity 自問：「能不能更簡單？不該寫的有沒有寫？資深工程師會說過度設計嗎？」
- `CLAUDE_TEMPLATE.md` 精簡閉環步驟 1 自檢第 7 問：「資深工程師看到會說過度設計嗎？」（K-02 senior engineer test）
- `concepts/閉環核心理念.md` 末尾 K-16 Anti-Patterns Summary 第 2 條：「Strategy pattern 處理單一計算」→ 修正：「一個函式直到複雜度真的需要」

**歷史教訓**：方法論本身的演進——v5.10.1 / v5.15.0 都做過「主動瘦身」（CLAUDE_TEMPLATE 從 606 → 361 行）。教訓：規則愈多執行可靠性愈低，要一次只加當前真實需要的。

## 修正版本

```python
def calculate_discounted_price(original: float, discount_rate: float) -> float:
    """折扣後價格 = 原價 × (1 - 折扣率)"""
    return original * (1 - discount_rate)

# 使用
final_price = calculate_discounted_price(100, 0.2)
```

3 行。等真的有「多種折扣策略」需求出現時再 refactor 為 strategy pattern，而不是預先設計。

## 關鍵限制

**適用**：
- 真的單一場景、無分支邏輯、未來變化未知
- 用戶 explicit 說「先做 MVP，未來再擴展」
- 任務等級為微小 / 中型，無強型別 framework 約束

**不適用**：
- 已知未來會有多種變化（例：用戶說「之後還要加會員折扣 / 組合折扣」）→ 用合理抽象
- 框架約束需要 interface（例：插件系統、可替換策略 IoC）→ 抽象是必要的

**白名單例外**：
- 已知約束的明確抽象（例：DI container、event bus）→ 不視為過度設計
- 用戶 explicit 說「我要 strategy pattern」→ 尊重決定（同 Section 12.5 4 條 push back 解除）

---

最後修訂：2026-04-26（v6.3.0 K-07 引入 · 來源 Karpathy 4 原則 Q2 Simplicity · 對映 CLAUDE_TEMPLATE Section 0 + 步驟 1 自檢 ⑦）
