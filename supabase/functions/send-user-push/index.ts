// Supabase Edge Function: send-user-push
// Generic function to send push notification to a specific user
// Called from Admin dashboard (e.g., after manual school verification)
//
// Input: { user_id, title, body, data? }
// Requires Supabase secret: FIREBASE_SERVICE_ACCOUNT (JSON string)

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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { user_id, title, body, data } = await req.json();
    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: "user_id, title, and body are required" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Get device tokens for this user
    const { data: deviceTokens, error: tokenError } = await supabase
      .from("device_tokens")
      .select("id, token")
      .eq("user_id", user_id);

    if (tokenError) {
      console.error("Error fetching device tokens:", tokenError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch device tokens" }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!deviceTokens || deviceTokens.length === 0) {
      console.log(`No device tokens for user ${user_id}`);
      return new Response(
        JSON.stringify({ success: true, sent: 0, reason: "no_device_tokens" }),
        { headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // 2. Get Firebase credentials
    const firebaseSaJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!firebaseSaJson) {
      console.warn("No FIREBASE_SERVICE_ACCOUNT secret. Skipping push.");
      return new Response(
        JSON.stringify({ success: true, sent: 0, reason: "no_firebase_credentials" }),
        { headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const serviceAccount: ServiceAccount = JSON.parse(firebaseSaJson);
    const accessToken = await getAccessToken(serviceAccount);

    // 3. Send FCM to all device tokens
    let sentCount = 0;
    const invalidTokenIds: string[] = [];

    await Promise.all(
      deviceTokens.map(async ({ id, token }: { id: string; token: string }) => {
        const success = await sendFcmMessage(
          accessToken,
          token,
          title,
          body,
          data || {}
        );
        if (success) {
          sentCount++;
        } else {
          invalidTokenIds.push(id);
        }
      })
    );

    // 4. Remove invalid tokens
    if (invalidTokenIds.length > 0) {
      await supabase.from("device_tokens").delete().in("id", invalidTokenIds);
      console.log(`Removed ${invalidTokenIds.length} invalid device tokens`);
    }

    console.log(
      `User push for ${user_id}: sent=${sentCount}, failed=${invalidTokenIds.length}`
    );
    return new Response(
      JSON.stringify({ success: true, sent: sentCount, failed: invalidTokenIds.length }),
      { headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});
