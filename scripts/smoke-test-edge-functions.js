#!/usr/bin/env node

const supabaseUrl = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const anonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || '';
const adminJwt = process.env.SUPABASE_ADMIN_JWT || '';
const orderNumber = process.env.SMOKE_ORDER_NUMBER || '';
const recipient = process.env.SMOKE_EMAIL_TO || '';

if (!supabaseUrl || !anonKey) {
  console.error('Missing SUPABASE_URL and SUPABASE_ANON_KEY/SUPABASE_PUBLISHABLE_KEY.');
  process.exit(1);
}

const checks = [
  {
    name: 'stripe-checkout-session rejects missing order',
    functionName: 'stripe-checkout-session',
    auth: anonKey,
    body: {
      orderNumber: '',
      mode: 'Test',
      successUrl: 'https://egbeanom.com/payment-success',
      cancelUrl: 'https://egbeanom.com/payment-failed',
    },
    expectOk: false,
  },
  {
    name: 'send-email rejects unsupported anonymous kind',
    functionName: 'send-email',
    auth: anonKey,
    body: {
      kind: 'unsupported',
      recipients: [recipient || 'customer@example.com'],
      subject: 'Smoke test',
      htmlBody: '<p>Smoke test</p>',
    },
    expectOk: false,
  },
];

if (adminJwt && orderNumber) {
  checks.push({
    name: 'tracking-status admin refresh',
    functionName: 'tracking-status',
    auth: adminJwt,
    body: { orderNumber },
    expectOk: true,
  });
}

(async () => {
  let failures = 0;
  for (const check of checks) {
    const response = await fetch(`${supabaseUrl}/functions/v1/${check.functionName}`, {
      method: 'POST',
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${check.auth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(check.body),
    });
    const text = await response.text();
    let payload;
    try {
      payload = JSON.parse(text);
    } catch (_) {
      payload = { raw: text };
    }
    const ok = check.expectOk ? response.ok && !payload.error : !response.ok || !!payload.error;
    if (!ok) {
      failures += 1;
      console.error(`${check.name}: failed`, { status: response.status, payload });
    } else {
      console.log(`${check.name}: ok`, { status: response.status });
    }
  }
  process.exit(failures === 0 ? 0 : 1);
})();
