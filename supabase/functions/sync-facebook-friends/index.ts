// Supabase Edge Function: sync-facebook-friends
// Syncs a user's Facebook friends who also use the Campus Nerds app
// and stores the friendships in the database for group matching
//
// NEW: Optionally exchanges short-lived token for long-lived token (60 days)
//      and stores it for background sync during auto-grouping

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Facebook App credentials (from environment)
const FB_APP_ID = Deno.env.get('FB_APP_ID') ?? ''
const FB_APP_SECRET = Deno.env.get('FB_APP_SECRET') ?? ''

interface FacebookFriend {
  id: string
  name?: string
}

interface FacebookFriendsResponse {
  data: FacebookFriend[]
  paging?: {
    next?: string
  }
  error?: {
    message: string
    type: string
    code: number
  }
}

interface LongLivedTokenResponse {
  access_token?: string
  token_type?: string
  expires_in?: number
  error?: {
    message: string
    type: string
    code: number
  }
}

// Exchange short-lived token for long-lived token (60 days)
async function exchangeForLongLivedToken(shortLivedToken: string): Promise<string | null> {
  if (!FB_APP_ID || !FB_APP_SECRET) {
    console.log('FB_APP_ID or FB_APP_SECRET not configured, skipping token exchange')
    return null
  }

  try {
    const response = await fetch(
      `https://graph.facebook.com/v18.0/oauth/access_token?` +
      `grant_type=fb_exchange_token&` +
      `client_id=${FB_APP_ID}&` +
      `client_secret=${FB_APP_SECRET}&` +
      `fb_exchange_token=${shortLivedToken}`
    )

    const data: LongLivedTokenResponse = await response.json()

    if (data.error) {
      console.error('Token exchange error:', data.error.message)
      return null
    }

    console.log(`Got long-lived token, expires in ${data.expires_in} seconds`)
    return data.access_token || null
  } catch (error) {
    console.error('Token exchange failed:', error)
    return null
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role for admin operations
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const jwt = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(jwt)

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Get Facebook access token and options from request body
    const { access_token, store_token = false } = await req.json()

    if (!access_token) {
      return new Response(JSON.stringify({ error: 'Missing access_token' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Optionally exchange for long-lived token
    let tokenToUse = access_token
    let longLivedToken: string | null = null

    if (store_token) {
      longLivedToken = await exchangeForLongLivedToken(access_token)
      if (longLivedToken) {
        tokenToUse = longLivedToken
        console.log('Using long-lived token for sync')
      }
    }

    // Fetch friends from Facebook Graph API
    // Note: user_friends permission only returns friends who also use this app
    const fbResponse = await fetch(
      `https://graph.facebook.com/v18.0/me/friends?access_token=${tokenToUse}&limit=5000`
    )

    const fbData: FacebookFriendsResponse = await fbResponse.json()

    if (fbData.error) {
      // Log failed sync attempt
      await supabaseClient.from('fb_friend_sync_attempts').insert({
        user_id: user.id,
        status: 'failed',
        error_message: fbData.error.message,
        raw_response: fbData.error,
      })

      return new Response(JSON.stringify({
        error: fbData.error.message,
        error_code: fbData.error.code
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const friends = fbData.data || []
    const friendFbIds = friends.map(f => f.id)

    // Find app users who are also Facebook friends
    const { data: appFriends, error: queryError } = await supabaseClient
      .from('users')
      .select('id, fb_user_id')
      .in('fb_user_id', friendFbIds.length > 0 ? friendFbIds : ['__no_friends__'])

    if (queryError) {
      console.error('Query error:', queryError)
    }

    // Insert friendships (symmetric relationship)
    let insertedCount = 0
    let skippedCount = 0

    for (const friend of appFriends || []) {
      // Ensure symmetric storage: user_low_id < user_high_id
      const userLowId = user.id < friend.id ? user.id : friend.id
      const userHighId = user.id > friend.id ? user.id : friend.id

      // Upsert friendship (avoid duplicates)
      const { error: insertError } = await supabaseClient
        .from('friendships')
        .upsert({
          user_low_id: userLowId,
          user_high_id: userHighId,
          last_seen_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }, {
          onConflict: 'user_low_id,user_high_id'
        })

      if (!insertError) {
        insertedCount++
      } else {
        skippedCount++
        console.error('Insert error:', insertError)
      }
    }

    // Update user's sync status and optionally store long-lived token
    const updateData: Record<string, any> = {
      fb_last_sync_at: new Date().toISOString(),
      fb_last_sync_status: 'success',
    }

    // Store long-lived token if available and user consented
    if (store_token && longLivedToken) {
      updateData.fb_access_token = longLivedToken
      console.log('Storing long-lived token for user')
    }

    await supabaseClient.from('users').update(updateData).eq('id', user.id)

    // Log successful sync
    await supabaseClient.from('fb_friend_sync_attempts').insert({
      user_id: user.id,
      status: 'success',
      friends_count: insertedCount,
      raw_response: {
        total_fb_friends: friends.length,
        matched_app_users: appFriends?.length || 0,
        inserted_friendships: insertedCount,
        skipped_duplicates: skippedCount,
      },
    })

    return new Response(JSON.stringify({
      success: true,
      friends_count: insertedCount,
      total_fb_friends: friends.length,
      matched_app_users: appFriends?.length || 0,
      token_stored: store_token && longLivedToken !== null,
      message: `成功同步 ${insertedCount} 位好友`,
    }), {
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
