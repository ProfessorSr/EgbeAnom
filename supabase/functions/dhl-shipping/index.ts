import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN') ?? 'https://egbeanom.com',
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
const DHL_SHIPMENTS_URL = 'https://express.api.dhl.com/mydhlapi/shipments';

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
  const encrypted = await fetchEncryptedShippingCredential('dhl');
  if (encrypted) {
    return {
      credentials: {
        accountNumber: stringValue(encrypted.account_number),
        siteId: stringValue(encrypted.site_id),
        apiKey: stringValue(encrypted.api_key),
        apiPassword: stringValue(encrypted.api_password),
        clientId: stringValue(encrypted.client_id),
        clientSecret: stringValue(encrypted.client_secret),
      },
    };
  }

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

async function fetchEncryptedShippingCredential(carrier: string): Promise<Json | null> {
  const encryptionKey = Deno.env.get('ENCRYPTION_KEY') ?? '';
  if (!encryptionKey.trim()) {
    return null;
  }
  const { data, error } = await serviceClient
    .from('encrypted_credentials')
    .select('credentials_encrypted')
    .eq('provider_type', 'shipping_carrier')
    .eq('provider_name', carrier)
    .maybeSingle();
  if (error) {
    throw new Error(`Could not load encrypted ${carrier.toUpperCase()} credentials: ${error.message}`);
  }
  if (!data) {
    return null;
  }
  const { data: decrypted, error: decryptError } = await serviceClient.rpc(
    'decrypt_credential_value',
    {
      p_encrypted_data: data.credentials_encrypted,
      p_encryption_key_hex: encryptionKey.trim(),
    },
  );
  if (decryptError) {
    throw new Error(`Could not decrypt ${carrier.toUpperCase()} credentials: ${decryptError.message}`);
  }
  return JSON.parse(stringValue(decrypted)) as Json;
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
    siteId: string;
    apiPassword: string;
    apiKey: string;
  },
) {
  if (!credentials.accountNumber || !credentials.apiKey) {
    throw new Error('DHL account number and API key are required for label creation.');
  }

  const address = ((order.shipping_address as Json | undefined) ?? {}) as Json;
  if (!stringValue(address.address_line1) || !stringValue(address.city) || !stringValue(address.state) || !stringValue(address.postal_code)) {
    throw new Error('The order is missing a complete shipping address for DHL label creation.');
  }

  const payload = {
    plannedShippingDateAndTime: new Date().toISOString(),
    pickup: {
      isRequested: false,
    },
    productCode: dhlProductCode(stringValue(order.shipping_service), stringValue(order.shipping_priority)),
    accounts: [
      {
        typeCode: 'shipper',
        number: credentials.accountNumber,
      },
    ],
    customerDetails: {
      shipperDetails: {
        postalAddress: {
          addressLine1: stringValue(storeInfo.address_line1),
          addressLine2: stringValue(storeInfo.address_line2),
          cityName: stringValue(storeInfo.city),
          postalCode: normalizeZip(stringValue(storeInfo.postal_code)),
          provinceCode: stringValue(storeInfo.state),
          countryCode: 'US',
        },
        contactInformation: {
          fullName: stringValue(storeInfo.display_name) || 'EgbeAnom',
          companyName: stringValue(storeInfo.display_name) || 'EgbeAnom',
          phone: stringValue(storeInfo.phone),
          email: stringValue(storeInfo.email),
        },
      },
      receiverDetails: {
        postalAddress: {
          addressLine1: stringValue(address.address_line1),
          addressLine2: stringValue(address.address_line2),
          cityName: stringValue(address.city),
          postalCode: normalizeZip(stringValue(address.postal_code)),
          provinceCode: stringValue(address.state),
          countryCode: 'US',
        },
        contactInformation: {
          fullName: buildRecipientName(order, address),
          companyName: buildRecipientName(order, address),
          phone: stringValue(address.phone),
          email: stringValue(address.email) || stringValue(order.email),
        },
      },
    },
    content: {
      packages: [
        {
          weight: poundsFromOunces(numberValue(packageInfo.weightOz, 8)),
          dimensions: {
            length: Math.max(1, Math.ceil(numberValue(packageInfo.lengthIn, 6))),
            width: Math.max(1, Math.ceil(numberValue(packageInfo.widthIn, 3))),
            height: Math.max(1, Math.ceil(numberValue(packageInfo.heightIn, 3))),
          },
        },
      ],
      isCustomsDeclarable: false,
      description: `Order ${stringValue(order.order_number) || stringValue(order.id)}`,
    },
    outputImageProperties: {
      printerDPI: 300,
      encodingFormat: 'pdf',
      imageOptions: [{ typeCode: 'label', templateName: 'ECOM26_84_A4_001' }],
    },
    customerReferences: [
      {
        value: stringValue(order.order_number) || stringValue(order.id),
        typeCode: 'CU',
      },
    ],
  };

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    'DHL-API-Key': credentials.apiKey,
  };
  if (credentials.siteId && credentials.apiPassword) {
    headers.Authorization = `Basic ${btoa(`${credentials.siteId}:${credentials.apiPassword}`)}`;
  }

  const response = await fetch(DHL_SHIPMENTS_URL, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });
  const jsonBody = await response.json();
  if (!response.ok) {
    throw new Error(
      stringValue(jsonBody?.detail) ||
      stringValue(jsonBody?.message) ||
      `DHL label creation failed: ${response.statusText}`,
    );
  }

  const trackingNumber =
    stringValue(jsonBody?.shipmentTrackingNumber) ||
    stringValue((jsonBody?.packages?.[0] ?? {}).trackingNumber);
  const docs = Array.isArray(jsonBody?.documents) ? (jsonBody.documents as Json[]) : [];
  const labelDoc = docs.find((doc) => stringValue(doc.typeCode).toLowerCase() === 'label') ?? docs[0] ?? {};
  const labelBase64 = stringValue(labelDoc.content);
  if (!trackingNumber) {
    throw new Error('DHL label response did not include a tracking number.');
  }
  if (!labelBase64) {
    throw new Error('DHL label response did not include printable label content.');
  }

  return {
    trackingNumber,
    labelStatus: 'Label printed',
    labelFileName: stringValue(labelDoc.fileName) || `dhl-label-${trackingNumber}.pdf`,
    labelContentType: 'application/pdf',
    labelBase64,
    trackingUrl: `https://www.dhl.com/us-en/home/tracking.html?tracking-id=${encodeURIComponent(trackingNumber)}`,
    postage: numberValue((jsonBody?.shipmentCharges ?? {}).totalPrice, 0),
    estimatedDays: stringValue(order.shipping_service) || 'DHL-calculated',
  };
}

function normalizeZip(zip: string) {
  return zip.replace(/[^0-9]/g, '').slice(0, 5);
}

function buildRecipientName(order: Json, address: Json) {
  const first = stringValue(address.first_name).trim();
  const last = stringValue(address.last_name).trim();
  const full = `${first} ${last}`.trim();
  return full || stringValue(order.customer) || 'Customer';
}

function dhlProductCode(service: string, priority: string) {
  const text = `${service} ${priority}`.toLowerCase();
  if (text.includes('express') || text.includes('overnight') || text.includes('one day')) {
    return 'N';
  }
  if (text.includes('ground') || text.includes('standard')) {
    return 'G';
  }
  return 'N';
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
