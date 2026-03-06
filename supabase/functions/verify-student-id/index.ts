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

const CONFIDENCE_THRESHOLD = 80

const CLAUDE_PROMPT = `你是一位專業的學生證辨識系統。請分析這張學生證照片，並提取以下資訊。

任務：
1. 辨識這是否是一張有效的學生證（大學學生證、學生身分證明、在學證明）
2. 提取大學名稱、學生姓名、學號
3. 評估照片品質和真實性

台灣大學列表（請從中比對，大學名稱必須完全一致）：
{UNIVERSITY_LIST}

回傳嚴格的 JSON 格式（不要包含 markdown code block）：
{
  "is_student_id": true/false,
  "university_name": "辨識到的大學名稱（必須與上方列表中的名稱完全一致，若無法比對則填 null）",
  "student_name": "學生姓名（若無法辨識則填 null）",
  "student_id_number": "學號（若無法辨識則填 null）",
  "confidence": 0-100 的整數,
  "issues": ["問題列表，如：照片模糊、文字被遮擋、疑似翻拍、非學生證等"],
  "reasoning": "你的推理過程簡述"
}

重要：
- 只回傳 JSON，不要有其他文字
- university_name 請使用該大學的正式中文全名，必須與列表完全一致
- confidence 代表你對這是有效學生證的信心程度
- 如果無法辨識或不是學生證，confidence 設為 0
- issues 陣列在沒有問題時設為空陣列 []
`

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ─── 1. JWT 驗證 ───
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
    const { storage_path } = await req.json()
    if (!storage_path) {
      return jsonResponse({ error: 'storage_path is required' }, 400)
    }

    // ─── 3. 建立 pending 記錄 ───
    const { data: verification, error: insertError } = await supabaseClient
      .from('student_id_verifications')
      .insert({
        user_id: user.id,
        storage_path,
        status: 'pending',
      })
      .select('id')
      .single()

    if (insertError || !verification) {
      console.error('建立驗證記錄失敗:', insertError)
      return jsonResponse({ error: 'Failed to create verification record' }, 500)
    }

    const verificationId = verification.id

    // ─── 4. 從 Storage 下載照片 ───
    const { data: fileData, error: downloadError } = await supabaseClient
      .storage
      .from('student-id-uploads')
      .download(storage_path)

    if (downloadError || !fileData) {
      console.error('下載照片失敗:', downloadError)
      await supabaseClient.from('student_id_verifications')
        .update({
          status: 'manual_review',
          review_notes: '無法下載照片',
        })
        .eq('id', verificationId)
      return jsonResponse({
        status: 'pending_review',
        message: '照片已提交，我們會在 1-2 個工作天內完成人工審核，届時將以推播通知告知您結果。',
      })
    }

    // ─── 5. 查詢所有大學名稱 ───
    const { data: universities } = await supabaseClient
      .from('universities')
      .select('id, name, code')
      .order('name')

    const universityList = (universities || [])
      .map((u: { name: string }) => u.name)
      .join('、')

    // ─── 6. 照片轉 base64 ───
    const arrayBuffer = await fileData.arrayBuffer()
    const bytes = new Uint8Array(arrayBuffer)
    let binary = ''
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    const base64Image = btoa(binary)

    // 偵測 MIME type
    const ext = storage_path.split('.').pop()?.toLowerCase() || 'jpg'
    const mimeType = ext === 'png' ? 'image/png'
      : ext === 'webp' ? 'image/webp'
      : 'image/jpeg'

    // ─── 7. 呼叫 Claude Sonnet 4.6 Vision API ───
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      console.error('ANTHROPIC_API_KEY 未設定')
      await supabaseClient.from('student_id_verifications')
        .update({
          status: 'manual_review',
          review_notes: 'ANTHROPIC_API_KEY 未設定',
        })
        .eq('id', verificationId)
      return jsonResponse({
        status: 'pending_review',
        message: '照片已提交，我們會在 1-2 個工作天內完成人工審核，届時將以推播通知告知您結果。',
      })
    }

    const prompt = CLAUDE_PROMPT.replace('{UNIVERSITY_LIST}', universityList)

    let aiResult: {
      is_student_id: boolean
      university_name: string | null
      student_name: string | null
      student_id_number: string | null
      confidence: number
      issues: string[]
      reasoning: string
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
          model: 'claude-sonnet-4-6-20250514',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: mimeType,
                    data: base64Image,
                  },
                },
                {
                  type: 'text',
                  text: prompt,
                },
              ],
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
      if (!analysisText) throw new Error('Claude 回傳內容為空')

      aiResult = JSON.parse(analysisText)
    } catch (err) {
      // AI 失敗 -> fallback 到人工審核
      console.error('Claude 分析失敗:', err)
      await supabaseClient.from('student_id_verifications')
        .update({
          status: 'manual_review',
          review_notes: `AI 分析失敗: ${err instanceof Error ? err.message : String(err)}`,
        })
        .eq('id', verificationId)
      return jsonResponse({
        status: 'pending_review',
        message: '照片已提交，我們會在 1-2 個工作天內完成人工審核，届時將以推播通知告知您結果。',
      })
    }

    // ─── 8. 比對大學 ───
    let matchedUniversity: { id: string; name: string; code: string } | null = null
    let matchedDomain: string | null = null

    if (aiResult.university_name && universities) {
      matchedUniversity = universities.find(
        (u: { name: string }) => u.name === aiResult.university_name
      ) || null

      if (matchedUniversity) {
        const { data: domainRow } = await supabaseClient
          .from('university_email_domains')
          .select('domain')
          .eq('university_id', matchedUniversity.id)
          .limit(1)
          .single()
        matchedDomain = domainRow?.domain || null
      }
    }

    // ─── 9. 決定結果 ───
    const confidence = aiResult.confidence || 0
    const isAutoVerify = confidence >= CONFIDENCE_THRESHOLD
      && aiResult.is_student_id === true
      && matchedUniversity != null
      && matchedDomain != null
      && (!aiResult.issues || aiResult.issues.length === 0)

    // 更新 AI 分析結果
    await supabaseClient
      .from('student_id_verifications')
      .update({
        ai_university_name: aiResult.university_name || null,
        ai_student_name: aiResult.student_name || null,
        ai_student_id_number: aiResult.student_id_number || null,
        ai_confidence: confidence,
        ai_issues: aiResult.issues || [],
        ai_raw_response: aiResult,
        ai_model: 'claude-sonnet-4-6-20250514',
        matched_university_id: matchedUniversity?.id || null,
        matched_domain: matchedDomain,
        status: isAutoVerify ? 'auto_verified' : 'manual_review',
        reviewed_by: isAutoVerify ? 'ai' : null,
        reviewed_at: isAutoVerify ? new Date().toISOString() : null,
      })
      .eq('id', verificationId)

    if (isAutoVerify) {
      // ─── 10a. 自動驗證成功 ───
      const prefix = user.id.replace(/-/g, '').substring(0, 8)
      const aiEmail = `ai.${prefix}@${matchedDomain}`

      // 停用現有的 active email
      await supabaseClient
        .from('user_school_emails')
        .update({
          is_active: false,
          released_at: new Date().toISOString(),
          released_reason: 'ai_verification_replacement',
        })
        .eq('user_id', user.id)
        .eq('is_active', true)

      // 插入新的 verified record
      const { data: emailRecord, error: emailError } = await supabaseClient
        .from('user_school_emails')
        .insert({
          user_id: user.id,
          school_email: aiEmail,
          status: 'verified',
          verified_at: new Date().toISOString(),
          is_active: true,
          verification_method: 'ai',
        })
        .select('id')
        .single()

      if (emailError) {
        // email 衝突 -> 轉人工審核
        console.error('建立 school email 失敗:', emailError)
        await supabaseClient.from('student_id_verifications')
          .update({
            status: 'manual_review',
            review_notes: `建立 email 失敗: ${emailError.message}`,
          })
          .eq('id', verificationId)
        return jsonResponse({
          status: 'pending_review',
          message: '照片已提交，我們會在 1-2 個工作天內完成人工審核，届時將以推播通知告知您結果。',
        })
      }

      // 更新 school_email_id
      await supabaseClient.from('student_id_verifications')
        .update({ school_email_id: emailRecord.id })
        .eq('id', verificationId)

      return jsonResponse({
        status: 'verified',
        university_name: matchedUniversity!.name,
      })

    } else {
      // ─── 10b. 需要人工審核（已由步驟 9 更新 status 為 manual_review）───
      return jsonResponse({
        status: 'pending_review',
        message: '照片已提交，我們會在 1-2 個工作天內完成人工審核，届時將以推播通知告知您結果。',
      })
    }

  } catch (err) {
    console.error('未預期的錯誤:', err)
    return jsonResponse({
      error: err instanceof Error ? err.message : 'Unknown error',
    }, 500)
  }
})

