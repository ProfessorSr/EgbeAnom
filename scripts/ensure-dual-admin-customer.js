const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const email = (
  process.env.ACCOUNT_EMAIL ||
  process.env.ADMIN_EMAIL ||
  'calvin.fowler74@gmail.com'
)
  .trim()
  .toLowerCase();
const name = process.env.ACCOUNT_NAME || process.env.ADMIN_NAME || 'Calvin Fowler';
const role = process.env.ADMIN_ROLE || 'owner';

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY first.');
  process.exit(1);
}

const baseUrl = supabaseUrl.replace(/\/$/, '');

async function request(path, options = {}) {
  const headers = {
    authorization: `Bearer ${serviceRoleKey}`,
    apikey: serviceRoleKey,
    'content-type': 'application/json',
    ...(options.headers || {}),
  };
  for (const [key, value] of Object.entries(headers)) {
    if (value === undefined) {
      delete headers[key];
    }
  }
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers,
  });
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  if (!response.ok) {
    throw new Error(`${path}: ${response.status} ${text}`);
  }
  return data;
}

function profileId(prefix, value) {
  const slug = value
    .split('@')[0]
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return `${prefix}-${slug || Date.now()}`;
}

async function findUserByEmail(accountEmail) {
  for (let page = 1; page <= 20; page += 1) {
    const data = await request(
      `/auth/v1/admin/users?page=${page}&per_page=100`,
      { method: 'GET', headers: { 'content-type': undefined } },
    );
    const users = Array.isArray(data?.users) ? data.users : [];
    const user = users.find(
      (candidate) =>
        `${candidate.email || ''}`.trim().toLowerCase() === accountEmail,
    );
    if (user) {
      return user;
    }
    if (users.length < 100) {
      return null;
    }
  }
  return null;
}

async function upsert(table, row) {
  const cleanRow = { ...row };
  for (let attempt = 0; attempt < 8; attempt += 1) {
    try {
      await request(`/rest/v1/${table}?on_conflict=email`, {
        method: 'POST',
        headers: { prefer: 'resolution=merge-duplicates,return=minimal' },
        body: JSON.stringify(cleanRow),
      });
      return;
    } catch (error) {
      const match = String(error.message).match(/'([^']+)' column/);
      if (!match) {
        throw error;
      }
      delete cleanRow[match[1]];
    }
  }
  throw new Error(`Could not upsert ${table} with the live table schema.`);
}

async function main() {
  const user = await findUserByEmail(email);
  if (!user) {
    throw new Error(
      `No Supabase Auth user exists for ${email}. Create/sign up the user first, or run the admin repair script with a password.`,
    );
  }

  await upsert('store_customers', {
    id: profileId('CUS', email),
    auth_user_id: user.id,
    name,
    email,
    joined_days_ago: 0,
    orders: 0,
    lifetime_value: 0,
    segment: 'Test Customer',
    referral_code: email.split('@')[0].toUpperCase().replace(/[^A-Z0-9]+/g, ''),
    referral_credits: 0,
    loyalty_points: 0,
    referred_by: '',
    accepts_marketing: true,
    is_blocked: false,
    last_login_at: new Date().toISOString(),
  });

  await upsert('backend_users', {
    id: profileId('ADM', email),
    auth_user_id: user.id,
    name,
    email,
    role,
    is_active: true,
    is_blocked: false,
  });

  console.log(`${email} is now linked as both admin and customer.`);
  console.log('Use the Account page customer login to see the customer view.');
  console.log('Use the Admin email tools to send test customer emails to this address.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
