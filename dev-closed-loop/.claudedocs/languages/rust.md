# Rust 語言 Skill

> 閉環整合：為 Phase 1-5 提供 Rust 特定的規範和工具鏈指令。
> 內容來源：Jeffallan/claude-skills Rust Engineer（3,624 ⭐）+ davidbarsky Rust Skills

## 語言偵測觸發

```yaml
檔案模式: ["*.rs"]
配置檔案: ["Cargo.toml", "Cargo.lock"]
套件關鍵字: ["[dependencies]", "crate"]
```

---

## Phase 1：架構師補充 📐

### 型別系統指南

**參數與回傳值定義**：

```rust
// ✅ 用 Result<T, E> 表達可失敗操作
fn process_order(order: &Order) -> Result<ProcessedOrder, OrderError>

// ✅ 用 enum 表達完整狀態空間（編譯器強制窮舉）
enum ApiResponse<T> {
    Success(T),
    Error(AppError),
    Loading,
}

// ✅ 用 newtype pattern 防止原始型別混用
struct UserId(i64);
struct OrderId(i64);

// ✅ 用 trait 定義行為契約
trait OrderProcessor {
    fn process(&self, order: &Order) -> Result<ProcessedOrder, ProcessError>;
    fn validate(&self, order: &Order) -> Result<(), ValidationError>;
}
```

**所有權與借用設計**：

| 概念 | 設計指引 | 範例 |
|------|---------|------|
| 所有權轉移 | 呼叫者不再需要資料時 | `fn consume(data: Vec<u8>)` |
| 不可變借用 | 只讀存取 | `fn read(data: &[u8])` |
| 可變借用 | 需要修改資料 | `fn modify(data: &mut Vec<u8>)` |
| `Clone` vs 借用 | 優先借用，必要時才 clone | `data.clone()` 僅當生命週期不允許借用 |
| 生命週期 | 明確標註輸入輸出關係 | `fn first<'a>(s: &'a str) -> &'a str` |
| 智慧指標 | 共享所有權或動態大小 | `Box<T>`, `Rc<T>`, `Arc<T>` |

### 常見 BC-x 模式

| BC 模式 | 說明 | Rust 慣用處理 |
|---------|------|-------------|
| Option 處理 | 值可能不存在 | `Option<T>` + `map/and_then/unwrap_or` |
| 越界存取 | 陣列/字串索引 | `get()` 回傳 `Option` 而非直接索引 |
| 整數溢位 | 數值計算溢位 | `checked_add/mul` 或 `saturating_add` |
| UTF-8 邊界 | 字串切片在字元邊界 | `char_indices()` 而非 byte offset |
| 空集合 | 空 Vec/HashMap 操作 | `is_empty()` 檢查 + `unwrap_or_default()` |

### 常見 EH-x 模式

| EH 模式 | 說明 | Rust 慣用處理 |
|---------|------|-------------|
| Library 錯誤 | 給呼叫者的結構化錯誤 | `thiserror` crate：`#[derive(Error)]` |
| Application 錯誤 | 應用層錯誤聚合 | `anyhow` crate：`anyhow::Result<T>` |
| 錯誤傳播 | 層層傳遞錯誤 | `?` 運算子 + `From` trait 自動轉換 |
| panic 恢復 | 不可恢復錯誤 | 限制 `unwrap()` 使用，用 `expect()` 附訊息 |
| 非同步錯誤 | tokio task 中的錯誤 | `JoinHandle::await?` + 適當的錯誤型別 |

### 設計模式建議

| 模式 | 適用場景 | 關鍵特徵 |
|------|---------|---------|
| Builder | 複雜結構體建構 | `XxxBuilder` + 鏈式呼叫 + `build() -> Result<T, E>` |
| Newtype | 型別安全的原始值包裝 | `struct Meters(f64)` + trait 實作 |
| Typestate | 編譯期狀態機 | 泛型參數表達狀態，方法只在特定狀態可用 |
| Strategy (trait object) | 動態多型 | `Box<dyn Processor>` |
| RAII | 資源管理 | `Drop` trait 自動清理 |

---

## Phase 2：程序設計師補充 💻

### 編碼慣例

```yaml
命名規則:
  函式/方法: snake_case
  型別/Trait: PascalCase
  常數: UPPER_SNAKE_CASE
  模組: snake_case
  生命週期: 短描述性（'a, 'ctx, 'input）
  Crate: kebab-case（Cargo.toml）/ snake_case（程式碼中）

錯誤處理:
  - Library crate: 用 thiserror 定義結構化錯誤
  - Application: 用 anyhow 簡化錯誤處理
  - 禁止非必要的 unwrap()，用 expect() 附說明或 ? 傳播
  - 測試中可以用 unwrap()

所有權規則:
  - 優先借用 &T，其次 &mut T，最後才轉移所有權
  - 小型 Copy 型別直接複製
  - 跨執行緒共享用 Arc<Mutex<T>> 或 channel
```

### 專案結構

```
project/
├── src/
│   ├── main.rs          # 二進位入口
│   ├── lib.rs           # 庫入口
│   ├── error.rs         # 錯誤型別定義
│   ├── config.rs        # 配置
│   ├── models/          # 資料模型
│   ├── services/        # 業務邏輯
│   ├── handlers/        # 請求處理（Web）
│   └── utils/           # 工具函式
├── tests/               # 整合測試
├── benches/             # 基準測試
├── examples/            # 範例程式
├── Cargo.toml
└── Cargo.lock
```

### 工具鏈指令

| 用途 | 指令 | 說明 |
|------|------|------|
| **增量驗證（lint）** | `cargo clippy -- -D warnings` | Phase 2 每完成一個檔案執行 |
| **格式化** | `cargo fmt` | 強制統一格式 |
| **建置** | `cargo build` | 編譯（debug 模式） |
| **建置（release）** | `cargo build --release` | 優化編譯 |
| **檢查（快速）** | `cargo check` | 只做型別檢查不產出二進位 |

### 非同步模式（Tokio）

```rust
// 結構化並行
async fn process_all(items: Vec<Item>) -> Result<Vec<Output>> {
    let mut handles = Vec::new();
    for item in items {
        handles.push(tokio::spawn(async move {
            process_item(item).await
        }));
    }
    let mut results = Vec::new();
    for handle in handles {
        results.push(handle.await??);
    }
    Ok(results)
}

// 取消安全
async fn cancellable_work(cancel: CancellationToken) -> Result<()> {
    tokio::select! {
        result = do_work() => result,
        _ = cancel.cancelled() => {
            cleanup().await;
            Err(anyhow!("cancelled"))
        }
    }
}
```

### 錯誤型別定義

```rust
// Library 錯誤（thiserror）
#[derive(Debug, Error)]
pub enum OrderError {
    #[error("order is empty")]
    EmptyOrder,
    #[error("invalid amount: {0}")]
    InvalidAmount(f64),
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
}
```

---

## Phase 3：檢核師補充 🔍

### 語言專屬審查清單

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| `unwrap()` / `expect()` | high | 非測試程式碼禁止 `unwrap()`，`expect()` 需有意義訊息 |
| 未處理 `Result` | high | 所有 `Result` 必須處理（`?` 或 match） |
| `unsafe` 區塊 | high | 每個 `unsafe` 需要安全性說明註解 |
| `clone()` 過度使用 | medium | 優先借用，clone 需要合理理由 |
| 死鎖風險 | high | 多個 Mutex lock 的順序必須一致 |
| 未使用的 `pub` | medium | 不需要匯出的項目移除 `pub` |
| Clippy 警告 | medium | 所有 clippy warning 需處理 |

### 安全反模式

| 反模式 | 風險 | 修正方式 |
|--------|------|---------|
| 不必要的 `unsafe` | 記憶體安全性破壞 | 用安全抽象替代 |
| SQL 字串拼接 | SQL injection | 用 sqlx 的參數化查詢 |
| `transmute` 使用 | 未定義行為 | 用 `From/Into` trait |
| 未驗證外部輸入 | 各類注入 | 解析前驗證 + `FromStr` trait |
| 密鑰硬編碼 | 機密洩露 | 環境變數 + `dotenvy` |

### 效能反模式

| 反模式 | 影響 | 修正方式 |
|--------|------|---------|
| 不必要的 allocation | 記憶體/CPU | `&str` 代替 `String`，`&[T]` 代替 `Vec<T>` |
| 不必要的 `clone()` | CPU | 借用或 `Cow<T>` |
| `collect()` 後立即迭代 | 記憶體浪費 | 保持 iterator 鏈式 |
| 未使用 `with_capacity` | 重複 allocation | 已知大小時預分配 |
| `Rc` 用於跨執行緒 | 編譯錯誤/效能 | 用 `Arc` |

### 結構安全

> Rust 的所有權系統和窮舉 match 已原生提供大部分結構安全保證。以下為額外注意項。

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| `#[non_exhaustive]` 缺失 | medium | 公開 API 的 enum 加 `#[non_exhaustive]`，控制 API 演化 |
| `Drop` 順序依賴 | medium | 多資源的 struct，確認 `Drop` 析構順序符合預期 |
| `Mutex` 中毒未處理 | high | `lock().unwrap()` 改為 `lock().expect("reason")` 或處理 `PoisonError` |
| interior mutability 濫用 | medium | `RefCell` / `Cell` 使用需合理理由，優先用所有權轉移 |

---

## Phase 4：測試師補充 🧪

### 測試框架與指令

| 用途 | 工具 | 指令 |
|------|------|------|
| **單元測試** | 內建 `#[test]` | `cargo test` |
| **整合測試** | tests/ 目錄 | `cargo test --test integration` |
| **文件測試** | 內建 doc test | `cargo test --doc` |
| **基準測試** | criterion | `cargo bench` |
| **屬性測試** | proptest | 內嵌於測試模組 |
| **模擬** | mockall | `#[automock]` 巨集 |
| **覆蓋率** | cargo-tarpaulin | `cargo tarpaulin` |

### 測試模式

**基礎結構**：
```rust
#[cfg(test)]
mod tests {
    use super::*;

    // BC-1: 邊界條件
    #[test]
    fn test_empty_order() {
        let result = process_order(&Order::default());
        assert!(matches!(result, Err(OrderError::EmptyOrder)));
    }

    // EH-1: 錯誤處理
    #[test]
    fn test_invalid_amount() {
        let order = Order { amount: -1.0, ..Default::default() };
        assert!(matches!(result, Err(OrderError::InvalidAmount(_))));
    }

    // 正常路徑
    #[test]
    fn test_valid_order() -> Result<()> {
        let result = process_order(&valid_order())?;
        assert_eq!(result.status, Status::Processed);
        Ok(())
    }
}
```

**屬性測試（proptest）**：
```rust
proptest! {
    #[test]
    fn test_amount_always_positive(amount in 0.01f64..1_000_000.0) {
        let order = Order { amount, ..Default::default() };
        let result = process_order(&order).unwrap();
        prop_assert!(result.total > 0.0);
    }
}
```

**非同步測試**：
```rust
#[tokio::test]
async fn test_async_process() {
    let result = async_process_order(&valid_order()).await;
    assert!(result.is_ok());
}
```

### Mock/Stub 模式

```rust
// mockall
#[automock]
trait Repository {
    fn find_by_id(&self, id: i64) -> Result<User>;
}

#[test]
fn test_with_mock() {
    let mut mock = MockRepository::new();
    mock.expect_find_by_id()
        .with(eq(1))
        .returning(|_| Ok(User { id: 1, name: "test".into() }));

    let service = UserService::new(Box::new(mock));
    let user = service.get_user(1).unwrap();
    assert_eq!(user.name, "test");
}
```

---

## Phase 5：自証師補充 ✅

### 驗證指令

Phase 5 自証時依序執行：

```bash
# 1. 格式檢查
cargo fmt -- --check

# 2. Clippy 靜態分析
cargo clippy -- -D warnings

# 3. 建置
cargo build

# 4. 測試（含文件測試）
cargo test

# 5. 文件建置（驗證文件範例）
cargo doc --no-deps
```

### 品質指標

| 指標 | 目標 | 工具 |
|------|------|------|
| 編譯通過 | 0 error, 0 warning | `cargo build` |
| Clippy 通過 | 0 warning | `cargo clippy -D warnings` |
| 測試覆蓋率 | BC/EH 100% | `cargo tarpaulin` |
| unsafe 區塊 | 0 或有安全說明 | 手動檢查 |
| 文件測試 | 全通過 | `cargo test --doc` |

---

最後修訂：2026-02-24
