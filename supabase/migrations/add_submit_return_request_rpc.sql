create or replace function public.submit_return_request(
  p_order_number text,
  p_email text,
  p_return_reason text,
  p_return_items jsonb default '[]'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  if not public.check_rate_limit(
    'return_request',
    lower(coalesce(p_email, 'anonymous')),
    3600,
    5
  ) then
    return false;
  end if;

  update public.orders
  set
    return_status = 'Return requested',
    return_reason = coalesce(nullif(btrim(p_return_reason), ''), return_reason),
    return_items = coalesce(p_return_items, '[]'::jsonb),
    return_admin_comment = '',
    rma_number = '',
    rma_created_at = null,
    return_requested_at = now(),
    return_decision_at = null,
    return_restocked = false,
    returned_at = null,
    updated_at = now()
  where order_number = p_order_number
    and lower(email) = lower(p_email)
    and financial_status in ('paid', 'Paid', 'partially_refunded', 'Partially refunded')
    and return_status in ('No return', 'Return rejected', '');

  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

grant execute on function public.submit_return_request(text, text, text, jsonb)
  to anon, authenticated;
