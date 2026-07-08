const { Client } = require('pg');

const updates = [
  {
    id: 1001,
    vibe:
      'Bright, confident, and polished with a juicy opening that feels energetic, successful, and sharply dressed.',
    performance:
      'Long-wearing extrait strength with a vivid fruity opening, steady woody projection, and a smoky-musky dry-down that holds through the day.',
    comparison:
      'Inspired by the fruity-smoky woods style of Creed Aventus, with Egbe Anom emphasizing ripe pineapple, crisp citrus, and a confident amber-moss base.',
    fragrance_profile:
      'A fruity woody aromatic profile built around sparkling citrus, blackcurrant, pineapple, jasmine, smoky birch, cedarwood, oakmoss, musk, ambroxan, and amber.',
  },
  {
    id: 1003,
    vibe:
      'Clean, magnetic, and assertive with a fresh shower brightness over peppery woods and smooth amber.',
    fragrance_profile:
      'A fresh spicy woody profile with Calabrian bergamot, black pepper, lavender, vetiver, patchouli, ambroxan, cedar, and labdanum.',
  },
  {
    id: 1004,
    performance:
      'Strong extrait performance with a spicy-fruity opening, plush floral-gourmand heart, and a warm amber-vanilla trail suited for evening wear.',
    fragrance_profile:
      'A dark amber fruity floral gourmand profile with pear, ginger, black pepper, cocoa, quince chutney, jasmine, peach, orange blossom, patchouli, vanilla, ambroxan, cashmeran, benzoin, and amber.',
  },
  {
    id: 1002,
    vibe:
      'Tropical, joyful, and attention-grabbing with a sun-warmed sweetness that still feels smooth, musky, and grown.',
    fragrance_profile:
      'A tropical fruity chypre profile with passionfruit, peach, pear, raspberry, cassis, warm sand, lily of the valley, musk, vanilla, sandalwood, patchouli, and heliotrope.',
  },
  {
    id: 1005,
    vibe:
      'Opulent, romantic, and plush with a satin-like rose sweetness wrapped in oud, vanilla, amber, and soft powder.',
  },
];

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is required.');
  }

  const client = new Client({ connectionString });
  await client.connect();
  try {
    for (const update of updates) {
      const fields = Object.entries(update).filter(([key]) => key !== 'id');
      const assignments = fields
        .map(([key], index) => `${key} = case when btrim(coalesce(${key}, '')) = '' then $${index + 1} else ${key} end`)
        .join(', ');
      const values = fields.map(([, value]) => value);
      values.push(update.id);
      await client.query(
        `update public.products set ${assignments}, updated_at = now() where id = $${values.length}`,
        values,
      );
    }

    const result = await client.query(`
      select id, name
      from public.products
      where btrim(coalesce(description, '')) = ''
         or btrim(coalesce(vibe, '')) = ''
         or btrim(coalesce(performance, '')) = ''
         or btrim(coalesce(comparison, '')) = ''
         or btrim(coalesce(fragrance_profile, '')) = ''
         or btrim(coalesce(top_notes, '')) = ''
         or btrim(coalesce(heart_notes, '')) = ''
         or btrim(coalesce(base_notes, '')) = ''
      order by sort_order asc, name asc
    `);
    if (result.rows.length > 0) {
      console.log('Products still missing detail fields:');
      console.log(JSON.stringify(result.rows, null, 2));
      process.exitCode = 1;
      return;
    }
    console.log(`Filled missing fragrance detail fields for ${updates.length} product(s).`);
    console.log('All fragrance products now have description, vibe, performance, comparison, fragrance profile, top notes, heart notes, and base notes.');
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
