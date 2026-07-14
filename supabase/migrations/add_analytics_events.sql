create table if not exists public.analytics_events (
  id text primary key,
  session_id text not null default '',
  visitor text not null default 'Guest visitor',
  event_name text not null,
  page text not null default '',
  source text not null default 'Direct',
  referrer text not null default 'Direct',
  device text not null default 'Unknown device',
  product_id bigint,
  product_name text not null default '',
  order_id text not null default '',
  value numeric(12,2) not null default 0,
  currency text not null default 'USD',
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

alter table public.analytics_events
  add column if not exists session_id text not null default '',
  add column if not exists visitor text not null default 'Guest visitor',
  add column if not exists event_name text not null default '',
  add column if not exists page text not null default '',
  add column if not exists source text not null default 'Direct',
  add column if not exists referrer text not null default 'Direct',
  add column if not exists device text not null default 'Unknown device',
  add column if not exists product_id bigint,
  add column if not exists product_name text not null default '',
  add column if not exists order_id text not null default '',
  add column if not exists value numeric(12,2) not null default 0,
  add column if not exists currency text not null default 'USD',
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists occurred_at timestamptz not null default now();

alter table public.analytics_events enable row level security;

drop policy if exists "backend admins read analytics events" on public.analytics_events;
drop policy if exists "public insert analytics events" on public.analytics_events;

create policy "backend admins read analytics events" on public.analytics_events
  for select using (public.is_backend_admin());

create policy "public insert analytics events" on public.analytics_events
  for insert with check (true);

grant select on public.analytics_daily_metrics to authenticated;
grant select on public.analytics_sessions to authenticated;
grant select on public.analytics_events to authenticated;
grant insert on public.analytics_events to anon, authenticated;

create index if not exists idx_analytics_events_occurred_desc
  on public.analytics_events(occurred_at desc);
create index if not exists idx_analytics_events_event_occurred
  on public.analytics_events(event_name, occurred_at desc);
create index if not exists idx_analytics_events_session
  on public.analytics_events(session_id);
