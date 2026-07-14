const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type JsonMap = Record<string, unknown>;

function jsonResponse(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function stripeRequest(
  path: string,
  secretKey: string,
  body?: URLSearchParams,
): Promise<JsonMap> {
  const response = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: body == null ? "GET" : "POST",
    headers: {
      Authorization: `Bearer ${secretKey}`,
      ...(body == null
        ? {}
        : { "Content-Type": "application/x-www-form-urlencoded" }),
    },
    body,
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message =
      typeof data?.error?.message === "string"
        ? data.error.message
        : `Stripe request failed with ${response.status}`;
    throw new Error(message);
  }
  return data as JsonMap;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey || !stripeSecretKey) {
      throw new Error(
        "Missing SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, or STRIPE_SECRET_KEY.",
      );
    }

    const body = await request.json().catch(() => ({}));
    const orderNumber = `${body.orderNumber ?? ""}`.trim();
    const amount = Number(body.amount ?? 0);
    const reason = `${body.reason ?? "requested_by_customer"}`.trim();
    if (!orderNumber) {
      throw new Error("Missing orderNumber.");
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new Error("Refund amount must be greater than 0.");
    }

    const orderResponse = await fetch(
      `${supabaseUrl}/rest/v1/orders?select=order_number,payment_reference,payment_session_id,grand_total,email&order_number=eq.${encodeURIComponent(orderNumber)}&limit=1`,
      {
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      },
    );
    const orders = await orderResponse.json().catch(() => []);
    if (!orderResponse.ok || !Array.isArray(orders) || orders.length === 0) {
      throw new Error(`Order ${orderNumber} was not found.`);
    }

    const order = orders[0] as JsonMap;
    const reference = `${order.payment_reference ?? ""}`.trim();
    const sessionId = `${order.payment_session_id ?? ""}`.trim();
    let paymentIntent = reference.startsWith("pi_") ? reference : "";
    if (!paymentIntent && sessionId.startsWith("cs_")) {
      const session = await stripeRequest(
        `checkout/sessions/${encodeURIComponent(sessionId)}`,
        stripeSecretKey,
      );
      paymentIntent = `${session.payment_intent ?? ""}`.trim();
    }
    if (!paymentIntent) {
      throw new Error(
        "This order does not have a Stripe payment intent or checkout session id.",
      );
    }

    const refundBody = new URLSearchParams();
    refundBody.set("payment_intent", paymentIntent);
    refundBody.set("amount", `${Math.round(amount * 100)}`);
    refundBody.set("metadata[order_number]", orderNumber);
    if (reason) {
      refundBody.set("metadata[admin_reason]", reason);
    }
    const refund = await stripeRequest("refunds", stripeSecretKey, refundBody);
    const refundId = `${refund.id ?? ""}`.trim();
    if (!refundId) {
      throw new Error("Stripe did not return a refund id.");
    }

    await fetch(
      `${supabaseUrl}/rest/v1/orders?order_number=eq.${encodeURIComponent(orderNumber)}`,
      {
        method: "PATCH",
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
          Prefer: "return=minimal",
        },
        body: JSON.stringify({
          stripe_refund_id: refundId,
          refund_reference: refundId,
        }),
      },
    );

    return jsonResponse({ refundId, status: refund.status ?? "submitted" });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : `${error}` },
      400,
    );
  }
});
