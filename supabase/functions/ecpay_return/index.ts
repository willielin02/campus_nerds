import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'

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

async function sha256HexUpper(input: string): Promise<string> {
  const data = new TextEncoder().encode(input)
  const hash = await crypto.subtle.digest('SHA-256', data)
  const bytes = new Uint8Array(hash)
  const hex = Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('')
  return hex.toUpperCase()
}

async function computeCheckMacValue(params: Record<string, string>, hashKey: string, hashIv: string): Promise<string> {
  const keys = Object.keys(params).filter((k) => k !== 'CheckMacValue').sort((a, b) => a.localeCompare(b))
  const raw = keys.map((k) => `${k}=${params[k]}`).join('&')
  const toHash = `HashKey=${hashKey}&${raw}&HashIV=${hashIv}`
  const encoded = ecpayEncodeForCheckMac(toHash)
  return await sha256HexUpper(encoded)
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  const text = await req.text()
  const form = new URLSearchParams(text)
  const payload: Record<string, string> = {}
  for (const [k, v] of form.entries()) payload[k] = v

  const hashKey = Deno.env.get('ECPAY_HASH_KEY')!
  const hashIv = Deno.env.get('ECPAY_HASH_IV')!

  const receivedMac = payload.CheckMacValue ?? ''
  const expectedMac = await computeCheckMacValue(payload, hashKey, hashIv)
  if (receivedMac !== expectedMac) return new Response('0|FAIL', { status: 200 })

  const merchantTradeNo = payload.MerchantTradeNo
  const rtnCode = payload.RtnCode // 1 means paid for Credit typically; confirm in your ECPay logs

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  const { data: order, error: orderErr } = await supabaseAdmin
    .from('orders')
    .select('id,user_id,status,ticket_type_snapshot,pack_size_snapshot')
    .eq('merchant_trade_no', merchantTradeNo)
    .single()

  if (orderErr || !order) return new Response('0|FAIL', { status: 200 })

  // write raw payment log (idempotent enough for now)
  await supabaseAdmin.from('ecpay_payments').upsert({
    order_id: order.id,
    trade_no: payload.TradeNo ?? null,
    rtn_code: payload.RtnCode ? Number(payload.RtnCode) : null,
    rtn_msg: payload.RtnMsg ?? null,
    trade_amt: payload.TradeAmt ? Number(payload.TradeAmt) : null,
    paid_at: payload.PaymentDate ? new Date(payload.PaymentDate).toISOString() : new Date().toISOString(),
    check_mac_value: receivedMac,
    raw: payload,
  }, { onConflict: 'order_id' })

  // If success and not already paid -> mark paid + grant tickets
  if (String(rtnCode) === '1' && order.status !== 'paid') {
    await supabaseAdmin.from('orders').update({
      status: 'paid',
      paid_at: new Date().toISOString(),
    }).eq('id', order.id)

    const deltaStudy = order.ticket_type_snapshot === 'study' ? order.pack_size_snapshot : 0
    const deltaGames = order.ticket_type_snapshot === 'games' ? order.pack_size_snapshot : 0

    await supabaseAdmin.from('ticket_ledger').insert({
      user_id: order.user_id,
      order_id: order.id,
      delta_study: deltaStudy,
      delta_games: deltaGames,
      reason: 'purchase_credit',
    })
  }

  // ECPay requires exactly "1|OK" on success notifications
  return new Response('1|OK', { status: 200 })
})
