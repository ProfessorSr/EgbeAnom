# What To Do For 100%

To get **Public Launch Readiness from about 92% to 100%**, the remaining work is mostly real-world verification, not new feature building.

The score is conservative on purpose. The core store is built, but public launch should wait until at least one live payment processor, final email/inbox, tax, and owner walkthrough checks are complete. Carrier shipping processors are optional add-ons unless the client chooses to buy shipping labels inside the site at launch.

## Must Do Before Launch

1. **Run one small live payment**
   - Switch the chosen payment processor from sandbox/test to live keys.
   - Buy one low-cost product for real.
   - Confirm:
     - order is created as unpaid before payment
     - payment changes it to paid
     - success page shows order details
     - survey appears
     - inventory decreases
     - admin order shows correctly

2. **Confirm final email after deployment**
   - Custom domain SMTP is working.
   - After deployment, send one more test email from admin.
   - Sync the admin Email inbox and confirm new messages appear.
   - Confirm customer emails arrive for:
     - paid order/invoice
     - processing
     - label created
     - sent/shipped
     - RMA/return approval

3. **Only if the client wants live carrier labels: test real carrier label creation**
   - Carrier processors are add-ons, not mandatory for production launch.
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

6. **Final banner and logo upload check**
   - Upload the final homepage banner.
   - Upload the final logo.
   - Refresh the site and confirm both still show.

7. **Final browser workflow check**
   - Test batch invoice printing.
   - Test batch packing list printing.
   - Test cancel/failed payment paths.
   - Test admin notification badges.
   - Test desktop browser alerts and sound on the client computer.
   - Test the customer account cards.
   - Test one customer return request and admin RMA approval.
   - Confirm reports match sample/trusted orders.

8. **Final owner walkthrough**
   - Walk the client through:
     - adding products/photos
     - checking orders
     - not shipping unpaid orders
     - printing invoices/pack lists/labels
     - refunds/returns
     - notifications
     - Email inbox
     - mailing lists
     - Analytics tab
     - email settings
     - reports
     - tax/shipping settings

## Plain-English Summary

The app itself is close. To call it 100%, prove the live money, final email/inbox, live taxes, live inventory, browser alerts, and owner workflow are all correct with the client's real accounts. Prove live carrier labels only if carrier processors are included in the launch scope.
