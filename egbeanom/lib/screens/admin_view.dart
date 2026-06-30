part of '../main.dart';

enum AdminSection {
  overview,
  catalog,
  categories,
  inventory,
  carts,
  promotions,
  payments,
  shipping,
  content,
  customers,
  orders,
  invoices,
  reviews,
  notifications,
  email,
  site,
  storeInfo,
  taxes,
  backendUsers,
  analytics,
  reports,
}

typedef ProductRemoveCallback = Future<void> Function(Fragrance product);
typedef AsyncValueChanged<T> = Future<void> Function(T value);

class AdminView extends StatefulWidget {
  const AdminView({
    super.key,
    required this.products,
    required this.categories,
    required this.orders,
    required this.activeCarts,
    required this.customers,
    required this.dailyMetrics,
    required this.coupons,
    required this.paymentMethods,
    required this.shippingOptions,
    required this.shippingCredentials,
    required this.noteOptions,
    required this.pendingNoteOptions,
    required this.familyOptions,
    required this.seasonOptions,
    required this.occasionOptions,
    required this.contentBlocks,
    required this.reviews,
    required this.notifications,
    required this.siteStatus,
    required this.storeInfo,
    required this.taxRules,
    required this.measurementSystem,
    required this.backendUsers,
    required this.activeUserSessions,
    required this.emailSettings,
    required this.onSave,
    required this.onRemove,
    required this.onUploadImages,
    required this.onSaveCategory,
    required this.onRemoveCategory,
    required this.onSaveCoupon,
    required this.onTogglePayment,
    required this.onSavePayment,
    required this.onSaveShippingOption,
    required this.onDeleteShippingOption,
    required this.onSaveShippingCredentials,
    required this.onSaveContent,
    required this.onUpdateOrder,
    required this.onCreateShippingLabel,
    required this.onBatchUpdateOrders,
    required this.onUpdateReview,
    required this.onSendEmail,
    required this.onSaveEmailSettings,
    required this.onUpdateSiteStatus,
    required this.onSaveStoreInfo,
    required this.onUploadStoreAsset,
    required this.onSaveTaxRule,
    required this.onDeleteTaxRule,
    required this.onSaveCustomer,
    required this.onBlockIp,
    required this.onSaveBackendUser,
    required this.onApproveFragranceNote,
  });

  final List<Fragrance> products;
  final List<Category> categories;
  final List<Order> orders;
  final List<ActiveCart> activeCarts;
  final List<CustomerAccount> customers;
  final List<DailyMetric> dailyMetrics;
  final List<CouponRule> coupons;
  final List<PaymentMethodConfig> paymentMethods;
  final List<ShippingOption> shippingOptions;
  final Map<String, ShippingCarrierCredentials> shippingCredentials;
  final List<String> noteOptions;
  final List<String> pendingNoteOptions;
  final List<String> familyOptions;
  final List<String> seasonOptions;
  final List<String> occasionOptions;
  final List<ContentBlock> contentBlocks;
  final List<ReviewSummary> reviews;
  final List<StoreNotification> notifications;
  final SiteStatus siteStatus;
  final StoreInfo storeInfo;
  final List<TaxRule> taxRules;
  final MeasurementSystem measurementSystem;
  final List<BackendUser> backendUsers;
  final List<ActiveUserSession> activeUserSessions;
  final EmailServerSettings emailSettings;
  final AsyncValueChanged<Fragrance> onSave;
  final ProductRemoveCallback onRemove;
  final Future<List<ProductImage>> Function(
    Fragrance product,
    List<UploadedImageFile> files,
  )
  onUploadImages;
  final AsyncValueChanged<Category> onSaveCategory;
  final ValueChanged<Category> onRemoveCategory;
  final AsyncValueChanged<CouponRule> onSaveCoupon;
  final AsyncValueChanged<PaymentMethodConfig> onTogglePayment;
  final AsyncValueChanged<PaymentMethodConfig> onSavePayment;
  final AsyncValueChanged<ShippingOption> onSaveShippingOption;
  final AsyncValueChanged<ShippingOption> onDeleteShippingOption;
  final Future<void> Function(
    String carrier,
    ShippingCarrierCredentials credentials,
  )
  onSaveShippingCredentials;
  final AsyncValueChanged<ContentBlock> onSaveContent;
  final AsyncValueChanged<Order> onUpdateOrder;
  final Future<ShippingLabelResult> Function(Order order) onCreateShippingLabel;
  final void Function(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  )
  onBatchUpdateOrders;
  final Future<void> Function(ReviewSummary review, String status)
  onUpdateReview;
  final void Function(String audience, String subject, String body) onSendEmail;
  final AsyncValueChanged<EmailServerSettings> onSaveEmailSettings;
  final AsyncValueChanged<SiteStatus> onUpdateSiteStatus;
  final AsyncValueChanged<StoreInfo> onSaveStoreInfo;
  final Future<String> Function(UploadedImageFile file) onUploadStoreAsset;
  final AsyncValueChanged<TaxRule> onSaveTaxRule;
  final AsyncValueChanged<TaxRule> onDeleteTaxRule;
  final AsyncValueChanged<CustomerAccount> onSaveCustomer;
  final ValueChanged<String> onBlockIp;
  final AsyncValueChanged<BackendUser> onSaveBackendUser;
  final AsyncValueChanged<String> onApproveFragranceNote;

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  AdminSection _section = AdminSection.overview;
  Fragrance? _editing;

  double get _revenue =>
      widget.orders.fold(0, (total, order) => total + order.total);
  int get _inventory =>
      widget.products.fold(0, (total, product) => total + product.stock);
  int get _unitsSold =>
      widget.products.fold(0, (total, product) => total + product.sold);
  int get _reservedInventory =>
      widget.activeCarts.fold(0, (total, cart) => total + cart.itemCount);
  double get _cartValue =>
      widget.activeCarts.fold(0, (total, cart) => total + cart.value);
  int get _newUsersToday =>
      widget.customers.where((customer) => customer.joinedDaysAgo == 0).length;
  int get _newUsers7Days =>
      widget.dailyMetrics.fold(0, (total, metric) => total + metric.newUsers);
  double get _conversionRate {
    final visits = widget.dailyMetrics.fold(
      0,
      (total, metric) => total + metric.visits,
    );
    final orders = widget.dailyMetrics.fold(
      0,
      (total, metric) => total + metric.orders,
    );
    return visits == 0 ? 0 : orders / visits * 100;
  }

  List<Fragrance> get _lowStockProducts => widget.products
      .where((product) => product.stock <= product.reorderPoint)
      .toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Marketplace admin',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _editing = Fragrance(
                      id: DateTime.now().millisecondsSinceEpoch,
                      name: '',
                      type: 'Perfume',
                      brand: '',
                      notes: '',
                      size: '',
                      price: 0,
                      stock: 0,
                      sold: 0,
                      featuredColor: const Color(0xFFC88F52),
                      sku: '',
                      photoUrl: '',
                      vendor: '',
                      categoryId: widget.categories.isEmpty
                          ? 1
                          : widget.categories.first.id,
                    );
                    _section = AdminSection.catalog;
                  });
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add fragrance'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Operations, merchandising, customers, carts, inventory, and performance reporting.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _AdminSectionBar(
            selected: _section,
            onSelected: (section) => setState(() => _section = section),
          ),
          const SizedBox(height: 18),
          _buildSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    return switch (_section) {
      AdminSection.overview => _AdminOverview(
        revenue: _revenue,
        inventory: _inventory,
        unitsSold: _unitsSold,
        orderCount: widget.orders.length,
        reservedInventory: _reservedInventory,
        cartValue: _cartValue,
        newUsersToday: _newUsersToday,
        newUsers7Days: _newUsers7Days,
        conversionRate: _conversionRate,
        lowStockProducts: _lowStockProducts,
        activeCarts: widget.activeCarts,
        dailyMetrics: widget.dailyMetrics,
        products: widget.products,
        sessions: widget.activeUserSessions,
        orders: widget.orders,
        reviews: widget.reviews,
        onOpenSection: (section) => setState(() => _section = section),
      ),
      AdminSection.catalog => _CatalogSection(
        products: widget.products,
        categories: widget.categories,
        measurementSystem: widget.measurementSystem,
        noteOptions: widget.noteOptions,
        pendingNoteOptions: widget.pendingNoteOptions,
        familyOptions: widget.familyOptions,
        seasonOptions: widget.seasonOptions,
        occasionOptions: widget.occasionOptions,
        editing: _editing,
        onEdit: (product) => setState(() => _editing = product),
        onRemove: widget.onRemove,
        onApproveFragranceNote: widget.onApproveFragranceNote,
        onUploadImages: widget.onUploadImages,
        onCancel: () => setState(() => _editing = null),
        onSave: (product) async {
          await widget.onSave(product);
          if (mounted) {
            setState(() => _editing = null);
          }
        },
      ),
      AdminSection.categories => _CategoriesSection(
        categories: widget.categories,
        onSave: widget.onSaveCategory,
        onRemove: widget.onRemoveCategory,
      ),
      AdminSection.inventory => _InventorySection(
        products: widget.products,
        activeCarts: widget.activeCarts,
        lowStockProducts: _lowStockProducts,
        measurementSystem: widget.measurementSystem,
        onOpenReports: () => setState(() => _section = AdminSection.reports),
        onEdit: (product) {
          setState(() {
            _editing = product;
            _section = AdminSection.catalog;
          });
        },
        onRemove: widget.onRemove,
      ),
      AdminSection.carts => _CartsSection(activeCarts: widget.activeCarts),
      AdminSection.promotions => _PromotionsSection(
        coupons: widget.coupons,
        onSave: widget.onSaveCoupon,
      ),
      AdminSection.payments => _PaymentsSection(
        methods: widget.paymentMethods,
        onToggle: widget.onTogglePayment,
        onSave: widget.onSavePayment,
      ),
      AdminSection.shipping => _ShippingSection(
        options: widget.shippingOptions,
        credentials: widget.shippingCredentials,
        onSave: widget.onSaveShippingOption,
        onDelete: widget.onDeleteShippingOption,
        onSaveCredentials: widget.onSaveShippingCredentials,
      ),
      AdminSection.content => _ContentManagementSection(
        blocks: widget.contentBlocks,
        onSave: widget.onSaveContent,
      ),
      AdminSection.customers => _CustomersSection(
        customers: widget.customers,
        orders: widget.orders,
        activeCarts: widget.activeCarts,
        storeInfo: widget.storeInfo,
        onSaveCustomer: widget.onSaveCustomer,
        onBlockIp: widget.onBlockIp,
      ),
      AdminSection.orders => _OrdersSection(
        orders: widget.orders,
        shippingOptions: widget.shippingOptions,
        storeInfo: widget.storeInfo,
        onUpdateOrder: widget.onUpdateOrder,
        onCreateShippingLabel: widget.onCreateShippingLabel,
        onBatchUpdateOrders: widget.onBatchUpdateOrders,
      ),
      AdminSection.invoices => _InvoicesSection(
        orders: widget.orders,
        storeInfo: widget.storeInfo,
      ),
      AdminSection.reviews => _ReviewsSection(
        reviews: widget.reviews,
        onUpdateReview: widget.onUpdateReview,
      ),
      AdminSection.notifications => _NotificationsSection(
        notifications: widget.notifications,
      ),
      AdminSection.email => _EmailSection(
        customers: widget.customers,
        settings: widget.emailSettings,
        onSendEmail: widget.onSendEmail,
        onSaveSettings: widget.onSaveEmailSettings,
      ),
      AdminSection.site => _SiteStatusSection(
        status: widget.siteStatus,
        products: widget.products,
        onSave: widget.onUpdateSiteStatus,
      ),
      AdminSection.storeInfo => _StoreInfoSection(
        storeInfo: widget.storeInfo,
        onSave: widget.onSaveStoreInfo,
        onUploadAsset: widget.onUploadStoreAsset,
      ),
      AdminSection.taxes => _TaxRulesSection(
        taxRules: widget.taxRules,
        onSave: widget.onSaveTaxRule,
        onDelete: widget.onDeleteTaxRule,
      ),
      AdminSection.backendUsers => _BackendUsersSection(
        users: widget.backendUsers,
        onSave: widget.onSaveBackendUser,
        onBlockIp: widget.onBlockIp,
      ),
      AdminSection.analytics => _AnalyticsSection(
        sessions: widget.activeUserSessions,
        dailyMetrics: widget.dailyMetrics,
        products: widget.products,
        orders: widget.orders,
        activeCarts: widget.activeCarts,
        conversionRate: _conversionRate,
      ),
      AdminSection.reports => _ReportsSection(
        dailyMetrics: widget.dailyMetrics,
        products: widget.products,
        categories: widget.categories,
        orders: widget.orders,
        customers: widget.customers,
        coupons: widget.coupons,
        paymentMethods: widget.paymentMethods,
        shippingOptions: widget.shippingOptions,
        contentBlocks: widget.contentBlocks,
        reviews: widget.reviews,
        backendUsers: widget.backendUsers,
        conversionRate: _conversionRate,
      ),
    };
  }
}

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key, required this.error, required this.onLogin});

  final String error;
  final Future<void> Function(String email, String password) onLogin;

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onLogin(_email.text, _password.text);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 44,
                    color: const Color(0xFFC88F52),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Admin portal',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Admin email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    onSubmitted: (_) => unawaited(_submit()),
                  ),
                  if (widget.error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSectionBar extends StatelessWidget {
  const _AdminSectionBar({required this.selected, required this.onSelected});

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AdminSection.overview, Icons.space_dashboard_outlined, 'Overview'),
      (AdminSection.catalog, Icons.local_offer_outlined, 'Catalog'),
      (AdminSection.categories, Icons.category_outlined, 'Categories'),
      (AdminSection.inventory, Icons.inventory_2_outlined, 'Inventory'),
      (AdminSection.carts, Icons.shopping_cart_checkout, 'Carts'),
      (AdminSection.promotions, Icons.sell_outlined, 'Promotions'),
      (AdminSection.payments, Icons.payments_outlined, 'Payments'),
      (AdminSection.shipping, Icons.local_shipping_outlined, 'Shipping'),
      (AdminSection.content, Icons.view_quilt_outlined, 'Content'),
      (AdminSection.customers, Icons.group_outlined, 'Customers'),
      (AdminSection.orders, Icons.receipt_long_outlined, 'Orders'),
      (AdminSection.invoices, Icons.description_outlined, 'Invoices'),
      (AdminSection.reviews, Icons.reviews_outlined, 'Reviews'),
      (AdminSection.notifications, Icons.notifications_outlined, 'Alerts'),
      (AdminSection.email, Icons.outgoing_mail, 'Email'),
      (AdminSection.site, Icons.toggle_on_outlined, 'Site'),
      (
        AdminSection.storeInfo,
        Icons.store_mall_directory_outlined,
        'Store info',
      ),
      (AdminSection.taxes, Icons.request_quote_outlined, 'Taxes'),
      (AdminSection.backendUsers, Icons.admin_panel_settings_outlined, 'Users'),
      (AdminSection.reports, Icons.query_stats, 'Reports'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AdminSection>(
            value: selected,
            isExpanded: true,
            iconEnabledColor: Colors.white,
            dropdownColor: Colors.white,
            selectedItemBuilder: (context) => [
              for (final item in items)
                Row(
                  children: [
                    Icon(item.$2, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item.$1,
                  child: Row(
                    children: [
                      Icon(item.$2, color: const Color(0xFF23130D)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.$3)),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onSelected(value);
              }
            },
          ),
        ),
      ),
    );
  }
}

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

  List<DailyMetric> _lastMetrics(int days) {
    if (widget.dailyMetrics.length <= days) {
      return widget.dailyMetrics;
    }
    return widget.dailyMetrics.sublist(widget.dailyMetrics.length - days);
  }

  List<DailyMetric> get _windowMetrics => _lastMetrics(_windowDays);

  int get _ordersInWindow =>
      _windowMetrics.fold(0, (sum, metric) => sum + metric.orders);
  int get _usersInWindow =>
      _windowMetrics.fold(0, (sum, metric) => sum + metric.newUsers);
  double get _revenueInWindow =>
      _windowMetrics.fold(0, (sum, metric) => sum + metric.revenue);
  int get _visitsInWindow =>
      _windowMetrics.fold(0, (sum, metric) => sum + metric.visits);
  double get _averageOrderValue =>
      _ordersInWindow == 0 ? 0 : _revenueInWindow / _ordersInWindow;
  double get _revenuePerVisit =>
      _visitsInWindow == 0 ? 0 : _revenueInWindow / _visitsInWindow;

  @override
  Widget build(BuildContext context) {
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
                  'Revenue is ${currency(_revenueInWindow)} from $_ordersInWindow orders, with ${widget.conversionRate.toStringAsFixed(1)}% conversion and ${currency(_averageOrderValue)} average order value.',
                ),
                const SizedBox(height: 4),
                Text(
                  'Acquisition added $_usersInWindow users and generated $_visitsInWindow visits (${currency(_revenuePerVisit)} revenue per visit).',
                ),
              ],
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
              currency(_revenueInWindow),
            ),
            _MetricData(
              Icons.receipt_long_outlined,
              'Orders ($_windowDays days)',
              '$_ordersInWindow',
            ),
            _MetricData(
              Icons.analytics_outlined,
              'Avg order value',
              currency(_averageOrderValue),
            ),
            _MetricData(
              Icons.swap_vert_circle_outlined,
              'Revenue per visit',
              currency(_revenuePerVisit),
            ),
            _MetricData(
              Icons.person_add_alt,
              'New users today',
              '${widget.newUsersToday}',
            ),
            _MetricData(
              Icons.groups_outlined,
              'New users ($_windowDays days)',
              '$_usersInWindow',
            ),
            _MetricData(
              Icons.trending_up,
              'Conversion',
              '${widget.conversionRate.toStringAsFixed(1)}%',
            ),
            _MetricData(
              Icons.visibility_outlined,
              'Visits ($_windowDays days)',
              '$_visitsInWindow',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Trend charts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        _DashboardChartGrid(
          products: widget.products,
          dailyMetrics: _windowMetrics,
          activeCarts: widget.activeCarts,
          onOpenSection: widget.onOpenSection,
        ),
        const SizedBox(height: 18),
        Text(
          'Operational insights',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        _CommerceDashboardPanels(
          products: widget.products,
          metrics: _windowMetrics,
          activeCarts: widget.activeCarts,
          sessions: widget.sessions,
          orders: widget.orders,
          reviews: widget.reviews,
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
                  child: _DailyTrendPanel(metrics: _windowMetrics),
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
  const _MetricData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, this.tall = false});

  final List<_MetricData> metrics;
  final bool tall;

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
          childAspectRatio: tall
              ? (columns == 4 ? 1.45 : 1.25)
              : (columns == 4 ? 3.1 : 2.4),
          children: [
            for (final metric in metrics)
              _MetricCard(
                icon: metric.icon,
                label: metric.label,
                value: metric.value,
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
                              onTap: () => onOpenSection(AdminSection.catalog),
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
    required this.onTap,
  });

  final String title;
  final String action;
  final List<String> rows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
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
        ),
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
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                  const Icon(Icons.open_in_new, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(height: 160, child: child),
            ],
          ),
        ),
      ),
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

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.products,
    required this.categories,
    required this.measurementSystem,
    required this.noteOptions,
    required this.pendingNoteOptions,
    required this.familyOptions,
    required this.seasonOptions,
    required this.occasionOptions,
    required this.editing,
    required this.onEdit,
    required this.onRemove,
    required this.onApproveFragranceNote,
    required this.onUploadImages,
    required this.onCancel,
    required this.onSave,
  });

  final List<Fragrance> products;
  final List<Category> categories;
  final MeasurementSystem measurementSystem;
  final List<String> noteOptions;
  final List<String> pendingNoteOptions;
  final List<String> familyOptions;
  final List<String> seasonOptions;
  final List<String> occasionOptions;
  final Fragrance? editing;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;
  final AsyncValueChanged<String> onApproveFragranceNote;
  final Future<List<ProductImage>> Function(
    Fragrance product,
    List<UploadedImageFile> files,
  )
  onUploadImages;
  final VoidCallback onCancel;
  final AsyncValueChanged<Fragrance> onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 980;
        final grid = _CatalogGrid(
          products: products,
          onEdit: onEdit,
          onRemove: onRemove,
        );
        final editor = editing == null
            ? const _EmptyState(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Product media and merchandising',
                body:
                    'Select a fragrance or add a new one to manage photos, SKU, vendor, stock, and pricing.',
              )
            : ProductEditor(
                key: ValueKey(editing!.id),
                product: editing!,
                categories: categories,
                measurementSystem: measurementSystem,
                noteOptions: noteOptions,
                familyOptions: familyOptions,
                seasonOptions: seasonOptions,
                occasionOptions: occasionOptions,
                onUploadImages: onUploadImages,
                onCancel: onCancel,
                onSave: onSave,
              );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pendingNoteOptions.isNotEmpty) ...[
                _PendingNotesPanel(
                  notes: pendingNoteOptions,
                  onApprove: onApproveFragranceNote,
                ),
                const SizedBox(height: 18),
              ],
              grid,
              const SizedBox(height: 18),
              editor,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pendingNoteOptions.isNotEmpty) ...[
              _PendingNotesPanel(
                notes: pendingNoteOptions,
                onApprove: onApproveFragranceNote,
              ),
              const SizedBox(height: 18),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: grid),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: editor),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PendingNotesPanel extends StatelessWidget {
  const _PendingNotesPanel({required this.notes, required this.onApprove});

  final List<String> notes;
  final AsyncValueChanged<String> onApprove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom notes awaiting approval',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final note in notes)
                  ActionChip(
                    avatar: const Icon(Icons.check, size: 18),
                    label: Text(note),
                    onPressed: () => onApprove(note),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({
    required this.products,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Fragrance> products;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760
            ? 3
            : constraints.maxWidth > 520
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.2 : 1.25,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: product.featuredColor.withValues(alpha: 0.18),
                      child: ProductPhoto(product: product, iconSize: 42),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(product.sku),
                        const SizedBox(height: 6),
                        Text('${product.vendor} • ${product.size}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => onEdit(product),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              tooltip: 'Remove',
                              onPressed: () async => onRemove(product),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.products,
    required this.activeCarts,
    required this.lowStockProducts,
    required this.measurementSystem,
    required this.onOpenReports,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Fragrance> products;
  final List<ActiveCart> activeCarts;
  final List<Fragrance> lowStockProducts;
  final MeasurementSystem measurementSystem;
  final VoidCallback onOpenReports;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InventoryTable(
          products: products,
          activeCarts: activeCarts,
          measurementSystem: measurementSystem,
          onEdit: onEdit,
          onRemove: onRemove,
        ),
        const SizedBox(height: 16),
        _LowStockPanel(products: lowStockProducts),
        const SizedBox(height: 16),
        _InventoryDownloadCard(onOpenReports: onOpenReports),
      ],
    );
  }
}

class _InventoryDownloadCard extends StatelessWidget {
  const _InventoryDownloadCard({required this.onOpenReports});

  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Database export',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose tables and download CSV, JSON, or SQL from Reports.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenReports,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download database'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalTableScroller extends StatefulWidget {
  const _HorizontalTableScroller({required this.child});

  final Widget child;

  @override
  State<_HorizontalTableScroller> createState() =>
      _HorizontalTableScrollerState();
}

class _HorizontalTableScrollerState extends State<_HorizontalTableScroller> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class _CartsSection extends StatelessWidget {
  const _CartsSection({required this.activeCarts});

  final List<ActiveCart> activeCarts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Active carts and reserved inventory',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (activeCarts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active cart reservations.'),
            ),
          )
        else
          for (final cart in activeCarts)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.shopping_cart_checkout),
                title: Text('${cart.id} • ${cart.customer}'),
                subtitle: Text(
                  '${cart.itemCount} unit(s) reserved • ${currency(cart.value)} • ${cart.minutesAgo} min ago',
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final line in cart.lines)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      leading: SizedBox.square(
                        dimension: 42,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ProductPhoto(product: line.product),
                        ),
                      ),
                      title: Text(line.product.name),
                      subtitle: Text(
                        '${line.quantity} reserved from ${line.stockAvailable} on hand',
                      ),
                      trailing: Text(currency(line.total)),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection({
    required this.categories,
    required this.onSave,
    required this.onRemove,
  });

  final List<Category> categories;
  final AsyncValueChanged<Category> onSave;
  final ValueChanged<Category> onRemove;

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  Category? _editing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: _HorizontalTableScroller(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Order')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Visible')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final category in widget.categories)
                        DataRow(
                          cells: [
                            DataCell(Text('${category.sortOrder}')),
                            DataCell(Text(category.name)),
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Text(category.description),
                              ),
                            ),
                            DataCell(Text(category.isVisible ? 'Yes' : 'No')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        setState(() => _editing = category),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Hide',
                                    onPressed: () => widget.onRemove(category),
                                    icon: const Icon(
                                      Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: CategoryEditor(
                category: _editing,
                nextId: DateTime.now().millisecondsSinceEpoch,
                onSave: (category) async {
                  await widget.onSave(category);
                  if (mounted) {
                    setState(() => _editing = null);
                  }
                },
                onNew: () => setState(() => _editing = null),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({
    super.key,
    required this.category,
    required this.nextId,
    required this.onSave,
    required this.onNew,
  });

  final Category? category;
  final int nextId;
  final AsyncValueChanged<Category> onSave;
  final VoidCallback onNew;

  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _sortOrder;
  bool _isVisible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CategoryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category?.id != widget.category?.id) {
      _name.dispose();
      _description.dispose();
      _sortOrder.dispose();
      _load();
    }
  }

  void _load() {
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _sortOrder = TextEditingController(
      text: '${widget.category?.sortOrder ?? 10}',
    );
    _isVisible = widget.category?.isVisible ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Category manager',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sortOrder,
              decoration: const InputDecoration(labelText: 'Sort order'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible on storefront'),
              value: _isVisible,
              onChanged: (value) => setState(() => _isVisible = value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNew,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        Category(
          id: widget.category?.id ?? widget.nextId,
          name: _name.text.trim().isEmpty ? 'New category' : _name.text.trim(),
          description: _description.text.trim(),
          sortOrder: int.tryParse(_sortOrder.text) ?? 10,
          isVisible: _isVisible,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _PromotionsSection extends StatefulWidget {
  const _PromotionsSection({required this.coupons, required this.onSave});

  final List<CouponRule> coupons;
  final AsyncValueChanged<CouponRule> onSave;

  @override
  State<_PromotionsSection> createState() => _PromotionsSectionState();
}

class _PromotionsSectionState extends State<_PromotionsSection> {
  CouponRule? _editing;
  bool _showArchive = false;

  @override
  Widget build(BuildContext context) {
    final visibleCoupons = widget.coupons
        .where((coupon) => coupon.isArchived == _showArchive)
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 7 : 0,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.sell_outlined),
                            label: Text('Active'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.archive_outlined),
                            label: Text('Archive'),
                          ),
                        ],
                        selected: {_showArchive},
                        onSelectionChanged: (value) {
                          setState(() {
                            _showArchive = value.first;
                            _editing = null;
                          });
                        },
                      ),
                    ),
                    if (visibleCoupons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _showArchive
                              ? 'No archived coupon codes.'
                              : 'No active coupon codes.',
                        ),
                      )
                    else
                      _HorizontalTableScroller(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Value')),
                            DataColumn(label: Text('Min spend')),
                            DataColumn(label: Text('Usage')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (final coupon in visibleCoupons)
                              DataRow(
                                cells: [
                                  DataCell(Text(coupon.code)),
                                  DataCell(Text(coupon.name)),
                                  DataCell(Text(coupon.type)),
                                  DataCell(
                                    Text(
                                      coupon.type == 'Percent'
                                          ? '${coupon.value.toStringAsFixed(0)}%'
                                          : currency(coupon.value),
                                    ),
                                  ),
                                  DataCell(Text(currency(coupon.minimumSpend))),
                                  DataCell(
                                    Text('${coupon.used}/${coupon.usageLimit}'),
                                  ),
                                  DataCell(
                                    Text(
                                      coupon.isArchived
                                          ? 'Archived'
                                          : coupon.isActive
                                          ? 'Active'
                                          : 'Inactive',
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          onPressed: () =>
                                              setState(() => _editing = coupon),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: coupon.isArchived
                                              ? 'Unarchive'
                                              : 'Archive',
                                          onPressed: () => _setArchived(
                                            coupon,
                                            !coupon.isArchived,
                                          ),
                                          icon: Icon(
                                            coupon.isArchived
                                                ? Icons.unarchive_outlined
                                                : Icons.archive_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: CouponEditor(
                coupon: _editing,
                onSave: (coupon) async {
                  await widget.onSave(coupon);
                  if (mounted) {
                    setState(() => _editing = null);
                  }
                },
                onNew: () => setState(() => _editing = null),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setArchived(CouponRule coupon, bool archived) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(
        CouponRule(
          code: coupon.code,
          name: coupon.name,
          type: coupon.type,
          value: coupon.value,
          minimumSpend: coupon.minimumSpend,
          usageLimit: coupon.usageLimit,
          used: coupon.used,
          starts: coupon.starts,
          ends: coupon.ends,
          isActive: archived ? false : coupon.isActive,
          isArchived: archived,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _editing = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(archived ? 'Coupon archived.' : 'Coupon unarchived.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            archived
                ? 'Coupon archive failed: $error'
                : 'Coupon unarchive failed: $error',
          ),
        ),
      );
    }
  }
}

class CouponEditor extends StatefulWidget {
  const CouponEditor({
    super.key,
    required this.coupon,
    required this.onSave,
    required this.onNew,
  });

  final CouponRule? coupon;
  final AsyncValueChanged<CouponRule> onSave;
  final VoidCallback onNew;

  @override
  State<CouponEditor> createState() => _CouponEditorState();
}

class _CouponEditorState extends State<CouponEditor> {
  late TextEditingController _code;
  late TextEditingController _name;
  late TextEditingController _value;
  late TextEditingController _minimumSpend;
  late TextEditingController _usageLimit;
  late String _type;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CouponEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coupon?.code != widget.coupon?.code) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    _code = TextEditingController(text: widget.coupon?.code ?? '');
    _name = TextEditingController(text: widget.coupon?.name ?? '');
    _value = TextEditingController(text: '${widget.coupon?.value ?? 10}');
    _minimumSpend = TextEditingController(
      text: '${widget.coupon?.minimumSpend ?? 0}',
    );
    _usageLimit = TextEditingController(
      text: '${widget.coupon?.usageLimit ?? 100}',
    );
    _type = widget.coupon?.type ?? 'Percent';
    _active = widget.coupon?.isActive ?? true;
  }

  void _disposeControllers() {
    _code.dispose();
    _name.dispose();
    _value.dispose();
    _minimumSpend.dispose();
    _usageLimit.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Discount rule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Coupon code'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Promotion name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Discount type'),
              items: const [
                DropdownMenuItem(value: 'Percent', child: Text('Percent off')),
                DropdownMenuItem(
                  value: 'Fixed amount',
                  child: Text('Fixed amount off'),
                ),
                DropdownMenuItem(
                  value: 'Free shipping',
                  child: Text('Free shipping'),
                ),
                DropdownMenuItem(
                  value: 'Buy X get Y',
                  child: Text('Buy X get Y'),
                ),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _value,
                    decoration: const InputDecoration(labelText: 'Value'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _minimumSpend,
                    decoration: const InputDecoration(
                      labelText: 'Minimum spend',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _usageLimit,
              decoration: const InputDecoration(labelText: 'Usage limit'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active promotion'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNew,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        CouponRule(
          code: _code.text.trim().isEmpty
              ? 'NEWCODE'
              : _code.text.trim().toUpperCase(),
          name: _name.text.trim().isEmpty ? 'New promotion' : _name.text.trim(),
          type: _type,
          value: double.tryParse(_value.text) ?? 0,
          minimumSpend: double.tryParse(_minimumSpend.text) ?? 0,
          usageLimit: int.tryParse(_usageLimit.text) ?? 100,
          used: widget.coupon?.used ?? 0,
          starts: widget.coupon?.starts ?? '2026-06-01',
          ends: widget.coupon?.ends ?? '2026-12-31',
          isActive: _active,
          isArchived: widget.coupon?.isArchived ?? false,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Promotion saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Promotion save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _PaymentsSection extends StatefulWidget {
  const _PaymentsSection({
    required this.methods,
    required this.onToggle,
    required this.onSave,
  });

  final List<PaymentMethodConfig> methods;
  final AsyncValueChanged<PaymentMethodConfig> onToggle;
  final AsyncValueChanged<PaymentMethodConfig> onSave;

  @override
  State<_PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends State<_PaymentsSection> {
  PaymentMethodConfig? _editing;

  @override
  Widget build(BuildContext context) {
    final connected = widget.methods.where((method) {
      return method.publicKey.isNotEmpty || method.merchantId.isNotEmpty;
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            const _MetricData(Icons.credit_card, 'Cards', 'Stripe-ready'),
            _MetricData(
              Icons.account_balance_wallet_outlined,
              'Wallets',
              '${widget.methods.where((m) => m.isEnabled).length} enabled',
            ),
            _MetricData(Icons.link_outlined, 'Connected', '$connected methods'),
            const _MetricData(
              Icons.security_outlined,
              'Fraud tools',
              'Rules needed',
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 920;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: Card(
                    child: Column(
                      children: [
                        for (final method in widget.methods)
                          ListTile(
                            leading: Switch(
                              value: method.isEnabled,
                              onChanged: (_) => widget.onToggle(method),
                            ),
                            title: Text('${method.name} • ${method.provider}'),
                            subtitle: Text(
                              '${method.status} • ${method.mode} • ${method.fee} • ${method.settlement}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Configure',
                              onPressed: () =>
                                  setState(() => _editing = method),
                              icon: const Icon(Icons.settings_outlined),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 5 : 0,
                  child: _PaymentMethodEditor(
                    method:
                        _editing ??
                        (widget.methods.isEmpty ? null : widget.methods.first),
                    onSave: (method) async {
                      await widget.onSave(method);
                      setState(() => _editing = method);
                    },
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

class _PaymentMethodEditor extends StatefulWidget {
  const _PaymentMethodEditor({required this.method, required this.onSave});

  final PaymentMethodConfig? method;
  final AsyncValueChanged<PaymentMethodConfig> onSave;

  @override
  State<_PaymentMethodEditor> createState() => _PaymentMethodEditorState();
}

class _PaymentMethodEditorState extends State<_PaymentMethodEditor> {
  late TextEditingController _publicKey;
  late TextEditingController _merchantId;
  late TextEditingController _apiSecret;
  late TextEditingController _webhookUrl;
  late TextEditingController _descriptor;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PaymentMethodEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.method != widget.method) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    final method = widget.method;
    _publicKey = TextEditingController(text: method?.publicKey ?? '');
    _merchantId = TextEditingController(text: method?.merchantId ?? '');
    _apiSecret = TextEditingController(text: method?.apiSecret ?? '');
    _webhookUrl = TextEditingController(text: method?.webhookUrl ?? '');
    _descriptor = TextEditingController(
      text: method?.statementDescriptor ?? 'EGBE ANOM',
    );
    _mode = method?.mode ?? 'Test';
  }

  void _disposeControllers() {
    _publicKey.dispose();
    _merchantId.dispose();
    _apiSecret.dispose();
    _webhookUrl.dispose();
    _descriptor.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    if (method == null) {
      return const _EmptyState(
        icon: Icons.payments_outlined,
        title: 'No payment methods',
        body:
            'Add payment providers in the admin database to configure merchant accounts.',
      );
    }
    final provider = method.provider.toLowerCase();
    final labels = _PaymentProviderLabels.forProvider(provider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Provider setup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text('${method.name} • ${method.provider}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Mode'),
              items: const [
                DropdownMenuItem(value: 'Test', child: Text('Test')),
                DropdownMenuItem(value: 'Live', child: Text('Live')),
              ],
              onChanged: (value) => setState(() => _mode = value ?? _mode),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _publicKey,
              decoration: InputDecoration(
                labelText: labels.publicKey,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _merchantId,
              decoration: InputDecoration(
                labelText: labels.merchantId,
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apiSecret,
              decoration: InputDecoration(
                labelText: labels.apiSecret,
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _webhookUrl,
              decoration: InputDecoration(
                labelText: labels.webhook,
                helperText: labels.returnUrls,
                prefixIcon: const Icon(Icons.webhook_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptor,
              decoration: InputDecoration(
                labelText: labels.descriptor,
                prefixIcon: const Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Text(labels.instructions),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => widget.onSave(
                PaymentMethodConfig(
                  name: method.name,
                  provider: method.provider,
                  status:
                      _publicKey.text.trim().isEmpty &&
                          _merchantId.text.trim().isEmpty
                      ? 'Not connected'
                      : 'Configured',
                  fee: method.fee,
                  settlement: method.settlement,
                  isEnabled: method.isEnabled,
                  mode: _mode,
                  publicKey: _publicKey.text.trim(),
                  merchantId: _merchantId.text.trim(),
                  apiSecret: _apiSecret.text.trim(),
                  webhookUrl: _webhookUrl.text.trim(),
                  statementDescriptor: _descriptor.text.trim(),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save provider settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProviderLabels {
  const _PaymentProviderLabels({
    required this.publicKey,
    required this.merchantId,
    required this.apiSecret,
    required this.webhook,
    required this.descriptor,
    required this.returnUrls,
    required this.instructions,
  });

  final String publicKey;
  final String merchantId;
  final String apiSecret;
  final String webhook;
  final String descriptor;
  final String returnUrls;
  final String instructions;

  factory _PaymentProviderLabels.forProvider(String provider) {
    if (provider.contains('stripe')) {
      return const _PaymentProviderLabels(
        publicKey: 'Stripe publishable key',
        merchantId: 'Stripe account ID',
        apiSecret: 'Stripe secret key',
        webhook: 'Stripe webhook endpoint',
        descriptor: 'Stripe statement descriptor',
        returnUrls:
            'Success: /?payment=success or /payment-success • Cancel: /?payment=failed or /payment-failed',
        instructions:
            'Store Stripe secret keys server-side. Use Checkout success_url and cancel_url for the return pages.',
      );
    }
    if (provider.contains('paypal')) {
      return const _PaymentProviderLabels(
        publicKey: 'PayPal client ID',
        merchantId: 'PayPal merchant ID',
        apiSecret: 'PayPal client secret',
        webhook: 'PayPal webhook ID / endpoint',
        descriptor: 'PayPal invoice prefix',
        returnUrls:
            'Return URL: /?payment=success • Cancel URL: /?payment=failed',
        instructions:
            'Store the PayPal client secret server-side. Use PayPal return_url and cancel_url for checkout approval results.',
      );
    }
    if (provider.contains('square')) {
      return const _PaymentProviderLabels(
        publicKey: 'Square application ID',
        merchantId: 'Square location ID',
        apiSecret: 'Square access token',
        webhook: 'Square webhook signature key / endpoint',
        descriptor: 'Square statement descriptor',
        returnUrls:
            'Square Web Payments SDK should return to /payment-success or /payment-failed after backend capture.',
        instructions:
            'Store the Square access token server-side. Browser checkout should only use the application ID and location ID.',
      );
    }
    if (provider.contains('apple') || provider.contains('google')) {
      return const _PaymentProviderLabels(
        publicKey: 'Wallet merchant identifier',
        merchantId: 'Processor merchant account',
        apiSecret: 'Processor certificate or token',
        webhook: 'Wallet processor callback',
        descriptor: 'Wallet display name',
        returnUrls:
            'Wallet authorization should resolve to /payment-success or /payment-failed after backend capture.',
        instructions:
            'Apple Pay and Google Pay are device wallet buttons. Customers do not type card details here; wallet tokens must be validated and captured server-side through the configured card processor.',
      );
    }
    return const _PaymentProviderLabels(
      publicKey: 'Provider public key / client ID',
      merchantId: 'Provider merchant account ID',
      apiSecret: 'Provider secret key or API token',
      webhook: 'Provider webhook endpoint',
      descriptor: 'Statement descriptor',
      returnUrls:
          'Success: /payment-success or /?payment=success • Failure: /payment-failed or /?payment=failed',
      instructions:
          'Secret keys must be stored in a secure server-side payment backend.',
    );
  }
}

class _ShippingSection extends StatefulWidget {
  const _ShippingSection({
    required this.options,
    required this.credentials,
    required this.onSave,
    required this.onDelete,
    required this.onSaveCredentials,
  });

  final List<ShippingOption> options;
  final Map<String, ShippingCarrierCredentials> credentials;
  final AsyncValueChanged<ShippingOption> onSave;
  final AsyncValueChanged<ShippingOption> onDelete;
  final Future<void> Function(
    String carrier,
    ShippingCarrierCredentials credentials,
  )
  onSaveCredentials;

  @override
  State<_ShippingSection> createState() => _ShippingSectionState();
}

class _ShippingSectionState extends State<_ShippingSection> {
  String _selectedCarrier = 'USPS';
  String? _editingCarrier;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.options.where((option) => option.isEnabled).length;
    final enabledCarriers = _carriers
        .where((carrier) => _carrierOptions(carrier).any((o) => o.isEnabled))
        .length;
    final flatRate = _flatRateOption;
    final selectedMethods = _carrierMethods(_selectedCarrier);
    final selectedOptions = _carrierOptions(_selectedCarrier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.local_shipping_outlined,
              'Checkout options',
              '$enabled live',
            ),
            _MetricData(
              Icons.hub_outlined,
              'Providers on',
              '$enabledCarriers / ${_carriers.length}',
            ),
            _MetricData(
              Icons.route_outlined,
              'Carrier methods',
              '${widget.options.where((option) => !_isFlatRate(option)).length}',
            ),
            const _MetricData(Icons.print_outlined, 'Labels', 'Order screen'),
          ],
        ),
        const SizedBox(height: 16),
        _FlatRateShippingCard(
          option: flatRate,
          onSave: widget.onSave,
          onDisable: () => widget.onSave(
            ShippingOption(
              id: flatRate.id,
              name: flatRate.name,
              carrier: flatRate.carrier,
              service: flatRate.service,
              priority: flatRate.priority,
              price: flatRate.price,
              estimatedDays: flatRate.estimatedDays,
              isEnabled: false,
              sortOrder: flatRate.sortOrder,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 1000
                ? 4
                : constraints.maxWidth > 720
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 4.2 : 2.7,
              children: [
                for (final carrier in _carriers)
                  _ShippingProviderCard(
                    carrier: carrier,
                    enabled: _carrierOptions(
                      carrier,
                    ).any((option) => option.isEnabled),
                    selected: carrier == _selectedCarrier,
                    configured:
                        (widget.credentials[carrier] ??
                                const ShippingCarrierCredentials())
                            .isConfigured,
                    methodCount: _carrierMethods(carrier).length,
                    selectedMethodCount: _carrierOptions(
                      carrier,
                    ).where((option) => option.isEnabled).length,
                    onSelected: () =>
                        setState(() => _selectedCarrier = carrier),
                    onEnabledChanged: (value) => _toggleCarrier(carrier, value),
                    onEdit: () => setState(() => _editingCarrier = carrier),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 5 : 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipping providers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Turn carriers on or off here. Select a provider to choose which carrier-provided services appear at checkout.',
                          ),
                          const SizedBox(height: 12),
                          for (final carrier in _carriers)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () =>
                                  setState(() => _selectedCarrier = carrier),
                              leading: Icon(
                                carrier == _selectedCarrier
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(carrier),
                              subtitle: Text(
                                '${_carrierOptions(carrier).where((o) => o.isEnabled).length} checkout method(s) selected',
                              ),
                              trailing: Switch(
                                value: _carrierOptions(
                                  carrier,
                                ).any((option) => option.isEnabled),
                                onChanged: (value) =>
                                    _toggleCarrier(carrier, value),
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
                  flex: wide ? 7 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_editingCarrier != null) ...[
                        _ShippingProviderCredentialsCard(
                          carrier: _editingCarrier!,
                          credentials:
                              widget.credentials[_editingCarrier!] ??
                              const ShippingCarrierCredentials(),
                          onSave: (credentials) {
                            final carrier = _editingCarrier!;
                            setState(() {
                              _editingCarrier = null;
                            });
                            widget.onSaveCredentials(carrier, credentials);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$carrier credentials saved for backend shipping services.',
                                ),
                              ),
                            );
                          },
                          onCancel: () =>
                              setState(() => _editingCarrier = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedCarrier carrier methods',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Prices and delivery windows come from the carrier rate adapter once credentials are connected. Select the methods customers can choose at checkout.',
                              ),
                              const SizedBox(height: 12),
                              for (final method in selectedMethods)
                                _ShippingMethodTile(
                                  method: method,
                                  option: selectedOptions.firstWhere(
                                    (option) =>
                                        _sameCarrier(
                                          option.carrier,
                                          method.carrier,
                                        ) &&
                                        option.service == method.service,
                                    orElse: () =>
                                        method.toOption(sortOrder: 50),
                                  ),
                                  onChanged: (value) => _saveMethodSelection(
                                    method,
                                    selectedOptions.firstWhere(
                                      (option) =>
                                          _sameCarrier(
                                            option.carrier,
                                            method.carrier,
                                          ) &&
                                          option.service == method.service,
                                      orElse: () =>
                                          method.toOption(sortOrder: 50),
                                    ),
                                    value,
                                  ),
                                  onDelete: () {
                                    final existing = selectedOptions
                                        .where(
                                          (option) =>
                                              option.service == method.service,
                                        )
                                        .toList();
                                    for (final option in existing) {
                                      widget.onDelete(option);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static const List<String> _carriers = ['FedEx', 'UPS', 'USPS', 'DHL'];

  ShippingOption get _flatRateOption {
    return widget.options.firstWhere(
      _isFlatRate,
      orElse: () => ShippingOption(
        id: 'ship-flat-rate',
        name: 'Flat rate shipping',
        carrier: 'Flat Rate',
        service: 'Storewide shipping',
        priority: 'Standard',
        price: 7.95,
        estimatedDays: '3-5 business days',
        isEnabled: false,
        sortOrder: 5,
      ),
    );
  }

  bool _isFlatRate(ShippingOption option) =>
      option.carrier.trim().toLowerCase() == 'flat rate' ||
      option.id == 'ship-flat-rate';

  List<ShippingOption> _carrierOptions(String carrier) => widget.options
      .where((option) => _sameCarrier(option.carrier, carrier))
      .toList();

  void _toggleCarrier(String carrier, bool enabled) {
    final options = _carrierOptions(carrier);
    setState(() => _selectedCarrier = carrier);
    if (options.isEmpty && enabled) {
      final first = _carrierMethods(carrier).first;
      _saveMethodSelection(first, first.toOption(sortOrder: 40), true);
      return;
    }
    for (final option in options) {
      option.isEnabled = enabled;
      widget.onSave(option);
    }
  }

  void _saveMethodSelection(
    _CarrierShippingMethod method,
    ShippingOption option,
    bool enabled,
  ) {
    widget.onSave(
      ShippingOption(
        id: option.id.isEmpty ? method.id : option.id,
        name: option.name.isEmpty ? method.customerLabel : option.name,
        carrier: method.carrier,
        service: method.service,
        priority: method.priority,
        price: method.price,
        estimatedDays: method.estimatedDays,
        isEnabled: enabled,
        sortOrder: option.sortOrder,
      ),
    );
    setState(() {});
  }

  List<_CarrierShippingMethod> _carrierMethods(String carrier) {
    return switch (carrier.toUpperCase()) {
      'FEDEX' => const [
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: 'Ground',
          priority: 'Standard',
          estimatedDays: '3-5 business days',
          price: 9.95,
        ),
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: 'Home Delivery',
          priority: 'Standard',
          estimatedDays: '2-5 business days',
          price: 10.95,
        ),
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: '2 Day',
          priority: 'Priority',
          estimatedDays: '2 business days',
          price: 18.95,
        ),
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: 'Priority Overnight',
          priority: 'Express',
          estimatedDays: 'Next business day',
          price: 34.95,
        ),
      ],
      'UPS' => const [
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: 'Ground',
          priority: 'Standard',
          estimatedDays: '3-5 business days',
          price: 9.95,
        ),
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: '3 Day Select',
          priority: 'Priority',
          estimatedDays: '3 business days',
          price: 16.95,
        ),
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: '2nd Day Air',
          priority: 'Priority',
          estimatedDays: '2 business days',
          price: 22.95,
        ),
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: 'Next Day Air',
          priority: 'Express',
          estimatedDays: 'Next business day',
          price: 38.95,
        ),
      ],
      'DHL' => const [
        _CarrierShippingMethod(
          carrier: 'DHL',
          service: 'Express Worldwide',
          priority: 'Express',
          estimatedDays: '1-3 business days',
          price: 39.95,
        ),
        _CarrierShippingMethod(
          carrier: 'DHL',
          service: 'Express Easy',
          priority: 'Priority',
          estimatedDays: '2-5 business days',
          price: 29.95,
        ),
        _CarrierShippingMethod(
          carrier: 'DHL',
          service: 'Packet Plus',
          priority: 'Standard',
          estimatedDays: '4-8 business days',
          price: 14.95,
        ),
      ],
      _ => const [
        _CarrierShippingMethod(
          carrier: 'USPS',
          service: 'Ground Advantage',
          priority: 'Standard',
          estimatedDays: '3-5 business days',
          price: 7.95,
        ),
        _CarrierShippingMethod(
          carrier: 'USPS',
          service: 'Priority Mail',
          priority: 'Priority',
          estimatedDays: '1-3 business days',
          price: 11.95,
        ),
        _CarrierShippingMethod(
          carrier: 'USPS',
          service: 'Priority Mail Express',
          priority: 'Express',
          estimatedDays: '1-2 business days',
          price: 29.95,
        ),
      ],
    };
  }

  bool _sameCarrier(String left, String right) =>
      left.trim().toUpperCase() == right.trim().toUpperCase();
}

class _CarrierShippingMethod {
  const _CarrierShippingMethod({
    required this.carrier,
    required this.service,
    required this.priority,
    required this.estimatedDays,
    required this.price,
  });

  final String carrier;
  final String service;
  final String priority;
  final String estimatedDays;
  final double price;

  String get id =>
      'ship-${carrier.toLowerCase().replaceAll(' ', '-')}-${service.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
  String get customerLabel => '$carrier $service';

  ShippingOption toOption({required int sortOrder}) {
    return ShippingOption(
      id: id,
      name: customerLabel,
      carrier: carrier,
      service: service,
      priority: priority,
      price: price,
      estimatedDays: estimatedDays,
      isEnabled: false,
      sortOrder: sortOrder,
    );
  }
}

class _FlatRateShippingCard extends StatefulWidget {
  const _FlatRateShippingCard({
    required this.option,
    required this.onSave,
    required this.onDisable,
  });

  final ShippingOption option;
  final AsyncValueChanged<ShippingOption> onSave;
  final VoidCallback onDisable;

  @override
  State<_FlatRateShippingCard> createState() => _FlatRateShippingCardState();
}

class _FlatRateShippingCardState extends State<_FlatRateShippingCard> {
  late final TextEditingController _price;
  late final TextEditingController _days;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: widget.option.price.toString());
    _days = TextEditingController(text: widget.option.estimatedDays);
  }

  @override
  void didUpdateWidget(covariant _FlatRateShippingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option.price != widget.option.price) {
      _price.text = widget.option.price.toString();
    }
    if (oldWidget.option.estimatedDays != widget.option.estimatedDays) {
      _days.text = widget.option.estimatedDays;
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 720;
            final priceField = TextField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Flat shipping price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            );
            final daysField = TextField(
              controller: _days,
              decoration: const InputDecoration(
                labelText: 'Delivery estimate',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            );
            final fields = wide
                ? Row(
                    children: [
                      Expanded(child: priceField),
                      const SizedBox(width: 10),
                      Expanded(child: daysField),
                    ],
                  )
                : Column(
                    children: [
                      priceField,
                      const SizedBox(height: 10),
                      daysField,
                    ],
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Flat rate shipping',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: const Text(
                    'Use one storewide shipping price regardless of carrier.',
                  ),
                  value: widget.option.isEnabled,
                  onChanged: (value) {
                    if (value) {
                      _save(isEnabled: true);
                    } else {
                      widget.onDisable();
                    }
                  },
                ),
                const SizedBox(height: 10),
                fields,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _save(isEnabled: true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save flat rate'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _save({required bool isEnabled}) {
    widget.onSave(
      ShippingOption(
        id: widget.option.id,
        name: 'Flat rate shipping',
        carrier: 'Flat Rate',
        service: 'Storewide shipping',
        priority: 'Standard',
        price: double.tryParse(_price.text) ?? 0,
        estimatedDays: _days.text.trim().isEmpty
            ? '3-5 business days'
            : _days.text.trim(),
        isEnabled: isEnabled,
        sortOrder: widget.option.sortOrder,
      ),
    );
  }
}

class _ShippingProviderCard extends StatelessWidget {
  const _ShippingProviderCard({
    required this.carrier,
    required this.enabled,
    required this.selected,
    required this.configured,
    required this.methodCount,
    required this.selectedMethodCount,
    required this.onSelected,
    required this.onEnabledChanged,
    required this.onEdit,
  });

  final String carrier;
  final bool enabled;
  final bool selected;
  final bool configured;
  final int methodCount;
  final int selectedMethodCount;
  final VoidCallback onSelected;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xFFFFF7EA) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: enabled ? const Color(0xFF27724E) : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      carrier,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$selectedMethodCount of $methodCount methods selected',
                    ),
                    Text(
                      configured ? 'Credentials added' : 'Credentials needed',
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit provider credentials',
                onPressed: onEdit,
                icon: const Icon(Icons.key_outlined),
              ),
              Switch(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingMethodTile extends StatelessWidget {
  const _ShippingMethodTile({
    required this.method,
    required this.option,
    required this.onChanged,
    required this.onDelete,
  });

  final _CarrierShippingMethod method;
  final ShippingOption option;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Switch(value: option.isEnabled, onChanged: onChanged),
      title: Text(method.customerLabel),
      subtitle: Text('${method.priority} • ${method.estimatedDays}'),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(currency(method.price)),
          IconButton(
            tooltip: 'Remove saved checkout method',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ShippingProviderCredentialsCard extends StatefulWidget {
  const _ShippingProviderCredentialsCard({
    required this.carrier,
    required this.credentials,
    required this.onSave,
    required this.onCancel,
  });

  final String carrier;
  final ShippingCarrierCredentials credentials;
  final ValueChanged<ShippingCarrierCredentials> onSave;
  final VoidCallback onCancel;

  @override
  State<_ShippingProviderCredentialsCard> createState() =>
      _ShippingProviderCredentialsCardState();
}

class _ShippingProviderCredentialsCardState
    extends State<_ShippingProviderCredentialsCard> {
  late final TextEditingController _customerId;
  late final TextEditingController _accountNumber;
  late final TextEditingController _apiKey;
  late final TextEditingController _apiSecret;
  late final TextEditingController _meterNumber;
  late final TextEditingController _clientId;
  late final TextEditingController _clientSecret;

  @override
  void initState() {
    super.initState();
    final credentials = widget.credentials;
    _customerId = TextEditingController(text: credentials.customerId);
    _accountNumber = TextEditingController(text: credentials.accountNumber);
    _apiKey = TextEditingController(text: credentials.apiKey);
    _apiSecret = TextEditingController(text: credentials.apiSecret);
    _meterNumber = TextEditingController(text: credentials.meterNumber);
    _clientId = TextEditingController(text: credentials.clientId);
    _clientSecret = TextEditingController(text: credentials.clientSecret);
  }

  @override
  void didUpdateWidget(covariant _ShippingProviderCredentialsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carrier == widget.carrier &&
        oldWidget.credentials == widget.credentials) {
      return;
    }
    final credentials = widget.credentials;
    _customerId.text = credentials.customerId;
    _accountNumber.text = credentials.accountNumber;
    _apiKey.text = credentials.apiKey;
    _apiSecret.text = credentials.apiSecret;
    _meterNumber.text = credentials.meterNumber;
    _clientId.text = credentials.clientId;
    _clientSecret.text = credentials.clientSecret;
  }

  @override
  void dispose() {
    _customerId.dispose();
    _accountNumber.dispose();
    _apiKey.dispose();
    _apiSecret.dispose();
    _meterNumber.dispose();
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrier = widget.carrier.trim().toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.carrier} provider credentials',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'These values belong in the secure shipping backend. The admin form captures the exact carrier fields needed for live rates and labels.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 680;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (carrier == 'USPS') ...[
                      _credentialField(
                        controller: _customerId,
                        label: 'Customer registration ID (CRID)',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _accountNumber,
                        label: 'EPS account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _meterNumber,
                        label: 'Mailer ID (MID)',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'Manifest MID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'USPS consumer key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'USPS consumer secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else if (carrier == 'UPS') ...[
                      _credentialField(
                        controller: _accountNumber,
                        label: 'UPS shipper account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'UPS API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: 'UPS API secret',
                        wide: wide,
                        obscure: true,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'UPS OAuth client ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'UPS OAuth client secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else if (carrier == 'FEDEX') ...[
                      _credentialField(
                        controller: _accountNumber,
                        label: 'FedEx account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _meterNumber,
                        label: 'FedEx meter number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'FedEx API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: 'FedEx API secret',
                        wide: wide,
                        obscure: true,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'FedEx OAuth client ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'FedEx OAuth client secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else if (carrier == 'DHL') ...[
                      _credentialField(
                        controller: _accountNumber,
                        label: 'DHL account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _customerId,
                        label: 'DHL site ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'DHL API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: 'DHL API password',
                        wide: wide,
                        obscure: true,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'DHL API client ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'DHL API client secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else ...[
                      _credentialField(
                        controller: _customerId,
                        label: '${widget.carrier} site ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _accountNumber,
                        label: '${widget.carrier} account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: '${widget.carrier} API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: '${widget.carrier} API password/secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => widget.onSave(
                    ShippingCarrierCredentials(
                      customerId: _customerId.text.trim(),
                      accountNumber: _accountNumber.text.trim(),
                      apiKey: _apiKey.text.trim(),
                      apiSecret: _apiSecret.text.trim(),
                      meterNumber: _meterNumber.text.trim(),
                      clientId: _clientId.text.trim(),
                      clientSecret: _clientSecret.text.trim(),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save provider'),
                ),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _credentialField({
    required TextEditingController controller,
    required String label,
    required bool wide,
    bool obscure = false,
  }) {
    return SizedBox(
      width: wide ? 310 : double.infinity,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ShippingOptionEditor extends StatefulWidget {
  const _ShippingOptionEditor({required this.option, required this.onSave});

  final ShippingOption? option;
  final AsyncValueChanged<ShippingOption> onSave;

  @override
  State<_ShippingOptionEditor> createState() => _ShippingOptionEditorState();
}

class _ShippingOptionEditorState extends State<_ShippingOptionEditor> {
  late TextEditingController _name;
  late TextEditingController _carrier;
  late TextEditingController _service;
  late TextEditingController _price;
  late TextEditingController _days;
  late TextEditingController _sortOrder;
  late String _priority;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ShippingOptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option != widget.option) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    final option = widget.option;
    _name = TextEditingController(text: option?.name ?? 'New shipping option');
    _carrier = TextEditingController(
      text: _normalizedCarrier(option?.carrier ?? 'USPS'),
    );
    _service = TextEditingController(
      text: option?.service ?? 'Ground Advantage',
    );
    _price = TextEditingController(text: (option?.price ?? 7.95).toString());
    _days = TextEditingController(
      text: option?.estimatedDays ?? '3-5 business days',
    );
    _sortOrder = TextEditingController(
      text: (option?.sortOrder ?? 40).toString(),
    );
    _priority = option?.priority ?? 'Standard';
    _enabled = option?.isEnabled ?? true;
  }

  List<String> get _servicesForCarrier {
    return switch (_carrier.text.trim().toUpperCase()) {
      'USPS' => const [
        'Ground Advantage',
        'Priority Mail',
        'Priority Mail Express',
        'First-Class Package',
      ],
      'UPS' => const ['Ground', '3 Day Select', '2nd Day Air', 'Next Day Air'],
      'FEDEX' => const [
        'Ground',
        'Home Delivery',
        'Express Saver',
        '2 Day',
        'Priority Overnight',
      ],
      'DHL' => const ['Express Worldwide', 'Express Easy', 'Packet Plus'],
      _ => const ['Ground', 'Express'],
    };
  }

  void _disposeControllers() {
    _name.dispose();
    _carrier.dispose();
    _service.dispose();
    _price.dispose();
    _days.dispose();
    _sortOrder.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Checkout shipping option',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Customer label'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        ['USPS', 'UPS', 'FedEx', 'DHL'].contains(_carrier.text)
                        ? _carrier.text
                        : 'USPS',
                    decoration: const InputDecoration(labelText: 'Carrier'),
                    items: const [
                      DropdownMenuItem(value: 'USPS', child: Text('USPS')),
                      DropdownMenuItem(value: 'UPS', child: Text('UPS')),
                      DropdownMenuItem(value: 'FedEx', child: Text('FedEx')),
                      DropdownMenuItem(value: 'DHL', child: Text('DHL')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _carrier.text = value ?? 'USPS';
                        final services = _servicesForCarrier;
                        if (!services.contains(_service.text)) {
                          _service.text = services.first;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_carrier.text),
                    initialValue: _servicesForCarrier.contains(_service.text)
                        ? _service.text
                        : _servicesForCarrier.first,
                    decoration: InputDecoration(
                      labelText: '${_carrier.text} service',
                      helperText: _shippingHelperText(_carrier.text),
                    ),
                    items: [
                      for (final service in _servicesForCarrier)
                        DropdownMenuItem(value: service, child: Text(service)),
                    ],
                    onChanged: (value) =>
                        setState(() => _service.text = value ?? _service.text),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Standard',
                        child: Text('Standard'),
                      ),
                      DropdownMenuItem(
                        value: 'Priority',
                        child: Text('Priority'),
                      ),
                      DropdownMenuItem(
                        value: 'Express',
                        child: Text('Express'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _priority = value ?? _priority),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _days,
                    decoration: const InputDecoration(
                      labelText: 'Delivery estimate',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sortOrder,
                    decoration: const InputDecoration(labelText: 'Sort order'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show at checkout'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                final id =
                    widget.option?.id ??
                    'ship-${DateTime.now().millisecondsSinceEpoch}';
                widget.onSave(
                  ShippingOption(
                    id: id,
                    name: _name.text.trim().isEmpty
                        ? 'Shipping option'
                        : _name.text.trim(),
                    carrier: _carrier.text.trim(),
                    service: _service.text.trim(),
                    priority: _priority,
                    price: double.tryParse(_price.text) ?? 0,
                    estimatedDays: _days.text.trim(),
                    isEnabled: _enabled,
                    sortOrder: int.tryParse(_sortOrder.text) ?? 10,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save shipping option'),
            ),
          ],
        ),
      ),
    );
  }

  String _shippingHelperText(String carrier) {
    return switch (carrier.trim().toUpperCase()) {
      'USPS' => 'USPS labels/rates require USPS or aggregator credentials.',
      'UPS' =>
        'UPS rates use account number, OAuth client, and shipper address.',
      'FEDEX' => 'FedEx rates use meter/account credentials and service code.',
      'DHL' => 'DHL Express uses account number and API key credentials.',
      _ =>
        'Carrier-specific API credentials are configured in backend shipping services.',
    };
  }

  String _normalizedCarrier(String carrier) {
    return switch (carrier.trim().toUpperCase()) {
      'UPS' => 'UPS',
      'FEDEX' => 'FedEx',
      'DHL' => 'DHL',
      _ => 'USPS',
    };
  }
}

class _ContentManagementSection extends StatelessWidget {
  const _ContentManagementSection({required this.blocks, required this.onSave});

  final List<ContentBlock> blocks;
  final AsyncValueChanged<ContentBlock> onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 580
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 1.05 : 0.78,
          ),
          itemCount: blocks.length,
          itemBuilder: (context, index) =>
              ContentBlockCard(block: blocks[index], onSave: onSave),
        );
      },
    );
  }
}

class ContentBlockCard extends StatefulWidget {
  const ContentBlockCard({
    super.key,
    required this.block,
    required this.onSave,
  });

  final ContentBlock block;
  final AsyncValueChanged<ContentBlock> onSave;

  @override
  State<ContentBlockCard> createState() => _ContentBlockCardState();
}

class _ContentBlockCardState extends State<ContentBlockCard> {
  late final TextEditingController _title;
  late final TextEditingController _placement;
  late final TextEditingController _body;
  late final TextEditingController _sortOrder;
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.block.title);
    _placement = TextEditingController(text: widget.block.placement);
    _body = TextEditingController(text: widget.block.body);
    _sortOrder = TextEditingController(text: '${widget.block.sortOrder}');
    _visible = widget.block.isVisible;
  }

  @override
  void dispose() {
    _title.dispose();
    _placement.dispose();
    _body.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Content block',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _placement,
              decoration: const InputDecoration(labelText: 'Placement'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'Body copy'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sortOrder,
                    decoration: const InputDecoration(labelText: 'Sort'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible'),
                    value: _visible,
                    onChanged: (value) => setState(() => _visible = value),
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => widget.onSave(
                ContentBlock(
                  id: widget.block.id,
                  title: _title.text.trim(),
                  placement: _placement.text.trim(),
                  body: _body.text.trim(),
                  sortOrder:
                      int.tryParse(_sortOrder.text) ?? widget.block.sortOrder,
                  isVisible: _visible,
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save content'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersSection extends StatefulWidget {
  const _CustomersSection({
    required this.customers,
    required this.orders,
    required this.activeCarts,
    required this.storeInfo,
    required this.onSaveCustomer,
    required this.onBlockIp,
  });

  final List<CustomerAccount> customers;
  final List<Order> orders;
  final List<ActiveCart> activeCarts;
  final StoreInfo storeInfo;
  final AsyncValueChanged<CustomerAccount> onSaveCustomer;
  final ValueChanged<String> onBlockIp;

  @override
  State<_CustomersSection> createState() => _CustomersSectionState();
}

class _CustomersSectionState extends State<_CustomersSection> {
  String _query = '';
  String _sortBy = 'Name';
  CustomerAccount? _selected;

  List<CustomerAccount> get _visibleCustomers {
    final query = _query.trim().toLowerCase();
    final customers = widget.customers.where((customer) {
      if (query.isEmpty) {
        return true;
      }
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.segment.toLowerCase().contains(query) ||
          customer.createdIp.toLowerCase().contains(query) ||
          customer.lastLoginIp.toLowerCase().contains(query);
    }).toList();
    customers.sort((a, b) {
      return switch (_sortBy) {
        'Orders' => b.orders.compareTo(a.orders),
        'LTV' => b.lifetimeValue.compareTo(a.lifetimeValue),
        'Newest' => a.joinedDaysAgo.compareTo(b.joinedDaysAgo),
        'Segment' => a.segment.compareTo(b.segment),
        _ => a.name.compareTo(b.name),
      };
    });
    return customers;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _visibleCustomers;
    final selected = _selected;
    final newToday = widget.customers
        .where((customer) => customer.joinedDaysAgo == 0)
        .length;
    final new7 = widget.customers
        .where((customer) => customer.joinedDaysAgo <= 7)
        .length;
    final value = widget.customers.fold(
      0.0,
      (total, customer) => total + customer.lifetimeValue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(Icons.person_add_alt, 'New today', '$newToday users'),
            _MetricData(Icons.groups_outlined, 'New 7 days', '$new7 users'),
            _MetricData(
              Icons.diamond_outlined,
              'Customer value',
              currency(value),
            ),
            _MetricData(
              Icons.loyalty_outlined,
              'VIP customers',
              '${widget.customers.where((c) => c.segment == 'VIP').length}',
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
                  flex: wide ? 7 : 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Search customers',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sortBy,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Name',
                                      child: Text('Name'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Newest',
                                      child: Text('Newest'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Orders',
                                      child: Text('Orders'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'LTV',
                                      child: Text('LTV'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Segment',
                                      child: Text('Segment'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _sortBy = value ?? _sortBy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _HorizontalTableScroller(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Customer')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Joined')),
                                DataColumn(label: Text('Orders')),
                                DataColumn(label: Text('LTV')),
                                DataColumn(label: Text('Segment')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Last IP')),
                                DataColumn(label: Text('Referral')),
                              ],
                              rows: [
                                for (final customer in customers)
                                  DataRow(
                                    selected: selected?.id == customer.id,
                                    onSelectChanged: (_) =>
                                        setState(() => _selected = customer),
                                    cells: [
                                      DataCell(Text(customer.name)),
                                      DataCell(Text(customer.email)),
                                      DataCell(
                                        Text(
                                          customer.joinedDaysAgo == 0
                                              ? 'Today'
                                              : '${customer.joinedDaysAgo} days ago',
                                        ),
                                      ),
                                      DataCell(Text('${customer.orders}')),
                                      DataCell(
                                        Text(currency(customer.lifetimeValue)),
                                      ),
                                      DataCell(Text(customer.segment)),
                                      DataCell(
                                        Text(
                                          customer.isBlocked
                                              ? 'Blocked'
                                              : 'Active',
                                        ),
                                      ),
                                      DataCell(Text(customer.lastLoginIp)),
                                      DataCell(Text(customer.referralCode)),
                                    ],
                                  ),
                              ],
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
                  flex: wide ? 4 : 0,
                  child: _CustomerProfilePanel(
                    customer: selected,
                    orders: selected == null
                        ? const []
                        : widget.orders
                              .where((order) => order.email == selected.email)
                              .toList(),
                    carts: selected == null
                        ? const []
                        : widget.activeCarts
                              .where((cart) => cart.customer == selected.name)
                              .toList(),
                    storeInfo: widget.storeInfo,
                    onSaveCustomer: widget.onSaveCustomer,
                    onBlockIp: widget.onBlockIp,
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

class _CustomerProfilePanel extends StatelessWidget {
  const _CustomerProfilePanel({
    required this.customer,
    required this.orders,
    required this.carts,
    required this.storeInfo,
    required this.onSaveCustomer,
    required this.onBlockIp,
  });

  final CustomerAccount? customer;
  final List<Order> orders;
  final List<ActiveCart> carts;
  final StoreInfo storeInfo;
  final AsyncValueChanged<CustomerAccount> onSaveCustomer;
  final ValueChanged<String> onBlockIp;

  @override
  Widget build(BuildContext context) {
    final customer = this.customer;
    if (customer == null) {
      return const _EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Select a customer',
        body:
            'Click a customer row to review profile, order history, and carts.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(customer.email),
            if (customer.addressLine1.isNotEmpty ||
                customer.city.isNotEmpty ||
                customer.county.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                [
                  customer.addressLine1,
                  customer.addressLine2,
                  [
                    customer.city,
                    customer.county,
                    customer.state,
                    customer.postalCode,
                  ].where((item) => item.trim().isNotEmpty).join(', '),
                  customer.country,
                ].where((item) => item.trim().isNotEmpty).join('\n'),
              ),
            ],
            const SizedBox(height: 8),
            _CustomerMetaRow(
              icon: Icons.event_available_outlined,
              label: 'Account created',
              value: _formatCustomerDate(customer.createdAt),
            ),
            _CustomerMetaRow(
              icon: Icons.login_outlined,
              label: 'Last login',
              value: _formatCustomerDate(customer.lastLoginAt),
            ),
            _CustomerMetaRow(
              icon: Icons.public,
              label: 'Last IP address',
              value: customer.lastLoginIp.isEmpty
                  ? 'Not recorded'
                  : customer.lastLoginIp,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    customer.isBlocked
                        ? Icons.block_outlined
                        : Icons.verified_user_outlined,
                    size: 18,
                  ),
                  label: Text(customer.isBlocked ? 'Blocked' : 'Active'),
                ),
                if (customer.lastLoginIp.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.public, size: 18),
                    label: Text('Last IP ${customer.lastLoginIp}'),
                  ),
                if (customer.createdIp.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: Text('Created from ${customer.createdIp}'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      customer
                        ..isBlocked = !customer.isBlocked
                        ..blockedReason = customer.isBlocked
                            ? 'Blocked from admin customer profile'
                            : '';
                      onSaveCustomer(customer);
                    },
                    icon: Icon(
                      customer.isBlocked
                          ? Icons.lock_open_outlined
                          : Icons.block_outlined,
                    ),
                    label: Text(
                      customer.isBlocked ? 'Unblock account' : 'Block account',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: customer.lastLoginIp.trim().isEmpty
                        ? null
                        : () => onBlockIp(customer.lastLoginIp),
                    icon: const Icon(Icons.public_off_outlined),
                    label: const Text('Block IP'),
                  ),
                ),
              ],
            ),
            if (customer.blockedReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(customer.blockedReason),
            ],
            const SizedBox(height: 12),
            Text('Orders', style: Theme.of(context).textTheme.titleMedium),
            if (orders.isEmpty)
              const Text('No orders for this customer yet.')
            else
              for (final order in orders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${order.id} • ${currency(order.total)}'),
                  subtitle: Text(order.fulfillmentStatus),
                  trailing: const Icon(Icons.description_outlined),
                  onTap: () => _showInvoiceDialog(context, order, storeInfo),
                ),
            const Divider(),
            Text('Carts', style: Theme.of(context).textTheme.titleMedium),
            if (carts.isEmpty)
              const Text('No active carts for this customer.')
            else
              for (final cart in carts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${cart.id} • ${currency(cart.value)}'),
                  subtitle: Text('${cart.itemCount} item(s)'),
                ),
          ],
        ),
      ),
    );
  }
}

void _showInvoiceDialog(
  BuildContext context,
  Order order,
  StoreInfo storeInfo,
) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InvoiceDocumentPreview(order: order, storeInfo: storeInfo),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => printHtmlDocument(
                  'Invoice ${order.id}',
                  _invoiceHtml(order, storeInfo),
                ),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print invoice'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CustomerMetaRow extends StatelessWidget {
  const _CustomerMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF27724E)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCustomerDate(DateTime? value) {
  if (value == null) {
    return 'Not recorded';
  }
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

class _OrdersSection extends StatefulWidget {
  const _OrdersSection({
    required this.orders,
    required this.shippingOptions,
    required this.storeInfo,
    required this.onUpdateOrder,
    required this.onCreateShippingLabel,
    required this.onBatchUpdateOrders,
  });

  final List<Order> orders;
  final List<ShippingOption> shippingOptions;
  final StoreInfo storeInfo;
  final AsyncValueChanged<Order> onUpdateOrder;
  final Future<ShippingLabelResult> Function(Order order) onCreateShippingLabel;
  final void Function(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  )
  onBatchUpdateOrders;

  @override
  State<_OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<_OrdersSection> {
  final Set<String> _selectedOrderIds = {};
  String _sortBy = 'Shipping method';
  String _statusFilter = 'All';
  String _batchAction = 'Print Pack List';
  String _printPacket = '';
  bool _isApplyingBatchAction = false;

  List<Order> get _visibleOrders {
    final orders = widget.orders.where((order) {
      if (_statusFilter == 'All') {
        return true;
      }
      return order.fulfillmentStatus == _statusFilter ||
          order.status == _statusFilter ||
          order.labelStatus == _statusFilter;
    }).toList();

    final methodRank = <String, int>{};
    for (final option in widget.shippingOptions) {
      methodRank.putIfAbsent(
        '${option.carrier} ${option.service}',
        () => methodRank.length,
      );
    }
    orders.sort((a, b) {
      return switch (_sortBy) {
        'Shipping method' =>
          (methodRank['${a.shippingCarrier} ${a.shippingService}'] ?? 999)
              .compareTo(
                methodRank['${b.shippingCarrier} ${b.shippingService}'] ?? 999,
              ),
        'Delivery days' => _shippingDaysForOrder(
          a,
        ).compareTo(_shippingDaysForOrder(b)),
        'Shipping priority' => a.shippingPriority.compareTo(b.shippingPriority),
        'Newest' => (b.createdAt ?? DateTime(2000)).compareTo(
          a.createdAt ?? DateTime(2000),
        ),
        'Total' => b.total.compareTo(a.total),
        'Status' => a.fulfillmentStatus.compareTo(b.fulfillmentStatus),
        _ => a.id.compareTo(b.id),
      };
    });
    return orders;
  }

  List<Order> get _selectedOrders => widget.orders
      .where((order) => _selectedOrderIds.contains(order.id))
      .toList();

  int _shippingDaysForOrder(Order order) {
    final method = '${order.shippingCarrier} ${order.shippingService}';
    for (final option in widget.shippingOptions) {
      if ('${option.carrier} ${option.service}' == method) {
        final match = RegExp(r'\d+').firstMatch(option.estimatedDays);
        return int.tryParse(match?.group(0) ?? '') ?? 99;
      }
    }
    return 99;
  }

  void _toggleAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedOrderIds
          ..clear()
          ..addAll(_visibleOrders.map((order) => order.id));
      } else {
        _selectedOrderIds.clear();
      }
    });
  }

  void _printSelected() {
    final orders = _selectedOrders;
    if (orders.isEmpty) {
      return;
    }
    widget.onBatchUpdateOrders(orders, 'Processing', 'Not requested');
    final packet = orders
        .map((order) => _packListHtml(order, widget.storeInfo))
        .join('\n<div class="egbeanom-page-break"></div>\n');
    setState(() {
      _printPacket = _buildPrintPacket(orders);
    });
    printHtmlDocument('Egbe Anom pack list', packet);
  }

  void _printInvoices() {
    final orders = _selectedOrders;
    if (orders.isEmpty) {
      return;
    }
    final packet = orders
        .map((order) => _invoiceHtml(order, widget.storeInfo, printLite: true))
        .join('\n<div class="egbeanom-page-break"></div>\n');
    setState(() {
      _printPacket = orders.map(_buildInvoicePacket).join('\n\n');
    });
    printHtmlDocument('Egbe Anom invoices', packet);
  }

  Future<void> _printShippingLabels() async {
    final orders = _selectedOrders;
    if (orders.isEmpty || _isApplyingBatchAction) {
      return;
    }

    setState(() {
      _isApplyingBatchAction = true;
    });

    final completed = <Order>[];
    final failures = <String>[];
    for (final order in orders) {
      try {
        await widget.onCreateShippingLabel(order);
        completed.add(order);
      } catch (_) {
        failures.add(order.id);
      }
    }

    if (!mounted) {
      return;
    }

    if (completed.isNotEmpty) {
      // Label creation sends status to Label created and queues customer update email.
      widget.onBatchUpdateOrders(completed, 'Label created', 'Label created');
    }

    setState(() {
      _isApplyingBatchAction = false;
      _printPacket = _buildStatusPacket(
        completed,
        'Label created',
        'Label created',
      );
    });

    final messenger = ScaffoldMessenger.of(context);
    if (completed.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Printed ${completed.length} label(s). Status set to Label created and customer email queued.',
          ),
        ),
      );
    }
    if (failures.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Label creation failed for ${failures.length} order(s): ${failures.join(', ')}',
          ),
        ),
      );
    }
  }

  void _batchStatus(String fulfillmentStatus, String labelStatus) {
    final orders = _selectedOrders;
    if (orders.isEmpty) {
      return;
    }
    widget.onBatchUpdateOrders(orders, fulfillmentStatus, labelStatus);
    setState(() {
      _printPacket = _buildStatusPacket(orders, fulfillmentStatus, labelStatus);
    });
  }

  Future<void> _applyBatchAction() async {
    switch (_batchAction) {
      case 'Print Invoice':
        _printInvoices();
      case 'Print Pack List':
        _printSelected();
      case 'Print label':
        await _printShippingLabels();
      case 'Shipped':
        _batchStatus('Shipped', 'Shipped');
    }
  }

  String _buildPrintPacket(List<Order> orders) {
    final buffer = StringBuffer()
      ..writeln('EGBE ANOM PICK LIST')
      ..writeln('Orders: ${orders.length}')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('')
      ..writeln('ORDER LIST');
    for (final order in orders) {
      buffer.writeln(
        '${order.id} | ${order.customer} | ${order.shippingPriority} | ${order.shippingCarrier} ${order.shippingService} | ${order.itemCount} item(s) | ${currency(order.total)}',
      );
    }
    for (final order in orders) {
      buffer
        ..writeln('')
        ..writeln('----------------------------------------')
        ..writeln('INVOICE / PACKING LIST')
        ..writeln(order.id)
        ..writeln('${order.customer} <${order.email}>')
        ..writeln(
          'Ship: ${order.shippingCarrier} ${order.shippingService} (${order.shippingPriority})',
        )
        ..writeln('Shipping paid: ${currency(order.shippingTotal)}')
        ..writeln('Status: Processing')
        ..writeln('')
        ..writeln('ITEMS');
      if (order.lines.isEmpty) {
        buffer.writeln('${order.itemCount} item(s) from order record');
      } else {
        for (final line in order.lines) {
          buffer.writeln(
            '${line.quantity} x ${line.sku} | ${line.product.name} • ${line.size} | ${line.product.itemLocation} | ${line.product.shippingSize(MeasurementSystem.standard)}',
          );
        }
      }
      buffer
        ..writeln('')
        ..writeln('Picker: ____________  Packed: ____________');
    }
    return buffer.toString();
  }

  String _buildStatusPacket(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  ) {
    final buffer = StringBuffer()
      ..writeln('Batch order update')
      ..writeln('Orders: ${orders.length}')
      ..writeln('Fulfillment: $fulfillmentStatus')
      ..writeln('Label: $labelStatus')
      ..writeln('');
    for (final order in orders) {
      buffer.writeln('${order.id} | ${order.customer} | ${order.email}');
    }
    return buffer.toString();
  }

  String _buildInvoicePacket(Order order) {
    final buffer = StringBuffer()
      ..writeln('EGBE ANOM INVOICE')
      ..writeln(order.id)
      ..writeln('${order.customer} <${order.email}>')
      ..writeln('Date: ${order.createdAt ?? DateTime.now()}')
      ..writeln('')
      ..writeln('ITEMS');
    if (order.lines.isEmpty) {
      buffer.writeln('${order.itemCount} item(s) from order record');
    } else {
      for (final line in order.lines) {
        buffer.writeln(
          '${line.quantity} x ${line.sku} | ${line.product.name} | ${currency(line.total)}',
        );
      }
    }
    buffer
      ..writeln('')
      ..writeln('Shipping: ${currency(order.shippingTotal)}')
      ..writeln('Total: ${currency(order.total)}')
      ..writeln('QR: https://egbeanom.com');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _visibleOrders;
    final allVisibleSelected =
        visibleOrders.isNotEmpty &&
        visibleOrders.every((order) => _selectedOrderIds.contains(order.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.inventory_outlined,
              'To pick',
              '${widget.orders.where((o) => o.fulfillmentStatus == 'Unfulfilled' || o.fulfillmentStatus == 'Being picked').length}',
            ),
            _MetricData(
              Icons.label_important_outline,
              'Labels',
              '${widget.orders.where((o) => o.labelStatus == 'Label created').length}',
            ),
            _MetricData(
              Icons.local_shipping_outlined,
              'Sent',
              '${widget.orders.where((o) => o.fulfillmentStatus == 'Sent' || o.fulfillmentStatus == 'Shipped').length}',
            ),
            _MetricData(
              Icons.check_box_outlined,
              'Selected',
              '${_selectedOrderIds.length}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortBy,
                        decoration: const InputDecoration(labelText: 'Sort by'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Shipping method',
                            child: Text('Shipping method'),
                          ),
                          DropdownMenuItem(
                            value: 'Delivery days',
                            child: Text('Delivery days'),
                          ),
                          DropdownMenuItem(
                            value: 'Newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'Total',
                            child: Text('Total'),
                          ),
                          DropdownMenuItem(
                            value: 'Status',
                            child: Text('Status'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _sortBy = value ?? _sortBy),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Filter'),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All orders'),
                          ),
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'Processing',
                            child: Text('Processing'),
                          ),
                          DropdownMenuItem(
                            value: 'Label created',
                            child: Text('Label created'),
                          ),
                          DropdownMenuItem(
                            value: 'Shipped',
                            child: Text('Shipped'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _statusFilter = value ?? _statusFilter,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _selectedOrderIds.isEmpty
                          ? null
                          : () => _applyBatchAction(),
                      icon: const Icon(Icons.task_alt_outlined),
                      label: Text(
                        _isApplyingBatchAction
                            ? 'Applying...'
                            : 'Apply to selected',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _batchAction,
                        decoration: const InputDecoration(
                          labelText: 'Selected orders',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Print Invoice',
                            child: Text('Print Invoice'),
                          ),
                          DropdownMenuItem(
                            value: 'Print Pack List',
                            child: Text('Print Pack List'),
                          ),
                          DropdownMenuItem(
                            value: 'Print label',
                            child: Text('Print label'),
                          ),
                          DropdownMenuItem(
                            value: 'Shipped',
                            child: Text('Shipped'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _batchAction = value ?? _batchAction,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: allVisibleSelected,
                  onChanged: _toggleAll,
                  title: Text(
                    'Select all visible orders (${visibleOrders.length})',
                  ),
                ),
                const Divider(),
                for (final order in visibleOrders)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: _selectedOrderIds.contains(order.id),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedOrderIds.add(order.id);
                          } else {
                            _selectedOrderIds.remove(order.id);
                          }
                        });
                      },
                    ),
                    title: Text('${order.id} • ${order.customer}'),
                    subtitle: Text(
                      '${order.shippingPriority} • ${order.shippingCarrier} ${order.shippingService} • ${order.fulfillmentStatus} • ${order.labelStatus}',
                    ),
                    trailing: Text(currency(order.total)),
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                        ),
                        title: const Text('Customer'),
                        subtitle: Text(order.email),
                      ),
                      if (order.lines.isNotEmpty)
                        for (final line in order.lines)
                          ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 8,
                            ),
                            title: Text(line.product.name),
                            subtitle: Text(
                              '${line.quantity} x ${currency(line.unitPrice)} • ${line.size} • ${line.product.itemLocation}',
                            ),
                            trailing: Text(currency(line.total)),
                          ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 14),
                        child: _OrderFulfillmentEditor(
                          order: order,
                          onSave: widget.onUpdateOrder,
                          onCreateShippingLabel: widget.onCreateShippingLabel,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_printPacket.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Printable batch packet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _printPacket,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InvoicesSection extends StatefulWidget {
  const _InvoicesSection({required this.orders, required this.storeInfo});

  final List<Order> orders;
  final StoreInfo storeInfo;

  @override
  State<_InvoicesSection> createState() => _InvoicesSectionState();
}

class _InvoicesSectionState extends State<_InvoicesSection> {
  Order? _selected;
  final _header = TextEditingController(text: 'Egbe Anom');
  final _footer = TextEditingController(
    text: 'Thank you for shopping with Egbe Anom.',
  );

  @override
  void dispose() {
    _header.dispose();
    _footer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 920;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 4 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Invoice editor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _header,
                        decoration: const InputDecoration(
                          labelText: 'Invoice header',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _footer,
                        decoration: const InputDecoration(
                          labelText: 'Invoice footer',
                        ),
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (widget.orders.isEmpty)
                        const Text('No orders available for invoices.')
                      else
                        for (final order in widget.orders)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            selected: selected == order,
                            title: Text(order.id),
                            subtitle: Text(order.customer),
                            trailing: Text(currency(order.total)),
                            onTap: () => setState(() => _selected = order),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: selected == null
                      ? const _EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Select an order',
                          body:
                              'Choose an order to preview, print, and confirm invoice copy.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InvoiceDocumentPreview(
                              order: selected,
                              storeInfo: widget.storeInfo,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => printHtmlDocument(
                                'Invoice ${selected.id}',
                                _invoiceHtml(selected, widget.storeInfo),
                              ),
                              icon: const Icon(Icons.print_outlined),
                              label: const Text('Print invoice'),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews, required this.onUpdateReview});

  final List<ReviewSummary> reviews;
  final Future<void> Function(ReviewSummary review, String status)
  onUpdateReview;

  @override
  Widget build(BuildContext context) {
    final pending = reviews
        .where((review) => review.status == 'pending')
        .length;
    return Column(
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(Icons.rate_review_outlined, 'Pending', '$pending'),
            _MetricData(
              Icons.verified_outlined,
              'Approved',
              '${reviews.where((r) => r.status == 'approved').length}',
            ),
            _MetricData(
              Icons.block_outlined,
              'Rejected',
              '${reviews.where((r) => r.status == 'rejected').length}',
            ),
            _MetricData(Icons.reviews_outlined, 'Total', '${reviews.length}'),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final review in reviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      review.status == 'approved'
                          ? Icons.verified_outlined
                          : Icons.rate_review_outlined,
                    ),
                    title: Text(
                      '${review.title} • ${review.rating.toStringAsFixed(1)}',
                    ),
                    subtitle: Text(
                      '${review.scope} • ${review.author} • ${review.status}\n${review.body}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Approve',
                          onPressed: () => onUpdateReview(review, 'approved'),
                          icon: const Icon(Icons.check),
                        ),
                        IconButton.outlined(
                          tooltip: 'Delete',
                          onPressed: () => onUpdateReview(review, 'rejected'),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({required this.notifications});

  final List<StoreNotification> notifications;

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  StoreNotification? _selected;

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (notifications.isEmpty)
              const Text('No notifications yet.')
            else
              for (final item in notifications)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.type == 'order'
                        ? Icons.shopping_bag_outlined
                        : item.type == 'email'
                        ? Icons.outgoing_mail
                        : Icons.notifications_outlined,
                    color: const Color(0xFFC88F52),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                  selected: _selected == item,
                  onTap: () {
                    setState(() {
                      item.isRead = true;
                      _selected = item;
                    });
                  },
                  trailing: Text(
                    '${item.createdAt.month}/${item.createdAt.day} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                ),
            if (_selected != null) ...[
              const Divider(),
              Text(
                _selected!.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(_selected!.message),
              const SizedBox(height: 6),
              Text(_selected!.isRead ? 'Read' : 'Unread'),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatefulWidget {
  const _AnalyticsSection({
    required this.sessions,
    required this.dailyMetrics,
    required this.products,
    required this.orders,
    required this.activeCarts,
    required this.conversionRate,
  });

  final List<ActiveUserSession> sessions;
  final List<DailyMetric> dailyMetrics;
  final List<Fragrance> products;
  final List<Order> orders;
  final List<ActiveCart> activeCarts;
  final double conversionRate;

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
    final productOrders = _filterOrders(widget.orders, _productRange);
    final reportOrders = _filterOrders(widget.orders, _reportRange);
    final visits = trafficMetrics.fold(0, (sum, metric) => sum + metric.visits);
    final revenue = salesOrders.fold(0.0, (sum, order) => sum + order.total);
    final topProducts = _rankProducts(productOrders);
    final hourly = _salesByHour(salesOrders);
    final monthly = _salesByMonth(reportOrders);
    final taxCollected = reportOrders.fold(
      0.0,
      (sum, order) =>
          sum +
          math.max(
            0,
            order.total -
                order.shippingTotal -
                order.lines.fold(0.0, (lineSum, line) => lineSum + line.total),
          ),
    );
    final averageOrder = salesOrders.isEmpty
        ? 0.0
        : revenue / salesOrders.length;
    final sourceCounts = <String, double>{};
    for (final session in widget.sessions) {
      sourceCounts.update(
        session.source,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final pageCounts = <String, double>{};
    for (final session in widget.sessions) {
      pageCounts.update(
        session.currentPage,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.visibility_outlined,
              'Users online',
              '${widget.sessions.length}',
            ),
            _MetricData(Icons.ads_click_outlined, 'Visits', '$visits'),
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
                        onTap: () {},
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
                        onTap: () {},
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
                    onTap: () {},
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
                    onTap: () {},
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
    required this.settings,
    required this.onSendEmail,
    required this.onSaveSettings,
  });

  final List<CustomerAccount> customers;
  final EmailServerSettings settings;
  final void Function(String audience, String subject, String body) onSendEmail;
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
  String _audience = 'All customers';
  late bool _useSsl;
  bool _htmlMode = true;
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
    _useSsl = widget.settings.useSsl;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audiences = [
      'All customers',
      'VIP customers',
      'New customers',
      ...widget.customers.map((customer) => customer.email),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 5 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Email delivery settings',
                        style: Theme.of(context).textTheme.titleLarge,
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
                      const SizedBox(height: 10),
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
                            width: 110,
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
                      const SizedBox(height: 10),
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
                            width: 110,
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Mailbox username',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Use SSL/TLS'),
                        value: _useSsl,
                        onChanged: (value) => setState(() => _useSsl = value),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => widget.onSaveSettings(
                          EmailServerSettings(
                            fromName: _fromName.text.trim(),
                            fromEmail: _fromEmail.text.trim(),
                            imapHost: _imapHost.text.trim(),
                            imapPort: int.tryParse(_imapPort.text) ?? 993,
                            smtpHost: _smtpHost.text.trim(),
                            smtpPort: int.tryParse(_smtpPort.text) ?? 587,
                            username: _username.text.trim(),
                            useSsl: _useSsl,
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save email settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 5 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Customer email',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _audience,
                        decoration: const InputDecoration(
                          labelText: 'Audience',
                        ),
                        items: [
                          for (final item in audiences)
                            DropdownMenuItem(value: item, child: Text(item)),
                        ],
                        onChanged: (value) =>
                            setState(() => _audience = value ?? _audience),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _body,
                        decoration: InputDecoration(
                          labelText: _htmlMode ? 'HTML message' : 'Message',
                        ),
                        minLines: 5,
                        maxLines: 8,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Send as HTML email'),
                        value: _htmlMode,
                        onChanged: (value) => setState(() => _htmlMode = value),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => widget.onSendEmail(
                          _audience,
                          _subject.text.trim(),
                          _htmlMode
                              ? '<html><body>${_body.text.trim()}</body></html>'
                              : _body.text.trim(),
                        ),
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Queue email'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email templates',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final template in _templates)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(template.name),
                          subtitle: Text(template.subject),
                          children: [
                            TextFormField(
                              initialValue: template.subject,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                              ),
                              onChanged: (value) => template.subject = value,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: template.htmlBody,
                              decoration: const InputDecoration(
                                labelText: 'HTML body',
                              ),
                              minLines: 4,
                              maxLines: 8,
                              onChanged: (value) => template.htmlBody = value,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _subject.text = template.subject;
                                    _body.text = template.htmlBody;
                                    _htmlMode = true;
                                  });
                                },
                                icon: const Icon(Icons.edit_note_outlined),
                                label: const Text('Use template'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SiteStatusSection extends StatefulWidget {
  const _SiteStatusSection({
    required this.status,
    required this.products,
    required this.onSave,
  });

  final SiteStatus status;
  final List<Fragrance> products;
  final AsyncValueChanged<SiteStatus> onSave;

  @override
  State<_SiteStatusSection> createState() => _SiteStatusSectionState();
}

class _SiteStatusSectionState extends State<_SiteStatusSection> {
  late final TextEditingController _message;
  late final TextEditingController _returnPolicy;
  late final TextEditingController _googleAnalyticsId;
  late bool _isLive;
  late MeasurementSystem _measurementSystem;
  late bool _showNoteEncyclopedia;
  late bool _showIngredientProfiles;
  late bool _showBrandProfile;
  late bool _showRecommendations;
  late bool _showLatestFragranceNews;
  late bool _showCommunity;
  late bool _showCompanyReviews;
  late String _homeShelfMode;
  late Set<int> _featuredProductIds;

  @override
  void initState() {
    super.initState();
    _isLive = widget.status.isLive;
    _measurementSystem = widget.status.measurementSystem;
    _showNoteEncyclopedia = widget.status.showNoteEncyclopedia;
    _showIngredientProfiles = widget.status.showIngredientProfiles;
    _showBrandProfile = widget.status.showBrandProfile;
    _showRecommendations = widget.status.showRecommendations;
    _showLatestFragranceNews = widget.status.showLatestFragranceNews;
    _showCommunity = widget.status.showCommunity;
    _showCompanyReviews = widget.status.showCompanyReviews;
    _homeShelfMode = widget.status.homeShelfMode;
    _featuredProductIds = widget.status.featuredProductIds.toSet();
    _message = TextEditingController(text: widget.status.message);
    _returnPolicy = TextEditingController(text: widget.status.returnPolicy);
    _googleAnalyticsId = TextEditingController(
      text: widget.status.googleAnalyticsMeasurementId,
    );
  }

  @override
  void dispose() {
    _message.dispose();
    _returnPolicy.dispose();
    _googleAnalyticsId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 840;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 4 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Storefront status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isLive ? 'Site is live' : 'Site is offline',
                        ),
                        subtitle: Text(
                          _isLive
                              ? 'Customers can shop normally.'
                              : 'Customers see the upgrade greeting.',
                        ),
                        value: _isLive,
                        onChanged: (value) => setState(() => _isLive = value),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<MeasurementSystem>(
                        initialValue: _measurementSystem,
                        decoration: const InputDecoration(
                          labelText: 'Measurement system',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: MeasurementSystem.standard,
                            child: Text('Standard (oz / in)'),
                          ),
                          DropdownMenuItem(
                            value: MeasurementSystem.metric,
                            child: Text('Metric (g / cm)'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () =>
                              _measurementSystem = value ?? _measurementSystem,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _message,
                        decoration: const InputDecoration(
                          labelText: 'Offline greeting',
                          prefixIcon: Icon(Icons.favorite_border),
                        ),
                        minLines: 3,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _returnPolicy,
                        decoration: const InputDecoration(
                          labelText: 'Return policy',
                          prefixIcon: Icon(Icons.replay_outlined),
                        ),
                        minLines: 3,
                        maxLines: 6,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _googleAnalyticsId,
                        decoration: const InputDecoration(
                          labelText: 'Google Analytics measurement ID',
                          prefixIcon: Icon(Icons.analytics_outlined),
                          helperText: 'Example: G-XXXXXXXXXX',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Storefront sections',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _homeShelfMode,
                        decoration: const InputDecoration(
                          labelText: 'Home product shelf',
                          prefixIcon: Icon(Icons.view_carousel_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Featured products',
                            child: Text('Featured products'),
                          ),
                          DropdownMenuItem(
                            value: 'Best sellers',
                            child: Text('Best sellers'),
                          ),
                          DropdownMenuItem(
                            value: 'Most favorited',
                            child: Text('Most favorited'),
                          ),
                          DropdownMenuItem(
                            value: 'Top rated',
                            child: Text('Top rated'),
                          ),
                          DropdownMenuItem(
                            value: 'Newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'Price low',
                            child: Text('Price low'),
                          ),
                          DropdownMenuItem(
                            value: 'Price high',
                            child: Text('Price high'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _homeShelfMode = value ?? _homeShelfMode,
                        ),
                      ),
                      if (_homeShelfMode == 'Featured products') ...[
                        const SizedBox(height: 10),
                        Text(
                          'Featured products',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        for (final product
                            in widget.products
                                .where((product) => product.isActive)
                                .take(24))
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _featuredProductIds.contains(product.id),
                            title: Text(product.name),
                            subtitle: Text(product.sku),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  if (_featuredProductIds.length < 4) {
                                    _featuredProductIds.add(product.id);
                                  }
                                } else {
                                  _featuredProductIds.remove(product.id);
                                }
                              });
                            },
                          ),
                      ],
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Note encyclopedia'),
                        value: _showNoteEncyclopedia,
                        onChanged: (value) =>
                            setState(() => _showNoteEncyclopedia = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ingredient profiles'),
                        value: _showIngredientProfiles,
                        onChanged: (value) =>
                            setState(() => _showIngredientProfiles = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('EgbeAnom profile'),
                        value: _showBrandProfile,
                        onChanged: (value) =>
                            setState(() => _showBrandProfile = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recommendations'),
                        value: _showRecommendations,
                        onChanged: (value) =>
                            setState(() => _showRecommendations = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Latest fragrance news'),
                        value: _showLatestFragranceNews,
                        onChanged: (value) =>
                            setState(() => _showLatestFragranceNews = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Community'),
                        value: _showCommunity,
                        onChanged: (value) =>
                            setState(() => _showCommunity = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Company reviews'),
                        value: _showCompanyReviews,
                        onChanged: (value) =>
                            setState(() => _showCompanyReviews = value),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await widget.onSave(
                              SiteStatus(
                                isLive: _isLive,
                                measurementSystem: _measurementSystem,
                                message: _message.text.trim().isEmpty
                                    ? SiteStatus().message
                                    : _message.text.trim(),
                                returnPolicy: _returnPolicy.text.trim().isEmpty
                                    ? SiteStatus().returnPolicy
                                    : _returnPolicy.text.trim(),
                                googleAnalyticsMeasurementId: _googleAnalyticsId
                                    .text
                                    .trim(),
                                showNoteEncyclopedia: _showNoteEncyclopedia,
                                showIngredientProfiles: _showIngredientProfiles,
                                showBrandProfile: _showBrandProfile,
                                showRecommendations: _showRecommendations,
                                showLatestFragranceNews:
                                    _showLatestFragranceNews,
                                showCommunity: _showCommunity,
                                showCompanyReviews: _showCompanyReviews,
                                homeShelfMode: _homeShelfMode,
                                featuredProductIds: _featuredProductIds
                                    .toList(),
                              ),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Site settings saved.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Site settings save failed: $error',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save site status'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 5 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 170,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something beautiful is being prepared',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_message.text, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StoreInfoSection extends StatefulWidget {
  const _StoreInfoSection({
    required this.storeInfo,
    required this.onSave,
    required this.onUploadAsset,
  });

  final StoreInfo storeInfo;
  final AsyncValueChanged<StoreInfo> onSave;
  final Future<String> Function(UploadedImageFile file) onUploadAsset;

  @override
  State<_StoreInfoSection> createState() => _StoreInfoSectionState();
}

class _StoreInfoSectionState extends State<_StoreInfoSection> {
  bool _uploadingBanner = false;
  late final _storeName = TextEditingController(
    text: widget.storeInfo.storeName,
  );
  late final _displayName = TextEditingController(
    text: widget.storeInfo.displayName,
  );
  late final _bannerUrl = TextEditingController(
    text: widget.storeInfo.bannerUrl,
  );
  late final _logoUrl = TextEditingController(text: widget.storeInfo.logoUrl);
  late final _address1 = TextEditingController(
    text: widget.storeInfo.addressLine1,
  );
  late final _address2 = TextEditingController(
    text: widget.storeInfo.addressLine2,
  );
  late final _city = TextEditingController(text: widget.storeInfo.city);
  late final _state = TextEditingController(text: widget.storeInfo.state);
  late final _postal = TextEditingController(text: widget.storeInfo.postalCode);
  late final _country = TextEditingController(text: widget.storeInfo.country);
  late final _email = TextEditingController(text: widget.storeInfo.email);
  late final _phone = TextEditingController(text: widget.storeInfo.phone);
  late final _fax = TextEditingController(text: widget.storeInfo.fax);
  late final _facebook = TextEditingController(
    text: widget.storeInfo.facebookUrl,
  );
  late final _instagram = TextEditingController(
    text: widget.storeInfo.instagramUrl,
  );
  late final _tiktok = TextEditingController(text: widget.storeInfo.tiktokUrl);
  late final _x = TextEditingController(text: widget.storeInfo.xUrl);
  late final _youtube = TextEditingController(
    text: widget.storeInfo.youtubeUrl,
  );

  @override
  void dispose() {
    for (final controller in [
      _storeName,
      _displayName,
      _bannerUrl,
      _logoUrl,
      _address1,
      _address2,
      _city,
      _state,
      _postal,
      _country,
      _email,
      _phone,
      _fax,
      _facebook,
      _instagram,
      _tiktok,
      _x,
      _youtube,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Store info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _responsiveFields([
              TextField(
                controller: _storeName,
                decoration: const InputDecoration(
                  labelText: 'Legal store name',
                ),
              ),
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                  labelText: 'Website display name',
                ),
              ),
              TextField(
                controller: _bannerUrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Uploaded banner image',
                  suffixIcon: _uploadingBanner
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Upload banner',
                          onPressed: _uploadBanner,
                          icon: const Icon(Icons.upload_file_outlined),
                        ),
                ),
              ),
              TextField(
                controller: _logoUrl,
                decoration: const InputDecoration(labelText: 'Logo URL'),
              ),
              TextField(
                controller: _address1,
                decoration: const InputDecoration(labelText: 'Address line 1'),
              ),
              TextField(
                controller: _address2,
                decoration: const InputDecoration(labelText: 'Address line 2'),
              ),
              TextField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: _state,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              TextField(
                controller: _postal,
                decoration: const InputDecoration(labelText: 'ZIP / Postal'),
              ),
              TextField(
                controller: _country,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _fax,
                decoration: const InputDecoration(labelText: 'Fax'),
              ),
              TextField(
                controller: _facebook,
                decoration: const InputDecoration(labelText: 'Facebook URL'),
              ),
              TextField(
                controller: _instagram,
                decoration: const InputDecoration(labelText: 'Instagram URL'),
              ),
              TextField(
                controller: _tiktok,
                decoration: const InputDecoration(labelText: 'TikTok URL'),
              ),
              TextField(
                controller: _x,
                decoration: const InputDecoration(labelText: 'X URL'),
              ),
              TextField(
                controller: _youtube,
                decoration: const InputDecoration(labelText: 'YouTube URL'),
              ),
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save store info'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 820
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final field in fields) SizedBox(width: width, child: field),
          ],
        );
      },
    );
  }

  Future<void> _uploadBanner() async {
    try {
      final files = await pickProductImages();
      if (files.isEmpty) {
        return;
      }
      setState(() => _uploadingBanner = true);
      final url = await widget.onUploadAsset(files.first);
      if (!mounted) {
        return;
      }
      setState(() => _bannerUrl.text = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Banner image uploaded.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Banner upload failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingBanner = false);
      }
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(
        StoreInfo(
          storeName: _storeName.text.trim(),
          displayName: _displayName.text.trim(),
          bannerUrl: _bannerUrl.text.trim(),
          logoUrl: _logoUrl.text.trim(),
          addressLine1: _address1.text.trim(),
          addressLine2: _address2.text.trim(),
          city: _city.text.trim(),
          state: _state.text.trim(),
          postalCode: _postal.text.trim(),
          country: _country.text.trim().isEmpty ? 'US' : _country.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          fax: _fax.text.trim(),
          facebookUrl: _facebook.text.trim(),
          instagramUrl: _instagram.text.trim(),
          tiktokUrl: _tiktok.text.trim(),
          xUrl: _x.text.trim(),
          youtubeUrl: _youtube.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Store info saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Store info save failed: $error')),
      );
    }
  }
}

class _TaxRulesSection extends StatefulWidget {
  const _TaxRulesSection({
    required this.taxRules,
    required this.onSave,
    required this.onDelete,
  });

  final List<TaxRule> taxRules;
  final AsyncValueChanged<TaxRule> onSave;
  final AsyncValueChanged<TaxRule> onDelete;

  @override
  State<_TaxRulesSection> createState() => _TaxRulesSectionState();
}

class _TaxRulesSectionState extends State<_TaxRulesSection> {
  TaxRule? _editing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 920;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: _HorizontalTableScroller(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('State')),
                      DataColumn(label: Text('County')),
                      DataColumn(label: Text('City')),
                      DataColumn(label: Text('ZIP')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Rate')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final rule in widget.taxRules)
                        DataRow(
                          cells: [
                            DataCell(Text(rule.name)),
                            DataCell(Text(rule.state)),
                            DataCell(Text(rule.county)),
                            DataCell(Text(rule.city)),
                            DataCell(Text(rule.postalCodePrefix)),
                            DataCell(Text(rule.isVat ? 'VAT' : rule.taxType)),
                            DataCell(
                              Text('${(rule.rate * 100).toStringAsFixed(3)}%'),
                            ),
                            DataCell(Text(rule.isEnabled ? 'Enabled' : 'Off')),
                            DataCell(
                              Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        setState(() => _editing = rule),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                            context: this.context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: const Text(
                                                'Delete tax rule?',
                                              ),
                                              content: Text(
                                                'This will permanently delete "${rule.name}".',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (!confirmed) {
                                        return;
                                      }
                                      try {
                                        await widget.onDelete(rule);
                                        if (_editing?.id == rule.id) {
                                          setState(() => _editing = null);
                                        }
                                        if (!mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Tax rule "${rule.name}" deleted.',
                                            ),
                                          ),
                                        );
                                      } catch (error) {
                                        if (!mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Tax rule delete failed: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: _TaxRuleEditor(
                key: ValueKey(_editing?.id ?? 'tax-editor-new'),
                rule: _editing,
                onSave: (rule) async {
                  await widget.onSave(rule);
                  setState(() => _editing = null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TaxRuleEditor extends StatefulWidget {
  const _TaxRuleEditor({super.key, required this.rule, required this.onSave});

  final TaxRule? rule;
  final AsyncValueChanged<TaxRule> onSave;

  @override
  State<_TaxRuleEditor> createState() => _TaxRuleEditorState();
}

class _TaxRuleEditorState extends State<_TaxRuleEditor> {
  late final _name = TextEditingController(
    text: widget.rule?.name ?? 'New tax rule',
  );
  late final _state = TextEditingController(text: widget.rule?.state ?? '');
  late final _county = TextEditingController(text: widget.rule?.county ?? '');
  late final _city = TextEditingController(text: widget.rule?.city ?? '');
  late final _zip = TextEditingController(
    text: widget.rule?.postalCodePrefix ?? '',
  );
  late final _rate = TextEditingController(
    text: ((widget.rule?.rate ?? 0.082) * 100).toStringAsFixed(3),
  );
  bool _enabled = true;
  bool _vat = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.rule?.isEnabled ?? true;
    _vat = widget.rule?.isVat ?? false;
  }

  @override
  void didUpdateWidget(covariant _TaxRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule?.id != widget.rule?.id) {
      _name.text = widget.rule?.name ?? 'New tax rule';
      _state.text = widget.rule?.state ?? '';
      _county.text = widget.rule?.county ?? '';
      _city.text = widget.rule?.city ?? '';
      _zip.text = widget.rule?.postalCodePrefix ?? '';
      _rate.text = ((widget.rule?.rate ?? 0.082) * 100).toStringAsFixed(3);
      _enabled = widget.rule?.isEnabled ?? true;
      _vat = widget.rule?.isVat ?? false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _state, _county, _city, _zip, _rate]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tax rule', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _county,
              decoration: const InputDecoration(labelText: 'County'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _zip,
              decoration: const InputDecoration(labelText: 'ZIP prefix'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rate,
              decoration: const InputDecoration(labelText: 'Rate percent'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('VAT'),
              value: _vat,
              onChanged: (value) => setState(() => _vat = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save tax rule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(
        TaxRule(
          id: widget.rule?.id ?? 'tax-${DateTime.now().millisecondsSinceEpoch}',
          name: _name.text.trim().isEmpty ? 'Tax rule' : _name.text.trim(),
          state: _state.text.trim().toUpperCase(),
          county: _county.text.trim(),
          city: _city.text.trim(),
          postalCodePrefix: _zip.text.trim(),
          taxType: _vat ? 'vat' : 'sales',
          rate: (double.tryParse(_rate.text) ?? 0) / 100,
          isVat: _vat,
          isEnabled: _enabled,
        ),
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Tax rule saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Tax rule save failed: $error')),
      );
    }
  }
}

class _BackendUsersSection extends StatefulWidget {
  const _BackendUsersSection({
    required this.users,
    required this.onSave,
    required this.onBlockIp,
  });

  final List<BackendUser> users;
  final AsyncValueChanged<BackendUser> onSave;
  final ValueChanged<String> onBlockIp;

  @override
  State<_BackendUsersSection> createState() => _BackendUsersSectionState();
}

class _BackendUsersSectionState extends State<_BackendUsersSection> {
  BackendUser? _editing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: _HorizontalTableScroller(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Last IP')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final user in widget.users)
                        DataRow(
                          cells: [
                            DataCell(Text(user.name)),
                            DataCell(Text(user.email)),
                            DataCell(Text(user.role)),
                            DataCell(
                              Text(
                                user.isBlocked
                                    ? 'Blocked'
                                    : user.isActive
                                    ? 'Active'
                                    : 'Disabled',
                              ),
                            ),
                            DataCell(Text(user.lastLoginIp)),
                            DataCell(
                              IconButton(
                                tooltip: 'Edit user',
                                onPressed: () =>
                                    setState(() => _editing = user),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: BackendUserEditor(
                user: _editing,
                onNew: () => setState(() => _editing = null),
                onBlockIp: widget.onBlockIp,
                onSave: (user) async {
                  await widget.onSave(user);
                  setState(() => _editing = null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class BackendUserEditor extends StatefulWidget {
  const BackendUserEditor({
    super.key,
    required this.user,
    required this.onNew,
    required this.onBlockIp,
    required this.onSave,
  });

  final BackendUser? user;
  final VoidCallback onNew;
  final ValueChanged<String> onBlockIp;
  final AsyncValueChanged<BackendUser> onSave;

  @override
  State<BackendUserEditor> createState() => _BackendUserEditorState();
}

class _BackendUserEditorState extends State<BackendUserEditor> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _blockedReason;
  late String _role;
  late bool _active;
  late bool _blocked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BackendUserEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.id != widget.user?.id) {
      _name.dispose();
      _email.dispose();
      _blockedReason.dispose();
      _load();
    }
  }

  void _load() {
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _blockedReason = TextEditingController(
      text: widget.user?.blockedReason ?? '',
    );
    _role = widget.user?.role ?? 'staff';
    _active = widget.user?.isActive ?? true;
    _blocked = widget.user?.isBlocked ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _blockedReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Backend user', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline),
              title: Text('Supabase Auth manages passwords'),
              subtitle: Text(
                'Create or reset this user in Supabase Auth, then keep this profile email and role in sync here.',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'owner', child: Text('Owner')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: (value) => setState(() => _role = value ?? _role),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Authorized for backend access'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Blocked account'),
              value: _blocked,
              onChanged: (value) => setState(() => _blocked = value),
            ),
            TextField(
              controller: _blockedReason,
              decoration: const InputDecoration(
                labelText: 'Blocked reason',
                prefixIcon: Icon(Icons.report_gmailerrorred_outlined),
              ),
            ),
            if ((widget.user?.lastLoginIp ?? '').isNotEmpty ||
                (widget.user?.createdIp ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((widget.user?.lastLoginIp ?? '').isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.public, size: 18),
                      label: Text('Last IP ${widget.user!.lastLoginIp}'),
                    ),
                  if ((widget.user?.createdIp ?? '').isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text('Created from ${widget.user!.createdIp}'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (widget.user?.lastLoginIp ?? '').trim().isEmpty
                    ? null
                    : () => widget.onBlockIp(widget.user!.lastLoginIp),
                icon: const Icon(Icons.public_off_outlined),
                label: const Text('Block last IP'),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNew,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onSave(
                      BackendUser(
                        id:
                            widget.user?.id ??
                            'ADM-${DateTime.now().millisecondsSinceEpoch}',
                        name: _name.text.trim().isEmpty
                            ? 'Backend user'
                            : _name.text.trim(),
                        email: _email.text.trim().toLowerCase(),
                        role: _role,
                        isActive: _active,
                        isBlocked: _blocked,
                        createdIp: widget.user?.createdIp ?? '',
                        lastLoginIp: widget.user?.lastLoginIp ?? '',
                        blockedReason: _blockedReason.text.trim(),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    final topProducts = [...products]..sort((a, b) => b.sold.compareTo(a.sold));
    final totalVisits = dailyMetrics.fold(
      0,
      (total, metric) => total + metric.visits,
    );
    final totalNewUsers = dailyMetrics.fold(
      0,
      (total, metric) => total + metric.newUsers,
    );
    final totalOrders = dailyMetrics.fold(
      0,
      (total, metric) => total + metric.orders,
    );
    final totalRevenue = dailyMetrics.fold(
      0.0,
      (total, metric) => total + metric.revenue,
    );
    final averageOrderValue = totalOrders == 0
        ? 0.0
        : totalRevenue / totalOrders;

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
                      value: '$totalVisits',
                      trend: '+${math.min(totalNewUsers, 9999)} new users',
                    ),
                    _AnalyticsPill(
                      label: 'Conversions',
                      value: '${conversionRate.toStringAsFixed(1)}%',
                      trend: '$totalOrders orders',
                    ),
                    _AnalyticsPill(
                      label: 'Revenue',
                      value: currency(totalRevenue),
                      trend: '${currency(averageOrderValue)} avg order',
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
            _MetricData(Icons.visibility_outlined, 'Visits', '$totalVisits'),
            _MetricData(Icons.person_add_alt, 'New users', '$totalNewUsers'),
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
    final tax = orders.fold(
      0.0,
      (sum, order) =>
          sum +
          math.max(
            0,
            order.total -
                order.shippingTotal -
                order.lines.fold(0.0, (lineSum, line) => lineSum + line.total),
          ),
    );
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
                ),
                _MetricData(
                  Icons.request_quote_outlined,
                  'Tax collected',
                  currency(tax),
                ),
                _MetricData(
                  Icons.local_shipping_outlined,
                  'Shipping collected',
                  currency(shipping),
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
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
      ),
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

class _InventoryTable extends StatefulWidget {
  const _InventoryTable({
    required this.products,
    required this.activeCarts,
    required this.measurementSystem,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Fragrance> products;
  final List<ActiveCart> activeCarts;
  final MeasurementSystem measurementSystem;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;

  @override
  State<_InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<_InventoryTable> {
  String _query = '';
  String _stockFilter = 'All';

  int _reservedFor(Fragrance product) {
    return widget.activeCarts.fold(0, (total, cart) {
      return total +
          cart.lines
              .where((line) => line.product.id == product.id)
              .fold(0, (lineTotal, line) => lineTotal + line.quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products.where((product) {
      final query = _query.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.itemLocation.toLowerCase().contains(query);
      final reserved = _reservedFor(product);
      final available = product.stock - reserved;
      final matchesStock = switch (_stockFilter) {
        'Low stock' => product.stock <= product.reorderPoint,
        'Reserved' => reserved > 0,
        'Available' => available > 0,
        _ => true,
      };
      return matchesQuery && matchesStock;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                'Inventory',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                return Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      flex: wide ? 4 : 0,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Filter inventory',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 10)
                    else
                      const SizedBox(height: 10),
                    Expanded(
                      flex: wide ? 3 : 0,
                      child: DropdownButtonFormField<String>(
                        initialValue: _stockFilter,
                        decoration: const InputDecoration(
                          labelText: 'Stock view',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                            value: 'Low stock',
                            child: Text('Low stock'),
                          ),
                          DropdownMenuItem(
                            value: 'Reserved',
                            child: Text('Reserved'),
                          ),
                          DropdownMenuItem(
                            value: 'Available',
                            child: Text('Available'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _stockFilter = value ?? _stockFilter,
                        ),
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 10)
                    else
                      const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _printInventory(products),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _HorizontalTableScroller(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Photo')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('In carts')),
                  DataColumn(label: Text('Available')),
                  DataColumn(label: Text('Reorder')),
                  DataColumn(label: Text('Ship size')),
                  DataColumn(label: Text('Sold')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: products.map((product) {
                  final reserved = _reservedFor(product);
                  final available = product.stock - reserved;
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox.square(
                          dimension: 42,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ProductPhoto(product: product),
                          ),
                        ),
                      ),
                      DataCell(Text(product.name)),
                      DataCell(Text(product.sku)),
                      DataCell(Text(product.type)),
                      DataCell(Text(currency(product.price))),
                      DataCell(Text('${product.stock}')),
                      DataCell(Text(product.itemLocation)),
                      DataCell(Text('$reserved')),
                      DataCell(Text('$available')),
                      DataCell(Text('${product.reorderPoint}')),
                      DataCell(
                        Text(product.shippingSize(widget.measurementSystem)),
                      ),
                      DataCell(Text('${product.sold}')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => widget.onEdit(product),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () async => widget.onRemove(product),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printInventory(List<Fragrance> products) {
    final contents = [
      'Egbe Anom inventory',
      'Filter: $_stockFilter',
      'Generated: ${DateTime.now()}',
      '',
      for (final product in products)
        '${product.sku} | ${product.name} | ${product.brand} | location ${product.itemLocation} | stock ${product.stock} | reserved ${_reservedFor(product)} | reorder ${product.reorderPoint} | ${product.shippingSize(widget.measurementSystem)}',
    ].join('\n');
    printTextDocument('Egbe Anom inventory', contents);
  }
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({
    super.key,
    required this.product,
    required this.categories,
    required this.measurementSystem,
    required this.noteOptions,
    required this.familyOptions,
    required this.seasonOptions,
    required this.occasionOptions,
    required this.onSave,
    required this.onCancel,
    required this.onUploadImages,
  });

  final Fragrance product;
  final List<Category> categories;
  final MeasurementSystem measurementSystem;
  final List<String> noteOptions;
  final List<String> familyOptions;
  final List<String> seasonOptions;
  final List<String> occasionOptions;
  final AsyncValueChanged<Fragrance> onSave;
  final VoidCallback onCancel;
  final Future<List<ProductImage>> Function(
    Fragrance product,
    List<UploadedImageFile> files,
  )
  onUploadImages;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _vibe;
  late final TextEditingController _performance;
  late final TextEditingController _comparison;
  late final TextEditingController _fragranceProfile;
  late final TextEditingController _ingredients;
  late final TextEditingController _size;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  late final TextEditingController _sku;
  late final TextEditingController _vendor;
  late final TextEditingController _itemLocation;
  late final TextEditingController _reorderPoint;
  late final TextEditingController _weightOz;
  late final TextEditingController _lengthIn;
  late final TextEditingController _widthIn;
  late final TextEditingController _heightIn;
  late List<ProductImage> _images;
  late List<ProductVariant> _variants;
  bool _uploading = false;
  bool _saving = false;
  late String _type;
  late String _concentration;
  late String _gender;
  late int _categoryId;
  late Set<String> _generalNotes;
  late Set<String> _topNotes;
  late Set<String> _heartNotes;
  late Set<String> _baseNotes;
  late Set<String> _families;
  late Set<String> _seasons;
  late Set<String> _occasions;

  static const _typeOptions = ['Perfume', 'Cologne', 'Body Oil'];
  static const _concentrationOptions = [
    'EDT',
    'EDP',
    'Parfum',
    'Extrait de Parfum',
    'Oil',
  ];
  static const _genderOptions = ['Unisex', 'Women', 'Men'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product.name);
    _brand = TextEditingController(text: widget.product.brand);
    _description = TextEditingController(text: widget.product.description);
    _vibe = TextEditingController(text: widget.product.vibe);
    _performance = TextEditingController(text: widget.product.performance);
    _comparison = TextEditingController(text: widget.product.comparison);
    _fragranceProfile = TextEditingController(
      text: widget.product.fragranceProfile,
    );
    _ingredients = TextEditingController(text: widget.product.ingredients);
    _size = TextEditingController(text: widget.product.size);
    _price = TextEditingController(
      text: widget.product.price.toStringAsFixed(2),
    );
    _cost = TextEditingController(text: widget.product.cost.toStringAsFixed(2));
    _stock = TextEditingController(text: '${widget.product.stock}');
    _sku = TextEditingController(text: widget.product.sku);
    _vendor = TextEditingController(text: widget.product.vendor);
    _itemLocation = TextEditingController(text: widget.product.itemLocation);
    _reorderPoint = TextEditingController(
      text: '${widget.product.reorderPoint}',
    );
    _weightOz = TextEditingController(
      text: _displayWeight(widget.product.weightOz).toStringAsFixed(1),
    );
    _lengthIn = TextEditingController(
      text: _displayLength(widget.product.lengthIn).toStringAsFixed(1),
    );
    _widthIn = TextEditingController(
      text: _displayLength(widget.product.widthIn).toStringAsFixed(1),
    );
    _heightIn = TextEditingController(
      text: _displayLength(widget.product.heightIn).toStringAsFixed(1),
    );
    _type = _safeDropdownValue(widget.product.type, _typeOptions);
    _concentration = _safeDropdownValue(
      widget.product.concentration,
      _concentrationOptions,
    );
    _gender = _safeDropdownValue(widget.product.gender, _genderOptions);
    _categoryId = widget.product.categoryId;
    _generalNotes = _splitValues(widget.product.notes);
    _topNotes = _splitValues(widget.product.topNotes);
    _heartNotes = _splitValues(widget.product.heartNotes);
    _baseNotes = _splitValues(widget.product.baseNotes);
    _families = _splitValues(widget.product.family);
    _seasons = _splitValues(widget.product.season);
    _occasions = _splitValues(widget.product.occasion);
    _images = [...widget.product.images];
    _variants = widget.product.variants.isEmpty
        ? [
            ProductVariant(
              id: DateTime.now().millisecondsSinceEpoch,
              size: widget.product.size,
              sku: widget.product.sku,
              price: widget.product.price,
              stock: widget.product.stock,
              reorderPoint: widget.product.reorderPoint,
            ),
          ]
        : [
            for (final variant in widget.product.variants)
              ProductVariant(
                id: variant.id,
                size: variant.size,
                sku: variant.sku,
                price: variant.price,
                stock: variant.stock,
                reorderPoint: variant.reorderPoint,
                isActive: variant.isActive,
              ),
          ];
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _description.dispose();
    _vibe.dispose();
    _performance.dispose();
    _comparison.dispose();
    _fragranceProfile.dispose();
    _ingredients.dispose();
    _size.dispose();
    _price.dispose();
    _cost.dispose();
    _stock.dispose();
    _sku.dispose();
    _vendor.dispose();
    _itemLocation.dispose();
    _reorderPoint.dispose();
    _weightOz.dispose();
    _lengthIn.dispose();
    _widthIn.dispose();
    _heightIn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final activeVariants = _variants
        .where((variant) => variant.isActive && variant.size.trim().isNotEmpty)
        .toList();
    final primaryVariant = activeVariants.isEmpty
        ? ProductVariant(
            id: DateTime.now().millisecondsSinceEpoch,
            size: _size.text.trim(),
            sku: _sku.text.trim(),
            price: double.tryParse(_price.text) ?? 0,
            stock: int.tryParse(_stock.text) ?? 0,
            reorderPoint: int.tryParse(_reorderPoint.text) ?? 8,
          )
        : activeVariants.first;
    final product = Fragrance(
      id: widget.product.id,
      name: _name.text.trim(),
      type: _type,
      brand: _brand.text.trim(),
      notes: _joinValues(_generalNotes),
      size: primaryVariant.size.trim(),
      price: primaryVariant.price,
      cost: double.tryParse(_cost.text) ?? 0,
      stock: activeVariants.fold(0, (total, variant) => total + variant.stock),
      sold: widget.product.sold,
      featuredColor: widget.product.featuredColor,
      sku: primaryVariant.sku.trim(),
      photoUrl: widget.product.photoUrl,
      vendor: _vendor.text.trim(),
      categoryId: _categoryId,
      brandId: widget.product.brandId,
      itemLocation: _itemLocation.text.trim(),
      reorderPoint: primaryVariant.reorderPoint,
      description: _description.text.trim(),
      vibe: _vibe.text.trim(),
      performance: _performance.text.trim(),
      comparison: _comparison.text.trim(),
      fragranceProfile: _fragranceProfile.text.trim(),
      ingredients: _ingredients.text.trim(),
      topNotes: _joinValues(_topNotes),
      heartNotes: _joinValues(_heartNotes),
      baseNotes: _joinValues(_baseNotes),
      concentration: _concentration,
      gender: _gender,
      season: _joinValues(_seasons),
      occasion: _joinValues(_occasions),
      family: _joinValues(_families),
      rating: widget.product.rating,
      reviewCount: widget.product.reviewCount,
      weightOz: _storedWeight(
        double.tryParse(_weightOz.text) ?? _displayWeight(8),
      ),
      lengthIn: _storedLength(
        double.tryParse(_lengthIn.text) ?? _displayLength(6),
      ),
      widthIn: _storedLength(
        double.tryParse(_widthIn.text) ?? _displayLength(3),
      ),
      heightIn: _storedLength(
        double.tryParse(_heightIn.text) ?? _displayLength(3),
      ),
      images: _images,
      variants: activeVariants,
    );
    setState(() => _saving = true);
    try {
      await widget.onSave(product);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool get _metric => widget.measurementSystem == MeasurementSystem.metric;
  String get _weightLabel => _metric ? 'Weight (g)' : 'Weight (oz)';
  String get _lengthLabel => _metric ? 'Length (cm)' : 'Length (in)';
  String get _widthLabel => _metric ? 'Width (cm)' : 'Width (in)';
  String get _heightLabel => _metric ? 'Height (cm)' : 'Height (in)';
  List<String> get _noteOptions => _mergedOptions(widget.noteOptions, [
    _generalNotes,
    _topNotes,
    _heartNotes,
    _baseNotes,
  ]);
  List<String> get _familyOptions =>
      _mergedOptions(widget.familyOptions, [_families]);
  List<String> get _seasonOptions =>
      _mergedOptions(widget.seasonOptions, [_seasons]);
  List<String> get _occasionOptions =>
      _mergedOptions(widget.occasionOptions, [_occasions]);
  double _displayWeight(double oz) => _metric ? oz * 28.3495 : oz;
  double _displayLength(double inches) => _metric ? inches * 2.54 : inches;
  double _storedWeight(double value) => _metric ? value / 28.3495 : value;
  double _storedLength(double value) => _metric ? value / 2.54 : value;
  Set<String> _splitValues(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  String _joinValues(Set<String> values) => values.join(', ');
  String _safeDropdownValue(String value, List<String> options) {
    return options.contains(value) ? value : options.first;
  }

  List<String> _mergedOptions(
    List<String> options,
    List<Set<String>> selected,
  ) {
    final merged = <String>{
      for (final option in options)
        if (option.trim().isNotEmpty) option.trim(),
      for (final values in selected)
        for (final value in values)
          if (value.trim().isNotEmpty) value.trim(),
    }.toList();
    merged.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return merged;
  }

  Future<void> _uploadImages() async {
    try {
      final files = await pickProductImages();
      if (files.isEmpty) {
        return;
      }
      setState(() => _uploading = true);
      final uploaded = await widget.onUploadImages(widget.product, files);
      if (!mounted) {
        return;
      }
      setState(() {
        _images.addAll(uploaded);
        if (_images.isNotEmpty && !_images.any((image) => image.isPrimary)) {
          _images.first.isPrimary = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${uploaded.length} photo(s) uploaded.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo upload failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _setPrimary(ProductImage image) {
    setState(() {
      for (final item in _images) {
        item.isPrimary = item == image;
      }
    });
  }

  void _removeImage(ProductImage image) {
    setState(() {
      final wasPrimary = image.isPrimary;
      _images.remove(image);
      if (wasPrimary && _images.isNotEmpty) {
        _images.first.isPrimary = true;
      }
    });
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        ProductVariant(
          id: DateTime.now().millisecondsSinceEpoch + _variants.length,
          size: '',
          sku: '',
          price: 0,
          stock: 0,
          reorderPoint: 8,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fragrance editor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Fragrance type'),
              items: [
                for (final option in _typeOptions)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue:
                  widget.categories.any(
                    (category) => category.id == _categoryId,
                  )
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Store category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in widget.categories.where(
                  (category) => category.isVisible,
                ))
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _categoryId = value ?? _categoryId),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _vendor,
                    decoration: const InputDecoration(labelText: 'Vendor'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _itemLocation,
              decoration: const InputDecoration(
                labelText: 'Item location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Fragrance notes',
              options: _noteOptions,
              selected: _generalNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _generalNotes = values),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vibe,
              decoration: const InputDecoration(labelText: 'Vibe'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _performance,
              decoration: const InputDecoration(labelText: 'Performance'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comparison,
              decoration: const InputDecoration(labelText: 'Comparison'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fragranceProfile,
              decoration: const InputDecoration(labelText: 'Fragrance profile'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ingredients,
              decoration: const InputDecoration(
                labelText: 'Notes / ingredients',
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Top notes',
              options: _noteOptions,
              selected: _topNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _topNotes = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Heart notes',
              options: _noteOptions,
              selected: _heartNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _heartNotes = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Base notes',
              options: _noteOptions,
              selected: _baseNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _baseNotes = values),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _concentration,
                    decoration: const InputDecoration(
                      labelText: 'Concentration',
                    ),
                    items: [
                      for (final option in _concentrationOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) => setState(
                      () => _concentration = value ?? _concentration,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: [
                      for (final option in _genderOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) =>
                        setState(() => _gender = value ?? _gender),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Families',
              options: _familyOptions,
              selected: _families,
              onChanged: (values) => setState(() => _families = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Seasons',
              options: _seasonOptions,
              selected: _seasons,
              onChanged: (values) => setState(() => _seasons = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Occasions',
              options: _occasionOptions,
              selected: _occasions,
              onChanged: (values) => setState(() => _occasions = values),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cost,
              decoration: const InputDecoration(
                labelText: 'Admin cost',
                prefixIcon: Icon(Icons.price_check_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _VariantTable(
              variants: _variants,
              onAdd: _addVariant,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightOz,
                    decoration: InputDecoration(
                      labelText: _weightLabel,
                      prefixIcon: const Icon(Icons.scale_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lengthIn,
                    decoration: InputDecoration(labelText: _lengthLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _widthIn,
                    decoration: InputDecoration(labelText: _widthLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _heightIn,
                    decoration: InputDecoration(labelText: _heightLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Product photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _uploadImages,
              icon: _uploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_uploading ? 'Uploading photos' : 'Upload photos'),
            ),
            if (_uploading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              const Text('Uploading selected product photos...'),
            ],
            const SizedBox(height: 8),
            if (_images.isEmpty)
              const Text('No product photos uploaded yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final image in _images)
                    SizedBox(
                      width: 92,
                      height: 126,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: image.isPrimary
                                ? const Color(0xFFC88F52)
                                : const Color(0xFFE2DCD2),
                            width: image.isPrimary ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: ProductImageView(
                                source: image.url,
                                fallbackColor: widget.product.featuredColor,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Make primary',
                                  onPressed: () => _setPrimary(image),
                                  iconSize: 18,
                                  icon: Icon(
                                    image.isPrimary
                                        ? Icons.star
                                        : Icons.star_border,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove photo',
                                  onPressed: () => _removeImage(image),
                                  iconSize: 18,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectChipGroup extends StatefulWidget {
  const _MultiSelectChipGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowCustomEntry = false,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool allowCustomEntry;

  @override
  State<_MultiSelectChipGroup> createState() => _MultiSelectChipGroupState();
}

class _MultiSelectChipGroupState extends State<_MultiSelectChipGroup> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _addCustom() {
    final value = _custom.text.trim();
    if (value.isEmpty) {
      return;
    }
    final next = {...widget.selected, value};
    widget.onChanged(next);
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.title,
        filled: true,
        fillColor: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final option in widget.options)
                FilterChip(
                  label: Text(option),
                  selected: widget.selected.contains(option),
                  onSelected: (value) {
                    final next = {...widget.selected};
                    if (value) {
                      next.add(option);
                    } else {
                      next.remove(option);
                    }
                    widget.onChanged(next);
                  },
                ),
            ],
          ),
          if (widget.allowCustomEntry) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _custom,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Add note for this fragrance',
                    ),
                    onSubmitted: (_) => _addCustom(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Add note',
                  onPressed: _addCustom,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantTable extends StatelessWidget {
  const _VariantTable({
    required this.variants,
    required this.onAdd,
    required this.onChanged,
  });

  final List<ProductVariant> variants;
  final VoidCallback onAdd;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sizes, pricing, and inventory',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add size'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _HorizontalTableScroller(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Live')),
              DataColumn(label: Text('Size')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Reorder')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final variant in variants)
                DataRow(
                  cells: [
                    DataCell(
                      Switch(
                        value: variant.isActive,
                        onChanged: (value) {
                          variant.isActive = value;
                          onChanged();
                        },
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          initialValue: variant.size,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Size',
                          ),
                          onChanged: (value) => variant.size = value,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          initialValue: variant.sku,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'SKU',
                          ),
                          onChanged: (value) => variant.sku = value,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: variant.price.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Price',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              variant.price = double.tryParse(value) ?? 0,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 76,
                        child: TextFormField(
                          initialValue: '${variant.stock}',
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Stock',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              variant.stock = int.tryParse(value) ?? 0,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 86,
                        child: TextFormField(
                          initialValue: '${variant.reorderPoint}',
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Reorder',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              variant.reorderPoint = int.tryParse(value) ?? 8,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Remove size',
                        onPressed: variants.length == 1
                            ? null
                            : () {
                                variants.remove(variant);
                                onChanged();
                              },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderFulfillmentEditor extends StatefulWidget {
  const _OrderFulfillmentEditor({
    required this.order,
    required this.onSave,
    required this.onCreateShippingLabel,
  });

  final Order order;
  final AsyncValueChanged<Order> onSave;
  final Future<ShippingLabelResult> Function(Order order) onCreateShippingLabel;

  @override
  State<_OrderFulfillmentEditor> createState() =>
      _OrderFulfillmentEditorState();
}

class _OrderFulfillmentEditorState extends State<_OrderFulfillmentEditor> {
  late TextEditingController _tracking;
  late String _status;
  late String _carrier;
  late String _service;
  late String _labelStatus;
  bool _creatingLabel = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.fulfillmentStatus;
    _carrier = widget.order.shippingCarrier.isEmpty
        ? 'USPS'
        : widget.order.shippingCarrier;
    _service = widget.order.shippingService.isEmpty
        ? 'Ground Advantage'
        : widget.order.shippingService;
    _labelStatus = widget.order.labelStatus;
    _tracking = TextEditingController(text: widget.order.trackingNumber);
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Order status'),
                items: const [
                  DropdownMenuItem(
                    value: 'Unfulfilled',
                    child: Text('Unfulfilled'),
                  ),
                  DropdownMenuItem(
                    value: 'Being picked',
                    child: Text('Being picked'),
                  ),
                  DropdownMenuItem(value: 'Packing', child: Text('Packing')),
                  DropdownMenuItem(
                    value: 'Label created',
                    child: Text('Label created'),
                  ),
                  DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                  DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                  DropdownMenuItem(
                    value: 'Delivered',
                    child: Text('Delivered'),
                  ),
                  DropdownMenuItem(
                    value: 'Cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _carrier,
                decoration: const InputDecoration(labelText: 'Carrier'),
                items: const [
                  DropdownMenuItem(value: 'USPS', child: Text('USPS')),
                  DropdownMenuItem(value: 'UPS', child: Text('UPS')),
                  DropdownMenuItem(value: 'FedEx', child: Text('FedEx')),
                  DropdownMenuItem(value: 'DHL', child: Text('DHL')),
                ],
                onChanged: (value) =>
                    setState(() => _carrier = value ?? _carrier),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _service,
                decoration: const InputDecoration(labelText: 'Service'),
                items: const [
                  DropdownMenuItem(
                    value: 'Ground Advantage',
                    child: Text('Ground Advantage'),
                  ),
                  DropdownMenuItem(
                    value: 'Priority Mail',
                    child: Text('Priority Mail'),
                  ),
                  DropdownMenuItem(value: 'Ground', child: Text('Ground')),
                  DropdownMenuItem(value: '2 Day', child: Text('2 Day')),
                  DropdownMenuItem(value: 'Express', child: Text('Express')),
                ],
                onChanged: (value) =>
                    setState(() => _service = value ?? _service),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _tracking,
                decoration: const InputDecoration(labelText: 'Tracking number'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _creatingLabel
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (_carrier != 'USPS') {
                          setState(() {
                            _labelStatus = 'Label created';
                            _status = 'Label created';
                          });
                          return;
                        }
                        setState(() => _creatingLabel = true);
                        try {
                          final label = await widget.onCreateShippingLabel(
                            widget.order,
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _tracking.text = label.trackingNumber;
                            _labelStatus = label.labelStatus;
                            _status = 'Label created';
                            _service = widget.order.shippingService.isEmpty
                                ? _service
                                : widget.order.shippingService;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'USPS label created for ${label.trackingNumber}.',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text('$error')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _creatingLabel = false);
                          }
                        }
                      },
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(_creatingLabel ? 'Creating label' : 'Create label'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  widget.order
                    ..status = _status == 'Unfulfilled'
                        ? 'Paid'
                        : _status == 'Sent'
                        ? 'Shipped'
                        : _status
                    ..fulfillmentStatus = _status
                    ..shippingCarrier = _carrier
                    ..shippingService = _service
                    ..trackingNumber = _tracking.text.trim()
                    ..labelStatus = _labelStatus;
                  widget.onSave(widget.order);
                },
                icon: const Icon(Icons.save_outlined),
                label: Text('Save • $_labelStatus'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
