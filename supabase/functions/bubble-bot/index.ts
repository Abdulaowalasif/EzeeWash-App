// supabase/functions/bubble-bot/index.ts

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  try {
    console.log("Bubble Bot triggered");

    // ─────────────────────────────
    // 1. Read request
    // ─────────────────────────────
    const body = await req.json().catch(() => ({}));
    const message = body?.message || "Please analyze this image.";
    const imageBase64 = body?.image;

    if (!message && !imageBase64) {
      return new Response(
        JSON.stringify({ reply: "No message or image received", action: "none" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────
    // 2. API KEY
    // ─────────────────────────────
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ reply: "Missing GEMINI_API_KEY in Supabase secrets", action: "none" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────
    // 3. System prompt
    // ─────────────────────────────
    const prompt = `
You are "Bubble Bot", the official AI assistant for the EzzeWash laundry service app.

RULES:
1. NEVER introduce yourself (do not say "Hi, I'm Bubble Bot"). Just dive straight into the answer.
2. If an image is provided, analyze it to identify the fabric type or garment. Recommend the best EzzeWash service for it (e.g., Dry Cleaning for suits/silk, Wash & Fold for daily wear, Ironing, or Shoe Cleaning).
3. Answer questions related to laundry services, pickup, delivery, pricing, and orders.
4. Assist users with app functionalities (e.g., tracking orders, profile section).
5. You MUST respond ONLY with a valid, raw JSON object containing exactly two keys: "reply" (your message) and "action" (a command code). Do not include markdown formatting.

Available action codes:
- "none" : Use if no specific navigation is needed.
- "nav_track_order" : Use if the user wants to track their laundry.
- "nav_pricing" : Use if the user asks about prices or you are recommending a specific paid service.
- "nav_profile" : Use if the user asks about their account.

User message: ${message}
`;

    // ─────────────────────────────
    // 4. Construct Payload Parts
    // ─────────────────────────────
    const parts: any[] = [{ text: prompt }];

    if (imageBase64) {
      const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, "");

      parts.push({
        inlineData: {
          mimeType: "image/jpeg",
          data: cleanBase64,
        },
      });
    }

    // ─────────────────────────────
    // 5. Gemini API call
    // ─────────────────────────────
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {
              parts: parts,
            },
          ],
          // REMOVED responseMimeType to fix the API crash
          generationConfig: {
            maxOutputTokens: 1024,
            temperature: 0.7,
          },
        }),
      }
    );

    const data = await response.json();

    console.log("GEMINI RAW RESPONSE:", JSON.stringify(data, null, 2));

    // ─────────────────────────────
    // 6. Handle API errors
    // ─────────────────────────────
    if (!response.ok || data?.error) {
      return new Response(
        JSON.stringify({
          reply: data?.error?.message || "Gemini API error",
          action: "none"
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────
    // 7. Extract & Clean reply safely
    // ─────────────────────────────
    let replyString = data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!replyString) {
      return new Response(
        JSON.stringify({
          reply: "Sorry, I couldn't generate a response.",
          action: "none"
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // Clean up Markdown formatting (```json ... ```) just in case Gemini adds it
    replyString = replyString.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // ─────────────────────────────
    // 8. Success response
    // ─────────────────────────────
    return new Response(
      replyString,
      {
        headers: { "Content-Type": "application/json" },
      }
    );

  } catch (err) {
    console.error("EDGE FUNCTION ERROR:", err);

    return new Response(
      JSON.stringify({
        reply: "Server error: " + err.message,
        action: "none"
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});