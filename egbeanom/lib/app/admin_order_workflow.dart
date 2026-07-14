part of '../main.dart';

class AdminOrderWorkflow {
  const AdminOrderWorkflow._();

  static const List<String> shippingFilters = [
    'All',
    'Standard',
    'Priority',
    'Priority One Day',
    'Ground',
  ];

  static const List<String> statusFilters = [
    'All',
    'Pending',
    'Processing',
    'Invoice created',
    'Label created',
    'Sent',
    'Shipped',
    'Delivered',
    'Cancelled',
    'Refunded',
  ];

  static const List<String> paymentFilters = [
    'All',
    'Unpaid',
    'Paid',
    'Partially refunded',
    'Refunded',
  ];

  static List<Order> visibleOrders(
    List<Order> orders, {
    String shippingFilter = 'All',
    String paymentFilter = 'All',
    String statusFilter = 'All',
  }) {
    final filtered = orders.where((order) {
      return matchesShippingFilter(order, shippingFilter) &&
          matchesPaymentFilter(order, paymentFilter) &&
          matchesStatusFilter(order, statusFilter);
    }).toList();

    filtered.sort((a, b) {
      final shippingCompare = shippingRank(a).compareTo(shippingRank(b));
      if (shippingCompare != 0) {
        return shippingCompare;
      }
      final statusCompare = statusRank(a).compareTo(statusRank(b));
      if (statusCompare != 0) {
        return statusCompare;
      }
      return (b.createdAt ?? DateTime(2000)).compareTo(
        a.createdAt ?? DateTime(2000),
      );
    });
    return filtered;
  }

  static bool matchesShippingFilter(Order order, String filter) {
    if (filter == 'All') {
      return true;
    }
    return shippingType(order) == filter;
  }

  static bool matchesStatusFilter(Order order, String filter) {
    if (filter == 'All') {
      return true;
    }
    return workflowStatus(order) == filter;
  }

  static bool matchesPaymentFilter(Order order, String filter) {
    if (filter == 'All') {
      return true;
    }
    return paymentStatus(order) == filter;
  }

  static int shippingRank(Order order) {
    final type = shippingType(order);
    final index = shippingFilters.indexOf(type);
    return index == -1 ? shippingFilters.length : index;
  }

  static int statusRank(Order order) {
    final status = workflowStatus(order);
    final index = statusFilters.indexOf(status);
    return index == -1 ? statusFilters.length : index;
  }

  static String shippingType(Order order) {
    final text =
        '${order.shippingPriority} ${order.shippingCarrier} ${order.shippingService}'
            .toLowerCase();
    if (text.contains('one day') ||
        text.contains('1 day') ||
        text.contains('overnight') ||
        text.contains('express')) {
      return 'Priority One Day';
    }
    if (text.contains('priority')) {
      return 'Priority';
    }
    if (text.contains('ground')) {
      return 'Ground';
    }
    return 'Standard';
  }

  static String workflowStatus(Order order) {
    final fulfillment = order.fulfillmentStatus.toLowerCase();
    final status = order.status.toLowerCase();
    final financial = order.financialStatus.toLowerCase();
    final label = order.labelStatus.toLowerCase();

    if (financial == 'refunded' || status == 'refunded') {
      return 'Refunded';
    }
    if (fulfillment == 'cancelled' || status == 'cancelled') {
      return 'Cancelled';
    }
    if (fulfillment == 'delivered' || status == 'delivered') {
      return 'Delivered';
    }
    if (fulfillment == 'shipped' || status == 'shipped') {
      return 'Shipped';
    }
    if (fulfillment == 'sent' || status == 'sent') {
      return 'Sent';
    }
    if (fulfillment == 'label printed' ||
        fulfillment == 'label created' ||
        fulfillment == 'label_created' ||
        label == 'label printed' ||
        label == 'label created' ||
        label == 'label_created') {
      return 'Label created';
    }
    if (fulfillment == 'invoice created' ||
        fulfillment == 'invoice_created' ||
        status == 'invoice created' ||
        status == 'invoice_created') {
      return 'Invoice created';
    }
    if (fulfillment == 'processing' ||
        fulfillment == 'being picked' ||
        fulfillment == 'packing' ||
        status == 'processing' ||
        status == 'picking') {
      return 'Processing';
    }
    return 'Pending';
  }

  static String paymentStatus(Order order) {
    final financial = order.financialStatus.trim().toLowerCase();
    final status = order.status.trim().toLowerCase();
    if (financial == 'refunded' || status == 'refunded') {
      return 'Refunded';
    }
    if (financial == 'partially refunded' ||
        financial == 'partially_refunded') {
      return 'Partially refunded';
    }
    if (financial == 'paid' || status == 'paid') {
      return 'Paid';
    }
    return 'Unpaid';
  }

  static bool isPaid(Order order) => paymentStatus(order) == 'Paid';

  static List<Order> unpaidOrders(List<Order> orders) =>
      orders.where((order) => !isPaid(order)).toList();
}

@visibleForTesting
List<Order> adminVisibleOrdersForTest(
  List<Order> orders, {
  String shippingFilter = 'All',
  String paymentFilter = 'All',
  String statusFilter = 'All',
}) => AdminOrderWorkflow.visibleOrders(
  orders,
  shippingFilter: shippingFilter,
  paymentFilter: paymentFilter,
  statusFilter: statusFilter,
);

@visibleForTesting
String adminOrderShippingTypeForTest(Order order) =>
    AdminOrderWorkflow.shippingType(order);

@visibleForTesting
String adminOrderWorkflowStatusForTest(Order order) =>
    AdminOrderWorkflow.workflowStatus(order);

@visibleForTesting
String adminOrderPaymentStatusForTest(Order order) =>
    AdminOrderWorkflow.paymentStatus(order);

@visibleForTesting
List<Order> adminUnpaidOrdersForTest(List<Order> orders) =>
    AdminOrderWorkflow.unpaidOrders(orders);
