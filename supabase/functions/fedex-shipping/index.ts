import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type Json = Record<string, unknown>;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Missing Supabase function environment variables.');
}

const serviceClient = createClient(supabaseUrl, serviceRoleKey);
const FEDEX_OAUTH_URL = 'https://apis.fedex.com/oauth/token';
const FEDEX_RATES_URL = 'https://apis.fedex.com/rate/v1/rates/quotes';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = (await request.json()) as Json;
    const user = await requireBackendUser(request);
    const settings = await loadFedexSettings();
    
    if (!settings.credentials.clientId || !settings.credentials.clientSecret) {
      throw new Error('FedEx OAuth credentials are not configured.');
    }

    const oauthToken = await fetchFedexOAuthToken(settings.credentials);
    const action = `${body.action ?? ''}`;
    
    if (action === 'quoteRates') {
      const result = await quoteRates(
        body.request as Json,
        oauthToken,
        settings.credentials,
      );
      return json({ quotes: result, user: user.email });
    }
    
    if (action === 'createLabel') {
      const result = await createLabel(
        body.order as Json,
        body.storeInfo as Json,
        body.package as Json,
        oauthToken,
        settings.credentials,
      );
      return json(result);
    }
    
    return json({ error: 'Unsupported FedEx action.' }, 400);
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'FedEx request failed.' },
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
    throw new Error('Backend admin access is required for FedEx operations.');
  }
  return rows[0];
}

async function loadFedexSettings() {
  const { data: providerData, error: providerError } = await serviceClient
    .from('site_settings')
    .select('value')
    .eq('key', 'shipping_carrier_credentials_fedex')
    .limit(1)
    .maybeSingle();
  if (providerError) {
    throw new Error(`Could not load FedEx credentials: ${providerError.message}`);
  }
  if (providerData?.value && typeof providerData.value === 'object') {
    const raw = providerData.value as Json;
    return {
      credentials: {
        accountNumber: stringValue(raw.account_number),
        meterNumber: stringValue(raw.meter_number),
        apiKey: stringValue(raw.api_key),
        apiSecret: stringValue(raw.api_secret),
        clientId: stringValue(raw.client_id),
        clientSecret: stringValue(raw.client_secret),
      },
    };
  }

  const { data, error } = await serviceClient
    .from('site_settings')
    .select('value')
    .eq('key', 'shipping_carrier_credentials')
    .limit(1)
    .maybeSingle();
  if (error) {
    throw new Error(`Could not load shipping credentials: ${error.message}`);
  }
  const value = (data?.value ?? {}) as Json;
  const raw = ((value.FedEx as Json | undefined) ?? {}) as Json;
  return {
    credentials: {
      accountNumber: stringValue(raw.account_number),
      meterNumber: stringValue(raw.meter_number),
      apiKey: stringValue(raw.api_key),
      apiSecret: stringValue(raw.api_secret),
      clientId: stringValue(raw.client_id),
      clientSecret: stringValue(raw.client_secret),
    },
  };
}

async function fetchFedexOAuthToken(credentials: {
  clientId: string;
  clientSecret: string;
}) {
  const response = await fetch(FEDEX_OAUTH_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: credentials.clientId,
      client_secret: credentials.clientSecret,
    }).toString(),
  });
  const jsonBody = await response.json();
  if (!response.ok || !jsonBody.access_token) {
    throw new Error(stringValue(jsonBody.error_description) || 'FedEx OAuth token request failed.');
  }
  return stringValue(jsonBody.access_token);
}

async function quoteRates(
  request: Json,
  oauthToken: string,
  credentials: {
    accountNumber: string;
    meterNumber: string;
  },
) {
  if (!credentials.accountNumber || !credentials.meterNumber) {
    throw new Error('FedEx account number and meter number are required for rate quotes.');
  }
  const originZip = stringValue(request.originZip);
  const destinationZip = stringValue(request.destinationZip);
  if (!originZip || !destinationZip) {
    throw new Error('Origin and destination ZIP codes are required for FedEx rate quotes.');
  }

  const payload = {
    accountNumber: credentials.accountNumber,
    rateRequestControlParameters: {
      returnTransitTimes: true,
      servicesNeededOnly: false,
    },
    requestedShipment: {
      shipper: {
        address: {
          postalCode: originZip,
          countryCode: 'US',
        },
      },
      recipient: {
        address: {
          postalCode: destinationZip,
          countryCode: 'US',
        },
      },
      shipDateStamp: new Date().toISOString().split('T')[0],
      pickupType: 'DROPOFF_AT_FDX_LOCATION',
      requestedPackageLineItems: [
        {
          weight: {
            units: 'LB',
            value: poundsFromOunces(numberValue(request.weightOz, 8)),
          },
          dimensions: {
            length: numberValue(request.lengthIn, 6),
            width: numberValue(request.widthIn, 3),
            height: numberValue(request.heightIn, 3),
            units: 'IN',
          },
        },
      ],
    },
  };

  const response = await fetch(FEDEX_RATES_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${oauthToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
  });

  const jsonBody = await response.json();
  if (!response.ok) {
    throw new Error(
      stringValue(jsonBody?.errors?.[0]?.message) ||
      `FedEx rate lookup failed: ${response.statusText}`,
    );
  }

  const rateReplyDetails = Array.isArray(jsonBody?.rateReplyDetails)
    ? (jsonBody.rateReplyDetails as Json[])
    : [];

  return rateReplyDetails.slice(0, 3).map((entry) => {
    const ratedShipmentDetails = Array.isArray(entry.ratedShipmentDetails)
      ? (entry.ratedShipmentDetails as Json[])
      : [];
    const detail = ratedShipmentDetails[0] ?? {};
    const shippingCharges = (detail.shippingCharges as Json | undefined) ?? {};
    const totalCharges = (shippingCharges.totalSurchargesAndFees as Json | undefined) ??
      (shippingCharges.baseCharge as Json | undefined) ?? {};

    return {
      carrier: 'FedEx',
      service: stringValue(entry.serviceType) || 'FedEx Service',
      amount: parseFloat(stringValue(totalCharges.amount, '0')),
      currency: 'USD',
      estimatedDays: numberValue(entry.operationalDetail?.aPackageDeliveryEstimate, 3),
    };
  });
}

async function createLabel(
  order: Json,
  storeInfo: Json,
  packageInfo: Json,
  oauthToken: string,
  credentials: {
    accountNumber: string;
    meterNumber: string;
  },
) {
  if (!credentials.accountNumber || !credentials.meterNumber) {
    throw new Error('FedEx account number and meter number are required for label creation.');
  }

  const address = ((order.shipping_address as Json | undefined) ?? {}) as Json;
  if (!stringValue(address.address_line1) || !stringValue(address.city) || !stringValue(address.state) || !stringValue(address.postal_code)) {
    throw new Error('The order is missing a complete shipping address for FedEx label creation.');
  }

  throw new Error('FedEx label creation is not connected to the FedEx Ship API yet.');
}

function json(data: Json, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function stringValue(val: unknown, fallback = ''): string {
  return typeof val === 'string' ? val : fallback;
}

function numberValue(val: unknown, fallback = 0): number {
  const num = typeof val === 'number' ? val : parseFloat(`${val}`);
  return isNaN(num) ? fallback : num;
}

function poundsFromOunces(ounces: number): number {
  return parseFloat((ounces / 16).toFixed(2));
}
