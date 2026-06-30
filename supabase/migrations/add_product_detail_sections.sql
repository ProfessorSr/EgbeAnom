alter table public.products
  add column if not exists vibe text not null default '',
  add column if not exists performance text not null default '',
  add column if not exists comparison text not null default '',
  add column if not exists fragrance_profile text not null default '';

update public.products
set comparison = trim(substring(description from '(Compare this to .*)'))
where comparison = ''
  and description ~* 'Compare this to ';

update public.products
set description = trim(regexp_replace(description, '\s*Compare this to .*$', '', 'i'))
where description ~* 'Compare this to ';
