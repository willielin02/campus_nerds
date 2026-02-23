// Supabase Edge Function: send-push-notifications
// Called via pg_net AFTER trigger when event status changes to 'notified'
// Also called by send_chat_open_notifications() for chat_open notifications
// Sends FCM push notifications to all users with unread notifications for that event
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
      console.error(`FCM send failed for token ${deviceToken.substring(0, 20)}...: ${errorData}`);
      return false;
    }
    return true;
  } catch (error) {
    console.error(`FCM send error: ${error}`);
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { event_id } = await req.json();
    if (!event_id) {
      return new Response(JSON.stringify({ error: "Missing event_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`Sending push notifications for event ${event_id}`);

    // 1. Fetch event category for FCM data
    const { data: event } = await supabase
      .from("events")
      .select("category")
      .eq("id", event_id)
      .single();

    const eventCategory = event?.category ?? "";

    // 2. Fetch unsent notifications
    const { data: notifications, error: notifError } = await supabase
      .from("notifications")
      .select("id, user_id, title, body, type, event_id, booking_id, group_id")
      .eq("event_id", event_id)
      .is("push_sent_at", null);

    if (notifError) {
      console.error("Error fetching notifications:", notifError);
      return new Response(JSON.stringify({ error: "Failed to fetch notifications" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!notifications || notifications.length === 0) {
      console.log("No unsent notifications found");
      return new Response(JSON.stringify({ success: true, sent: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`Found ${notifications.length} notifications to send`);

    // 3. Get Firebase service account
    const firebaseSaJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!firebaseSaJson) {
      console.warn("No FIREBASE_SERVICE_ACCOUNT secret. Skipping FCM push.");
      const notifIds = notifications.map((n: any) => n.id);
      await supabase
        .from("notifications")
        .update({ push_sent_at: new Date().toISOString() })
        .in("id", notifIds);
      return new Response(
        JSON.stringify({ success: true, sent: 0, skipped: notifications.length, reason: "no_firebase_credentials" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    let serviceAccount: ServiceAccount;
    try {
      serviceAccount = JSON.parse(firebaseSaJson);
    } catch {
      console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT");
      return new Response(JSON.stringify({ error: "Invalid Firebase credentials" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const accessToken = await getAccessToken(serviceAccount);
    const userIds = [...new Set(notifications.map((n: any) => n.user_id))];

    const { data: deviceTokens } = await supabase
      .from("device_tokens")
      .select("user_id, token, platform")
      .in("user_id", userIds);

    const tokensByUser = new Map<string, Array<{ token: string; platform: string }>>();
    for (const dt of deviceTokens || []) {
      const existing = tokensByUser.get(dt.user_id) || [];
      existing.push({ token: dt.token, platform: dt.platform });
      tokensByUser.set(dt.user_id, existing);
    }

    let sentCount = 0;
    let failedCount = 0;
    const sentNotifIds: string[] = [];
    const invalidTokens: string[] = [];

    for (const notif of notifications) {
      const tokens = tokensByUser.get(notif.user_id) || [];
      if (tokens.length === 0) {
        sentNotifIds.push(notif.id);
        continue;
      }
      for (const { token } of tokens) {
        const data: Record<string, string> = {
          type: notif.type,
          event_id: notif.event_id,
          notification_id: notif.id,
          category: eventCategory,
        };
        if (notif.booking_id) data.booking_id = notif.booking_id;
        if (notif.group_id) data.group_id = notif.group_id;

        const success = await sendFcmMessage(accessToken, token, notif.title, notif.body, data);
        if (success) {
          sentCount++;
        } else {
          failedCount++;
          invalidTokens.push(token);
        }
      }
      sentNotifIds.push(notif.id);
    }

    if (sentNotifIds.length > 0) {
      await supabase
        .from("notifications")
        .update({ push_sent_at: new Date().toISOString() })
        .in("id", sentNotifIds);
    }

    if (invalidTokens.length > 0) {
      await supabase.from("device_tokens").delete().in("token", invalidTokens);
      console.log(`Removed ${invalidTokens.length} invalid device tokens`);
    }

    console.log(`Push complete: sent=${sentCount}, failed=${failedCount}`);
    return new Response(
      JSON.stringify({ success: true, sent: sentCount, failed: failedCount, total_notifications: notifications.length }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
