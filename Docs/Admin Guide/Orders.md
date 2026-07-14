# Orders

Use this every day to process orders.

## Payment And Fulfillment Status

- When a customer places an order, it is saved as pending and unpaid before Stripe payment finishes.
- After Stripe payment succeeds, financial status changes to paid.
- New paid orders should have order status Pending.

## Order Status Meanings

- Pending means the paid order is new and needs work.
- Processing means the pack list was printed and the order is being picked.
- Invoice created means the invoice was created or printed.
- Label created means the shipping label was created.
- Sent or Shipped means the package has been sent.
- Delivered means the customer received it.
- Cancelled means the order should not be fulfilled.
- Awaiting return item means a return was approved and the store is waiting for the item to come back.

## Normal Order Flow

- Print the pack list. The order becomes Processing.
- Create or print the invoice. The order becomes Invoice created.
- Create the shipping label. The order becomes Label created.
- When the package leaves, mark it Sent. The order becomes shipped.

## Filters

- Shipping type filter should show standard, priority, priority one day, ground, and all.
- Order status filter should show pending, processing, invoice created, label created, awaiting return item, sent, delivered, cancelled, and all.
- Financial status filter helps you avoid shipping unpaid orders.

## Returns And Refunds

- Customers can request a return or refund from their order page.
- The admin can approve or deny the request and add a reason and comment.
- If approved, the system creates an RMA and emails it to the customer.
- The order moves to Awaiting return item.
- After the item is received, the admin records the item condition and chooses the refund amount.
- Refund choices are product plus shipping, just product, just shipping, or a specific dollar amount.
- Approved refunds are sent through Stripe and saved back on the order.

## Batch Printing

- You can select many orders and print invoices, pack lists, or labels.
- Each invoice or pack list should print on its own 8.5 x 11 inch page.
- If only one prints during batch work, stop and ask a technical helper to check the browser print window and batch print page.

[Back to Admin Guide Home](./README.md)
