create or replace function public.order_exists(p_order_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.orders
    where id::text = p_order_id
  );
$$;

drop policy if exists "customers can create order items" on public.order_items;

create policy "customers can create order items" on public.order_items
  for insert with check (
    public.order_exists(order_id)
  );