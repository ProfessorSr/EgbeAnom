import 'package:egbeanom/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Order order({
    required String id,
    String shippingPriority = 'Standard',
    String shippingCarrier = 'USPS',
    String shippingService = 'Standard',
    String status = 'Pending',
    String financialStatus = 'Paid',
    String fulfillmentStatus = 'Pending',
    String labelStatus = 'Not requested',
    DateTime? createdAt,
  }) {
    return Order(
      id: id,
      customer: 'Customer $id',
      email: '$id@example.com',
      total: 100,
      itemCount: 1,
      status: status,
      financialStatus: financialStatus,
      fulfillmentStatus: fulfillmentStatus,
      shippingPriority: shippingPriority,
      shippingCarrier: shippingCarrier,
      shippingService: shippingService,
      labelStatus: labelStatus,
      createdAt: createdAt,
    );
  }

  group('Admin order workflow', () {
    test('classifies shipping types from configured shipping text', () {
      expect(
        adminOrderShippingTypeForTest(
          order(id: 'one-day', shippingService: 'Priority One Day'),
        ),
        'Priority One Day',
      );
      expect(
        adminOrderShippingTypeForTest(
          order(id: 'priority', shippingPriority: 'Priority'),
        ),
        'Priority',
      );
      expect(
        adminOrderShippingTypeForTest(
          order(id: 'ground', shippingService: 'Ground Advantage'),
        ),
        'Ground',
      );
      expect(adminOrderShippingTypeForTest(order(id: 'standard')), 'Standard');
    });

    test('normalizes workflow and payment statuses for admin filters', () {
      expect(
        adminOrderWorkflowStatusForTest(
          order(id: 'label', labelStatus: 'label_created'),
        ),
        'Label created',
      );
      expect(
        adminOrderWorkflowStatusForTest(
          order(id: 'sent', fulfillmentStatus: 'Sent'),
        ),
        'Sent',
      );
      expect(
        adminOrderWorkflowStatusForTest(
          order(id: 'refund', financialStatus: 'Refunded'),
        ),
        'Refunded',
      );
      expect(
        adminOrderPaymentStatusForTest(
          order(id: 'partial', financialStatus: 'partially_refunded'),
        ),
        'Partially refunded',
      );
      expect(
        adminOrderPaymentStatusForTest(
          order(id: 'unpaid', financialStatus: 'Unpaid'),
        ),
        'Unpaid',
      );
    });

    test(
      'filters and sorts visible orders by shipping, status, then newest',
      () {
        final orders = [
          order(
            id: 'ground',
            shippingService: 'Ground',
            fulfillmentStatus: 'Pending',
            createdAt: DateTime(2026, 7, 1),
          ),
          order(
            id: 'priority-new',
            shippingPriority: 'Priority',
            fulfillmentStatus: 'Processing',
            createdAt: DateTime(2026, 7, 3),
          ),
          order(
            id: 'priority-old',
            shippingPriority: 'Priority',
            fulfillmentStatus: 'Processing',
            createdAt: DateTime(2026, 7, 2),
          ),
        ];

        final visible = adminVisibleOrdersForTest(
          orders,
          shippingFilter: 'Priority',
          statusFilter: 'Processing',
        );

        expect(visible.map((order) => order.id), [
          'priority-new',
          'priority-old',
        ]);
      },
    );

    test('finds unpaid selected orders before batch print actions', () {
      final paid = order(id: 'paid', financialStatus: 'Paid');
      final unpaid = order(id: 'unpaid', financialStatus: 'Unpaid');

      expect(adminUnpaidOrdersForTest([paid, unpaid]), [unpaid]);
    });
  });
}
