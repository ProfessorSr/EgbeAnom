part of '../main.dart';

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({
    required this.dailyMetrics,
    required this.products,
    required this.categories,
    required this.orders,
    required this.customers,
    required this.coupons,
    required this.paymentMethods,
    required this.shippingOptions,
    required this.contentBlocks,
    required this.reviews,
    required this.backendUsers,
    required this.conversionRate,
  });

  final List<DailyMetric> dailyMetrics;
  final List<Fragrance> products;
  final List<Category> categories;
  final List<Order> orders;
  final List<CustomerAccount> customers;
  final List<CouponRule> coupons;
  final List<PaymentMethodConfig> paymentMethods;
  final List<ShippingOption> shippingOptions;
  final List<ContentBlock> contentBlocks;
  final List<ReviewSummary> reviews;
  final List<BackendUser> backendUsers;
  final double conversionRate;

  @override
  Widget build(BuildContext context) {
    final metrics = AdminReportMetrics.from(
      dailyMetrics: dailyMetrics,
      products: products,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Traffic, customer growth, conversion, and catalog performance.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _AnalyticsPill(
                      label: 'Sessions',
                      value: '${metrics.totalVisits}',
                      trend:
                          '+${math.min(metrics.totalNewUsers, 9999)} new users',
                    ),
                    _AnalyticsPill(
                      label: 'Conversions',
                      value: '${conversionRate.toStringAsFixed(1)}%',
                      trend: '${metrics.totalOrders} orders',
                    ),
                    _AnalyticsPill(
                      label: 'Revenue',
                      value: currency(metrics.totalRevenue),
                      trend: '${currency(metrics.averageOrderValue)} avg order',
                    ),
                    _AnalyticsPill(
                      label: 'Audience',
                      value: '${customers.length}',
                      trend: 'registered customers',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.visibility_outlined,
              'Visits',
              '${metrics.totalVisits}',
            ),
            _MetricData(
              Icons.person_add_alt,
              'New users',
              '${metrics.totalNewUsers}',
            ),
            _MetricData(
              Icons.percent,
              'Conversion',
              '${conversionRate.toStringAsFixed(1)}%',
            ),
            _MetricData(
              Icons.people_alt_outlined,
              'Customers',
              '${customers.length}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DatabaseDownloadPanel(tables: _exportTables()),
        const SizedBox(height: 16),
        _TaxReportSummaryPanel(orders: orders),
        const SizedBox(height: 16),
        _SalesReportPanel(
          orders: orders,
          customers: customers,
          dailyMetrics: dailyMetrics,
        ),
        const SizedBox(height: 16),
        _RevenueReportPanel(
          orders: orders,
          products: products,
          dailyMetrics: dailyMetrics,
        ),
        const SizedBox(height: 16),
        _ExpenseReportPanel(orders: orders, products: products),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _DailyTrendPanel(metrics: dailyMetrics),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top fragrances',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          for (final product in metrics.topProducts.take(5))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox.square(
                                dimension: 42,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: ProductPhoto(product: product),
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                '${product.sold} sold • ${product.stock} on hand',
                              ),
                              trailing: Text(currency(product.price)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Map<String, List<Map<String, Object?>>> _exportTables() {
    return {
      'products': [
        for (final product in products)
          {
            'id': product.id,
            'sku': product.sku,
            'name': product.name,
            'brand': product.brand,
            'type': product.type,
            'price': product.price,
            'cost': product.cost,
            'stock': product.stock,
            'sold': product.sold,
            'is_active': product.isActive,
            'category_id': product.categoryId,
            'description': product.description,
          },
      ],
      'categories': [
        for (final category in categories)
          {
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'sort_order': category.sortOrder,
            'is_visible': category.isVisible,
          },
      ],
      'orders': [
        for (final order in orders)
          {
            'id': order.id,
            'customer': order.customer,
            'email': order.email,
            'status': order.status,
            'financial_status': order.financialStatus,
            'fulfillment_status': order.fulfillmentStatus,
            'total': order.total,
            'created_at': order.createdAt?.toIso8601String(),
          },
      ],
      'customers': [
        for (final customer in customers)
          {
            'id': customer.id,
            'name': customer.name,
            'email': customer.email,
            'segment': customer.segment,
            'orders': customer.orders,
            'lifetime_value': customer.lifetimeValue,
            'last_login_at': customer.lastLoginAt?.toIso8601String(),
            'created_at': customer.createdAt?.toIso8601String(),
            'last_login_ip': customer.lastLoginIp,
            'is_blocked': customer.isBlocked,
          },
      ],
      'coupon_rules': [
        for (final coupon in coupons)
          {
            'code': coupon.code,
            'name': coupon.name,
            'type': coupon.type,
            'value': coupon.value,
            'minimum_spend': coupon.minimumSpend,
            'usage_limit': coupon.usageLimit,
            'used': coupon.used,
            'buy_quantity': coupon.buyQuantity,
            'get_quantity': coupon.getQuantity,
            'get_price': coupon.getPrice,
            'remaining_balance': coupon.remainingBalance,
            'recipient_email': coupon.recipientEmail,
            'starts': coupon.starts,
            'ends': coupon.ends,
            'is_active': coupon.isActive,
            'is_archived': coupon.isArchived,
          },
      ],
      'payment_methods': [
        for (final method in paymentMethods)
          {
            'provider': method.provider,
            'name': method.name,
            'status': method.status,
            'is_enabled': method.isEnabled,
            'mode': method.mode,
          },
      ],
      'shipping_options': [
        for (final option in shippingOptions) option.toRow(),
      ],
      'content_blocks': [
        for (final block in contentBlocks)
          {
            'id': block.id,
            'title': block.title,
            'placement': block.placement,
            'body': block.body,
            'sort_order': block.sortOrder,
            'is_visible': block.isVisible,
          },
      ],
      'store_reviews': [
        for (final review in reviews)
          {
            'id': review.id,
            'product_id': review.productId,
            'author': review.author,
            'rating': review.rating,
            'title': review.title,
            'body': review.body,
            'status': review.status,
            'scope': review.scope,
          },
      ],
      'backend_users': [
        for (final user in backendUsers)
          {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role,
            'is_active': user.isActive,
            'is_blocked': user.isBlocked,
            'last_login_at': user.lastLoginAt?.toIso8601String(),
            'last_login_ip': user.lastLoginIp,
          },
      ],
      'daily_metrics': [
        for (final metric in dailyMetrics)
          {
            'day': metric.day,
            'visits': metric.visits,
            'orders': metric.orders,
            'new_users': metric.newUsers,
            'revenue': metric.revenue,
          },
      ],
    };
  }
}

class _AnalyticsPill extends StatelessWidget {
  const _AnalyticsPill({
    required this.label,
    required this.value,
    required this.trend,
  });

  final String label;
  final String value;
  final String trend;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2DCD2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(trend),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxReportSummaryPanel extends StatefulWidget {
  const _TaxReportSummaryPanel({required this.orders});

  final List<Order> orders;

  @override
  State<_TaxReportSummaryPanel> createState() => _TaxReportSummaryPanelState();
}

class _TaxReportSummaryPanelState extends State<_TaxReportSummaryPanel> {
  String _range = 'This year';

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders();
    final productRevenue = orders.fold(
      0.0,
      (sum, order) =>
          sum + order.lines.fold(0.0, (lineSum, line) => lineSum + line.total),
    );
    final shipping = orders.fold(
      0.0,
      (sum, order) => sum + order.shippingTotal,
    );
    final total = orders.fold(0.0, (sum, order) => sum + order.total);
    final tax = orders.fold(0.0, (sum, order) => sum + _orderTaxTotal(order));
    final cost = orders.fold(
      0.0,
      (sum, order) =>
          sum +
          order.lines.fold(
            0.0,
            (lineSum, line) => lineSum + line.product.cost * line.quantity,
          ),
    );
    final statusCounts = <String, int>{};
    for (final order in orders) {
      statusCounts.update(
        order.fulfillmentStatus,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tax and sales reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _RangeSelector(
                  value: _range,
                  onChanged: (value) => setState(() => _range = value),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Use this for period sales, estimated tax liability, shipping collected, COGS, and profit review.',
            ),
            const SizedBox(height: 14),
            _MetricGrid(
              metrics: [
                _MetricData(
                  Icons.receipt_long_outlined,
                  'Orders',
                  '${orders.length}',
                ),
                _MetricData(
                  Icons.sell_outlined,
                  'Product sales',
                  currency(productRevenue),
                  onTap: () => _showProductSalesBreakdown(context, orders),
                ),
                _MetricData(
                  Icons.request_quote_outlined,
                  'Tax collected',
                  currency(tax),
                  onTap: () => _showTaxBreakdown(context, orders),
                ),
                _MetricData(
                  Icons.local_shipping_outlined,
                  'Shipping collected',
                  currency(shipping),
                  onTap: () => _showShippingBreakdown(context, orders),
                ),
                _MetricData(
                  Icons.inventory_2_outlined,
                  'COGS estimate',
                  currency(cost),
                ),
                _MetricData(
                  Icons.savings_outlined,
                  'Profit estimate',
                  currency(total - tax - shipping - cost),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _printTaxReport(orders),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Print tax PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _printProductSalesReport(orders),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Print product sales'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _printShippingReport(orders),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Print shipping'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in statusCounts.entries)
                  Chip(
                    avatar: const Icon(Icons.local_activity_outlined, size: 16),
                    label: Text('${entry.key}: ${entry.value}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Order> _filteredOrders() {
    final cutoff = _cutoff();
    if (cutoff == null) return List.of(widget.orders);
    return widget.orders
        .where((order) => (order.createdAt ?? DateTime(1970)).isAfter(cutoff))
        .toList();
  }

  void _showTaxBreakdown(BuildContext context, List<Order> orders) {
    final rows = _taxBreakdownRows(orders);
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + (row['amount'] as double),
    );
    _showReportBreakdownDialog(
      context: context,
      title: 'Tax collected breakdown',
      subtitle: '${orders.length} order(s) • ${currency(total)} collected',
      columns: const ['Tax type', 'Jurisdiction', 'Rate', 'Amount'],
      rows: [
        for (final row in rows)
          [
            row['name'] as String,
            row['jurisdiction'] as String,
            row['rate'] as String,
            currency(row['amount'] as double),
          ],
      ],
      emptyMessage: 'No tax was collected for the selected period.',
    );
  }

  void _showProductSalesBreakdown(BuildContext context, List<Order> orders) {
    final rows = _productSalesRows(orders);
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + (row['revenue'] as double),
    );
    _showReportBreakdownDialog(
      context: context,
      title: 'Product sales breakdown',
      subtitle: '${orders.length} order(s) • ${currency(total)} product sales',
      columns: const ['Product', 'SKU', 'Qty', 'Sales'],
      rows: [
        for (final row in rows)
          [
            row['name'] as String,
            row['sku'] as String,
            '${row['quantity']}',
            currency(row['revenue'] as double),
          ],
      ],
      emptyMessage: 'No products were sold in the selected period.',
    );
  }

  void _showShippingBreakdown(BuildContext context, List<Order> orders) {
    final rows = _shippingBreakdownRows(orders);
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + (row['amount'] as double),
    );
    _showReportBreakdownDialog(
      context: context,
      title: 'Shipping collected breakdown',
      subtitle: '${orders.length} order(s) • ${currency(total)} collected',
      columns: const ['Carrier', 'Service', 'Orders', 'Collected'],
      rows: [
        for (final row in rows)
          [
            row['carrier'] as String,
            row['service'] as String,
            '${row['orders']}',
            currency(row['amount'] as double),
          ],
      ],
      emptyMessage: 'No shipping was collected for the selected period.',
    );
  }

  List<Map<String, Object>> _taxBreakdownRows(List<Order> orders) {
    final map = <String, Map<String, Object>>{};
    for (final order in orders) {
      for (final line in order.taxBreakdown) {
        if (line.amount <= 0) {
          continue;
        }
        final name = line.name.trim().isEmpty ? 'Tax' : line.name.trim();
        final jurisdiction = line.jurisdiction.trim().isEmpty
            ? 'Unspecified'
            : line.jurisdiction.trim();
        final key = '$name|$jurisdiction|${line.rate.toStringAsFixed(5)}';
        final existing = map[key];
        if (existing == null) {
          map[key] = {
            'name': name,
            'jurisdiction': jurisdiction,
            'rateValue': line.rate,
            'rate': '${(line.rate * 100).toStringAsFixed(3)}%',
            'amount': line.amount,
          };
        } else {
          existing['amount'] = (existing['amount'] as double) + line.amount;
        }
      }
    }
    final rows = map.values.toList()
      ..sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );
    return rows;
  }

  List<Map<String, Object>> _productSalesRows(List<Order> orders) {
    final map = <String, Map<String, Object>>{};
    for (final order in orders) {
      for (final line in order.lines) {
        final sku = line.sku.trim().isEmpty ? 'No SKU' : line.sku.trim();
        final name = line.product.name.trim().isEmpty
            ? 'Product'
            : line.product.name.trim();
        final key = '${line.product.id}|$sku|$name';
        final existing = map[key];
        if (existing == null) {
          map[key] = {
            'name': name,
            'sku': sku,
            'quantity': line.quantity,
            'revenue': line.total,
          };
        } else {
          existing['quantity'] = (existing['quantity'] as int) + line.quantity;
          existing['revenue'] = (existing['revenue'] as double) + line.total;
        }
      }
    }
    final rows = map.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );
    return rows;
  }

  List<Map<String, Object>> _shippingBreakdownRows(List<Order> orders) {
    final map = <String, Map<String, Object>>{};
    for (final order in orders) {
      if (order.shippingTotal <= 0) {
        continue;
      }
      final carrier = order.shippingCarrier.trim().isEmpty
          ? 'Unspecified'
          : order.shippingCarrier.trim();
      final serviceParts = [
        order.shippingService.trim(),
        order.shippingPriority.trim(),
      ].where((part) => part.isNotEmpty).toList();
      final service = serviceParts.isEmpty
          ? 'Unspecified'
          : serviceParts.join(' • ');
      final key = '$carrier|$service';
      final existing = map[key];
      if (existing == null) {
        map[key] = {
          'carrier': carrier,
          'service': service,
          'orders': 1,
          'amount': order.shippingTotal,
        };
      } else {
        existing['orders'] = (existing['orders'] as int) + 1;
        existing['amount'] =
            (existing['amount'] as double) + order.shippingTotal;
      }
    }
    final rows = map.values.toList()
      ..sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );
    return rows;
  }

  void _showReportBreakdownDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<String> columns,
    required List<List<String>> rows,
    required String emptyMessage,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subtitle),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Text(emptyMessage)
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        for (final column in columns)
                          DataColumn(label: Text(column)),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              for (final value in row) DataCell(Text(value)),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _printTaxReport(List<Order> orders) {
    final rows = [
      for (final row in _taxBreakdownRows(orders))
        [
          row['name'] as String,
          row['jurisdiction'] as String,
          row['rate'] as String,
          currency(row['amount'] as double),
        ],
    ];
    _printSpreadsheetReport(
      title: 'Tax collected report',
      subtitle: '${orders.length} order(s)',
      columns: const ['Tax type', 'Jurisdiction', 'Rate', 'Amount'],
      rows: rows,
    );
  }

  void _printProductSalesReport(List<Order> orders) {
    final rows = [
      for (final row in _productSalesRows(orders))
        [
          row['name'] as String,
          row['sku'] as String,
          '${row['quantity']}',
          currency(row['revenue'] as double),
        ],
    ];
    _printSpreadsheetReport(
      title: 'Product sales report',
      subtitle: '${orders.length} order(s)',
      columns: const ['Product', 'SKU', 'Qty', 'Sales'],
      rows: rows,
    );
  }

  void _printShippingReport(List<Order> orders) {
    final rows = [
      for (final row in _shippingBreakdownRows(orders))
        [
          row['carrier'] as String,
          row['service'] as String,
          '${row['orders']}',
          currency(row['amount'] as double),
        ],
    ];
    _printSpreadsheetReport(
      title: 'Shipping collected report',
      subtitle: '${orders.length} order(s)',
      columns: const ['Carrier', 'Service', 'Orders', 'Collected'],
      rows: rows,
    );
  }

  void _printSpreadsheetReport({
    required String title,
    required String subtitle,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    final generated = DateTime.now();
    final headerCells = columns
        .map((column) => '<th>${htmlEscape.convert(column)}</th>')
        .join();
    final bodyRows = rows.isEmpty
        ? '<tr><td colspan="${columns.length}">No rows for this report.</td></tr>'
        : rows
              .map(
                (row) =>
                    '<tr>${row.map((value) => '<td>${htmlEscape.convert(value)}</td>').join()}</tr>',
              )
              .join();
    final html =
        '''
<style>
  @page { size: letter; margin: 0.45in; }
  body { font-family: Arial, sans-serif; color: #1f1f1f; }
  h1 { margin: 0 0 4px; font-size: 22px; }
  .meta { margin-bottom: 16px; color: #555; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; font-size: 11px; }
  th, td { border: 1px solid #222; padding: 6px 7px; text-align: left; vertical-align: top; }
  th { background: #f2f2f2; font-weight: 700; }
  td:last-child, th:last-child { text-align: right; }
</style>
<h1>${htmlEscape.convert(title)}</h1>
<div class="meta">${htmlEscape.convert(subtitle)} | Generated ${generated.month}/${generated.day}/${generated.year}</div>
<table>
  <thead><tr>$headerCells</tr></thead>
  <tbody>$bodyRows</tbody>
</table>
''';
    printHtmlDocument(title, html);
  }

  DateTime? _cutoff() {
    final now = DateTime.now();
    return switch (_range) {
      '7 days' => now.subtract(const Duration(days: 7)),
      '30 days' => now.subtract(const Duration(days: 30)),
      '90 days' => now.subtract(const Duration(days: 90)),
      'This year' => DateTime(now.year),
      _ => null,
    };
  }
}

class _SalesReportPanel extends StatefulWidget {
  const _SalesReportPanel({
    required this.orders,
    required this.customers,
    required this.dailyMetrics,
  });

  final List<Order> orders;
  final List<CustomerAccount> customers;
  final List<DailyMetric> dailyMetrics;

  @override
  State<_SalesReportPanel> createState() => _SalesReportPanelState();
}

class _SalesReportPanelState extends State<_SalesReportPanel> {
  String _range = '30 days';

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders();
    final topCustomers = _topCustomersByOrders();
    final avgOrderValue = filteredOrders.isEmpty
        ? 0.0
        : filteredOrders.fold<double>(0, (sum, order) => sum + order.total) /
              filteredOrders.length;
    final repeatCustomers = _repeatCustomerCount();
    final newCustomers = filteredOrders.where((order) {
      final customer = widget.customers
          .cast<CustomerAccount?>()
          .fold<CustomerAccount?>(
            null,
            (prev, c) => c != null && c.email == order.email ? c : prev,
          );
      return customer?.orders == 1;
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sales Report',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _range,
                          decoration: const InputDecoration(
                            labelText: 'Period',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '7 days',
                              child: Text('7 days'),
                            ),
                            DropdownMenuItem(
                              value: '30 days',
                              child: Text('30 days'),
                            ),
                            DropdownMenuItem(
                              value: '90 days',
                              child: Text('90 days'),
                            ),
                            DropdownMenuItem(
                              value: 'This year',
                              child: Text('This year'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _range = value ?? _range),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Print or save PDF',
                        onPressed: _printSalesReport,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricGrid(
              metrics: [
                _MetricData(
                  Icons.shopping_cart_outlined,
                  'Total orders',
                  '${filteredOrders.length}',
                ),
                _MetricData(
                  Icons.attach_money_outlined,
                  'Avg order value',
                  currency(avgOrderValue),
                ),
                _MetricData(
                  Icons.people_alt_outlined,
                  'Repeat customers',
                  '$repeatCustomers',
                ),
                _MetricData(
                  Icons.person_add_alt_outlined,
                  'New customers',
                  '$newCustomers',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Top customers by orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final entry in topCustomers.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry['email'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${entry['orderCount']} orders'),
                    Text(
                      currency(entry['totalSpent'] as double),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Order> _filteredOrders() {
    final cutoff = _cutoff();
    if (cutoff == null) return List.of(widget.orders);
    return widget.orders
        .where((order) => (order.createdAt ?? DateTime(1970)).isAfter(cutoff))
        .toList();
  }

  List<Map<String, dynamic>> _topCustomersByOrders() {
    final filtered = _filteredOrders();
    final map = <String, Map<String, dynamic>>{};
    for (final order in filtered) {
      final email = order.email;
      if (map.containsKey(email)) {
        map[email]!['orderCount']++;
        map[email]!['totalSpent'] += order.total;
      } else {
        map[email] = {
          'email': email,
          'orderCount': 1,
          'totalSpent': order.total,
        };
      }
    }
    final sorted = map.values.toList()
      ..sort(
        (a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int),
      );
    return sorted;
  }

  int _repeatCustomerCount() {
    final emails = _filteredOrders().map((o) => o.email).toList();
    final emailCounts = <String, int>{};
    for (final email in emails) {
      emailCounts[email] = (emailCounts[email] ?? 0) + 1;
    }
    return emailCounts.values.where((count) => count > 1).length;
  }

  void _printSalesReport() {
    final rows = [
      for (final order in _filteredOrders())
        [
          order.id,
          order.createdAt == null
              ? ''
              : '${order.createdAt!.month}/${order.createdAt!.day}/${order.createdAt!.year}',
          order.customer,
          order.email,
          order.financialStatus,
          order.fulfillmentStatus,
          currency(order.total),
        ],
    ];
    final headerCells = const [
      'Order',
      'Date',
      'Customer',
      'Email',
      'Payment',
      'Status',
      'Total',
    ].map((column) => '<th>${htmlEscape.convert(column)}</th>').join();
    final bodyRows = rows.isEmpty
        ? '<tr><td colspan="7">No sales for this period.</td></tr>'
        : rows
              .map(
                (row) =>
                    '<tr>${row.map((value) => '<td>${htmlEscape.convert(value)}</td>').join()}</tr>',
              )
              .join();
    final generated = DateTime.now();
    final html =
        '''
<style>
  @page { size: letter landscape; margin: 0.45in; }
  body { font-family: Arial, sans-serif; color: #1f1f1f; }
  h1 { margin: 0 0 4px; font-size: 22px; }
  .meta { margin-bottom: 16px; color: #555; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; font-size: 10.5px; }
  th, td { border: 1px solid #222; padding: 6px 7px; text-align: left; vertical-align: top; }
  th { background: #f2f2f2; font-weight: 700; }
  td:last-child, th:last-child { text-align: right; }
</style>
<h1>Sales report</h1>
<div class="meta">${htmlEscape.convert(_range)} | Generated ${generated.month}/${generated.day}/${generated.year}</div>
<table>
  <thead><tr>$headerCells</tr></thead>
  <tbody>$bodyRows</tbody>
</table>
''';
    printHtmlDocument('Egbe Anom sales report', html);
  }

  DateTime? _cutoff() {
    final now = DateTime.now();
    return switch (_range) {
      '7 days' => now.subtract(const Duration(days: 7)),
      '30 days' => now.subtract(const Duration(days: 30)),
      '90 days' => now.subtract(const Duration(days: 90)),
      'This year' => DateTime(now.year),
      _ => null,
    };
  }
}

class _RevenueReportPanel extends StatefulWidget {
  const _RevenueReportPanel({
    required this.orders,
    required this.products,
    required this.dailyMetrics,
  });

  final List<Order> orders;
  final List<Fragrance> products;
  final List<DailyMetric> dailyMetrics;

  @override
  State<_RevenueReportPanel> createState() => _RevenueReportPanelState();
}

class _RevenueReportPanelState extends State<_RevenueReportPanel> {
  String _range = '30 days';

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders();
    final totalRevenue = filteredOrders.fold<double>(
      0,
      (sum, o) => sum + o.total,
    );
    final topProducts = _topProductsByRevenue();
    final byStatus = _revenueByStatus();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Revenue Report',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _range,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: const [
                      DropdownMenuItem(value: '7 days', child: Text('7 days')),
                      DropdownMenuItem(
                        value: '30 days',
                        child: Text('30 days'),
                      ),
                      DropdownMenuItem(
                        value: '90 days',
                        child: Text('90 days'),
                      ),
                      DropdownMenuItem(
                        value: 'This year',
                        child: Text('This year'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _range = value ?? _range),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricGrid(
              metrics: [
                _MetricData(
                  Icons.attach_money_outlined,
                  'Total revenue',
                  currency(totalRevenue),
                ),
                _MetricData(
                  Icons.trending_up_outlined,
                  'Avg per order',
                  currency(
                    filteredOrders.isEmpty
                        ? 0
                        : totalRevenue / filteredOrders.length,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Revenue by status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final entry in byStatus.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      currency(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Top products by revenue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final entry in topProducts.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry['name'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${entry['quantity']} sold'),
                    Text(
                      currency(entry['revenue'] as double),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Order> _filteredOrders() {
    final cutoff = _cutoff();
    if (cutoff == null) return List.of(widget.orders);
    return widget.orders
        .where((order) => (order.createdAt ?? DateTime(1970)).isAfter(cutoff))
        .toList();
  }

  List<Map<String, dynamic>> _topProductsByRevenue() {
    final filtered = _filteredOrders();
    final map = <int, Map<String, dynamic>>{};
    for (final order in filtered) {
      for (final line in order.lines) {
        final productId = line.product.id;
        if (map.containsKey(productId)) {
          map[productId]!['quantity'] += line.quantity;
          map[productId]!['revenue'] += line.product.price * line.quantity;
        } else {
          map[productId] = {
            'name': line.product.name,
            'quantity': line.quantity,
            'revenue': line.product.price * line.quantity,
          };
        }
      }
    }
    final sorted = map.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );
    return sorted;
  }

  Map<String, double> _revenueByStatus() {
    final filtered = _filteredOrders();
    final map = <String, double>{};
    for (final order in filtered) {
      final status = order.status;
      map[status] = (map[status] ?? 0) + order.total;
    }
    return map;
  }

  DateTime? _cutoff() {
    final now = DateTime.now();
    return switch (_range) {
      '7 days' => now.subtract(const Duration(days: 7)),
      '30 days' => now.subtract(const Duration(days: 30)),
      '90 days' => now.subtract(const Duration(days: 90)),
      'This year' => DateTime(now.year),
      _ => null,
    };
  }
}

class _ExpenseReportPanel extends StatefulWidget {
  const _ExpenseReportPanel({required this.orders, required this.products});

  final List<Order> orders;
  final List<Fragrance> products;

  @override
  State<_ExpenseReportPanel> createState() => _ExpenseReportPanelState();
}

class _ExpenseReportPanelState extends State<_ExpenseReportPanel> {
  String _range = '30 days';

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders();
    final cogs = _costOfGoodsSold();
    final estimatedShipping = _estimatedShippingCosts();
    final totalExpense = cogs + estimatedShipping;
    final totalRevenue = filteredOrders.fold<double>(
      0,
      (sum, o) => sum + o.total,
    );
    final grossMargin = totalRevenue - totalExpense;
    final marginPercent = totalRevenue == 0
        ? 0
        : (grossMargin / totalRevenue) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Expense Report',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _range,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: const [
                      DropdownMenuItem(value: '7 days', child: Text('7 days')),
                      DropdownMenuItem(
                        value: '30 days',
                        child: Text('30 days'),
                      ),
                      DropdownMenuItem(
                        value: '90 days',
                        child: Text('90 days'),
                      ),
                      DropdownMenuItem(
                        value: 'This year',
                        child: Text('This year'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _range = value ?? _range),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricGrid(
              metrics: [
                _MetricData(Icons.inventory_2_outlined, 'COGS', currency(cogs)),
                _MetricData(
                  Icons.local_shipping_outlined,
                  'Est. shipping',
                  currency(estimatedShipping),
                ),
                _MetricData(
                  Icons.trending_down_outlined,
                  'Total expenses',
                  currency(totalExpense),
                ),
                _MetricData(
                  Icons.savings_outlined,
                  'Gross margin',
                  '${marginPercent.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gross profit (Revenue - COGS - Shipping)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currency(grossMargin),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Order> _filteredOrders() {
    final cutoff = _cutoff();
    if (cutoff == null) return List.of(widget.orders);
    return widget.orders
        .where((order) => (order.createdAt ?? DateTime(1970)).isAfter(cutoff))
        .toList();
  }

  double _costOfGoodsSold() {
    final filtered = _filteredOrders();
    double total = 0;
    for (final order in filtered) {
      for (final line in order.lines) {
        total += line.product.cost * line.quantity;
      }
    }
    return total;
  }

  double _estimatedShippingCosts() {
    final filtered = _filteredOrders();
    double total = 0;
    for (final order in filtered) {
      total += order.shippingTotal;
    }
    return total;
  }

  DateTime? _cutoff() {
    final now = DateTime.now();
    return switch (_range) {
      '7 days' => now.subtract(const Duration(days: 7)),
      '30 days' => now.subtract(const Duration(days: 30)),
      '90 days' => now.subtract(const Duration(days: 90)),
      'This year' => DateTime(now.year),
      _ => null,
    };
  }
}

class _DatabaseDownloadPanel extends StatefulWidget {
  const _DatabaseDownloadPanel({required this.tables});

  final Map<String, List<Map<String, Object?>>> tables;

  @override
  State<_DatabaseDownloadPanel> createState() => _DatabaseDownloadPanelState();
}

class _DatabaseDownloadPanelState extends State<_DatabaseDownloadPanel> {
  late final Set<String> _selected = widget.tables.keys.toSet();
  String _format = 'CSV';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Download database',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _format,
                    decoration: const InputDecoration(labelText: 'Format'),
                    items: const [
                      DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                      DropdownMenuItem(value: 'JSON', child: Text('JSON')),
                      DropdownMenuItem(value: 'SQL', child: Text('SQL')),
                    ],
                    onChanged: (value) =>
                        setState(() => _format = value ?? _format),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in widget.tables.entries)
                  FilterChip(
                    label: Text('${entry.key} (${entry.value.length})'),
                    selected: _selected.contains(entry.key),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(entry.key);
                        } else {
                          _selected.remove(entry.key);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _download,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download selected tables'),
            ),
          ],
        ),
      ),
    );
  }

  void _download() {
    final selectedTables = {
      for (final table in _selected) table: widget.tables[table] ?? [],
    };
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    if (_format == 'CSV') {
      for (final entry in selectedTables.entries) {
        downloadTextFile(
          fileName: 'egbeanom-${entry.key}-$stamp.csv',
          contents: _toCsvTable(entry.key, entry.value),
          mimeType: 'text/csv',
        );
      }
      return;
    }
    final lower = _format.toLowerCase();
    final contents = switch (_format) {
      'JSON' => const JsonEncoder.withIndent('  ').convert(selectedTables),
      'SQL' => _toSql(selectedTables),
      _ => '',
    };
    downloadTextFile(
      fileName: 'egbeanom-database-$stamp.$lower',
      contents: contents,
      mimeType: switch (_format) {
        'JSON' => 'application/json',
        'SQL' => 'application/sql',
        _ => 'text/plain',
      },
    );
  }

  String _toCsvTable(String table, List<Map<String, Object?>> rows) {
    final buffer = StringBuffer();
    buffer.writeln('# $table');
    final columns = _columns(rows);
    buffer.writeln(columns.map(_csvCell).join(','));
    for (final row in rows) {
      buffer.writeln(
        columns.map((column) => _csvCell('${row[column] ?? ''}')).join(','),
      );
    }
    return buffer.toString();
  }

  String _toSql(Map<String, List<Map<String, Object?>>> tables) {
    final buffer = StringBuffer();
    for (final entry in tables.entries) {
      final columns = _columns(entry.value);
      for (final row in entry.value) {
        final values = columns
            .map((column) => _sqlValue(row[column]))
            .join(',');
        buffer.writeln(
          'insert into ${entry.key} (${columns.join(',')}) values ($values);',
        );
      }
    }
    return buffer.toString();
  }

  List<String> _columns(List<Map<String, Object?>> rows) {
    final columns = <String>{};
    for (final row in rows) {
      columns.addAll(row.keys);
    }
    return columns.toList();
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  String _sqlValue(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is num || value is bool) {
      return '$value';
    }
    return "'${'$value'.replaceAll("'", "''")}'";
  }
}

class _DailyTrendPanel extends StatelessWidget {
  const _DailyTrendPanel({required this.metrics});

  final List<DailyMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = metrics.fold(0.0, (max, metric) {
      return metric.revenue > max ? metric.revenue : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily marketplace performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            for (final metric in metrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 42, child: Text(metric.day)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: maxRevenue == 0
                              ? 0
                              : metric.revenue / maxRevenue,
                          backgroundColor: const Color(0xFFE8E1D6),
                          color: const Color(0xFFC88F52),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 190,
                      child: Text(
                        '${currency(metric.revenue)} • ${metric.newUsers} new • ${metric.orders} orders',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  const _LowStockPanel({required this.products});

  final List<Fragrance> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reorder watchlist',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (products.isEmpty)
              const Text('No products are below reorder point.')
            else
              for (final product in products)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber_outlined,
                    color: Color(0xFFC88F52),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.stock} on hand • reorder at ${product.reorderPoint}',
                  ),
                  trailing: Text(product.vendor),
                ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFC88F52)),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.open_in_new, size: 16),
              ],
            ],
          ),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: _SparklineChart(
              values: [
                label.length.toDouble(),
                value.length.toDouble() + 2,
                icon.codePoint % 11 + 4,
                (label.codeUnitAt(0) % 13) + 3,
                value.codeUnitAt(0) % 15 + 5,
              ],
            ),
          ),
        ],
      ),
    );
    return Card(
      clipBehavior: onTap == null ? Clip.none : Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(values),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = math.max(1, maxValue - minValue);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minValue) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF27724E)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}
