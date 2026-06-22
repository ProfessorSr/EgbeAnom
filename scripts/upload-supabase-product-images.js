const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL;
const apiKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SUPABASE_ACCESS_TOKEN ||
  process.env.SUPABASE_ANON_KEY ||
  process.env.SUPABASE_PUBLISHABLE_KEY;
const bucket = process.env.SUPABASE_PRODUCT_BUCKET || 'product-images';

const productRows = [
  {
    id: 1001,
    category_id: 1,
    name: 'The Pineapple Man',
    fragrance_type: 'Perfume',
    brand: 'Egbe Anom',
    vendor: 'Egbe Anom',
    item_location: 'Main warehouse',
    sku: 'EA-PINEAPPLE-MAN-50',
    notes: 'Lemon, Pink Pepper, Apple, Calabrian Bergamot, Blackcurrant, Pineapple, Sweet Jasmine, Patchouli, Birch, Cedarwood, Oakmoss, Musk, Ambroxan',
    size: '50 ml',
    price: 50.00,
    cost: 0.00,
    stock: 10,
    sold: 0,
    reorder_point: 8,
    weight_oz: 8.0,
    length_in: 6.0,
    width_in: 3.0,
    height_in: 3.0,
    photo_url: `${supabaseUrl}/storage/v1/object/public/${bucket}/products/1001/pineapple-copy.png`,
    featured_color: '#E5A11B',
    sort_order: 10,
    is_active: true,
    description: "The Pineapple Man is a bold fruity-woody men's fragrance inspired by an iconic confident profile. It opens bright and juicy with pineapple, bergamot, lemon, apple, pink pepper, and blackcurrant, then settles into a rich masculine base of smoky birch, cedarwood, oakmoss, musk, and ambroxan. This oil-based Extrait de Parfum is blended at 30% concentration for exceptional longevity and versatile wear from daytime to formal evenings.",
    ingredients: 'Extrait de Parfum, oil based, 30% concentration.',
    top_notes: 'Lemon, Pink Pepper, Apple, Calabrian Bergamot, Blackcurrant',
    heart_notes: 'Pineapple, Sweet Jasmine, Patchouli',
    base_notes: 'Birch, Cedarwood, Oakmoss, Musk, Ambroxan',
    concentration: 'Extrait de Parfum',
    gender: 'Men',
    season: 'Year-round',
    occasion: 'Daily wear, Evening, Formal',
    family: 'Fruity, Woody, Aromatic',
    rating: 5.0,
    review_count: 0,
  },
  {
    id: 1002,
    category_id: 1,
    name: 'African Keke',
    fragrance_type: 'Perfume',
    brand: 'Egbe Anom',
    vendor: 'Egbe Anom',
    item_location: 'Main warehouse',
    sku: 'EA-AFRICAN-KEKE-50',
    notes: 'Passionfruit, Peach, Pear, Raspberry, Cassis, Warm Sand, Lily of the Valley, Musk, Vanilla, Sandalwood, Patchouli, Heliotrope',
    size: '50 ml',
    price: 50.00,
    cost: 0.00,
    stock: 0,
    sold: 0,
    reorder_point: 8,
    weight_oz: 8.0,
    length_in: 6.0,
    width_in: 3.0,
    height_in: 3.0,
    photo_url: `${supabaseUrl}/storage/v1/object/public/${bucket}/products/1002/keke.png`,
    featured_color: '#B67619',
    sort_order: 20,
    is_active: true,
    description: 'African Keke is a bold, long-lasting fruity-chypre fragrance for both men and women. It blends lush tropical fruits like passionfruit, peach, and pear with a warm sensual base of musk, vanilla, sandalwood, patchouli, and heliotrope. The juicy opening balances into an earthy warm-sand accord before settling into a creamy, powdery, musky dry-down. Compare it to similar fragrances like Kirke by Tiziana Terenzi.',
    ingredients: '30% concentration Extrait de Parfum. Highly concentrated for massive sillage and exceptional staying power that can last on skin and clothing for an entire day or more.',
    top_notes: 'Passionfruit, Peach, Pear, Raspberry, Cassis, Warm Sand',
    heart_notes: 'Lily of the Valley',
    base_notes: 'Musk, Vanilla, Sandalwood, Patchouli, Heliotrope',
    concentration: 'Extrait de Parfum',
    gender: 'Unisex',
    season: 'Spring, Summer, Warm weather',
    occasion: 'Evening, Daily wear, Signature scent',
    family: 'Fruity, Chypre, Tropical, Musky',
    rating: 5.0,
    review_count: 0,
  },
];

const variantRows = [
  { id: 1001, product_id: 1001, size: '50 ml', sku: 'EA-PINEAPPLE-MAN-50', price: 50.00, stock: 10, reorder_point: 8, is_active: true },
  { id: 1002, product_id: 1002, size: '50 ml', sku: 'EA-AFRICAN-KEKE-50', price: 50.00, stock: 0, reorder_point: 8, is_active: true },
];

const noteRows = [
  'Lemon', 'Pink Pepper', 'Apple', 'Calabrian Bergamot', 'Blackcurrant',
  'Pineapple', 'Sweet Jasmine', 'Patchouli', 'Birch', 'Cedarwood', 'Oakmoss',
  'Musk', 'Ambroxan', 'Passionfruit', 'Peach', 'Pear', 'Raspberry', 'Cassis',
  'Warm Sand', 'Lily of the Valley', 'Vanilla', 'Sandalwood', 'Heliotrope',
].map((name) => ({ name, note_type: 'Global', family: '', description: '' }));

const files = [
  [1001, 'products/1001/pineapple-copy.png', 'egbeanom/assets/pineapple copy.png', 'The Pineapple Man fragrance bottle', 1, true],
  [1001, 'products/1001/pineapple2.png', 'egbeanom/assets/images/pineapple2.png', 'The Pineapple Man front bottle photo', 2, false],
  [1001, 'products/1001/pineapple3.png', 'egbeanom/assets/images/pineapple3.png', 'The Pineapple Man bottle side photo', 3, false],
  [1001, 'products/1001/pineapple4.png', 'egbeanom/assets/images/pineapple4.png', 'The Pineapple Man angled bottle photo', 4, false],
  [1001, 'products/1001/pineapple5.png', 'egbeanom/assets/images/pineapple5.png', 'The Pineapple Man back bottle photo', 5, false],
  [1002, 'products/1002/keke.png', 'egbeanom/assets/images/keke.png', 'African Keke front bottle photo', 1, true],
  [1002, 'products/1002/keke2.png', 'egbeanom/assets/images/keke2.png', 'African Keke full bottle photo', 2, false],
  [1002, 'products/1002/keke3.png', 'egbeanom/assets/images/keke3.png', 'African Keke side bottle photo', 3, false],
  [1002, 'products/1002/keke4.png', 'egbeanom/assets/images/keke4.png', 'African Keke angled bottle photo', 4, false],
  [1002, 'products/1002/keke5.png', 'egbeanom/assets/images/keke5.png', 'African Keke back bottle photo', 5, false],
];

if (!supabaseUrl || !apiKey) {
  console.error(
    'Set SUPABASE_URL and a real SUPABASE_SERVICE_ROLE_KEY first. ' +
      'SUPABASE_ACCESS_TOKEN can also work if it belongs to a signed-in admin.',
  );
  process.exit(1);
}

const baseUrl = supabaseUrl.replace(/\/$/, '');

async function upload(storagePath, filePath) {
  const fullPath = path.resolve(filePath);
  const bytes = fs.readFileSync(fullPath);
  const url = `${baseUrl}/storage/v1/object/${bucket}/${storagePath}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${apiKey}`,
      apikey: apiKey,
      'content-type': 'image/png',
      'x-upsert': 'true',
    },
    body: bytes,
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `${storagePath}: ${response.status} ${body}\n` +
        'If this is an RLS/policy error, use the actual Supabase service-role key ' +
        'or sign in as an admin and pass SUPABASE_ACCESS_TOKEN.',
    );
  }
  return {
    publicUrl: `${baseUrl}/storage/v1/object/public/${bucket}/${storagePath}`,
    fileSize: bytes.length,
  };
}

async function upsert(table, row, onConflict) {
  const query = onConflict ? `?on_conflict=${encodeURIComponent(onConflict)}` : '';
  const copy = { ...row };
  for (let attempt = 0; attempt < 12; attempt += 1) {
    const response = await fetch(`${baseUrl}/rest/v1/${table}${query}`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${apiKey}`,
        apikey: apiKey,
        'content-type': 'application/json',
        prefer: 'resolution=merge-duplicates,return=minimal',
      },
      body: JSON.stringify(copy),
    });
    if (response.ok) {
      return;
    }
    const text = await response.text();
    const match =
      text.match(/'([^']+)' column/) ||
      text.match(/Column \\"([^"]+)\\" is an identity column/) ||
      text.match(/Column "([^"]+)" is an identity column/);
    if (!match) {
      throw new Error(`${table}: ${response.status} ${text}`);
    }
    delete copy[match[1]];
  }
  throw new Error(`${table}: could not match the live schema.`);
}

async function removeExistingProductImages(productIds) {
  return removeRowsByProductIds('product_images', productIds);
}

async function removeExistingProductVariants(productIds) {
  return removeRowsByProductIds('product_variants', productIds);
}

async function removeRowsByProductIds(table, productIds) {
  const filter = productIds.join(',');
  const response = await fetch(`${baseUrl}/rest/v1/${table}?product_id=in.(${filter})`, {
    method: 'DELETE',
    headers: {
      authorization: `Bearer ${apiKey}`,
      apikey: apiKey,
      prefer: 'return=minimal',
    },
  });
  if (!response.ok) {
    throw new Error(`${table} delete: ${response.status} ${await response.text()}`);
  }
}

async function updateProductPhoto(productId, photoUrl) {
  const response = await fetch(`${baseUrl}/rest/v1/products?id=eq.${productId}`, {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${apiKey}`,
      apikey: apiKey,
      'content-type': 'application/json',
      prefer: 'return=minimal',
    },
    body: JSON.stringify({ photo_url: photoUrl }),
  });
  if (!response.ok) {
    throw new Error(`products: ${response.status} ${await response.text()}`);
  }
}

async function main() {
  for (const note of noteRows) {
    await upsert('fragrance_notes', note, 'name');
  }
  for (const product of productRows) {
    await upsert('products', product);
  }
  await removeExistingProductVariants([1001, 1002]);
  for (const variant of variantRows) {
    await upsert('product_variants', variant);
  }
  await removeExistingProductImages([1001, 1002]);
  for (const [productId, storagePath, filePath, altText, sortOrder, isPrimary] of files) {
    const { publicUrl, fileSize } = await upload(storagePath, filePath);
    await upsert('product_images', {
      product_id: productId,
      url: publicUrl,
      storage_path: storagePath,
      content_type: 'image/png',
      file_size: fileSize,
      alt_text: altText,
      sort_order: sortOrder,
      is_primary: isPrimary,
    });
    if (isPrimary) {
      await updateProductPhoto(productId, publicUrl);
    }
    console.log(publicUrl);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
