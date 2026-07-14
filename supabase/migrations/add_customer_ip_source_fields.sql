alter table public.store_customers
  add column if not exists created_source text not null default '',
  add column if not exists last_login_source text not null default '',
  add column if not exists last_login_at timestamptz;
