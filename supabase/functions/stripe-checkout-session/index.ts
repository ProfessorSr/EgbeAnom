// Stripe Checkout Session creator for EgbeAnom storefront.
// The browser sends only an order number and return URLs; totals are loaded
// from Supabase so checkout pricing cannot be changed client-side.

// @ts-ignore Remote URL import is resolved by Supabase Edge Runtime (Deno).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

declare const Deno: {
  env: { get: (name: string) => string | undefined };
  serve: (handler: (request: Request) => Response | Promise<Response>) => unknown;
};

type Json = Record<string, unknown>;

const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN') ?? 'https://egbeanom.com',
  'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Vary': 'Origin',
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Missing Supabase function environment variables.');
}

const serviceClient = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed.' }, 405);
  }

  try {
    const body = asObject(await request.json());
    const orderNumber = asString(body.orderNumber).trim();
    const successUrl = asString(body.successUrl).trim();
    const cancelUrl = asString(body.cancelUrl).trim();
    const mode = asString(body.mode).trim().toLowerCase();
    const stripeSecretKey = selectStripeSecretKey(mode);

    if (!orderNumber) {
      return json({ error: 'orderNumber is required.' }, 400);
    }
    await enforceRateLimit(
      'stripe_checkout_session',
      `${clientIp(request)}:${orderNumber}`,
      60,
      6,
    );
    if (!successUrl || !cancelUrl) {
      return json({ error: 'successUrl and cancelUrl are required.' }, 400);
    }

    const { data: order, error: orderError } = await serviceClient
      .from('orders')
      .select('*')
      .eq('order_number', orderNumber)
      .maybeSingle();
    if (orderError) {
      throw new Error(`Order lookup failed: ${orderError.message}`);
    }
    if (!order) {
      return json({ error: 'Order was not found.' }, 404);
    }

    const financialStatus = asString(order.financial_status).toLowerCase();
    if (financialStatus === 'paid' || financialStatus === 'refunded') {
      return json({ error: 'Order is no longer eligible for checkout.' }, 409);
    }

    const currency = 'usd';
    const targetAmount = Math.round(asNumber(order.grand_total) * 100);
    if (targetAmount <= 0) {
      return json({ error: 'Stored order total must be greater than 0.' }, 400);
    }

    const { data: orderItems, error: itemError } = await serviceClient
      .from('order_items')
      .select('*')
      .eq('order_id', orderNumber)
      .order('id', { ascending: true });
    if (itemError) {
      throw new Error(`Order item lookup failed: ${itemError.message}`);
    }

    const checkoutItems = buildCheckoutLineItems(
      Array.isArray(orderItems) ? orderItems : [],
      order,
      targetAmount,
    );

    const params = new URLSearchParams();
    params.set('mode', 'payment');
    params.set('success_url', successUrl);
    params.set('cancel_url', cancelUrl);
    params.set('client_reference_id', orderNumber);
    params.set('metadata[order_number]', orderNumber);
    params.set('metadata[customer_email]', asString(order.email));
    for (let index = 0; index < checkoutItems.length; index += 1) {
      const item = checkoutItems[index];
      params.set(`line_items[${index}][price_data][currency]`, currency);
      params.set(`line_items[${index}][price_data][unit_amount]`, `${item.amount}`);
      params.set(`line_items[${index}][price_data][product_data][name]`, item.name);
      params.set(`line_items[${index}][quantity]`, `${item.quantity}`);
    }
    const customerEmail = asString(order.email).trim();
    if (customerEmail) {
      params.set('customer_email', customerEmail);
    }

    const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    const stripeJson = asObject(await stripeResponse.json());
    if (!stripeResponse.ok) {
      const stripeError = asObject(stripeJson.error);
      const message = asString(stripeError.message) || 'Stripe checkout session creation failed.';
      return json({ error: message, stripe: stripeJson }, 400);
    }

    const checkoutUrl = asString(stripeJson.url).trim();
    const sessionId = asString(stripeJson.id).trim();
    if (!checkoutUrl || !sessionId) {
      return json({ error: 'Stripe did not return a checkout URL and session ID.' }, 400);
    }

    const { error: updateError } = await serviceClient
      .from('orders')
      .update({
        payment_provider: 'stripe',
        payment_reference: sessionId,
        payment_session_id: sessionId,
        updated_at: new Date().toISOString(),
      })
      .eq('order_number', orderNumber);
    if (updateError) {
      throw new Error(`Could not save Stripe session ID: ${updateError.message}`);
    }

    return json({
      url: checkoutUrl,
      sessionId,
      orderNumber,
    });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'Stripe checkout session creation failed.' },
      400,
    );
  }
});

function buildCheckoutLineItems(
  orderItems: Json[],
  order: Json,
  targetAmount: number,
): Array<{ name: string; amount: number; quantity: number }> {
  const items: Array<{ name: string; amount: number; quantity: number }> = [];
  let runningTotal = 0;
  let hasAdjustment = false;
  for (const item of orderItems) {
    const lineTotal = Math.round(asNumber(item.line_total) * 100);
    if (lineTotal <= 0) {
      continue;
    }
    const name = [
      asNumber(item.quantity) > 1 ? `${Math.round(asNumber(item.quantity))} x` : '',
      asString(item.product_name).trim() || 'Egbe Anom item',
      asString(item.size).trim(),
    ]
      .filter((part) => part.length > 0)
      .join(' ');
    items.push({ name, amount: lineTotal, quantity: 1 });
    runningTotal += lineTotal;
  }

  const discount = Math.round(asNumber(order.discount_total) * 100);
  if (discount > 0) {
    hasAdjustment = true;
    runningTotal -= discount;
  }

  const shipping = Math.round(asNumber(order.shipping_total) * 100);
  if (shipping > 0) {
    items.push({ name: 'Shipping', amount: shipping, quantity: 1 });
    runningTotal += shipping;
  }

  const tax = Math.round(asNumber(order.tax_total) * 100);
  if (tax > 0) {
    items.push({ name: 'Tax', amount: tax, quantity: 1 });
    runningTotal += tax;
  }

  const positiveItems = items.filter((item) => item.amount > 0);
  if (positiveItems.length === 0 || runningTotal !== targetAmount || hasAdjustment) {
    return [{ name: 'Egbe Anom order', amount: targetAmount, quantity: 1 }];
  }
  return positiveItems;
}

function selectStripeSecretKey(mode: string): string {
  const isLive = mode === 'live';
  const specific = Deno.env.get(
    isLive ? 'STRIPE_SECRET_KEY_LIVE' : 'STRIPE_SECRET_KEY_TEST',
  );
  if (specific && specific.trim().length > 0) {
    return specific.trim();
  }
  const fallback = Deno.env.get('STRIPE_SECRET_KEY') ?? '';
  if (fallback.trim().length > 0) {
    return fallback.trim();
  }
  throw new Error(
    'Missing Stripe secret key. Set STRIPE_SECRET_KEY_TEST/STRIPE_SECRET_KEY_LIVE or STRIPE_SECRET_KEY.',
  );
}

function asObject(value: unknown): Json {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Json;
  }
  return {};
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function asNumber(value: unknown): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

async function enforceRateLimit(
  scope: string,
  subject: string,
  windowSeconds: number,
  maxEvents: number,
): Promise<void> {
  const { data, error } = await serviceClient.rpc('check_rate_limit', {
    p_scope: scope,
    p_subject: subject,
    p_window_seconds: windowSeconds,
    p_max_events: maxEvents,
  });
  if (error) {
    throw new Error(`Rate limit check failed: ${error.message}`);
  }
  if (data !== true) {
    throw new Error('Too many attempts. Please wait a minute and try again.');
  }
}

function clientIp(request: Request): string {
  return (
    request.headers.get('x-forwarded-for')?.split(',').shift()?.trim() ||
    request.headers.get('cf-connecting-ip') ||
    'unknown'
  );
}

function json(payload: Json, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
