alter table public.orders
  add column if not exists return_items jsonb not null default '[]'::jsonb,
  add column if not exists return_admin_comment text not null default '',
  add column if not exists return_condition text not null default '',
  add column if not exists refund_option text not null default '',
  add column if not exists stripe_refund_id text not null default '',
  add column if not exists rma_number text not null default '',
  add column if not exists rma_created_at timestamptz,
  add column if not exists return_requested_at timestamptz,
  add column if not exists return_decision_at timestamptz;
