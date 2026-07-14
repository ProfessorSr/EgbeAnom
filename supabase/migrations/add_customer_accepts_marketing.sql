alter table public.store_customers
  add column if not exists accepts_marketing boolean not null default false;
