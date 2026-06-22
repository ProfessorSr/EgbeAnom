# Egbe Anom Supabase Setup

This folder contains the Supabase setup for the store. Supabase Auth is the
source of truth for customer/admin login. The `store_customers` and
`backend_users` tables are profile/role tables only; they should not contain
password hashes.

## Apply schema

Run `supabase/schema.sql` in the Supabase SQL editor. It creates the core product, image, note, customer, backend-user, blocked-IP, and site-settings tables, plus a public `product-images` storage bucket.

Then run `supabase/seed.sql` to load the current product catalog and fragrance notes.

## Auth model

Create customer accounts through the storefront. The app calls Supabase Auth
signup/login and then creates or reads the matching `store_customers` profile.

For admin users, create the user in Supabase Auth first, then add a matching
row in `backend_users` with that auth user's `id` in `auth_user_id`, plus the
same email and role. Admin login uses Supabase Auth password verification and
then checks the `backend_users` profile for authorization.

## Upload current product images

Set:

```sh
export SUPABASE_URL="https://devtecknxpgdhbkdjnvt.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="[copy the real service-role key from Supabase dashboard]"
export SUPABASE_PRODUCT_BUCKET="product-images"
node scripts/upload-supabase-product-images.js
```

The script uploads Pineapple Man and African Keke images, updates the matching
`product_images` rows, and sets each product's primary photo URL. A public
publishable/anon key is not enough for this script unless you pass an admin
`SUPABASE_ACCESS_TOKEN` instead.

## Flutter build config

Build/run Flutter web with:

```sh
flutter run -d chrome \
  --dart-define=SUPABASE_URL="https://devtecknxpgdhbkdjnvt.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="sb_publishable_AwMJ5ir84BN_d0LLmtl5IQ_R9ZqlNkj" \
  --dart-define=SUPABASE_PRODUCT_BUCKET="product-images"
```

The web gateway calls Supabase REST, Auth, and Storage directly.
