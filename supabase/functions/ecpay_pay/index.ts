import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';
function ecpayEncodeForCheckMac(raw) {
  // ECPay algorithm: URL encode then lower-case then replace %20 -> +, and some special replacements.
  // We'll do: encodeURIComponent then toLowerCase, then replacements per common ECPay spec implementations.
  return encodeURIComponent(raw).toLowerCase().replace(/%20/g, '+').replace(/%21/g, '!').replace(/%28/g, '(').replace(/%29/g, ')').replace(/%2a/g, '*').replace(/%2d/g, '-').replace(/%2e/g, '.').replace(/%5f/g, '_');
}
function formatEcpayDate(date) {
  const yyyy = date.getFullYear();
  const MM = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  const HH = String(date.getHours()).padStart(2, '0');
  const mm = String(date.getMinutes()).padStart(2, '0');
  const ss = String(date.getSeconds()).padStart(2, '0');
  // 重點：用 / 而不是 -
  return `${yyyy}/${MM}/${dd} ${HH}:${mm}:${ss}`;
}
async function sha256HexUpper(input) {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', data);
  const bytes = new Uint8Array(hash);
  const hex = Array.from(bytes).map((b)=>b.toString(16).padStart(2, '0')).join('');
  return hex.toUpperCase();
}
/*
async function computeCheckMacValue(params: Record<string, string>, hashKey: string, hashIv: string): Promise<string> {
  const keys = Object.keys(params).filter((k) => k !== 'CheckMacValue').sort((a, b) => a.localeCompare(b))
  const raw = keys.map((k) => `${k}=${params[k]}`).join('&')
  const toHash = `HashKey=${hashKey}&${raw}&HashIV=${hashIv}`
  const encoded = ecpayEncodeForCheckMac(toHash)
  return await sha256HexUpper(encoded)
}
*/ async function computeCheckMacValue(params, hashKey, hashIv) {
  const keys = Object.keys(params).filter((k)=>k !== 'CheckMacValue').sort() // 用內建 sort，純 ASCII 夠用
  ;
  const raw = keys.map((k)=>`${k}=${params[k]}`).join('&');
  const toHash = `HashKey=${hashKey}&${raw}&HashIV=${hashIv}`;
  const encoded = ecpayEncodeForCheckMac(toHash);
  console.log('ECPAY RAW   =', toHash);
  console.log('ECPAY ENCODED =', encoded);
  const data = new TextEncoder().encode(encoded);
  const hash = await crypto.subtle.digest('SHA-256', data);
  const bytes = new Uint8Array(hash);
  const mac = Array.from(bytes).map((b)=>b.toString(16).padStart(2, '0')).join('').toUpperCase();
  console.log('ECPAY MAC   =', mac);
  return mac;
}
function htmlAutoPost(action, fields) {
  const inputs = Object.entries(fields).map(([k, v])=>`<input type="hidden" name="${k}" value="${String(v).replace(/"/g, '&quot;')}" />`).join('\n');
  return `<!doctype html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body>
  <form id="f" method="post" action="${action}">
    ${inputs}
  </form>
  <script>document.getElementById('f').submit();</script>
</body>
</html>`;
}
Deno.serve(async (req)=>{
  const url = new URL(req.url);
  const token = url.searchParams.get('token');
  if (!token) return new Response('Missing token', {
    status: 400
  });
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
  const hashKey = Deno.env.get('ECPAY_HASH_KEY');
  const hashIv = Deno.env.get('ECPAY_HASH_IV');
  const merchantId = Deno.env.get('ECPAY_MERCHANT_ID');
  const env = (Deno.env.get('ECPAY_ENV') ?? 'stage').toLowerCase();
  const tokenHash = await sha256HexUpper(token);
  const { data: order, error } = await supabaseAdmin.from('orders').select('id,merchant_trade_no,total_amount,title_snapshot,status,checkout_token_expires_at').eq('checkout_token_hash', tokenHash).single();
  if (error || !order) return new Response('Invalid token', {
    status: 400
  });
  if (order.status !== 'pending') return new Response('Order not payable', {
    status: 400
  });
  if (order.checkout_token_expires_at && new Date(order.checkout_token_expires_at).getTime() < Date.now()) {
    return new Response('Token expired', {
      status: 400
    });
  }
  const returnUrl = Deno.env.get('ECPAY_RETURN_URL');
  const orderResultUrl = Deno.env.get('ECPAY_ORDER_RESULT_URL');
  const merchantTradeDate = formatEcpayDate(new Date());
  const params = {
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
    EncryptType: '1'
  };
  params.CheckMacValue = await computeCheckMacValue(params, hashKey, hashIv);
  const gateway = env === 'prod' ? 'https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5' : 'https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5';
  const html = htmlAutoPost(gateway, params);
  // ✅ 改成直接回傳 HTML，而不是 JSON
  return new Response(html, {
    status: 200,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store'
    }
  });
/* 使用 WebView 時留下來的
  // ✅ 重點：只回 JSON，裡面塞 html 字串
  return new Response(
    JSON.stringify({ html }),
    {
      status: 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    },
  )
  */ });
