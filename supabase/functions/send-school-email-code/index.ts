// supabase/functions/send-school-email-code/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const RESEND_FROM_EMAIL = Deno.env.get("RESEND_FROM_EMAIL");
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
function extractBaseDomain(domain) {
  const lower = domain.toLowerCase().trim();
  const parts = lower.split(".");
  // 台灣常見學校：xxx.edu.tw → 取最後三段
  if (lower.endsWith(".edu.tw") && parts.length >= 3) {
    return parts.slice(-3).join(".");
  }
  // 其他（例如 mit.edu / ox.ac.uk 等）：先用簡單版，取最後兩段
  if (parts.length >= 2) {
    return parts.slice(-2).join(".");
  }
  // 保底：原樣返回
  return lower;
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
    // ==== 1. 解析 body，並在失敗時把 body 打出來 ====
    const body = await req.json().catch((err)=>{
      console.error("JSON PARSE ERROR:", err);
      return {};
    });
    let { school_email } = body;
    if (!school_email) {
      // 這裡把 body 整個印出來，確認到底收到什麼
      return badRequest("school_email is required", {
        body
      });
    }
    school_email = school_email.trim().toLowerCase();
    if (!school_email.includes("@")) {
      return badRequest("Invalid email format", {
        school_email
      });
    }
    // ==== Check if email is already active for another user ====
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: activeRow, error: activeError } = await adminClient
      .from("user_school_emails")
      .select("id, user_id")
      .eq("school_email", school_email)
      .eq("is_active", true)
      .maybeSingle();
    if (activeError) {
      console.error("check active email error", activeError);
      return jsonResponse({ error: "Internal error" }, 500);
    }
    if (activeRow && activeRow.user_id !== user.id) {
      return jsonResponse({ error: "email_already_bound" }, 409);
    }
    const now = new Date();
    // ==== 2. rate limit：也把實際時間差打出來 ====
    const { data: lastRecord, error: lastError } = await supabase.from("school_email_verifications").select("id, last_sent_at, sent_count").eq("user_id", user.id).eq("school_email", school_email).order("created_at", {
      ascending: false
    }).limit(1).maybeSingle();
    if (lastError) {
      console.error("select last otp error", lastError);
      return jsonResponse({
        error: "Internal error"
      }, 500);
    }
    if (lastRecord?.last_sent_at) {
      const lastSent = new Date(lastRecord.last_sent_at);
      const diffMs = now.getTime() - lastSent.getTime();
      if (diffMs < 60_000) {
        return badRequest("rate_limit", {
          last_sent_at: lastRecord.last_sent_at,
          now: now.toISOString(),
          diffMs
        });
      }
    }
    // 產生 6 碼 OTP
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const salt = crypto.randomUUID();
    const code_hash = await hashCode(otp, salt);
    const expiresAt = new Date(now.getTime() + 15 * 60_000).toISOString();
    const insertPayload = {
      user_id: user.id,
      school_email,
      code_hash,
      salt,
      expires_at: expiresAt,
      sent_count: (lastRecord?.sent_count ?? 0) + 1,
      last_sent_at: now.toISOString()
    };
    const { error: insertError } = await supabase.from("school_email_verifications").insert(insertPayload);
    if (insertError) {
      console.error("insert otp error", insertError);
      return jsonResponse({
        error: "Internal error"
      }, 500);
    }
    // 呼叫 Resend API 寄信
    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        from: RESEND_FROM_EMAIL,
        to: [
          school_email
        ],
        subject: "Campus Nerds 校園信箱驗證碼",
        text: `你的 Campus Nerds 校園信箱驗證碼是：${otp}\n\n15 分鐘內有效，若非本人操作請忽略此信。`
      })
    });
    if (!resendResp.ok) {
      console.error("resend error", await resendResp.text());
      return jsonResponse({
        error: "Failed to send email"
      }, 500);
    }
    return jsonResponse({
      ok: true
    });
  } catch (err) {
    console.error("unexpected error", err);
    return jsonResponse({
      error: "Unexpected error"
    }, 500);
  }
});
