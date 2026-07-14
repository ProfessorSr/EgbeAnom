const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const mdDir = path.join(root, 'Docs', 'Admin Guide');
const bookDir = path.join(root, 'Docs', 'Admin Guide Book');

const pages = [
  {
    title: 'Overview',
    file: 'Overview.md',
    html: 'overview.html',
    summary: 'Use this page first. It shows the biggest numbers and points you to the work that needs attention.',
    sections: [
      ['What This Page Is For', [
        'The overview is the store dashboard.',
        'Use it to check sales, orders, customers, inventory, reviews, and alerts.',
        'The cards on the dashboard open the matching detail page. For example, Revenue opens sales details, Orders opens the orders page, and New Users opens customers sorted by newest first.'
      ]],
      ['What To Check Every Morning', [
        'Look for new paid orders.',
        'Look for unpaid orders so they do not get shipped by mistake.',
        'Look for low-stock products.',
        'Look for reviews waiting for approval.',
        'Look for alerts that need action.'
      ]],
      ['Simple Rule', [
        'If a number looks wrong, click the card. The detail page should show where the number came from.'
      ]]
    ]
  },
  {
    title: 'Catalog',
    file: 'Catalog.md',
    html: 'catalog.html',
    summary: 'Use this to add, edit, and check products.',
    sections: [
      ['What Belongs On Every Product', [
        'Each fragrance should have a name, price, SKU, photo, category, stock count, and description.',
        'Each fragrance should also have Description, Vibe, Performance, Comparison, Fragrance Profile, top notes, heart notes, and base notes filled in.',
        'If a product has sizes or versions, check the price, SKU, and stock for each version.'
      ]],
      ['Photos', [
        'A product photo should show on the storefront and in admin.',
        'If a photo is missing, upload it again or ask a technical helper to check the image storage connection.'
      ]],
      ['Before Making A Product Live', [
        'Read the product page like a customer.',
        'Check that the price is right.',
        'Check that stock is not zero unless the product is truly sold out.'
      ]]
    ]
  },
  {
    title: 'Categories',
    file: 'Categories.md',
    html: 'categories.html',
    summary: 'Use this to group products so shoppers can find them.',
    sections: [
      ['What Categories Do', [
        'Categories are shelves inside the online store.',
        'Examples are Men, Women, Unisex, Samples, or Gift Sets.',
        'Keep names short and clear.'
      ]],
      ['Good Habit', [
        'After changing categories, open the storefront and make sure products still appear in the right places.'
      ]]
    ]
  },
  {
    title: 'Inventory',
    file: 'Inventory.md',
    html: 'inventory.html',
    summary: 'Use this to watch stock counts and print a simple stock table.',
    sections: [
      ['How Stock Changes', [
        'When an order is paid, inventory goes down one time.',
        'Unpaid orders should not lower inventory yet.',
        'The system remembers if stock was already lowered for an order so a refresh should not subtract it twice.'
      ]],
      ['What To Check', [
        'Look for low-stock items.',
        'Fix stock counts if a physical count does not match the screen.',
        'Use the print option when you want a simple table with lines, like what is shown on the screen.'
      ]],
      ['If Stock Looks Wrong', [
        'Check whether the order was paid.',
        'Check whether the product version has its own stock count.',
        'Ask a technical helper if paid orders are not lowering stock.'
      ]]
    ]
  },
  {
    title: 'Carts',
    file: 'Carts.md',
    html: 'carts.html',
    summary: 'Use this to see shopping carts before they become orders.',
    sections: [
      ['What You See Here', [
        'A cart is what a shopper is thinking about buying.',
        'A cart is not the same as a paid order.',
        'Use carts to understand what shoppers are interested in.'
      ]]
    ]
  },
  {
    title: 'Promotions',
    file: 'Promotions.md',
    html: 'promotions.html',
    summary: 'Use this for coupons and special deals.',
    sections: [
      ['Promotion Types', [
        'You can make normal discount codes.',
        'You can make free shipping offers.',
        'You can make buy X and get Y at a set price, such as buy 2 and get 1 for $5.'
      ]],
      ['Before Sharing A Code', [
        'Check the spelling of the code.',
        'Check the start and end dates.',
        'Check limits so the discount cannot be used more than intended.',
        'Test the code in checkout before sending it to customers.'
      ]]
    ]
  },
  {
    title: 'Payments',
    file: 'Payments.md',
    html: 'payments.html',
    summary: 'Use this to manage payment provider settings and check payment flow.',
    sections: [
      ['Plain English Version', [
        'Stripe sandbox checkout is working from cart to payment to admin order update.',
        'An order is first saved as pending and unpaid.',
        'After Stripe says payment succeeded, the order changes to paid and stays pending for fulfillment.',
        'Before public launch, do one small live payment with production Stripe keys.'
      ]],
      ['What Not To Ship', [
        'Do not ship unpaid orders.',
        'Use the order financial status to confirm payment was received.',
        'If payment status is missing or unpaid, stop and check before sending product.'
      ]],
      ['After A Successful Payment', [
        'The customer sees the payment received page.',
        'The customer sees order details.',
        'The customer can fill out the survey.',
        'The customer should receive an invoice or order email after SMTP email is tested.'
      ]]
    ]
  },
  {
    title: 'Shipping',
    file: 'Shipping.md',
    html: 'shipping.html',
    summary: 'Use this to manage shipping prices, methods, and carrier tools.',
    sections: [
      ['Shipping Choices', [
        'The store supports flat rate per order.',
        'The store supports flat rate per item.',
        'The store can also show carrier choices such as standard, priority, priority one day, and ground.'
      ]],
      ['Labels', [
        'Carrier labels need real carrier account details before launch.',
        'If carrier label details are missing, the system can still make a clean address label.',
        'When a label is created, the order should move to Label created.'
      ]],
      ['Tracking', [
        'If the carrier gives a tracking number, it should be saved on the order.',
        'A tracking number can also be typed in by hand.'
      ]]
    ]
  },
  {
    title: 'Content',
    file: 'Content.md',
    html: 'content.html',
    summary: 'Use this to change store words, sections, and public page content.',
    sections: [
      ['What To Edit Here', [
        'Homepage text.',
        'Banners.',
        'Store page wording.',
        'Small content blocks around the website.'
      ]],
      ['Good Habit', [
        'After changing content, open the storefront and read it like a customer.'
      ]]
    ]
  },
  {
    title: 'Customers',
    file: 'Customers.md',
    html: 'customers.html',
    summary: 'Use this to review customer records.',
    sections: [
      ['What You Can See', [
        'Customer name.',
        'Email.',
        'Address details.',
        'Order count.',
        'Lifetime value.',
        'Blocked status.'
      ]],
      ['When To Use This Page', [
        'Fix a customer record.',
        'Look up a customer order history.',
        'Block a problem account if needed.'
      ]]
    ]
  },
  {
    title: 'Orders',
    file: 'Orders.md',
    html: 'orders.html',
    summary: 'Use this every day to process orders.',
    sections: [
      ['Payment And Fulfillment Status', [
        'When a customer places an order, it is saved as pending and unpaid before Stripe payment finishes.',
        'After Stripe payment succeeds, financial status changes to paid.',
        'New paid orders should have order status Pending.'
      ]],
      ['Order Status Meanings', [
        'Pending means the paid order is new and needs work.',
        'Processing means the pack list was printed and the order is being picked.',
        'Invoice created means the invoice was created or printed.',
        'Label created means the shipping label was created.',
        'Sent or Shipped means the package has been sent.',
        'Delivered means the customer received it.',
        'Cancelled means the order should not be fulfilled.'
      ]],
      ['Normal Order Flow', [
        'Print the pack list. The order becomes Processing.',
        'Create or print the invoice. The order becomes Invoice created.',
        'Create the shipping label. The order becomes Label created.',
        'When the package leaves, mark it Sent. The order becomes shipped.'
      ]],
      ['Filters', [
        'Shipping type filter should show standard, priority, priority one day, ground, and all.',
        'Order status filter should show pending, processing, invoice created, label created, sent, delivered, cancelled, and all.',
        'Financial status filter helps you avoid shipping unpaid orders.'
      ]],
      ['Batch Printing', [
        'You can select many orders and print invoices, pack lists, or labels.',
        'Each invoice or pack list should print on its own 8.5 x 11 inch page.',
        'If only one prints during batch work, stop and ask a technical helper to check the browser print window and batch print page.'
      ]]
    ]
  },
  {
    title: 'Invoices',
    file: 'Invoices.md',
    html: 'invoices.html',
    summary: 'Use this to preview and print customer invoices.',
    sections: [
      ['What The Invoice Should Look Like', [
        'The invoice is clean, mostly black and white, and should fit one order on one 8.5 x 11 inch page.',
        'The EgbeAnom watermark should appear softly in the background.',
        'The QR code should appear in the bottom right area.',
        'The return policy should appear neatly in the footer.'
      ]],
      ['Editable Text', [
        'The footer text changes the thank-you message on the invoice.',
        'The old separate invoice header text box was removed because it did not control anything useful.'
      ]],
      ['Printing', [
        'Use one invoice per order.',
        'For many orders, batch print should still keep each order on its own page.'
      ]]
    ]
  },
  {
    title: 'Reviews',
    file: 'Reviews.md',
    html: 'reviews.html',
    summary: 'Use this to approve survey and product reviews.',
    sections: [
      ['Where Reviews Come From', [
        'After successful payment, the customer can fill out a survey on the payment received page.',
        'Submitted survey answers should appear in admin reviews.',
        'Approved reviews can be shown publicly if the store is set up to display them.'
      ]],
      ['If Nothing Shows', [
        'If there are no comments, the comments area should stay hidden and only the leave comment section should show.',
        'If a customer says they submitted a review but it is missing, ask a technical helper to check review saving.'
      ]]
    ]
  },
  {
    title: 'Alerts',
    file: 'Alerts.md',
    html: 'alerts.html',
    summary: 'Use this as the store notice board.',
    sections: [
      ['What Alerts Are For', [
        'New orders.',
        'Review activity.',
        'Low stock.',
        'Shipping or payment events that need attention.'
      ]],
      ['Good Habit', [
        'Check alerts once a day, then clear or handle anything important.'
      ]]
    ]
  },
  {
    title: 'Email',
    file: 'Email.md',
    html: 'email.html',
    summary: 'Use this to set up SMTP email and send test emails.',
    sections: [
      ['What Email Does Now', [
        'The app can send through SMTP using the deployed email function.',
        'Customers can receive an invoice or order email after successful payment.',
        'Customers can receive emails when status changes to Processing, Label created, and Sent or Shipped.'
      ]],
      ['Provider Choices', [
        'Choose Google or Gmail if the store uses a Gmail or Google Workspace mailbox.',
        'Choose GoDaddy if the mailbox is hosted at GoDaddy.',
        'Choose Generic if another email company gives you SMTP settings.'
      ]],
      ['What To Enter', [
        'From name is the store name customers see.',
        'From email is the store email address.',
        'SMTP host and port come from the email provider.',
        'Username is usually the full email address.',
        'Password should usually be an app password, not the normal mailbox password.',
        'Use direct SSL only if the provider says to use SSL on that port. Gmail and GoDaddy usually use port 587 with direct SSL turned off.'
      ]],
      ['Before Trusting Email', [
        'Save settings.',
        'Send one test email to a real inbox.',
        'Open the inbox and confirm it arrived.',
        'Then test a paid order email.'
      ]]
    ]
  },
  {
    title: 'Site',
    file: 'Site.md',
    html: 'site.html',
    summary: 'Use this to control public website settings.',
    sections: [
      ['Common Things To Check', [
        'Store online or offline setting.',
        'Homepage sections.',
        'Return policy.',
        'Public contact information.',
        'Analytics or tracking settings.'
      ]],
      ['Important', [
        'The store location in Store Info is what tax rules use. Do not change it casually.'
      ]]
    ]
  },
  {
    title: 'Store Info',
    file: 'Store Info.md',
    html: 'store-info.html',
    summary: 'Use this to set the store name, address, phone, and email.',
    sections: [
      ['Why This Page Matters', [
        'Invoices use this information.',
        'Labels and packing papers use this information.',
        'Tax rules use the store state, county, city, and country.'
      ]],
      ['Before Launch', [
        'Check store name.',
        'Check phone number.',
        'Check email.',
        'Check full address.',
        'Check city, county, state, ZIP, and country.'
      ]]
    ]
  },
  {
    title: 'Taxes',
    file: 'Taxes.md',
    html: 'taxes.html',
    summary: 'Use this to manage state, county, city, other, VAT, and import tax rules.',
    sections: [
      ['Location Tax Rule', [
        'If the customer is in the same city as the store, charge city, county, and state taxes.',
        'If the customer is in the same county but not the same city, charge county and state taxes.',
        'If the customer is in the same state but not the same county or city, charge state tax.',
        'If the customer is not in the same state, do not charge US state, county, or city tax.'
      ]],
      ['Other Tax Types', [
        'Use Other for a tax that is not tied to state, county, or city.',
        'Use VAT or import tax for country-based international charges.',
        'VAT means Value Added Tax. It is a sales-style tax used by many countries outside the United States.'
      ]],
      ['Checkout', [
        'Customers should see the tax breakdown before paying.',
        'The breakdown helps the store know what money belongs to state, county, city, VAT, or other tax.'
      ]]
    ]
  },
  {
    title: 'Users',
    file: 'Users.md',
    html: 'users.html',
    summary: 'Use this to manage admin users.',
    sections: [
      ['What To Do Here', [
        'Add people who need admin access.',
        'Remove people who no longer need access.',
        'Keep admin access limited to trusted people.'
      ]],
      ['Good Habit', [
        'Review admin users before handoff and at least once a month.'
      ]]
    ]
  },
  {
    title: 'Analytics',
    file: 'Analytics.md',
    html: 'analytics.html',
    summary: 'Use this to see traffic and store activity.',
    sections: [
      ['What To Watch', [
        'Visitors.',
        'Product views.',
        'Cart activity.',
        'Orders.',
        'Revenue.'
      ]],
      ['If Numbers Reset', [
        'Analytics should be stored in the database.',
        'If numbers go back to zero after refresh, ask a technical helper to check the analytics save path.'
      ]]
    ]
  },
  {
    title: 'Reports',
    file: 'Reports.md',
    html: 'reports.html',
    summary: 'Use this to understand money, products, shipping, and taxes.',
    sections: [
      ['Tax Collected', [
        'The tax card should show total tax collected.',
        'Clicking or opening the details should break tax down by state, county, city, VAT, import, and other.',
        'This helps send the right amount to the right tax office.'
      ]],
      ['Product Sales', [
        'Product sales should show what sold and how many.',
        'Use this to reorder popular items and spot slow movers.'
      ]],
      ['Shipping', [
        'Shipping reports should show totals by method or carrier.',
        'Use this to compare what customers paid against what shipping cost.'
      ]],
      ['Downloads', [
        'Use CSV when you want a spreadsheet.',
        'Use JSON or SQL only if a technical helper asks for it.'
      ]]
    ]
  }
];

const rootDocs = {
  'README.md': `# EgbeAnom Handoff Docs

This folder is the handoff pack for the EgbeAnom store.

It is written for a store owner, not a programmer.

Start here:

1. \`OWNER_QUICK_START.md\`
2. \`Docs/Admin Guide/README.md\`
3. \`ROUTINE_CHECKLIST.md\`
4. \`CURRENT_STATUS.md\`
5. \`PRODUCTION_HANDOFF_CHECKLIST.md\`

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
`,
  'OWNER_QUICK_START.md': `# Owner Quick Start

This guide is for the store owner.

It uses simple words on purpose.

## What The Admin Area Does

Think of the admin area like the control room for the store.

It lets you:

- add and edit products
- change prices and stock
- make coupons
- set tax rules
- set shipping choices
- look at orders
- print invoices, pack lists, and labels
- approve reviews
- see reports
- send customer emails

## What To Open First

When you log in, start here:

1. \`Store Info\`
2. \`Taxes\`
3. \`Shipping\`
4. \`Email\`
5. \`Payments\`
6. \`Catalog\`
7. \`Orders\`
8. \`Reports\`

## First Day Setup

### 1. Store Info

Add the final store name, address, city, county, state, ZIP code, country, email, and phone number.

This matters because taxes, invoices, pack lists, and labels use this information.

### 2. Taxes

Add the tax rules for the store.

Simple rule:

- same city as the store means city, county, and state tax
- same county but different city means county and state tax
- same state but different county means state tax
- different state means no US state, county, or city tax

For international orders, use VAT or import tax rules when needed.

### 3. Shipping

Set the shipping choices customers can pick.

The store supports:

- flat rate per order
- flat rate per item
- carrier choices such as standard, priority, priority one day, and ground

Real carrier labels need real carrier account details.

### 4. Email

Choose Google/Gmail, GoDaddy, or Generic SMTP.

Enter the mailbox settings, save, then send a test email to a real inbox.

Do not trust customer emails until the test email arrives.

### 5. Payments

Stripe sandbox checkout works for testing.

Before real customers use the store, add live Stripe keys and run one small live payment.

### 6. Catalog

Check every product.

Make sure each item has a name, price, photo, SKU, stock count, and description.

## Daily Work

- Open \`Overview\`.
- Open \`Orders\`.
- Print pack lists for paid new orders.
- Print invoices if needed.
- Create labels.
- Mark sent packages as sent.
- Check \`Inventory\` for low stock.
- Check \`Reviews\`.
- Check \`Reports\` when you need numbers.

## Easy Rule

Do not ship an order unless the financial status says paid.
`,
  'ADMIN_GUIDE.md': `# Admin Guide

The full owner guide lives here:

[Docs/Admin Guide/README.md](./Docs/Admin%20Guide/README.md)

There is also a browser book here:

[Docs/Admin Guide Book/index.html](./Docs/Admin%20Guide%20Book/index.html)

Best starting pages:

- [Overview](./Docs/Admin%20Guide/Overview.md)
- [Catalog](./Docs/Admin%20Guide/Catalog.md)
- [Orders](./Docs/Admin%20Guide/Orders.md)
- [Taxes](./Docs/Admin%20Guide/Taxes.md)
- [Email](./Docs/Admin%20Guide/Email.md)
- [Reports](./Docs/Admin%20Guide/Reports.md)
`,
  'CURRENT_STATUS.md': `# Current Status

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

## Still Needs Real-World Sign-Off

These items are built, but should be tested with real business accounts before public launch:

- one small live Stripe payment
- real SMTP email delivery to an inbox
- real carrier label creation with final carrier credentials
- final tax rates checked against the real store location

## Important Order Rule

An order can exist before payment.

That is normal.

Do not ship it until the financial status says paid.

## Best Honest Launch Advice

The store is close for handoff and training.

Before public launch, finish the live payment test, email inbox test, carrier credential test, and final tax review.
`,
  'ROUTINE_CHECKLIST.md': `# Routine Checklist

This is the simple care list for the store.

## Every Day

- open \`Overview\`
- open \`Orders\`
- look for paid orders with status \`Pending\`
- do not ship unpaid orders
- print pack lists
- create invoices if needed
- create labels
- mark sent packages as \`Sent\`
- open \`Inventory\` and look for low stock
- open \`Reviews\` and approve or reject waiting reviews
- check alerts

## Every Week

- open \`Reports\`
- check sales
- check tax collected
- check product sales
- check shipping totals
- check low-stock items
- send one test email if email settings changed
- review promotions and turn off old coupons

## Every Month

- download CSV reports
- save order history
- save customer history
- save product list
- review taxes
- review admin users
- print one invoice and one pack list as a spot check

## Before A Big Sale

- check prices
- check stock
- check coupons
- check shipping choices
- check tax rules
- check homepage content
- send a test email

## Before Public Launch

- final store info is complete
- final product photos are uploaded
- final tax rules are correct
- final shipping rules are correct
- real SMTP email test arrived in an inbox
- one small live Stripe payment worked
- invoices print correctly
- pack lists print correctly
- labels print correctly
- unpaid orders are clearly visible in admin

## When To Ask For Technical Help

Ask for help if the problem mentions:

- Stripe keys or webhooks
- Supabase
- SMTP passwords or app passwords
- carrier account credentials
- database errors
- emails not arriving
- payment not updating an order to paid
`,
  'PRODUCTION_HANDOFF_CHECKLIST.md': `# Production Handoff Checklist

This is the simple checklist for client handoff.

\`[x]\` means done.

\`[~]\` means built, but needs a real-world check.

\`[ ]\` means not signed off yet.

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
- [x] Move SMTP, payment, and carrier secrets out of plain \`site_settings\` JSON and into an encrypted credential path.
- [x] Fix and apply the credential encryption migration before storing real production secrets.

### High Priority Hardening

- [x] Add refund workflow and make refunds update order financial status.
- [x] Add cancellation workflow and make cancellations prevent fulfillment.
- [x] Add return/RMA workflow with optional restocking.
- [x] Add failed-payment recovery emails or abandoned checkout follow-up.
- [x] Add rate limiting or abuse protection for checkout session creation, reviews, surveys, analytics, and email sending.
- [x] Add upload validation for product/site images, including file size, MIME type, and allowed extensions.
- [x] Correct the production index migration so it references \`analytics_daily_metrics\`, not \`daily_metrics\`.
- [x] Confirm all production indexes are applied to the live database.
- [x] Add server-side pagination/filtering for orders, customers, products, reviews, and reports.
- [x] Add address validation before shipping labels are purchased.
- [ ] Live-test USPS, UPS, FedEx, and DHL labels with real or sandbox carrier credentials. Use \`npm run smoke-test-carrier-labels\` after credentials are configured.
- [x] Add tracking status refresh or carrier webhook support where available.
- [x] Add password reset and account verification test coverage.
- [x] Add stronger audit logging for admin changes to products, prices, stock, orders, taxes, payment settings, shipping settings, and credentials.
- [x] Add monitoring/alerting for failed payments, failed emails, failed label creation, and webhook errors.

### Code Maintainability

- [~] Split the large storefront/app state file into smaller checkout, account, catalog, analytics, email, and order services. Started with reward/promotion logic extracted to \`lib/app/store_reward_program.dart\`.
- [~] Split the large admin screen file into separate admin modules for orders, catalog, inventory, reports, taxes, shipping, email, and users. Started with order filtering/status workflow extracted to \`lib/app/admin_order_workflow.dart\`.
- [x] Move invoice, packing list, and label HTML builders into dedicated template files or renderer classes. Address labels, invoices, packing lists, and the invoice preview now live in \`lib/widgets/print_templates.dart\` with focused print-template tests.
- [x] Add integration tests for checkout, Stripe success, Stripe failure, order creation, survey saving, inventory decrement, coupon limits, tax breakdown, and email sending. Local guard coverage now verifies draft order parsing, paid/failed status handoff, inventory validation, coupon limits, tax breakdown, and survey review parsing; live Stripe/SMTP checks remain in Final Sign-Off.
- [x] Add Edge Function tests or scripted smoke tests for Stripe checkout, Stripe webhook, send-email, and shipping functions.
- [x] Add regression tests for order filters, batch printing, status changes, and admin payment/fulfillment warnings. Admin order workflow tests now cover shipping filters, workflow/payment status normalization, unpaid-order detection for batch actions, and sorted visible orders.

### Security And Web Launch

- [x] Replace broad CORS defaults with final production origins for all Edge Functions where possible.
- [x] Document why \`send-email\` uses Supabase \`--no-verify-jwt\` and keep its internal admin/order checks covered by tests.
- [x] Self-host or integrity-protect the remote passkeys script loaded in \`web/index.html\`.
- [x] Add production security headers, including Content Security Policy, X-Frame-Options or frame-ancestors, Referrer-Policy, and Permissions-Policy.
- [x] Add \`robots.txt\`.
- [x] Add \`sitemap.xml\`.
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
`
};

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function mdList(items) {
  return items.map((item) => `- ${item}`).join('\n');
}

function pageMarkdown(page) {
  return `# ${page.title}\n\n${page.summary}\n\n${page.sections.map(([heading, items]) => `## ${heading}\n\n${mdList(items)}`).join('\n\n')}\n\n[Back to Admin Guide Home](./README.md)\n`;
}

function guideReadme() {
  const links = pages.map((page) => `- [${page.title}](./${encodeURI(page.file)}) - ${page.summary}`).join('\n');
  return `# EgbeAnom Admin Guide\n\nThis is the plain-English guide for running the store.\n\nIt is written for someone who does not code.\n\n## Start Here\n\n1. Read [Overview](./Overview.md).\n2. Check [Store Info](./Store%20Info.md).\n3. Check [Taxes](./Taxes.md).\n4. Check [Shipping](./Shipping.md).\n5. Check [Email](./Email.md).\n6. Use [Orders](./Orders.md) every day.\n\n## Important Rule\n\nDo not ship an order unless its financial status says paid.\n\n## Pages\n\n${links}\n\n## Browser Book\n\nOpen the browser version here:\n\n[Open the browser book](../Admin%20Guide%20Book/index.html)\n`;
}

function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function nav(active) {
  return `<nav class="nav-card"><h2>Guide Pages</h2><ul>${pages.map((page) => {
    const cls = page.html === active ? ' class="active"' : '';
    return `<li><a${cls} href="${page.html}">${escapeHtml(page.title)}</a></li>`;
  }).join('')}</ul></nav>`;
}

function htmlShell(title, active, body) {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)} - EgbeAnom Admin Guide</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="shell">
    <header class="book-top">
      <h1>EgbeAnom Admin Guide</h1>
      <p>Plain-English instructions for running the store.</p>
    </header>
    <section class="book-grid">
      ${nav(active)}
      <article class="page-card">
        ${body}
      </article>
    </section>
  </main>
</body>
</html>
`;
}

function pageHtml(page) {
  const sections = page.sections.map(([heading, items]) => `<h2>${escapeHtml(heading)}</h2>\n<ul>${items.map((item) => `<li>${escapeHtml(item)}</li>`).join('')}</ul>`).join('\n');
  return htmlShell(page.title, page.html, `<span class="eyebrow">Admin Page</span>\n<h1>${escapeHtml(page.title)}</h1>\n<p>${escapeHtml(page.summary)}</p>\n${sections}\n<div class="next-box"><a href="index.html">Back to guide home</a></div>`);
}

function indexHtml() {
  const cards = pages.map((page) => `<a class="home-link" href="${page.html}"><strong>${escapeHtml(page.title)}</strong><span>${escapeHtml(page.summary)}</span></a>`).join('\n');
  return htmlShell('Home', '', `<span class="eyebrow">Handoff Book</span>\n<h1>Start Here</h1>\n<p>This book explains the admin area in simple words. Use it when training the owner or checking how to do normal store work.</p>\n<div class="tip"><strong>Main rule:</strong> do not ship an order unless the financial status says paid.</div>\n<div class="home-grid">${cards}</div>`);
}

function styleCss() {
  return `:root {
  --bg: #f7f3ec;
  --paper: #fffdf9;
  --ink: #1a1a1a;
  --muted: #63594b;
  --line: #decfb8;
  --gold: #b8842b;
  --gold-dark: #7d5819;
  --shadow: 0 18px 40px rgba(45, 31, 10, 0.08);
}

* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: Georgia, 'Times New Roman', serif;
  background: #f7f3ec;
  color: var(--ink);
}

a { color: var(--gold-dark); }

.shell {
  max-width: 1120px;
  margin: 0 auto;
  padding: 28px 20px 60px;
}

.book-top {
  background: #111;
  color: #f8e3ac;
  border: 1px solid #2e2312;
  border-radius: 18px;
  padding: 26px;
  box-shadow: var(--shadow);
}

.book-top h1 {
  margin: 0 0 8px;
  font-size: 40px;
  font-weight: 500;
}

.book-top p {
  margin: 0;
  font-size: 18px;
  line-height: 1.5;
  color: #f9f1da;
}

.book-grid {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 22px;
  margin-top: 22px;
}

.nav-card,
.page-card {
  background: var(--paper);
  border: 1px solid var(--line);
  border-radius: 16px;
  box-shadow: var(--shadow);
}

.nav-card {
  padding: 18px;
  position: sticky;
  top: 20px;
  align-self: start;
}

.nav-card h2 {
  margin: 0 0 12px;
  font-size: 22px;
}

.nav-card ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.nav-card li + li { margin-top: 6px; }

.nav-card a {
  display: block;
  padding: 10px 12px;
  border-radius: 10px;
  text-decoration: none;
  color: var(--ink);
}

.nav-card a:hover,
.nav-card a.active {
  background: #f4ead5;
  color: var(--gold-dark);
}

.page-card { padding: 28px; }

.eyebrow {
  display: inline-block;
  margin-bottom: 12px;
  padding: 7px 12px;
  border-radius: 999px;
  background: #f6ead1;
  color: var(--gold-dark);
  font-size: 13px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-family: Arial, sans-serif;
  font-weight: 700;
}

.page-card h1 {
  margin: 0 0 12px;
  font-size: 38px;
  font-weight: 500;
}

.page-card h2 {
  margin-top: 28px;
  font-size: 25px;
}

.page-card p,
.page-card li {
  font-size: 18px;
  line-height: 1.7;
}

.page-card ul,
.page-card ol { padding-left: 24px; }

.tip,
.next-box {
  margin-top: 20px;
  padding: 16px 18px;
  border-radius: 14px;
  border: 1px solid var(--line);
  background: #fbf6eb;
}

.home-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
  margin-top: 20px;
}

.home-link {
  display: block;
  padding: 16px;
  background: #f8f1e2;
  border: 1px solid var(--line);
  border-radius: 14px;
  color: var(--ink);
  text-decoration: none;
}

.home-link strong {
  display: block;
  margin-bottom: 8px;
  font-size: 19px;
}

.home-link span {
  display: block;
  color: var(--muted);
  line-height: 1.45;
}

@media (max-width: 760px) {
  .book-grid { grid-template-columns: 1fr; }
  .nav-card { position: static; }
  .book-top h1,
  .page-card h1 { font-size: 31px; }
}
`;
}

ensureDir(mdDir);
ensureDir(bookDir);

for (const [file, content] of Object.entries(rootDocs)) {
  fs.writeFileSync(path.join(root, file), content);
}

fs.writeFileSync(path.join(mdDir, 'README.md'), guideReadme());
for (const page of pages) {
  fs.writeFileSync(path.join(mdDir, page.file), pageMarkdown(page));
}

fs.writeFileSync(path.join(bookDir, 'style.css'), styleCss());
fs.writeFileSync(path.join(bookDir, 'index.html'), indexHtml());
for (const page of pages) {
  fs.writeFileSync(path.join(bookDir, page.html), pageHtml(page));
}

console.log(`Generated ${pages.length} guide pages plus root handoff docs.`);
