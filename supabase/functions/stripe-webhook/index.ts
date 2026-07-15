// Stripe webhook handler for EgbeAnom order status updates.
// Verifies Stripe signatures and updates public.orders by order_number.

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
      'authorization, x-client-info, apikey, content-type, stripe-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Vary': 'Origin',
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const stripeWebhookSecrets = [
  Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '',
  Deno.env.get('STRIPE_WEBHOOK_SECRET_TEST') ?? '',
  Deno.env.get('STRIPE_WEBHOOK_SECRET_LIVE') ?? '',
]
  .map((value) => value.trim())
  .filter((value, index, array) => value.length > 0 && array.indexOf(value) === index);

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Missing Supabase function environment variables.');
}

if (stripeWebhookSecrets.length === 0) {
  throw new Error(
    'Missing Stripe webhook secret. Set STRIPE_WEBHOOK_SECRET or STRIPE_WEBHOOK_SECRET_TEST/STRIPE_WEBHOOK_SECRET_LIVE.',
  );
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
    const signatureHeader = request.headers.get('stripe-signature') ?? '';
    if (signatureHeader.trim().length === 0) {
      return json({ error: 'Missing stripe-signature header.' }, 400);
    }

    const rawBody = await request.text();
    const verified = await verifyStripeSignature(
      rawBody,
      signatureHeader,
      stripeWebhookSecrets,
    );
    if (!verified) {
      return json({ error: 'Invalid Stripe signature.' }, 400);
    }

    const event = parseJson(rawBody);
    const eventType = asString(event?.type).trim();
    if (eventType.length === 0) {
      return json({ error: 'Invalid Stripe event payload.' }, 400);
    }

    const object = asObject(asObject(event?.data)?.object);
    if (eventType === 'checkout.session.completed') {
      const result = await handleCheckoutCompleted(object);
      return json({
        received: true,
        eventType,
        orderNumber: result.orderNumber,
        updatedRows: result.updatedRows,
      });
    }

    const updates = buildOrderUpdate(eventType, object);
    if (updates == null) {
      // Unhandled events are acknowledged to avoid retries.
      return json({ received: true, ignored: true, eventType });
    }

    const { orderNumber, update } = updates;
    const { data, error } = await serviceClient
      .from('orders')
      .update(update)
      .eq('order_number', orderNumber)
      .select('order_number,status,financial_status,payment_reference')
      .limit(1);

    if (error) {
      throw new Error(`Supabase order update failed: ${error.message}`);
    }

    return json({
      received: true,
      eventType,
      orderNumber,
      updatedRows: Array.isArray(data) ? data.length : 0,
    });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'Webhook handling failed.' },
      400,
    );
  }
});

async function handleCheckoutCompleted(
  stripeObject: Json,
): Promise<{ orderNumber: string; updatedRows: number }> {
  const metadata = asObject(stripeObject.metadata);
  const orderNumber =
    asString(metadata.order_number) || asString(stripeObject.client_reference_id);
  if (!orderNumber) {
    throw new Error('checkout.session.completed missing order_number metadata.');
  }

  const paymentStatus = asString(stripeObject.payment_status).toLowerCase();
  if (paymentStatus !== 'paid') {
    throw new Error(`Stripe session for ${orderNumber} is not paid.`);
  }

  const amountTotal = asNumber(stripeObject.amount_total);
  const currency = asString(stripeObject.currency).toLowerCase();
  if (currency !== 'usd') {
    throw new Error(`Stripe session for ${orderNumber} used unexpected currency ${currency}.`);
  }

  const sessionId = asString(stripeObject.id);
  const paymentReference =
    asString(stripeObject.payment_intent) || sessionId;
  const { data: order, error: orderError } = await serviceClient
    .from('orders')
    .select('order_number,email,grand_total,financial_status,payment_session_id,payment_reference')
    .eq('order_number', orderNumber)
    .maybeSingle();
  if (orderError) {
    throw new Error(`Supabase order lookup failed: ${orderError.message}`);
  }
  if (!order) {
    throw new Error(`Order ${orderNumber} was not found.`);
  }

  const expectedAmount = Math.round(asNumber(order.grand_total) * 100);
  if (amountTotal !== expectedAmount) {
    throw new Error(
      `Stripe amount mismatch for ${orderNumber}: expected ${expectedAmount}, received ${amountTotal}.`,
    );
  }

  const storedSessionId = asString(order.payment_session_id);
  if (storedSessionId && storedSessionId !== sessionId) {
    throw new Error(`Stripe session mismatch for ${orderNumber}.`);
  }

  const existingFinancialStatus = asString(order.financial_status).toLowerCase();
  if (existingFinancialStatus === 'paid') {
    return { orderNumber, updatedRows: 0 };
  }

  const { data, error } = await serviceClient
    .from('orders')
    .update({
      status: 'Paid',
      financial_status: 'Paid',
      fulfillment_status: 'Pending',
      payment_provider: 'stripe',
      payment_reference: paymentReference,
      payment_session_id: sessionId,
    })
    .eq('order_number', orderNumber)
    .select('order_number');
  if (error) {
    throw new Error(`Supabase order update failed: ${error.message}`);
  }

  const { error: inventoryError } = await serviceClient.rpc('decrement_inventory_for_order', {
    p_order_number: orderNumber,
    p_email: asString(order.email),
  });
  if (inventoryError) {
    throw new Error(`Inventory update failed: ${inventoryError.message}`);
  }

  await serviceClient.from('active_carts').update({
    status: 'recovered',
    recovered_at: new Date().toISOString(),
    last_seen_at: new Date().toISOString(),
  }).eq('customer_email', asString(order.email).trim().toLowerCase()).eq('status', 'active');

  await serviceClient.from('admin_notifications').upsert({
    id: `N-order-paid-${orderNumber}`,
    type: 'payment',
    title: 'Order paid',
    message: `${orderNumber} was paid successfully and is ready for fulfillment.`,
    is_read: false,
    created_at: new Date().toISOString(),
  }, { onConflict: 'id' });

  return {
    orderNumber,
    updatedRows: Array.isArray(data) ? data.length : 0,
  };
}

function buildOrderUpdate(
  eventType: string,
  stripeObject: Json,
): { orderNumber: string; update: Json } | null {
  if (eventType === 'checkout.session.completed') {
    const metadata = asObject(stripeObject.metadata);
    const orderNumber =
      asString(metadata.order_number) || asString(stripeObject.client_reference_id);
    if (!orderNumber) {
      throw new Error('checkout.session.completed missing order_number metadata.');
    }
    const paymentReference =
      asString(stripeObject.payment_intent) || asString(stripeObject.id);
    return {
      orderNumber,
      update: {
        status: 'Paid',
        financial_status: 'Paid',
        fulfillment_status: 'Unfulfilled',
        payment_provider: 'stripe',
        payment_reference: paymentReference,
      },
    };
  }

  if (
    eventType === 'checkout.session.expired' ||
    eventType === 'payment_intent.payment_failed' ||
    eventType === 'payment_intent.canceled'
  ) {
    const metadata = asObject(stripeObject.metadata);
    const orderNumber =
      asString(metadata.order_number) || asString(stripeObject.client_reference_id);
    if (!orderNumber) {
      throw new Error(`${eventType} missing order_number metadata.`);
    }
    const paymentReference = asString(stripeObject.id);
    return {
      orderNumber,
      update: {
        status: 'Pending',
        financial_status: 'Unpaid',
        payment_provider: 'stripe',
        payment_reference: paymentReference,
      },
    };
  }

  if (
    eventType === 'refund.created' ||
    eventType === 'refund.updated' ||
    eventType === 'charge.refunded'
  ) {
    const metadata = asObject(stripeObject.metadata);
    const orderNumber = asString(metadata.order_number);
    if (!orderNumber) {
      return null;
    }
    const refundedAmount =
      eventType === 'charge.refunded'
        ? asCentsAmount(stripeObject.amount_refunded)
        : asCentsAmount(stripeObject.amount);
    const chargeFullyRefunded =
      eventType === 'charge.refunded' && stripeObject.refunded === true;
    const markedFullRefund =
      asString(metadata.refund_status).toLowerCase() === 'refunded' ||
      asString(metadata.refund_type).toLowerCase() === 'full';
    const refundSucceeded = chargeFullyRefunded || markedFullRefund;
    return {
      orderNumber,
      update: {
        status: refundSucceeded ? 'Refunded' : 'Paid',
        financial_status: refundSucceeded ? 'Refunded' : 'Partially refunded',
        refund_status: refundSucceeded ? 'Refunded' : 'Partially refunded',
        refund_total: refundedAmount,
        refund_reference: asString(stripeObject.id),
        refund_reason: asString(stripeObject.reason),
        refunded_at: new Date().toISOString(),
      },
    };
  }

  return null;
}

async function verifyStripeSignature(
  payload: string,
  signatureHeader: string,
  signingSecrets: string[],
): Promise<boolean> {
  const parsed = parseStripeSignature(signatureHeader);
  if (!parsed || !parsed.timestamp || parsed.signatures.length === 0) {
    return false;
  }

  const ageSeconds = Math.abs(Math.floor(Date.now() / 1000) - parsed.timestamp);
  if (ageSeconds > 300) {
    return false;
  }

  const signedPayload = `${parsed.timestamp}.${payload}`;
  const encoder = new TextEncoder();
  for (const signingSecret of signingSecrets) {
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(signingSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign'],
    );
    const signatureBytes = await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(signedPayload),
    );
    const expected = toHex(new Uint8Array(signatureBytes));

    for (const actual of parsed.signatures) {
      if (timingSafeEqual(expected, actual)) {
        return true;
      }
    }
  }
  return false;
}

function parseStripeSignature(header: string): {
  timestamp: number;
  signatures: string[];
} | null {
  const parts = header.split(',').map((entry) => entry.trim());
  let timestamp = 0;
  const signatures: string[] = [];

  for (const part of parts) {
    const [key, value] = part.split('=', 2);
    if (!key || !value) {
      continue;
    }
    if (key === 't') {
      timestamp = Number.parseInt(value, 10) || 0;
      continue;
    }
    if (key === 'v1') {
      signatures.push(value);
    }
  }

  return { timestamp, signatures };
}

function timingSafeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < left.length; i++) {
    diff |= left.charCodeAt(i) ^ right.charCodeAt(i);
  }
  return diff === 0;
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((value) => value.toString(16).padStart(2, '0'))
    .join('');
}

function parseJson(raw: string): Json {
  const parsed = JSON.parse(raw);
  return asObject(parsed);
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

function asCentsAmount(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value)
    ? Math.round(value) / 100
    : 0;
}

function json(payload: Json, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
