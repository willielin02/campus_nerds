// Supabase Edge Function: confirm-group
// Staff uses this to confirm a group (draft -> scheduled)
// This function:
// 1. Syncs Facebook friends for all members with stored access tokens
// 2. Then updates the group status to 'scheduled'
// 3. The trigger will validate (no friends in group, etc.)
//
// If the trigger validation fails (e.g., friends found), the update is rolled back
// and an error is returned.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface FacebookFriendsResponse {
  data: { id: string; name?: string }[];
  error?: { message: string; type: string; code: number };
}

interface GroupConfirmRequest {
  group_id: string;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify authorization - should be a staff member
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase client with service role for admin operations
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Get request body
    const body: GroupConfirmRequest = await req.json();
    const { group_id } = body;

    if (!group_id) {
      return new Response(JSON.stringify({ error: "Missing group_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`Confirming group ${group_id}`);

    // 1. Get all members in the group
    const { data: members, error: membersError } = await supabaseClient
      .from("group_members")
      .select(
        `
        booking_id,
        bookings!inner (
          user_id,
          users!inner (
            id,
            fb_user_id,
            fb_access_token
          )
        )
      `
      )
      .eq("group_id", group_id)
      .is("left_at", null);

    if (membersError) {
      console.error("Error fetching group members:", membersError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch group members" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Found ${members?.length || 0} members in group`);

    // 2. Sync Facebook friends for members with stored access tokens
    const syncResults = {
      users_synced: 0,
      sync_errors: 0,
      friendships_found: 0,
    };

    for (const member of members || []) {
      const user = (member as any).bookings?.users;
      if (!user?.fb_access_token) {
        console.log(`User ${user?.id} has no stored access token, skipping`);
        continue;
      }

      try {
        // Call Facebook Graph API to get friends
        const fbResponse = await fetch(
          `https://graph.facebook.com/v18.0/me/friends?access_token=${user.fb_access_token}&limit=5000`
        );
        const fbData: FacebookFriendsResponse = await fbResponse.json();

        if (fbData.error) {
          console.error(
            `Facebook API error for user ${user.id}:`,
            fbData.error.message
          );

          // Token might be expired, clear it
          if (fbData.error.code === 190) {
            await supabaseClient
              .from("users")
              .update({
                fb_access_token: null,
                fb_last_sync_status: "failed",
              })
              .eq("id", user.id);
          }

          syncResults.sync_errors++;
          continue;
        }

        const friends = fbData.data || [];
        const friendFbIds = friends.map((f) => f.id);

        // Find app users who are also Facebook friends
        const { data: appFriends } = await supabaseClient
          .from("users")
          .select("id, fb_user_id")
          .in(
            "fb_user_id",
            friendFbIds.length > 0 ? friendFbIds : ["__no_friends__"]
          );

        // Insert friendships
        for (const friend of appFriends || []) {
          const userLowId = user.id < friend.id ? user.id : friend.id;
          const userHighId = user.id > friend.id ? user.id : friend.id;

          await supabaseClient
            .from("friendships")
            .upsert(
              {
                user_low_id: userLowId,
                user_high_id: userHighId,
                last_seen_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
              },
              {
                onConflict: "user_low_id,user_high_id",
              }
            );

          syncResults.friendships_found++;
        }

        // Update sync status
        await supabaseClient
          .from("users")
          .update({
            fb_last_sync_at: new Date().toISOString(),
            fb_last_sync_status: "success",
          })
          .eq("id", user.id);

        syncResults.users_synced++;
        console.log(
          `Synced ${appFriends?.length || 0} friends for user ${user.id}`
        );
      } catch (syncError) {
        console.error(`Sync error for user ${user.id}:`, syncError);
        syncResults.sync_errors++;
      }
    }

    console.log("Friend sync results:", syncResults);

    // 3. Now update the group status to 'scheduled'
    // venue_id and timing fields should already be set via admin venue save
    // The trigger handle_group_status_scheduled will validate:
    // - Group is full (members = max_size)
    // - venue_id is set
    // - Times are set
    // - NO Facebook friends in the group (will fail if friends found)
    const { error: updateError } = await supabaseClient
      .from("groups")
      .update({
        status: "scheduled",
      })
      .eq("id", group_id);

    if (updateError) {
      console.error("Error updating group status:", updateError);

      // Check if it's a Facebook friends validation error
      if (
        updateError.message &&
        updateError.message.includes("Facebook friends")
      ) {
        return new Response(
          JSON.stringify({
            error: "group_contains_facebook_friends",
            message: updateError.message,
            details:
              "此群組中有臉書好友，無法確認分組。請調整成員後再試。",
            sync_results: syncResults,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          error: "failed_to_confirm_group",
          message: updateError.message,
          sync_results: syncResults,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Successfully confirmed group ${group_id}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: "群組確認成功",
        group_id: group_id,
        sync_results: syncResults,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
