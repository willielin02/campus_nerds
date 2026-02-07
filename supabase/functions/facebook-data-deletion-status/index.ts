// Supabase Edge Function: facebook-data-deletion-status
// Returns the status of a Facebook data deletion request
// This URL is provided to Facebook and users can check their deletion status

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const confirmationCode = url.searchParams.get('code')

    if (!confirmationCode) {
      return new Response(renderHtml('錯誤', '缺少確認碼'), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' }
      })
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Look up the deletion request
    const { data: request, error } = await supabaseClient
      .from('fb_data_deletion_requests')
      .select('*')
      .eq('confirmation_code', confirmationCode)
      .maybeSingle()

    if (error || !request) {
      return new Response(renderHtml(
        '查無資料',
        `找不到確認碼為 ${confirmationCode} 的資料刪除請求。<br><br>這可能是因為：<br>• 確認碼不正確<br>• 請求尚未處理`
      ), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' }
      })
    }

    const statusText = request.status === 'completed'
      ? '✅ 已完成 - 您的 Facebook 相關資料已從我們的系統中刪除。'
      : request.status === 'no_user_found'
      ? '✅ 已完成 - 我們的系統中未找到與您 Facebook 帳號相關的資料。'
      : `處理中 - 狀態: ${request.status}`

    const createdAt = new Date(request.created_at).toLocaleString('zh-TW', {
      timeZone: 'Asia/Taipei'
    })

    return new Response(renderHtml(
      '資料刪除狀態',
      `<strong>確認碼：</strong>${confirmationCode}<br><br>
       <strong>狀態：</strong>${statusText}<br><br>
       <strong>請求時間：</strong>${createdAt}<br><br>
       如有任何問題，請聯繫 support@campusnerds.app`
    ), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' }
    })

  } catch (error) {
    console.error('Error:', error)
    return new Response(renderHtml('錯誤', '處理請求時發生錯誤'), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' }
    })
  }
})

function renderHtml(title: string, content: string): string {
  return `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - Campus Nerds</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      color: #e0e0e0;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    .container {
      background: rgba(255, 255, 255, 0.05);
      border-radius: 16px;
      padding: 40px;
      max-width: 500px;
      width: 100%;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    h1 {
      color: #fff;
      margin-top: 0;
      font-size: 24px;
    }
    .logo {
      font-size: 32px;
      margin-bottom: 20px;
    }
    .content {
      line-height: 1.8;
      color: #b0b0b0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">📚 Campus Nerds</div>
    <h1>${title}</h1>
    <div class="content">${content}</div>
  </div>
</body>
</html>`
}
