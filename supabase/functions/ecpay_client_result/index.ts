import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

const PAY_SITE_URL = Deno.env.get('PAY_SITE_URL') ?? 'https://pay.campusnerds.app'

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  const text = await req.text()
  const form = new URLSearchParams(text)

  const merchantTradeNo = form.get('MerchantTradeNo') ?? ''
  const rtnCode = form.get('RtnCode') ?? ''
  const rtnMsg = form.get('RtnMsg') ?? ''

  // Redirect to the payment result page hosted on Cloudflare Pages
  const redirectUrl = new URL(`${PAY_SITE_URL}/ecpay/result`)
  redirectUrl.searchParams.set('MerchantTradeNo', merchantTradeNo)
  redirectUrl.searchParams.set('RtnCode', rtnCode)
  redirectUrl.searchParams.set('RtnMsg', rtnMsg)

  return Response.redirect(redirectUrl.toString(), 302)
})
