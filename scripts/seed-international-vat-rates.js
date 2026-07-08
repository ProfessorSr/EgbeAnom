const { Client } = require('pg');

const rates = [
  ['AR', 'Argentina', 0.21],
  ['AU', 'Australia', 0.10],
  ['AT', 'Austria', 0.20],
  ['BE', 'Belgium', 0.21],
  ['BG', 'Bulgaria', 0.20],
  ['BR', 'Brazil', 0.17],
  ['CA', 'Canada', 0.05],
  ['CL', 'Chile', 0.19],
  ['CO', 'Colombia', 0.19],
  ['HR', 'Croatia', 0.25],
  ['CY', 'Cyprus', 0.19],
  ['CZ', 'Czech Republic', 0.21],
  ['DK', 'Denmark', 0.25],
  ['EG', 'Egypt', 0.14],
  ['EE', 'Estonia', 0.22],
  ['FI', 'Finland', 0.255],
  ['FR', 'France', 0.20],
  ['DE', 'Germany', 0.19],
  ['GH', 'Ghana', 0.15],
  ['GR', 'Greece', 0.24],
  ['HU', 'Hungary', 0.27],
  ['IS', 'Iceland', 0.24],
  ['IN', 'India', 0.18],
  ['IE', 'Ireland', 0.23],
  ['IL', 'Israel', 0.18],
  ['IT', 'Italy', 0.22],
  ['JP', 'Japan', 0.10],
  ['KE', 'Kenya', 0.16],
  ['LV', 'Latvia', 0.21],
  ['LT', 'Lithuania', 0.21],
  ['LU', 'Luxembourg', 0.17],
  ['MY', 'Malaysia', 0.08],
  ['MT', 'Malta', 0.18],
  ['MX', 'Mexico', 0.16],
  ['MA', 'Morocco', 0.20],
  ['NL', 'Netherlands', 0.21],
  ['NZ', 'New Zealand', 0.15],
  ['NG', 'Nigeria', 0.075],
  ['NO', 'Norway', 0.25],
  ['PL', 'Poland', 0.23],
  ['PT', 'Portugal', 0.23],
  ['RO', 'Romania', 0.19],
  ['SA', 'Saudi Arabia', 0.15],
  ['SG', 'Singapore', 0.09],
  ['SK', 'Slovakia', 0.20],
  ['SI', 'Slovenia', 0.22],
  ['ZA', 'South Africa', 0.15],
  ['KR', 'South Korea', 0.10],
  ['ES', 'Spain', 0.21],
  ['SE', 'Sweden', 0.25],
  ['CH', 'Switzerland', 0.081],
  ['TR', 'Turkey', 0.20],
  ['AE', 'United Arab Emirates', 0.05],
  ['GB', 'United Kingdom', 0.20],
];

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required.');
  }

  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    for (const [code, country, rate] of rates) {
      await client.query(
        `
          insert into public.tax_rules (
            id, name, country, state, county, city, postal_code_prefix,
            tax_type, rate, is_vat, is_enabled, sort_order
          )
          values ($1, $2, $3, '', '', '', '', 'vat', $4, true, true, 50)
          on conflict (id) do update set
            name = excluded.name,
            country = excluded.country,
            tax_type = excluded.tax_type,
            rate = excluded.rate,
            is_vat = excluded.is_vat,
            is_enabled = public.tax_rules.is_enabled,
            sort_order = excluded.sort_order,
            updated_at = now()
        `,
        [`vat-${code.toLowerCase()}`, `${country} VAT/GST`, code, rate],
      );
    }
    console.log(`Seeded ${rates.length} international VAT/GST tax rule(s).`);
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
