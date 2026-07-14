#!/usr/bin/env node

const carriers = [
  ['USPS', 'usps-shipping'],
  ['UPS', 'ups-shipping'],
  ['FEDEX', 'fedex-shipping'],
  ['DHL', 'dhl-shipping'],
];

const supabaseUrl = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const anonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || '';
const adminJwt = process.env.SUPABASE_ADMIN_JWT || '';
const confirmed = process.env.CONFIRM_PURCHASE_LABELS === 'yes';

if (!supabaseUrl || !anonKey || !adminJwt) {
  console.error(
    'Missing SUPABASE_URL, SUPABASE_ANON_KEY/SUPABASE_PUBLISHABLE_KEY, or SUPABASE_ADMIN_JWT.',
  );
  process.exit(1);
}

if (!confirmed) {
  console.error(
    'This smoke test can purchase real carrier labels. Set CONFIRM_PURCHASE_LABELS=yes only when sandbox or approved live carrier credentials are configured.',
  );
  process.exit(1);
}

const order = {
  id: `SMOKE-${Date.now()}`,
  order_number: `SMOKE-${Date.now()}`,
  customer_name: 'Carrier Smoke Test',
  email: 'test@example.com',
  shipping_carrier: '',
  shipping_service: 'standard',
  shipping_address: {
    firstName: 'Carrier',
    lastName: 'Test',
    addressLine1: '475 L Enfant Plaza SW',
    addressLine2: '',
    city: 'Washington',
    state: 'DC',
    postalCode: '20260',
    country: 'US',
    phone: '2025550100',
  },
};

const storeInfo = {
  name: 'EgbeAnom Fragrance',
  email: 'orders@example.com',
  phone: '2025550101',
  addressLine1: '475 L Enfant Plaza SW',
  addressLine2: '',
  city: 'Washington',
  state: 'DC',
  county: 'District of Columbia',
  postalCode: '20260',
  country: 'US',
};

const parcel = {
  weightOz: 8,
  lengthIn: 6,
  widthIn: 4,
  heightIn: 3,
};

(async () => {
  let failures = 0;
  for (const [carrier, functionName] of carriers) {
    const response = await fetch(`${supabaseUrl}/functions/v1/${functionName}`, {
      method: 'POST',
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${adminJwt}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        action: 'createLabel',
        order: { ...order, shipping_carrier: carrier },
        storeInfo,
        package: parcel,
      }),
    });
    const text = await response.text();
    let payload;
    try {
      payload = JSON.parse(text);
    } catch (_) {
      payload = { raw: text };
    }
    if (!response.ok || payload.error) {
      failures += 1;
      console.error(`${carrier}: failed`, payload);
      continue;
    }
    console.log(`${carrier}: ok`, {
      trackingNumber: payload.trackingNumber || '',
      labelStatus: payload.labelStatus || '',
      labelFileName: payload.labelFileName || '',
    });
  }
  process.exit(failures === 0 ? 0 : 1);
})();
