# Python 語言 Skill

> 閉環整合：為 Phase 1-5 提供 Python 特定的規範和工具鏈指令。
> 內容來源：Jeffallan/claude-skills Python Pro（3,624 ⭐）

## 語言偵測觸發

```yaml
檔案模式: ["*.py", "*.pyi"]
配置檔案: ["pyproject.toml", "setup.py", "setup.cfg", "requirements.txt"]
套件關鍵字: ["python", "pip", "poetry", "uv"]
```

---

## Phase 1：架構師補充 📐

### 型別系統指南

**參數與回傳值定義**：

```python
from typing import Protocol, TypeVar, TypedDict, ParamSpec

# ✅ 用型別標註定義函式簽名
def process_order(order: Order) -> Result[ProcessedOrder, OrderError]:
    ...

# ✅ 用 Protocol 定義行為契約（結構化子型別）
class OrderProcessor(Protocol):
    def process(self, order: Order) -> ProcessedOrder: ...
    def validate(self, order: Order) -> None: ...

# ✅ 用 TypedDict 定義字典結構
class ApiResponse(TypedDict):
    status: str
    data: dict[str, Any]
    timestamp: datetime

# ✅ 用 dataclass 定義資料模型
@dataclass(frozen=True, slots=True)
class Order:
    id: str
    amount: Decimal
    items: list[OrderItem]
```

**進階型別工具**：

| 技術 | 適用場景 | 範例 |
|------|---------|------|
| Protocol | 結構化子型別（duck typing 型別化） | `class Readable(Protocol): def read(self) -> bytes: ...` |
| TypedDict | 字典結構約束 | `class Config(TypedDict): host: str; port: int` |
| Generic | 泛型容器/函式 | `class Stack(Generic[T]): ...` |
| ParamSpec | 裝飾器參數保留 | `P = ParamSpec('P')` |
| TypeGuard | 型別窄化函式 | `def is_valid(x: Any) -> TypeGuard[ValidOrder]: ...` |
| Literal | 字串/數值限定 | `status: Literal['active', 'inactive']` |
| `@overload` | 多簽名 | 不同輸入型別 → 不同回傳型別 |

### 常見 BC-x 模式

| BC 模式 | 說明 | Python 慣用處理 |
|---------|------|---------------|
| None 值 | 值可能為 None | `Optional[T]` + `is not None` 檢查 |
| 空容器 | 空 list/dict/set | 真值檢查 `if not items:` |
| 型別錯誤 | 動態型別的風險 | mypy strict mode + runtime validation |
| 可變預設引數 | `def f(x=[])` 陷阱 | `def f(x: list[int] | None = None)` |
| 浮點精度 | 金額計算 | `Decimal` 而非 `float` |
| 編碼問題 | 非 UTF-8 輸入 | `encoding='utf-8'` 明確指定 |

### 常見 EH-x 模式

| EH 模式 | 說明 | Python 慣用處理 |
|---------|------|---------------|
| 自訂例外 | 業務邏輯錯誤 | 繼承 `Exception`，附加 context 屬性 |
| 例外鏈 | 保留原始錯誤資訊 | `raise NewError(...) from original_error` |
| 資源清理 | 檔案/連線關閉 | `with` statement（context manager） |
| 外部 API 錯誤 | 網路/第三方服務 | `try/except` + retry + 逾時設定 |
| 驗證錯誤 | 輸入資料不合法 | Pydantic model + `ValidationError` |

### 設計模式建議

| 模式 | 適用場景 | 關鍵特徵 |
|------|---------|---------|
| Repository | 資料存取抽象 | Protocol 定義 + 依賴注入 |
| Strategy | 動態切換演算法 | Protocol + 函式/類別實作 |
| Factory | 複雜物件建構 | `@classmethod` 或獨立工廠函式 |
| Decorator | 橫切關注點 | `@functools.wraps` 保留函式資訊 |
| Context Manager | 資源管理 | `__enter__/__exit__` 或 `@contextmanager` |
| Observer | 事件驅動 | `Signal` 或簡單的 callback list |

---

## Phase 2：程序設計師補充 💻

### 編碼慣例

```yaml
命名規則:
  模組/套件: snake_case
  類別: PascalCase
  函式/方法: snake_case
  常數: UPPER_SNAKE_CASE
  私有: _leading_underscore
  型別變數: PascalCase（T, TResult）

Import 順序 (isort):
  1. 標準庫
  2. 第三方套件
  3. 本地套件
  （各組之間空行分隔）

程式碼風格:
  - 行寬上限: 88（Black 預設）或 79（PEP 8）
  - 字串: 統一用雙引號或單引號（專案一致）
  - f-string 優先於 format() 和 %
  - 列表推導 vs for 迴圈: 簡單轉換用推導，複雜邏輯用迴圈
```

### 專案結構

```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── models.py        # 資料模型
│       ├── services.py      # 業務邏輯
│       ├── repositories.py  # 資料存取
│       ├── api/             # API 路由
│       ├── utils/           # 工具函式
│       └── exceptions.py    # 自訂例外
├── tests/
│   ├── conftest.py          # 共用 fixture
│   ├── test_models.py
│   ├── test_services.py
│   └── test_api/
├── pyproject.toml           # 專案配置（推薦）
└── README.md
```

### 工具鏈指令

| 用途 | 指令 | 說明 |
|------|------|------|
| **增量驗證（lint）** | `ruff check src/` | Phase 2 每完成一個檔案執行 |
| **型別檢查** | `mypy src/` | 靜態型別驗證 |
| **格式化** | `ruff format src/` 或 `black src/` | 程式碼格式統一 |
| **Import 排序** | `ruff check --select I --fix src/` 或 `isort src/` | Import 順序 |
| **建置** | `python -m build` | 建置套件 |

### pyproject.toml 配置

```toml
[tool.mypy]
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM", "TCH"]
```

### 非同步模式

```python
import asyncio
from contextlib import asynccontextmanager

# 結構化並行（Python 3.11+）
async def process_all(items: list[Item]) -> list[Output]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(process_item(item)) for item in items]
    return [task.result() for task in tasks]

# 資源管理
@asynccontextmanager
async def managed_connection(url: str):
    conn = await connect(url)
    try:
        yield conn
    finally:
        await conn.close()
```

### 標準庫善用

```python
from pathlib import Path          # 路徑操作（不用 os.path）
from dataclasses import dataclass # 資料類別
from functools import lru_cache   # 快取
from itertools import chain       # 迭代器工具
from collections import Counter   # 計數器
from contextlib import contextmanager  # context manager
```

---

## Phase 3：檢核師補充 🔍

### 語言專屬審查清單

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| 裸 `except:` | high | 禁止 `except:` 或 `except Exception:`（太寬），指定具體例外 |
| `eval()` / `exec()` | high | 禁止對外部輸入使用 |
| 可變預設引數 | high | `def f(x=[])` 改為 `def f(x: list | None = None)` |
| 缺少型別標註 | medium | 所有公開函式必須有型別標註 |
| 全域可變狀態 | medium | 避免模組層級的可變變數 |
| 未使用 `with` | medium | 檔案/連線操作必須用 context manager |
| `import *` | medium | 禁止 wildcard import |

### 安全反模式

| 反模式 | 風險 | 修正方式 |
|--------|------|---------|
| `eval()` / `exec()` | 程式碼注入 | `ast.literal_eval()` 或 JSON 解析 |
| SQL 字串拼接 | SQL injection | 參數化查詢 `cursor.execute(sql, params)` |
| `pickle` 反序列化 | 任意程式碼執行 | 用 JSON 或 msgpack |
| `os.system()` | 命令注入 | `subprocess.run(cmd_list)` |
| 密鑰硬編碼 | 機密洩露 | 環境變數 + `python-dotenv` |
| `yaml.load()` | 任意程式碼執行 | `yaml.safe_load()` |

### 效能反模式

| 反模式 | 影響 | 修正方式 |
|--------|------|---------|
| 迴圈中 `+` 拼接字串 | O(n²) | `''.join(parts)` 或 f-string |
| 巢狀迴圈查找 | O(n²) | 用 `dict` 或 `set` 做 O(1) 查找 |
| 未使用 generator | 記憶體 | `yield` 替代 return list |
| 重複計算 | CPU | `@lru_cache` 或 `@cached_property` |
| 全域 import 未用到 | 載入時間 | 延遲 import（在函式內 import） |

### 結構安全

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| 非法狀態可表達 | medium | 互斥狀態用 `enum.Enum`，禁止多個 `bool` 欄位組合 |
| 窮舉匹配缺失 | medium | `match` 語句加 `case _: assert_never(x)` 防遺漏（3.10+） |
| 不必要的可變性 | low | 優先 `@dataclass(frozen=True)` / `Final` / `tuple` |
| 資源未釋放 | high | 所有 IO 用 `with` context manager，禁止裸 `open()` / 裸連線 |

---

## Phase 4：測試師補充 🧪

### 測試框架與指令

| 用途 | 工具 | 指令 |
|------|------|------|
| **單元測試** | pytest | `pytest tests/` |
| **覆蓋率** | pytest-cov | `pytest --cov=src tests/` |
| **非同步測試** | pytest-asyncio | `pytest tests/` (自動偵測) |
| **屬性測試** | Hypothesis | 內嵌於測試函式 |
| **型別測試** | mypy | `mypy src/` |
| **全部執行** | tox / nox | `tox` |

### 測試模式

**基礎結構（pytest）**：
```python
import pytest
from package_name.services import process_order

class TestProcessOrder:
    """process_order 測試"""

    # BC-1: 邊界條件
    def test_empty_order(self):
        with pytest.raises(EmptyOrderError):
            process_order(Order())

    # EH-1: 錯誤處理
    def test_invalid_amount(self):
        order = Order(amount=Decimal("-1"))
        with pytest.raises(InvalidAmountError):
            process_order(order)

    # 正常路徑
    def test_valid_order(self, valid_order):
        result = process_order(valid_order)
        assert result.status == Status.PROCESSED
```

**參數化測試**：
```python
@pytest.mark.parametrize("amount,expected_error", [
    (Decimal("0"), EmptyOrderError),       # BC-1
    (Decimal("-1"), InvalidAmountError),    # BC-2
    (Decimal("1e10"), OverflowError),       # BC-3
])
def test_invalid_amounts(amount, expected_error):
    with pytest.raises(expected_error):
        process_order(Order(amount=amount))
```

**Fixture 模式**：
```python
@pytest.fixture
def valid_order() -> Order:
    return Order(id="test-1", amount=Decimal("100.00"), items=[mock_item()])

@pytest.fixture
def mock_repository(mocker) -> MockRepository:
    repo = mocker.Mock(spec=OrderRepository)
    repo.find_by_id.return_value = valid_order()
    return repo
```

**屬性測試（Hypothesis）**：
```python
from hypothesis import given, strategies as st

@given(amount=st.decimals(min_value=Decimal("0.01"), max_value=Decimal("1000000")))
def test_valid_amount_always_produces_result(amount):
    order = Order(amount=amount, items=[mock_item()])
    result = process_order(order)
    assert result.total > 0
```

### Mock/Stub 模式

```python
from unittest.mock import AsyncMock, MagicMock, patch

# 依賴注入 mock（推薦）
def test_service_with_mock_repo():
    mock_repo = MagicMock(spec=UserRepository)
    mock_repo.find_by_id.return_value = User(id=1, name="test")
    service = UserService(repository=mock_repo)
    user = service.get_user(1)
    assert user.name == "test"

# AsyncMock
async def test_async_service():
    mock_repo = AsyncMock(spec=UserRepository)
    mock_repo.find_by_id.return_value = User(id=1, name="test")
    service = UserService(repository=mock_repo)
    user = await service.get_user(1)
    assert user.name == "test"
```

---

## Phase 5：自証師補充 ✅

### 驗證指令

Phase 5 自証時依序執行：

```bash
# 1. 型別檢查
mypy src/

# 2. Lint 檢查
ruff check src/

# 3. 格式檢查
ruff format --check src/

# 4. 測試
pytest tests/

# 5. 覆蓋率
pytest --cov=src --cov-report=term-missing tests/
```

### 品質指標

| 指標 | 目標 | 工具 |
|------|------|------|
| 型別檢查 | 0 error（strict mode） | `mypy --strict` |
| Lint 通過 | 0 error | `ruff check` |
| 測試覆蓋率 | BC/EH 100% | `pytest --cov` |
| 格式一致 | 0 diff | `ruff format --check` |
| Import 排序 | 正確 | `ruff check --select I` |

---

最後修訂：2026-02-24
