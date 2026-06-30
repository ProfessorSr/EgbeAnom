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

const products = [
  {
    id: 1003,
    name: 'Sauvageur',
    sku: 'EA-SAUVAGEUR-50',
    notes:
      'Calabrian Bergamot, Black Pepper, Sichuan Pepper, Lavender, Pink Pepper, Vetiver, Patchouli, Geranium, Ambroxan, Cedar, Labdanum',
    photo: 'products/1003/sauvegeur.png',
    color: '#173B68',
    description:
      'Sauvageur is a fresh and woody men’s fragrance with a bold burst of citrus that dries down into a rich spicy and ambery-woody finish. It balances a clean fresh-out-of-the-shower vibe with confident masculine warmth.',
    comparison: 'Compare this to Dior Sauvage.',
    ingredients:
      'Extrait de Parfum, oil based, 30% concentration. Known for exceptional longevity, mass appeal, and versatility from daytime wear to formal evenings.',
    top: 'Calabrian Bergamot, Black Pepper',
    heart:
      'Sichuan Pepper, Lavender, Pink Pepper, Vetiver, Patchouli, Geranium',
    base: 'Ambroxan, Cedar, Labdanum',
    gender: 'Men',
    season: 'Year-round',
    occasion: 'Daily wear, Evening, Formal',
    family: 'Fresh, Woody, Spicy, Amber',
    images: [
      ['sauvegeur.png', 'egbeanom/assets/images/sauvegeur.png'],
      ['sauvageur2.png', 'egbeanom/assets/images/sauvageur2.png'],
      ['sauvageur3.png', 'egbeanom/assets/images/sauvageur3.png'],
      ['sauvageur4.png', 'egbeanom/assets/images/sauvageur4.png'],
      ['sauvageur5.png', 'egbeanom/assets/images/sauvageur5.png'],
    ],
  },
  {
    id: 1004,
    name: 'Not Tonight Bae',
    sku: 'EA-NOT-TONIGHT-BAE-50',
    notes:
      'Pear, Ginger, Black Pepper, Cocoa, Mandarin Orange, Quince Chutney, Moroccan Jasmine Absolute, Peach, Orange Blossom, Indonesian Patchouli, Vanilla, Ambroxan, Cashmeran, Benzoin',
    photo: 'products/1004/mama.png',
    color: '#D47A8B',
    description:
      'Not Tonight Bae is a richer, darker, and more gourmand fragrance. Concentrated at 30% parfum strength, this amber-fruity-floral scent blends spicy black pepper, ginger, and powdery cocoa with sweet quince chutney, peach, and Moroccan jasmine, resting on a warm base of Indonesian patchouli and vanilla.',
    comparison: 'Compare this to Pas Ce Soir Extrait by BDK.',
    ingredients:
      'Sensual, bold, and playful yet deeply mysterious. Extrait de Parfum, oil based, 30% concentration.',
    top: 'Pear, Ginger, Black Pepper, Cocoa, Mandarin Orange',
    heart:
      'Quince Chutney, Moroccan Jasmine Absolute, Peach, Orange Blossom',
    base: 'Indonesian Patchouli, Vanilla, Ambroxan, Cashmeran, Benzoin',
    gender: 'Unisex',
    season: 'Cool weather, Evening',
    occasion: 'Date night, Evening, Formal',
    family: 'Amber, Fruity, Floral, Gourmand',
    images: [
      ['mama.png', 'egbeanom/assets/images/mama.png'],
      ['mamadelima.png', 'egbeanom/assets/images/mamadelima.png'],
      ['mamadelima2.png', 'egbeanom/assets/images/mamadelima2.png'],
      ['mamadelima3.png', 'egbeanom/assets/images/mamadelima3.png'],
      ['mamadelima4.png', 'egbeanom/assets/images/mamadelima4.png'],
    ],
  },
];

const notes = Array.from(
  new Set(products.flatMap((product) => product.notes.split(',').map((n) => n.trim()))),
).filter(Boolean);

async function fetchJson(pathname, options = {}) {
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
    throw new Error(`${table} delete: ${response.status} ${await response.text()}`);
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

async function main() {
  for (const note of notes) {
    await upsert('fragrance_notes', {
      name: note,
      note_type: 'Global',
      family: '',
      description: `${note} fragrance note.`,
    }, 'name');
  }
  for (const product of products) {
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
      photo_url: `${baseUrl}/storage/v1/object/public/${bucket}/${product.photo}`,
      featured_color: product.color,
      sort_order: product.id - 990,
      is_active: true,
      description: product.description,
      comparison: product.comparison,
      ingredients: product.ingredients,
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
    for (const [index, [name, filePath]] of product.images.entries()) {
      const storagePath = `products/${product.id}/${name}`;
      const uploaded = await upload(storagePath, filePath);
      await upsert('product_images', {
        product_id: product.id,
        url: uploaded.url,
        storage_path: storagePath,
        content_type: 'image/png',
        file_size: uploaded.size,
        alt_text: `${product.name} product photo ${index + 1}`,
        sort_order: index + 1,
        is_primary: index === 0,
      });
      console.log(uploaded.url);
    }
  }
  const rows = await fetchJson('/rest/v1/products?select=id,name,product_images(*)&id=in.(1003,1004)&order=id.asc');
  console.log(rows.map((row) => `${row.name}: ${(row.product_images || []).length} images`).join('\n'));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
