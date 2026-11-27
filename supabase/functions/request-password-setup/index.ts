// パスワード設定メールの送信（利用者リストに登録されたメールアドレスにだけ送る）
// - 初めての人: 招待メール（リンクを開くとパスワード設定画面）
// - 登録済みの人: パスワード再設定メール
// リストにないアドレスでも同じ応答を返し、登録の有無を外部に知らせない。
// Supabase に配置済み（verify_jwt: false）。
import { createClient } from "npm:@supabase/supabase-js@2.118.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const URL_ = Deno.env.get("SUPABASE_URL")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ error: "bad_request" }, 400); }

  const email = String(body.email ?? "").trim().toLowerCase();
  if (email.length > 254 || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return json({ error: "invalid_email" }, 400);
  const redirectTo = typeof body.redirectTo === "string" && /^https:\/\//.test(body.redirectTo) ? body.redirectTo : undefined;

  const admin = createClient(URL_, SERVICE, { auth: { persistSession: false, autoRefreshToken: false } });

  const { data: row, error: e1 } = await admin.from("allowed_emails").select("email").eq("email", email).maybeSingle();
  if (e1) { console.error("allowlist lookup failed", e1.message); return json({ error: "server_error" }, 500); }
  if (!row) return json({ ok: true });

  const isRate = (m?: string, s?: number) => s === 429 || /rate limit|too many/i.test(m ?? "");

  const inv = await admin.auth.admin.inviteUserByEmail(email, { redirectTo });
  if (!inv.error) return json({ ok: true });
  if (isRate(inv.error.message, inv.error.status)) return json({ error: "rate_limited" }, 429);

  // すでにアカウントがある場合は再設定メール
  const rec = await admin.auth.resetPasswordForEmail(email, { redirectTo });
  if (rec.error) {
    if (isRate(rec.error.message, rec.error.status)) return json({ error: "rate_limited" }, 429);
    console.error("send failed", inv.error.message, rec.error.message);
    return json({ error: "send_failed" }, 500);
  }
  return json({ ok: true });
});
