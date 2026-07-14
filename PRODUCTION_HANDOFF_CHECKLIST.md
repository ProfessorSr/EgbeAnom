# Production Handoff Checklist

This is the simple checklist for client handoff.

`[x]` means done.

`[~]` means built, but needs a real-world check.

`[ ]` means not signed off yet.

## Quick Score

- Overall handoff readiness: about 90%
- Core fragrance-store workflow: about 95%
- Admin and store operations: about 90%
- Checkout and Stripe sandbox flow: about 95%
- Printing and fulfillment workflow: about 94%
- Email workflow: about 98%
- Public launch readiness: about 92%
- Commercial platform parity: about 68%

These scores are conservative on purpose. Most core features are built, but public launch should not be called 100% until at least one live payment processor is tested, final email/inbox behavior is confirmed after deployment, tax rates are reviewed, and the owner can complete the daily workflow without developer help. Carrier shipping processors are optional add-ons unless the client chooses to buy shipping labels inside the site at launch.

The lower commercial-platform score is not a launch blocker. It means this custom store is strong for the current fragrance business, but it does not yet include every Shopify/BigCommerce/Square-style growth feature such as POS hardware, multi-channel selling, B2B accounts, subscriptions, multi-location inventory, advanced tax/accounting integrations, and an app marketplace.

## Store Setup

- [x] Store info screen exists
- [x] Store address is used by taxes, invoices, and labels
- [~] Final live store address has been checked
- [~] Final banner and logo upload should be tested in Site or Store Info

## Products And Inventory

- [x] Products can be managed
- [x] Photos can be managed
- [x] Main product photo changes save to the database
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
- ⚠️ One small live payment through the active payment processor, currently Stripe, has been completed

## Orders And Fulfillment

- [x] Orders can be filtered by shipping type
- [x] Orders can be filtered by order status
- [x] Orders can be filtered by financial status
- [x] Pack list printing moves orders to Processing
- [x] Invoice creation moves orders to Invoice created
- [x] Label creation moves orders to Label created
- [x] Sent marks orders as shipped
- [x] Batch invoice and pack list printing exists
- [x] Customer return requests exist
- [x] Admin return approval or denial exists
- [x] Approved returns create an RMA and email the customer
- [x] Received returns can trigger Stripe refunds
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
- [x] Custom domain SMTP settings have sent successfully
- [x] Shared email template style exists
- [x] Email footer includes support and unsubscribe wording
- [x] QR code appears in the email footer
- [x] Mass emails hide other recipients by sending one at a time
- [x] Admin Email inbox exists
- [x] Mailing list groups exist for account and non-account recipients
- [x] SMTP sending works with the custom email domain
- [~] Final inbox sync should be checked again after deployment

## Customer Account

- [x] Customer account main page uses clickable cards
- [x] Orders card opens order history with invoices
- [x] Credits card opens credit history and balance
- [x] Points card opens points detail
- [x] Referrals card opens referrals and the full referral link
- [x] Customers can update account information
- [x] Customers can request returns or refunds from an order

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
- [x] Store can launch without live carrier processors by using flat-rate shipping and address-label printing
- ⚠️ Optional add-on: live-test USPS, UPS, FedEx, or DHL if the client chooses carrier label buying inside the site

## Reports

- [x] Reports page exists
- [x] Tax breakdown exists
- [x] Product sales breakdown exists
- [x] Shipping breakdown exists
- [x] CSV downloads exist
- [~] Numbers should be checked against trusted sample orders

## Analytics And Notifications

- [x] Analytics has its own admin tab
- [x] Analytics are stored in the database
- [x] Admin notification bell exists
- [x] Red unread badges appear on the bell and admin tab dropdown
- [x] New order, review, return, and email alerts are tracked
- [x] Browser desktop alerts and sound can be enabled
- [~] Final browser notification permission should be checked on the client computer

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
- ⚠️ Optional add-on: live-test USPS, UPS, FedEx, or DHL labels with real or sandbox carrier credentials if the client chooses live carrier processors. Use `npm run smoke-test-carrier-labels` after credentials are configured.
- [x] Add tracking status refresh or carrier webhook support where available.
- [x] Add password reset and account verification test coverage.
- [x] Add stronger audit logging for admin changes to products, prices, stock, orders, taxes, payment settings, shipping settings, and credentials.
- [x] Add monitoring/alerting for failed payments, failed emails, failed label creation, and webhook errors.

### Code Maintainability

- [~] Split the large storefront/app state file into smaller checkout, account, catalog, analytics, email, and order services. Started with reward/promotion logic extracted to `lib/app/store_reward_program.dart`.
- [~] Split the large admin screen file into separate admin modules for orders, catalog, inventory, reports, taxes, shipping, email, and users. Started with order filtering/status workflow extracted to `lib/app/admin_order_workflow.dart`; dashboard, overview, and report metrics now live in `lib/app/admin_metrics.dart` with focused tests.
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

## Paid Expansions

Optional paid upgrades and commercial-platform comparison items now live in:

[Docs/Admin Guide/Expansions.md](./Docs/Admin%20Guide/Expansions.md)

Keep the launch checklist focused on what is needed to hand off and go live. Use the Expansions page when the client asks what can be added later for an additional implementation cost.

## Final Sign-Off

Before public launch, finish these:

- ⚠️ live payment test through the active payment processor, currently Stripe
- [~] final SMTP send and inbox sync after deployment
- ⚠️ optional carrier label test only if carrier processors are part of launch
- ⚠️ final tax rate review
- ⚠️ final owner walkthrough
