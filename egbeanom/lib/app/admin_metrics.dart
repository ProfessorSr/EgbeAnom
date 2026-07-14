part of '../main.dart';

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.revenue,
    required this.inventory,
    required this.unitsSold,
    required this.reservedInventory,
    required this.cartValue,
    required this.newUsersToday,
    required this.newUsers7Days,
    required this.conversionRate,
    required this.lowStockProducts,
  });

  factory AdminDashboardMetrics.from({
    required List<Fragrance> products,
    required List<Order> orders,
    required List<ActiveCart> activeCarts,
    required List<CustomerAccount> customers,
    required List<DailyMetric> dailyMetrics,
  }) {
    final visits = dailyMetrics.fold<int>(
      0,
      (total, metric) => total + metric.visits,
    );
    final metricOrders = dailyMetrics.fold<int>(
      0,
      (total, metric) => total + metric.orders,
    );
    return AdminDashboardMetrics(
      revenue: orders.fold<double>(0, (total, order) => total + order.total),
      inventory: products.fold<int>(0, (total, product) {
        return total + product.stock;
      }),
      unitsSold: products.fold<int>(0, (total, product) {
        return total + product.sold;
      }),
      reservedInventory: activeCarts.fold<int>(0, (total, cart) {
        return total + cart.itemCount;
      }),
      cartValue: activeCarts.fold<double>(0, (total, cart) {
        return total + cart.value;
      }),
      newUsersToday: customers.where((customer) {
        return customer.joinedDaysAgo == 0;
      }).length,
      newUsers7Days: dailyMetrics.fold<int>(0, (total, metric) {
        return total + metric.newUsers;
      }),
      conversionRate: visits == 0 ? 0 : metricOrders / visits * 100,
      lowStockProducts: products.where((product) {
        return product.stock <= product.reorderPoint;
      }).toList(),
    );
  }

  final double revenue;
  final int inventory;
  final int unitsSold;
  final int reservedInventory;
  final double cartValue;
  final int newUsersToday;
  final int newUsers7Days;
  final double conversionRate;
  final List<Fragrance> lowStockProducts;
}

class AdminOverviewWindowMetrics {
  const AdminOverviewWindowMetrics({
    required this.days,
    required this.metrics,
    required this.orders,
    required this.users,
    required this.revenue,
    required this.visits,
    required this.averageOrderValue,
    required this.revenuePerVisit,
  });

  factory AdminOverviewWindowMetrics.from({
    required int days,
    required List<DailyMetric> dailyMetrics,
    required List<Order> orders,
  }) {
    final metrics = dailyMetrics.length <= days
        ? dailyMetrics
        : dailyMetrics.sublist(dailyMetrics.length - days);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final paidOrders = orders.where((order) {
      final created = order.createdAt;
      if (created == null || created.isBefore(cutoff)) {
        return false;
      }
      final financial = order.financialStatus.trim().toLowerCase();
      return financial == 'paid' ||
          financial == 'partially refunded' ||
          financial == 'refunded';
    }).toList();
    final metricOrders = metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.orders,
    );
    final orderCount = metricOrders > 0 ? metricOrders : paidOrders.length;
    final metricRevenue = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.revenue,
    );
    final revenue = metricRevenue > 0
        ? metricRevenue
        : paidOrders.fold<double>(0, (sum, order) => sum + order.total);
    final visits = metrics.fold<int>(0, (sum, metric) => sum + metric.visits);
    return AdminOverviewWindowMetrics(
      days: days,
      metrics: metrics,
      orders: orderCount,
      users: metrics.fold<int>(0, (sum, metric) => sum + metric.newUsers),
      revenue: revenue,
      visits: visits,
      averageOrderValue: orderCount == 0 ? 0 : revenue / orderCount,
      revenuePerVisit: visits == 0 ? 0 : revenue / visits,
    );
  }

  final int days;
  final List<DailyMetric> metrics;
  final int orders;
  final int users;
  final double revenue;
  final int visits;
  final double averageOrderValue;
  final double revenuePerVisit;
}

class AdminReportMetrics {
  const AdminReportMetrics({
    required this.totalVisits,
    required this.totalNewUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.topProducts,
  });

  factory AdminReportMetrics.from({
    required List<DailyMetric> dailyMetrics,
    required List<Fragrance> products,
  }) {
    final totalOrders = dailyMetrics.fold<int>(
      0,
      (total, metric) => total + metric.orders,
    );
    final totalRevenue = dailyMetrics.fold<double>(
      0,
      (total, metric) => total + metric.revenue,
    );
    return AdminReportMetrics(
      totalVisits: dailyMetrics.fold<int>(
        0,
        (total, metric) => total + metric.visits,
      ),
      totalNewUsers: dailyMetrics.fold<int>(
        0,
        (total, metric) => total + metric.newUsers,
      ),
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      averageOrderValue: totalOrders == 0 ? 0 : totalRevenue / totalOrders,
      topProducts: ([...products]..sort((a, b) => b.sold.compareTo(a.sold))),
    );
  }

  final int totalVisits;
  final int totalNewUsers;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final List<Fragrance> topProducts;
}

@visibleForTesting
AdminDashboardMetrics adminDashboardMetricsForTest({
  required List<Fragrance> products,
  required List<Order> orders,
  required List<ActiveCart> activeCarts,
  required List<CustomerAccount> customers,
  required List<DailyMetric> dailyMetrics,
}) => AdminDashboardMetrics.from(
  products: products,
  orders: orders,
  activeCarts: activeCarts,
  customers: customers,
  dailyMetrics: dailyMetrics,
);

@visibleForTesting
AdminOverviewWindowMetrics adminOverviewWindowMetricsForTest({
  required int days,
  required List<DailyMetric> dailyMetrics,
  required List<Order> orders,
}) => AdminOverviewWindowMetrics.from(
  days: days,
  dailyMetrics: dailyMetrics,
  orders: orders,
);

@visibleForTesting
AdminReportMetrics adminReportMetricsForTest({
  required List<DailyMetric> dailyMetrics,
  required List<Fragrance> products,
}) => AdminReportMetrics.from(dailyMetrics: dailyMetrics, products: products);
