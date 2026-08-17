// supabase/functions/bubble-bot/index.ts

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  // ─────────────────────────────
  // 0. Handle CORS preflight
  // ─────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log("Bubble Bot triggered");

    // ─────────────────────────────
    // 1. Read request
    // ─────────────────────────────
    const body = await req.json().catch(() => ({}));
    const message = body?.message || "Please analyze this image.";
    const imageBase64 = body?.image;
    const userId: string | null = body?.user_id ?? null;
    const history = body?.history || [];

    if (!message && !imageBase64) {
      return new Response(
        JSON.stringify({ reply: "No message or image received", action: "none", service_id: null }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────
    // 2. Environment Variables
    // ─────────────────────────────
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ reply: "Missing GEMINI_API_KEY in Supabase secrets", action: "none", service_id: null }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────
    // 3. Fetch Data from Supabase DB
    // ─────────────────────────────
    let dbContext = "No database records available at the moment.";
    let servicesData: any[] = [];

    if (SUPABASE_URL && SUPABASE_ANON_KEY) {
      const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

      const now = new Date().toISOString();

      // Fire all Supabase queries in parallel to reduce network roundtrips
      const [servicesResult, userPromosResult, globalPromosResult] = await Promise.all([
        // Fetch all active services
        supabase
          .from('services')
          .select('id, title, description, price, category, tags')
          .eq('is_active', true),
          
        // Fetch user-specific promos (if logged in)
        userId ? supabase
          .from('promos')
          .select('code, title, description, discount_type, discount_value, target_service_id')
          .eq('is_active', true)
          .eq('target_user_id', userId)
          .or(`valid_until.gte.${now},valid_until.is.null`) 
        : Promise.resolve({ data: [] }),
        
        // Always include global promos
        supabase
          .from('promos')
          .select('code, title, description, discount_type, discount_value, target_service_id')
          .eq('is_active', true)
          .is('target_user_id', null)
          .or(`valid_until.gte.${now},valid_until.is.null`)
      ]);

      servicesData = servicesResult.data || [];
      let promosData: any[] = userPromosResult.data || [];
      const globalPromos = globalPromosResult.data || [];

      // Merge: user-specific first, then global (deduplicate by code)
      const existingCodes = new Set(promosData.map((p: any) => p.code));
      for (const gp of globalPromos) {
        if (!existingCodes.has(gp.code)) {
          promosData.push(gp);
        }
      }

      // Build DB context string for Gemini
      // Include service IDs so the model can return the correct one
      const servicesContext = servicesData.length > 0
        ? servicesData.map((s: any) =>
          `- [ID: ${s.id}] ${s.title} (${s.category}) — Price: ${s.price} | ${s.description}${s.tags?.length ? ' | Tags: ' + s.tags.join(', ') : ''}`
        ).join('\n')
        : "No services currently listed.";

      const promosContext = promosData.length > 0
        ? promosData.map((p: any) =>
          `- Code: ${p.code} | ${p.title ?? p.description} | ${p.discount_type === 'percentage' ? p.discount_value + '% off' : p.discount_value + ' taka off'}${p.target_service_id ? ' (applies to service ID: ' + p.target_service_id + ')' : ' (applies to all)'}`
        ).join('\n')
        : "No active promos for this user.";

      dbContext = `
[AVAILABLE SERVICES & PRICING]
${servicesContext}

[ACTIVE PROMOS FOR THIS USER]
${promosContext}
      `;
    }

    // ─────────────────────────────
    // 4. System prompt
    // ─────────────────────────────
    const systemPrompt = `
You are "Bubble Bot", the official AI assistant for the EzzeWash laundry service app.

DATABASE KNOWLEDGE (CRITICAL):
You MUST ONLY use the following data when answering questions about services, prices, or promos.
Do NOT make up, guess, or hallucinate any prices, services, or promo codes not in this list:
${dbContext}

RESPONSE FORMAT (MANDATORY):
You MUST respond ONLY with a valid raw JSON object with exactly three keys:
1. "reply" — Your helpful message to the user (string). Use *asterisks* around key terms for bold.
2. "action" — Navigation action code (string).
3. "service_id" — The UUID of the single most-relevant service from the database (string), or null if no specific service applies.

RULES:
1. NEVER introduce yourself. Dive straight into the answer.
2. SHOW PRICING: Always list matching services with their exact prices from the database.
3. RECOMMEND SERVICE: If an image is provided, analyze the fabric/garment and pick the SINGLE best matching service. Set "service_id" to its ID.
4. SHOW PROMOS: Only mention promos from [ACTIVE PROMOS FOR THIS USER]. Match the promo to the recommended service if target_service_id applies. Show at most 1–2 relevant promos, not all of them.
5. Do not include markdown code fences in your response.

Available action codes:
- "none" : No navigation needed.
- "nav_track_order" : User wants to track laundry.
- "nav_pricing" : User asks about prices or a paid service is recommended.
- "nav_profile" : User asks about their account.
`;

    // ─────────────────────────────
    // 5. Construct Payload Parts
    // ─────────────────────────────
    const rawContents: any[] = [];

    if (history && Array.isArray(history)) {
      for (const msg of history) {
        const parts: any[] = [];
        if (msg.text) {
          parts.push({ text: msg.text });
        }
        if (msg.image) {
          const cleanBase64 = msg.image.replace(/^data:image\/\w+;base64,/, "");
          parts.push({
            inlineData: {
              mimeType: "image/jpeg",
              data: cleanBase64,
            },
          });
        }
        if (parts.length > 0) {
          rawContents.push({
            role: msg.role === 'model' ? 'model' : 'user',
            parts: parts
          });
        }
      }
    }

    const currentParts: any[] = [{ text: message }];
    if (imageBase64) {
      const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, "");
      currentParts.push({
        inlineData: {
          mimeType: "image/jpeg",
          data: cleanBase64,
        },
      });
    }

    rawContents.push({
      role: 'user',
      parts: currentParts
    });

    // Gemini requires alternating roles starting with 'user'
    const contents: any[] = [];
    for (const msg of rawContents) {
      if (contents.length === 0 && msg.role === 'model') {
        continue; // Skip leading model messages
      }
      
      const last = contents[contents.length - 1];
      if (last && last.role === msg.role) {
        last.parts.push(...msg.parts); // Combine consecutive messages of the same role
      } else {
        contents.push({ role: msg.role, parts: [...msg.parts] });
      }
    }

    // ─────────────────────────────
    // 6. Gemini API call
    // ─────────────────────────────
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemPrompt }]
          },
          contents: contents,
          generationConfig: {
            maxOutputTokens: 4096,
            temperature: 0.2,
            responseMimeType: "application/json",
          },
        }),
      }
    );

    const data = await response.json();

    if (data?.usageMetadata) {
      console.log(`[USAGE TRACKING] User: ${userId || 'anonymous'} | Total Tokens: ${data.usageMetadata.totalTokenCount} | Prompt: ${data.usageMetadata.promptTokenCount} | Response: ${data.usageMetadata.candidatesTokenCount}`);
    } else {
      console.log("GEMINI RAW RESPONSE:", JSON.stringify(data, null, 2));
    }

    // ─────────────────────────────
    // 7. Handle API errors
    // ─────────────────────────────
    if (!response.ok || data?.error) {
      return new Response(
        JSON.stringify({
          reply: data?.error?.message || "Gemini API error",
          action: "none",
          service_id: null,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ─────────────────────────────
    // 8. Extract & Clean reply safely
    // ─────────────────────────────
    let replyString = data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!replyString) {
      return new Response(
        JSON.stringify({
          reply: "Sorry, I couldn't generate a response.",
          action: "none",
          service_id: null,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Strip markdown code fences if Gemini wraps the JSON
    replyString = replyString.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Validate it is parseable JSON before returning
    let parsed: any;
    try {
      parsed = JSON.parse(replyString);
    } catch (_) {
      // If there's extra conversational text, try to extract just the JSON part
      const jsonMatch = replyString.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          parsed = JSON.parse(jsonMatch[0]);
        } catch (e) {
          parsed = { reply: replyString, action: "none", service_id: null };
        }
      } else {
        parsed = { reply: replyString, action: "none", service_id: null };
      }
    }

    // Ensure service_id is a valid UUID from our services list, otherwise null
    if (parsed.service_id) {
      const validIds = servicesData.map((s: any) => s.id);
      if (!validIds.includes(parsed.service_id)) {
        parsed.service_id = null;
      }
    }

    // ─────────────────────────────
    // 9. Success response
    // ─────────────────────────────
    return new Response(JSON.stringify(parsed), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("EDGE FUNCTION ERROR:", err);

    return new Response(
      JSON.stringify({
        reply: "Server error: " + (err as Error).message,
        action: "none",
        service_id: null,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});