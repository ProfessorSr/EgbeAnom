const { Client } = require('pg');

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('Set DATABASE_URL first.');
  process.exit(1);
}

const sql = `
alter table public.store_reviews
  add column if not exists customer_email text not null default '';

update public.store_reviews
set customer_email = ''
where customer_email is null;

drop policy if exists "public approved review read" on public.store_reviews;
create policy "public approved review read" on public.store_reviews
  for select using (
    status = 'approved'
    or customer_email = (auth.jwt() ->> 'email')
    or public.is_backend_admin()
  );

drop policy if exists "authenticated users create reviews" on public.store_reviews;
create policy "authenticated users create reviews" on public.store_reviews
  for insert with check (
    auth.role() = 'authenticated'
    and customer_email = (auth.jwt() ->> 'email')
  );

drop policy if exists "backend admins manage reviews" on public.store_reviews;
create policy "backend admins manage reviews" on public.store_reviews
  for all using (public.is_backend_admin()) with check (public.is_backend_admin());
`;

async function main() {
  const client = new Client({ connectionString: databaseUrl });
  await client.connect();
  await client.query(sql);
  await client.end();
  console.log('store_reviews customer_email and policies updated');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
