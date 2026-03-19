// supabase/functions/create-payment-intent/index.ts
//
// Deploy:  supabase functions deploy create-payment-intent --no-verify-jwt
// Secrets: STRIPE_SECRET_KEY

import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

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
    // ── Auth ──────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Parse body ────────────────────────────────────────────────────────
    const { amount, orderId, description } = await req.json();

    if (!amount || !orderId) {
      return new Response(
        JSON.stringify({ error: "amount and orderId are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Currency: BDT ─────────────────────────────────────────────────────
    // Stripe supports BDT (Bangladeshi Taka) as a zero-decimal currency.
    // BDT has NO sub-unit (no poisha in Stripe's system), so the amount
    // is passed as-is (no multiplication by 100).
    //
    // Example: ৳500 → amount: 500  (NOT 50000)
    //
    // Stripe supported BDT reference:
    // https://stripe.com/docs/currencies#zero-decimal
    //
    // Note: BDT is supported only on specific Stripe accounts.
    // If your Stripe account doesn't support BDT, contact Stripe support
    // or use a supported currency like USD with a fixed exchange rate.

    const amountInSmallestUnit = Math.round(amount); // BDT is zero-decimal

    // ── Create PaymentIntent ──────────────────────────────────────────────
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInSmallestUnit,
      currency: "bdt",
      automatic_payment_methods: { enabled: true },
      metadata: {
        order_id: orderId,
        user_id: user.id,
        user_email: user.email ?? "",
      },
      description: description ?? `EzeeWash order ${orderId}`,
    });

    // ── Save payment record ───────────────────────────────────────────────
    const adminSupabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    await adminSupabase.from("payments").upsert(
      {
        order_id: orderId,
        user_id: user.id,
        amount: amount,
        currency: "bdt",
        payment_method: "stripe",
        status: "processing",
        stripe_payment_intent_id: paymentIntent.id,
      },
      { onConflict: "stripe_payment_intent_id" }
    );

    await adminSupabase
      .from("orders")
      .update({ stripe_payment_intent_id: paymentIntent.id })
      .eq("id", orderId);

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("create-payment-intent error:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});