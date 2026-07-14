import 'package:egbeanom/main.dart';
import 'package:egbeanom/models/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Checkout flow guardrails', () {
    test(
      'draft order rows keep checkout totals, items, coupon, and tax lines',
      () {
        final order = Order.fromRow({
          'order_number': 'EA-CHECKOUT-1',
          'customer_name': 'Mina Customer',
          'email': 'mina@example.com',
          'status': 'Pending',
          'financial_status': 'Unpaid',
          'fulfillment_status': 'Pending',
          'subtotal': 84,
          'discount_total': 10,
          'shipping_total': 8,
          'grand_total': 88,
          'item_count': 2,
          'coupon_code': 'SAVE10',
          'tax_breakdown': [
            {
              'name': 'Arizona State Tax',
              'jurisdiction': 'state',
              'rate': 0.056,
              'amount': 4.20,
            },
            {
              'name': 'Phoenix City Tax',
              'jurisdiction': 'city',
              'rate': 0.023,
              'amount': 1.80,
            },
          ],
          'order_items': [
            {
              'product_id': 7,
              'product_name': 'Amber Test',
              'size': '50 ml',
              'unit_price': 42,
              'quantity': 2,
              'sku': 'AMB-50',
              'item_location': 'Shelf A1',
            },
          ],
        });

        expect(order.status, 'Pending');
        expect(order.financialStatus, 'Unpaid');
        expect(order.fulfillmentStatus, 'Pending');
        expect(order.couponCode, 'SAVE10');
        expect(order.lines.single.quantity, 2);
        expect(order.lines.single.product.name, 'Amber Test');
        expect(order.taxBreakdown.map((line) => line.jurisdiction), [
          'state',
          'city',
        ]);
        expect(
          order.taxBreakdown.fold<double>(0, (sum, line) => sum + line.amount),
          6,
        );
      },
    );

    test('successful and failed payment states stay explicit for admin', () {
      final order = Order(
        id: 'EA-CHECKOUT-2',
        customer: 'Mina Customer',
        email: 'mina@example.com',
        total: 88,
        itemCount: 2,
        status: 'Pending',
        financialStatus: 'Unpaid',
        fulfillmentStatus: 'Pending',
      );

      order
        ..status = 'Pending'
        ..financialStatus = 'Paid'
        ..fulfillmentStatus = 'Pending';

      expect(adminOrderWorkflowStatusForTest(order), 'Pending');
      expect(adminOrderPaymentStatusForTest(order), 'Paid');

      order
        ..status = 'Cancelled'
        ..financialStatus = 'Unpaid'
        ..fulfillmentStatus = 'Cancelled';

      expect(adminOrderWorkflowStatusForTest(order), 'Cancelled');
      expect(adminOrderPaymentStatusForTest(order), 'Unpaid');
    });

    test('inventory and coupon limits block unsafe checkout states', () {
      expect(Validators.validateInventoryAvailable(1, 2), isNotNull);
      expect(Validators.validateInventoryAvailable(5, 2), isNull);

      final usedCoupon = CouponRule.fromRow({
        'code': 'LIMIT1',
        'name': 'One use',
        'discount_type': 'Fixed amount',
        'value': 10,
        'minimum_spend': 0,
        'usage_limit': 1,
        'used': 1,
        'is_active': true,
        'is_archived': false,
      });

      expect(usedCoupon.usageLimit, 1);
      expect(usedCoupon.used, 1);
      expect(usedCoupon.used >= usedCoupon.usageLimit, isTrue);
    });

    test(
      'survey review rows preserve order/customer status for admin review',
      () {
        final review = ReviewSummary.fromRow({
          'id': 33,
          'author': 'Mina Customer',
          'rating': 5,
          'title': 'Beautiful',
          'body': 'The scent lasted all day.',
          'scope': 'company',
          'status': 'pending',
          'customer_email': 'mina@example.com',
        });

        expect(review.scope, 'company');
        expect(review.status, 'pending');
        expect(review.customerEmail, 'mina@example.com');
      },
    );
  });
}
