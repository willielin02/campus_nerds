import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';
function sha256HexUpper(input) {
  const data = new TextEncoder().encode(input);
  return crypto.subtle.digest('SHA-256', data).then((hash)=>{
    const bytes = new Uint8Array(hash);
    const hex = Array.from(bytes).map((b)=>b.toString(16).padStart(2, '0')).join('');
    return hex.toUpperCase();
  });
}
function toEcpayUrlEncoded(str) {
  // encodeURIComponent then ECPay's special replacements are applied later in CheckMacValue builder
  return encodeURIComponent(str);
}
async function computeTokenHash(token) {
  return await sha256HexUpper(token);
}
function randomToken(len = 32) {
  const bytes = crypto.getRandomValues(new Uint8Array(len));
  // base64url-ish
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}
function merchantTradeNoFromOrderId(orderId) {
  // ECPay MerchantTradeNo max length 20, only [0-9A-Za-z]
  // Use first 20 chars of a safe base (orderId without dashes)
  const s = orderId.replace(/-/g, '').slice(0, 20);
  return s;
}
Deno.serve(async (req)=>{
  if (req.method !== 'POST') return new Response('Method not allowed', {
    status: 405
  });
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  // Use user JWT from Authorization header (Supabase will verify JWT for this function)
  const authHeader = req.headers.get('Authorization') ?? '';
  const supabaseAuthed = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY'), {
    global: {
      headers: {
        Authorization: authHeader
      }
    }
  });
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
  const { data: userData, error: userErr } = await supabaseAuthed.auth.getUser();
  if (userErr || !userData?.user) return new Response('Unauthorized', {
    status: 401
  });
  const body = await req.json().catch(()=>null);
  if (!body?.product_id) return new Response('Missing product_id', {
    status: 400
  });
  // 1) Load product
  const { data: product, error: prodErr } = await supabaseAdmin.from('products').select('id,ticket_type,pack_size,price_twd,title,is_active').eq('id', body.product_id).single();
  if (prodErr || !product || !product.is_active) {
    return new Response('Invalid product', {
      status: 400
    });
  }
  // 2) Create order (pending)
  const orderId = crypto.randomUUID();
  const merchantTradeNo = merchantTradeNoFromOrderId(orderId);
  const checkoutToken = randomToken(24);
  const checkoutTokenHash = await computeTokenHash(checkoutToken);
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString() // 15 min
  ;
  const totalAmount = product.price_twd;
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
    checkout_token_expires_at: expiresAt
  });
  if (insErr) return new Response(`Create order failed: ${insErr.message}`, {
    status: 500
  });
  // 3) Return checkout URL for WebView
  // You can also bind a custom domain later; for now use Supabase function URL directly.
  const checkoutUrl = `${supabaseUrl}/functions/v1/ecpay_pay?token=${encodeURIComponent(checkoutToken)}`;
  return new Response(JSON.stringify({
    order_id: orderId,
    checkout_url: checkoutUrl,
    checkout_token: checkoutToken
  }), {
    headers: {
      'Content-Type': 'application/json'
    }
  });
});
