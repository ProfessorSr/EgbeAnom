# Payments

Use this to manage payment provider settings and check payment flow.

## Plain English Version

- Stripe sandbox checkout is working from cart to payment to admin order update.
- An order is first saved as pending and unpaid.
- After Stripe says payment succeeded, the order changes to paid and stays pending for fulfillment.
- Before public launch, do one small live payment with production Stripe keys.

## What Not To Ship

- Do not ship unpaid orders.
- Use the order financial status to confirm payment was received.
- If payment status is missing or unpaid, stop and check before sending product.

## After A Successful Payment

- The customer sees the payment received page.
- The customer sees order details.
- The customer can fill out the survey.
- The customer should receive an invoice or order email after SMTP email is tested.

[Back to Admin Guide Home](./README.md)
