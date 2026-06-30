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
const UPS_OAUTH_URL = 'https://onlinetools.ups.com/security/v1/oauth/token';
const UPS_RATES_URL = 'https://onlinetools.ups.com/rest/v1/rating/Rate';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = (await request.json()) as Json;
    const user = await requireBackendUser(request);
    const settings = await loadUpsSettings();
    
    if (!settings.credentials.clientId || !settings.credentials.clientSecret) {
      throw new Error('UPS OAuth credentials are not configured.');
    }

    const oauthToken = await fetchUpsOAuthToken(settings.credentials);
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
    
    return json({ error: 'Unsupported UPS action.' }, 400);
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'UPS request failed.' },
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
    throw new Error('Backend admin access is required for UPS operations.');
  }
  return rows[0];
}

async function loadUpsSettings() {
  const { data: providerData, error: providerError } = await serviceClient
    .from('site_settings')
    .select('value')
    .eq('key', 'shipping_carrier_credentials_ups')
    .limit(1)
    .maybeSingle();
  if (providerError) {
    throw new Error(`Could not load UPS credentials: ${providerError.message}`);
  }
  if (providerData?.value && typeof providerData.value === 'object') {
    const raw = providerData.value as Json;
    return {
      credentials: {
        accountNumber: stringValue(raw.account_number),
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
  const raw = ((value.UPS as Json | undefined) ?? {}) as Json;
  return {
    credentials: {
      accountNumber: stringValue(raw.account_number),
      apiKey: stringValue(raw.api_key),
      apiSecret: stringValue(raw.api_secret),
      clientId: stringValue(raw.client_id),
      clientSecret: stringValue(raw.client_secret),
    },
  };
}

async function fetchUpsOAuthToken(credentials: {
  clientId: string;
  clientSecret: string;
}) {
  const auth = btoa(`${credentials.clientId}:${credentials.clientSecret}`);
  const response = await fetch(UPS_OAUTH_URL, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });
  const jsonBody = await response.json();
  if (!response.ok || !jsonBody.access_token) {
    throw new Error(stringValue(jsonBody.error_description) || 'UPS OAuth token request failed.');
  }
  return stringValue(jsonBody.access_token);
}

async function quoteRates(
  request: Json,
  oauthToken: string,
  credentials: {
    accountNumber: string;
  },
) {
  if (!credentials.accountNumber) {
    throw new Error('UPS account number is required for rate quotes.');
  }
  const originZip = stringValue(request.originZip);
  const destinationZip = stringValue(request.destinationZip);
  if (!originZip || !destinationZip) {
    throw new Error('Origin and destination ZIP codes are required for UPS rate quotes.');
  }

  const payload = {
    RateRequest: {
      Request: {
        RequestOption: 'rate',
        SubVersion: '2408',
      },
      Shipment: {
        Shipper: {
          ShipperNumber: credentials.accountNumber,
          Address: {
            PostalCode: originZip,
            CountryCode: 'US',
          },
        },
        ShipTo: {
          Address: {
            PostalCode: destinationZip,
            CountryCode: 'US',
          },
        },
        Package: {
          PackagingType: {
            Code: '02',
          },
          Dimensions: {
            UnitOfMeasurement: {
              Code: 'IN',
            },
            Length: numberValue(request.lengthIn, 6),
            Width: numberValue(request.widthIn, 3),
            Height: numberValue(request.heightIn, 3),
          },
          PackageWeight: {
            UnitOfMeasurement: {
              Code: 'LBS',
            },
            Weight: poundsFromOunces(numberValue(request.weightOz, 8)),
          },
        },
      },
    },
  };

  const response = await fetch(UPS_RATES_URL, {
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
      stringValue(jsonBody?.response?.errors?.[0]?.message) ||
      `UPS rate lookup failed: ${response.statusText}`,
    );
  }

  const ratedShipment = Array.isArray(jsonBody?.RateResponse?.RatedShipment)
    ? (jsonBody.RateResponse.RatedShipment as Json[])
    : [];

  return ratedShipment.map((entry) => {
    const service = (entry.Service as Json | undefined) ?? {};
    const totalCharges = (entry.TotalCharges as Json | undefined) ?? {};
    return {
      carrier: 'UPS',
      service: stringValue(service.Description) || 'UPS Service',
      amount: parseFloat(stringValue(totalCharges.MonetaryValue, '0')),
      currency: 'USD',
      estimatedDays: numberValue(entry.GuaranteedDaysToDelivery, 3),
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
  },
) {
  if (!credentials.accountNumber) {
    throw new Error('UPS account number is required for label creation.');
  }

  const address = ((order.shipping_address as Json | undefined) ?? {}) as Json;
  if (!stringValue(address.address_line1) || !stringValue(address.city) || !stringValue(address.state) || !stringValue(address.postal_code)) {
    throw new Error('The order is missing a complete shipping address for UPS label creation.');
  }

  throw new Error('UPS label creation is not connected to the UPS Ship API yet.');
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
