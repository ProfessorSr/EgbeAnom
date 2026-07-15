part of '../main.dart';

class _AdminOverview extends StatefulWidget {
  const _AdminOverview({
    required this.revenue,
    required this.inventory,
    required this.unitsSold,
    required this.orderCount,
    required this.reservedInventory,
    required this.cartValue,
    required this.newUsersToday,
    required this.newUsers7Days,
    required this.conversionRate,
    required this.lowStockProducts,
    required this.activeCarts,
    required this.dailyMetrics,
    required this.products,
    required this.sessions,
    required this.orders,
    required this.reviews,
    required this.onOpenSection,
  });

  final double revenue;
  final int inventory;
  final int unitsSold;
  final int orderCount;
  final int reservedInventory;
  final double cartValue;
  final int newUsersToday;
  final int newUsers7Days;
  final double conversionRate;
  final List<Fragrance> lowStockProducts;
  final List<ActiveCart> activeCarts;
  final List<DailyMetric> dailyMetrics;
  final List<Fragrance> products;
  final List<ActiveUserSession> sessions;
  final List<Order> orders;
  final List<ReviewSummary> reviews;
  final ValueChanged<AdminSection> onOpenSection;

  @override
  State<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<_AdminOverview> {
  int _windowDays = 14;

  @override
  Widget build(BuildContext context) {
    final metrics = AdminOverviewWindowMetrics.from(
      days: _windowDays,
      dailyMetrics: widget.dailyMetrics,
      orders: widget.orders,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Overview window',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              _RangeSelect(
                label: 'Time range',
                value: _windowDays,
                onChanged: (value) => setState(() => _windowDays = value),
              ),
              Text('Showing last $_windowDays days of activity'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onOpenSection(AdminSection.reports),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revenue is ${currency(metrics.revenue)} from ${metrics.orders} orders, with ${widget.conversionRate.toStringAsFixed(1)}% conversion and ${currency(metrics.averageOrderValue)} average order value.',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acquisition added ${metrics.users} users and generated ${metrics.visits} visits (${currency(metrics.revenuePerVisit)} revenue per visit).',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Key performance indicators',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.payments_outlined,
              'Revenue ($_windowDays days)',
              currency(metrics.revenue),
              targetSection: AdminSection.reports,
            ),
            _MetricData(
              Icons.receipt_long_outlined,
              'Orders ($_windowDays days)',
              '${metrics.orders}',
              targetSection: AdminSection.orders,
            ),
            _MetricData(
              Icons.analytics_outlined,
              'Avg order value',
              currency(metrics.averageOrderValue),
              targetSection: AdminSection.reports,
            ),
            _MetricData(
              Icons.swap_vert_circle_outlined,
              'Revenue per visit',
              currency(metrics.revenuePerVisit),
              targetSection: AdminSection.analytics,
            ),
            _MetricData(
              Icons.person_add_alt,
              'New users today',
              '${widget.newUsersToday}',
              targetSection: AdminSection.customers,
            ),
            _MetricData(
              Icons.groups_outlined,
              'New users ($_windowDays days)',
              '${metrics.users}',
              targetSection: AdminSection.customers,
            ),
            _MetricData(
              Icons.trending_up,
              'Conversion',
              '${widget.conversionRate.toStringAsFixed(1)}%',
              targetSection: AdminSection.analytics,
            ),
            _MetricData(
              Icons.visibility_outlined,
              'Visits ($_windowDays days)',
              '${metrics.visits}',
              targetSection: AdminSection.analytics,
            ),
            _MetricData(
              Icons.inventory_2_outlined,
              'Inventory',
              '${widget.inventory} units',
              targetSection: AdminSection.inventory,
            ),
            _MetricData(
              Icons.reviews_outlined,
              'Reviews',
              '${widget.reviews.length}',
              targetSection: AdminSection.reviews,
            ),
          ],
          onOpenSection: widget.onOpenSection,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 920;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: _OverviewQuickLinks(
                    onOpenSection: widget.onOpenSection,
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _ActionCenter(
                    lowStockProducts: widget.lowStockProducts,
                    activeCarts: widget.activeCarts,
                    onOpenSection: widget.onOpenSection,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(
    this.icon,
    this.label,
    this.value, {
    this.targetSection,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final AdminSection? targetSection;
  final VoidCallback? onTap;
}

class _RangeSelect extends StatelessWidget {
  const _RangeSelect({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 day')),
          DropdownMenuItem(value: 7, child: Text('7 days')),
          DropdownMenuItem(value: 14, child: Text('14 days')),
          DropdownMenuItem(value: 30, child: Text('30 days')),
          DropdownMenuItem(value: 60, child: Text('60 days')),
          DropdownMenuItem(value: 90, child: Text('90 days')),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _OverviewQuickLinks extends StatelessWidget {
  const _OverviewQuickLinks({required this.onOpenSection});

  final ValueChanged<AdminSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final links = [
      (
        Icons.receipt_long_outlined,
        'Orders',
        'Review new orders and fulfillment status.',
        AdminSection.orders,
      ),
      (
        Icons.analytics_outlined,
        'Analytics',
        'Open detailed traffic, source, page, and ecommerce analytics.',
        AdminSection.analytics,
      ),
      (
        Icons.file_download_outlined,
        'Reports',
        'Export sales, tax, product, and customer tables.',
        AdminSection.reports,
      ),
      (
        Icons.inventory_2_outlined,
        'Inventory',
        'Check stock, low-stock items, and print inventory.',
        AdminSection.inventory,
      ),
      (
        Icons.outgoing_mail,
        'Email',
        'Send test emails and manage customer notices.',
        AdminSection.email,
      ),
      (
        Icons.reviews_outlined,
        'Reviews',
        'Moderate pending and published customer reviews.',
        AdminSection.reviews,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final link in links)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(link.$1),
                title: Text(link.$2),
                subtitle: Text(link.$3),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenSection(link.$4),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, this.onOpenSection});

  final List<_MetricData> metrics;
  final ValueChanged<AdminSection>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1120
            ? 4
            : constraints.maxWidth > 620
            ? 2
            : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 3.1 : 2.4,
          children: [
            for (final metric in metrics)
              _MetricCard(
                icon: metric.icon,
                label: metric.label,
                value: metric.value,
                onTap:
                    metric.onTap ??
                    (metric.targetSection == null || onOpenSection == null
                        ? null
                        : () => onOpenSection!(metric.targetSection!)),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardChartGrid extends StatelessWidget {
  const _DashboardChartGrid({
    required this.products,
    required this.dailyMetrics,
    required this.activeCarts,
    required this.onOpenSection,
  });

  final List<Fragrance> products;
  final List<DailyMetric> dailyMetrics;
  final List<ActiveCart> activeCarts;
  final ValueChanged<AdminSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final categories = <String, double>{};
    for (final product in products) {
      categories.update(
        product.type,
        (value) => value + product.stock,
        ifAbsent: () => product.stock.toDouble(),
      );
    }
    final revenue = dailyMetrics
        .map((metric) => ChartPoint(metric.day, metric.revenue))
        .toList();
    final users = dailyMetrics
        .map((metric) => ChartPoint(metric.day, metric.newUsers.toDouble()))
        .toList();
    final carts = activeCarts
        .map((cart) => ChartPoint(cart.id.replaceAll('CART-', ''), cart.value))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1040
            ? 4
            : constraints.maxWidth > 760
            ? 2
            : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 1.75 : 1.55,
          children: [
            _ChartCard(
              title: 'Sales by day',
              subtitle: 'Click for reporting details',
              onTap: () => onOpenSection(AdminSection.reports),
              child: _MiniBarChart(points: revenue),
            ),
            _ChartCard(
              title: 'Catalog mix',
              subtitle: 'Inventory units by fragrance type',
              onTap: () => onOpenSection(AdminSection.inventory),
              child: _MiniBarChart(
                points: categories.entries
                    .map((entry) => ChartPoint(entry.key, entry.value))
                    .toList(),
                color: const Color(0xFF5A6FA8),
              ),
            ),
            _ChartCard(
              title: 'Customer growth',
              subtitle: 'New users per day',
              onTap: () => onOpenSection(AdminSection.customers),
              child: _MiniBarChart(
                points: users,
                color: const Color(0xFF27724E),
              ),
            ),
            _ChartCard(
              title: 'Cart exposure',
              subtitle: 'Reserved cart value',
              onTap: () => onOpenSection(AdminSection.carts),
              child: _MiniBarChart(
                points: carts,
                color: const Color(0xFF5A6FA8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChartPoint {
  const ChartPoint(this.label, this.value);

  final String label;
  final double value;
}

class _CommerceDashboardPanels extends StatelessWidget {
  const _CommerceDashboardPanels({
    required this.products,
    required this.metrics,
    required this.activeCarts,
    required this.sessions,
    required this.orders,
    required this.reviews,
    required this.onOpenSection,
  });

  final List<Fragrance> products;
  final List<DailyMetric> metrics;
  final List<ActiveCart> activeCarts;
  final List<ActiveUserSession> sessions;
  final List<Order> orders;
  final List<ReviewSummary> reviews;
  final ValueChanged<AdminSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final topProducts = [...products]..sort((a, b) => b.sold.compareTo(a.sold));
    final trafficCounts = <String, double>{};
    for (final session in sessions) {
      trafficCounts.update(
        session.source,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final pageCounts = <String, double>{};
    for (final session in sessions) {
      pageCounts.update(
        session.currentPage,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final traffic = trafficCounts.entries
        .map((entry) => ChartPoint(entry.key, entry.value))
        .toList();
    final pages = pageCounts.entries
        .map((entry) => ChartPoint(entry.key, entry.value))
        .toList();
    final sales = metrics.map((m) => ChartPoint(m.day, m.revenue)).toList();
    final orders = metrics
        .map((m) => ChartPoint(m.day, m.orders.toDouble()))
        .toList();
    final totalVisits = metrics.fold(0, (sum, metric) => sum + metric.visits);
    final viewedProducts = sessions
        .where((session) => session.currentPage == StoreView.detail.name)
        .length;
    final checkoutSessions = sessions
        .where((session) => session.currentPage == StoreView.checkout.name)
        .length;
    final purchaseCount = this.orders.length;
    final pendingReviews = reviews
        .where((review) => review.status == 'pending')
        .length;
    final approvedReviews = reviews
        .where((review) => review.status == 'approved')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 980;
        return Column(
          children: [
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 7 : 0,
                  child: _ChartCard(
                    title: 'Sales summary',
                    subtitle: 'Revenue and order movement',
                    onTap: () => onOpenSection(AdminSection.reports),
                    child: _MiniBarChart(points: sales),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _ChartCard(
                    title: 'Traffic sources',
                    subtitle: 'Live acquisition source mix',
                    onTap: () => onOpenSection(AdminSection.customers),
                    child: _MiniBarChart(
                      points: traffic,
                      color: const Color(0xFF27724E),
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
                  flex: wide ? 7 : 0,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onOpenSection(AdminSection.catalog),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top selling products',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            for (final product in topProducts.take(5))
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
                                trailing: Text(
                                  currency(product.sold * product.price),
                                ),
                                onTap: () =>
                                    onOpenSection(AdminSection.catalog),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: Column(
                    children: [
                      _ChartCard(
                        title: 'Visit and sales statistics',
                        subtitle: 'Orders over selected range',
                        onTap: () => onOpenSection(AdminSection.orders),
                        child: _MiniBarChart(
                          points: orders,
                          color: const Color(0xFF5A6FA8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onOpenSection(AdminSection.carts),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fulfillment snapshot',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                _MiniDashboardRow(
                                  label: 'Active carts',
                                  value: '${activeCarts.length}',
                                ),
                                _MiniDashboardRow(
                                  label: 'Reserved units',
                                  value:
                                      '${activeCarts.fold(0, (sum, cart) => sum + cart.itemCount)}',
                                ),
                                _MiniDashboardRow(
                                  label: 'Reserved value',
                                  value: currency(
                                    activeCarts.fold(
                                      0,
                                      (sum, cart) => sum + cart.value,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      onOpenSection(AdminSection.carts),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Open carts'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                    title: 'Realtime pages',
                    subtitle: 'Active users by current page',
                    onTap: () => onOpenSection(AdminSection.customers),
                    child: _MiniBarChart(
                      points: pages,
                      color: const Color(0xFF5A6FA8),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _FunnelCard(
                    title: 'Purchase journey',
                    steps: [
                      _FunnelStep('Session start', totalVisits),
                      _FunnelStep('View product', viewedProducts),
                      _FunnelStep(
                        'Add to cart',
                        activeCarts.fold(
                          0,
                          (sum, cart) => sum + cart.itemCount,
                        ),
                      ),
                      _FunnelStep('Begin checkout', checkoutSessions),
                      _FunnelStep('Purchase', purchaseCount),
                    ],
                    onTap: () => onOpenSection(AdminSection.orders),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _FunnelCard(
                    title: 'Checkout journey',
                    steps: [
                      _FunnelStep('Begin checkout', checkoutSessions),
                      _FunnelStep('Add shipping', purchaseCount),
                      _FunnelStep('Add payment', purchaseCount),
                      _FunnelStep('Purchase', purchaseCount),
                    ],
                    onTap: () => onOpenSection(AdminSection.orders),
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
                  flex: wide ? 5 : 0,
                  child: _MiniTableCard(
                    title: 'Transactions',
                    action: 'Open orders',
                    onTap: () => onOpenSection(AdminSection.orders),
                    rows: [
                      for (final order in this.orders.take(6))
                        '${order.id} • ${order.customer} • ${currency(order.total)}',
                    ],
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _MiniTableCard(
                    title: 'Review moderation',
                    action: 'Open reviews',
                    onTap: () => onOpenSection(AdminSection.reviews),
                    rows: [
                      'Pending: $pendingReviews',
                      'Approved: $approvedReviews',
                      'Rejected: ${reviews.where((review) => review.status == 'rejected').length}',
                    ],
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _MiniTableCard(
                    title: 'Ecommerce purchases',
                    action: 'Open catalog',
                    onTap: () => onOpenSection(AdminSection.catalog),
                    rows: [
                      for (final product in topProducts.take(5))
                        '${product.name} • ${product.sold} sold • ${currency(product.sold * product.price)}',
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
}

class _FunnelStep {
  const _FunnelStep(this.label, this.value);

  final String label;
  final int value;
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({
    required this.title,
    required this.steps,
    required this.onTap,
  });

  final String title;
  final List<_FunnelStep> steps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final maxValue = steps.fold(
      0,
      (max, step) => step.value > max ? step.value : max,
    );
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final step in steps) ...[
                Row(
                  children: [
                    Expanded(child: Text(step.label)),
                    Text('${step.value}'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: maxValue == 0 ? 0 : step.value / maxValue,
                  minHeight: 8,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTableCard extends StatelessWidget {
  const _MiniTableCard({
    required this.title,
    required this.action,
    required this.rows,
    this.onTap,
  });

  final String title;
  final String action;
  final List<String> rows;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (onTap != null)
                TextButton(onPressed: onTap, child: Text(action)),
            ],
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            const Text('No records yet.')
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(row),
              ),
        ],
      ),
    );
    return Card(
      clipBehavior: onTap == null ? Clip.none : Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: content,
            ),
    );
  }
}

class _MiniDashboardRow extends StatelessWidget {
  const _MiniDashboardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: Text(subtitle)),
              ?trailing,
              if (trailing != null) const SizedBox(width: 8),
              if (onTap != null) const Icon(Icons.open_in_new, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
    return Card(
      clipBehavior: onTap == null ? Clip.none : Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.points,
    this.color = const Color(0xFFC88F52),
  });

  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold(
      0.0,
      (max, point) => point.value > max ? point.value : max,
    );
    return CustomPaint(
      painter: _AxisBarChartPainter(
        points: points,
        maxValue: maxValue,
        color: color,
        textStyle:
            Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10) ??
            const TextStyle(fontSize: 10),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AxisBarChartPainter extends CustomPainter {
  const _AxisBarChartPainter({
    required this.points,
    required this.maxValue,
    required this.color,
    required this.textStyle,
  });

  final List<ChartPoint> points;
  final double maxValue;
  final Color color;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFF7B7268)
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = const Color(0xFFE2DCD2)
      ..strokeWidth = 1;
    final left = 38.0;
    final bottom = size.height - 22;
    final top = 8.0;
    final right = size.width - 6;
    final chartWidth = math.max(1.0, right - left);
    final chartHeight = math.max(1.0, bottom - top);

    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    final ticks = 4;
    for (var i = 0; i <= ticks; i++) {
      final y = bottom - chartHeight * i / ticks;
      canvas.drawLine(Offset(left - 4, y), Offset(left, y), axisPaint);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      final labelValue = maxValue == 0 ? 0 : maxValue * i / ticks;
      _drawText(
        canvas,
        labelValue.toStringAsFixed(labelValue >= 10 ? 0 : 1),
        Offset(0, y - 7),
        textStyle,
        maxWidth: left - 6,
        align: TextAlign.right,
      );
    }

    if (points.isEmpty) {
      _drawText(
        canvas,
        'No live data',
        Offset(left + 12, top + chartHeight / 2 - 8),
        textStyle,
        maxWidth: chartWidth - 24,
      );
      return;
    }

    final slot = chartWidth / points.length;
    final barWidth = math.max(4.0, slot * 0.48);
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final height = maxValue == 0 ? 0.0 : point.value / maxValue * chartHeight;
      final x = left + slot * i + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - height, barWidth, height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      canvas.drawLine(
        Offset(left + slot * i + slot / 2, bottom),
        Offset(left + slot * i + slot / 2, bottom + 4),
        axisPaint,
      );
      _drawText(
        canvas,
        point.label,
        Offset(left + slot * i, bottom + 5),
        textStyle,
        maxWidth: slot,
        align: TextAlign.center,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _AxisBarChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.color != color ||
      oldDelegate.textStyle != textStyle;
}

class _ActionCenter extends StatelessWidget {
  const _ActionCenter({
    required this.lowStockProducts,
    required this.activeCarts,
    required this.onOpenSection,
  });

  final List<Fragrance> lowStockProducts;
  final List<ActiveCart> activeCarts;
  final ValueChanged<AdminSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Operations queue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _QueueTile(
              icon: Icons.warning_amber_outlined,
              title: '${lowStockProducts.length} low-stock fragrances',
              subtitle: lowStockProducts.isEmpty
                  ? 'All reorder points are healthy.'
                  : lowStockProducts.map((product) => product.name).join(', '),
              onTap: () => onOpenSection(AdminSection.inventory),
            ),
            _QueueTile(
              icon: Icons.shopping_cart_checkout,
              title: '${activeCarts.length} active carts',
              subtitle: 'Review reserved inventory and abandoned carts.',
              onTap: () => onOpenSection(AdminSection.carts),
            ),
            _QueueTile(
              icon: Icons.add_photo_alternate_outlined,
              title: 'Catalog media',
              subtitle:
                  'Add or update fragrance photos, SKUs, vendors, and pricing.',
              onTap: () => onOpenSection(AdminSection.catalog),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFFC88F52)),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
