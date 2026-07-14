import 'package:egbeanom/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Fragrance product({
    required int id,
    required String name,
    required double price,
    required int stock,
    required int sold,
    int reorderPoint = 8,
  }) {
    return Fragrance(
      id: id,
      name: name,
      type: 'Perfume',
      brand: 'EgbeAnom',
      notes: '',
      size: '50 ml',
      price: price,
      stock: stock,
      sold: sold,
      featuredColor: Colors.black,
      sku: 'SKU-$id',
      photoUrl: '',
      vendor: 'EgbeAnom',
      categoryId: 1,
      reorderPoint: reorderPoint,
    );
  }

  Order order({
    required String id,
    required double total,
    String financialStatus = 'Paid',
    DateTime? createdAt,
  }) {
    return Order(
      id: id,
      customer: 'Customer $id',
      email: '$id@example.com',
      total: total,
      itemCount: 1,
      status: 'Pending',
      financialStatus: financialStatus,
      createdAt: createdAt,
    );
  }

  CustomerAccount customer({required String id, required int joinedDaysAgo}) {
    return CustomerAccount(
      id: id,
      name: 'Customer $id',
      email: '$id@example.com',
      joinedDaysAgo: joinedDaysAgo,
      orders: 0,
      lifetimeValue: 0,
      segment: 'New',
    );
  }

  group('Admin dashboard metrics', () {
    test('summarizes inventory, carts, revenue, and customer growth', () {
      final bottle = product(
        id: 1,
        name: 'Bottle',
        price: 50,
        stock: 4,
        sold: 3,
        reorderPoint: 5,
      );
      final sample = product(
        id: 2,
        name: 'Sample',
        price: 12,
        stock: 20,
        sold: 7,
      );

      final metrics = adminDashboardMetricsForTest(
        products: [bottle, sample],
        orders: [
          order(id: 'A', total: 90),
          order(id: 'B', total: 40),
        ],
        activeCarts: [
          ActiveCart(
            id: 'cart-1',
            customer: 'Avery',
            minutesAgo: 4,
            lines: [CartLine(product: bottle, quantity: 2)],
          ),
        ],
        customers: [
          customer(id: 'new', joinedDaysAgo: 0),
          customer(id: 'old', joinedDaysAgo: 3),
        ],
        dailyMetrics: const [
          DailyMetric(
            day: 'Mon',
            newUsers: 2,
            visits: 20,
            orders: 4,
            revenue: 80,
          ),
          DailyMetric(
            day: 'Tue',
            newUsers: 1,
            visits: 30,
            orders: 6,
            revenue: 120,
          ),
        ],
      );

      expect(metrics.revenue, 130);
      expect(metrics.inventory, 24);
      expect(metrics.unitsSold, 10);
      expect(metrics.reservedInventory, 2);
      expect(metrics.cartValue, 100);
      expect(metrics.newUsersToday, 1);
      expect(metrics.newUsers7Days, 3);
      expect(metrics.conversionRate, 20);
      expect(metrics.lowStockProducts, [bottle]);
    });

    test('uses paid orders when daily metrics do not contain revenue', () {
      final metrics = adminOverviewWindowMetricsForTest(
        days: 7,
        dailyMetrics: const [
          DailyMetric(
            day: 'Mon',
            newUsers: 1,
            visits: 10,
            orders: 0,
            revenue: 0,
          ),
        ],
        orders: [
          order(id: 'paid', total: 60, createdAt: DateTime.now()),
          order(
            id: 'unpaid',
            total: 200,
            financialStatus: 'Unpaid',
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(metrics.orders, 1);
      expect(metrics.revenue, 60);
      expect(metrics.visits, 10);
      expect(metrics.averageOrderValue, 60);
      expect(metrics.revenuePerVisit, 6);
    });

    test('sorts report top products by units sold', () {
      final lowSeller = product(
        id: 1,
        name: 'Low seller',
        price: 45,
        stock: 10,
        sold: 2,
      );
      final topSeller = product(
        id: 2,
        name: 'Top seller',
        price: 55,
        stock: 10,
        sold: 9,
      );

      final metrics = adminReportMetricsForTest(
        dailyMetrics: const [
          DailyMetric(
            day: 'Mon',
            newUsers: 1,
            visits: 12,
            orders: 2,
            revenue: 90,
          ),
          DailyMetric(
            day: 'Tue',
            newUsers: 2,
            visits: 18,
            orders: 3,
            revenue: 150,
          ),
        ],
        products: [lowSeller, topSeller],
      );

      expect(metrics.totalVisits, 30);
      expect(metrics.totalNewUsers, 3);
      expect(metrics.totalOrders, 5);
      expect(metrics.totalRevenue, 240);
      expect(metrics.averageOrderValue, 48);
      expect(metrics.topProducts.first, topSeller);
    });
  });
}
