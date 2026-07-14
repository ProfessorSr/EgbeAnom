const { Client } = require('pg');

const databaseUrl = process.env.DATABASE_URL;
const keepEmail = (process.env.KEEP_CUSTOMER_EMAIL || 'calvin.fowler74@gmail.com')
  .trim()
  .toLowerCase();

if (!databaseUrl) {
  console.error('Set DATABASE_URL first.');
  process.exit(1);
}

const client = new Client({ connectionString: databaseUrl });

const tablesToCount = [
  'public.orders',
  'public.order_items',
  'public.order_surveys',
  'public.store_reviews',
  'public.admin_notifications',
  'public.active_carts',
  'public.customer_wishlist',
  'public.analytics_daily_metrics',
  'public.analytics_sessions',
  'public.analytics_events',
  'public.mailing_list_subscribers',
  'public.store_customers',
  'public.admin_audit_log',
];

async function countTable(table) {
  const result = await client.query(`select count(*)::int as count from ${table}`);
  return result.rows[0].count;
}

async function snapshot(label) {
  console.log(`\n${label}`);
  for (const table of tablesToCount) {
    try {
      console.log(`${table}: ${await countTable(table)}`);
    } catch (error) {
      console.log(`${table}: skipped (${error.message})`);
    }
  }
}

async function main() {
  await client.connect();
  await snapshot('Before cleanup');

  await client.query('begin');
  try {
    const backendEmails = await client.query(`
      select lower(email) as email
      from public.backend_users
      where coalesce(email, '') <> ''
    `);
    const backendEmailList = backendEmails.rows.map((row) => row.email);

    await client.query('delete from public.order_items');
    await client.query('delete from public.orders');
    await client.query('delete from public.order_surveys');
    await client.query('delete from public.store_reviews');
    await client.query('delete from public.admin_notifications');
    await client.query('delete from public.active_carts');
    await client.query('delete from public.customer_wishlist');
    await client.query('delete from public.analytics_events');
    await client.query('delete from public.analytics_sessions');
    await client.query('delete from public.analytics_daily_metrics');
    await client.query('delete from public.admin_audit_log');
    await client.query(
      'delete from public.mailing_list_subscribers where lower(email) <> $1',
      [keepEmail],
    );
    await client.query(
      `
      delete from public.store_customers
      where lower(email) <> $1
      `,
      [keepEmail],
    );
    await client.query(
      `
      update public.store_customers
      set orders = 0,
          order_count = 0,
          lifetime_value = 0,
          referral_credits = 0,
          loyalty_points = 0,
          segment = 'Customer',
          updated_at = now()
      where lower(email) = $1
      `,
      [keepEmail],
    );

    const preservedAuthEmails = [keepEmail, ...backendEmailList];
    await client.query(
      `
      delete from auth.users
      where lower(email) <> all($1::text[])
      `,
      [preservedAuthEmails],
    );

    await client.query('commit');
  } catch (error) {
    await client.query('rollback');
    throw error;
  }

  await snapshot('After cleanup');
  await client.end();
}

main().catch(async (error) => {
  console.error(error);
  try {
    await client.end();
  } catch (_) {}
  process.exit(1);
});
