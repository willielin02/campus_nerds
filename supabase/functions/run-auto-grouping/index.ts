// Supabase Edge Function: run-auto-grouping
// Orchestrates Facebook friends sync + auto grouping for events 2 days out
//
// This function:
// 1. Finds events scheduled for 2 days from now
// 2. Gets all users with Facebook linked who are registered for those events
// 3. For users with stored access tokens, syncs their Facebook friends
// 4. Then runs auto_seed_groups_for_event for each event
//
// Should be called by a cron job (e.g., pg_cron or external scheduler)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FacebookFriendsResponse {
  data: { id: string; name?: string }[]
  error?: { message: string; type: string; code: number }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // This function should only be called with service role key
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.includes('service_role')) {
      // Verify it's a service role call by checking the key
      const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
      const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

      if (!authHeader?.includes(serviceRoleKey.substring(0, 20))) {
        return new Response(JSON.stringify({ error: 'Unauthorized - service role required' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Calculate target date (2 days from now in Taipei timezone)
    const now = new Date()
    const taipeiOffset = 8 * 60 * 60 * 1000 // UTC+8
    const taipeiNow = new Date(now.getTime() + taipeiOffset)
    const targetDate = new Date(taipeiNow)
    targetDate.setDate(targetDate.getDate() + 2)
    const targetDateStr = targetDate.toISOString().split('T')[0]

    console.log(`Looking for events on ${targetDateStr}`)

    // 1. Get events scheduled for target date
    const { data: events, error: eventsError } = await supabaseClient
      .from('events')
      .select('id, event_date, category')
      .eq('event_date', targetDateStr)
      .eq('status', 'scheduled')

    if (eventsError) {
      console.error('Error fetching events:', eventsError)
      return new Response(JSON.stringify({ error: 'Failed to fetch events' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (!events || events.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: `No events found for ${targetDateStr}`,
        events_processed: 0
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log(`Found ${events.length} events for ${targetDateStr}`)

    const results = {
      events_processed: 0,
      users_synced: 0,
      sync_errors: 0,
      grouping_results: [] as any[]
    }

    // 2. For each event, sync Facebook friends for registered users
    for (const event of events) {
      console.log(`Processing event ${event.id}`)

      // Get users with Facebook linked who are registered for this event
      const { data: usersWithFb, error: usersError } = await supabaseClient
        .from('bookings')
        .select(`
          user_id,
          users!inner (
            id,
            fb_user_id,
            fb_access_token
          )
        `)
        .eq('event_id', event.id)
        .eq('status', 'active')
        .not('users.fb_user_id', 'is', null)

      if (usersError) {
        console.error(`Error fetching users for event ${event.id}:`, usersError)
        continue
      }

      console.log(`Found ${usersWithFb?.length || 0} users with Facebook for event ${event.id}`)

      // 3. Sync Facebook friends for users with stored access tokens
      for (const booking of usersWithFb || []) {
        const user = (booking as any).users
        if (!user?.fb_access_token) {
          console.log(`User ${user?.id} has no stored access token, skipping sync`)
          continue
        }

        try {
          // Call Facebook Graph API to get friends
          const fbResponse = await fetch(
            `https://graph.facebook.com/v18.0/me/friends?access_token=${user.fb_access_token}&limit=5000`
          )
          const fbData: FacebookFriendsResponse = await fbResponse.json()

          if (fbData.error) {
            console.error(`Facebook API error for user ${user.id}:`, fbData.error.message)

            // Token might be expired, clear it
            if (fbData.error.code === 190) {
              await supabaseClient.from('users').update({
                fb_access_token: null,
                fb_last_sync_status: 'failed'
              }).eq('id', user.id)
            }

            results.sync_errors++
            continue
          }

          const friends = fbData.data || []
          const friendFbIds = friends.map(f => f.id)

          // Find app users who are also Facebook friends
          const { data: appFriends } = await supabaseClient
            .from('users')
            .select('id, fb_user_id')
            .in('fb_user_id', friendFbIds.length > 0 ? friendFbIds : ['__no_friends__'])

          // Insert friendships
          for (const friend of appFriends || []) {
            const userLowId = user.id < friend.id ? user.id : friend.id
            const userHighId = user.id > friend.id ? user.id : friend.id

            await supabaseClient
              .from('friendships')
              .upsert({
                user_low_id: userLowId,
                user_high_id: userHighId,
                last_seen_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
              }, {
                onConflict: 'user_low_id,user_high_id'
              })
          }

          // Update sync status
          await supabaseClient.from('users').update({
            fb_last_sync_at: new Date().toISOString(),
            fb_last_sync_status: 'success'
          }).eq('id', user.id)

          results.users_synced++
          console.log(`Synced ${appFriends?.length || 0} friends for user ${user.id}`)

        } catch (syncError) {
          console.error(`Sync error for user ${user.id}:`, syncError)
          results.sync_errors++
        }
      }

      // 4. Run auto_seed_groups_for_event
      try {
        const { error: seedError } = await supabaseClient
          .rpc('auto_seed_groups_for_event', { p_event_id: event.id })

        if (seedError) {
          console.error(`Error running auto_seed for event ${event.id}:`, seedError)
          results.grouping_results.push({
            event_id: event.id,
            success: false,
            error: seedError.message
          })
        } else {
          console.log(`Successfully ran auto_seed for event ${event.id}`)
          results.grouping_results.push({
            event_id: event.id,
            success: true
          })
        }
      } catch (rpcError) {
        console.error(`RPC error for event ${event.id}:`, rpcError)
        results.grouping_results.push({
          event_id: event.id,
          success: false,
          error: String(rpcError)
        })
      }

      results.events_processed++
    }

    return new Response(JSON.stringify({
      success: true,
      target_date: targetDateStr,
      ...results
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
