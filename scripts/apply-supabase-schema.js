const fs = require('fs');
const { Client } = require('pg');

const databaseUrl = process.env.DATABASE_URL;
const schemaPath = process.argv[2] || 'supabase/schema.sql';

if (!databaseUrl) {
  console.error('Set DATABASE_URL first.');
  process.exit(1);
}

async function main() {
  const sql = fs.readFileSync(schemaPath, 'utf8');
  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  await client.query(sql);
  await client.end();
  console.log(`Applied schema: ${schemaPath}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
