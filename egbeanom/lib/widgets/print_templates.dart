part of '../main.dart';

String _storeAddress(StoreInfo storeInfo) {
  return [
    storeInfo.addressLine1,
    storeInfo.addressLine2,
    [
      storeInfo.city,
      storeInfo.state,
      storeInfo.postalCode,
    ].where((item) => item.trim().isNotEmpty).join(', '),
    storeInfo.country,
  ].where((item) => item.trim().isNotEmpty).join('<br>');
}

String _orderDate(Order order) {
  final value = order.createdAt ?? DateTime.now();
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$month/$day/${value.year}';
}

double _orderTaxTotal(Order order) {
  if (order.taxBreakdown.isNotEmpty) {
    return order.taxBreakdown.fold(0, (sum, line) => sum + line.amount);
  }
  final lineSubtotal = order.lines.fold<double>(
    0,
    (total, line) => total + line.total,
  );
  final subtotal = order.subtotal > 0 ? order.subtotal : lineSubtotal;
  return math.max(
    0,
    order.total -
        order.shippingTotal -
        math.max(0, subtotal - order.discountTotal),
  );
}

const String _siteQrImageUrl = 'assets/assets/images/egbeanom_qr_code.png';
const String _invoiceWatermarkImageUrl = 'assets/assets/images/bw_image.png';
const String _siteQrLabel = 'egbeanom.com';

String _siteQrImage() =>
    '<img src="$_siteQrImageUrl" alt="EgbeAnom website QR code">';

String _invoiceThankYouPlain(String? thankYouText) {
  final trimmed = thankYouText?.trim() ?? '';
  return trimmed.isEmpty ? 'Thank you for choosing EgbeAnom.' : trimmed;
}

String _invoiceThankYouHtml(String? thankYouText) {
  final message = _invoiceThankYouPlain(thankYouText);
  const lead = 'Thank you';
  if (message.toLowerCase().startsWith(lead.toLowerCase())) {
    final rest = message.substring(lead.length).trimLeft();
    return '<span class="script">$lead</span>${htmlEscape.convert(rest)}';
  }
  return htmlEscape.convert(message);
}

String _invoiceReturnPolicyHtml(String? returnPolicyText) {
  final policy = (returnPolicyText?.trim().isNotEmpty ?? false)
      ? returnPolicyText!.trim()
      : SiteStatus().returnPolicy;
  return htmlEscape.convert(policy).replaceAll('\n', '<br>');
}

@visibleForTesting
String buildAddressLabelHtmlForTest(
  Order order,
  String carrier,
  StoreInfo storeInfo,
) => _addressLabelHtml(order, carrier, storeInfo);

@visibleForTesting
String buildInvoiceHtmlForTest(
  Order order,
  StoreInfo storeInfo, {
  bool printLite = false,
  String? thankYouText,
  String? returnPolicyText,
}) => _invoiceHtml(
  order,
  storeInfo,
  printLite: printLite,
  thankYouText: thankYouText,
  returnPolicyText: returnPolicyText,
);

@visibleForTesting
String buildPackListHtmlForTest(Order order, StoreInfo storeInfo) =>
    _packListHtml(order, storeInfo);

String _addressLabelHtml(Order order, String carrier, StoreInfo storeInfo) {
  final address = order.shippingAddress;
  final recipient = [
    address.firstName,
    address.lastName,
  ].where((value) => value.trim().isNotEmpty).join(' ').trim();
  final toName = recipient.isEmpty ? order.customer : recipient;
  final lines = <String>[
    address.addressLine1,
    address.addressLine2,
    '${address.city}, ${address.state} ${address.postalCode}'.trim(),
    address.country,
  ].where((line) => line.trim().isNotEmpty).map(htmlEscape.convert).toList();

  final fromLines = <String>[
    storeInfo.displayName,
    storeInfo.addressLine1,
    storeInfo.addressLine2,
    '${storeInfo.city}, ${storeInfo.state} ${storeInfo.postalCode}'.trim(),
    storeInfo.country,
  ].where((line) => line.trim().isNotEmpty).map(htmlEscape.convert).toList();
  final storeName = htmlEscape.convert(storeInfo.displayName);
  final storeAddress = _storeAddress(storeInfo);

  return '''
<section class="egbeanom-print-page address-label-doc">
  <style>
    .address-label-doc { font-family: Georgia, 'Times New Roman', serif; color: #121212; box-sizing: border-box; width: 8.5in; height: 11in; border: 1px solid #b7892f; background: #fff; position: relative; overflow: hidden; }
    .label-watermark { position: absolute; inset: 0; display: grid; place-items: center; pointer-events: none; z-index: 0; }
    .label-watermark img { width: 68%; max-width: 620px; opacity: .1; filter: grayscale(1); }
    .label-head, .label-body, .label-footer { position: relative; z-index: 1; }
    .label-head { display: grid; grid-template-columns: 1fr 2.1in; gap: .32in; align-items: start; border-bottom: .03in solid #d3a13c; padding: .36in .46in .28in; }
    .label-brand h1 { margin: 0; font-size: 34pt; font-weight: 400; line-height: 1; }
    .label-brand p { margin: .08in 0 0; font: 11pt Arial, sans-serif; color: #333; }
    .label-meta { border-left: 1px solid #936e2a; padding-left: .22in; font: 9pt Arial, sans-serif; line-height: 1.45; }
    .label-meta strong { color: #b8842b; text-transform: uppercase; }
    .label-body { padding: .45in .55in .3in; }
    .from-box { border: 1px solid #d8bd80; padding: .16in; margin-bottom: .28in; font: 10pt Arial, sans-serif; line-height: 1.35; background: rgba(255,255,255,.86); }
    .label-title { color: #b8842b; text-transform: uppercase; letter-spacing: 1px; font-weight: 700; margin-bottom: .06in; }
    .ship-box { border: .03in solid #111; padding: .38in; min-height: 4.45in; display: flex; flex-direction: column; justify-content: center; background: rgba(255,255,255,.9); }
    .ship-to { color: #b8842b; text-transform: uppercase; letter-spacing: 1px; font: 700 11pt Arial, sans-serif; margin-bottom: .16in; }
    .ship-name { font: 700 30pt Arial, sans-serif; line-height: 1.12; margin-bottom: .2in; }
    .ship-address { font: 22pt Arial, sans-serif; line-height: 1.25; }
    .label-footer { border-top: 1px solid #d8bd80; padding: .18in .46in; display: grid; grid-template-columns: 1fr .82in; gap: .25in; align-items: end; font: 8pt Arial, sans-serif; color: #333; }
    .label-qr { width: .72in; height: .72in; border: 2px solid #111; box-sizing: border-box; padding: 0; justify-self: end; }
    .label-qr img { display: block; width: 100%; height: 100%; object-fit: contain; }
    @media print {
      .address-label-doc {
        width: 8.5in !important;
        height: 11in !important;
        margin: 0 !important;
        overflow: hidden !important;
      }
      .label-watermark img {
        width: 5.4in !important;
        opacity: .09 !important;
      }
    }
  </style>
  <div class="label-watermark"><img src="$_invoiceWatermarkImageUrl" alt=""></div>
  <div class="label-head">
    <div class="label-brand">
      <h1>$storeName</h1>
      <p>Where Elegance Speaks.<br>Scents Last Forever.</p>
    </div>
    <div class="label-meta">
      <strong>Order</strong><br>${htmlEscape.convert(order.id)}<br>
      <strong>Carrier</strong><br>${htmlEscape.convert(carrier)}<br>
      <strong>Status</strong><br>No postage included
    </div>
  </div>
  <div class="label-body">
    <div class="from-box"><div class="label-title">From</div>${fromLines.join('<br>')}</div>
    <div class="ship-box">
      <div class="ship-to">Ship To</div>
      <div class="ship-name">${htmlEscape.convert(toName)}</div>
      <div class="ship-address">${lines.join('<br>')}</div>
    </div>
  </div>
  <div class="label-footer">
    <div><div class="label-title">Store</div>$storeName<br>$storeAddress</div>
    <div class="label-qr">${_siteQrImage()}</div>
  </div>
</section>
''';
}

String _invoiceHtml(
  Order order,
  StoreInfo storeInfo, {
  bool printLite = false,
  String? thankYouText,
  String? returnPolicyText,
}) {
  final storeName = htmlEscape.convert(storeInfo.displayName);
  final address = _storeAddress(storeInfo);
  final contact =
      [
            storeInfo.email,
            storeInfo.phone,
            if (storeInfo.fax.isNotEmpty) 'Fax: ${storeInfo.fax}',
          ]
          .where((item) => item.trim().isNotEmpty)
          .map(htmlEscape.convert)
          .join('<br>');
  final lineSubtotal = order.lines.fold<double>(
    0,
    (total, line) => total + line.total,
  );
  final subtotal = order.subtotal > 0 ? order.subtotal : lineSubtotal;
  final discount = order.discountTotal;
  final tax = _orderTaxTotal(order);
  final taxSummary = order.taxBreakdown.isEmpty
      ? '<div><strong>TAX</strong><span>${currency(tax)}</span></div>'
      : order.taxBreakdown
            .map(
              (line) =>
                  '<div><strong>${htmlEscape.convert(line.jurisdiction.toUpperCase())} TAX</strong><span>${currency(line.amount)}</span></div>',
            )
            .join();
  final rows = order.lines.isEmpty
      ? '''
        <tr>
          <td class="item-photo"></td>
          <td><strong>Order item</strong><br><em>EgbeAnom Fragrance</em></td>
          <td>${order.itemCount}</td>
          <td>${currency(math.max(0, subtotal - discount))}</td>
          <td>${currency(math.max(0, subtotal - discount))}</td>
        </tr>
      '''
      : order.lines
            .map(
              (line) =>
                  '''
        <tr>
          <td class="item-photo">${line.product.primaryPhotoUrl.trim().isEmpty ? '' : '<img src="${htmlEscape.convert(line.product.primaryPhotoUrl)}" alt="${htmlEscape.convert(line.product.name)}">'}</td>
          <td>
            <strong>${htmlEscape.convert(line.product.name)}</strong><br>
            <em>${htmlEscape.convert(line.product.concentration)}</em><br>
            <span>${htmlEscape.convert(line.sku)} • ${htmlEscape.convert(line.size)}</span>
          </td>
          <td>${line.quantity}</td>
          <td>${currency(line.unitPrice)}</td>
          <td>${currency(line.total)}</td>
        </tr>
      ''',
            )
            .join();
  final due =
      order.createdAt?.add(const Duration(days: 14)) ??
      DateTime.now().add(const Duration(days: 14));
  final thankYou = _invoiceThankYouHtml(thankYouText);
  final returnPolicy = _invoiceReturnPolicyHtml(returnPolicyText);
  return '''
<section class="egbeanom-print-page invoice-doc">
  <style>
    .invoice-doc { font-family: Georgia, 'Times New Roman', serif; color: #121212; max-width: 940px; margin: 0 auto; background: #fff; border: 1px solid #b7892f; position: relative; overflow: hidden; }
    .invoice-watermark { position: absolute; inset: 0; display: grid; place-items: center; pointer-events: none; z-index: 0; }
    .invoice-watermark img { width: 68%; max-width: 620px; opacity: .12; filter: grayscale(1); }
    .invoice-top, .invoice-addresses, .invoice-table-wrap, .invoice-lower, .invoice-footer { position: relative; z-index: 1; }
    .invoice-top { background: #fff; color: #121212; padding: 34px 46px 28px; display: grid; grid-template-columns: 1fr 260px; gap: 34px; align-items: center; border-bottom: 3px solid #d3a13c; }
    .invoice-brand h1 { margin: 0; font-size: 54px; font-weight: 400; }
    .invoice-brand p { color: #333; font-size: 19px; margin: 14px 0 0; line-height: 1.35; }
    .invoice-meta { border-left: 1px solid #936e2a; padding-left: 36px; }
    .invoice-meta h2 { margin: 0 0 22px; font-size: 54px; letter-spacing: 4px; font-weight: 500; }
    .invoice-meta-grid { display: grid; grid-template-columns: 110px 1fr; gap: 12px 20px; color: #121212; font-family: Arial, sans-serif; font-size: 18px; }
    .invoice-meta-grid strong { color: #d3a13c; text-transform: uppercase; }
    .invoice-addresses { padding: 48px 64px 34px; display: grid; grid-template-columns: 1fr 1px 1fr; gap: 46px; align-items: start; }
    .gold-title { color: #b8842b; text-transform: uppercase; letter-spacing: 1px; font: 700 22px Arial, sans-serif; margin-bottom: 14px; }
    .divider-vertical { width: 1px; min-height: 180px; background: #caa45c; }
    .invoice-addresses p { margin: 0; font-size: 18px; line-height: 1.45; }
    .contact-line { display: grid; grid-template-columns: 34px 1fr; gap: 12px; margin-bottom: 16px; font-size: 18px; line-height: 1.35; }
    .contact-line b { color: #b8842b; font-size: 24px; text-align: center; }
    .invoice-table-wrap { padding: 0 46px 18px; position: relative; }
    .invoice-items { width: 100%; border-collapse: collapse; position: relative; z-index: 1; font-family: Arial, sans-serif; }
    .invoice-items th { background: transparent; color: #7d5a1e; padding: 14px; font-size: 15px; text-transform: uppercase; border: 1px solid #d8bd80; }
    .invoice-items td { border: 1px solid #d8bd80; padding: 14px; vertical-align: middle; font-size: 16px; }
    .invoice-items em { font-family: Georgia, serif; }
    .invoice-items span { color: #555; font-size: 12px; }
    .item-photo { width: 78px; text-align: center; }
    .item-photo img { width: 54px; height: 68px; object-fit: cover; }
    .invoice-lower { display: grid; grid-template-columns: 1fr 360px; gap: 44px; padding: 14px 46px 30px; align-items: end; }
    .thank-you { font-size: 20px; }
    .thank-you .script { color: #c28d2e; font-size: 38px; font-style: italic; display: block; margin-bottom: 8px; }
    .invoice-summary { font-family: Arial, sans-serif; }
    .invoice-summary div { display: flex; justify-content: space-between; padding: 14px 28px; border: 1px solid #d8bd80; border-bottom: 0; font-size: 17px; }
    .invoice-summary .grand { background: transparent; color: #121212; border: 1px solid #d8bd80; font-size: 30px; font-weight: 700; }
    .invoice-footer { background: transparent; border-top: 1px solid #d8bd80; padding: 28px 70px 34px; display: grid; grid-template-columns: 1fr 1fr 120px; gap: 34px; align-items: end; font-family: Arial, sans-serif; }
    .invoice-footer-title { color: #b8842b; text-transform: uppercase; font-weight: 700; margin-bottom: 8px; }
    .invoice-return-policy { grid-column: 1 / 3; color: #333; font-size: 13px; line-height: 1.35; padding-bottom: 4px; }
    .invoice-qr { width: 104px; height: 104px; border: 4px solid #111; box-sizing: border-box; background: transparent; padding: 0; justify-self: end; align-self: end; grid-column: 3; grid-row: 1 / span 2; }
    .invoice-qr img { display: block; width: 100%; height: 100%; object-fit: contain; }
    ${printLite ? '.invoice-top { border-bottom-width: 2px; }' : ''}
    @media print {
      .invoice-doc {
        width: 8.5in !important;
        height: 11in !important;
        max-width: none !important;
        margin: 0 !important;
        border-width: 1px !important;
        box-sizing: border-box !important;
        overflow: hidden !important;
      }
      .invoice-watermark img {
        width: 5.4in !important;
        opacity: .1 !important;
      }
      .invoice-top {
        padding: .18in .28in !important;
        grid-template-columns: 1fr 1.75in !important;
        gap: .22in !important;
        border-bottom-width: .03in !important;
      }
      .invoice-brand h1 {
        font-size: 26pt !important;
        line-height: 1 !important;
      }
      .invoice-brand p {
        font-size: 9pt !important;
        margin-top: .08in !important;
      }
      .invoice-meta {
        padding-left: .18in !important;
      }
      .invoice-meta h2 {
        font-size: 24pt !important;
        margin-bottom: .12in !important;
      }
      .invoice-meta-grid {
        grid-template-columns: .66in 1fr !important;
        gap: .04in .08in !important;
        font-size: 8.5pt !important;
      }
      .invoice-addresses {
        padding: .22in .34in .14in !important;
        gap: .22in !important;
      }
      .gold-title {
        font-size: 11pt !important;
        margin-bottom: .06in !important;
      }
      .divider-vertical {
        min-height: .78in !important;
      }
      .invoice-addresses p,
      .contact-line {
        font-size: 8.5pt !important;
        line-height: 1.25 !important;
      }
      .contact-line {
        grid-template-columns: .18in 1fr !important;
        gap: .06in !important;
        margin-bottom: .06in !important;
      }
      .contact-line b {
        font-size: 11pt !important;
      }
      .invoice-table-wrap {
        padding: 0 .28in .1in !important;
      }
      .invoice-items th {
        padding: .06in !important;
        font-size: 7.5pt !important;
      }
      .invoice-items td {
        padding: .055in !important;
        font-size: 8pt !important;
        line-height: 1.18 !important;
      }
      .invoice-items span {
        font-size: 6.5pt !important;
      }
      .item-photo {
        width: .48in !important;
      }
      .item-photo img {
        width: .32in !important;
        height: .42in !important;
      }
      .invoice-lower {
        grid-template-columns: 1fr 2.35in !important;
        gap: .18in !important;
        padding: .06in .28in .12in !important;
      }
      .thank-you {
        font-size: 9pt !important;
      }
      .thank-you .script {
        font-size: 20pt !important;
        margin-bottom: .03in !important;
      }
      .invoice-summary div {
        padding: .055in .1in !important;
        font-size: 8.5pt !important;
      }
      .invoice-summary .grand {
        font-size: 14pt !important;
      }
      .invoice-footer {
        padding: .12in .35in !important;
        grid-template-columns: 1fr 1fr .65in !important;
        gap: .06in .14in !important;
        font-size: 8pt !important;
      }
      .invoice-footer-title {
        margin-bottom: .04in !important;
      }
      .invoice-return-policy {
        font-size: 6.5pt !important;
        line-height: 1.18 !important;
        padding-bottom: 0 !important;
      }
      .invoice-qr {
        width: .65in !important;
        height: .65in !important;
        border-width: 2px !important;
        padding: 0 !important;
        justify-self: end !important;
        align-self: end !important;
        grid-column: 3 !important;
        grid-row: 1 / span 2 !important;
      }
      .invoice-qr img {
        width: 100% !important;
        height: 100% !important;
      }
    }
  </style>
  <div class="invoice-watermark"><img src="$_invoiceWatermarkImageUrl" alt=""></div>
  <div class="invoice-top">
    <div class="invoice-brand">
      <h1>$storeName</h1>
      <p>Where Elegance Speaks.<br>Scents Last Forever.</p>
    </div>
    <div class="invoice-meta">
      <h2>INVOICE</h2>
      <div class="invoice-meta-grid">
        <strong>Invoice #</strong><span>${htmlEscape.convert(order.id)}</span>
        <strong>Date</strong><span>${_orderDate(order)}</span>
        <strong>Due Date</strong><span>${due.month}/${due.day}/${due.year}</span>
      </div>
    </div>
  </div>
  <div class="invoice-addresses">
    <div>
      <div class="gold-title">Bill To:</div>
      <p><strong>${htmlEscape.convert(order.customer)}</strong><br>${htmlEscape.convert(order.email)}<br>${htmlEscape.convert(order.shippingCarrier)} ${htmlEscape.convert(order.shippingService)}</p>
    </div>
    <div class="divider-vertical"></div>
    <div>
      <div class="contact-line"><b>•</b><span><strong>$storeName</strong><br>$address</span></div>
      <div class="contact-line"><b>☎</b><span>${htmlEscape.convert(storeInfo.phone.isEmpty ? 'Phone not set' : storeInfo.phone)}</span></div>
      <div class="contact-line"><b>✉</b><span>${htmlEscape.convert(storeInfo.email.isEmpty ? 'Email not set' : storeInfo.email)}</span></div>
      <div class="contact-line"><b>◎</b><span>www.egbeanom.com</span></div>
    </div>
  </div>
  <div class="invoice-table-wrap">
    <table class="invoice-items">
      <thead>
        <tr><th></th><th>Item Description</th><th>Qty</th><th>Unit Price</th><th>Total</th></tr>
      </thead>
      <tbody>$rows</tbody>
    </table>
  </div>
  <div class="invoice-lower">
    <div class="thank-you">$thankYou</div>
    <div class="invoice-summary">
      <div><strong>SUBTOTAL</strong><span>${currency(subtotal)}</span></div>
      ${discount > 0 ? '<div><strong>DISCOUNT${order.couponCode.isEmpty ? '' : ' (${htmlEscape.convert(order.couponCode)})'}</strong><span>-${currency(discount)}</span></div>' : ''}
      <div><strong>SHIPPING</strong><span>${currency(order.shippingTotal)}</span></div>
      $taxSummary
      <div class="grand"><span>TOTAL</span><span>${currency(order.total)}</span></div>
    </div>
  </div>
  <div class="invoice-footer">
    <div class="invoice-return-policy"><div class="invoice-footer-title">Return Policy</div>$returnPolicy</div>
    <div><div class="invoice-footer-title">Customer Support</div>$contact</div>
    <div><div class="invoice-footer-title">Follow Us</div>@egbeanom.fragrance</div>
    <div class="invoice-qr">${_siteQrImage()}</div>
  </div>
</section>
''';
}

String _packListHtml(Order order, StoreInfo storeInfo) {
  final storeName = htmlEscape.convert(storeInfo.displayName);
  final address = _storeAddress(storeInfo);
  final rows = order.lines.isEmpty
      ? '<tr><td>Order record item count</td><td>${order.itemCount}</td><td></td><td></td></tr>'
      : order.lines
            .map(
              (line) =>
                  '''
        <tr>
          <td>${htmlEscape.convert(line.product.name)}<br><span>${htmlEscape.convert(line.sku)} • ${htmlEscape.convert(line.size)}</span></td>
          <td>${line.quantity}</td>
          <td>${htmlEscape.convert(line.product.itemLocation.isEmpty ? 'No location' : line.product.itemLocation)}</td>
          <td>${htmlEscape.convert(line.product.shippingSize(MeasurementSystem.standard))}</td>
        </tr>
      ''',
            )
            .join();
  return '''
<section class="egbeanom-print-page pack-list-doc">
  <style>
    .pack-list-doc { font-family: Georgia, 'Times New Roman', serif; color: #121212; max-width: 940px; margin: 0 auto; background: #fff; border: 1px solid #b7892f; box-sizing: border-box; position: relative; overflow: hidden; }
    .pack-watermark { position: absolute; inset: 0; display: grid; place-items: center; pointer-events: none; z-index: 0; }
    .pack-watermark img { width: 68%; max-width: 620px; opacity: .1; filter: grayscale(1); }
    .pick-head, .pick-grid, .pack-table-wrap, .signatures, .pack-footer { position: relative; z-index: 1; }
    .pick-head { display: grid; grid-template-columns: 1fr 180px; gap: 28px; align-items: center; border-bottom: 3px solid #d3a13c; padding: 34px 46px 24px; }
    .pick-head h1 { margin: 0 0 8px; font-size: 48px; font-weight: 500; letter-spacing: 3px; text-transform: uppercase; }
    .pick-head .brand { font-size: 22px; color: #333; }
    .pick-meta { border-left: 1px solid #936e2a; padding-left: 24px; font-family: Arial, sans-serif; font-size: 15px; line-height: 1.45; text-align: left; }
    .pick-meta strong { color: #b8842b; text-transform: uppercase; }
    .pack-qr-wrap { text-align: center; font: 10px Arial, sans-serif; color: #333; margin-top: 10px; }
    .pack-qr { width: 82px; height: 82px; border: 3px solid #111; box-sizing: border-box; background: transparent; padding: 0; margin-left: auto; }
    .pack-qr img { display: block; width: 100%; height: 100%; object-fit: contain; }
    .pick-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; padding: 34px 46px 20px; }
    .pick-box { border: 1px solid #d8bd80; padding: 16px; min-height: 92px; font-family: Arial, sans-serif; line-height: 1.35; background: rgba(255,255,255,.86); }
    .pack-title { color: #b8842b; text-transform: uppercase; letter-spacing: 1px; font-weight: 700; margin-bottom: 8px; }
    .pack-table-wrap { padding: 0 46px 20px; }
    table { width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; background: rgba(255,255,255,.88); }
    th { color: #7d5a1e; text-align: left; padding: 12px; border: 1px solid #d8bd80; text-transform: uppercase; font-size: 13px; }
    td { border: 1px solid #d8bd80; padding: 12px; vertical-align: top; font-size: 15px; }
    td span { color: #555; font-size: 12px; }
    .signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 34px; padding: 18px 46px 26px; font-family: Arial, sans-serif; }
    .sig { border-top: 1px solid #936e2a; padding-top: 10px; min-height: 24px; }
    .pack-footer { border-top: 1px solid #d8bd80; padding: 18px 46px 24px; display: grid; grid-template-columns: 1fr 1fr; gap: 24px; font-family: Arial, sans-serif; font-size: 13px; line-height: 1.35; }
    .pack-footer-title { color: #b8842b; text-transform: uppercase; font-weight: 700; margin-bottom: 6px; }
    @media print {
      .pack-list-doc {
        width: 8.5in !important;
        height: 11in !important;
        max-width: none !important;
        margin: 0 !important;
        padding: 0 !important;
        border-width: 1px !important;
        overflow: hidden !important;
      }
      .pack-watermark img {
        width: 5.4in !important;
        opacity: .09 !important;
      }
      .pick-head {
        grid-template-columns: 1fr 1.35in !important;
        padding: .18in .28in !important;
        gap: .18in !important;
        border-bottom-width: .03in !important;
      }
      .pick-head h1 {
        font-size: 24pt !important;
        margin-bottom: .04in !important;
      }
      .pick-head .brand {
        font-size: 10pt !important;
      }
      .pick-meta {
        padding-left: .14in !important;
        font-size: 8pt !important;
      }
      .pack-qr-wrap {
        font-size: 6pt !important;
        margin-top: .06in !important;
      }
      .pack-qr {
        width: .58in !important;
        height: .58in !important;
        padding: 0 !important;
      }
      .pick-grid {
        gap: .14in !important;
        padding: .18in .28in .12in !important;
      }
      .pick-box {
        min-height: .68in !important;
        padding: .1in !important;
        font-size: 9pt !important;
        line-height: 1.25 !important;
      }
      .pack-title {
        margin-bottom: .04in !important;
      }
      .pack-table-wrap {
        padding: 0 .28in .12in !important;
      }
      table {
        font-size: 8.5pt !important;
      }
      th {
        padding: .06in !important;
      }
      td {
        padding: .055in .06in !important;
        line-height: 1.18 !important;
      }
      td span {
        font-size: 7pt !important;
      }
      .signatures {
        padding: .14in .28in .18in !important;
        gap: .24in !important;
        font-size: 9pt !important;
      }
      .pack-footer {
        padding: .12in .28in !important;
        gap: .2in !important;
        font-size: 7.5pt !important;
      }
      .pack-footer-title {
        margin-bottom: .03in !important;
      }
    }
  </style>
  <div class="pack-watermark"><img src="$_invoiceWatermarkImageUrl" alt=""></div>
  <div class="pick-head">
    <div>
      <h1>Pack List</h1>
      <div class="brand">$storeName</div>
    </div>
    <div class="pick-meta">
      <strong>Order</strong><br>${htmlEscape.convert(order.id)}<br>
      <strong>Date</strong><br>${_orderDate(order)}<br>
      <strong>Priority</strong><br>${htmlEscape.convert(order.shippingPriority)}
      <div class="pack-qr-wrap">
        <div class="pack-qr">${_siteQrImage()}</div>
        $_siteQrLabel
      </div>
    </div>
  </div>
  <div class="pick-grid">
    <div class="pick-box"><div class="pack-title">Customer</div>${htmlEscape.convert(order.customer)}<br>${htmlEscape.convert(order.email)}</div>
    <div class="pick-box"><div class="pack-title">Shipping</div>${htmlEscape.convert(order.shippingCarrier)} ${htmlEscape.convert(order.shippingService)}<br>${htmlEscape.convert(order.trackingNumber.isEmpty ? 'Tracking pending' : order.trackingNumber)}</div>
  </div>
  <div class="pack-table-wrap">
    <table>
      <thead><tr><th>Item</th><th>Qty</th><th>Pick location</th><th>Package size</th></tr></thead>
      <tbody>$rows</tbody>
    </table>
  </div>
  <div class="signatures">
    <div class="sig">Picked by / Time</div>
    <div class="sig">Packed by / Time</div>
  </div>
  <div class="pack-footer">
    <div><div class="pack-footer-title">Store</div>$storeName<br>$address</div>
    <div><div class="pack-footer-title">Customer Care</div>${htmlEscape.convert(storeInfo.email.isEmpty ? 'Email not set' : storeInfo.email)}<br>${htmlEscape.convert(storeInfo.phone.isEmpty ? 'Phone not set' : storeInfo.phone)}</div>
  </div>
</section>
''';
}

String _rmaHtml(Order order, StoreInfo storeInfo) {
  final storeName = htmlEscape.convert(storeInfo.displayName);
  final rmaNumber = htmlEscape.convert(
    order.rmaNumber.trim().isEmpty ? 'Pending RMA' : order.rmaNumber,
  );
  final orderId = htmlEscape.convert(order.id);
  final customer = htmlEscape.convert(order.customer);
  final reason = htmlEscape.convert(order.returnReason);
  final comment = htmlEscape.convert(order.returnAdminComment);
  final returnItems =
      (order.returnItems.isEmpty
              ? order.lines.map(ReturnRequestItem.fromLine).toList()
              : order.returnItems)
          .map(
            (item) =>
                '<tr><td>${htmlEscape.convert(item.productName)}</td><td>${htmlEscape.convert(item.size)}</td><td>${htmlEscape.convert(item.sku)}</td><td>${item.quantity}</td></tr>',
          )
          .join();
  final storeAddress =
      [
            storeInfo.displayName,
            storeInfo.addressLine1,
            storeInfo.addressLine2,
            [
              storeInfo.city,
              storeInfo.state,
              storeInfo.postalCode,
            ].where((item) => item.trim().isNotEmpty).join(', '),
            storeInfo.country,
          ]
          .where((line) => line.trim().isNotEmpty)
          .map(htmlEscape.convert)
          .join('<br>');
  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>RMA $rmaNumber</title>
  <style>
    @page { size: letter; margin: 0.45in; }
    body { font-family: Arial, sans-serif; color: #172026; }
    h1 { margin: 0 0 4px; font-size: 28px; }
    h2 { margin: 20px 0 8px; font-size: 18px; }
    .header { border-bottom: 2px solid #172026; padding-bottom: 12px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 14px; }
    .box { border: 1px solid #172026; padding: 12px; min-height: 86px; }
    table { width: 100%; border-collapse: collapse; margin-top: 8px; }
    th, td { border: 1px solid #172026; padding: 8px; text-align: left; }
    th { background: #f2f2f2; }
    .label { margin-top: 28px; border: 2px dashed #172026; padding: 18px; min-height: 180px; }
    .label-title { text-transform: uppercase; font-weight: 700; letter-spacing: 1px; margin-bottom: 12px; }
    .large { font-size: 22px; font-weight: 700; }
    .muted { color: #555; }
  </style>
</head>
<body>
  <div class="header">
    <h1>$storeName Return Authorization</h1>
    <div class="large">RMA: $rmaNumber</div>
    <div>Order: $orderId &nbsp; Customer: $customer</div>
  </div>
  <div class="grid">
    <div class="box">
      <strong>Customer reason</strong><br>
      ${reason.isEmpty ? 'No reason provided.' : reason}
    </div>
    <div class="box">
      <strong>Store note</strong><br>
      ${comment.isEmpty ? 'Approved for return. Include this RMA in the package.' : comment}
    </div>
  </div>
  <h2>Approved return items</h2>
  <table>
    <thead><tr><th>Product</th><th>Size</th><th>SKU</th><th>Qty</th></tr></thead>
    <tbody>$returnItems</tbody>
  </table>
  <h2>Instructions</h2>
  <p>Print this page and include it inside the return package. Attach the return label below to the outside of the package. Refunds are applied after the returned item is received and inspected.</p>
  <div class="label">
    <div class="label-title">Return mailing label</div>
    <div class="muted">Return to:</div>
    <div class="large">$storeName</div>
    <div>$storeAddress</div>
    <br>
    <div><strong>RMA:</strong> $rmaNumber</div>
    <div><strong>Order:</strong> $orderId</div>
  </div>
</body>
</html>
''';
}

class _InvoiceDocumentPreview extends StatelessWidget {
  const _InvoiceDocumentPreview({
    required this.order,
    required this.storeInfo,
    this.thankYouText,
    this.returnPolicyText,
  });

  final Order order;
  final StoreInfo storeInfo;
  final String? thankYouText;
  final String? returnPolicyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF161616), fontSize: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF050505),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'INVOICE',
                      style: TextStyle(
                        color: Color(0xFFF7D47C),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  Text(
                    storeInfo.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF7F2E8),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text('${order.customer}\n${order.email}')),
                  Text('${order.id}\n${_orderDate(order)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final line in order.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${line.product.name} • ${line.size}'),
                    ),
                    Text('${line.quantity} x ${currency(line.unitPrice)}'),
                    const SizedBox(width: 12),
                    Text(currency(line.total)),
                  ],
                ),
              ),
            const Divider(color: Color(0xFFCCCCCC)),
            Text(
              _invoiceThankYouPlain(thankYouText),
              style: const TextStyle(
                color: Color(0xFFC28D2E),
                fontFamily: 'Georgia',
                fontSize: 22,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Return Policy',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              (returnPolicyText?.trim().isNotEmpty ?? false)
                  ? returnPolicyText!.trim()
                  : SiteStatus().returnPolicy,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Shipping ${currency(order.shippingTotal)}\nTotal ${currency(order.total)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
