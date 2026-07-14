# EgbeAnom Supabase Technical Notes

This folder is for the technical helper who manages the live Supabase project.

The owner handoff guide is in the root folder and in `Docs/Admin Guide`.

## What Supabase Handles

Supabase stores the live store data:

- products, variants, photos, and fragrance details
- categories
- coupons and promotions
- store info
- tax rules
- shipping settings
- orders and order items
- customer profiles
- reviews and post-purchase surveys
- admin users and roles
- analytics
- site settings, including email and payment settings

Supabase Auth is the source of truth for login.

The `store_customers` and `backend_users` tables are profile tables. They should not store password hashes.

## Schema

The main schema file is:

`supabase/schema.sql`

It includes the current tables, policies, and helper functions, including:

- order and order item storage
- review and survey storage
- tax breakdown storage
- product detail sections
- inventory decrement after paid orders
- row-level security policies

Apply schema changes with the project’s normal schema apply script or through the Supabase SQL editor.

## Edge Functions

Current functions include:

- `stripe-checkout-session` creates Stripe checkout sessions
- `stripe-webhook` receives Stripe payment events and updates orders
- `send-email` sends SMTP customer emails
- `usps-shipping`, `ups-shipping`, `fedex-shipping`, and `dhl-shipping` handle carrier label/rate work
- `credential-migration` supports credential migration/encryption work

Deploy a function with:

```sh
supabase functions deploy FUNCTION_NAME --project-ref PROJECT_REF
```

Example:

```sh
supabase functions deploy send-email --project-ref devtecknxpgdhbkdjnvt
```

`send-email` is intentionally deployed with `--no-verify-jwt` when used for
customer order events. This lets post-payment order emails be sent from the
storefront return flow, but the function still performs its own checks:

- manual emails require a backend admin user
- order-event emails must match the order recipient
- unsupported email kinds are rejected
- rate limiting is enforced inside the function

Use this command for email deployments:

```sh
supabase functions deploy send-email --project-ref PROJECT_REF --no-verify-jwt
```

Run the Edge Function smoke checks with:

```sh
npm run smoke-test-edge-functions
```

## Required Environment Values

Use real values from the Supabase, Stripe, SMTP, and carrier dashboards.

Do not commit secret values into this repository.

Common values:

- Supabase project URL
- Supabase anon or publishable key for the Flutter app
- Supabase service role key for trusted server scripts only
- Stripe secret key
- Stripe webhook signing secret
- allowed storefront/admin origins for CORS
- carrier API credentials

SMTP settings are entered in the admin Email screen, then used by the `send-email` function.

## Current Payment Flow

The store creates an order before Stripe payment finishes.

That order starts as:

- order status: `Pending`
- financial status: `unpaid`

After Stripe confirms payment, the order changes to:

- order status: `Pending`
- financial status: `paid`

Inventory is lowered after the order is paid. The inventory helper is idempotent, so the same paid order should not subtract stock twice.

## Current Email Flow

Email sending is wired through the `send-email` function.

Customer emails are expected for:

- successful paid order with invoice/order details
- Processing status
- Label created status
- Sent or Shipped status

Before launch, enter real SMTP settings in admin and confirm a test email arrives in a real inbox.

## Current Tax Flow

Tax rules are based on the store location in Store Info and the customer address at checkout.

US location rules:

- same city as store: charge city, county, and state tax
- same county but different city: charge county and state tax
- same state but different county: charge state tax
- different state: no US state, county, or city tax

International rules can use VAT, import, or other country-based tax rules.

## Current Shipping Flow

The app supports:

- flat rate per order
- flat rate per item
- carrier options
- generated carrier labels when credentials are ready
- address-label fallback when carrier label creation is not available

Before launch, test each live carrier account that will be used.

## Product Images

Product images are stored in the configured Supabase storage bucket.

The upload helper is:

```sh
node scripts/upload-supabase-product-images.js
```

Use a service role key or another approved admin credential when running image upload scripts.

## Handoff Rule

If a document or old note says live payments, emails, taxes, inventory, or labels are not wired, check the current root handoff docs first.

The current owner-facing source of truth starts at:

`README.md`
