const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL;
const apiKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const bucket = process.env.SUPABASE_PRODUCT_BUCKET || 'product-images';
const imagePath =
  process.env.STELLAR_IMAGE_PATH || '/Users/professorsr/Downloads/stellar.jpg';

if (!supabaseUrl || !apiKey) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY first.');
  process.exit(1);
}

if (!fs.existsSync(imagePath)) {
  console.error(`Image not found: ${imagePath}`);
  process.exit(1);
}

const baseUrl = supabaseUrl.replace(/\/$/, '');

const product = {
  id: 1007,
  name: 'Stellar Times',
  sku: 'EA-STELLAR-TIMES-50',
  notes: 'Bergamot, Grapefruit, Ginger, Musk',
  imageName: 'stellar.jpg',
  color: '#3F2B25',
  description:
    'Stellar Times is a luxurious, unisex Extrait de Parfum. It is a vibrant, radiant citrus and spice scent that combines fresh grapefruit, bergamot, and sweet zesty ginger to create a long-lasting, uplifting, and breezy feel.',
  comparison: 'Compare this to Symphony by Louis Vuitton.',
  performance:
    'Extrait de Parfum oil based and 30% concentration. Known for exceptional longevity and mass appeal, it is highly versatile, transitioning seamlessly from daytime wear to formal evenings. Despite being a citrus fragrance, it is renowned for lasting 12+ hours on the skin.',
  fragranceProfile:
    'A radiant citrus-spice profile built around bright zesty bergamot, crisp sparkling grapefruit, warm sweet ginger, and a velvety musky roundness.',
  vibe:
    'It opens with a burst of high energy that develops into a velvety, musky roundness: uplifting, breezy, refined, and polished.',
  top: 'Bright, zesty Bergamot',
  heart: 'Crisp, sparkling Grapefruit',
  base: 'Warm, invigorating, and sweet Ginger, Musk',
  gender: 'Unisex',
  season: 'Spring, Summer, Warm weather, Year-round',
  occasion: 'Daily wear, Office, Vacation, Evening, Formal',
  family: 'Citrus, Spice, Fresh, Aromatic, Musk',
};

const notes = Array.from(
  new Set(product.notes.split(',').map((note) => note.trim())),
).filter(Boolean);

const optionRows = {
  fragrance_families: product.family.split(',').map((name) => name.trim()),
  fragrance_seasons: product.season.split(',').map((name) => name.trim()),
  fragrance_occasions: product.occasion.split(',').map((name) => name.trim()),
};

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
  const query = onConflict
    ? `?on_conflict=${encodeURIComponent(onConflict)}`
    : '';
  const copy = { ...row };
  for (let attempt = 0; attempt < 14; attempt += 1) {
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
    const text = await response.text();
    if (response.ok) {
      return;
    }
    const match =
      text.match(/'([^']+)' column/) ||
      text.match(/Column \\"([^"]+)\\" is an identity column/) ||
      text.match(/non-DEFAULT value into column \\"([^"]+)\\"/);
    if (!match) {
      throw new Error(`${table}: ${response.status} ${text}`);
    }
    delete copy[match[1]];
  }
  throw new Error(`${table}: could not match live schema.`);
}

async function removeRows(table, productId) {
  const response = await fetch(
    `${baseUrl}/rest/v1/${table}?product_id=eq.${productId}`,
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
    throw new Error(
      `${table} delete: ${response.status} ${await response.text()}`,
    );
  }
}

async function upload(storagePath, filePath) {
  const bytes = fs.readFileSync(path.resolve(filePath));
  const response = await fetch(
    `${baseUrl}/storage/v1/object/${bucket}/${storagePath}`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${apiKey}`,
        apikey: apiKey,
        'content-type': 'image/jpeg',
        'x-upsert': 'true',
      },
      body: bytes,
    },
  );
  if (!response.ok) {
    throw new Error(
      `${storagePath}: ${response.status} ${await response.text()}`,
    );
  }
  return {
    url: `${baseUrl}/storage/v1/object/public/${bucket}/${storagePath}`,
    size: bytes.length,
  };
}

async function main() {
  for (const note of notes) {
    await upsert(
      'fragrance_notes',
      {
        name: note,
        note_type: 'Global',
        family: product.family,
        description: `${note} fragrance note.`,
      },
      'name',
    );
  }

  for (const [table, names] of Object.entries(optionRows)) {
    for (const name of names.filter(Boolean)) {
      await upsert(table, { name }, 'name');
    }
  }

  const storagePath = `products/${product.id}/${product.imageName}`;
  const uploaded = await upload(storagePath, imagePath);

  await upsert('products', {
    id: product.id,
    category_id: 1,
    name: product.name,
    fragrance_type: 'Perfume',
    brand: 'Egbe Anom',
    vendor: 'Egbe Anom',
    item_location: 'Main warehouse',
    sku: product.sku,
    notes: product.notes,
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
    photo_url: uploaded.url,
    featured_color: product.color,
    sort_order: 70,
    is_active: true,
    description: product.description,
    vibe: product.vibe,
    performance: product.performance,
    comparison: product.comparison,
    fragrance_profile: product.fragranceProfile,
    ingredients: product.performance,
    top_notes: product.top,
    heart_notes: product.heart,
    base_notes: product.base,
    concentration: 'Extrait de Parfum',
    gender: product.gender,
    season: product.season,
    occasion: product.occasion,
    family: product.family,
    rating: 5,
    review_count: 0,
  });

  await removeRows('product_variants', product.id);
  await upsert('product_variants', {
    product_id: product.id,
    size: '50 ml',
    sku: product.sku,
    price: 50,
    stock: 10,
    reorder_point: 8,
    is_active: true,
  });

  await removeRows('product_images', product.id);
  await upsert('product_images', {
    product_id: product.id,
    url: uploaded.url,
    storage_path: storagePath,
    content_type: 'image/jpeg',
    file_size: uploaded.size,
    alt_text: `${product.name} product photo 1`,
    sort_order: 1,
    is_primary: true,
  });

  const rows = await request(
    `/rest/v1/products?select=id,name,sku,season,occasion,comparison,photo_url,product_images(*)&id=eq.${product.id}`,
  );
  console.log(JSON.stringify(rows, null, 2));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
