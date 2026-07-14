// Tracking status refresh endpoint for admin order operations.

// @ts-ignore Remote URL import is resolved by Supabase Edge Runtime (Deno).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

declare const Deno: {
  env: { get: (name: string) => string | undefined };
  serve: (handler: (request: Request) => Response | Promise<Response>) => unknown;
};

type Json = Record<string, unknown>;

const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN') ?? 'https://egbeanom.com',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
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
    await requireBackendUser(request);
    const body = (await request.json()) as Json;
    const orderNumber = stringValue(body.orderNumber).trim();
    if (!orderNumber) {
      return json({ error: 'orderNumber is required.' }, 400);
    }

    const { data: order, error } = await serviceClient
      .from('orders')
      .select('order_number,shipping_carrier,tracking_number,fulfillment_status,status,tracking_status')
      .eq('order_number', orderNumber)
      .limit(1)
      .maybeSingle();
    if (error) {
      throw new Error(`Could not load order: ${error.message}`);
    }
    if (!order) {
      return json({ error: 'Order was not found.' }, 404);
    }

    const trackingNumber = stringValue(order.tracking_number).trim();
    const carrier = stringValue(order.shipping_carrier).trim();
    const trackingUrl = trackingUrlForCarrier(carrier, trackingNumber);
    const trackingStatus = inferTrackingStatus(order as Json, trackingNumber);
    const checkedAt = new Date().toISOString();

    const { error: updateError } = await serviceClient
      .from('orders')
      .update({
        tracking_status: trackingStatus,
        tracking_url: trackingUrl,
        tracking_last_checked_at: checkedAt,
      })
      .eq('order_number', orderNumber);
    if (updateError) {
      throw new Error(`Could not update tracking status: ${updateError.message}`);
    }

    return json({
      orderNumber,
      carrier,
      trackingNumber,
      trackingStatus,
      trackingUrl,
      checkedAt,
      source: 'egbeanom_tracking_refresh',
    });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'Tracking refresh failed.' },
      400,
    );
  }
});

async function requireBackendUser(request: Request) {
  const authHeader = request.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    throw new Error('Missing authorization token.');
  }
  const { data, error } = await serviceClient.auth.getUser(token);
  if (error || !data.user) {
    throw new Error('Could not verify Supabase user.');
  }
  const { data: rows, error: rowError } = await serviceClient
    .from('backend_users')
    .select('id,email,is_active,is_blocked,auth_user_id')
    .or(`auth_user_id.eq.${data.user.id},email.eq.${data.user.email ?? ''}`)
    .limit(1);
  if (rowError || !rows?.length || rows[0].is_active === false || rows[0].is_blocked === true) {
    throw new Error('Backend admin access is required for tracking operations.');
  }
  return rows[0];
}

function inferTrackingStatus(order: Json, trackingNumber: string): string {
  if (!trackingNumber) {
    return 'Tracking pending';
  }
  const fulfillment = stringValue(order.fulfillment_status).toLowerCase();
  const status = stringValue(order.status).toLowerCase();
  if (fulfillment == 'delivered' || status == 'delivered') {
    return 'Delivered';
  }
  if (fulfillment == 'shipped' || status == 'shipped' || status == 'sent') {
    return 'Shipped';
  }
  if (fulfillment == 'label created' || status == 'label created') {
    return 'Label created';
  }
  return stringValue(order.tracking_status).trim() || 'Tracking available';
}

function trackingUrlForCarrier(carrier: string, trackingNumber: string): string {
  if (!trackingNumber) {
    return '';
  }
  const encoded = encodeURIComponent(trackingNumber);
  switch (carrier.trim().toUpperCase()) {
    case 'UPS':
      return `https://www.ups.com/track?tracknum=${encoded}`;
    case 'FEDEX':
      return `https://www.fedex.com/fedextrack/?trknbr=${encoded}`;
    case 'DHL':
      return `https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=${encoded}`;
    default:
      return `https://tools.usps.com/go/TrackConfirmAction?tLabels=${encoded}`;
  }
}

function stringValue(value: unknown): string {
  return typeof value === 'string' ? value : value == null ? '' : `${value}`;
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
