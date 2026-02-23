import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'

const PAY_SITE_URL = Deno.env.get('PAY_SITE_URL') ?? 'https://pay.campusnerds.app'

function sha256HexUpper(input: string): Promise<string> {
  const data = new TextEncoder().encode(input)
  return crypto.subtle.digest('SHA-256', data).then((hash) => {
    const bytes = new Uint8Array(hash)
    const hex = Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('')
    return hex.toUpperCase()
  })
}

async function computeTokenHash(token: string): Promise<string> {
  return await sha256HexUpper(token)
}

function randomToken(len = 32): string {
  const bytes = crypto.getRandomValues(new Uint8Array(len))
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
}

function merchantTradeNoFromOrderId(orderId: string): string {
  const s = orderId.replace(/-/g, '').slice(0, 20)
  return s
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const authHeader = req.headers.get('Authorization') ?? ''
  const token = authHeader.replace('Bearer ', '')

  const supabaseAuthed = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  })

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  const { data: userData, error: userErr } = await supabaseAuthed.auth.getUser(token)
  if (userErr || !userData?.user) return new Response('Unauthorized', { status: 401 })

  const body = await req.json().catch(() => null)
  if (!body?.product_id) return new Response('Missing product_id', { status: 400 })

  const { data: product, error: prodErr } = await supabaseAdmin
    .from('products')
    .select('id,ticket_type,pack_size,price_twd,title,is_active')
    .eq('id', body.product_id)
    .single()

  if (prodErr || !product || !product.is_active) {
    return new Response('Invalid product', { status: 400 })
  }

  const orderId = crypto.randomUUID()
  const merchantTradeNo = merchantTradeNoFromOrderId(orderId)

  const checkoutToken = randomToken(24)
  const checkoutTokenHash = await computeTokenHash(checkoutToken)
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString()

  const totalAmount = product.price_twd

  const { error: insErr } = await supabaseAdmin.from('orders').insert({
    id: orderId,
    user_id: userData.user.id,
    product_id: product.id,
    merchant_trade_no: merchantTradeNo,
    ticket_type_snapshot: product.ticket_type,
    pack_size_snapshot: product.pack_size,
    title_snapshot: product.title,
    price_snapshot_twd: product.price_twd,
    total_amount: totalAmount,
    currency: 'TWD',
    status: 'pending',
    checkout_token_hash: checkoutTokenHash,
    checkout_token_expires_at: expiresAt,
  })

  if (insErr) return new Response(`Create order failed: ${insErr.message}`, { status: 500 })

  // Extract project ref from SUPABASE_URL (e.g. "https://abcdef.supabase.co" → "abcdef")
  const projectRef = new URL(supabaseUrl).hostname.split('.')[0]

  // Point to the Cloudflare Pages bootstrap page, which will POST to ecpay_pay
  const checkoutUrl = `${PAY_SITE_URL}/checkout.html?token=${encodeURIComponent(checkoutToken)}&ref=${projectRef}`

  return new Response(
    JSON.stringify({
      order_id: orderId,
      checkout_url: checkoutUrl,
      checkout_token: checkoutToken,
    }),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
