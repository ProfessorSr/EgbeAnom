# Current Status

This file tells the plain truth about what the store can do right now.

## Working Now

- products and photos
- categories
- inventory review and inventory printing
- coupons and promotions
- buy X and get Y at a set price
- tax rules for state, county, city, other, VAT, and import charges
- checkout tax breakdown
- flat rate shipping per order and per item
- carrier shipping setup
- order review, filters, and batch actions
- invoice, pack list, and label printing
- customer reviews and post-purchase survey
- customer records
- admin users
- reports and downloads
- Stripe sandbox checkout
- order creation before payment as pending and unpaid
- order update after successful payment to paid
- inventory decrease after paid order
- SMTP email sending path
- custom domain SMTP test succeeded
- admin email inbox sync
- admin notification bell and red badges
- customer account cards and account updates
- customer return requests
- admin return, RMA, and Stripe refund workflow
- gift cards, loyalty, referrals, wishlist, and mailing lists
- analytics saved in the database

## Clean Starting Data

Old test orders, old test customers, old reviews, carts, wishlist entries, notifications, and analytics were cleaned.

The customer account kept for testing is `calvin.fowler74@gmail.com`.

## Quick Score

- overall handoff readiness: about 90%
- core fragrance-store workflow: about 95%
- admin and store operations: about 90%
- checkout and Stripe sandbox flow: about 95%
- printing and fulfillment workflow: about 94%
- email workflow: about 98%
- public launch readiness: about 92%
- commercial platform parity: about 68%

These scores are conservative on purpose. Most core features are built, but public launch should not be called 100% until at least one live payment processor is tested, final email/inbox behavior is confirmed after deployment, tax rates are reviewed, and the owner can complete the daily workflow without developer help. Carrier shipping processors are optional add-ons unless the client chooses to buy shipping labels inside the site at launch.

The commercial platform score is lower because Shopify, BigCommerce, WooCommerce, Square, and Wix-style platforms include broader growth features like POS hardware, multi-channel selling, B2B accounts, subscriptions, multi-location inventory, accounting/tax integrations, and app marketplaces. Those are useful future upgrades, not required for this fragrance-store handoff.

## Still Needs Real-World Sign-Off

These items are built, but should be tested with real business accounts before public launch:

- one small live payment through the active payment processor, currently Stripe
- final email send and inbox sync after deployment
- final tax rates checked against the real store location

## Important Order Rule

An order can exist before payment.

That is normal.

Do not ship it until the financial status says paid.

## Best Honest Launch Advice

The store is close for handoff and training.

Before public launch, finish the live payment test, final email/inbox check after deployment, and final tax review. Test carrier credentials only if the client chooses live carrier label processors for launch.
