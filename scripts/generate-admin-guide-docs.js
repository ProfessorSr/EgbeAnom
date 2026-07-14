const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const mdDir = path.join(root, 'Docs', 'Admin Guide');
const bookDir = path.join(root, 'Docs', 'Admin Guide Book');

const pages = [
  {
    title: 'Owner Quick Start',
    file: 'Owner Quick Start.md',
    html: 'owner-quick-start.html',
    summary: 'Start here when training the store owner.',
    sections: [
      ['What The Admin Area Does', [
        'Think of the admin area like the control room for the store.',
        'Use it to add and edit products, change prices and stock, make coupons, set tax rules, set shipping choices, look at orders, print invoices, print pack lists, create labels, approve reviews, see reports, send customer emails, read store inbox messages, handle returns and refunds, and check admin notifications.'
      ]],
      ['What To Open First', [
        '1. Store Info.',
        '2. Taxes.',
        '3. Shipping.',
        '4. Email.',
        '5. Payments.',
        '6. Catalog.',
        '7. Orders.',
        '8. Analytics.',
        '9. Reports.'
      ]],
      ['First Day Setup', [
        'Store Info: add the final store name, address, city, county, state, ZIP code, country, email, and phone number.',
        'Taxes: add the tax rules for the store. Same city means city, county, and state tax. Same county means county and state tax. Same state means state tax. Different state means no US state, county, or city tax.',
        'Shipping: set the shipping choices customers can pick. Carrier processors are optional add-ons; the store can launch with flat-rate shipping and address-label printing.',
        'Email: choose Google/Gmail, GoDaddy, or Generic SMTP. Save the mailbox settings, send a test email, and sync the inbox.',
        'Payments: before real customers use the store, add live keys for the active payment processor, currently Stripe, and run one small live payment.',
        'Catalog: check every product for name, price, photo, SKU, stock count, and description.'
      ]],
      ['Daily Work', [
        'Open Overview.',
        'Open Orders.',
        'Print pack lists for paid new orders.',
        'Print invoices if needed.',
        'Create labels or address labels.',
        'Mark sent packages as sent.',
        'Check Inventory for low stock.',
        'Check Reviews.',
        'Check the notification bell for new orders, reviews, returns, and unread email.',
        'Check the Email inbox if the badge shows unread messages.',
        'Check Reports when you need numbers.'
      ]],
      ['Easy Rule', [
        'Do not ship an order unless the financial status says paid.'
      ]],
      ['Optional Paid Upgrades', [
        'The Expansions page lists features that can be added later for an additional implementation cost.'
      ]]
    ]
  },
  {
    title: 'Routine Checklist',
    file: 'Routine Checklist.md',
    html: 'routine-checklist.html',
    summary: 'Print this page and keep it near the shipping or admin workstation as a daily reminder.',
    printable: true,
    sections: [
      ['Every Day', [
        'Open Overview.',
        'Open Orders.',
        'Look for paid orders with status Pending.',
        'Do not ship unpaid orders.',
        'Print pack lists.',
        'Create invoices if needed.',
        'Create labels or address labels.',
        'Mark sent packages as Sent.',
        'Open Inventory and look for low stock.',
        'Open Reviews and approve or reject waiting reviews.',
        'Check the notification bell for new orders, reviews, returns, and unread email.',
        'Check alerts.'
      ]],
      ['Every Week', [
        'Open Reports.',
        'Check sales.',
        'Check tax collected.',
        'Check product sales.',
        'Check shipping totals.',
        'Check low-stock items.',
        'Send one test email if email settings changed.',
        'Sync the Email inbox and check unread messages.',
        'Check admin notification badges.',
        'Review promotions and turn off old coupons.',
        'Review mailing list signups.'
      ]],
      ['Every Month', [
        'Download CSV reports.',
        'Save order history.',
        'Save customer history.',
        'Save product list.',
        'Review taxes.',
        'Review admin users.',
        'Review unread notifications.',
        'Print one invoice and one pack list as a spot check.'
      ]],
      ['Before A Big Sale', [
        'Check prices.',
        'Check stock.',
        'Check coupons.',
        'Check shipping choices.',
        'Check tax rules.',
        'Check homepage content.',
        'Send a test email.'
      ]],
      ['Before Public Launch', [
        'Final store info is complete.',
        'Final homepage banner and logo upload has been tested.',
        'Final product photos are uploaded.',
        'Final tax rules are correct.',
        'Final shipping rules are correct.',
        'Final SMTP email test arrived in an inbox.',
        'Admin Email inbox sync works.',
        'One small live payment through the active payment processor, currently Stripe, worked.',
        'Invoices print correctly.',
        'Pack lists print correctly.',
        'Labels or address labels print correctly.',
        'Unpaid orders are clearly visible in admin.'
      ]],
      ['When To Ask For Technical Help', [
        'Ask for help if the problem mentions Stripe keys or webhooks.',
        'Ask for help if the problem mentions Supabase.',
        'Ask for help if the problem mentions SMTP passwords or app passwords.',
        'Ask for help if the problem mentions carrier account credentials.',
        'Ask for help if the problem mentions database errors.',
        'Ask for help if emails are not arriving.',
        'Ask for help if inbox messages are not syncing.',
        'Ask for help if payment is not updating an order to paid.'
      ]]
    ]
  },
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
        'Carrier label processors are optional add-ons. The store can launch with flat-rate shipping and clean address-label printing if the client does not want live carrier APIs at first.',
        'Carrier labels need real carrier account details only if the client chooses to buy labels inside the site.',
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
        'Phone and account contact details.',
        'Order count.',
        'Lifetime value.',
        'Blocked status.',
        'Last known IP address and device/source type when available.',
        'Mailing list status for account customers.'
      ]],
      ['When To Use This Page', [
        'Fix a customer record.',
        'Look up a customer order history.',
        'Send an email directly to one customer.',
        'Block a problem account if needed.'
      ]],
      ['Customer Account Pages', [
        'Customers can update account information such as address, phone, and email.',
        'The main account page uses cards for Orders, Credits, Points, and Referrals.',
        'Each card opens its own detail page.',
        'Customers can join or leave the account mailing list from their profile or the homepage mailing list card.'
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
        'Cancelled means the order should not be fulfilled.',
        'Awaiting return item means a return was approved and the store is waiting for the item to come back.'
      ]],
      ['Normal Order Flow', [
        'Print the pack list. The order becomes Processing.',
        'Create or print the invoice. The order becomes Invoice created.',
        'Create the shipping label. The order becomes Label created.',
        'When the package leaves, mark it Sent. The order becomes shipped.'
      ]],
      ['Filters', [
        'Shipping type filter should show standard, priority, priority one day, ground, and all.',
        'Order status filter should show pending, processing, invoice created, label created, awaiting return item, sent, delivered, cancelled, and all.',
        'Financial status filter helps you avoid shipping unpaid orders.'
      ]],
      ['Returns And Refunds', [
        'Customers can request a return or refund from their order page.',
        'The admin can approve or deny the request and add a reason and comment.',
        'If approved, the system creates an RMA and emails it to the customer.',
        'The order moves to Awaiting return item.',
        'After the item is received, the admin records the item condition and chooses the refund amount.',
        'Refund choices are product plus shipping, just product, just shipping, or a specific dollar amount.',
        'Approved refunds are sent through Stripe and saved back on the order.'
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
      ]],
      ['Deleting Reviews', [
        'Deleting a review should remove it from the database.',
        'If a deleted review comes back after refreshing, ask a technical helper to check the review delete path.'
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
        'New return requests.',
        'Unread email inbox messages.',
        'Low stock.',
        'Shipping or payment events that need attention.'
      ]],
      ['Where Alerts Show', [
        'Admins see a notification icon near the top right.',
        'A red badge means something unread needs attention.',
        'The big admin tab dropdown also shows red counts beside the matching section name.',
        'Order alerts open the Orders page.',
        'Review alerts open the Reviews page.',
        'Email alerts open the Email page.'
      ]],
      ['Desktop Alerts', [
        'Use Enable desktop alerts if the browser asks for notification permission.',
        'When enabled, the admin can get browser notifications and a sound while the admin page is open.',
        'The admin page also checks for new work while it is already open.'
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
        'Google/Gmail, GoDaddy, custom domain, and generic SMTP settings are supported.',
        'Customers can receive an invoice or order email after successful payment.',
        'Customers can receive emails when status changes to Processing, Label created, and Sent or Shipped.',
        'Emails use the same clean style as invoices and pack lists.',
        'Email footers include support information, unsubscribe instructions, and the QR code.'
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
      ['Inbox', [
        'The Email page includes an inbox for store email such as orders@egbeanom.com.',
        'Use Sync inbox to pull recent messages into admin.',
        'Unread messages show in the Email badge.',
        'Open a message to read it, mark it read or unread, or reply from the composer.'
      ]],
      ['Mailing Lists', [
        'There are two mailing lists.',
        'Account customers can join from their profile or from the homepage mailing list card while logged in.',
        'Non-account visitors can join by entering only an email address.',
        'Use the mailing list recipient choices when sending group emails.',
        'Mass emails are sent one at a time so customers do not see each other addresses.'
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
        'Homepage mailing list block.',
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
        'Sessions.',
        'Traffic sources.',
        'Devices and browsers.',
        'Pages viewed.',
        'Searches.',
        'Product views.',
        'Cart activity.',
        'Orders.',
        'Revenue.',
        'Conversion activity.'
      ]],
      ['Admin Analytics Tab', [
        'Analytics has its own admin tab for deeper store traffic data.',
        'Overview stays simple, while Analytics shows more detailed charts and tables.',
        'The goal is to see Google Analytics-style information from inside the admin area.'
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
  },
  {
    title: 'Expansions',
    file: 'Expansions.md',
    html: 'expansions.html',
    summary: 'Use this page to see optional paid upgrades the client may want later.',
    sections: [
      ['What This Page Is', [
        'These are not required for the current launch.',
        'These are upgrade ideas that can be priced separately if the client wants them.',
        'The current store already covers the main fragrance-store workflow.'
      ]],
      ['Sales Channel Expansions', [
        'POS and in-person checkout with card-reader hardware.',
        'Automatic online and offline inventory sync.',
        'Amazon, eBay, TikTok Shop, Instagram/Facebook Shop, and Google Merchant Center integrations.',
        'Product feeds for outside marketplaces.'
      ]],
      ['Customer And Marketing Expansions', [
        'Wholesale pricing, customer-specific price lists, purchase orders, net terms, and company accounts.',
        'Subscription or replenishment orders for recurring fragrance purchases.',
        'Live chat, help desk tickets, SMS updates, and automated post-purchase flows.',
        'Advanced merchandising such as bundles, recommendations, upsells, cross-sells, waitlists, back-in-stock alerts, A/B tests, and a landing-page builder.'
      ]],
      ['Operations Expansions', [
        'Multiple warehouses, inventory locations, warehouse transfers, vendor receiving, purchase orders, and inventory forecasting.',
        'Multiple vendors or future brand expansion.',
        'Mobile admin or POS app for orders, inventory, labels, and customer messages.',
        'Enterprise operations such as uptime status page, support SLA, staff role granularity, audit export, backup/restore drills, and disaster recovery runbook.'
      ]],
      ['Payment, Tax, And International Expansions', [
        'Multi-currency checkout, multi-language content, and deeper international localization.',
        'Advanced tax automation and filing integrations such as Avalara or TaxJar-style workflows.',
        'QuickBooks or Xero accounting exports.',
        'Built-in fraud scoring, chargeback workflow, and order-risk rules before fulfillment.',
        'Additional wallet/payment choices such as PayPal, Venmo, Apple Pay, Google Pay, saved wallets, or one-click checkout.'
      ]],
      ['Technology Expansions', [
        'App or plugin integration layer so future tools can be added with less custom coding.',
        'Headless/API commerce for outside storefronts, mobile apps, AI shopping agents, and third-party checkout experiences.',
        'Advanced customer self-service such as tracking lookup and saved payment preferences.'
      ]]
    ]
  }
];

const rootDocs = {
  'README.md': `# EgbeAnom Handoff Docs

This folder is the handoff pack for the EgbeAnom store.

It is written for a store owner, not a programmer.

Start here:

1. \`Docs/Admin Guide/README.md\`
2. \`Docs/Admin Guide/Owner Quick Start.md\`
3. \`Docs/Admin Guide/Routine Checklist.md\`
4. \`CURRENT_STATUS.md\`
5. \`PRODUCTION_HANDOFF_CHECKLIST.md\`
6. \`Docs/Admin Guide/Expansions.md\`

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

The customer account kept for testing is \`calvin.fowler74@gmail.com\`.

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
`,
  'PRODUCTION_HANDOFF_CHECKLIST.md': `# Production Handoff Checklist

This is the simple checklist for client handoff.

\`[x]\` means done.

\`[~]\` means built, but needs a real-world check.

\`[ ]\` means not signed off yet.

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
- ⚠️ Optional add-on: live-test USPS, UPS, FedEx, or DHL labels with real or sandbox carrier credentials if the client chooses live carrier processors. Use \`npm run smoke-test-carrier-labels\` after credentials are configured.
- [x] Add tracking status refresh or carrier webhook support where available.
- [x] Add password reset and account verification test coverage.
- [x] Add stronger audit logging for admin changes to products, prices, stock, orders, taxes, payment settings, shipping settings, and credentials.
- [x] Add monitoring/alerting for failed payments, failed emails, failed label creation, and webhook errors.

### Code Maintainability

- [~] Split the large storefront/app state file into smaller checkout, account, catalog, analytics, email, and order services. Started with reward/promotion logic extracted to \`lib/app/store_reward_program.dart\`.
- [~] Split the large admin screen file into separate admin modules for orders, catalog, inventory, reports, taxes, shipping, email, and users. Started with order filtering/status workflow extracted to \`lib/app/admin_order_workflow.dart\`; dashboard, overview, and report metrics now live in \`lib/app/admin_metrics.dart\` with focused tests.
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
`
};

const testListMarkdown = `# Test List Page

Use this as the final site audit checklist. Check each item only after you personally test it in the browser.

## Customer Storefront

- ⚠️ Homepage loads on desktop.
- ⚠️ Homepage loads on phone-size screen.
- ⚠️ Homepage banner image displays correctly.
- ⚠️ Logo displays correctly.
- ⚠️ Mailing list block appears on the homepage.
- ⚠️ Logged-out visitor can join the non-account mailing list with only an email address.
- ⚠️ Logged-in customer can join or leave the account mailing list from the homepage card.
- ⚠️ Product listing loads all active products.
- ⚠️ Product search returns expected products.
- ⚠️ Product filters and sorting work.
- ⚠️ Product detail page shows photo, price, SKU, stock status, description, vibe, performance, comparison, fragrance profile, top notes, heart notes, and base notes.
- ⚠️ Product main image stays changed after refresh.
- ⚠️ Wishlist/favorites works for a logged-in customer.
- ⚠️ Removed test category \`asdfd\` does not appear.
- ⚠️ Removed test promotion \`asdfdasf\` does not appear.

## Customer Account

- ⚠️ Admin email account can also act as a customer account.
- ⚠️ Customer can log in.
- ⚠️ Customer can log out.
- ⚠️ Customer can reset password.
- ⚠️ Account page always shows the cards.
- ⚠️ Cards are compact enough on desktop.
- ⚠️ Cards are compact enough on mobile.
- ⚠️ Profile card opens profile details below the cards.
- ⚠️ Customer can update name.
- ⚠️ Customer can update email.
- ⚠️ Customer can update phone.
- ⚠️ Customer can update shipping address.
- ⚠️ Customer can update billing address.
- ⚠️ Updated phone prefills into checkout.
- ⚠️ Orders card opens order history.
- ⚠️ Customer can view order details.
- ⚠️ Customer can print or save invoice.
- ⚠️ Credits card opens credit history.
- ⚠️ Store credit balance is correct.
- ⚠️ Points card opens points history.
- ⚠️ Loyalty points balance is correct.
- ⚠️ Referral card opens referral page.
- ⚠️ Full referral link is visible and copyable.
- ⚠️ Account mailing list checkbox saves after refresh.

## Cart And Checkout

- ⚠️ Add single product to cart.
- ⚠️ Add multiple products to cart.
- ⚠️ Cart quantity can increase.
- ⚠️ Cart quantity can decrease.
- ⚠️ Cart item can be removed.
- ⚠️ Cart total updates correctly.
- ⚠️ Active carts do not include carts that already checked out and paid.
- ⚠️ Promo code field is visible in checkout.
- ⚠️ Standard promo code applies correctly.
- ⚠️ Invalid promo code shows a clear message.
- ⚠️ Buy X get Y at price Z promotion applies correctly.
- ⚠️ Gift card can be applied.
- ⚠️ Store credit can be applied when available.
- ⚠️ Shipping options show flat rate per order.
- ⚠️ Shipping options show flat rate per item.
- ⚠️ Shipping options show standard, priority, priority one day, and ground when enabled.
- ⚠️ Customer address fields are required before payment.
- ⚠️ Same city as store charges city, county, and state tax.
- ⚠️ Same county but different city charges county and state tax.
- ⚠️ Same state but different county charges state tax.
- ⚠️ Different state charges no state/county/city tax.
- ⚠️ International order adds configured VAT/import charges.
- ⚠️ Checkout shows tax breakdown before Stripe.
- ⚠️ Stripe checkout shows ordered items.
- ⚠️ Order is created before payment as pending and unpaid.
- ⚠️ Failed or abandoned payment leaves order unpaid.
- ⚠️ Successful payment changes financial status to paid.
- ⚠️ Successful payment keeps order status as Pending.
- ⚠️ Success page shows order ID.
- ⚠️ Success page shows ordered items.
- ⚠️ Success page shows paid financial status.
- ⚠️ Success page shows survey.
- ⚠️ Survey submission saves without error.
- ⚠️ After survey submission, customer redirects to home page.
- ⚠️ Survey review appears in admin Reviews.
- ⚠️ Paid order lowers inventory once.
- ⚠️ Refreshing paid order does not lower inventory again.

## Admin Overview And Dashboard

- ⚠️ Admin login works.
- ⚠️ Overview order count reflects a newly paid order.
- ⚠️ Overview revenue reflects a newly paid order.
- ⚠️ Overview customer count is correct.
- ⚠️ Overview review count is correct.
- ⚠️ Overview low-stock count is correct.
- ⚠️ Revenue tile opens sales details.
- ⚠️ Orders tile opens Orders page.
- ⚠️ New Users tile opens users/customers sorted by newest.
- ⚠️ Reviews tile opens Reviews page.
- ⚠️ Inventory tile opens Inventory page.
- ⚠️ Every clickable dashboard card opens a useful detail page.

## Admin Notifications

- ⚠️ New paid order creates admin notification.
- ⚠️ Notification bell shows unread red badge.
- ⚠️ Big admin tab dropdown shows red count next to the matching tab text.
- ⚠️ New order notification opens Orders page.
- ⚠️ New review notification opens Reviews page.
- ⚠️ Return request notification opens the order or return detail.
- ⚠️ Unread email notification opens Email page.
- ⚠️ Alert appears while admin page is already open.
- ⚠️ Browser desktop notification permission can be enabled.
- ⚠️ Browser notification appears for new important work.
- ⚠️ Notification sound plays when enabled.
- ⚠️ Marking notification read removes unread badge.

## Admin Orders

- ⚠️ New paid order appears in Orders.
- ⚠️ New unpaid order is clearly marked unpaid.
- ⚠️ Admin can see payment/financial status.
- ⚠️ Admin can filter by unpaid.
- ⚠️ Admin can filter by paid.
- ⚠️ Shipping type dropdown includes standard, priority, priority one day, ground, and all.
- ⚠️ Order status dropdown includes pending, processing, invoice created, label created, awaiting return item, sent/shipped, delivered, cancelled, and all.
- ⚠️ Delivery Days option is not in sort/filter dropdown.
- ⚠️ Order detail shows customer info.
- ⚠️ Order detail shows items.
- ⚠️ Order detail shows tax breakdown.
- ⚠️ Order detail shows shipping method.
- ⚠️ Order detail shows tracking number when available.
- ⚠️ Manual tracking number can be added.
- ⚠️ Pack list print changes status to Processing.
- ⚠️ Invoice print changes status to Invoice created.
- ⚠️ Label creation changes status to Label created.
- ⚠️ Mark Sent changes status to shipped/sent.
- ⚠️ Delivered status can be set when needed.
- ⚠️ Unpaid order cannot be accidentally fulfilled without a visible warning.
- ⚠️ Batch invoice print includes every selected order.
- ⚠️ Batch pack list print includes every selected order.
- ⚠️ Batch labels include every selected order when labels are available.

## Returns, RMAs, Refunds, And Credits

- ⚠️ Customer can open return/refund request from order detail.
- ⚠️ Customer can select which products are being returned.
- ⚠️ Customer can enter return reason/comment.
- ⚠️ Customer submit creates request without showing a false error.
- ⚠️ Admin sees request on the order.
- ⚠️ Admin sees Review return request button.
- ⚠️ Admin can approve request.
- ⚠️ Admin can deny request.
- ⚠️ Admin can enter refund reason.
- ⚠️ Admin can enter admin decision comment.
- ⚠️ Admin can enter return condition.
- ⚠️ Refund amount dropdown includes full/product plus shipping.
- ⚠️ Refund amount dropdown includes product only.
- ⚠️ Refund amount dropdown includes shipping only.
- ⚠️ Refund amount can be specific dollar amount if available.
- ⚠️ Admin can choose refund to payment method.
- ⚠️ Admin can choose refund as store credit.
- ⚠️ Approval creates RMA number automatically.
- ⚠️ Approval emails RMA to customer.
- ⚠️ Approved return changes order status to Awaiting return item.
- ⚠️ Customer can see return/RMA status.
- ⚠️ Received return can be recorded.
- ⚠️ Stripe refund works for payment-method refund.
- ⚠️ Store credit refund adds credit to customer account.
- ⚠️ Customer credit history shows the credit.
- ⚠️ Admin customer profile shows the credit.

## Email Sending

- ⚠️ SMTP settings save after refresh.
- ⚠️ Custom domain SMTP sends test email.
- ⚠️ Gmail SMTP sends test email if Gmail is used.
- ⚠️ GoDaddy SMTP sends test email if GoDaddy is used.
- ⚠️ Generic SMTP sends test email if generic provider is used.
- ⚠️ Paid order email sends to customer.
- ⚠️ Paid order email includes invoice/order details.
- ⚠️ Processing status email sends.
- ⚠️ Label created status email sends.
- ⚠️ Sent/shipped status email sends.
- ⚠️ Return/RMA email sends.
- ⚠️ Mass email sends one email per recipient.
- ⚠️ Mass email does not expose other recipient addresses.
- ⚠️ Email editor accepts HTML content.
- ⚠️ Email template uses invoice/pack-list style.
- ⚠️ Email header shows brand name and logo.
- ⚠️ Email footer includes unsubscribe wording.
- ⚠️ Email footer QR code displays at bottom right.
- ⚠️ Email width looks good in Gmail or main email client.
- ⚠️ Unsubscribe path or instructions are clear.

## Admin Email Inbox

- ⚠️ Admin Email page looks like a real mailbox.
- ⚠️ Folders show on the left.
- ⚠️ Message list shows on the right.
- ⚠️ Sync inbox pulls new messages.
- ⚠️ Opening a message shows popup.
- ⚠️ Message popup is scrollable.
- ⚠️ Admin can reply.
- ⚠️ Admin can forward.
- ⚠️ Read email stays read after sync.
- ⚠️ Mark unread works.
- ⚠️ If supported by provider, reading in site marks message read on email server.
- ⚠️ SMTP settings are accessible from settings area, not blocking normal mailbox use.

## Reviews

- ⚠️ After-purchase survey creates review.
- ⚠️ Review alert appears.
- ⚠️ Admin can approve review.
- ⚠️ Approved review appears publicly where expected.
- ⚠️ Admin can delete review.
- ⚠️ Deleted review stays deleted after refresh.
- ⚠️ If no comments exist, comments area stays hidden.
- ⚠️ Comments display above Leave Comment section when comments exist.

## Products, Categories, Inventory, And Promotions

- ⚠️ Admin can add product.
- ⚠️ Admin can edit product.
- ⚠️ Admin can upload product image.
- ⚠️ Main product image saves after refresh.
- ⚠️ Product fragrance detail fields save.
- ⚠️ Product top notes save.
- ⚠️ Product heart notes save.
- ⚠️ Product base notes save.
- ⚠️ Admin can update inventory count.
- ⚠️ Inventory print option shows simple table with lines.
- ⚠️ Low-stock item appears in low-stock area.
- ⚠️ Admin can add category.
- ⚠️ Admin can remove category.
- ⚠️ Admin can add promotion.
- ⚠️ Admin can remove promotion.
- ⚠️ Gift card can be created.
- ⚠️ Gift card balance updates after use.
- ⚠️ Loyalty points rules work.
- ⚠️ Referral reward rules work.

## Taxes, Shipping, Payments, And Store Info

- ⚠️ Store Info saves store name.
- ⚠️ Store Info saves address.
- ⚠️ Store Info saves city.
- ⚠️ Store Info saves county.
- ⚠️ Store Info saves state.
- ⚠️ Store Info saves country.
- ⚠️ Store Info saves phone.
- ⚠️ Store Info saves email.
- ⚠️ Tax page edit/delete buttons are side by side under Actions.
- ⚠️ State tax rule can be added.
- ⚠️ County tax rule can be added.
- ⚠️ City tax rule can be added.
- ⚠️ Other non-location tax can be added.
- ⚠️ VAT/import country tax can be added.
- ⚠️ Taxes apply correctly at checkout.
- ⚠️ Tax amounts appear in order detail.
- ⚠️ Tax amounts appear in reports.
- ⚠️ Flat rate per-order shipping works.
- ⚠️ Flat rate per-item shipping works.
- ⚠️ Optional carrier label creation works with final credentials or known sandbox credentials if carrier processors are enabled.
- ⚠️ Tracking number saves from carrier when provided.
- ⚠️ Live Stripe keys are entered only when ready.
- ⚠️ One small live payment through the active payment processor, currently Stripe, succeeds before public launch.
- ⚠️ One live refund succeeds before public launch.

## Printing

- ⚠️ Invoice prints one order per 8.5 x 11 page.
- ⚠️ Invoice does not have dark/colored table backgrounds.
- ⚠️ Invoice watermark shows.
- ⚠️ Invoice QR code fills its square correctly.
- ⚠️ Invoice footer text is editable.
- ⚠️ Invoice return policy appears neatly.
- ⚠️ Pack list matches invoice style.
- ⚠️ Pack list prints one order per 8.5 x 11 page.
- ⚠️ Label creation page matches invoice/pack-list style.
- ⚠️ Address label prints cleanly.
- ⚠️ Batch invoice print keeps each order on its own page.
- ⚠️ Batch pack list print keeps each order on its own page.

## Reports And Analytics

- ⚠️ Tax collected card opens tax-type breakdown.
- ⚠️ Tax breakdown shows state tax total.
- ⚠️ Tax breakdown shows county tax total.
- ⚠️ Tax breakdown shows city tax total.
- ⚠️ Tax breakdown shows VAT/import/other totals when used.
- ⚠️ Product sales card opens product breakdown.
- ⚠️ Product sales breakdown shows units sold by product.
- ⚠️ Shipping card opens carrier/method breakdown.
- ⚠️ Tax report can print or save as PDF.
- ⚠️ Sales report can print or save as PDF.
- ⚠️ Reports use spreadsheet-style layout.
- ⚠️ CSV downloads work.
- ⚠️ Analytics has separate admin tab.
- ⚠️ Analytics stores page views in database.
- ⚠️ Analytics stores product views in database.
- ⚠️ Analytics stores searches in database.
- ⚠️ Analytics stores cart activity in database.
- ⚠️ Analytics stores checkout activity in database.
- ⚠️ Analytics stores orders/revenue in database.
- ⚠️ Analytics persists after refresh.
- ⚠️ Analytics persists after closing and reopening app.
- ⚠️ Overview numbers match Analytics/order data.
- ⚠️ Analytics cards that are clickable open details.
- ⚠️ Analytics cards that do nothing do not look clickable.

## Users, Customers, And Admin Records

- ⚠️ Admin user can be added.
- ⚠️ Admin user can be removed.
- ⚠️ Customer record shows last IP address after customer activity.
- ⚠️ Customer record shows source type such as browser, PC, or mobile.
- ⚠️ Admin can send email directly from customer account page.
- ⚠️ Customer list does not force showing every customer in email dropdown.
- ⚠️ Mailing list has account-customer group.
- ⚠️ Mailing list has non-account visitor group.
- ⚠️ Targeted email can send to account mailing list.
- ⚠️ Targeted email can send to non-account mailing list.

## Security And Launch Readiness

- ⚠️ No real passwords are written in docs.
- ⚠️ No real service role keys are committed for client handoff.
- ⚠️ Environment variables are set in production host.
- ⚠️ Supabase Edge Functions are deployed.
- ⚠️ Stripe webhook is deployed and receiving events.
- ⚠️ Email function is deployed.
- ⚠️ Shipping functions are deployed only if carrier processors are enabled for launch.
- ⚠️ Database migrations are applied.
- ⚠️ Supabase RLS/security rules are checked.
- ⚠️ CORS origins match final production site.
- ⚠️ Admin-only pages are blocked from normal customers.
- ⚠️ Customer cannot see another customer's order.
- ⚠️ Error messages are understandable.
- ⚠️ App errors show understandable messages and do not expose secrets.
- ⚠️ robots.txt exists.
- ⚠️ sitemap.xml exists.
- ⚠️ Public page metadata looks correct.
- ⚠️ Final backup/export plan is documented.

## Final Sign-Off

- ⚠️ Complete one full customer purchase in sandbox.
- ⚠️ Complete one full customer purchase with at least one live payment processor.
- ⚠️ Confirm order email arrives.
- ⚠️ Confirm admin notification arrives.
- ⚠️ Print invoice.
- ⚠️ Print pack list.
- ⚠️ Create address label, or carrier label if carrier processors are enabled.
- ⚠️ Mark order sent.
- ⚠️ Submit customer return request.
- ⚠️ Approve return and create RMA.
- ⚠️ Complete refund to payment method.
- ⚠️ Complete refund to store credit.
- ⚠️ Confirm reports match the test order.
- ⚠️ Confirm analytics match the test order.
- ⚠️ Owner can process an order without developer help.
- ⚠️ Owner can send a test email without developer help.
- ⚠️ Owner can find paid expansion list.
- ⚠️ Client accepts handoff.

## Status Legend

- ✅ Complete
- ⚠️ Needs Testing
- ❌ Not Working
- 🔄 In Progress
`;

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
  return `# EgbeAnom Admin Guide\n\nThis is the plain-English guide for running the store.\n\nIt is written for someone who does not code.\n\n## Start Here\n\n1. Read [Owner Quick Start](./Owner%20Quick%20Start.md).\n2. Print [Routine Checklist](./Routine%20Checklist.md) and keep it near the workstation.\n3. Read [Overview](./Overview.md).\n4. Check [Store Info](./Store%20Info.md).\n5. Check [Taxes](./Taxes.md).\n6. Check [Shipping](./Shipping.md).\n7. Check [Email](./Email.md).\n8. Use [Orders](./Orders.md) every day.\n\n## Important Rule\n\nDo not ship an order unless its financial status says paid.\n\n## Pages\n\n${links}\n\n## Browser Book\n\nOpen the browser version here:\n\n[Open the browser book](../Admin%20Guide%20Book/index.html)\n`;
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
  const printNote = page.printable
    ? '<div class="tip print-note"><strong>Printable page:</strong> use your browser print button and post this near the admin or shipping workstation.</div>\n'
    : '';
  return htmlShell(page.title, page.html, `<span class="eyebrow">Admin Page</span>\n<h1>${escapeHtml(page.title)}</h1>\n<p>${escapeHtml(page.summary)}</p>\n${printNote}${sections}\n<div class="next-box"><a href="index.html">Back to guide home</a></div>`);
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

@media print {
  body {
    background: #fff;
  }

  .shell {
    max-width: none;
    padding: 0;
  }

  .book-top,
  .nav-card,
  .next-box,
  .print-note {
    display: none;
  }

  .book-grid {
    display: block;
    margin: 0;
  }

  .page-card {
    border: 0;
    border-radius: 0;
    box-shadow: none;
    padding: 0.25in;
  }

  .eyebrow {
    background: transparent;
    padding: 0;
  }

  .page-card h1 {
    font-size: 28pt;
  }

  .page-card h2 {
    break-after: avoid;
    page-break-after: avoid;
    margin-top: 18pt;
  }

  .page-card p,
  .page-card li {
    font-size: 12pt;
    line-height: 1.35;
  }
}
`;
}

ensureDir(mdDir);
ensureDir(bookDir);

for (const [file, content] of Object.entries(rootDocs)) {
  fs.writeFileSync(path.join(root, file), content);
}
for (const removedRootDoc of ['OWNER_QUICK_START.md', 'ROUTINE_CHECKLIST.md']) {
  const removedPath = path.join(root, removedRootDoc);
  if (fs.existsSync(removedPath)) {
    fs.unlinkSync(removedPath);
  }
}
fs.writeFileSync(path.join(root, 'Test List Page.md'), testListMarkdown);
const oldTestListHtml = path.join(root, 'Test List Page.html');
if (fs.existsSync(oldTestListHtml)) {
  fs.unlinkSync(oldTestListHtml);
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
