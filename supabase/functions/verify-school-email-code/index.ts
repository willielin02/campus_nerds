// supabase/functions/verify-school-email-code/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders
    }
  });
}
function badRequest(message, extra) {
  console.error("BAD REQUEST:", message, extra ?? "");
  return jsonResponse({
    error: message
  }, 400);
}
async function hashCode(code, salt) {
  const encoder = new TextEncoder();
  const data = encoder.encode(`${code}:${salt}`);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b)=>b.toString(16).padStart(2, "0")).join("");
}
serve(async (req)=>{
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders
    });
  }
  if (req.method !== "POST") {
    return jsonResponse({
      error: "Method not allowed"
    }, 405);
  }
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: { Authorization: authHeader }
      }
    });
    const { data: authData, error: authError } = await supabase.auth.getUser(token);
    if (authError || !authData?.user) {
      console.error("AUTH ERROR:", authError);
      return jsonResponse({
        error: "Unauthorized"
      }, 401);
    }
    const user = authData.user;
    // ---- 這段是重點：可同時支援 JSON + x-www-form-urlencoded ----
    const rawBody = await req.text();
    console.log("RAW BODY:", rawBody);
    let body = {};
    if (rawBody) {
      try {
        body = JSON.parse(rawBody);
      } catch (_) {
        const params = new URLSearchParams(rawBody);
        body = Object.fromEntries(params.entries());
      }
    }
    console.log("PARSED BODY:", body);
    let { school_email, code } = body;
    if (!school_email || !code) {
      return badRequest("school_email and code are required", {
        body
      });
    }
    school_email = school_email.trim().toLowerCase();
    code = code.trim();
    // -----------------------------------------------------------
    // 找出最新一筆未 consumed 的 OTP
    const { data: ver, error: verError } = await supabase.from("school_email_verifications").select("*").eq("user_id", user.id).eq("school_email", school_email).is("consumed_at", null).order("created_at", {
      ascending: false
    }).limit(1).maybeSingle();
    if (verError) {
      console.error("select otp error", verError);
      return jsonResponse({
        error: "Internal error"
      }, 500);
    }
    if (!ver) {
      return badRequest("找不到對應的驗證碼，請重新發送");
    }
    const now = new Date();
    if (new Date(ver.expires_at).getTime() < now.getTime()) {
      return badRequest("驗證碼已過期，請重新發送");
    }
    const expectedHash = await hashCode(code, ver.salt);
    if (expectedHash !== ver.code_hash) {
      await supabase.from("school_email_verifications").update({
        fail_count: (ver.fail_count ?? 0) + 1
      }).eq("id", ver.id);
      return badRequest("驗證碼錯誤");
    }
    // 標記已使用
    const { error: consumeError } = await supabase.from("school_email_verifications").update({
      consumed_at: now.toISOString()
    }).eq("id", ver.id);
    if (consumeError) {
      console.error("consume otp error", consumeError);
      return jsonResponse({
        error: "Internal error"
      }, 500);
    }
    // 檢查是否被其他 user active 使用
    const { data: activeRow, error: activeError } = await supabase.from("user_school_emails").select("id, user_id").eq("school_email", school_email).eq("is_active", true).maybeSingle();
    if (activeError) {
      console.error("select active email error", activeError);
      return jsonResponse({
        error: "Internal error"
      }, 500);
    }
    if (activeRow && activeRow.user_id !== user.id) {
      return badRequest("此學校信箱已被其他帳號使用，請聯絡客服");
    }
    // 停用該使用者目前啟用的其他信箱（確保一人一次只有一個啟用信箱）
    const { error: deactivateError } = await supabase.from("user_school_emails").update({
      is_active: false
    }).eq("user_id", user.id).eq("is_active", true).neq("school_email", school_email);
    if (deactivateError) {
      console.error("deactivate old emails error", deactivateError);
      return jsonResponse({
        error: "Internal error"
      }, 500);
    }
    const verifiedAt = now.toISOString();
    const { data: upsertData, error: upsertError } = await supabase.from("user_school_emails").upsert({
      user_id: user.id,
      school_email,
      status: "verified",
      verified_at: verifiedAt,
      is_active: true
    }, {
      onConflict: "user_id,school_email"
    }).select("id").single();
    if (upsertError) {
      console.error("upsert user_school_emails error", upsertError);
      return jsonResponse({
        error: "此學校信箱已被使用，請聯絡客服"
      }, 400);
    }
    const { data: profile, error: profileError } = await supabase.from("user_profile_v").select("*").eq("id", user.id).single();
    if (profileError) {
      console.error("select profile error", profileError);
      return jsonResponse({
        error: "驗證成功，但讀取使用者資料失敗"
      }, 500);
    }
    return jsonResponse({
      ok: true,
      profile
    });
  } catch (err) {
    console.error("unexpected error", err);
    return jsonResponse({
      error: "Unexpected error"
    }, 500);
  }
});
