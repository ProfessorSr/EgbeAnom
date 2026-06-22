const { Client } = require('pg');

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('Set DATABASE_URL first.');
  process.exit(1);
}

const sql = `
delete from public.store_reviews
where customer_email like 'test.customer%@example.com';

insert into public.store_reviews (
  scope,
  product_id,
  customer_email,
  author,
  rating,
  title,
  body,
  status
) values
  (
    'Company',
    null,
    'test.customer1@example.com',
    'Test Customer One',
    5,
    'Fast shipping test',
    'This is a pending company review for approval testing.',
    'pending'
  ),
  (
    'Company',
    null,
    'test.customer2@example.com',
    'Test Customer Two',
    4,
    'Packaging looked good',
    'Pending company review to confirm approval persists after refresh.',
    'pending'
  ),
  (
    'Fragrance',
    1001,
    'test.customer3@example.com',
    'Test Customer Three',
    5,
    'Pineapple projection',
    'Pending product comment for The Pineapple Man approval testing.',
    'pending'
  ),
  (
    'Fragrance',
    1002,
    'test.customer4@example.com',
    'Test Customer Four',
    4,
    'African Keke test',
    'Pending product comment for African Keke approval testing.',
    'pending'
  ),
  (
    'Fragrance',
    1005,
    'test.customer5@example.com',
    'Test Customer Five',
    5,
    'Aoud test review',
    'Pending product comment for Aoud approval testing.',
    'pending'
  );
`;

async function main() {
  const client = new Client({ connectionString: databaseUrl });
  await client.connect();
  await client.query(sql);
  const result = await client.query(
    "select id, scope, status from public.store_reviews where customer_email like 'test.customer%@example.com' order by id",
  );
  await client.end();
  console.log(
    result.rows
      .map((row) => `${row.id}: ${row.scope} ${row.status}`)
      .join('\n'),
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
