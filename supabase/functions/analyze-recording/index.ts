import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

const WHISPER_API_URL = 'https://api.openai.com/v1/audio/transcriptions'

const CLAUDE_PROMPT = `你是一位專業的英語口說教練，擅長幫助台灣大學生改善日常英文對話能力。

以下是一位學生在英文社交活動中的對話逐字稿。請仔細閱讀整份逐字稿，找出這位學生**反覆出現的表達習慣**（不是偶爾一次的口誤），特別關注：
- 中式英文直譯（Chinglish）
- 反覆使用的不自然句型或用詞
- 可以用更道地說法替代的高頻表達

你的核心任務是挑出 **3 個最值得改進的高頻問題**，每個問題都要：
1. 列出學生在對話中實際說過的 2-3 個原句
2. 針對每個原句，提供一個母語人士會使用的自然替代說法
3. 用一句話說明為什麼替代說法更好

原則：
- 替代說法必須是日常口語中**真正常用**的，不要書面語或過於正式的表達
- 優先挑「改掉一個習慣就能大幅進步」的問題，而非瑣碎的文法錯誤
- 所有分析和說明用繁體中文，英文原句和替代說法保持英文

回傳嚴格的 JSON 格式（不要包含 markdown code block）：

{
  "strengths": ["這位學生做得好的地方，2-3 項"],
  "top_3_fixes": [
    {
      "habit": "用一句中文描述這個壞習慣",
      "frequency": "在逐字稿中大約出現幾次",
      "examples": [
        {
          "original": "學生說的原句",
          "better": "母語人士的自然說法"
        },
        {
          "original": "學生說的另一個原句",
          "better": "母語人士的自然說法"
        }
      ],
      "why": "一句話說明為什麼替代說法更好"
    }
  ],
  "summary": "整體鼓勵與下次活動前可以練習的方向（2-3句）"
}

逐字稿：
`

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ─── 1. 驗證 JWT ───
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return jsonResponse({ error: 'Missing authorization header' }, 401)
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const jwt = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(jwt)
    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    // ─── 2. 接收參數 ───
    const { booking_id } = await req.json()
    if (!booking_id) {
      return jsonResponse({ error: 'booking_id is required' }, 400)
    }

    // ─── 3. 查詢錄音段落 ───
    const { data: segments, error: segError } = await supabaseClient
      .from('recording_segments')
      .select('*')
      .eq('booking_id', booking_id)
      .eq('user_id', user.id)
      .order('sequence', { ascending: true })

    if (segError) {
      console.error('查詢 recording_segments 失敗:', segError)
      return jsonResponse({ error: 'Failed to query recording segments' }, 500)
    }

    if (!segments || segments.length === 0) {
      return jsonResponse({ error: 'No recording segments found for this booking' }, 404)
    }

    // ─── 4. 建立/更新 learning_report ───
    const totalDuration = segments.reduce((sum: number, s: any) => sum + s.duration_seconds, 0)

    // 用 upsert：如果已存在就更新（支援重試）
    const { data: report, error: reportError } = await supabaseClient
      .from('learning_reports')
      .upsert({
        booking_id,
        user_id: user.id,
        status: 'transcribing',
        transcript: null,
        analysis: null,
        error_message: null,
        total_duration_seconds: totalDuration,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'booking_id' })
      .select('id')
      .single()

    if (reportError) {
      console.error('建立 learning_report 失敗:', reportError)
      return jsonResponse({ error: 'Failed to create learning report' }, 500)
    }

    const reportId = report.id

    // ─── 5. Whisper 語音轉文字 ───
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      await updateReportStatus(supabaseClient, reportId, 'failed', 'OPENAI_API_KEY not configured')
      return jsonResponse({ error: 'OPENAI_API_KEY not configured' }, 500)
    }

    const transcripts: string[] = []

    for (const segment of segments) {
      try {
        // 從 Storage 下載音檔
        const { data: fileData, error: downloadError } = await supabaseClient
          .storage
          .from('voice-recordings')
          .download(segment.storage_path)

        if (downloadError || !fileData) {
          throw new Error(`下載音檔失敗: ${segment.storage_path} - ${downloadError?.message}`)
        }

        // 呼叫 Whisper API
        const formData = new FormData()
        formData.append('file', fileData, `segment_${segment.sequence}.m4a`)
        formData.append('model', 'whisper-1')
        formData.append('language', 'en')
        formData.append('response_format', 'text')

        const whisperRes = await fetch(WHISPER_API_URL, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${openaiApiKey}` },
          body: formData,
        })

        if (!whisperRes.ok) {
          const errText = await whisperRes.text()
          throw new Error(`Whisper API 錯誤 (${whisperRes.status}): ${errText}`)
        }

        const text = await whisperRes.text()
        transcripts.push(text.trim())
      } catch (err) {
        console.error(`段落 ${segment.sequence} 轉文字失敗:`, err)
        await updateReportStatus(supabaseClient, reportId, 'failed', `Whisper 失敗 (段落 ${segment.sequence}): ${err instanceof Error ? err.message : String(err)}`)
        return jsonResponse({ error: `Transcription failed for segment ${segment.sequence}` }, 500)
      }
    }

    const fullTranscript = transcripts.join('\n\n')

    // 更新逐字稿，進入分析階段
    await supabaseClient
      .from('learning_reports')
      .update({
        transcript: fullTranscript,
        status: 'analyzing',
        updated_at: new Date().toISOString(),
      })
      .eq('id', reportId)

    // ─── 6. Claude Opus 4.6 分析 ───
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      await updateReportStatus(supabaseClient, reportId, 'failed', 'ANTHROPIC_API_KEY not configured')
      return jsonResponse({ error: 'ANTHROPIC_API_KEY not configured' }, 500)
    }

    try {
      const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: 'claude-opus-4-6-20250219',
          max_tokens: 4096,
          messages: [
            {
              role: 'user',
              content: CLAUDE_PROMPT + fullTranscript,
            },
          ],
        }),
      })

      if (!claudeRes.ok) {
        const errText = await claudeRes.text()
        throw new Error(`Claude API 錯誤 (${claudeRes.status}): ${errText}`)
      }

      const claudeData = await claudeRes.json()
      const analysisText = claudeData.content?.[0]?.text

      if (!analysisText) {
        throw new Error('Claude 回傳內容為空')
      }

      // 解析 JSON
      const analysis = JSON.parse(analysisText)

      // 驗證必要欄位
      if (!analysis.strengths || !analysis.top_3_fixes || !analysis.summary) {
        throw new Error('Claude 回傳的 JSON 格式不正確，缺少必要欄位')
      }

      // ─── 7. 寫入結果 ───
      await supabaseClient
        .from('learning_reports')
        .update({
          analysis,
          status: 'completed',
          updated_at: new Date().toISOString(),
        })
        .eq('id', reportId)

      return jsonResponse({ ok: true, report_id: reportId })

    } catch (err) {
      console.error('Claude 分析失敗:', err)
      await updateReportStatus(
        supabaseClient,
        reportId,
        'failed',
        `Claude 分析失敗: ${err instanceof Error ? err.message : String(err)}`
      )
      return jsonResponse({ error: 'AI analysis failed' }, 500)
    }

  } catch (err) {
    console.error('未預期的錯誤:', err)
    return jsonResponse({
      error: err instanceof Error ? err.message : 'Unknown error',
    }, 500)
  }
})

async function updateReportStatus(
  client: any,
  reportId: string,
  status: string,
  errorMessage: string
) {
  await client
    .from('learning_reports')
    .update({
      status,
      error_message: errorMessage,
      updated_at: new Date().toISOString(),
    })
    .eq('id', reportId)
}
