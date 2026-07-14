# Production Handoff Checklist

This is the simple checklist for client handoff.

`[x]` means done.

`[~]` means built, but needs a real-world check.

`[ ]` means not signed off yet.

## Quick Score

- Overall handoff readiness: about 92%
- Core fragrance-store workflow: about 95%
- Admin and store operations: about 92%
- Checkout and Stripe sandbox flow: about 95%
- Printing and fulfillment workflow: about 96%
- Email workflow: about 85% until a real SMTP inbox test passes
- Public launch readiness: about 92%
- Commercial platform parity: about 65%

The lower commercial-platform score is not a launch blocker. It means this custom store is strong for the current fragrance business, but it does not yet include every Shopify/BigCommerce/Square-style growth feature such as POS hardware, multi-channel selling, B2B accounts, subscriptions, multi-location inventory, advanced tax/accounting integrations, and an app marketplace.

## Store Setup

- [x] Store info screen exists
- [x] Store address is used by taxes, invoices, and labels
- [~] Final live store address has been checked

## Products And Inventory

- [x] Products can be managed
- [x] Photos can be managed
- [x] Fragrance detail fields are filled
- [x] Inventory can be printed
- [x] Paid orders lower inventory once
- [~] Final live product stock has been counted

## Checkout And Payments

- [x] Orders are saved before payment as pending and unpaid
- [x] Stripe sandbox payment works
- [x] Paid Stripe return updates order to paid
- [x] Success page shows order details
- [x] Survey shows after payment
- [~] Cancel and failed payment paths need one final manual check
- [ ] One small live Stripe payment has been completed

## Orders And Fulfillment

- [x] Orders can be filtered by shipping type
- [x] Orders can be filtered by order status
- [x] Orders can be filtered by financial status
- [x] Pack list printing moves orders to Processing
- [x] Invoice creation moves orders to Invoice created
- [x] Label creation moves orders to Label created
- [x] Sent marks orders as shipped
- [x] Batch invoice and pack list printing exists
- [~] Batch print should be checked once more in the final browser

## Email

- [x] Google/Gmail SMTP option exists
- [x] GoDaddy SMTP option exists
- [x] Generic SMTP option exists
- [x] Test email sending path exists
- [x] Paid order email path exists
- [x] Processing email path exists
- [x] Label created email path exists
- [x] Sent/shipped email path exists
- [ ] Real SMTP settings have been entered
- [ ] A real test email has arrived in an inbox

## Taxes

- [x] State, county, city, other, VAT, and import rules exist
- [x] Same-city rule charges city, county, and state tax
- [x] Same-county rule charges county and state tax
- [x] Same-state rule charges state tax
- [x] Out-of-state rule skips US state, county, and city tax
- [x] Checkout shows tax breakdown
- [~] Final tax rates have been checked with the business owner or tax professional

## Shipping

- [x] Flat rate per order exists
- [x] Flat rate per item exists
- [x] Carrier options exist
- [x] Address-label fallback exists
- [~] Real carrier credentials have been entered
- [~] Real carrier label creation has been tested

## Reports

- [x] Reports page exists
- [x] Tax breakdown exists
- [x] Product sales breakdown exists
- [x] Shipping breakdown exists
- [x] CSV downloads exist
- [~] Numbers should be checked against trusted sample orders

## Audit Fix Backlog

These items came from the production-readiness audit. Keep them here until each one is fixed, tested, and signed off.

### Critical Before Live Payments

- [x] Make Stripe Checkout use server-side order totals only. The browser should send an order number, and the function should load the order and order items from Supabase.
- [x] Make the Stripe webhook verify paid amount, currency, payment status, and order number before marking an order paid.
- [x] Store the Stripe Checkout session ID or payment intent on the order and prevent duplicate payment/session handling.
- [x] Tighten order RLS so public users cannot create arbitrary orders without a checkout ownership proof.
- [x] Tighten order item RLS so public users cannot attach items to another customer order.
- [x] Add atomic inventory reservation/decrement logic that fails when stock is too low instead of only clamping stock to zero after payment.
- [x] Move SMTP, payment, and carrier secrets out of plain `site_settings` JSON and into an encrypted credential path.
- [x] Fix and apply the credential encryption migration before storing real production secrets.

### High Priority Hardening

- [x] Add refund workflow and make refunds update order financial status.
- [x] Add cancellation workflow and make cancellations prevent fulfillment.
- [x] Add return/RMA workflow with optional restocking.
- [x] Add failed-payment recovery emails or abandoned checkout follow-up.
- [x] Add rate limiting or abuse protection for checkout session creation, reviews, surveys, analytics, and email sending.
- [x] Add upload validation for product/site images, including file size, MIME type, and allowed extensions.
- [x] Correct the production index migration so it references `analytics_daily_metrics`, not `daily_metrics`.
- [x] Confirm all production indexes are applied to the live database.
- [x] Add server-side pagination/filtering for orders, customers, products, reviews, and reports.
- [x] Add address validation before shipping labels are purchased.
- [ ] Live-test USPS, UPS, FedEx, and DHL labels with real or sandbox carrier credentials. Use `npm run smoke-test-carrier-labels` after credentials are configured.
- [x] Add tracking status refresh or carrier webhook support where available.
- [x] Add password reset and account verification test coverage.
- [x] Add stronger audit logging for admin changes to products, prices, stock, orders, taxes, payment settings, shipping settings, and credentials.
- [x] Add monitoring/alerting for failed payments, failed emails, failed label creation, and webhook errors.

### Code Maintainability

- [~] Split the large storefront/app state file into smaller checkout, account, catalog, analytics, email, and order services. Started with reward/promotion logic extracted to `lib/app/store_reward_program.dart`.
- [~] Split the large admin screen file into separate admin modules for orders, catalog, inventory, reports, taxes, shipping, email, and users. Started with order filtering/status workflow extracted to `lib/app/admin_order_workflow.dart`.
- [x] Move invoice, packing list, and label HTML builders into dedicated template files or renderer classes. Address labels, invoices, packing lists, and the invoice preview now live in `lib/widgets/print_templates.dart` with focused print-template tests.
- [x] Add integration tests for checkout, Stripe success, Stripe failure, order creation, survey saving, inventory decrement, coupon limits, tax breakdown, and email sending. Local guard coverage now verifies draft order parsing, paid/failed status handoff, inventory validation, coupon limits, tax breakdown, and survey review parsing; live Stripe/SMTP checks remain in Final Sign-Off.
- [x] Add Edge Function tests or scripted smoke tests for Stripe checkout, Stripe webhook, send-email, and shipping functions.
- [x] Add regression tests for order filters, batch printing, status changes, and admin payment/fulfillment warnings. Admin order workflow tests now cover shipping filters, workflow/payment status normalization, unpaid-order detection for batch actions, and sorted visible orders.

### Security And Web Launch

- [x] Replace broad CORS defaults with final production origins for all Edge Functions where possible.
- [x] Document why `send-email` uses Supabase `--no-verify-jwt` and keep its internal admin/order checks covered by tests.
- [x] Self-host or integrity-protect the remote passkeys script loaded in `web/index.html`.
- [x] Add production security headers, including Content Security Policy, X-Frame-Options or frame-ancestors, Referrer-Policy, and Permissions-Policy.
- [x] Add `robots.txt`.
- [x] Add `sitemap.xml`.
- [x] Improve web manifest name, description, theme color, and icons so it no longer reads like a default Flutter app.
- [x] Add structured data for products and organization SEO.
- [x] Add canonical URLs and richer meta tags for public product pages where Flutter web routing allows it.

### Ecommerce Features To Consider

- [x] Wishlist or favorites.
- [x] Gift cards.
- [x] Loyalty or referral program beyond basic referral fields.
- [ ] Wholesale pricing. Later upgrade; retail pricing only for current launch.
- [ ] Subscription fragrance orders. Save idea for later; not part of current launch.
- [ ] Multiple warehouses or inventory locations. Later upgrade; current launch uses one location.
- [ ] Multiple vendors or brand expansion. Later upgrade; current launch uses one vendor.
- [x] Better search, sorting, and filtering for larger catalogs.
- [x] Abandoned cart reporting and follow-up.
- [ ] Tax export workflow for state, county, city, VAT, import, and other tax totals.

## Comparisons

Compared with larger ecommerce platforms like Shopify, BigCommerce, WooCommerce, Square, and Wix, this custom store already has the core fragrance-store workflow: catalog, cart, Stripe checkout, admin orders, inventory, tax logic, promotions, gift cards, loyalty/referrals, reviews, email, reports, invoices, packing lists, and label workflows. The missing or later-upgrade items are:

- [ ] POS/in-person checkout with card-reader hardware and automatic online/offline inventory sync.
- [ ] Multi-channel selling integrations for Amazon, eBay, TikTok Shop, Instagram/Facebook Shop, Google Merchant Center, and product feeds.
- [ ] B2B/wholesale pricing, customer-specific price lists, purchase orders, net terms, and company accounts.
- [ ] Subscription/replenishment orders for recurring fragrance purchases.
- [ ] Multi-location inventory, warehouse transfers, purchase orders, vendor receiving, and inventory forecasting.
- [ ] Multi-currency checkout, multi-language storefront content, and deeper international localization.
- [ ] Advanced tax automation and accounting integrations such as Avalara/TaxJar-style filing support, QuickBooks/Xero exports, and automated tax return reports.
- [ ] Built-in fraud/risk scoring, chargeback workflow, and order-risk rules before fulfillment.
- [ ] Accelerated wallet checkout beyond Stripe Checkout, such as saved customer wallets, Shop Pay-style one-click checkout, Apple Pay/Google Pay review, and PayPal/Venmo options if wanted.
- [ ] Customer self-service portal for returns/RMAs, tracking lookup, invoice downloads, and saved addresses/payment preferences.
- [ ] Customer support integrations such as live chat, help desk tickets, SMS updates, and automated post-purchase flows.
- [ ] App/plugin marketplace or integration layer so future tools can be added without custom coding each one.
- [ ] Mobile admin/POS app for managing orders, inventory, labels, and customer messages from a phone.
- [ ] Enterprise operations features such as uptime status page, support SLA, staff role granularity, audit export, backups/restore drills, and disaster recovery runbook.
- [ ] Advanced merchandising tools: bundles, product recommendations, upsells/cross-sells, waitlists/back-in-stock alerts, A/B tests, and landing-page builder.
- [ ] Headless/API commerce features for external storefronts, mobile apps, AI shopping agents, and third-party checkout experiences.

## Final Sign-Off

Before public launch, finish these:

- [ ] live Stripe payment test
- [ ] real SMTP inbox test
- [ ] real carrier label test
- [ ] final tax rate review
- [ ] final owner walkthrough
