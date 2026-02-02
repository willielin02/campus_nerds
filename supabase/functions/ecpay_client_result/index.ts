import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
Deno.serve(async (req)=>{
  if (req.method !== 'POST') return new Response('Method not allowed', {
    status: 405
  });
  const text = await req.text();
  const form = new URLSearchParams(text);
  const merchantTradeNo = form.get('MerchantTradeNo') ?? '';
  const rtnCode = form.get('RtnCode') ?? '';
  const rtnMsg = form.get('RtnMsg') ?? '';
  // Redirect to your real result page (GET), so it can be a normal web page.
  const redirectUrl = new URL('https://pay.campusnerds.app/ecpay/result');
  redirectUrl.searchParams.set('MerchantTradeNo', merchantTradeNo);
  redirectUrl.searchParams.set('RtnCode', rtnCode);
  redirectUrl.searchParams.set('RtnMsg', rtnMsg);
  return Response.redirect(redirectUrl.toString(), 302);
});
