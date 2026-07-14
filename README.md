# EgbeAnom Handoff Docs

This folder is the handoff pack for the EgbeAnom store.

It is written for a store owner, not a programmer.

Start here:

1. `Docs/Admin Guide/README.md`
2. `Docs/Admin Guide/Owner Quick Start.md`
3. `Docs/Admin Guide/Routine Checklist.md`
4. `CURRENT_STATUS.md`
5. `PRODUCTION_HANDOFF_CHECKLIST.md`
6. `Docs/Admin Guide/Expansions.md`

## What Works Now

The store can manage products, categories, inventory, taxes, shipping, promotions, orders, invoices, pack lists, labels, reviews, reports, and admin users.

It also includes customer account cards, wishlist, gift cards, loyalty points, referrals, mailing lists, admin notifications, returns/RMAs, refunds, and an admin email inbox.

Stripe sandbox checkout has been tested through the main happy path:

- the customer adds items to cart
- the order is saved as pending and unpaid
- Stripe payment succeeds
- the order changes to paid
- the success page shows order details
- the survey appears
- the order can be processed in admin

Email sending is wired through SMTP, and custom domain SMTP has sent successfully. The admin Email page can also sync inbox messages for the store mailbox.

## Before Public Launch

Do these final checks:

- enter the final store address
- enter final tax rules
- enter final shipping choices
- enter carrier credentials only if the client wants live carrier label processors in the site
- confirm the final SMTP mailbox still sends and receives after deployment
- upload and confirm the final homepage banner and logo
- enter live keys for the active payment processor, currently Stripe, and run one small live payment
- check one invoice, one pack list, and one label printout
- make sure unpaid orders are not shipped

## Browser Book

There is also an easy browser version of the admin guide:

[Open the browser book](./Docs/Admin%20Guide%20Book/index.html)

## Paid Expansions

Optional paid upgrades are listed here:

[Expansions](./Docs/Admin%20Guide/Expansions.md)
