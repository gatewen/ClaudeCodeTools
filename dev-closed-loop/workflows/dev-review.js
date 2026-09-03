export const meta = {
  name: 'dev-review',
  description: '品質 + 安全 + 可維護性審查 workflow：correctness / security / 可測性與可維護性三個視角並行審查（可維護性標準讀專案 CLAUDE.md arch-rules 一節）→ 每條 high/medium finding 派獨立 skeptic 反駁 → 只留反駁失敗的。找問題用中階模型、security 與反駁用高階、彙整用低階。與內建 /code-review 擇一；處理外部輸入的專案建議用本 workflow（含安全視角）。',
  phases: [
    { title: 'Review' },
    { title: 'Verify' },
    { title: 'Synthesize' },
  ],
}

// ── 模型等級 ──
// 定義出處：CLAUDE_TEMPLATE.md「模型分配」表。workflow 腳本不能 import，所以四支各放一份相同常數，
// tests/test-cross-file-consistency.sh 鎖四份相同且與模板一致（SSOT 第三層：合不成一處就用測試逼一致）。
// low：機械型 · mid：實作與探索 · high：判斷型，不指定 model 即繼承主對話。
const TIERS = {
  low: { model: 'haiku', effort: 'low' },
  mid: { model: 'sonnet' },
  high: {},
}

// ── 架構標準來源 ──
// SSOT：規則本文只在專案 CLAUDE.md（arch-rules 錨點那一節），這裡只指路，不抄一份。括號內是條目名索引，測試鎖它與模板一致。
const ARCH_RULES = `
【架構與可維護性標準】用 Read 讀目前工作目錄（專案根）下的 CLAUDE.md，找到 <!-- arch-rules --> 標記所在的那一節，逐條當標準（先找再造 / 一處一事 / 依賴只往下 / 不預留抽象 / 留下為什麼 / 單一事實來源 / 假共用煞車）。
找不到該節就在回報開頭明寫「專案未定義架構規則，以下用一般原則」，不要假裝有。
`

// args: 審查目標（檔案清單 / 變更描述 / undefined=審查未 commit 變更）
const TARGET = typeof args === 'string' && args.trim()
  ? args.trim()
  : (Array.isArray(args) ? args.join(' ') : '未 commit 變更（用 git diff / git status 找出範圍）')

const FINDING_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['lens', 'findings'],
  properties: {
    lens: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['severity', 'where', 'problem', 'fix'],
        properties: {
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          where: { type: 'string', description: '檔:行' },
          problem: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
  },
}

// ============================================================
phase('Review')

// tier：找問題用中階（correctness / 可維護性），security 屬判斷型用高階；下方 verify 一律高階，找的人與驗的人不同模型
const lenses = [
  {
    key: 'correctness',
    tier: 'mid',
    prompt: `你是 correctness 審查者。審查目標：${TARGET}。
重點：邏輯錯誤 / 邊界條件 / 因果鏈漏接（改了 X 但連動的 Y 沒改——grep 呼叫者窮舉驗證）/ 設計-實作一致性。
對每個「改了某處」的判斷，用 grep 驗證呼叫者，呼叫者=0 的修改要警示。`,
  },
  {
    key: 'security',
    tier: 'high',
    prompt: `你是 security 審查者。審查目標：${TARGET}。
5 面向：輸入驗證 / 注入（SQL/cmd/path）/ 認證授權 / 敏感資料暴露 / 依賴風險。給攻擊向量，不只列規則。
無安全面向（純算法/UI 無外部輸入）則回報「無安全相關 finding」。`,
  },
  {
    key: 'maintainability',
    tier: 'mid',
    prompt: `你是可測性+可維護性審查者。審查目標：${TARGET}。
重點：是否可被測試覆蓋（BC-x 有無對應測試）/ 你的改動造成的 dead code（orphan imports/函式）/ 既有 dead code（提及不動）/ 架構與可維護性標準逐條比對（見下）。
${ARCH_RULES}`,
  },
]

const reviews = (await parallel(lenses.map(l => () =>
  agent(l.prompt, { label: `review:${l.key}`, phase: 'Review', schema: FINDING_SCHEMA, ...TIERS[l.tier] })
))).filter(Boolean)

// 攤平所有 high/medium findings 去重後對抗驗證
const allFindings = reviews.flatMap(r => (r.findings || []).map(f => ({ ...f, lens: r.lens })))
const toVerify = allFindings.filter(f => f.severity === 'high' || f.severity === 'medium')

// ============================================================
phase('Verify')

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['isReal', 'confidence', 'reasoning'],
  properties: {
    isReal: { type: 'boolean', description: '這個 finding 是真問題還是誤報' },
    confidence: { type: 'number' },
    reasoning: { type: 'string' },
  },
}

// 每個 high/medium finding 派獨立 skeptic 嘗試「反駁這是真問題」（異源驗證，打破同源天花板）
const verified = (await parallel(toVerify.map((f, i) => () =>
  agent(
    `你是獨立驗證者（與發現此問題的 reviewer 不同 context）。盡力反駁以下 finding 是真問題——它可能是誤報。
若你能證明它不是問題（誤讀程式碼 / 已被別處處理 / 不在執行路徑），判 isReal=false。若反駁失敗，判 isReal=true。
Finding：${JSON.stringify(f)}
審查目標：${TARGET}
用 Read/Grep 實際查證程式碼，不要憑空判斷。`,
    { label: `verify:${f.lens}-${i}`, phase: 'Verify', schema: VERDICT_SCHEMA, ...TIERS.high }
  ).then(v => ({ finding: f, verdict: v }))
))).filter(Boolean)

const confirmed = verified.filter(v => v.verdict?.isReal)
const dismissed = verified.filter(v => v.verdict && !v.verdict.isReal)

// ============================================================
phase('Synthesize')

const report = await agent(
  `你是審查彙整者。產出審查報告（繁中）。
確認為真的 findings（已通過獨立 skeptic 驗證）：${JSON.stringify(confirmed)}
被駁回的誤報（記錄但不要求修）：${JSON.stringify(dismissed)}
低嚴重度 findings（未經對抗驗證，摘要即可）：${JSON.stringify(allFindings.filter(f => f.severity === 'low'))}

彙整：(1) high findings 清單（R-x 編號，severity high→必修）(2) medium（建議/用戶決策）(3) low 摘要 (4) 誤報記錄 (5) 整體 verdict（pass / fix-required / needs-attention）。
誠實，不放大也不縮小。寫入 .claude-loop/artifacts/P3-review.md 並回報摘要。`,
  { label: 'review-synthesis', phase: 'Synthesize', ...TIERS.low }
)

return { report, confirmed: confirmed.length, dismissed: dismissed.length }
