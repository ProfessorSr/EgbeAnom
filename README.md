# EgbeAnom Handoff Docs

This folder is the handoff pack for the EgbeAnom store.

It is written for a store owner, not a programmer.

Start here:

1. `OWNER_QUICK_START.md`
2. `Docs/Admin Guide/README.md`
3. `ROUTINE_CHECKLIST.md`
4. `CURRENT_STATUS.md`
5. `PRODUCTION_HANDOFF_CHECKLIST.md`

## What Works Now

The store can manage products, categories, inventory, taxes, shipping, promotions, orders, invoices, pack lists, labels, reviews, reports, and admin users.

Stripe sandbox checkout has been tested through the main happy path:

- the customer adds items to cart
- the order is saved as pending and unpaid
- Stripe payment succeeds
- the order changes to paid
- the success page shows order details
- the survey appears
- the order can be processed in admin

Email sending is wired through SMTP. Before launch, enter the real mailbox settings and send a real test email.

## Before Public Launch

Do these final checks:

- enter the final store address
- enter final tax rules
- enter final shipping choices and carrier credentials
- enter real SMTP email settings and confirm a test email arrives
- enter live Stripe keys and run one small live payment
- check one invoice, one pack list, and one label printout
- make sure unpaid orders are not shipped

## Browser Book

There is also an easy browser version of the admin guide:

[Open the browser book](./Docs/Admin%20Guide%20Book/index.html)
