import 'package:egbeanom/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Order samplePrintOrder() => Order(
    id: 'EA-PRINT-1',
    customer: 'Mina Customer',
    email: 'mina@example.com',
    subtotal: 84,
    shippingTotal: 8,
    discountTotal: 4,
    total: 96,
    itemCount: 2,
    status: 'Pending',
    shippingCarrier: 'USPS',
    shippingService: 'Priority',
    shippingPriority: 'Priority',
    trackingNumber: '9400000000000000000000',
    couponCode: 'THANKYOU',
    taxBreakdown: const [
      TaxBreakdownLine(
        name: 'Arizona State Tax',
        jurisdiction: 'state',
        rate: 0.056,
        amount: 5.60,
      ),
      TaxBreakdownLine(
        name: 'Phoenix City Tax',
        jurisdiction: 'city',
        rate: 0.023,
        amount: 2.40,
      ),
    ],
    shippingAddress: ShippingAddress(
      firstName: 'Mina',
      lastName: 'Customer',
      addressLine1: '123 Amber Lane',
      city: 'Phoenix',
      state: 'AZ',
      postalCode: '85001',
      country: 'US',
    ),
    lines: [
      CartLine(
        product: Fragrance(
          id: 1,
          name: 'Test Fragrance',
          type: 'Perfume',
          brand: 'EgbeAnom',
          notes: 'Amber',
          size: '50 ml',
          price: 42,
          stock: 5,
          sold: 0,
          featuredColor: Colors.amber,
          sku: 'TEST-50',
          photoUrl: '',
          vendor: 'EgbeAnom',
          categoryId: 1,
          itemLocation: 'Shelf A1',
        ),
        quantity: 2,
      ),
    ],
  );

  StoreInfo sampleStoreInfo() => StoreInfo(
    displayName: 'EgbeAnom Fragrance',
    addressLine1: '456 Scent Ave',
    city: 'Phoenix',
    state: 'AZ',
    postalCode: '85002',
    country: 'US',
    email: 'care@example.com',
    phone: '555-0100',
  );

  test(
    'address label renderer includes store, recipient, QR, and print sizing',
    () {
      final order = samplePrintOrder();
      final html = buildAddressLabelHtmlForTest(
        order,
        'USPS',
        sampleStoreInfo(),
      );

      expect(html, contains('address-label-doc'));
      expect(html, contains('EA-PRINT-1'));
      expect(html, contains('Mina Customer'));
      expect(html, contains('123 Amber Lane'));
      expect(html, contains('EgbeAnom Fragrance'));
      expect(html, contains('egbeanom_qr_code.png'));
      expect(html, contains('width: 8.5in'));
      expect(html, contains('height: 11in'));
    },
  );

  test('invoice renderer includes printable invoice details and tax rows', () {
    final html = buildInvoiceHtmlForTest(
      samplePrintOrder(),
      sampleStoreInfo(),
      thankYouText: 'Thank you for your order.',
      returnPolicyText: 'Returns accepted within 30 days.',
    );

    expect(html, contains('invoice-doc'));
    expect(html, contains('INVOICE'));
    expect(html, contains('EA-PRINT-1'));
    expect(html, contains('Test Fragrance'));
    expect(html, contains('STATE TAX'));
    expect(html, contains('CITY TAX'));
    expect(html, contains('Returns accepted within 30 days.'));
    expect(html, contains('bw_image.png'));
    expect(html, contains('egbeanom_qr_code.png'));
    expect(html, contains('width: 8.5in'));
    expect(html, contains('height: 11in'));
  });

  test('pack list renderer includes pick details, QR, and one-page sizing', () {
    final html = buildPackListHtmlForTest(
      samplePrintOrder(),
      sampleStoreInfo(),
    );

    expect(html, contains('pack-list-doc'));
    expect(html, contains('Pack List'));
    expect(html, contains('EA-PRINT-1'));
    expect(html, contains('Shelf A1'));
    expect(html, contains('Picked by / Time'));
    expect(html, contains('Packed by / Time'));
    expect(html, contains('bw_image.png'));
    expect(html, contains('egbeanom_qr_code.png'));
    expect(html, contains('width: 8.5in'));
    expect(html, contains('height: 11in'));
  });
}
