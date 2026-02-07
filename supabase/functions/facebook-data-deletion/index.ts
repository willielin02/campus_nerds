// Supabase Edge Function: facebook-data-deletion
// Handles Facebook Data Deletion Callback requests
// https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback
//
// When a user removes the app from their Facebook settings,
// Facebook sends a signed_request to this endpoint.
// We must:
// 1. Verify the signature using FB_APP_SECRET
// 2. Delete/clear the user's Facebook-related data
// 3. Return a confirmation_code and status_url

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { decode as base64Decode } from "https://deno.land/std@0.168.0/encoding/base64.ts"
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const FB_APP_SECRET = Deno.env.get('FB_APP_SECRET') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

interface SignedRequestPayload {
  user_id: string
  algorithm: string
  issued_at: number
}

// Base64 URL decode (Facebook uses URL-safe base64)
function base64UrlDecode(input: string): Uint8Array {
  // Replace URL-safe characters with standard base64
  let base64 = input.replace(/-/g, '+').replace(/_/g, '/')
  // Add padding if needed
  while (base64.length % 4) {
    base64 += '='
  }
  return base64Decode(base64)
}

// Verify and parse Facebook signed_request
async function parseSignedRequest(signedRequest: string): Promise<SignedRequestPayload | null> {
  if (!FB_APP_SECRET) {
    console.error('FB_APP_SECRET not configured')
    return null
  }

  const parts = signedRequest.split('.')
  if (parts.length !== 2) {
    console.error('Invalid signed_request format')
    return null
  }

  const [encodedSig, encodedPayload] = parts

  try {
    // Decode the payload
    const payloadBytes = base64UrlDecode(encodedPayload)
    const payloadStr = new TextDecoder().decode(payloadBytes)
    const payload: SignedRequestPayload = JSON.parse(payloadStr)

    // Verify algorithm
    if (payload.algorithm?.toUpperCase() !== 'HMAC-SHA256') {
      console.error('Unsupported algorithm:', payload.algorithm)
      return null
    }

    // Verify signature
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(FB_APP_SECRET),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )

    const expectedSigBytes = await crypto.subtle.sign(
      'HMAC',
      key,
      new TextEncoder().encode(encodedPayload)
    )

    const expectedSig = btoa(String.fromCharCode(...new Uint8Array(expectedSigBytes)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')

    const receivedSig = encodedSig

    if (expectedSig !== receivedSig) {
      console.error('Signature verification failed')
      return null
    }

    return payload
  } catch (error) {
    console.error('Error parsing signed_request:', error)
    return null
  }
}

// Generate a unique confirmation code
function generateConfirmationCode(): string {
  const timestamp = Date.now().toString(36)
  const random = Math.random().toString(36).substring(2, 10)
  return `CN_${timestamp}_${random}`.toUpperCase()
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept POST requests
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  try {
    // Get signed_request from form data
    const formData = await req.formData()
    const signedRequest = formData.get('signed_request') as string

    if (!signedRequest) {
      return new Response(JSON.stringify({ error: 'Missing signed_request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Parse and verify the signed request
    const payload = await parseSignedRequest(signedRequest)

    if (!payload) {
      return new Response(JSON.stringify({ error: 'Invalid signed_request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const fbUserId = payload.user_id
    console.log(`Processing data deletion for FB user: ${fbUserId}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Find the user by fb_user_id
    const { data: user, error: findError } = await supabaseClient
      .from('users')
      .select('id')
      .eq('fb_user_id', fbUserId)
      .maybeSingle()

    if (findError) {
      console.error('Error finding user:', findError)
    }

    const confirmationCode = generateConfirmationCode()

    if (user) {
      // Clear Facebook-related data for this user
      const { error: updateError } = await supabaseClient
        .from('users')
        .update({
          fb_user_id: null,
          fb_connected_at: null,
          fb_last_sync_at: null,
          fb_last_sync_status: null,
          fb_access_token: null,
        })
        .eq('id', user.id)

      if (updateError) {
        console.error('Error clearing FB data:', updateError)
      } else {
        console.log(`Successfully cleared FB data for user: ${user.id}`)
      }

      // Log the deletion request
      await supabaseClient.from('fb_data_deletion_requests').insert({
        fb_user_id: fbUserId,
        user_id: user.id,
        confirmation_code: confirmationCode,
        status: 'completed',
      }).catch(err => {
        // Table might not exist, that's okay
        console.log('Could not log deletion request:', err.message)
      })
    } else {
      console.log(`No user found with fb_user_id: ${fbUserId}`)

      // Still log the request even if user not found
      await supabaseClient.from('fb_data_deletion_requests').insert({
        fb_user_id: fbUserId,
        user_id: null,
        confirmation_code: confirmationCode,
        status: 'no_user_found',
      }).catch(err => {
        console.log('Could not log deletion request:', err.message)
      })
    }

    // Return the required response format for Facebook
    // https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback#response
    const statusUrl = `${SUPABASE_URL}/functions/v1/facebook-data-deletion-status?code=${confirmationCode}`

    return new Response(JSON.stringify({
      url: statusUrl,
      confirmation_code: confirmationCode,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({
      error: error instanceof Error ? error.message : 'Unknown error'
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
