# EgbeAnom Store Notes

## Local Debug

Run from `egbeanom/`:

```sh
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://devtecknxpgdhbkdjnvt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY="[anon JWT from .vscode/launch.json]" \
  --dart-define=SUPABASE_PRODUCT_BUCKET=product-images
```

VS Code launch configs are already set up in:

- `.vscode/launch.json`
- `egbeanom/.vscode/launch.json`

Use a full debug restart after changing auth, Supabase config, or route logic.

## Supabase

Supabase is the database, auth provider, and product image bucket.

Apply schema updates from:

```sh
supabase/schema.sql
```

Seed/reference product data lives in:

```sh
supabase/seed.sql
```

Product images go into the public bucket:

```txt
product-images
```

## Admin Login

Current admin login:

```txt
calvin.fowler74@gmail.com
Vache1
```

Supabase rejected `Vache` because the project enforces a 6-character minimum password.

## Product Image/Repair Scripts

Run these from the repo root with a real Supabase service-role key in the environment.

```sh
SUPABASE_URL="https://devtecknxpgdhbkdjnvt.supabase.co" \
SUPABASE_SERVICE_ROLE_KEY="[service role key]" \
SUPABASE_PRODUCT_BUCKET="product-images" \
node scripts/upload-supabase-product-images.js
```

This repairs/imports The Pineapple Man and African Keke.

```sh
SUPABASE_URL="https://devtecknxpgdhbkdjnvt.supabase.co" \
SUPABASE_SERVICE_ROLE_KEY="[service role key]" \
SUPABASE_PRODUCT_BUCKET="product-images" \
node scripts/add-2026-06-18-products.js
```

This imports Sauvageur and Not Tonight Bae.

## Build

Run from the repo root:

```sh
npm run build-web
```

That command compiles the live Supabase URL, anon key, and `product-images` bucket into the Flutter web bundle. If you build manually, run from `egbeanom/`:

```sh
flutter build web \
  --dart-define=SUPABASE_URL=https://devtecknxpgdhbkdjnvt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRldnRlY2tueHBnZGhia2RqbnZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NTkzNjgsImV4cCI6MjA5NzIzNTM2OH0.yyBLbTrdXtanXmI_AB2BcbBoKAGDuWcod5C5DFvudoE" \
  --dart-define=SUPABASE_PRODUCT_BUCKET=product-images
```

Copy the contents of:

```txt
egbeanom/build/web/
```

to the web host public directory.

## Current Storefront Behavior

- Home page shows 4 products based on the admin-selected home shelf mode.
- Admin can select Best sellers, Most favorited, Top rated, Newest, Price low, Price high, or Featured products.
- Featured products are selected in Admin -> Site.
- Explore Collection opens the full catalog page.
- Home search opens the full catalog only when the search arrow is clicked.
- Catalog page supports live search, filter, and sort.

## Checks

Run before handoff:

```sh
flutter analyze
flutter test
```
