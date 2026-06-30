// Supabase Edge Function: Credential Migration Helper
// Purpose: Helps migrate credentials from plaintext site_settings to encrypted vault
// Deploy this temporarily to help with credential migration

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0?target=deno';

interface CredentialMigration {
  fromProvider: string;
  toProvider: string;
  credentials: Record<string, string>;
  encrypted: boolean;
}

Deno.serve(async (req: Request) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
  const encryptionKey = Deno.env.get('ENCRYPTION_KEY') || '';

  if (!supabaseUrl || !supabaseKey || !encryptionKey) {
    return new Response(
      JSON.stringify({
        error: 'Missing environment variables',
        required: ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'ENCRYPTION_KEY'],
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const client = createClient(supabaseUrl, supabaseKey);
  const action = new URL(req.url).searchParams.get('action') || 'status';

  try {
    switch (action) {
      case 'status':
        return await getStatus(client);

      case 'migrate-payment':
        return await migratePaymentCredentials(
          client,
          req,
          encryptionKey
        );

      case 'migrate-shipping':
        return await migrateShippingCredentials(
          client,
          req,
          encryptionKey
        );

      case 'verify':
        return await verifyEncryption(client, req, encryptionKey);

      default:
        return new Response(
          JSON.stringify({ error: 'Unknown action', action }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
    }
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

async function getStatus(
  client: ReturnType<typeof createClient>
): Promise<Response> {
  try {
    // Count plaintext credentials in site_settings
    const { data: plaintext, error: plaintextError } = await client
      .from('site_settings')
      .select('key')
      .filter('key', 'like', 'payment_processor_credentials_%');

    if (plaintextError) throw plaintextError;

    // Count encrypted credentials
    const { data: encrypted, error: encryptedError } = await client
      .from('encrypted_credentials')
      .select('id')
      .eq('provider_type', 'payment_processor');

    if (encryptedError) throw encryptedError;

    return new Response(
      JSON.stringify({
        status: 'ok',
        plaintext_credentials: plaintext?.length || 0,
        encrypted_credentials: encrypted?.length || 0,
        migration_complete: (plaintext?.length || 0) === 0,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    throw error;
  }
}

async function migratePaymentCredentials(
  client: ReturnType<typeof createClient>,
  req: Request,
  encryptionKey: string
): Promise<Response> {
  const body = await req.json();
  const { provider } = body as { provider: string };

  if (!provider) {
    return new Response(
      JSON.stringify({ error: 'provider parameter required' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  try {
    // Get plaintext credentials
    const { data, error: getError } = await client
      .from('site_settings')
      .select('value')
      .eq('key', `payment_processor_credentials_${provider}`)
      .single();

    if (getError || !data) {
      return new Response(
        JSON.stringify({ error: 'Credentials not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Store encrypted version
    const { error: storeError } = await client.rpc(
      'upsert_encrypted_credential',
      {
        p_provider_type: 'payment_processor',
        p_provider_name: provider,
        p_credentials_json: JSON.stringify(data.value),
        p_encryption_key: `decode('${encryptionKey}', 'hex')`,
      }
    );

    if (storeError) throw storeError;

    return new Response(
      JSON.stringify({
        success: true,
        provider,
        message: `Migrated ${provider} payment credentials to encrypted vault`,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    throw error;
  }
}

async function migrateShippingCredentials(
  client: ReturnType<typeof createClient>,
  req: Request,
  encryptionKey: string
): Promise<Response> {
  const body = await req.json();
  const { carrier } = body as { carrier: string };

  if (!carrier) {
    return new Response(
      JSON.stringify({ error: 'carrier parameter required' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  try {
    // Get plaintext credentials
    const { data, error: getError } = await client
      .from('site_settings')
      .select('value')
      .eq('key', `shipping_carrier_credentials_${carrier}`)
      .single();

    if (getError || !data) {
      return new Response(
        JSON.stringify({ error: 'Carrier credentials not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Store encrypted version
    const { error: storeError } = await client.rpc(
      'upsert_encrypted_credential',
      {
        p_provider_type: 'shipping_carrier',
        p_provider_name: carrier,
        p_credentials_json: JSON.stringify(data.value),
        p_encryption_key: `decode('${encryptionKey}', 'hex')`,
      }
    );

    if (storeError) throw storeError;

    return new Response(
      JSON.stringify({
        success: true,
        carrier,
        message: `Migrated ${carrier} shipping credentials to encrypted vault`,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    throw error;
  }
}

async function verifyEncryption(
  client: ReturnType<typeof createClient>,
  req: Request,
  encryptionKey: string
): Promise<Response> {
  const body = await req.json();
  const { provider_type, provider_name } = body as {
    provider_type: string;
    provider_name: string;
  };

  if (!provider_type || !provider_name) {
    return new Response(
      JSON.stringify({
        error: 'provider_type and provider_name parameters required',
      }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  try {
    // Retrieve encrypted credentials
    const { data, error } = await client.rpc(
      'get_encrypted_credential',
      {
        p_provider_type: provider_type,
        p_provider_name: provider_name,
        p_encryption_key: `decode('${encryptionKey}', 'hex')`,
      }
    );

    if (error) throw error;

    return new Response(
      JSON.stringify({
        success: true,
        provider_type,
        provider_name,
        decrypted_keys: Object.keys(JSON.parse(data)),
        message: 'Encryption verified - credentials successfully decrypted',
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    throw error;
  }
}
