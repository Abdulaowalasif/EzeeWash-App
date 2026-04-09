import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ONESIGNAL_USER_APP_ID = Deno.env.get("ONESIGNAL_USER_APP_ID")!;
const ONESIGNAL_USER_API_KEY = Deno.env.get("ONESIGNAL_USER_API_KEY")!;

// ✅ OneSignal v5 REST API endpoint (required for os_v2_app_ keys).
const ONESIGNAL_USER_API_URL = "https://api.onesignal.com/notifications";

interface NotificationRow {
  id: string;
  user_id?: string | null; // Made optional so it accepts null for global blasts
  title: string;
  body: string;
  type: string;
  order_id?: string;
  is_read: boolean;
  created_at: string;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: NotificationRow;
  schema: string;
  old_record?: NotificationRow;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch (e) {
    console.error("Failed to parse webhook body:", e);
    return new Response("Invalid JSON", { status: 400 });
  }

  console.log("Webhook received:", JSON.stringify(payload));

  // Only act on INSERT events on the notifications table.
  if (payload.type !== "INSERT" || payload.table !== "notifications") {
    console.log(`Skipping: type=${payload.type} table=${payload.table}`);
    return new Response("Ignored", { status: 200 });
  }

  const row = payload.record;

  // 🔴 CHANGED: We no longer block if user_id is missing! Only title & body are required.
  if (!row.title || !row.body) {
    console.error("Row missing required fields:", row);
    return new Response("Missing fields", { status: 400 });
  }

  // ─── Build OneSignal v5 Base Payload ───────────────────────────────────
  // We use 'any' type here so we can dynamically add targeting fields below
  const osPayload: any = {
    app_id: ONESIGNAL_USER_APP_ID,

    headings: { en: row.title },
    contents: { en: row.body },

    // Extra data passed to Flutter's addClickListener / foreground handler.
    data: {
      notificationId: row.id,
      type: row.type,
      ...(row.order_id ? { orderId: row.order_id } : {}),
    },

    ios_badge_type: "Increase",
    ios_badge_count: 1,
  };

  // ─── The Magic: Dynamic Targeting ──────────────────────────────────────
  if (row.user_id) {
    // SCENARIO A: Target exactly one user by their Supabase UUID.
    osPayload.target_channel = "push";
    osPayload.include_aliases = {
      external_id: [row.user_id],
    };
    osPayload.channel_for_external_user_ids = "push";
    console.log(`Sending personal push to user_id=${row.user_id}, notification_id=${row.id}`);
  } else {
    // SCENARIO B: No user_id provided. Blast to everyone!
    osPayload.included_segments = ["Total Subscriptions"];
    console.log(`Sending GLOBAL push to all users, notification_id=${row.id}`);
  }
  // ───────────────────────────────────────────────────────────────────────

  console.log("OneSignal payload:", JSON.stringify(osPayload));

  // ─── Call OneSignal v5 API ─────────────────────────────────────────────
  const osResponse = await fetch(ONESIGNAL_USER_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Key ${ONESIGNAL_USER_API_KEY}`,
    },
    body: JSON.stringify(osPayload),
  });

  // ─── SAFE PARSER: Prevents the "Unexpected token '<'" Crash ────────────
  const responseText = await osResponse.text();
  let osResult;

  try {
    osResult = JSON.parse(responseText);
  } catch (err) {
    console.error("❌ OneSignal returned HTML instead of JSON. Status Code:", osResponse.status);
    console.error("❌ Raw HTML Response:", responseText);

    return new Response(
      JSON.stringify({
        error: "OneSignal API returned an HTML page",
        statusCode: osResponse.status,
        rawHtmlExcerpt: responseText.substring(0, 200)
      }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }
  // ───────────────────────────────────────────────────────────────────────

  console.log(
    `OneSignal responded ${osResponse.status} | recipients=${osResult.recipients ?? "unknown"}:`,
    JSON.stringify(osResult)
  );

  if (!osResponse.ok) {
    console.error("OneSignal error:", JSON.stringify(osResult));
    return new Response(
      JSON.stringify({ error: "OneSignal request failed", details: osResult }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  if ((osResult.recipients ?? 0) === 0) {
    console.warn(
      `⚠️  Push accepted by OneSignal but recipients=0. ` +
        "If personal, the device's external_id may not be registered yet. " +
        "If global, you may have no subscribed users."
    );
  }

  return new Response(
    JSON.stringify({
      success: true,
      onesignal: osResult,
      recipients: osResult.recipients ?? 0,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});