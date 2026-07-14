# What To Do For 100%

To get **Public Launch Readiness from about 92% to 100%**, the remaining work is mostly real-world verification, not new feature building.

## Must Do Before Launch

1. **Run one small live Stripe payment**
   - Switch Stripe from sandbox/test to live keys.
   - Buy one low-cost product for real.
   - Confirm:
     - order is created as unpaid before payment
     - payment changes it to paid
     - success page shows order details
     - survey appears
     - inventory decreases
     - admin order shows correctly

2. **Enter real SMTP settings and send a real inbox test**
   - Use the final Gmail, GoDaddy, or generic SMTP account.
   - Send a test email from admin.
   - Confirm customer emails arrive for:
     - paid order/invoice
     - processing
     - label created
     - sent/shipped

3. **Test real carrier label creation**
   - Enter final USPS/UPS/FedEx/DHL credentials, or whichever carriers the owner will use at launch.
   - Run one label test.
   - Confirm:
     - tracking number saves
     - label status changes
     - order can move through fulfillment
     - fallback address-label printing still works if carrier API fails

4. **Final tax review**
   - Confirm store address, city, county, and state.
   - Confirm actual tax rates with the owner, accountant, or tax professional.
   - Verify checkout tax breakdown matches the intended rules.

5. **Final product stock count**
   - Count real inventory.
   - Update product stock numbers before accepting live orders.

6. **Final browser workflow check**
   - Test batch invoice printing.
   - Test batch packing list printing.
   - Test cancel/failed payment paths.
   - Confirm reports match sample/trusted orders.

7. **Final owner walkthrough**
   - Walk the client through:
     - adding products/photos
     - checking orders
     - not shipping unpaid orders
     - printing invoices/pack lists/labels
     - refunds/returns
     - email settings
     - reports
     - tax/shipping settings

## Plain-English Summary

The app itself is close. To call it 100%, prove the live money, live email, live shipping, live taxes, and live inventory are all correct with the client's real accounts.
