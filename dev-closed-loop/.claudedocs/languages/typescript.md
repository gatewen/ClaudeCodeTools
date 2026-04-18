# TypeScript 語言 Skill

> 閉環整合：為 Phase 1-5 提供 TypeScript 特定的規範和工具鏈指令。
> 內容來源：Jeffallan/claude-skills TypeScript Pro（3,624 ⭐）

## 語言偵測觸發

```yaml
檔案模式: ["*.ts", "*.tsx", "*.mts", "*.cts"]
配置檔案: ["tsconfig.json", "tsconfig.*.json"]
套件關鍵字: ["typescript", "@types/*"]
```

---

## Phase 1：架構師補充 📐

### 型別系統指南

**參數與回傳值定義**：

```typescript
// ✅ 用精確型別，不用 any
function processOrder(order: Order): Result<ProcessedOrder, OrderError>

// ✅ 用 discriminated union 表達多種狀態
type ApiResponse<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: AppError }
  | { status: 'loading' }

// ✅ 用 branded type 防止原始型別混用
type UserId = string & { readonly __brand: 'UserId' }
type OrderId = string & { readonly __brand: 'OrderId' }
```

**進階型別工具**：

| 技術 | 適用場景 | 範例 |
|------|---------|------|
| Conditional Types | 根據輸入型別決定輸出型別 | `T extends string ? StringResult : NumberResult` |
| Mapped Types | 批次轉換物件屬性 | `{ [K in keyof T]: Validator<T[K]> }` |
| Template Literal Types | 字串模式約束 | `type Route = \`/api/${string}\`` |
| `infer` 關鍵字 | 從複雜型別中提取子型別 | `T extends Promise<infer U> ? U : T` |
| `satisfies` 運算子 | 保留推導型別同時驗證結構 | `config satisfies Config` |

### 常見 BC-x 模式

| BC 模式 | 說明 | TypeScript 慣用處理 |
|---------|------|-------------------|
| 空值輸入 | `null`, `undefined`, 空字串 | 啟用 `strictNullChecks`，用 optional chaining `?.` |
| 陣列邊界 | 空陣列、超大陣列 | 型別守衛 + `Array.isArray()` |
| 型別窄化 | union type 的各分支 | discriminated union + exhaustive switch |
| 異步競態 | Promise 並行時的順序問題 | `AbortController` + 取消機制 |
| 泛型約束 | 泛型參數缺乏約束 | `extends` 約束：`<T extends Record<string, unknown>>` |

### 常見 EH-x 模式

| EH 模式 | 說明 | TypeScript 慣用處理 |
|---------|------|-------------------|
| API 呼叫失敗 | 網路錯誤、逾時、非預期回應 | Result type pattern：`Result<T, E>` |
| JSON 解析 | 外部資料結構不符預期 | Zod/Valibot runtime validation |
| 型別斷言失敗 | `as` 強制轉型的風險 | 優先用 type guard 而非 `as` |
| 未處理 Promise | async 函式未 catch | 全域 `unhandledrejection` + 局部 try-catch |

### 設計模式建議

| 模式 | 適用場景 | 關鍵特徵 |
|------|---------|---------|
| Result/Either | 可預期的錯誤回傳 | 不用 throw，型別安全的錯誤處理 |
| Builder | 複雜物件建構 | 鏈式呼叫 + 型別推導每一步 |
| Repository | 資料存取抽象 | interface 定義 + 依賴注入 |
| State Machine | 有限狀態轉換 | discriminated union + transition 函式 |
| Factory | 根據條件建立不同實例 | overloaded signatures + type narrowing |

---

## Phase 2：程序設計師補充 💻

### 編碼慣例

```yaml
命名規則:
  變數/函式: camelCase
  型別/介面/類別: PascalCase
  常數: UPPER_SNAKE_CASE
  檔案: kebab-case.ts（元件用 PascalCase.tsx）
  泛型參數: 單字母大寫或描述性 PascalCase（T, TResult, TError）

Import 順序:
  1. Node.js 內建模組
  2. 外部套件（npm packages）
  3. 專案內部模組（用路徑別名 @/）
  4. 相對路徑模組
  5. 型別 import（用 type 關鍵字）

嚴格模式要求:
  - strict: true（包含 strictNullChecks, noImplicitAny 等）
  - noUncheckedIndexedAccess: true
  - exactOptionalPropertyTypes: true（視專案需求）
```

### 專案結構

```
src/
├── types/           # 共用型別定義
├── utils/           # 工具函式
├── services/        # 業務邏輯層
├── repositories/    # 資料存取層
├── controllers/     # 請求處理層（後端）
├── components/      # UI 元件（前端）
├── hooks/           # React Hooks（前端）
└── __tests__/       # 測試檔案（或 tests/）
```

### 工具鏈指令

| 用途 | 指令 | 說明 |
|------|------|------|
| **增量驗證（lint）** | `npx eslint --ext .ts,.tsx src/` | Phase 2 每完成一個檔案執行 |
| **型別檢查** | `npx tsc --noEmit` | 全專案型別驗證 |
| **格式化** | `npx prettier --write "src/**/*.{ts,tsx}"` | 程式碼格式統一 |
| **建置** | `npx tsc` 或 `npm run build` | 編譯產出 |

### tsconfig 常用配置

```jsonc
// 基礎嚴格配置
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "bundler",
    "paths": { "@/*": ["./src/*"] }
  }
}
```

### 框架模式

**React + TypeScript**：
- Props 用 `interface`，內部狀態型別用 `type`
- 事件處理器用 `React.MouseEvent<HTMLButtonElement>` 而非 `any`
- Custom Hook 回傳用 `as const` 或明確 tuple 型別
- 用 `React.FC` 或直接函式宣告（專案統一即可）

**Node.js + TypeScript**：
- 用 `@types/node` 提供 Node API 型別
- 環境變數用 `process.env` + Zod schema 驗證
- 路徑用 `path.join()` 而非字串拼接

---

## Phase 3：檢核師補充 🔍

### 語言專屬審查清單

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| `any` 型別使用 | high | 禁止非必要的 `any`，用 `unknown` + type guard 替代 |
| 型別斷言 `as` | medium | 每個 `as` 都需要合理理由，優先用 type guard |
| 非空斷言 `!` | medium | 避免 `obj!.prop`，用 optional chaining 或提前驗證 |
| 未處理 Promise | high | 所有 async 呼叫必須有 error handling |
| 過度泛型 | medium | 泛型參數應有 `extends` 約束，不要無限制泛型 |
| Import 型別 | low | 純型別 import 用 `import type` 語法 |
| 嚴格模式缺失 | high | tsconfig 必須啟用 `strict: true` |

### 安全反模式

| 反模式 | 風險 | 修正方式 |
|--------|------|---------|
| `eval()` 或 `new Function()` | 程式碼注入 | 用安全的替代方案 |
| 未驗證的外部輸入直接使用 | XSS / 注入 | Zod/Valibot runtime validation |
| `dangerouslySetInnerHTML` | XSS | 用 DOMPurify 消毒 |
| 密鑰硬編碼 | 機密洩露 | 環境變數 + `.env` |
| `JSON.parse()` 無 try-catch | Runtime crash | 包裝 safe parse 函式 |

### 效能反模式

| 反模式 | 影響 | 修正方式 |
|--------|------|---------|
| 不必要的 re-render | UI 效能 | `React.memo`, `useMemo`, `useCallback` |
| 大型 bundle | 載入速度 | dynamic import + code splitting |
| 同步大量運算 | 主執行緒阻塞 | Web Worker 或分批處理 |
| 陣列多次遍歷 | CPU 浪費 | 單次 `reduce` 或 pipeline |

### 結構安全

| 項目 | 嚴重度 | 檢查重點 |
|------|--------|---------|
| 非法狀態可表達 | medium | 互斥狀態用 discriminated union，禁止多個 `boolean` 組合 |
| 窮舉匹配缺失 | medium | switch 的 default 用 `const _exhaustive: never = x` 防遺漏新 variant |
| 不必要的可變性 | low | 優先 `readonly` / `Readonly<T>` / `as const`，`let` 需理由 |
| 資源未釋放 | high | `addEventListener` 有對應 `removeEventListener`，subscription 必 `unsubscribe` |

---

## Phase 4：測試師補充 🧪

### 測試框架與指令

| 用途 | 工具 | 指令 |
|------|------|------|
| **單元測試** | Vitest（推薦）/ Jest | `npx vitest run` / `npx jest` |
| **覆蓋率** | Vitest / Jest + c8 | `npx vitest run --coverage` |
| **E2E 測試** | Playwright | `npx playwright test` |
| **型別測試** | tsd / expect-type | 內嵌於測試檔案 |
| **全部測試** | npm script | `npm test` |

### 測試模式

**基礎結構**：
```typescript
describe('functionName', () => {
  // BC-1: 邊界條件
  it('should handle empty input', () => {
    expect(fn('')).toEqual(defaultValue)
  })

  // EH-1: 錯誤處理
  it('should throw on invalid input', () => {
    expect(() => fn(null as any)).toThrow(ValidationError)
  })

  // 正常路徑
  it('should process valid input correctly', () => {
    expect(fn(validInput)).toEqual(expectedOutput)
  })
})
```

**非同步測試**：
```typescript
it('should handle API timeout', async () => {
  vi.useFakeTimers()
  const promise = fetchData()
  vi.advanceTimersByTime(5000)
  await expect(promise).rejects.toThrow(TimeoutError)
})
```

**型別測試**：
```typescript
import { expectTypeOf } from 'vitest'

it('should return correct type', () => {
  expectTypeOf(fn).returns.toEqualTypeOf<Result<Data, Error>>()
})
```

### Mock/Stub 模式

```typescript
// 模組 mock
vi.mock('./database', () => ({
  query: vi.fn().mockResolvedValue([{ id: 1 }])
}))

// 依賴注入 mock（推薦）
const mockRepo: UserRepository = {
  findById: vi.fn().mockResolvedValue(mockUser),
  save: vi.fn().mockResolvedValue(undefined)
}
const service = new UserService(mockRepo)
```

---

## Phase 5：自證師補充 ✅

### 驗證指令

Phase 5 自證時依序執行：

```bash
# 1. 型別檢查（驗型別安全）
npx tsc --noEmit

# 2. Lint 檢查（驗程式碼品質）
npx eslint --ext .ts,.tsx src/

# 3. 測試（驗邏輯正確性）
npx vitest run        # 或 npx jest

# 4. 建置（驗產出物完整）
npm run build         # 或 npx tsc
```

### 品質指標

| 指標 | 目標 | 工具 |
|------|------|------|
| 型別覆蓋率 | 0 個 `any` | `tsc --noEmit` 無錯誤 |
| 測試覆蓋率 | BC/EH 100% | `vitest --coverage` |
| Lint 通過 | 0 error | `eslint` 無 error |
| Bundle 大小 | 按專案定義 | `bundlephobia` / webpack-bundle-analyzer |

---

最後修訂：2026-02-24
