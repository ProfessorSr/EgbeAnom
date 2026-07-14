alter table public.store_customers
  add column if not exists phone text not null default '';
