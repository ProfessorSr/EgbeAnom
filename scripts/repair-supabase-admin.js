const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const adminEmail = process.env.ADMIN_EMAIL || 'calvin.fowler74@gmail.com';
const adminPassword = process.env.ADMIN_PASSWORD || 'Vache';
const adminName = process.env.ADMIN_NAME || 'Calvin Fowler';

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

async function findUserByEmail(email) {
  for (let page = 1; page <= 10; page += 1) {
    const data = await request(
      `/auth/v1/admin/users?page=${page}&per_page=100`,
      { method: 'GET', headers: { 'content-type': undefined } },
    );
    const users = Array.isArray(data?.users) ? data.users : [];
    const user = users.find(
      (candidate) => candidate.email?.toLowerCase() === email.toLowerCase(),
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

async function createOrResetUser() {
  const existing = await findUserByEmail(adminEmail);
  const body = {
    email: adminEmail,
    password: adminPassword,
    email_confirm: true,
    user_metadata: { name: adminName },
  };
  if (existing) {
    return request(`/auth/v1/admin/users/${existing.id}`, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  }
  return request('/auth/v1/admin/users', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

async function upsertBackendUser(user) {
  const row = {
    id: `ADM-${adminEmail.split('@')[0].toUpperCase().replace(/[^A-Z0-9]+/g, '-')}`,
    auth_user_id: user.id,
    name: adminName,
    email: adminEmail,
    role: 'owner',
    is_active: true,
    is_blocked: false,
  };
  for (let attempt = 0; attempt < 8; attempt += 1) {
    try {
      await request('/rest/v1/backend_users?on_conflict=email', {
        method: 'POST',
        headers: { prefer: 'resolution=merge-duplicates,return=minimal' },
        body: JSON.stringify(row),
      });
      return;
    } catch (error) {
      const match = String(error.message).match(/'([^']+)' column/);
      if (!match) {
        throw error;
      }
      delete row[match[1]];
    }
  }
  throw new Error('Could not upsert backend user with the live table schema.');
}

async function verifyLogin() {
  const response = await fetch(`${baseUrl}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      apikey: serviceRoleKey,
      authorization: `Bearer ${serviceRoleKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ email: adminEmail, password: adminPassword }),
  });
  if (!response.ok) {
    throw new Error(`Login verification failed: ${response.status}`);
  }
}

async function main() {
  const user = await createOrResetUser();
  await upsertBackendUser(user);
  await verifyLogin();
  console.log(`Admin auth repaired for ${adminEmail}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
