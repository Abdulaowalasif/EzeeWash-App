import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ONESIGNAL_USER_APP_ID = Deno.env.get("ONESIGNAL_USER_APP_ID")!;
const ONESIGNAL_USER_API_KEY = Deno.env.get("ONESIGNAL_USER_API_KEY")!;

// ✅ OneSignal v5 REST API endpoint (required for os_v2_app_ keys).
const ONESIGNAL_USER_API_URL = "https://api.onesignal.com/notifications";

interface NotificationRow {
  id: string;
  user_id: string;
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

  if (!row.user_id || !row.title || !row.body) {
    console.error("Row missing required fields:", row);
    return new Response("Missing fields", { status: 400 });
  }

  // ─── Build OneSignal v5 payload ────────────────────────────────────────
  const osPayload = {
    app_id: ONESIGNAL_USER_APP_ID,

    // Target the exact user by their Supabase UUID.
    target_channel: "push",
    include_aliases: {
      external_id: [row.user_id],
    },
    // FIX-1: belt-and-braces targeting fallback for v5 SDK
    channel_for_external_user_ids: "push",

    headings: { en: row.title },
    contents: { en: row.body },

    // Extra data passed to Flutter's addClickListener / foreground handler.
    data: {
      notificationId: row.id,
      type: row.type,
      ...(row.order_id ? { orderId: row.order_id } : {}),
    },

    // 🛑 REMOVED: android_channel_id so it defaults to the standard channel and stops the 400 errors!

    ios_badge_type: "Increase",
    ios_badge_count: 1,
  };

  console.log(
    `Sending push to user_id=${row.user_id}, notification_id=${row.id}`
  );
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

  const osResult = await osResponse.json();

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
      `⚠️  Push accepted by OneSignal but recipients=0 for user_id=${row.user_id}. ` +
        "The device's external_id may not be registered yet — " +
        "check that the Flutter app awaits NotificationService.setUserId()."
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