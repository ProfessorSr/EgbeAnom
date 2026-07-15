part of '../main.dart';

class _AnalyticsSection extends StatefulWidget {
  const _AnalyticsSection({
    required this.sessions,
    required this.dailyMetrics,
    required this.products,
    required this.orders,
    required this.reviews,
    required this.events,
    required this.activeCarts,
    required this.conversionRate,
    required this.onOpenSection,
  });

  final List<ActiveUserSession> sessions;
  final List<DailyMetric> dailyMetrics;
  final List<Fragrance> products;
  final List<Order> orders;
  final List<ReviewSummary> reviews;
  final List<AnalyticsEvent> events;
  final List<ActiveCart> activeCarts;
  final double conversionRate;
  final ValueChanged<AdminSection> onOpenSection;

  @override
  State<_AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<_AnalyticsSection> {
  String _salesRange = '30 days';
  String _trafficRange = '7 days';
  String _productRange = '90 days';
  String _reportRange = 'This year';

  @override
  Widget build(BuildContext context) {
    final salesOrders = _filterOrders(widget.orders, _salesRange);
    final trafficMetrics = _filterMetrics(widget.dailyMetrics, _trafficRange);
    final trafficEvents = _filterEvents(widget.events, _trafficRange);
    final productOrders = _filterOrders(widget.orders, _productRange);
    final reportOrders = _filterOrders(widget.orders, _reportRange);
    final visits = trafficMetrics.fold(0, (sum, metric) => sum + metric.visits);
    final revenue = salesOrders.fold(0.0, (sum, order) => sum + order.total);
    final topProducts = _rankProducts(productOrders);
    final hourly = _salesByHour(salesOrders);
    final monthly = _salesByMonth(reportOrders);
    final taxCollected = reportOrders.fold(
      0.0,
      (sum, order) => sum + _orderTaxTotal(order),
    );
    final averageOrder = salesOrders.isEmpty
        ? 0.0
        : revenue / salesOrders.length;
    final sourceCounts = <String, double>{};
    final sourceRows = trafficEvents.isNotEmpty ? trafficEvents : null;
    if (sourceRows == null) {
      for (final session in widget.sessions) {
        sourceCounts.update(
          session.source,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    } else {
      for (final event in sourceRows) {
        sourceCounts.update(
          event.source,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final pageCounts = <String, double>{};
    if (trafficEvents.isEmpty) {
      for (final session in widget.sessions) {
        pageCounts.update(
          session.currentPage,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    } else {
      for (final event in trafficEvents.where(
        (event) => event.eventName == 'page_view',
      )) {
        pageCounts.update(event.page, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final deviceCounts = <String, double>{};
    final referrerCounts = <String, double>{};
    if (trafficEvents.isEmpty) {
      for (final session in widget.sessions) {
        deviceCounts.update(
          session.device,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        final referrer = session.referrer.trim().isEmpty
            ? 'Direct'
            : session.referrer;
        referrerCounts.update(
          referrer,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    } else {
      for (final event in trafficEvents) {
        deviceCounts.update(
          event.device,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        final referrer = event.referrer.trim().isEmpty
            ? 'Direct'
            : event.referrer;
        referrerCounts.update(
          referrer,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    var totalActiveMinutes = 0;
    var engagedSessions = 0;
    for (final session in widget.sessions) {
      totalActiveMinutes += session.minutesActive;
      if (session.minutesActive >= 1 || session.currentPage != 'shop') {
        engagedSessions += 1;
      }
    }
    final newUsers = trafficMetrics.fold(
      0,
      (sum, metric) => sum + metric.newUsers,
    );
    final pageViews = trafficEvents
        .where((event) => event.eventName == 'page_view')
        .length;
    final views = pageViews > 0 ? pageViews : visits + widget.sessions.length;
    final viewsPerVisit = visits == 0 ? 0.0 : views / visits;
    final engagementRate = widget.sessions.isEmpty
        ? 0.0
        : engagedSessions / widget.sessions.length * 100;
    final averageEngagement = widget.sessions.isEmpty
        ? 0.0
        : totalActiveMinutes / widget.sessions.length;
    final eventCount = trafficEvents.isNotEmpty
        ? trafficEvents.length
        : visits +
              salesOrders.length +
              widget.activeCarts.fold(0, (sum, cart) => sum + cart.itemCount) +
              widget.sessions.length;
    final trafficByDay = trafficMetrics
        .map((metric) => ChartPoint(metric.day, metric.visits.toDouble()))
        .toList();
    final newUsersByDay = trafficMetrics
        .map((metric) => ChartPoint(metric.day, metric.newUsers.toDouble()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'First-party analytics modeled after Google Analytics reports: realtime, acquisition, engagement, pages, ecommerce, devices, and conversions.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.visibility_outlined,
              'Users online',
              '${widget.sessions.length}',
            ),
            _MetricData(Icons.ads_click_outlined, 'Visits', '$visits'),
            _MetricData(Icons.person_add_alt, 'New users', '$newUsers'),
            _MetricData(
              Icons.web_stories_outlined,
              trafficEvents.isEmpty ? 'Views estimate' : 'Views',
              '$views',
            ),
            _MetricData(
              Icons.repeat_outlined,
              'Views / visit',
              viewsPerVisit.toStringAsFixed(2),
            ),
            _MetricData(
              Icons.timer_outlined,
              'Avg engagement',
              '${averageEngagement.toStringAsFixed(1)} min',
            ),
            _MetricData(
              Icons.touch_app_outlined,
              trafficEvents.isEmpty ? 'Event estimate' : 'Events',
              '$eventCount',
            ),
            _MetricData(
              Icons.percent_outlined,
              'Conversion',
              '${widget.conversionRate.toStringAsFixed(1)}%',
            ),
            _MetricData(
              Icons.payments_outlined,
              'Tracked revenue',
              currency(revenue),
            ),
            _MetricData(
              Icons.shopping_cart_outlined,
              'Open carts',
              '${widget.activeCarts.length}',
            ),
            _MetricData(
              Icons.receipt_long_outlined,
              'Orders',
              '${salesOrders.length}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 980;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _ChartCard(
                    title: 'Traffic over time',
                    subtitle: 'GA-style users/sessions trend',
                    trailing: _RangeSelector(
                      value: _trafficRange,
                      onChanged: (value) =>
                          setState(() => _trafficRange = value),
                    ),
                    child: _MiniBarChart(points: trafficByDay),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _ChartCard(
                    title: 'New users',
                    subtitle: 'New customer/user acquisition trend',
                    trailing: _RangeSelector(
                      value: _trafficRange,
                      onChanged: (value) =>
                          setState(() => _trafficRange = value),
                    ),
                    child: _MiniBarChart(
                      points: newUsersByDay,
                      color: const Color(0xFF27724E),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _GoogleAnalyticsReportGrid(
          sourceCounts: sourceCounts,
          pageCounts: pageCounts,
          deviceCounts: deviceCounts,
          referrerCounts: referrerCounts,
          engagementRate: engagementRate,
          viewsPerVisit: viewsPerVisit,
        ),
        const SizedBox(height: 16),
        _AnalyticsInsightGrid(
          range: _salesRange,
          onRangeChanged: (value) => setState(() => _salesRange = value),
          revenue: revenue,
          averageOrder: averageOrder,
          taxCollected: taxCollected,
          orders: salesOrders.length,
          conversionRate: widget.conversionRate,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 980;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 7 : 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live user tracking',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          if (widget.sessions.isEmpty)
                            const Text('No active users recorded yet.')
                          else
                            for (final session in widget.sessions)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.person_pin_circle_outlined,
                                ),
                                title: Text(
                                  '${session.visitor} • ${session.currentPage}',
                                ),
                                subtitle: Text(
                                  '${session.source} from ${session.referrer} • ${session.device} • active ${session.minutesActive} min',
                                ),
                                trailing: Text(
                                  '${session.secondsSinceSeen}s ago',
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 5 : 0,
                  child: Column(
                    children: [
                      _ChartCard(
                        title: 'Traffic sources',
                        subtitle: 'Search, direct, social, referral',
                        trailing: _RangeSelector(
                          value: _trafficRange,
                          onChanged: (value) =>
                              setState(() => _trafficRange = value),
                        ),
                        child: _MiniBarChart(
                          points: sourceCounts.entries
                              .map(
                                (entry) => ChartPoint(entry.key, entry.value),
                              )
                              .toList(),
                          color: const Color(0xFF27724E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ChartCard(
                        title: 'Pages being viewed',
                        subtitle: 'Current active page distribution',
                        child: _MiniBarChart(
                          points: pageCounts.entries
                              .map(
                                (entry) => ChartPoint(entry.key, entry.value),
                              )
                              .toList(),
                          color: const Color(0xFF5A6FA8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 980;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _ChartCard(
                    title: 'When sales happen',
                    subtitle: 'Time-of-day sales analysis',
                    trailing: _RangeSelector(
                      value: _salesRange,
                      onChanged: (value) => setState(() => _salesRange = value),
                    ),
                    child: _MiniBarChart(
                      points: hourly.entries
                          .map((entry) => ChartPoint(entry.key, entry.value))
                          .toList(),
                      color: const Color(0xFFC88F52),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _ChartCard(
                    title: 'Seasonal sales',
                    subtitle: 'Month-by-month revenue',
                    trailing: _RangeSelector(
                      value: _reportRange,
                      onChanged: (value) =>
                          setState(() => _reportRange = value),
                    ),
                    child: _MiniBarChart(
                      points: monthly.entries
                          .map((entry) => ChartPoint(entry.key, entry.value))
                          .toList(),
                      color: const Color(0xFF5A6FA8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _ProductAnalyticsCard(
          products: widget.products,
          rankedProducts: topProducts,
          range: _productRange,
          onRangeChanged: (value) => setState(() => _productRange = value),
        ),
        const SizedBox(height: 16),
        _DashboardChartGrid(
          products: widget.products,
          dailyMetrics: trafficMetrics,
          activeCarts: widget.activeCarts,
          onOpenSection: widget.onOpenSection,
        ),
        const SizedBox(height: 16),
        _CommerceDashboardPanels(
          products: widget.products,
          metrics: trafficMetrics,
          activeCarts: widget.activeCarts,
          sessions: widget.sessions,
          orders: widget.orders,
          reviews: widget.reviews,
          onOpenSection: widget.onOpenSection,
        ),
      ],
    );
  }

  List<Order> _filterOrders(List<Order> orders, String range) {
    final cutoff = _cutoff(range);
    if (cutoff == null) return List.of(orders);
    return orders
        .where((order) => (order.createdAt ?? DateTime(1970)).isAfter(cutoff))
        .toList();
  }

  List<DailyMetric> _filterMetrics(List<DailyMetric> metrics, String range) {
    final cutoff = _cutoff(range);
    if (cutoff == null) return List.of(metrics);
    return metrics.where((metric) {
      final parsed = DateTime.tryParse(metric.day);
      return parsed == null || parsed.isAfter(cutoff);
    }).toList();
  }

  List<AnalyticsEvent> _filterEvents(
    List<AnalyticsEvent> events,
    String range,
  ) {
    final cutoff = _cutoff(range);
    if (cutoff == null) return List.of(events);
    return events.where((event) => event.occurredAt.isAfter(cutoff)).toList();
  }

  DateTime? _cutoff(String range) {
    final now = DateTime.now();
    return switch (range) {
      '7 days' => now.subtract(const Duration(days: 7)),
      '30 days' => now.subtract(const Duration(days: 30)),
      '90 days' => now.subtract(const Duration(days: 90)),
      'This year' => DateTime(now.year),
      _ => null,
    };
  }

  List<_ProductSalesRank> _rankProducts(List<Order> orders) {
    final rows = <String, _ProductSalesRank>{};
    for (final order in orders) {
      for (final line in order.lines) {
        final productId = line.product.id.toString();
        final existing = rows[productId];
        if (existing == null) {
          rows[productId] = _ProductSalesRank(
            product: line.product,
            units: line.quantity,
            revenue: line.total,
          );
        } else {
          existing.units += line.quantity;
          existing.revenue += line.total;
        }
      }
    }
    final ranked = rows.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    if (ranked.isNotEmpty) return ranked;
    return [
      for (final product in widget.products)
        _ProductSalesRank(
          product: product,
          units: product.sold,
          revenue: product.sold * product.price,
        ),
    ]..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  Map<String, double> _salesByHour(List<Order> orders) {
    final buckets = {
      '12a': 0.0,
      '3a': 0.0,
      '6a': 0.0,
      '9a': 0.0,
      '12p': 0.0,
      '3p': 0.0,
      '6p': 0.0,
      '9p': 0.0,
    };
    for (final order in orders) {
      final hour = order.createdAt?.hour ?? 12;
      final key = switch (hour) {
        < 3 => '12a',
        < 6 => '3a',
        < 9 => '6a',
        < 12 => '9a',
        < 15 => '12p',
        < 18 => '3p',
        < 21 => '6p',
        _ => '9p',
      };
      buckets[key] = (buckets[key] ?? 0) + order.total;
    }
    return buckets;
  }

  Map<String, double> _salesByMonth(List<Order> orders) {
    final labels = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final buckets = {for (final label in labels) label: 0.0};
    for (final order in orders) {
      final created = order.createdAt;
      if (created == null) continue;
      final key = labels[created.month - 1];
      buckets[key] = (buckets[key] ?? 0) + order.total;
    }
    return buckets;
  }
}

class _GoogleAnalyticsReportGrid extends StatelessWidget {
  const _GoogleAnalyticsReportGrid({
    required this.sourceCounts,
    required this.pageCounts,
    required this.deviceCounts,
    required this.referrerCounts,
    required this.engagementRate,
    required this.viewsPerVisit,
  });

  final Map<String, double> sourceCounts;
  final Map<String, double> pageCounts;
  final Map<String, double> deviceCounts;
  final Map<String, double> referrerCounts;
  final double engagementRate;
  final double viewsPerVisit;

  @override
  Widget build(BuildContext context) {
    final sourcePoints = _rankedPoints(sourceCounts);
    final pagePoints = _rankedPoints(pageCounts);
    final devicePoints = _rankedPoints(deviceCounts);
    final referrerRows = _rankedPoints(referrerCounts)
        .take(6)
        .map((point) => '${point.label} • ${point.value.toStringAsFixed(0)}')
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 980;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _ChartCard(
                    title: 'Traffic acquisition',
                    subtitle: 'Session source mix like GA acquisition',
                    child: _MiniBarChart(
                      points: sourcePoints,
                      color: const Color(0xFF27724E),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _ChartCard(
                    title: 'Pages and screens',
                    subtitle: 'Tracked page view distribution',
                    child: _MiniBarChart(
                      points: pagePoints,
                      color: const Color(0xFF5A6FA8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _ChartCard(
                    title: 'Tech details',
                    subtitle: 'Device categories from live sessions',
                    child: _MiniBarChart(
                      points: devicePoints,
                      color: const Color(0xFFC88F52),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _MiniTableCard(
                    title: 'Top referrers',
                    action: 'Analytics',
                    rows: referrerRows,
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _MiniTableCard(
                    title: 'Engagement summary',
                    action: 'Analytics',
                    rows: [
                      'Engagement rate estimate: ${engagementRate.toStringAsFixed(1)}%',
                      'Views per visit: ${viewsPerVisit.toStringAsFixed(2)}',
                      'Tracked events feed ecommerce and page reports.',
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<ChartPoint> _rankedPoints(Map<String, double> values) {
    final rows =
        values.entries
            .map(
              (entry) => ChartPoint(
                entry.key.trim().isEmpty ? 'Unknown' : entry.key.trim(),
                entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return rows.take(8).toList();
  }
}

class _ProductSalesRank {
  _ProductSalesRank({
    required this.product,
    required this.units,
    required this.revenue,
  });

  final Fragrance product;
  int units;
  double revenue;
}

class _AnalyticsInsightGrid extends StatelessWidget {
  const _AnalyticsInsightGrid({
    required this.range,
    required this.onRangeChanged,
    required this.revenue,
    required this.averageOrder,
    required this.taxCollected,
    required this.orders,
    required this.conversionRate,
  });

  final String range;
  final ValueChanged<String> onRangeChanged;
  final double revenue;
  final double averageOrder;
  final double taxCollected;
  final int orders;
  final double conversionRate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1050
            ? 5
            : constraints.maxWidth > 760
            ? 3
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 4.3 : 1.65,
          children: [
            _AnalyticsDrillCard(
              title: 'Sales revenue',
              value: currency(revenue),
              detail: '$orders order(s)',
              icon: Icons.trending_up,
              range: range,
              onRangeChanged: onRangeChanged,
            ),
            _AnalyticsDrillCard(
              title: 'Average order',
              value: currency(averageOrder),
              detail: 'Basket performance',
              icon: Icons.shopping_bag_outlined,
              range: range,
              onRangeChanged: onRangeChanged,
            ),
            _AnalyticsDrillCard(
              title: 'Tax collected',
              value: currency(taxCollected),
              detail: 'Sales tax/VAT estimate',
              icon: Icons.request_quote_outlined,
              range: range,
              onRangeChanged: onRangeChanged,
            ),
            _AnalyticsDrillCard(
              title: 'Conversion rate',
              value: '${conversionRate.toStringAsFixed(1)}%',
              detail: 'Orders from sessions',
              icon: Icons.percent_outlined,
              range: range,
              onRangeChanged: onRangeChanged,
            ),
            _AnalyticsDrillCard(
              title: 'Report period',
              value: range,
              detail: 'Tap cards for deeper reports',
              icon: Icons.date_range_outlined,
              range: range,
              onRangeChanged: onRangeChanged,
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsDrillCard extends StatelessWidget {
  const _AnalyticsDrillCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.range,
    required this.onRangeChanged,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final String range;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
                _RangeSelector(value: range, onChanged: onRangeChanged),
              ],
            ),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(detail),
          ],
        ),
      ),
    );
  }
}

class _ProductAnalyticsCard extends StatelessWidget {
  const _ProductAnalyticsCard({
    required this.products,
    required this.rankedProducts,
    required this.range,
    required this.onRangeChanged,
  });

  final List<Fragrance> products;
  final List<_ProductSalesRank> rankedProducts;
  final String range;
  final ValueChanged<String> onRangeChanged;

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
                    'Product analytics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _RangeSelector(value: range, onChanged: onRangeChanged),
              ],
            ),
            const SizedBox(height: 10),
            for (final row in rankedProducts.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox.square(
                  dimension: 42,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ProductPhoto(product: row.product),
                  ),
                ),
                title: Text(row.product.name),
                subtitle: Text(
                  '${row.units} sold • ${row.product.stock} in stock • ${row.product.rating.toStringAsFixed(1)} rating',
                ),
                trailing: Text(currency(row.revenue)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        items: const [
          DropdownMenuItem(value: '7 days', child: Text('7 days')),
          DropdownMenuItem(value: '30 days', child: Text('30 days')),
          DropdownMenuItem(value: '90 days', child: Text('90 days')),
          DropdownMenuItem(value: 'This year', child: Text('This year')),
          DropdownMenuItem(value: 'All time', child: Text('All time')),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _EmailSection extends StatefulWidget {
  const _EmailSection({
    required this.customers,
    required this.mailingListSubscribers,
    required this.messages,
    required this.settings,
    required this.onSendEmail,
    required this.onSyncInbox,
    required this.onMessageRead,
    required this.onSaveSettings,
  });

  final List<CustomerAccount> customers;
  final List<MailingListSubscriber> mailingListSubscribers;
  final List<EmailMessage> messages;
  final EmailServerSettings settings;
  final void Function(
    String audience,
    String subject,
    String body,
    String accountId,
  )
  onSendEmail;
  final Future<void> Function(String accountId) onSyncInbox;
  final void Function(EmailMessage message, bool isRead) onMessageRead;
  final AsyncValueChanged<EmailServerSettings> onSaveSettings;

  @override
  State<_EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends State<_EmailSection> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  late final TextEditingController _fromName;
  late final TextEditingController _fromEmail;
  late final TextEditingController _imapHost;
  late final TextEditingController _imapPort;
  late final TextEditingController _smtpHost;
  late final TextEditingController _smtpPort;
  late final TextEditingController _username;
  late final TextEditingController _password;
  String _audience = 'All customers';
  late String _provider;
  late bool _useSsl;
  late List<EmailServerSettings> _accounts;
  late String _selectedAccountId;
  bool _htmlMode = true;
  String _mailboxFilter = 'inbox';
  EmailMessage? _selectedMessage;
  bool _syncingInbox = false;
  final List<EmailTemplate> _templates = [
    EmailTemplate(
      key: 'order_received',
      name: 'Order received',
      subject: 'We received your Egbe Anom order',
      htmlBody:
          '<h1>Order received</h1><p>Thank you. Your order is paid and waiting for fulfillment.</p>',
    ),
    EmailTemplate(
      key: 'order_processed',
      name: 'Order processed',
      subject: 'Your Egbe Anom order is being prepared',
      htmlBody:
          '<h1>Your order is being prepared</h1><p>We are picking and packing your fragrance order.</p>',
    ),
    EmailTemplate(
      key: 'order_sent',
      name: 'Order sent',
      subject: 'Your Egbe Anom order is on the way',
      htmlBody:
          '<h1>Your order is on the way</h1><p>Your tracking information is included with this email.</p>',
    ),
    EmailTemplate(
      key: 'payment_failed',
      name: 'Payment unsuccessful',
      subject: 'Your Egbe Anom payment was not completed',
      htmlBody:
          '<h1>Payment not completed</h1><p>You can return to your cart and try another payment method.</p>',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fromName = TextEditingController(text: widget.settings.fromName);
    _fromEmail = TextEditingController(text: widget.settings.fromEmail);
    _imapHost = TextEditingController(text: widget.settings.imapHost);
    _imapPort = TextEditingController(text: '${widget.settings.imapPort}');
    _smtpHost = TextEditingController(text: widget.settings.smtpHost);
    _smtpPort = TextEditingController(text: '${widget.settings.smtpPort}');
    _username = TextEditingController(text: widget.settings.username);
    _password = TextEditingController(text: widget.settings.password);
    _provider = _normalizeEmailProvider(widget.settings.provider);
    _useSsl = widget.settings.useSsl;
    _accounts = widget.settings.allAccounts
        .map((account) => account.copyWithoutAccounts())
        .toList();
    _selectedAccountId = widget.settings.id;
    if (!_accounts.any((account) => account.id == _selectedAccountId)) {
      _selectedAccountId = _accounts.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_syncInbox());
    });
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    _fromName.dispose();
    _fromEmail.dispose();
    _imapHost.dispose();
    _imapPort.dispose();
    _smtpHost.dispose();
    _smtpPort.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String _mailingListAudienceCountText(
    String audience,
    int accountCount,
    int nonAccountCount,
  ) {
    return switch (audience) {
      'Account mailing list' => '$accountCount account recipient(s)',
      'Non-account mailing list' => '$nonAccountCount non-account recipient(s)',
      _ =>
        '${accountCount + nonAccountCount} mailing list recipient(s): $accountCount account, $nonAccountCount non-account',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accountMailingCount = widget.customers
        .where((customer) => customer.acceptsMarketing)
        .length;
    final accountEmails = widget.customers
        .map((customer) => customer.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    final nonAccountMailingCount = widget.mailingListSubscribers
        .where(
          (subscriber) =>
              subscriber.isActive &&
              !accountEmails.contains(subscriber.email.trim().toLowerCase()),
        )
        .length;
    final unreadCount = widget.messages
        .where(
          (message) =>
              message.accountId == _selectedAccountId && !message.isRead,
        )
        .length;
    final accountMessages = widget.messages
        .where((message) => message.accountId == _selectedAccountId)
        .toList();
    bool inFolder(EmailMessage message, String folder) {
      final mailbox = message.mailbox.trim().toLowerCase();
      return switch (folder) {
        'inbox' => mailbox == 'inbox',
        'sent' => mailbox.contains('sent'),
        'trash' => mailbox.contains('trash') || mailbox.contains('deleted'),
        'spam' => mailbox.contains('spam') || mailbox.contains('junk'),
        'archive' => mailbox.contains('archive'),
        _ => true,
      };
    }

    final visibleMessages = _mailboxFilter == 'unread'
        ? accountMessages.where((message) => !message.isRead).toList()
        : accountMessages
              .where((message) => inFolder(message, _mailboxFilter))
              .toList();
    final selectedAccount = _selectedEmailAccount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MailboxToolbar(
            title: 'Mailbox',
            subtitle:
                '${selectedAccount.fromEmail}  |  ${accountMessages.length} message(s)',
            accounts: _accounts,
            selectedAccountId: _selectedAccountId,
            onAccountChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedAccountId = value;
                _selectedMessage = null;
                _loadAccountIntoControllers(_selectedEmailAccount);
              });
            },
            unreadCount: unreadCount,
            syncing: _syncingInbox,
            onCompose: () => _showComposeDialog(),
            onSync: _syncInbox,
            onSettings: _showEmailSettingsDialog,
          ),
          const Divider(height: 1),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final sidebar = _MailboxSidebar(
                selected: _mailboxFilter,
                inboxCount: accountMessages
                    .where((message) => inFolder(message, 'inbox'))
                    .length,
                unreadCount: unreadCount,
                sentCount: accountMessages
                    .where((m) => inFolder(m, 'sent'))
                    .length,
                trashCount: accountMessages
                    .where((m) => inFolder(m, 'trash'))
                    .length,
                spamCount: accountMessages
                    .where((m) => inFolder(m, 'spam'))
                    .length,
                archiveCount: accountMessages
                    .where((m) => inFolder(m, 'archive'))
                    .length,
                accountMailingCount: accountMailingCount,
                nonAccountMailingCount: nonAccountMailingCount,
                onSelect: (value) {
                  if (value == 'compose') {
                    _showComposeDialog();
                    return;
                  }
                  setState(() => _mailboxFilter = value);
                },
              );
              final list = _InboxMessageList(
                messages: visibleMessages,
                selectedMessage: _selectedMessage,
                onSelect: _selectMessage,
              );
              if (!wide) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 260, child: sidebar),
                      const SizedBox(height: 12),
                      SizedBox(height: 520, child: list),
                    ],
                  ),
                );
              }
              return SizedBox(
                height: 680,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 230, child: sidebar),
                    const VerticalDivider(width: 1),
                    Expanded(child: list),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _syncInbox() async {
    setState(() => _syncingInbox = true);
    try {
      await widget.onSyncInbox(_selectedAccountId);
    } finally {
      if (mounted) {
        setState(() => _syncingInbox = false);
      }
    }
  }

  List<String> _emailAudiences() {
    return [
      'All customers',
      'All mailing list',
      'Account mailing list',
      'Non-account mailing list',
      'VIP customers',
      'New customers',
      if (_audience.contains('@') && _audience.contains('.')) _audience,
    ];
  }

  int get _accountMailingCount =>
      widget.customers.where((customer) => customer.acceptsMarketing).length;

  int get _nonAccountMailingCount {
    final accountEmails = widget.customers
        .map((customer) => customer.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    return widget.mailingListSubscribers
        .where(
          (subscriber) =>
              subscriber.isActive &&
              !accountEmails.contains(subscriber.email.trim().toLowerCase()),
        )
        .length;
  }

  EmailServerSettings get _selectedEmailAccount {
    return _accounts.firstWhere(
      (account) => account.id == _selectedAccountId,
      orElse: () => _accounts.first,
    );
  }

  String _emailAccountIdFor(String email) {
    final clean = email.trim().toLowerCase();
    final base = clean.isEmpty ? 'mailbox' : clean;
    var id = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (id.isEmpty) {
      id = 'mailbox';
    }
    var candidate = id;
    var index = 2;
    while (_accounts.any(
      (account) => account.id == candidate && account.id != _selectedAccountId,
    )) {
      candidate = '$id-$index';
      index += 1;
    }
    return candidate;
  }

  void _loadAccountIntoControllers(EmailServerSettings account) {
    _fromName.text = account.fromName;
    _fromEmail.text = account.fromEmail;
    _imapHost.text = account.imapHost;
    _imapPort.text = '${account.imapPort}';
    _smtpHost.text = account.smtpHost;
    _smtpPort.text = '${account.smtpPort}';
    _username.text = account.username;
    _password.text = account.password;
    _provider = _normalizeEmailProvider(account.provider);
    _useSsl = account.useSsl;
  }

  EmailServerSettings _accountFromControllers({String? id}) {
    final email = _fromEmail.text.trim();
    return EmailServerSettings(
      id: id ?? _emailAccountIdFor(email),
      label: email,
      provider: _provider,
      fromName: _fromName.text.trim(),
      fromEmail: email,
      imapHost: _imapHost.text.trim(),
      imapPort: int.tryParse(_imapPort.text) ?? 993,
      smtpHost: _smtpHost.text.trim(),
      smtpPort: int.tryParse(_smtpPort.text) ?? 587,
      username: _username.text.trim(),
      password: _password.text,
      useSsl: _useSsl,
    );
  }

  void _saveCurrentAccountDraft() {
    final index = _accounts.indexWhere(
      (account) => account.id == _selectedAccountId,
    );
    final account = _accountFromControllers(id: _selectedAccountId);
    if (index >= 0) {
      _accounts[index] = account;
    } else {
      _accounts.add(account);
      _selectedAccountId = account.id;
    }
  }

  void _addEmailAccount() {
    _saveCurrentAccountDraft();
    final account = EmailServerSettings(
      id: _emailAccountIdFor('support@egbeanom.com'),
      label: 'New mailbox',
      provider: 'generic',
      fromName: 'EgbeAnom',
      fromEmail: '',
      imapHost: 'mail.egbeanom.com',
      imapPort: 993,
      smtpHost: 'mail.egbeanom.com',
      smtpPort: 465,
      username: '',
      password: '',
      useSsl: true,
    );
    _accounts.add(account);
    _selectedAccountId = account.id;
    _loadAccountIntoControllers(account);
  }

  void _removeSelectedEmailAccount() {
    if (_accounts.length <= 1) {
      return;
    }
    _accounts.removeWhere((account) => account.id == _selectedAccountId);
    _selectedAccountId = _accounts.first.id;
    _loadAccountIntoControllers(_accounts.first);
  }

  void _selectMessage(EmailMessage message) {
    setState(() {
      _selectedMessage = message;
    });
    if (!message.isRead) {
      widget.onMessageRead(message, true);
    }
    _showMessageDialog(message);
  }

  void _replyToMessage(EmailMessage message) {
    setState(() {
      _audience = message.fromEmail.trim().toLowerCase();
      _subject.text = message.subject.toLowerCase().startsWith('re:')
          ? message.subject
          : 'Re: ${message.subject}';
      _body.text =
          '<p></p><hr><p><strong>Original message from ${htmlEscape.convert(message.fromEmail)}</strong></p><p>${htmlEscape.convert(message.preview)}</p>';
      _htmlMode = true;
    });
    _showComposeDialog(title: 'Reply');
  }

  void _forwardMessage(EmailMessage message) {
    final from = message.fromName.trim().isEmpty
        ? message.fromEmail
        : '${message.fromName} <${message.fromEmail}>';
    final body = message.textBody.trim().isNotEmpty
        ? message.textBody
        : message.preview;
    setState(() {
      _audience = '';
      _subject.text = message.subject.toLowerCase().startsWith('fwd:')
          ? message.subject
          : 'Fwd: ${message.subject}';
      _body.text =
          '<p></p><hr><p><strong>Forwarded message</strong></p><p><strong>From:</strong> ${htmlEscape.convert(from)}<br><strong>To:</strong> ${htmlEscape.convert(message.toEmail)}<br><strong>Subject:</strong> ${htmlEscape.convert(message.subject)}</p><p>${htmlEscape.convert(body)}</p>';
      _htmlMode = true;
    });
    _showComposeDialog(title: 'Forward');
  }

  void _sendComposedEmail() {
    widget.onSendEmail(
      _audience,
      _subject.text.trim(),
      _htmlMode
          ? '<html><body>${_body.text.trim()}</body></html>'
          : _body.text.trim(),
      _selectedAccountId,
    );
  }

  Future<void> _showComposeDialog({String title = 'Compose'}) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 760,
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: _EmailComposerPanel(
                  audiences: _emailAudiences(),
                  audience: _audience,
                  accountMailingCount: _accountMailingCount,
                  nonAccountMailingCount: _nonAccountMailingCount,
                  subject: _subject,
                  body: _body,
                  htmlMode: _htmlMode,
                  templates: _templates,
                  audienceCountText: _mailingListAudienceCountText,
                  onAudienceChanged: (value) {
                    setState(() => _audience = value);
                    dialogSetState(() {});
                  },
                  onHtmlModeChanged: (value) {
                    setState(() => _htmlMode = value);
                    dialogSetState(() {});
                  },
                  onUseTemplate: (template) {
                    setState(() {
                      _subject.text = template.subject;
                      _body.text = template.htmlBody;
                      _htmlMode = true;
                    });
                    dialogSetState(() {});
                  },
                  onSend: () {
                    _sendComposedEmail();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMessageDialog(EmailMessage message) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  message.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SizedBox(
            width: 760,
            height: MediaQuery.sizeOf(context).height * 0.68,
            child: _EmailMessageViewer(message: message),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                widget.onMessageRead(message, !message.isRead);
                Navigator.of(context).pop();
              },
              icon: Icon(
                message.isRead
                    ? Icons.mark_email_unread_outlined
                    : Icons.mark_email_read_outlined,
              ),
              label: Text(message.isRead ? 'Mark unread' : 'Mark read'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _forwardMessage(message);
              },
              icon: const Icon(Icons.forward_outlined),
              label: const Text('Forward'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _replyToMessage(message);
              },
              icon: const Icon(Icons.reply_outlined),
              label: const Text('Reply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEmailSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Email settings'),
              content: SizedBox(
                width: 680,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedAccountId,
                              decoration: const InputDecoration(
                                labelText: 'Email account',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              items: _accounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account.id,
                                      child: Text(account.displayLabel),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _saveCurrentAccountDraft();
                                  _selectedAccountId = value;
                                  _loadAccountIntoControllers(
                                    _selectedEmailAccount,
                                  );
                                });
                                dialogSetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Add mailbox',
                            onPressed: () {
                              setState(_addEmailAccount);
                              dialogSetState(() {});
                            },
                            icon: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Remove selected mailbox',
                            onPressed: _accounts.length <= 1
                                ? null
                                : () {
                                    setState(_removeSelectedEmailAccount);
                                    dialogSetState(() {});
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _provider,
                        decoration: const InputDecoration(
                          labelText: 'SMTP provider',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'google',
                            child: Text('Google / Gmail'),
                          ),
                          DropdownMenuItem(
                            value: 'godaddy',
                            child: Text('GoDaddy'),
                          ),
                          DropdownMenuItem(
                            value: 'generic',
                            child: Text('Generic SMTP'),
                          ),
                        ],
                        onChanged: (value) {
                          final provider = _normalizeEmailProvider(value);
                          setState(() {
                            _provider = provider;
                            _applyEmailProviderPreset(provider);
                          });
                          dialogSetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fromName,
                              decoration: const InputDecoration(
                                labelText: 'From name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _fromEmail,
                              decoration: const InputDecoration(
                                labelText: 'From email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _imapHost,
                              decoration: const InputDecoration(
                                labelText: 'IMAP host',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _imapPort,
                              decoration: const InputDecoration(
                                labelText: 'IMAP port',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _smtpHost,
                              decoration: const InputDecoration(
                                labelText: 'SMTP host',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _smtpPort,
                              decoration: const InputDecoration(
                                labelText: 'SMTP port',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Mailbox username',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        decoration: const InputDecoration(
                          labelText: 'SMTP password or app password',
                        ),
                        obscureText: true,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Use direct SSL'),
                        subtitle: const Text(
                          'Turn on for port 465. Leave off for port 587 STARTTLS.',
                        ),
                        value: _useSsl,
                        onChanged: (value) {
                          setState(() => _useSsl = value);
                          dialogSetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    _saveCurrentAccountDraft();
                    final selected = _selectedEmailAccount.copyWithoutAccounts()
                      ..accounts = _accounts
                          .map((account) => account.copyWithoutAccounts())
                          .toList();
                    widget.onSaveSettings(selected);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _normalizeEmailProvider(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'google' || 'gmail' => 'google',
      'godaddy' || 'go daddy' => 'godaddy',
      _ => 'generic',
    };
  }

  void _applyEmailProviderPreset(String provider) {
    switch (provider) {
      case 'google':
        _imapHost.text = 'imap.gmail.com';
        _imapPort.text = '993';
        _smtpHost.text = 'smtp.gmail.com';
        _smtpPort.text = '587';
        _useSsl = false;
        if (_username.text.trim().isEmpty) {
          _username.text = _fromEmail.text.trim();
        }
        break;
      case 'godaddy':
        _imapHost.text = 'imap.secureserver.net';
        _imapPort.text = '993';
        _smtpHost.text = 'smtpout.secureserver.net';
        _smtpPort.text = '587';
        _useSsl = false;
        if (_username.text.trim().isEmpty) {
          _username.text = _fromEmail.text.trim();
        }
        break;
      default:
        break;
    }
  }
}

class _MailboxToolbar extends StatelessWidget {
  const _MailboxToolbar({
    required this.title,
    required this.subtitle,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountChanged,
    required this.unreadCount,
    required this.syncing,
    required this.onCompose,
    required this.onSync,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final List<EmailServerSettings> accounts;
  final String selectedAccountId;
  final ValueChanged<String?> onAccountChanged;
  final int unreadCount;
  final bool syncing;
  final VoidCallback onCompose;
  final AsyncCallback onSync;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Mailbox',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              items: accounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(
                        account.displayLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onAccountChanged,
            ),
          ),
          const SizedBox(width: 8),
          if (unreadCount > 0) ...[
            Chip(
              avatar: const Icon(Icons.mark_email_unread_outlined, size: 18),
              label: Text('$unreadCount unread'),
            ),
            const SizedBox(width: 8),
          ],
          Tooltip(
            message: 'Sync inbox',
            child: IconButton.filledTonal(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_outlined),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Email settings',
            child: IconButton.filledTonal(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onCompose,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Compose'),
          ),
        ],
      ),
    );
  }
}

class _MailboxSidebar extends StatelessWidget {
  const _MailboxSidebar({
    required this.selected,
    required this.inboxCount,
    required this.unreadCount,
    required this.sentCount,
    required this.trashCount,
    required this.spamCount,
    required this.archiveCount,
    required this.accountMailingCount,
    required this.nonAccountMailingCount,
    required this.onSelect,
  });

  final String selected;
  final int inboxCount;
  final int unreadCount;
  final int sentCount;
  final int trashCount;
  final int spamCount;
  final int archiveCount;
  final int accountMailingCount;
  final int nonAccountMailingCount;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _MailboxRailButton(
            value: 'compose',
            selected: selected == 'compose',
            icon: Icons.edit_outlined,
            label: 'Compose',
            onSelect: onSelect,
          ),
          const SizedBox(height: 8),
          _MailboxRailButton(
            value: 'inbox',
            selected: selected == 'inbox',
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            count: inboxCount,
            onSelect: onSelect,
          ),
          _MailboxRailButton(
            value: 'unread',
            selected: selected == 'unread',
            icon: Icons.mark_email_unread_outlined,
            label: 'Unread',
            count: unreadCount,
            emphasize: unreadCount > 0,
            onSelect: onSelect,
          ),
          _MailboxRailButton(
            value: 'sent',
            selected: selected == 'sent',
            icon: Icons.send_outlined,
            label: 'Sent',
            count: sentCount,
            onSelect: onSelect,
          ),
          _MailboxRailButton(
            value: 'archive',
            selected: selected == 'archive',
            icon: Icons.archive_outlined,
            label: 'Archive',
            count: archiveCount,
            onSelect: onSelect,
          ),
          _MailboxRailButton(
            value: 'spam',
            selected: selected == 'spam',
            icon: Icons.report_gmailerrorred_outlined,
            label: 'Junk / Spam',
            count: spamCount,
            onSelect: onSelect,
          ),
          _MailboxRailButton(
            value: 'trash',
            selected: selected == 'trash',
            icon: Icons.delete_outline,
            label: 'Trash',
            count: trashCount,
            onSelect: onSelect,
          ),
          const Divider(height: 28),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.group_outlined),
            title: const Text('Account list'),
            trailing: Text('$accountMailingCount'),
          ),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.alternate_email),
            title: const Text('Public list'),
            trailing: Text('$nonAccountMailingCount'),
          ),
          const Divider(height: 28),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.info_outline),
            title: const Text('Mass emails send privately'),
            subtitle: const Text('Recipients do not see each other.'),
          ),
        ],
      ),
    );
  }
}

class _MailboxRailButton extends StatelessWidget {
  const _MailboxRailButton({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onSelect,
    this.count,
    this.emphasize = false,
  });

  final String value;
  final bool selected;
  final IconData icon;
  final String label;
  final int? count;
  final bool emphasize;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected || emphasize ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: count == null
          ? null
          : Container(
              constraints: const BoxConstraints(minWidth: 28),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: emphasize
                    ? const Color(0xFFB3261E)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: emphasize ? Colors.white : colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      onTap: () => onSelect(value),
    );
  }
}

class _EmailComposerPanel extends StatelessWidget {
  const _EmailComposerPanel({
    required this.audiences,
    required this.audience,
    required this.accountMailingCount,
    required this.nonAccountMailingCount,
    required this.subject,
    required this.body,
    required this.htmlMode,
    required this.templates,
    required this.audienceCountText,
    required this.onAudienceChanged,
    required this.onHtmlModeChanged,
    required this.onUseTemplate,
    required this.onSend,
  });

  final List<String> audiences;
  final String audience;
  final int accountMailingCount;
  final int nonAccountMailingCount;
  final TextEditingController subject;
  final TextEditingController body;
  final bool htmlMode;
  final List<EmailTemplate> templates;
  final String Function(String audience, int accountCount, int nonAccountCount)
  audienceCountText;
  final ValueChanged<String> onAudienceChanged;
  final ValueChanged<bool> onHtmlModeChanged;
  final ValueChanged<EmailTemplate> onUseTemplate;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final mailingAudience =
        audience == 'All mailing list' ||
        audience == 'Account mailing list' ||
        audience == 'Non-account mailing list';
    final selectedAudience = audiences.contains(audience)
        ? audience
        : 'All customers';
    final showSpecificEmail = audience.trim().isEmpty || audience.contains('@');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Compose',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedAudience,
            decoration: const InputDecoration(
              labelText: 'Audience',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: [
              for (final item in audiences)
                DropdownMenuItem(value: item, child: Text(item)),
            ],
            onChanged: (value) {
              if (value != null) {
                onAudienceChanged(value);
              }
            },
          ),
          if (showSpecificEmail) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: audience,
              decoration: const InputDecoration(
                labelText: 'Specific email address',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: onAudienceChanged,
            ),
          ],
          if (mailingAudience) ...[
            const SizedBox(height: 8),
            Text(
              audienceCountText(
                audience,
                accountMailingCount,
                nonAccountMailingCount,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: subject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(Icons.subject_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _HtmlEditorField(controller: body, htmlMode: htmlMode),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Send as HTML email'),
            value: htmlMode,
            onChanged: onHtmlModeChanged,
          ),
          const SizedBox(height: 12),
          Text('Templates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final template in templates)
                ActionChip(
                  avatar: const Icon(Icons.description_outlined, size: 18),
                  label: Text(template.name),
                  onPressed: () => onUseTemplate(template),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HtmlEditorField extends StatelessWidget {
  const _HtmlEditorField({
    required this.controller,
    required this.htmlMode,
    this.compact = false,
  });

  final TextEditingController controller;
  final bool htmlMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD8BD80)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(bottom: BorderSide(color: Color(0xFF3A3327))),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.code_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        htmlMode ? 'HTML editor' : 'Message editor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      htmlMode ? '<html>' : 'text',
                      style: const TextStyle(
                        color: Color(0xFFCDBB91),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.35,
                ),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: htmlMode
                      ? '<h1>Hello</h1>\n<p>Paste or write email HTML here.</p>'
                      : 'Write the email message here.',
                  hintStyle: const TextStyle(color: Color(0xFF6D6559)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                minLines: compact ? 8 : 16,
                maxLines: compact ? 12 : 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          htmlMode
              ? 'HTML is wrapped in the EgbeAnom email template when sent.'
              : 'Turn on HTML email to send this as HTML.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InboxMessageList extends StatelessWidget {
  const _InboxMessageList({
    required this.messages,
    required this.selectedMessage,
    required this.onSelect,
  });

  final List<EmailMessage> messages;
  final EmailMessage? selectedMessage;
  final ValueChanged<EmailMessage> onSelect;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No messages synced yet.'),
        ),
      );
    }
    final visibleMessages = messages.take(80).toList();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visibleMessages.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final message = visibleMessages[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          selected: selectedMessage?.id == message.id,
          leading: Icon(
            message.isRead
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
            color: message.isRead ? null : const Color(0xFFC88F52),
          ),
          title: Text(
            message.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: message.isRead ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${message.fromEmail}\n${message.preview}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          onTap: () => onSelect(message),
        );
      },
    );
  }
}

class _EmailMessageViewer extends StatelessWidget {
  const _EmailMessageViewer({required this.message});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    final body = message.textBody.trim().isNotEmpty
        ? message.textBody
        : message.preview;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'From: ${message.fromName.trim().isEmpty ? message.fromEmail : '${message.fromName} <${message.fromEmail}>'}',
                ),
                Text('To: ${message.toEmail}'),
                Text(
                  'Received: ${message.receivedAt.month}/${message.receivedAt.day}/${message.receivedAt.year} ${message.receivedAt.hour.toString().padLeft(2, '0')}:${message.receivedAt.minute.toString().padLeft(2, '0')}',
                ),
                if (message.orderNumber.trim().isNotEmpty)
                  Text('Order: ${message.orderNumber}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(body),
        ],
      ),
    );
  }
}
