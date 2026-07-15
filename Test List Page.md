# Test List Page

Use this as the final site audit checklist. Check each item only after you personally test it in the browser.

## Customer Storefront

- 🟢 ✅ Homepage loads on desktop.
- 🟢 ✅ Homepage loads on phone-size screen.
- 🟢 ✅ Homepage banner image displays correctly.
- 🟢 ✅ Logo displays correctly.
- 🟢 ✅ Mailing list block appears on the homepage.
- 🟢 ✅ Logged-out visitor can join the non-account mailing list with only an email address.
- 🟢 ✅ Logged-in customer can join or leave the account mailing list from the homepage card.
- 🟢 ✅ Product listing loads all active products.
- 🟢 ✅ Product search returns expected products.
- 🟢 ✅ Product filters and sorting work.
- 🟢 ✅ Product detail page shows photo, price, SKU, stock status, description, vibe, performance, comparison, fragrance profile, top notes, heart notes, and base notes.
- 🟢 ✅ Product main image stays changed after refresh.
- 🟢 ✅ Wishlist/favorites works for a logged-in customer.
- 🟢 ✅ Removed test category `asdfd` does not appear.
- 🟢 ✅ Removed test promotion `asdfdasf` does not appear.

## Customer Account

- 🟢 ✅ Admin email account can also act as a customer account.
- 🟢 ✅ Customer can log in.
- 🟢 ✅ Customer can log out.
- [ ] ⚠️ Customer can reset password.
- 🟢 ✅ Account page always shows the cards.
- 🟢 ✅ Cards are compact enough on desktop.
- 🟢 ✅ Cards are compact enough on mobile.
- 🟢 ✅ Profile card opens profile details below the cards.
- 🟢 ✅ Customer can update name.
- 🟢 ✅ Customer can update email.
- 🟢 ✅ Customer can update phone.
- 🟢 ✅ Customer can update shipping address.
- 🟢 ✅ Customer can update billing address.
- 🟢 ✅ Updated phone prefills into checkout.
- 🟢 ✅ Orders card opens order history.
- 🟢 ✅ Customer can view order details.
- 🟢 ✅ Customer can print or save invoice.
- 🟢 ✅ Credits card opens credit history.
- 🟢 ✅ Store credit balance is correct.
- 🟢 ✅ Points card opens points history.
- 🟢 ✅ Loyalty points balance is correct.
- 🟢 ✅ Referral card opens referral page.
- 🟢 ✅ Full referral link is visible and copyable.
- 🟢 ✅ Account mailing list checkbox saves after refresh.

## Cart And Checkout

- 🟢 ✅ Add single product to cart.
- 🟢 ✅ Add multiple products to cart.
- 🟢 ✅ Cart quantity can increase.
- 🟢 ✅ Cart quantity can decrease.
- 🟢 ✅ Cart item can be removed.
- 🟢 ✅ Cart total updates correctly.
- [ ] ⚠️ Active carts do not include carts that already checked out and paid.
- 🟢 ✅ Promo code field is visible in checkout.
- [ ] ⚠️ Standard promo code applies correctly.
- [ ] ⚠️ Invalid promo code shows a clear message.
- [ ] ⚠️ Buy X get Y at price Z promotion applies correctly.
- [ ] ⚠️ Gift card can be applied.
- [ ] ⚠️ Store credit can be applied when available.
- [ ] ⚠️ Shipping options show flat rate per order.
- [ ] ⚠️ Shipping options show flat rate per item.
- [ ] ⚠️ Shipping options show standard, priority, priority one day, and ground when enabled.
- [ ] ⚠️ Customer address fields are required before payment.
- [ ] ⚠️ Same city as store charges city, county, and state tax.
- [ ] ⚠️ Same county but different city charges county and state tax.
- [ ] ⚠️ Same state but different county charges state tax.
- [ ] ⚠️ Different state charges no state/county/city tax.
- [ ] ⚠️ International order adds configured VAT/import charges.
- [ ] ⚠️ Checkout shows tax breakdown before Stripe.
- [ ] ⚠️ Stripe checkout shows ordered items.
- [ ] ⚠️ Order is created before payment as pending and unpaid.
- [ ] ⚠️ Failed or abandoned payment leaves order unpaid.
- [ ] ⚠️ Successful payment changes financial status to paid.
- [ ] ⚠️ Successful payment keeps order status as Pending.
- [ ] ⚠️ Success page shows order ID.
- [ ] ⚠️ Success page shows ordered items.
- [ ] ⚠️ Success page shows paid financial status.
- [ ] ⚠️ Success page shows survey.
- [ ] ⚠️ Survey submission saves without error.
- [ ] ⚠️ After survey submission, customer redirects to home page.
- [ ] ⚠️ Survey review appears in admin Reviews.
- 🟢 ✅ Paid order lowers inventory once.
- [ ] ⚠️ Refreshing paid order does not lower inventory again.

## Admin Overview And Dashboard

- 🟢 ✅ Admin login works.
- 🟢 ✅ Overview order count reflects a newly paid order.
- 🟢 ✅ Overview revenue reflects a newly paid order.
- [ ] ⚠️ Overview customer count is correct.
- [ ] ⚠️ Overview review count is correct.
- 🟢 ✅ Overview low-stock count is correct.
- 🟢 ✅ Revenue tile opens sales details.
- 🟢 ✅ Orders tile opens Orders page.
- 🟢 ✅ New Users tile opens users/customers sorted by newest.
- [ ] ⚠️ Reviews tile opens Reviews page.
- [ ] ⚠️ Inventory tile opens Inventory page.
- [ ] ⚠️ Every clickable dashboard card opens a useful detail page.

## Admin Notifications

- [ ] ⚠️ New paid order creates admin notification.
- [ ] ⚠️ Notification bell shows unread red badge.
- [ ] ⚠️ Big admin tab dropdown shows red count next to the matching tab text.
- [ ] ⚠️ New order notification opens Orders page.
- [ ] ⚠️ New review notification opens Reviews page.
- [ ] ⚠️ Return request notification opens the order or return detail.
- [ ] ⚠️ Unread email notification opens Email page.
- [ ] ⚠️ Alert appears while admin page is already open.
- [ ] ⚠️ Browser desktop notification permission can be enabled.
- [ ] ⚠️ Browser notification appears for new important work.
- [ ] ⚠️ Notification sound plays when enabled.
- [ ] ⚠️ Marking notification read removes unread badge.

## Admin Orders

- 🟢 ✅ New paid order appears in Orders.
- [ ] ⚠️ New unpaid order is clearly marked unpaid.
- [ ] ⚠️ Admin can see payment/financial status.
- 🟢 ✅ Admin can filter by unpaid.
- 🟢 ✅ Admin can filter by paid.
- 🟢 ✅ Shipping type dropdown includes standard, priority, priority one day, ground, and all.
- 🟢 ✅ Order status dropdown includes pending, processing, invoice created, label created, awaiting return item, sent/shipped, delivered, cancelled, and all.
- 🟢 ✅ Delivery Days option is not in sort/filter dropdown.
- [ ] ⚠️ Order detail shows customer info.
- 🟢 ✅ Order detail shows items.
- [ ] ⚠️ Order detail shows tax breakdown.
- [ ] ⚠️ Order detail shows shipping method.
- 🟢 ✅ Order detail shows tracking number when available.
- 🟢 ✅ Manual tracking number can be added.
- 🟢 ✅ Pack list print changes status to Processing.
- 🟢 ✅ Invoice print changes status to Invoice created.
- 🟢 ✅ Label creation changes status to Label created.
- 🟢 ✅ Mark Sent changes status to shipped/sent.
- 🟢 ✅ Delivered status can be set when needed.
- [ ] ⚠️ Unpaid order cannot be accidentally fulfilled without a visible warning.
- 🟢 ✅ Batch invoice print includes every selected order.
- 🟢 ✅ Batch pack list print includes every selected order.
- [ ] ⚠️ Batch labels include every selected order when labels are available.

## Returns, RMAs, Refunds, And Credits

- [ ] ⚠️ Customer can open return/refund request from order detail.
- [ ] ⚠️ Customer can select which products are being returned.
- [ ] ⚠️ Customer can enter return reason/comment.
- [ ] ⚠️ Customer submit creates request without showing a false error.
- [ ] ⚠️ Admin sees request on the order.
- [ ] ⚠️ Admin sees Review return request button.
- [ ] ⚠️ Admin can approve request.
- [ ] ⚠️ Admin can deny request.
- [ ] ⚠️ Admin can enter refund reason.
- [ ] ⚠️ Admin can enter admin decision comment.
- [ ] ⚠️ Admin can enter return condition.
- [ ] ⚠️ Refund amount dropdown includes full/product plus shipping.
- [ ] ⚠️ Refund amount dropdown includes product only.
- [ ] ⚠️ Refund amount dropdown includes shipping only.
- [ ] ⚠️ Refund amount can be specific dollar amount if available.
- [ ] ⚠️ Admin can choose refund to payment method.
- [ ] ⚠️ Admin can choose refund as store credit.
- [ ] ⚠️ Approval creates RMA number automatically.
- [ ] ⚠️ Approval emails RMA to customer.
- [ ] ⚠️ Approved return changes order status to Awaiting return item.
- [ ] ⚠️ Customer can see return/RMA status.
- [ ] ⚠️ Received return can be recorded.
- [ ] ⚠️ Stripe refund works for payment-method refund.
- [ ] ⚠️ Store credit refund adds credit to customer account.
- [ ] ⚠️ Customer credit history shows the credit.
- [ ] ⚠️ Admin customer profile shows the credit.

## Email Sending

- 🟢 ✅ SMTP settings save after refresh.
- [ ] ⚠️ Custom domain SMTP sends test email.
- 🟢 ✅ Gmail SMTP sends test email if Gmail is used.
- 🟢 ✅ GoDaddy SMTP sends test email if GoDaddy is used.
- [ ] ⚠️ Generic SMTP sends test email if generic provider is used.
- [ ] ⚠️ Paid order email sends to customer.
- [ ] ⚠️ Paid order email includes invoice/order details.
- 🟢 ✅ Processing status email sends.
- 🟢 ✅ Label created status email sends.
- 🟢 ✅ Sent/shipped status email sends.
- [ ] ⚠️ Return/RMA email sends.
- [ ] ⚠️ Mass email sends one email per recipient.
- 🟢 ✅ Mass email does not expose other recipient addresses.
- [ ] ⚠️ Email editor accepts HTML content.
- 🟢 ✅ Email template uses invoice/pack-list style.
- [ ] ⚠️ Email header shows brand name and logo.
- 🟢 ✅ Email footer includes unsubscribe wording.
- 🟢 ✅ Email footer QR code displays at bottom right.
- [ ] ⚠️ Email width looks good in Gmail or main email client.
- [ ] ⚠️ Unsubscribe path or instructions are clear.

## Admin Email Inbox

- [ ] ⚠️ Admin Email page looks like a real mailbox.
- [ ] ⚠️ Folders show on the left.
- [ ] ⚠️ Message list shows on the right.
- [ ] ⚠️ Sync inbox pulls new messages.
- [ ] ⚠️ Opening a message shows popup.
- [ ] ⚠️ Message popup is scrollable.
- [ ] ⚠️ Admin can reply.
- [ ] ⚠️ Admin can forward.
- [ ] ⚠️ Read email stays read after sync.
- [ ] ⚠️ Mark unread works.
- [ ] ⚠️ If supported by provider, reading in site marks message read on email server.
- [ ] ⚠️ SMTP settings are accessible from settings area, not blocking normal mailbox use.

## Reviews

- [ ] ⚠️ After-purchase survey creates review.
- [ ] ⚠️ Review alert appears.
- [ ] ⚠️ Admin can approve review.
- [ ] ⚠️ Approved review appears publicly where expected.
- [ ] ⚠️ Admin can delete review.
- [ ] ⚠️ Deleted review stays deleted after refresh.
- [ ] ⚠️ If no comments exist, comments area stays hidden.
- [ ] ⚠️ Comments display above Leave Comment section when comments exist.

## Products, Categories, Inventory, And Promotions

- [ ] ⚠️ Admin can add product.
- [ ] ⚠️ Admin can edit product.
- [ ] ⚠️ Admin can upload product image.
- [ ] ⚠️ Main product image saves after refresh.
- [ ] ⚠️ Product fragrance detail fields save.
- [ ] ⚠️ Product top notes save.
- [ ] ⚠️ Product heart notes save.
- [ ] ⚠️ Product base notes save.
- [ ] ⚠️ Admin can update inventory count.
- [ ] ⚠️ Inventory print option shows simple table with lines.
- [ ] ⚠️ Low-stock item appears in low-stock area.
- [ ] ⚠️ Admin can add category.
- [ ] ⚠️ Admin can remove category.
- [ ] ⚠️ Admin can add promotion.
- [ ] ⚠️ Admin can remove promotion.
- [ ] ⚠️ Gift card can be created.
- [ ] ⚠️ Gift card balance updates after use.
- [ ] ⚠️ Loyalty points rules work.
- [ ] ⚠️ Referral reward rules work.

## Taxes, Shipping, Payments, And Store Info

- [ ] ⚠️ Store Info saves store name.
- [ ] ⚠️ Store Info saves address.
- [ ] ⚠️ Store Info saves city.
- [ ] ⚠️ Store Info saves county.
- [ ] ⚠️ Store Info saves state.
- [ ] ⚠️ Store Info saves country.
- [ ] ⚠️ Store Info saves phone.
- [ ] ⚠️ Store Info saves email.
- [ ] ⚠️ Tax page edit/delete buttons are side by side under Actions.
- [ ] ⚠️ State tax rule can be added.
- [ ] ⚠️ County tax rule can be added.
- [ ] ⚠️ City tax rule can be added.
- [ ] ⚠️ Other non-location tax can be added.
- [ ] ⚠️ VAT/import country tax can be added.
- [ ] ⚠️ Taxes apply correctly at checkout.
- [ ] ⚠️ Tax amounts appear in order detail.
- [ ] ⚠️ Tax amounts appear in reports.
- [ ] ⚠️ Flat rate per-order shipping works.
- [ ] ⚠️ Flat rate per-item shipping works.
- [ ] ⚠️ Optional carrier label creation works with final credentials or known sandbox credentials if carrier processors are enabled.
- [ ] ⚠️ Tracking number saves from carrier when provided.
- [ ] ⚠️ Live Stripe keys are entered only when ready.
- [ ] ⚠️ One small live payment through the active payment processor, currently Stripe, succeeds before public launch.
- [ ] ⚠️ One live refund succeeds before public launch.

## Printing

- [ ] ⚠️ Invoice prints one order per 8.5 x 11 page.
- [ ] ⚠️ Invoice does not have dark/colored table backgrounds.
- [ ] ⚠️ Invoice watermark shows.
- [ ] ⚠️ Invoice QR code fills its square correctly.
- [ ] ⚠️ Invoice footer text is editable.
- [ ] ⚠️ Invoice return policy appears neatly.
- [ ] ⚠️ Pack list matches invoice style.
- [ ] ⚠️ Pack list prints one order per 8.5 x 11 page.
- [ ] ⚠️ Label creation page matches invoice/pack-list style.
- [ ] ⚠️ Address label prints cleanly.
- [ ] ⚠️ Batch invoice print keeps each order on its own page.
- [ ] ⚠️ Batch pack list print keeps each order on its own page.

## Reports And Analytics

- [ ] ⚠️ Tax collected card opens tax-type breakdown.
- [ ] ⚠️ Tax breakdown shows state tax total.
- [ ] ⚠️ Tax breakdown shows county tax total.
- [ ] ⚠️ Tax breakdown shows city tax total.
- [ ] ⚠️ Tax breakdown shows VAT/import/other totals when used.
- [ ] ⚠️ Product sales card opens product breakdown.
- [ ] ⚠️ Product sales breakdown shows units sold by product.
- [ ] ⚠️ Shipping card opens carrier/method breakdown.
- [ ] ⚠️ Tax report can print or save as PDF.
- [ ] ⚠️ Sales report can print or save as PDF.
- [ ] ⚠️ Reports use spreadsheet-style layout.
- [ ] ⚠️ CSV downloads work.
- [ ] ⚠️ Analytics has separate admin tab.
- [ ] ⚠️ Analytics stores page views in database.
- [ ] ⚠️ Analytics stores product views in database.
- [ ] ⚠️ Analytics stores searches in database.
- [ ] ⚠️ Analytics stores cart activity in database.
- [ ] ⚠️ Analytics stores checkout activity in database.
- [ ] ⚠️ Analytics stores orders/revenue in database.
- [ ] ⚠️ Analytics persists after refresh.
- [ ] ⚠️ Analytics persists after closing and reopening app.
- [ ] ⚠️ Overview numbers match Analytics/order data.
- [ ] ⚠️ Analytics cards that are clickable open details.
- [ ] ⚠️ Analytics cards that do nothing do not look clickable.

## Users, Customers, And Admin Records

- [ ] ⚠️ Admin user can be added.
- [ ] ⚠️ Admin user can be removed.
- [ ] ⚠️ Customer record shows last IP address after customer activity.
- [ ] ⚠️ Customer record shows source type such as browser, PC, or mobile.
- [ ] ⚠️ Admin can send email directly from customer account page.
- [ ] ⚠️ Customer list does not force showing every customer in email dropdown.
- [ ] ⚠️ Mailing list has account-customer group.
- [ ] ⚠️ Mailing list has non-account visitor group.
- [ ] ⚠️ Targeted email can send to account mailing list.
- [ ] ⚠️ Targeted email can send to non-account mailing list.

## Security And Launch Readiness

- 🟢 ✅ No real passwords are written in docs.
- 🟢 ✅ No real service role keys are committed for client handoff.
- [ ] ⚠️ Environment variables are set in production host.
- [ ] ⚠️ Supabase Edge Functions are deployed.
- [ ] ⚠️ Stripe webhook is deployed and receiving events.
- [ ] ⚠️ Email function is deployed.
- [ ] ⚠️ Shipping functions are deployed only if carrier processors are enabled for launch.
- [ ] ⚠️ Database migrations are applied.
- [ ] ⚠️ Supabase RLS/security rules are checked.
- [ ] ⚠️ CORS origins match final production site.
- [ ] ⚠️ Admin-only pages are blocked from normal customers.
- [ ] ⚠️ Customer cannot see another customer's order.
- [ ] ⚠️ Error messages are understandable.
- [ ] ⚠️ App errors show understandable messages and do not expose secrets.
- 🟢 ✅ robots.txt exists.
- 🟢 ✅ sitemap.xml exists.
- [ ] ⚠️ Public page metadata looks correct.
- [ ] ⚠️ Final backup/export plan is documented.

## Final Sign-Off

- 🟢 ✅ Complete one full customer purchase in sandbox.
- [ ] ⚠️ Complete one full customer purchase with at least one live payment processor.
- [ ] ⚠️ Confirm order email arrives.
- [ ] ⚠️ Confirm admin notification arrives.
- 🟢 ✅ Print invoice.
- [ ] ⚠️ Print pack list.
- [ ] ⚠️ Create address label, or carrier label if carrier processors are enabled.
- 🟢 ✅ Mark order sent.

- [ ] ⚠️ Submit customer return request.
- [ ] ⚠️ Approve return and create RMA.
- [ ] ⚠️ Complete refund to payment method.
- [ ] ⚠️ Complete refund to store credit.
- [ ] ⚠️ Confirm reports match the test order.
- [ ] ⚠️ Confirm analytics match the test order.
- [ ] ⚠️ Owner can process an order without developer help.
- [ ] ⚠️ Owner can send a test email without developer help.
- [ ] ⚠️ Owner can find paid expansion list.
- [ ] ⚠️ Client accepts handoff.

## Live Chat Help

- [ ] ⚠️ Open live chat button appears when live chat is enabled.
- [ ] ⚠️ Customer can open the live chat panel.
- [ ] ⚠️ Customer can close the live chat panel.
- [ ] ⚠️ Logged-in customer name and email prefill in live chat.
- [ ] ⚠️ Guest can enter a name and valid email in live chat.
- [ ] ⚠️ Empty or invalid live chat submission shows a clear error.
- [ ] ⚠️ Sending a live chat message creates an admin customer-contact alert.
- [ ] ⚠️ Admin can turn live chat off from Site settings.
- [ ] ⚠️ Closed live chat stays hidden after refresh.
- [ ] ⚠️ Admin can turn live chat back on from Site settings.


## Status Legend

- 🟢 ✅ Complete
- ⚠️ Needs Testing
- ❌ Not Working
- 🔄 In Progress
