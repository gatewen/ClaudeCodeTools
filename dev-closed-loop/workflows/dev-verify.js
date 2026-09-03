export const meta = {
  name: 'dev-verify',
  description: '跨產出物追溯 workflow（可選）：枚舉設計規格的 BC-x → 單一 agent 正向追溯每條的實作與測試覆蓋 → 反向遍歷找死碼 / 未實作 / 範圍蔓延 → 報告。小專案用 coverage 工具即可，不必開。',
  phases: [
    { title: 'Enumerate' },
    { title: 'Forward Verify' },
    { title: 'Reverse Traverse' },
    { title: 'Synthesize' },
  ],
}

const SCOPE = typeof args === 'string' && args.trim()
  ? args.trim()
  : (Array.isArray(args) ? args.join(' ') : '本次產出（讀 .claude-loop/artifacts/ 下 P1-design-spec / P3-review 等）')

// ============================================================
phase('Enumerate')
// 建立「分母」——設計規格裡所有 BC-x 行為契約清單。漏列一條就會漏驗一條。

const ENUM_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['behaviorContracts', 'artifacts'],
  properties: {
    behaviorContracts: {
      type: 'array',
      items: { type: 'object', additionalProperties: false, required: ['id', 'statement'], properties: { id: { type: 'string' }, statement: { type: 'string' } } },
      description: '從設計規格枚舉的所有 BC-x（分母）',
    },
    artifacts: { type: 'array', items: { type: 'string' }, description: '存在的產出物清單' },
  },
}

const enumeration = await agent(
  `你是分母枚舉 agent。範圍：${SCOPE}
讀 .claude-loop/artifacts/ 下產出物（P1-design-spec.md 等），枚舉**所有** BC-x 行為契約（這是後續正向追溯的分母——漏列一個 BC-x 就會漏驗一條）。
回報：BC-x 清單（id + statement）+ 存在的產出物清單。`,
  { label: 'enumerate-bc', phase: 'Enumerate', schema: ENUM_SCHEMA }
)
const BCS = enumeration.behaviorContracts || []

// ============================================================
phase('Forward Verify')
// 正向：每條 BC-x 是否有實作、有測試。單一 agent 一次追完（每條開一個 agent 的成本不成比例）。

const COVERAGE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['coverage'],
  properties: {
    coverage: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['bcId', 'covered', 'implEvidence', 'testEvidence', 'gap'],
        properties: {
          bcId: { type: 'string' },
          covered: { type: 'boolean' },
          implEvidence: { type: 'string', description: '實作位置 檔:行 或「找不到」' },
          testEvidence: { type: 'string', description: '測試名稱 或「無測試」' },
          gap: { type: 'string', description: '若未覆蓋，缺什麼；覆蓋則留空' },
        },
      },
    },
  },
}

const forward = BCS.length ? await agent(
  `你是正向追溯 verifier。對下列每一條行為契約，用 Read/Grep 實際查證：有沒有對應實作（檔:行）、有沒有對應測試（測試名稱）。
預設懷疑：找得到完整實作 + 測試才判 covered=true，否則 false 並寫出 gap。不要憑印象，每條都要有證據位置。
分母共 ${BCS.length} 條，回報的 coverage 陣列必須也是 ${BCS.length} 條、bcId 一一對應。
BC 清單：${JSON.stringify(BCS)}
範圍：${SCOPE}`,
  { label: 'forward-trace', phase: 'Forward Verify', schema: COVERAGE_SCHEMA }
) : { coverage: [] }
const coverage = forward.coverage || []

// ============================================================
phase('Reverse Traverse')
// 反向：找「沒人提出的路徑」——死碼 / 未實作 / 未對應任何 BC-x 的行為。正向追溯看不到「沒被列出的」。

const reverse = await agent(
  `你是反向遍歷 verifier。正向追溯只驗「被列出的 BC-x」，看不到「沒人提出的路徑」，這一步補這個缺口。
範圍：${SCOPE}
已枚舉的 BC-x：${JSON.stringify(BCS.map(b => b.id))}
反向掃描：
1. **死碼**：新增/改動的程式碼中，有沒有不被任何執行路徑呼叫的（grep 呼叫者=0）？
2. **未實作**：設計規格提到但程式碼裡找不到的？
3. **未對應 BC**：實作了但不對應任何 BC-x 的行為（範圍蔓延 / 過度設計）？
用 Read/Grep 實際查。回報每類發現 + 檔:行 + 建議（刪除 / 補 BC / 補實作）。`,
  { label: 'reverse-traverse', phase: 'Reverse Traverse' }
)

// ============================================================
phase('Synthesize')

const notCovered = coverage.filter(c => !c.covered)
const missingIds = BCS.map(b => b.id).filter(id => !coverage.some(c => c.bcId === id))
const zeroDenominatorWarn = BCS.length === 0
  ? `\n⚠️ **分母=0 警示**：本次枚舉到 0 條 BC-x。這幾乎一定是異常（設計規格缺失／未落檔 .claude-loop/artifacts/ ／枚舉 agent 失敗），**不代表「全部通過」**。verdict 必須判 fix-required，並指出：先確認設計規格存在且含 BC-x 再重跑。嚴禁因「無 covered=false 項」而判 pass。\n`
  : ''
const missingWarn = missingIds.length
  ? `\n⚠️ 正向追溯漏回報 ${missingIds.length} 條 BC（${missingIds.join(', ')}），視為未覆蓋。\n`
  : ''
const verdict = await agent(
  `你是追溯彙整者。產出跨產出物一致性報告（繁中，寫入 .claude-loop/artifacts/P5-verify.md）。
${zeroDenominatorWarn}${missingWarn}正向覆蓋結果（分母 ${BCS.length} 條 BC-x）：${JSON.stringify(coverage)}
未覆蓋項：${JSON.stringify(notCovered)}
反向遍歷（死碼/未實作/範圍蔓延）：${JSON.stringify(reverse)}

彙整：
1. 正向覆蓋率：${coverage.length - notCovered.length}/${BCS.length} BC-x 完整覆蓋
2. ⛔ 正向有未覆蓋（covered=false 或漏回報）→ 禁止 commit，列回退建議（設計-實作不一致 → 補實作 / 測試不足 → 補測試）
3. 反向發現 → 死碼建議刪 / 未實作建議補 / 範圍蔓延建議砍
4. 整體 verdict（pass / fix-required）
誠實，不放大也不縮小。`,
  { label: 'verify-synthesis', phase: 'Synthesize' }
)

return {
  verdict,
  forwardCoverage: BCS.length === 0 ? '⚠️ 0/0（分母異常·非通過）' : `${coverage.length - notCovered.length}/${BCS.length}`,
  missingFromForward: missingIds,
  reverseFindings: reverse,
}
