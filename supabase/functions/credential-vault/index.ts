// Encrypted credential access for EgbeAnom admin.
// Keeps ENCRYPTION_KEY inside Supabase Edge Functions, not in the browser.

// @ts-ignore Remote URL import is resolved by Supabase Edge Runtime (Deno).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

declare const Deno: {
  env: { get: (name: string) => string | undefined };
  serve: (handler: (request: Request) => Response | Promise<Response>) => unknown;
};

type Json = Record<string, unknown>;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const encryptionKey = Deno.env.get('ENCRYPTION_KEY') ?? '';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Missing Supabase function environment variables.');
}

if (!encryptionKey || !/^[0-9a-fA-F]{64}$/.test(encryptionKey.trim())) {
  throw new Error('Missing ENCRYPTION_KEY. Set a 64-character hex key before using credential-vault.');
}

const serviceClient = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (request: Request) => {
  const headers = corsHeadersFor(request);
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed.' }, 405, headers);
  }

  try {
    await requireBackendUser(request);
    const body = asObject(await request.json());
    const action = asString(body.action).trim().toLowerCase();
    const providerType = normalizeProviderType(body.providerType);
    const providerName = normalizeProviderName(body.providerName);

    if (!providerType || !providerName) {
      return json({ error: 'providerType and providerName are required.' }, 400, headers);
    }

    if (action === 'get') {
      const credential = await getCredential(providerType, providerName);
      return json({ credential }, 200, headers);
    }

    if (action === 'upsert') {
      const credential = asObject(body.credential);
      await upsertCredential(providerType, providerName, credential);
      return json({ ok: true }, 200, headers);
    }

    return json({ error: 'Unsupported credential action.' }, 400, headers);
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : 'Credential vault request failed.' },
      400,
      headers,
    );
  }
});

async function requireBackendUser(request: Request): Promise<void> {
  const authHeader = request.headers.get('authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    throw new Error('Admin sign-in is required.');
  }

  const { data: authData, error: authError } = await serviceClient.auth.getUser(token);
  if (authError || !authData.user) {
    throw new Error('Admin session is not valid.');
  }

  const { data, error } = await serviceClient
    .from('backend_users')
    .select('id')
    .eq('auth_user_id', authData.user.id)
    .eq('is_active', true)
    .eq('is_blocked', false)
    .limit(1);
  if (error) {
    throw new Error(`Could not verify admin access: ${error.message}`);
  }
  if (!Array.isArray(data) || data.length === 0) {
    throw new Error('Backend admin access is required.');
  }
}

async function getCredential(
  providerType: string,
  providerName: string,
): Promise<Json | null> {
  const { data, error } = await serviceClient
    .from('encrypted_credentials')
    .select('credentials_encrypted')
    .eq('provider_type', providerType)
    .eq('provider_name', providerName)
    .maybeSingle();
  if (error) {
    throw new Error(`Could not load encrypted credential: ${error.message}`);
  }
  if (!data) {
    return null;
  }

  const decrypted = await rpcText('decrypt_credential_value', {
    p_encrypted_data: data.credentials_encrypted,
    p_encryption_key_hex: encryptionKey.trim(),
  });
  return asObject(JSON.parse(decrypted));
}

async function upsertCredential(
  providerType: string,
  providerName: string,
  credential: Json,
): Promise<void> {
  const encrypted = await rpcValue('encrypt_credential_value', {
    p_data: JSON.stringify(credential),
    p_encryption_key_hex: encryptionKey.trim(),
  });
  const { error } = await serviceClient
    .from('encrypted_credentials')
    .upsert({
      provider_type: providerType,
      provider_name: providerName,
      credentials_encrypted: encrypted,
      encryption_algorithm: 'aes',
      updated_at: new Date().toISOString(),
    }, { onConflict: 'provider_type,provider_name' });
  if (error) {
    throw new Error(`Could not save encrypted credential: ${error.message}`);
  }
}

async function rpcText(name: string, body: Json): Promise<string> {
  const value = await rpcValue(name, body);
  if (typeof value !== 'string') {
    throw new Error(`${name} did not return text.`);
  }
  return value;
}

async function rpcValue(name: string, body: Json): Promise<unknown> {
  const { data, error } = await serviceClient.rpc(name, body);
  if (error) {
    throw new Error(`${name} failed: ${error.message}`);
  }
  return data;
}

function normalizeProviderType(value: unknown): string {
  const text = asString(value).trim().toLowerCase();
  if (text === 'email_server' || text === 'payment_processor' || text === 'shipping_carrier') {
    return text;
  }
  return '';
}

function normalizeProviderName(value: unknown): string {
  const text = asString(value).trim().toLowerCase();
  return text.replace(/[^a-z0-9_-]+/g, '');
}

function asObject(value: unknown): Json {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Json;
  }
  return {};
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function json(payload: Json, status = 200, headers = corsHeadersFor()): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}

function corsHeadersFor(request?: Request): Record<string, string> {
  const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN') ?? 'https://egbeanom.com';
  const origin = request?.headers.get('origin') ?? allowedOrigin;
  return {
    'Access-Control-Allow-Origin': allowedOrigin === '*' ? '*' : allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
}
