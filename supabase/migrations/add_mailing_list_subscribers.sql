create table if not exists public.mailing_list_subscribers (
  email text primary key,
  name text not null default '',
  source text not null default 'Storefront',
  is_active boolean not null default true,
  subscribed_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mailing_list_subscribers
  add column if not exists name text not null default '',
  add column if not exists source text not null default 'Storefront',
  add column if not exists is_active boolean not null default true,
  add column if not exists subscribed_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.mailing_list_subscribers enable row level security;

drop policy if exists "public subscribe mailing list" on public.mailing_list_subscribers;
drop policy if exists "public update mailing list signup" on public.mailing_list_subscribers;
drop policy if exists "backend admins read mailing list" on public.mailing_list_subscribers;
drop policy if exists "backend admins manage mailing list" on public.mailing_list_subscribers;

create policy "public subscribe mailing list" on public.mailing_list_subscribers
  for insert with check (
    auth.role() in ('anon', 'authenticated')
    and email <> ''
  );
create policy "public update mailing list signup" on public.mailing_list_subscribers
  for update using (auth.role() in ('anon', 'authenticated'))
  with check (
    auth.role() in ('anon', 'authenticated')
    and email <> ''
  );
create policy "backend admins read mailing list" on public.mailing_list_subscribers
  for select using (public.is_backend_admin());
create policy "backend admins manage mailing list" on public.mailing_list_subscribers
  for all using (public.is_backend_admin()) with check (public.is_backend_admin());

grant select on public.mailing_list_subscribers to authenticated;
grant insert, update on public.mailing_list_subscribers to anon, authenticated;

create index if not exists idx_mailing_list_subscribers_active
  on public.mailing_list_subscribers(is_active, subscribed_at desc);
