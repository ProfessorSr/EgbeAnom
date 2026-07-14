# Inventory

Use this to watch stock counts and print a simple stock table.

## How Stock Changes

- When an order is paid, inventory goes down one time.
- Unpaid orders should not lower inventory yet.
- The system remembers if stock was already lowered for an order so a refresh should not subtract it twice.

## What To Check

- Look for low-stock items.
- Fix stock counts if a physical count does not match the screen.
- Use the print option when you want a simple table with lines, like what is shown on the screen.

## If Stock Looks Wrong

- Check whether the order was paid.
- Check whether the product version has its own stock count.
- Ask a technical helper if paid orders are not lowering stock.

[Back to Admin Guide Home](./README.md)
