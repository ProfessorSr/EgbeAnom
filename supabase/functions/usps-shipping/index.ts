// @ts-ignore Remote URL import is resolved by Supabase Edge Runtime (Deno).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

declare const Deno: {
  env: { get: (name: string) => string | undefined };
  serve: (handler: (request: Request) => Response | Promise<Response>) => unknown;
};

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

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = (await request.json()) as Json;
    const user = await requireBackendUser(request);
    const settings = await loadUspsSettings();
    if (!settings.credentials.clientId || !settings.credentials.clientSecret) {
      throw new Error('USPS OAuth credentials are not configured.');
    }

    const oauthToken = await fetchUspsOAuthToken(settings.credentials);
    const action = `${body.action ?? ''}`;
    if (action == 'quoteRates') {
      const result = await quoteRates(
        body.request as Json,
        oauthToken,
        settings.credentials,
      );
      return json({ quotes: result, user: user.email });
    }
    if (action == 'createLabel') {
      const result = await createLabel(
        body.order as Json,
        body.storeInfo as Json,
        body.package as Json,
        oauthToken,
        settings.credentials,
      );
      return json(result);
    }
    return json({ error: 'Unsupported USPS action.' }, 400);
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'USPS request failed.' },
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
    throw new Error('Backend admin access is required for USPS operations.');
  }
  return rows[0];
}

async function loadUspsSettings() {
  const { data: providerData, error: providerError } = await serviceClient
    .from('site_settings')
    .select('value')
    .eq('key', 'shipping_carrier_credentials_usps')
    .limit(1)
    .maybeSingle();
  if (providerError) {
    throw new Error(`Could not load USPS credentials: ${providerError.message}`);
  }
  if (providerData?.value && typeof providerData.value === 'object') {
    const raw = providerData.value as Json;
    return {
      credentials: {
        customerId: stringValue(raw.customer_id),
        accountNumber: stringValue(raw.account_number),
        apiKey: stringValue(raw.api_key),
        apiSecret: stringValue(raw.api_secret),
        meterNumber: stringValue(raw.meter_number),
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
  const raw = ((value.USPS as Json | undefined) ?? {}) as Json;
  return {
    credentials: {
      customerId: stringValue(raw.customer_id),
      accountNumber: stringValue(raw.account_number),
      apiKey: stringValue(raw.api_key),
      apiSecret: stringValue(raw.api_secret),
      meterNumber: stringValue(raw.meter_number),
      clientId: stringValue(raw.client_id),
      clientSecret: stringValue(raw.client_secret),
    },
  };
}

async function fetchUspsOAuthToken(credentials: {
  clientId: string;
  clientSecret: string;
}) {
  const response = await fetch('https://apis.usps.com/oauth2/v3/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: credentials.clientId,
      client_secret: credentials.clientSecret,
      grant_type: 'client_credentials',
    }),
  });
  const jsonBody = await response.json();
  if (!response.ok || !jsonBody.access_token) {
    throw new Error(stringValue(jsonBody.error_description) || 'USPS OAuth token request failed.');
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
  const mailClass = uspsMailClass(stringValue(request.service));
  const payload = {
    pricingOptions: [
      {
        priceType: 'COMMERCIAL',
        paymentAccount: {
          accountType: 'EPS',
          accountNumber: credentials.accountNumber,
        },
      },
    ],
    originZIPCode: stringValue(request.originZip),
    destinationZIPCode: stringValue(request.destinationZip),
    packageDescription: {
      weight: ouncesToPounds(numberValue(request.weightOz, 8)),
      length: numberValue(request.lengthIn, 6),
      width: numberValue(request.widthIn, 3),
      height: numberValue(request.heightIn, 3),
      girth: 1,
      mailClass,
      mailingDate: todayIso(),
      packageValue: 50,
    },
  };

  const response = await fetch('https://apis.usps.com/shipments/v3/options/search', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${oauthToken}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(payload),
  });
  const jsonBody = await response.json();
  if (!response.ok) {
    throw new Error(uspsError(jsonBody, 'USPS rate lookup failed.'));
  }
  const pricingOptions = Array.isArray(jsonBody.pricingOptions)
    ? (jsonBody.pricingOptions as Json[])
    : [];
  const option = pricingOptions[0] ?? {};
  const shippingOptions = Array.isArray(option.shippingOptions)
    ? (option.shippingOptions as Json[])
    : [];
  const selected = shippingOptions.find((entry) => stringValue(entry.mailClass) === mailClass) ?? shippingOptions[0] ?? {};
  const rateOptions = Array.isArray(selected.rateOptions)
    ? (selected.rateOptions as Json[])
    : [];

  return rateOptions.map((entry) => {
    const commitment = (entry.commitment as Json | undefined) ?? {};
    return {
      carrier: 'USPS',
      service: serviceLabelFromMailClass(mailClass),
      amount: numberValue(entry.totalPrice, numberValue(entry.totalBasePrice, 0)),
      currency: 'USD',
      estimatedDays: stringValue(commitment.name) || 'USPS-calculated',
    };
  });
}

async function createLabel(
  order: Json,
  storeInfo: Json,
  packageInfo: Json,
  oauthToken: string,
  credentials: {
    customerId: string;
    accountNumber: string;
    apiKey: string;
    meterNumber: string;
  },
) {
  const address = ((order.shipping_address as Json | undefined) ?? {}) as Json;
  if (!stringValue(address.address_line1) || !stringValue(address.city) || !stringValue(address.state) || !stringValue(address.postal_code)) {
    throw new Error('The order is missing a complete shipping address for USPS label creation.');
  }
  if (!credentials.customerId || !credentials.accountNumber || !credentials.meterNumber || !credentials.apiKey) {
    throw new Error('USPS label credentials are incomplete. Save CRID, account number, MID, and manifest MID first.');
  }

  const paymentAuthorizationToken = await fetchPaymentAuthorizationToken(
    oauthToken,
    credentials,
  );
  const mailClass = uspsMailClass(stringValue(order.shipping_service));
  const payload = {
    imageInfo: {
      imageType: 'PDF',
      labelType: '4X6LABEL',
      receiptOption: 'NONE',
      suppressPostage: false,
      suppressMailDate: false,
      returnLabel: false,
    },
    toAddress: {
      firstName: stringValue(address.first_name),
      lastName: stringValue(address.last_name),
      firm: buildRecipientFirm(order),
      streetAddress: stringValue(address.address_line1),
      secondaryAddress: stringValue(address.address_line2),
      city: stringValue(address.city),
      state: stringValue(address.state),
      ZIPCode: normalizeZip(stringValue(address.postal_code)),
      phone: stringValue(address.phone),
      email: stringValue(address.email) || stringValue(order.email),
    },
    fromAddress: {
      firm: stringValue(storeInfo.display_name) || stringValue(storeInfo.store_name) || 'EgbeAnom',
      streetAddress: stringValue(storeInfo.address_line1),
      secondaryAddress: stringValue(storeInfo.address_line2),
      city: stringValue(storeInfo.city),
      state: stringValue(storeInfo.state),
      ZIPCode: normalizeZip(stringValue(storeInfo.postal_code)),
      phone: stringValue(storeInfo.phone),
      email: stringValue(storeInfo.email),
    },
    packageDescription: {
      mailClass,
      rateIndicator: rateIndicatorForMailClass(mailClass),
      weightUOM: 'lb',
      weight: ouncesToPounds(numberValue(packageInfo.weightOz, 8)),
      dimensionsUOM: 'in',
      length: numberValue(packageInfo.lengthIn, 6),
      width: numberValue(packageInfo.widthIn, 3),
      height: numberValue(packageInfo.heightIn, 3),
      processingCategory: 'MACHINABLE',
      mailingDate: todayIso(),
      extraServices: [],
      destinationEntryFacilityType: 'NONE',
      packageOptions: {
        packageValue: Math.max(numberValue(order.grand_total, 0), 1),
      },
      customerReference: [stringValue(order.order_number)],
    },
  };

  const response = await fetch('https://apis.usps.com/labels/v3/label', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${oauthToken}`,
      'Content-Type': 'application/json',
      'X-Payment-Authorization-Token': paymentAuthorizationToken,
      'X-Idempotency-Key': stringValue(order.order_number) || crypto.randomUUID(),
    },
    body: JSON.stringify(payload),
  });
  const contentType = response.headers.get('content-type') ?? '';
  const raw = await response.text();
  if (!response.ok) {
    throw new Error(uspsError(tryParseJson(raw), 'USPS label creation failed.'));
  }
  const parsed = parseMultipartResponse(raw, contentType);
  const metadata = parsed.metadata;
  const trackingUrl = Array.isArray(metadata.links)
    ? stringValue(((metadata.links as Json[])[0] ?? {}).href)
    : '';
  return {
    trackingNumber: stringValue(metadata.trackingNumber),
    labelStatus: 'Label created',
    labelFileName: parsed.labelFileName,
    labelContentType: parsed.labelContentType,
    labelBase64: parsed.labelBase64,
    trackingUrl,
    postage: numberValue(metadata.postage, 0),
    estimatedDays: commitmentLabel(metadata.commitment),
  };
}

async function fetchPaymentAuthorizationToken(
  oauthToken: string,
  credentials: {
    customerId: string;
    accountNumber: string;
    apiKey: string;
    meterNumber: string;
  },
) {
  const payload = {
    roles: [
      {
        roleName: 'PAYER',
        CRID: credentials.customerId,
        MID: credentials.meterNumber,
        manifestMID: credentials.apiKey,
        accountType: 'EPS',
        accountNumber: credentials.accountNumber,
      },
      {
        roleName: 'LABEL_OWNER',
        CRID: credentials.customerId,
        MID: credentials.meterNumber,
        manifestMID: credentials.apiKey,
        accountType: 'EPS',
        accountNumber: credentials.accountNumber,
      },
    ],
  };
  const response = await fetch('https://apis.usps.com/payments/v3/payment-authorization', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${oauthToken}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(payload),
  });
  const jsonBody = await response.json();
  if (!response.ok || !jsonBody.paymentAuthorizationToken) {
    throw new Error(uspsError(jsonBody, 'USPS payment authorization failed.'));
  }
  return stringValue(jsonBody.paymentAuthorizationToken);
}

function parseMultipartResponse(raw: string, contentType: string) {
  const boundaryMatch = /boundary=([^;]+)/i.exec(contentType);
  if (!boundaryMatch) {
    throw new Error('USPS label response did not include a multipart boundary.');
  }
  const boundary = `--${boundaryMatch[1]}`;
  const parts = raw
    .split(boundary)
    .map((part) => part.trim())
    .filter((part) => part && part !== '--');
  let metadata: Json = {};
  let labelBase64 = '';
  let labelContentType = 'application/pdf';
  let labelFileName = 'usps-label.pdf';
  for (const part of parts) {
    const [headerBlock, ...bodyParts] = part.split(/\r?\n\r?\n/);
    if (!headerBlock || bodyParts.length === 0) {
      continue;
    }
    const body = bodyParts.join('\n\n').trim().replace(/--$/, '').trim();
    const nameMatch = /name="([^"]+)"/i.exec(headerBlock);
    const fileMatch = /filename="([^"]+)"/i.exec(headerBlock);
    const typeMatch = /Content-Type:\s*([^\r\n]+)/i.exec(headerBlock);
    const name = nameMatch?.[1] ?? '';
    if (name === 'labelMetadata') {
      metadata = tryParseJson(body) as Json;
    }
    if (name === 'labelImage') {
      labelBase64 = body.replace(/\s+/g, '');
      labelContentType = typeMatch?.[1]?.trim() ?? labelContentType;
      labelFileName = fileMatch?.[1] ?? labelFileName;
    }
  }
  if (!labelBase64) {
    throw new Error('USPS did not return a label image.');
  }
  return { metadata, labelBase64, labelContentType, labelFileName };
}

function uspsMailClass(service: string) {
  switch (service.trim().toUpperCase()) {
    case 'PRIORITY MAIL EXPRESS':
    case 'EXPRESS':
      return 'PRIORITY_MAIL_EXPRESS';
    case 'PRIORITY MAIL':
      return 'PRIORITY_MAIL';
    default:
      return 'USPS_GROUND_ADVANTAGE';
  }
}

function serviceLabelFromMailClass(mailClass: string) {
  switch (mailClass) {
    case 'PRIORITY_MAIL_EXPRESS':
      return 'Priority Mail Express';
    case 'PRIORITY_MAIL':
      return 'Priority Mail';
    default:
      return 'Ground Advantage';
  }
}

function rateIndicatorForMailClass(mailClass: string) {
  switch (mailClass) {
    case 'PRIORITY_MAIL_EXPRESS':
      return 'P5';
    case 'PRIORITY_MAIL':
      return 'CP';
    default:
      return 'SP';
  }
}

function commitmentLabel(value: unknown) {
  if (value && typeof value === 'object' && 'name' in value) {
    return stringValue((value as Json).name);
  }
  return '';
}

function buildRecipientFirm(order: Json) {
  return stringValue(order.customer_name) || 'Customer';
}

function uspsError(body: unknown, fallback: string) {
  if (body && typeof body === 'object') {
    const data = body as Json;
    return stringValue(data.error) || stringValue(data.message) || stringValue(data.title) || fallback;
  }
  return fallback;
}

function normalizeZip(value: string) {
  return value.replace(/[^0-9]/g, '').slice(0, 5);
}

function ouncesToPounds(ounces: number) {
  return Math.max(0.0625, Number((ounces / 16).toFixed(3)));
}

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

function stringValue(value: unknown) {
  return typeof value === 'string' ? value.trim() : '';
}

function numberValue(value: unknown, fallback = 0) {
  return typeof value === 'number' && Number.isFinite(value)
    ? value
    : typeof value === 'string' && value.trim().length > 0 && Number.isFinite(Number(value))
    ? Number(value)
    : fallback;
}

function tryParseJson(raw: string) {
  try {
    return JSON.parse(raw);
  } catch (_) {
    return {};
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}