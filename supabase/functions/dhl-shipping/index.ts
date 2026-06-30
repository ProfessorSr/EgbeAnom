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
const DHL_RATINGS_URL = 'https://express.api.dhl.com/mydhl/in/shipments/rates';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = (await request.json()) as Json;
    const user = await requireBackendUser(request);
    const settings = await loadDhlSettings();
    
    if (!settings.credentials.apiKey) {
      throw new Error('DHL API key is not configured.');
    }

    const action = `${body.action ?? ''}`;
    
    if (action === 'quoteRates') {
      const result = await quoteRates(
        body.request as Json,
        settings.credentials,
      );
      return json({ quotes: result, user: user.email });
    }
    
    if (action === 'createLabel') {
      const result = await createLabel(
        body.order as Json,
        body.storeInfo as Json,
        body.package as Json,
        settings.credentials,
      );
      return json(result);
    }
    
    return json({ error: 'Unsupported DHL action.' }, 400);
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'DHL request failed.' },
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
    throw new Error('Backend admin access is required for DHL operations.');
  }
  return rows[0];
}

async function loadDhlSettings() {
  const { data: providerData, error: providerError } = await serviceClient
    .from('site_settings')
    .select('value')
    .eq('key', 'shipping_carrier_credentials_dhl')
    .limit(1)
    .maybeSingle();
  if (providerError) {
    throw new Error(`Could not load DHL credentials: ${providerError.message}`);
  }
  if (providerData?.value && typeof providerData.value === 'object') {
    const raw = providerData.value as Json;
    return {
      credentials: {
        accountNumber: stringValue(raw.account_number),
        siteId: stringValue(raw.site_id),
        apiKey: stringValue(raw.api_key),
        apiPassword: stringValue(raw.api_password),
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
  const raw = ((value.DHL as Json | undefined) ?? {}) as Json;
  return {
    credentials: {
      accountNumber: stringValue(raw.account_number),
      siteId: stringValue(raw.site_id),
      apiKey: stringValue(raw.api_key),
      apiPassword: stringValue(raw.api_password),
      clientId: stringValue(raw.client_id),
      clientSecret: stringValue(raw.client_secret),
    },
  };
}

async function quoteRates(
  request: Json,
  credentials: {
    accountNumber: string;
    apiKey: string;
  },
) {
  if (!credentials.accountNumber || !credentials.apiKey) {
    throw new Error('DHL account number and API key are required for rate quotes.');
  }
  const originZip = stringValue(request.originZip);
  const destinationZip = stringValue(request.destinationZip);
  if (!originZip || !destinationZip) {
    throw new Error('Origin and destination ZIP codes are required for DHL rate quotes.');
  }

  const payload = {
    AccountNumber: credentials.accountNumber,
    RequestedShipment: {
      ShipmentRateType: 'ACCOUNT',
      Ship: {
        Shipper: {
          PostalAddress: {
            PostalCode: originZip,
            CountryCode: 'US',
          },
        },
        Recipient: {
          PostalAddress: {
            PostalCode: destinationZip,
            CountryCode: 'US',
          },
        },
        Shipment: {
          Weight: {
            Value: poundsFromOunces(numberValue(request.weightOz, 8)),
            UnitOfMeasurement: 'LB',
          },
          Dimensions: {
            Length: numberValue(request.lengthIn, 6),
            Width: numberValue(request.widthIn, 3),
            Height: numberValue(request.heightIn, 3),
            UnitOfMeasurement: 'IN',
          },
        },
      },
    },
  };

  const response = await fetch(DHL_RATINGS_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${btoa(`${credentials.accountNumber}:${credentials.apiKey}`)}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
  });

  const jsonBody = await response.json();
  if (!response.ok) {
    throw new Error(
      stringValue(jsonBody?.message) || `DHL rate lookup failed: ${response.statusText}`,
    );
  }

  const products = Array.isArray(jsonBody?.products)
    ? (jsonBody.products as Json[])
    : [];

  return products.slice(0, 3).map((entry) => {
    const totalPrice = (entry.totalPrice as Json[])?.[0] ?? {};
    return {
      carrier: 'DHL',
      service: stringValue(entry.productName) || 'DHL Service',
      amount: parseFloat(stringValue(totalPrice.price, '0')),
      currency: stringValue(totalPrice.currency, 'USD'),
      estimatedDays: numberValue(entry.deliveryTimeFrames?.[0]?.dayOfWeek, 3),
    };
  });
}

async function createLabel(
  order: Json,
  storeInfo: Json,
  packageInfo: Json,
  credentials: {
    accountNumber: string;
  },
) {
  if (!credentials.accountNumber) {
    throw new Error('DHL account number is required for label creation.');
  }

  const address = ((order.shipping_address as Json | undefined) ?? {}) as Json;
  if (!stringValue(address.address_line1) || !stringValue(address.city) || !stringValue(address.state) || !stringValue(address.postal_code)) {
    throw new Error('The order is missing a complete shipping address for DHL label creation.');
  }

  throw new Error('DHL label creation is not connected to the DHL Shipment API yet.');
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
