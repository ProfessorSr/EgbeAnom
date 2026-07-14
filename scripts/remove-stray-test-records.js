#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error(
    'Missing SUPABASE_URL/NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.',
  );
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

async function removeRows(table, column, values) {
  const { data, error } = await supabase
    .from(table)
    .delete()
    .in(column, values)
    .select(column);
  if (error) {
    throw new Error(`${table} cleanup failed: ${error.message}`);
  }
  console.log(`${table}: removed ${data?.length ?? 0} row(s).`);
}

async function main() {
  await removeRows('categories', 'name', ['asdfd']);
  await removeRows('coupon_rules', 'code', ['asdfdasf', 'ASDFDASF']);
  await removeRows('coupon_rules', 'name', ['asdfdasf', 'ASDFDASF']);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
