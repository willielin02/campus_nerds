// Supabase Edge Function: send-chat-push
// Called via pg_net AFTER INSERT trigger on group_messages (type='user')
// Sends FCM push notifications to all other group members
//
// Requires Supabase secret: FIREBASE_SERVICE_ACCOUNT (JSON string of Firebase service account)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "https://deno.land/x/jose@v5.2.0/index.ts";

const FIREBASE_PROJECT_ID = "campus-nerds-29593";
const FCM_URL = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
const SCOPES = "https://www.googleapis.com/auth/firebase.messaging";

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri: string;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const privateKey = await importPKCS8(sa.private_key, "RS256");
  const jwt = await new SignJWT({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: sa.token_uri,
    scope: SCOPES,
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const tokenResponse = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

async function sendFcmMessage(
  accessToken: string,
  deviceToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  try {
    const response = await fetch(FCM_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: {
              channel_id: "campus_nerds_notifications",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: { sound: "default", badge: 1 },
            },
          },
        },
      }),
    });
    if (!response.ok) {
      const errorData = await response.text();
      console.error(
        `FCM send failed for token ${deviceToken.substring(0, 20)}...: ${errorData}`
      );
      return false;
    }
    return true;
  } catch (error) {
    console.error(`FCM send error: ${error}`);
    return false;
  }
}

Deno.serve(async (req) => {
  try {
    const { group_id, message_id, sender_user_id, content } = await req.json();
    if (!group_id || !sender_user_id) {
      return new Response(
        JSON.stringify({ error: "Missing group_id or sender_user_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Get sender's nickname
    const { data: sender } = await supabase
      .from("user_profile_v")
      .select("nickname")
      .eq("id", sender_user_id)
      .single();

    const senderName = `書呆子 ${sender?.nickname || ""}`;

    // 2. Get event info from group (for FCM data routing)
    const { data: group } = await supabase
      .from("groups")
      .select("event_id, events(category)")
      .eq("id", group_id)
      .single();

    const eventId = group?.event_id ?? "";
    const category = (group?.events as any)?.category ?? "";

    // 3. Get all group members with their booking_ids and user_ids
    const { data: members } = await supabase
      .from("group_members")
      .select("bookings(id, user_id)")
      .eq("group_id", group_id)
      .is("left_at", null);

    // Build a map of user_id → booking_id for per-recipient data
    const userBookingMap = new Map<string, string>();
    const recipientUserIds: string[] = [];
    for (const m of members ?? []) {
      const uid = (m as any).bookings?.user_id;
      const bid = (m as any).bookings?.id;
      if (uid && uid !== sender_user_id) {
        recipientUserIds.push(uid);
        if (bid) userBookingMap.set(uid, bid);
      }
    }

    if (recipientUserIds.length === 0) {
      return new Response(JSON.stringify({ success: true, sent: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Get FCM tokens for recipients
    const { data: deviceTokens } = await supabase
      .from("device_tokens")
      .select("id, user_id, token")
      .in("user_id", recipientUserIds);

    if (!deviceTokens || deviceTokens.length === 0) {
      return new Response(JSON.stringify({ success: true, sent: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // 5. Get Firebase credentials and send FCM
    const firebaseSaJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!firebaseSaJson) {
      console.warn("No FIREBASE_SERVICE_ACCOUNT secret. Skipping.");
      return new Response(
        JSON.stringify({ success: true, sent: 0, reason: "no_firebase_credentials" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const serviceAccount: ServiceAccount = JSON.parse(firebaseSaJson);
    const accessToken = await getAccessToken(serviceAccount);

    const truncatedContent =
      content && content.length > 100
        ? content.substring(0, 100) + "..."
        : content || "";

    let sentCount = 0;
    const invalidTokenIds: string[] = [];

    await Promise.all(
      deviceTokens.map(async ({ id, user_id, token }: { id: string; user_id: string; token: string }) => {
        // Per-recipient FCM data with event context for navigation
        const data: Record<string, string> = {
          type: "chat_message",
          group_id,
          event_id: eventId,
          category,
        };
        if (message_id) data.message_id = message_id;
        const bookingId = userBookingMap.get(user_id);
        if (bookingId) data.booking_id = bookingId;

        const success = await sendFcmMessage(
          accessToken,
          token,
          senderName,
          truncatedContent,
          data
        );
        if (success) {
          sentCount++;
        } else {
          invalidTokenIds.push(id);
        }
      })
    );

    // 6. Remove invalid tokens
    if (invalidTokenIds.length > 0) {
      await supabase.from("device_tokens").delete().in("id", invalidTokenIds);
      console.log(`Removed ${invalidTokenIds.length} invalid device tokens`);
    }

    console.log(
      `Chat push for group ${group_id}: sent=${sentCount}, failed=${invalidTokenIds.length}`
    );
    return new Response(
      JSON.stringify({ success: true, sent: sentCount, failed: invalidTokenIds.length }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
