import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'

const PAY_SITE_URL = Deno.env.get('PAY_SITE_URL') ?? 'https://pay.campusnerds.app'

function ecpayEncodeForCheckMac(raw: string): string {
  return encodeURIComponent(raw)
    .toLowerCase()
    .replace(/%20/g, '+')
    .replace(/%21/g, '!')
    .replace(/%28/g, '(')
    .replace(/%29/g, ')')
    .replace(/%2a/g, '*')
    .replace(/%2d/g, '-')
    .replace(/%2e/g, '.')
    .replace(/%5f/g, '_')
}

function formatEcpayDate(date: Date): string {
  const yyyy = date.getFullYear()
  const MM = String(date.getMonth() + 1).padStart(2, '0')
  const dd = String(date.getDate()).padStart(2, '0')
  const HH = String(date.getHours()).padStart(2, '0')
  const mm = String(date.getMinutes()).padStart(2, '0')
  const ss = String(date.getSeconds()).padStart(2, '0')
  return `${yyyy}/${MM}/${dd} ${HH}:${mm}:${ss}`
}

async function computeCheckMacValue(
  params: Record<string, string>,
  hashKey: string,
  hashIv: string
): Promise<string> {
  const keys = Object.keys(params)
    .filter((k) => k !== 'CheckMacValue')
    .sort()

  const raw = keys.map((k) => `${k}=${params[k]}`).join('&')
  const toHash = `HashKey=${hashKey}&${raw}&HashIV=${hashIv}`
  const encoded = ecpayEncodeForCheckMac(toHash)

  const data = new TextEncoder().encode(encoded)
  const hash = await crypto.subtle.digest('SHA-256', data)
  const bytes = new Uint8Array(hash)
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase()
}

async function sha256HexUpper(input: string): Promise<string> {
  const data = new TextEncoder().encode(input)
  const hash = await crypto.subtle.digest('SHA-256', data)
  const bytes = new Uint8Array(hash)
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('').toUpperCase()
}

function htmlAutoPost(action: string, fields: Record<string, string>): string {
  const inputs = Object.entries(fields)
    .map(([k, v]) => `<input type="hidden" name="${k}" value="${String(v).replace(/"/g, '&quot;')}" />`)
    .join('\n    ')
  return `<!doctype html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body>
  <form id="f" method="post" action="${action}">
    ${inputs}
  </form>
  <script>document.getElementById('f').submit();</script>
</body>
</html>`
}

Deno.serve(async (req) => {
  const url = new URL(req.url)

  // GET: redirect to the pay site bootstrap page (which will POST back here)
  if (req.method === 'GET') {
    const token = url.searchParams.get('token')
    if (!token) return new Response('Missing token', { status: 400 })
    const redirectUrl = `${PAY_SITE_URL}/checkout.html?token=${encodeURIComponent(token)}`
    return Response.redirect(redirectUrl, 302)
  }

  // Only accept POST from here on
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  // Read token from POST form body
  const body = await req.text()
  const form = new URLSearchParams(body)
  const token = form.get('token')
  if (!token) return new Response('Missing token', { status: 400 })

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  const hashKey = Deno.env.get('ECPAY_HASH_KEY')!
  const hashIv = Deno.env.get('ECPAY_HASH_IV')!
  const merchantId = Deno.env.get('ECPAY_MERCHANT_ID')!
  const env = (Deno.env.get('ECPAY_ENV') ?? 'prod').toLowerCase()

  const tokenHash = await sha256HexUpper(token)

  const { data: order, error } = await supabaseAdmin
    .from('orders')
    .select('id,merchant_trade_no,total_amount,title_snapshot,status,checkout_token_expires_at')
    .eq('checkout_token_hash', tokenHash)
    .single()

  if (error || !order) return new Response('Invalid token', { status: 400 })
  if (order.status !== 'pending') return new Response('Order not payable', { status: 400 })
  if (order.checkout_token_expires_at && new Date(order.checkout_token_expires_at).getTime() < Date.now()) {
    return new Response('Token expired', { status: 400 })
  }

  const returnUrl = Deno.env.get('ECPAY_RETURN_URL')!
  const orderResultUrl = Deno.env.get('ECPAY_ORDER_RESULT_URL')!

  const merchantTradeDate = formatEcpayDate(new Date())

  const params: Record<string, string> = {
    MerchantID: merchantId,
    MerchantTradeNo: order.merchant_trade_no,
    MerchantTradeDate: merchantTradeDate,
    PaymentType: 'aio',
    TotalAmount: String(order.total_amount),
    TradeDesc: 'Campus Nerds Ticket',
    ItemName: order.title_snapshot,
    ReturnURL: returnUrl,
    OrderResultURL: orderResultUrl,
    ChoosePayment: 'Credit',
    EncryptType: '1',
  }

  params.CheckMacValue = await computeCheckMacValue(params, hashKey, hashIv)

  const gateway =
    env === 'prod'
      ? 'https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5'
      : 'https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5'

  const html = htmlAutoPost(gateway, params)

  // POST responses are NOT rewritten by Supabase (only GET text/html is).
  return new Response(html, {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  })
})
