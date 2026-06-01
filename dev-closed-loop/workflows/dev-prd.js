export const meta = {
  name: 'dev-prd',
  description: 'PRD / 需求探索 workflow（新能力，原方法論無 PRD 階段）：多角度需求探索 → judge-panel 候選 → 對抗驗證 → PRD 文件。事實求證確保需求前提不是憑空假設。',
  phases: [
    { title: 'Discover' },
    { title: 'Shape' },
    { title: 'Challenge' },
    { title: 'Synthesize' },
  ],
}

const IDEA = typeof args === 'string' && args.trim()
  ? args.trim()
  : (Array.isArray(args) ? args.join(' ') : '（未提供產品想法——請從對話脈絡或 .claude-loop/ 推斷，若無則回報需要輸入）')

const FACT_DISCIPLINE = `
【事實求證 — 必守】對「市場/用戶/現況/競品如此」這類事實斷言，標證據級：
🟢 A 級（可查證來源/檔:行）/ 🟡 B 級（間接推測）/ 🔴 反例檢查。
弱證據的需求假設必須標「假設·待驗證」，不可寫成既成事實。不要編造用戶沒說的需求。
`

// ============================================================
phase('Discover')

const DISCOVERY_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['problemStatement', 'targetUsers', 'jobsToBeDone', 'assumptions', 'openQuestions'],
  properties: {
    problemStatement: { type: 'string' },
    targetUsers: { type: 'array', items: { type: 'string' } },
    jobsToBeDone: { type: 'array', items: { type: 'string', description: '用戶要完成的工作（JTBD）' } },
    assumptions: { type: 'array', items: { type: 'string', description: '隱含假設 + 證據級' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
}

const angles = [
  { key: 'problem', brief: '問題視角：這到底解決什麼問題？問題真的存在嗎（證據）？' },
  { key: 'user', brief: '用戶視角：誰用？他們的 JTBD 是什麼？現在怎麼解決的？' },
  { key: 'scope', brief: '範圍視角：MVP 邊界在哪？什麼該砍？什麼是 v2？' },
]

const discoveries = (await parallel(angles.map(a => () =>
  agent(
    `你是需求探索 agent（${a.key} 視角）：${a.brief}
產品想法：「${IDEA}」
（可 Read/Grep 專案現況輔助判斷）
${FACT_DISCIPLINE}
回報：問題陳述 / 目標用戶 / JTBD / 假設（標證據級）/ 待答問題。`,
    { label: `discover:${a.key}`, phase: 'Discover', schema: DISCOVERY_SCHEMA }
  )
))).filter(Boolean)
const DISC = JSON.stringify(discoveries)

// ============================================================
phase('Shape')

const FEATURE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['mvpFeatures', 'deferred', 'successCriteria', 'risks'],
  properties: {
    mvpFeatures: { type: 'array', items: { type: 'string' } },
    deferred: { type: 'array', items: { type: 'string', description: 'v2+ 延後項' } },
    successCriteria: { type: 'array', items: { type: 'string', description: '可驗證的成功標準' } },
    risks: { type: 'array', items: { type: 'string' } },
  },
}

const candidates = (await parallel([
  { key: 'lean', brief: '精實：最小功能集驗證核心假設，能砍就砍。' },
  { key: 'complete', brief: '完整：第一版就解決用戶完整 JTBD，接受多做一點。' },
].map(c => () =>
  agent(
    `你是 PRD 塑形 agent（${c.key}）：${c.brief}
探索結果：${DISC}
產出功能候選：MVP 功能 / 延後項 / 可驗證成功標準 / 風險。
${FACT_DISCIPLINE}`,
    { label: `shape:${c.key}`, phase: 'Shape', schema: FEATURE_SCHEMA }
  )
))).filter(Boolean)

// ============================================================
phase('Challenge')

const challenge = await agent(
  `你是 PRD 對抗審查者。盡力挑戰以下需求探索 + 功能候選：
- 哪些「需求」其實是無證據的假設？（事實求證）
- MVP 範圍是否其實還能砍（YAGNI）？
- 成功標準是否真的可驗證，還是空話？
- 漏了哪個關鍵用戶/情境/失敗模式？
探索：${DISC}
候選：${JSON.stringify(candidates)}`,
  { label: 'challenge-prd', phase: 'Challenge' }
)

// ============================================================
phase('Synthesize')

const prd = await agent(
  `你是產品負責人，產出最終 PRD（繁中，寫入 .claude-loop/artifacts/PRD.md）。
綜合探索 + 候選，吸收對抗審查的挑戰（砍掉無證據假設、收緊 MVP）。
探索：${DISC}
候選：${JSON.stringify(candidates)}
挑戰：${JSON.stringify(challenge)}

PRD 須含：問題陳述 / 目標用戶 + JTBD / MVP 功能（明確邊界）/ 延後項 / 可驗證成功標準 / 風險與假設（標證據級·待驗證的明確標出）/ 下一步建議（通常接 /dev-design）。
${FACT_DISCIPLINE}
用 Write 落檔 + 回報 PRD 要點 + 仍待驗證的關鍵假設。`,
  { label: 'synthesize-prd', phase: 'Synthesize' }
)

return { prd }
