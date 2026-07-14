# Owner Quick Start

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

1. `Store Info`
2. `Taxes`
3. `Shipping`
4. `Email`
5. `Payments`
6. `Catalog`
7. `Orders`
8. `Reports`

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

- Open `Overview`.
- Open `Orders`.
- Print pack lists for paid new orders.
- Print invoices if needed.
- Create labels.
- Mark sent packages as sent.
- Check `Inventory` for low stock.
- Check `Reviews`.
- Check `Reports` when you need numbers.

## Easy Rule

Do not ship an order unless the financial status says paid.
