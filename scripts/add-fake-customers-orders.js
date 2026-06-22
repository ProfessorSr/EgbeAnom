const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY first.');
  process.exit(1);
}

const baseUrl = supabaseUrl.replace(/\/$/, '');

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      apikey: serviceRoleKey,
      authorization: `Bearer ${serviceRoleKey}`,
      'content-type': 'application/json',
      prefer: 'resolution=merge-duplicates,return=representation',
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${path}: ${response.status} ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function main() {
  const products = await request('/rest/v1/products?select=*&limit=5');
  const catalog = Array.isArray(products) && products.length ? products : [];
  const customers = [
    ['CUS-DEMO-001', 'Avery Johnson', 'avery.demo@example.com', 'Signature'],
    ['CUS-DEMO-002', 'Maya Collins', 'maya.demo@example.com', 'Fruity'],
    ['CUS-DEMO-003', 'Jordan Reed', 'jordan.demo@example.com', 'Woody'],
    ['CUS-DEMO-004', 'Simone Carter', 'simone.demo@example.com', 'Fresh'],
    ['CUS-DEMO-005', 'Darius Miles', 'darius.demo@example.com', 'Amber'],
  ];

  for (let i = 0; i < customers.length; i += 1) {
    const [id, name, email, segment] = customers[i];
    const product = catalog[i % Math.max(catalog.length, 1)] || {};
    const price = Number(product.price || 50);
    const orderNumber = `EA-DEMO-${String(i + 1).padStart(3, '0')}`;
    await request('/rest/v1/store_customers?on_conflict=email', {
      method: 'POST',
      body: JSON.stringify({
        id,
        name,
        email,
        joined_days_ago: 12 + i * 9,
        orders: 1,
        lifetime_value: price + 9.95,
        segment,
        referral_code: email.split('@')[0].toUpperCase(),
        referral_credits: i * 2,
      }),
    });
    await request('/rest/v1/orders?on_conflict=order_number', {
      method: 'POST',
      body: JSON.stringify({
        id: crypto.randomUUID(),
        order_number: orderNumber,
        customer_name: name,
        email,
        status: 'Paid',
        financial_status: 'Paid',
        fulfillment_status: i % 2 === 0 ? 'Shipped' : 'Processing',
        subtotal: price,
        tax_total: Number((price * 0.082).toFixed(2)),
        shipping_total: 9.95,
        grand_total: Number((price * 1.082 + 9.95).toFixed(2)),
        item_count: 1,
        shipping_carrier: i % 2 === 0 ? 'USPS' : 'UPS',
        shipping_service: i % 2 === 0 ? 'Ground Advantage' : 'Ground',
        shipping_priority: i % 2 === 0 ? 'Standard' : 'Priority',
        label_status: i % 2 === 0 ? 'Printed' : 'Not requested',
        shipping_address: {
          name,
          address1: `${100 + i} Demo Lane`,
          city: 'Phoenix',
          state: 'AZ',
          zip: `8500${i}`,
        },
      }),
    });
    await request('/rest/v1/order_items', {
      method: 'POST',
      headers: { prefer: 'return=minimal' },
      body: JSON.stringify({
        order_id: orderNumber,
        product_id: product.id || null,
        sku: product.sku || `DEMO-${i + 1}`,
        product_name: product.name || 'EgbeAnom demo fragrance',
        size: product.size || '50 ml',
        quantity: 1,
        unit_price: price,
        line_total: price,
        item_location: product.item_location || 'Main warehouse',
        product_photo_url: product.photo_url || '',
      }),
    });
  }
  console.log('Added 5 fake customers with previous orders.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
