alter table public.orders
  add column if not exists return_condition text not null default '',
  add column if not exists refund_option text not null default '',
  add column if not exists stripe_refund_id text not null default '';

alter table public.orders drop constraint if exists orders_fulfillment_status_check;
alter table public.orders add constraint orders_fulfillment_status_check
  check (
    fulfillment_status in (
      'Pending',
      'Processing',
      'Invoice created',
      'Unfulfilled',
      'Being picked',
      'Packing',
      'Label printed',
      'Label created',
      'Awaiting return item',
      'Sent',
      'Shipped',
      'Delivered',
      'Cancelled'
    )
  );
