const { Client } = require('pg');

const databaseUrl = process.env.DATABASE_URL;
const encryptionKey = process.env.ENCRYPTION_KEY;

if (!databaseUrl) {
  console.error('Set DATABASE_URL first.');
  process.exit(1);
}

if (!encryptionKey || !/^[0-9a-fA-F]{64}$/.test(encryptionKey)) {
  console.error('Set ENCRYPTION_KEY to a 64-character hex string.');
  process.exit(1);
}

function normalizeName(value) {
  return `${value || ''}`.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, '');
}

function providerForKey(key, value) {
  if (key === 'email_server_settings') {
    return [{ type: 'email_server', name: 'default', value }];
  }
  if (key.startsWith('payment_processor_credentials_')) {
    return [{
      type: 'payment_processor',
      name: normalizeName(key.replace('payment_processor_credentials_', '')),
      value,
    }];
  }
  if (key.startsWith('shipping_carrier_credentials_')) {
    return [{
      type: 'shipping_carrier',
      name: normalizeName(key.replace('shipping_carrier_credentials_', '')),
      value,
    }];
  }
  if (key === 'shipping_carrier_credentials') {
    const entries = [];
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      for (const [carrier, credential] of Object.entries(value)) {
        if (credential && typeof credential === 'object' && !Array.isArray(credential)) {
          entries.push({
            type: 'shipping_carrier',
            name: normalizeName(carrier),
            value: credential,
          });
        }
      }
    }
    if (entries.length === 0) {
      entries.push({ type: 'shipping_carrier', name: 'default', value });
    }
    return entries;
  }
  return [];
}

async function main() {
  const client = new Client({ connectionString: databaseUrl });
  await client.connect();
  try {
    await client.query('begin');
    const { rows } = await client.query(`
      select key, value
      from public.site_settings
      where key = 'email_server_settings'
        or key = 'shipping_carrier_credentials'
        or key like 'shipping_carrier_credentials_%'
        or key like 'payment_processor_credentials_%'
      order by key
    `);

    let migrated = 0;
    for (const row of rows) {
      for (const credential of providerForKey(row.key, row.value)) {
        if (!credential.name || !credential.value || Object.keys(credential.value).length === 0) {
          continue;
        }
        const encrypted = await client.query(
          `select public.encrypt_credential_value($1, $2) as value`,
          [JSON.stringify(credential.value), encryptionKey],
        );
        await client.query(
          `
          insert into public.encrypted_credentials (
            provider_type,
            provider_name,
            credentials_encrypted,
            encryption_algorithm,
            updated_at
          )
          values ($1, $2, $3, 'aes', now())
          on conflict (provider_type, provider_name)
          do update set
            credentials_encrypted = excluded.credentials_encrypted,
            encryption_algorithm = excluded.encryption_algorithm,
            updated_at = now()
          `,
          [credential.type, credential.name, encrypted.rows[0].value],
        );
        migrated += 1;
      }
    }

    if (migrated > 0) {
      await client.query(`
        delete from public.site_settings
        where key = 'email_server_settings'
          or key = 'shipping_carrier_credentials'
          or key like 'shipping_carrier_credentials_%'
          or key like 'payment_processor_credentials_%'
      `);
    }

    await client.query('commit');
    console.log(`Migrated ${migrated} credential set(s) to encrypted_credentials.`);
  } catch (error) {
    await client.query('rollback');
    throw error;
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
