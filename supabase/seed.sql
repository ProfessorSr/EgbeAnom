-- Current Egbe Anom catalog seed for Supabase.

insert into public.categories (id, name, description, sort_order, is_visible)
values (1, 'Fragrances', 'Egbe Anom fragrance catalog.', 10, true)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  sort_order = excluded.sort_order,
  is_visible = excluded.is_visible;

insert into public.fragrance_notes (name, note_type, family, description)
values
  ('Lemon', 'Top', 'Citrus', 'Bright lemon citrus note.'),
  ('Pink Pepper', 'Top', 'Spice', 'Sparkling rosy pepper note.'),
  ('Apple', 'Top', 'Fruity', 'Crisp apple note.'),
  ('Calabrian Bergamot', 'Top', 'Citrus', 'Fresh bergamot citrus note.'),
  ('Blackcurrant', 'Top', 'Berry', 'Dark tart berry note.'),
  ('Pineapple', 'Heart', 'Tropical fruit', 'Juicy tropical pineapple note.'),
  ('Sweet Jasmine', 'Heart', 'Floral', 'Sweet jasmine floral note.'),
  ('Birch', 'Base', 'Smoky wood', 'Smoky birch wood note.'),
  ('Cedarwood', 'Base', 'Woody', 'Dry cedarwood note.'),
  ('Oakmoss', 'Base', 'Chypre', 'Earthy mossy chypre note.'),
  ('Ambroxan', 'Base', 'Amber', 'Modern ambergris-like diffusion note.'),
  ('Passionfruit', 'Top', 'Tropical fruit', 'Juicy tropical fruit note.'),
  ('Peach', 'Top', 'Fruity', 'Soft sweet stone-fruit note.'),
  ('Pear', 'Top', 'Fruity', 'Crisp juicy pear note.'),
  ('Raspberry', 'Top', 'Berry', 'Bright tart-sweet berry note.'),
  ('Cassis', 'Top', 'Berry', 'Rich blackcurrant bud and berry nuance.'),
  ('Warm Sand', 'Top', 'Mineral', 'Sun-warmed sandy accord.'),
  ('Lily of the Valley', 'Heart', 'Floral', 'Fresh dewy white floral note.'),
  ('Musk', 'Base', 'Musky', 'Soft clean sensual musk note.'),
  ('Vanilla', 'Base', 'Gourmand', 'Creamy sweet vanilla note.'),
  ('Sandalwood', 'Base', 'Woody', 'Creamy smooth sandalwood note.'),
  ('Patchouli', 'Base', 'Earthy wood', 'Earthy woody patchouli note.'),
  ('Heliotrope', 'Base', 'Powdery floral', 'Creamy almond-like powdery floral note.')
on conflict (name) do update set
  note_type = excluded.note_type,
  family = excluded.family,
  description = excluded.description;

insert into public.products (
  id, category_id, name, fragrance_type, brand, vendor, item_location, sku,
  notes, size, price, cost, stock, sold, reorder_point, weight_oz, length_in,
  width_in, height_in, photo_url, featured_color, sort_order, is_active,
  description, ingredients, top_notes, heart_notes, base_notes, concentration,
  gender, season, occasion, family, rating, review_count
) values
  (
    1001, 1, 'The Pineapple Man', 'Perfume', 'Egbe Anom', 'Egbe Anom',
    'Main warehouse', 'EA-PINEAPPLE-MAN-50',
    'Lemon, Pink Pepper, Apple, Calabrian Bergamot, Blackcurrant, Pineapple, Sweet Jasmine, Patchouli, Birch, Cedarwood, Oakmoss, Musk, Ambroxan',
    '50 ml', 50.00, 0.00, 10, 0, 8, 8.0, 6.0, 3.0, 3.0,
    'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1001/pineapple-copy.png', '#E5A11B', 10, true,
    'The Pineapple Man is a bold fruity-woody men''s fragrance inspired by an iconic confident profile. It opens bright and juicy with pineapple, bergamot, lemon, apple, pink pepper, and blackcurrant, then settles into a rich masculine base of smoky birch, cedarwood, oakmoss, musk, and ambroxan. This oil-based Extrait de Parfum is blended at 30% concentration for exceptional longevity and versatile wear from daytime to formal evenings.',
    'Extrait de Parfum, oil based, 30% concentration.',
    'Lemon, Pink Pepper, Apple, Calabrian Bergamot, Blackcurrant',
    'Pineapple, Sweet Jasmine, Patchouli',
    'Birch, Cedarwood, Oakmoss, Musk, Ambroxan',
    'Extrait de Parfum', 'Men', 'Year-round', 'Daily wear, Evening, Formal',
    'Fruity, Woody, Aromatic', 5.0, 0
  ),
  (
    1002, 1, 'African Keke', 'Perfume', 'Egbe Anom', 'Egbe Anom',
    'Main warehouse', 'EA-AFRICAN-KEKE-50',
    'Passionfruit, Peach, Pear, Raspberry, Cassis, Warm Sand, Lily of the Valley, Musk, Vanilla, Sandalwood, Patchouli, Heliotrope',
    '50 ml', 50.00, 0.00, 0, 0, 8, 8.0, 6.0, 3.0, 3.0,
    'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1002/keke.png', '#B67619', 20, true,
    'African Keke is a bold, long-lasting fruity-chypre fragrance for both men and women. It blends lush tropical fruits like passionfruit, peach, and pear with a warm sensual base of musk, vanilla, sandalwood, patchouli, and heliotrope. The juicy opening balances into an earthy warm-sand accord before settling into a creamy, powdery, musky dry-down. Compare it to similar fragrances like Kirke by Tiziana Terenzi.',
    '30% concentration Extrait de Parfum. Highly concentrated for massive sillage and exceptional staying power that can last on skin and clothing for an entire day or more.',
    'Passionfruit, Peach, Pear, Raspberry, Cassis, Warm Sand',
    'Lily of the Valley',
    'Musk, Vanilla, Sandalwood, Patchouli, Heliotrope',
    'Extrait de Parfum', 'Unisex', 'Spring, Summer, Warm weather',
    'Evening, Daily wear, Signature scent', 'Fruity, Chypre, Tropical, Musky',
    5.0, 0
  )
on conflict (id) do update set
  name = excluded.name,
  sku = excluded.sku,
  notes = excluded.notes,
  price = excluded.price,
  stock = excluded.stock,
  photo_url = excluded.photo_url,
  description = excluded.description,
  ingredients = excluded.ingredients,
  top_notes = excluded.top_notes,
  heart_notes = excluded.heart_notes,
  base_notes = excluded.base_notes,
  concentration = excluded.concentration,
  gender = excluded.gender,
  season = excluded.season,
  occasion = excluded.occasion,
  family = excluded.family,
  is_active = excluded.is_active;

delete from public.product_variants
where product_id in (1001, 1002);

insert into public.product_variants (product_id, size, sku, price, stock, reorder_point, is_active)
values
  (1001, '50 ml', 'EA-PINEAPPLE-MAN-50', 50.00, 10, 8, true),
  (1002, '50 ml', 'EA-AFRICAN-KEKE-50', 50.00, 0, 8, true);

delete from public.product_images
where product_id in (1001, 1002);

insert into public.product_images (product_id, url, storage_path, content_type, file_size, alt_text, sort_order, is_primary)
values
  (1001, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1001/pineapple-copy.png', 'products/1001/pineapple-copy.png', 'image/png', 0, 'The Pineapple Man fragrance bottle', 1, true),
  (1001, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1001/pineapple2.png', 'products/1001/pineapple2.png', 'image/png', 0, 'The Pineapple Man front bottle photo', 2, false),
  (1001, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1001/pineapple3.png', 'products/1001/pineapple3.png', 'image/png', 0, 'The Pineapple Man bottle side photo', 3, false),
  (1001, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1001/pineapple4.png', 'products/1001/pineapple4.png', 'image/png', 0, 'The Pineapple Man angled bottle photo', 4, false),
  (1001, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1001/pineapple5.png', 'products/1001/pineapple5.png', 'image/png', 0, 'The Pineapple Man back bottle photo', 5, false),
  (1002, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1002/keke.png', 'products/1002/keke.png', 'image/png', 0, 'African Keke front bottle photo', 1, true),
  (1002, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1002/keke2.png', 'products/1002/keke2.png', 'image/png', 0, 'African Keke full bottle photo', 2, false),
  (1002, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1002/keke3.png', 'products/1002/keke3.png', 'image/png', 0, 'African Keke side bottle photo', 3, false),
  (1002, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1002/keke4.png', 'products/1002/keke4.png', 'image/png', 0, 'African Keke angled bottle photo', 4, false),
  (1002, 'https://devtecknxpgdhbkdjnvt.supabase.co/storage/v1/object/public/product-images/products/1002/keke5.png', 'products/1002/keke5.png', 'image/png', 0, 'African Keke back bottle photo', 5, false);
