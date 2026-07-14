create table if not exists public.email_messages (
  id text primary key,
  mailbox text not null default 'INBOX',
  message_id text not null default '',
  from_email text not null default '',
  from_name text not null default '',
  to_email text not null default '',
  subject text not null default '',
  preview text not null default '',
  text_body text not null default '',
  html_body text not null default '',
  received_at timestamptz not null default now(),
  is_read boolean not null default false,
  order_number text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(message_id)
);

alter table public.email_messages enable row level security;

drop policy if exists "backend admins manage email messages" on public.email_messages;
create policy "backend admins manage email messages" on public.email_messages
  for all using (public.is_backend_admin()) with check (public.is_backend_admin());

create index if not exists idx_email_messages_received_desc
  on public.email_messages(received_at desc);
create index if not exists idx_email_messages_read_received
  on public.email_messages(is_read, received_at desc);
