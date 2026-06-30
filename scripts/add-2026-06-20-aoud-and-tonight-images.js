const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL;
const apiKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const bucket = process.env.SUPABASE_PRODUCT_BUCKET || 'product-images';

if (!supabaseUrl || !apiKey) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY first.');
  process.exit(1);
}

const baseUrl = supabaseUrl.replace(/\/$/, '');

const aoud = {
  id: 1005,
  name: 'Aoud',
  sku: 'EA-AOUD-ZAMUNDA-50',
  notes:
    'Bulgarian Rose, Powdery Violet Accord, Strawberry, Turkish Rose Absolute, Natural Laotian Oud, Vanilla, Amber, Benzoin',
  color: '#5A3A31',
  description:
    'Aoud from Zamunda is a luxurious, opulent, and intensely romantic amber-woody-floral fragrance. Designed to evoke shimmering oriental silk against the skin, it has an incredibly smooth velveteen texture and room-filling sillage.',
  comparison: 'Compare this to Oud Satin Mood.',
  ingredients:
    'Extrait de Parfum, oil based, 30% concentration. Sweet, powdery, deeply floral, and resinous-woody with exceptional projection for 8 to 12+ hours on skin and multiple days on clothing.',
  top: 'Bulgarian Rose, Powdery Violet Accord, Strawberry',
  heart: 'Turkish Rose Absolute',
  base: 'Natural Laotian Oud, Vanilla, Amber, Benzoin',
  gender: 'Unisex',
  season: 'Fall, Winter, Cool weather',
  occasion: 'Evening wear, Romantic nights, Formal events',
  family: 'Amber, Woody, Floral, Oud',
  images: [
    ['aoud.png', 'egbeanom/assets/images/aoud.png'],
    ['aoud2.png', 'egbeanom/assets/images/aoud2.png'],
    ['aoud3.png', 'egbeanom/assets/images/aoud3.png'],
    ['aoud4.png', 'egbeanom/assets/images/aoud4.png'],
  ],
};

const tonightImages = [
  ['tonight.png', 'egbeanom/assets/images/tonight.png'],
  ['tonight2.png', 'egbeanom/assets/images/tonight2.png'],
  ['tonight3.png', 'egbeanom/assets/images/tonight3.png'],
  ['tonight4.png', 'egbeanom/assets/images/tonight4.png'],
  ['tonight5.png', 'egbeanom/assets/images/tonight5.png'],
];

async function request(pathname, options = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    ...options,
    headers: {
      authorization: `Bearer ${apiKey}`,
      apikey: apiKey,
      'content-type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${pathname}: ${response.status} ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function upsert(table, row, onConflict) {
  const query = onConflict ? `?on_conflict=${encodeURIComponent(onConflict)}` : '';
  const response = await fetch(`${baseUrl}/rest/v1/${table}${query}`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${apiKey}`,
      apikey: apiKey,
      'content-type': 'application/json',
      prefer: 'resolution=merge-duplicates,return=minimal',
    },
    body: JSON.stringify(row),
  });
  if (!response.ok) {
    throw new Error(`${table}: ${response.status} ${await response.text()}`);
  }
}

async function removeProductImages(productId) {
  const response = await fetch(
    `${baseUrl}/rest/v1/product_images?product_id=eq.${productId}`,
    {
      method: 'DELETE',
      headers: {
        authorization: `Bearer ${apiKey}`,
        apikey: apiKey,
        prefer: 'return=minimal',
      },
    },
  );
  if (!response.ok) {
    throw new Error(`product_images delete: ${response.status} ${await response.text()}`);
  }
}

async function upload(storagePath, filePath) {
  const bytes = fs.readFileSync(path.resolve(filePath));
  const response = await fetch(`${baseUrl}/storage/v1/object/${bucket}/${storagePath}`, {
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
    throw new Error(`${storagePath}: ${response.status} ${await response.text()}`);
  }
  return {
    url: `${baseUrl}/storage/v1/object/public/${bucket}/${storagePath}`,
    size: bytes.length,
  };
}

async function replaceImages(productId, productName, images) {
  await removeProductImages(productId);
  for (const [index, [name, filePath]] of images.entries()) {
    const storagePath = `products/${productId}/${name}`;
    const uploaded = await upload(storagePath, filePath);
    await upsert('product_images', {
      product_id: productId,
      url: uploaded.url,
      storage_path: storagePath,
      content_type: 'image/png',
      file_size: uploaded.size,
      alt_text: `${productName} product photo ${index + 1}`,
      sort_order: index + 1,
      is_primary: index === 0,
    });
    if (index === 0) {
      await request(`/rest/v1/products?id=eq.${productId}`, {
        method: 'PATCH',
        body: JSON.stringify({ photo_url: uploaded.url }),
      });
    }
  }
}

async function main() {
  for (const note of aoud.notes.split(',').map((item) => item.trim()).filter(Boolean)) {
    await upsert(
      'fragrance_notes',
      {
        name: note,
        note_type: 'Global',
        family: aoud.family,
        description: `${note} fragrance note.`,
      },
      'name',
    );
  }

  const primaryAoudUrl = `${baseUrl}/storage/v1/object/public/${bucket}/products/${aoud.id}/${aoud.images[0][0]}`;
  await upsert('products', {
    id: aoud.id,
    category_id: 1,
    name: aoud.name,
    fragrance_type: 'Perfume',
    brand: 'Egbe Anom',
    vendor: 'Egbe Anom',
    item_location: 'Main warehouse',
    sku: aoud.sku,
    notes: aoud.notes,
    size: '50 ml',
    price: 50,
    cost: 0,
    stock: 10,
    sold: 0,
    reorder_point: 8,
    weight_oz: 8,
    length_in: 6,
    width_in: 3,
    height_in: 3,
    photo_url: primaryAoudUrl,
    featured_color: aoud.color,
    sort_order: 50,
    is_active: true,
    description: aoud.description,
    comparison: aoud.comparison,
    ingredients: aoud.ingredients,
    top_notes: aoud.top,
    heart_notes: aoud.heart,
    base_notes: aoud.base,
    concentration: 'Extrait de Parfum',
    gender: aoud.gender,
    season: aoud.season,
    occasion: aoud.occasion,
    family: aoud.family,
    rating: 5,
    review_count: 0,
  });

  await request(`/rest/v1/product_variants?product_id=eq.${aoud.id}`, {
    method: 'DELETE',
    headers: { prefer: 'return=minimal' },
  });
  await upsert('product_variants', {
    product_id: aoud.id,
    size: '50 ml',
    sku: aoud.sku,
    price: 50,
    stock: 10,
    reorder_point: 8,
    is_active: true,
  });

  await replaceImages(aoud.id, aoud.name, aoud.images);
  await replaceImages(1004, 'Not Tonight Bae', tonightImages);

  const rows = await request(
    '/rest/v1/products?select=id,name,photo_url,product_images(*)&id=in.(1004,1005)&order=id.asc',
  );
  console.log(rows.map((row) => `${row.name}: ${(row.product_images || []).length} images`).join('\n'));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
