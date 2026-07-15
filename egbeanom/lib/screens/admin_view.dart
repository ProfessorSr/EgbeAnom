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
  mailingLists,
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
    required this.initialSection,
    required this.products,
    required this.categories,
    required this.orders,
    required this.activeCarts,
    required this.customers,
    required this.mailingListSubscribers,
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
    required this.emailMessages,
    required this.sectionAttentionCounts,
    required this.siteStatus,
    required this.storeInfo,
    required this.taxRules,
    required this.measurementSystem,
    required this.backendUsers,
    required this.activeUserSessions,
    required this.analyticsEvents,
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
    required this.onCreateStripeRefund,
    required this.onCreateShippingLabel,
    required this.onBatchUpdateOrders,
    required this.onUpdateReview,
    required this.onSendEmail,
    required this.onSyncInboundEmail,
    required this.onEmailMessageRead,
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
    required this.onNotificationRead,
    required this.onNotificationOpen,
  });

  final AdminSection initialSection;
  final List<Fragrance> products;
  final List<Category> categories;
  final List<Order> orders;
  final List<ActiveCart> activeCarts;
  final List<CustomerAccount> customers;
  final List<MailingListSubscriber> mailingListSubscribers;
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
  final List<EmailMessage> emailMessages;
  final Map<AdminSection, int> sectionAttentionCounts;
  final SiteStatus siteStatus;
  final StoreInfo storeInfo;
  final List<TaxRule> taxRules;
  final MeasurementSystem measurementSystem;
  final List<BackendUser> backendUsers;
  final List<ActiveUserSession> activeUserSessions;
  final List<AnalyticsEvent> analyticsEvents;
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
  final Future<String> Function(Order order, double amount, String reason)
  onCreateStripeRefund;
  final Future<ShippingLabelResult> Function(Order order) onCreateShippingLabel;
  final void Function(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  )
  onBatchUpdateOrders;
  final Future<void> Function(ReviewSummary review, String status)
  onUpdateReview;
  final void Function(
    String audience,
    String subject,
    String body,
    String accountId,
  )
  onSendEmail;
  final Future<void> Function(String accountId) onSyncInboundEmail;
  final void Function(EmailMessage message, bool isRead) onEmailMessageRead;
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
  final ValueChanged<StoreNotification> onNotificationRead;
  final ValueChanged<StoreNotification> onNotificationOpen;

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  late AdminSection _section = widget.initialSection;
  Fragrance? _editing;

  @override
  void didUpdateWidget(covariant AdminView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSection != oldWidget.initialSection) {
      setState(() => _section = widget.initialSection);
    }
  }

  AdminDashboardMetrics get _metrics => AdminDashboardMetrics.from(
    products: widget.products,
    orders: widget.orders,
    activeCarts: widget.activeCarts,
    customers: widget.customers,
    dailyMetrics: widget.dailyMetrics,
  );

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
            attentionCounts: widget.sectionAttentionCounts,
            onSelected: (section) => setState(() => _section = section),
          ),
          const SizedBox(height: 18),
          _buildSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    final metrics = _metrics;
    return switch (_section) {
      AdminSection.overview => _AdminOverview(
        revenue: metrics.revenue,
        inventory: metrics.inventory,
        unitsSold: metrics.unitsSold,
        orderCount: widget.orders.length,
        reservedInventory: metrics.reservedInventory,
        cartValue: metrics.cartValue,
        newUsersToday: metrics.newUsersToday,
        newUsers7Days: metrics.newUsers7Days,
        conversionRate: metrics.conversionRate,
        lowStockProducts: metrics.lowStockProducts,
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
        lowStockProducts: metrics.lowStockProducts,
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
        onSendEmail: (audience, subject, body) => widget.onSendEmail(
          audience,
          subject,
          body,
          widget.emailSettings.id,
        ),
        onSaveCustomer: widget.onSaveCustomer,
        onBlockIp: widget.onBlockIp,
      ),
      AdminSection.orders => _OrdersSection(
        orders: widget.orders,
        customers: widget.customers,
        shippingOptions: widget.shippingOptions,
        storeInfo: widget.storeInfo,
        siteStatus: widget.siteStatus,
        onUpdateOrder: widget.onUpdateOrder,
        onSaveCustomer: widget.onSaveCustomer,
        onCreateStripeRefund: widget.onCreateStripeRefund,
        onCreateShippingLabel: widget.onCreateShippingLabel,
        onBatchUpdateOrders: widget.onBatchUpdateOrders,
      ),
      AdminSection.invoices => _InvoicesSection(
        orders: widget.orders,
        storeInfo: widget.storeInfo,
        siteStatus: widget.siteStatus,
        onUpdateOrder: widget.onUpdateOrder,
      ),
      AdminSection.reviews => _ReviewsSection(
        reviews: widget.reviews,
        onUpdateReview: widget.onUpdateReview,
      ),
      AdminSection.notifications => _NotificationsSection(
        notifications: widget.notifications,
        onNotificationRead: widget.onNotificationRead,
        onNotificationOpen: widget.onNotificationOpen,
      ),
      AdminSection.email => _EmailSection(
        customers: widget.customers,
        mailingListSubscribers: widget.mailingListSubscribers,
        messages: widget.emailMessages,
        settings: widget.emailSettings,
        onSendEmail: widget.onSendEmail,
        onSyncInbox: widget.onSyncInboundEmail,
        onMessageRead: widget.onEmailMessageRead,
        onSaveSettings: widget.onSaveEmailSettings,
      ),
      AdminSection.mailingLists => _MailingListsSection(
        customers: widget.customers,
        subscribers: widget.mailingListSubscribers,
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
        storeInfo: widget.storeInfo,
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
        reviews: widget.reviews,
        events: widget.analyticsEvents,
        activeCarts: widget.activeCarts,
        conversionRate: metrics.conversionRate,
        onOpenSection: (section) => setState(() => _section = section),
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
        conversionRate: metrics.conversionRate,
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
  const _AdminSectionBar({
    required this.selected,
    required this.attentionCounts,
    required this.onSelected,
  });

  final AdminSection selected;
  final Map<AdminSection, int> attentionCounts;
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
      (
        AdminSection.mailingLists,
        Icons.mark_email_read_outlined,
        'Mailing Lists',
      ),
      (AdminSection.analytics, Icons.analytics_outlined, 'Analytics'),
      (AdminSection.site, Icons.toggle_on_outlined, 'Site'),
      (
        AdminSection.storeInfo,
        Icons.store_mall_directory_outlined,
        'Store info',
      ),
      (AdminSection.taxes, Icons.request_quote_outlined, 'Taxes'),
      (AdminSection.backendUsers, Icons.admin_panel_settings_outlined, 'Users'),
      (AdminSection.reports, Icons.file_download_outlined, 'Reports'),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.$3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if ((attentionCounts[item.$1] ?? 0) > 0) ...[
                            const SizedBox(width: 8),
                            _AdminSectionAttentionBadge(
                              count: attentionCounts[item.$1]!,
                              foreground: Colors.white,
                              background: const Color(0xFFB3261E),
                            ),
                          ],
                        ],
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
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: Text(item.$3)),
                            if ((attentionCounts[item.$1] ?? 0) > 0) ...[
                              const SizedBox(width: 8),
                              _AdminSectionAttentionBadge(
                                count: attentionCounts[item.$1]!,
                                foreground: Colors.white,
                                background: const Color(0xFFB3261E),
                              ),
                            ],
                          ],
                        ),
                      ),
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

class _AdminSectionAttentionBadge extends StatelessWidget {
  const _AdminSectionAttentionBadge({
    required this.count,
    required this.foreground,
    required this.background,
  });

  final int count;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
