part of '../main.dart';

class StoreShell extends StatefulWidget {
  const StoreShell({super.key});

  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  final StoreDataGateway _gateway = const StoreDataGateway();
  StoreView _view = StoreView.shop;
  StreamSubscription<String>? _browserRouteSubscription;
  String _lastBrowserRoute = '/';
  bool _accountStartsCreating = false;
  String _filter = 'All';
  String _query = '';
  String _sort = 'Featured';
  StoreInfoPage _infoPage = StoreInfoPage.notes;
  Fragrance? _selectedProduct;
  final List<CartLine> _cart = [];
  final List<Category> _categories = [];
  final List<BrandProfile> _brands = [];
  CustomerAccount? _currentCustomer;
  BackendUser? _currentBackendUser;
  String _adminLoginError = '';
  final Set<int> _wishlistProductIds = {};
  final List<Order> _orders = [];
  Order? _lastCompletedOrder;
  String _lastTrackedPage = '';
  late final String _visitorSessionId =
      'VIS-${DateTime.now().millisecondsSinceEpoch}';
  late final DateTime _visitorStartedAt = DateTime.now();
  final List<ActiveUserSession> _activeUserSessions = [];

  final List<Fragrance> _products = [];

  final List<CouponRule> _coupons = [];

  final List<PaymentMethodConfig> _paymentMethods = [];
  final List<ShippingOption> _shippingOptions = [];
  final List<TaxRule> _taxRules = [];
  StoreInfo _storeInfo = StoreInfo();
  String _selectedShippingOptionId = '';
  String _checkoutEmail = '';
  String _checkoutPhone = '';
  ShippingAddress _checkoutShippingAddress = ShippingAddress();

  final List<ContentBlock> _contentBlocks = [];

  final List<NewsItem> _newsItems = [];
  final List<FragranceNoteGuide> _noteGuide = [];
  final List<IngredientGuide> _ingredientGuide = [];
  final List<String> _familyOptions = [];
  final List<String> _seasonOptions = [];
  final List<String> _occasionOptions = [];

  final List<ReviewSummary> _productReviews = [];

  final List<ReviewSummary> _companyReviews = [];
  final SiteStatus _siteStatus = SiteStatus();
  final EmailServerSettings _emailSettings = EmailServerSettings();
  final Map<String, ShippingCarrierCredentials> _shippingCredentials = {
    'USPS': const ShippingCarrierCredentials(),
    'UPS': const ShippingCarrierCredentials(),
    'FedEx': const ShippingCarrierCredentials(),
    'DHL': const ShippingCarrierCredentials(),
  };
  final List<BackendUser> _backendUsers = [];
  final List<StoreNotification> _notifications = [];
  bool _adminPreviewMode = false;
  bool _refreshingShippingRate = false;

  List<ActiveCart> get _marketplaceCarts => [];

  final List<CustomerAccount> _customers = [];

  final List<DailyMetric> _dailyMetrics = [];

  @override
  void initState() {
    super.initState();
    final currentRoute = currentBrowserRoute();
    _lastBrowserRoute = currentRoute;
    _view = _viewForBrowserRoute(currentRoute) ?? _initialViewForReturnUrl();
    _browserRouteSubscription = browserRouteChanges().listen(
      _handleBrowserRouteChange,
    );
    _loadStoreData();
    _restoreAuthSession();
  }

  @override
  void dispose() {
    _browserRouteSubscription?.cancel();
    super.dispose();
  }

  StoreView _initialViewForReturnUrl() {
    final uri = Uri.base;
    final payment = uri.queryParameters['payment']?.toLowerCase();
    if (payment == 'success' || uri.path.contains('payment-success')) {
      return StoreView.paymentSuccess;
    }
    if (payment == 'failed' ||
        payment == 'failure' ||
        uri.path.contains('payment-failed') ||
        uri.path.contains('payment-cancelled')) {
      return StoreView.paymentFailure;
    }
    return StoreView.shop;
  }

  StoreView? _viewForBrowserRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) {
      return null;
    }
    final payment = uri.queryParameters['payment']?.toLowerCase();
    if (payment == 'success' || uri.path.contains('payment-success')) {
      return StoreView.paymentSuccess;
    }
    if (payment == 'failed' ||
        payment == 'failure' ||
        uri.path.contains('payment-failed') ||
        uri.path.contains('payment-cancelled')) {
      return StoreView.paymentFailure;
    }
    return switch (uri.path) {
      '/cart' => StoreView.cart,
      '/checkout' => StoreView.checkout,
      '/account' => StoreView.account,
      '/admin' => StoreView.admin,
      '/info' => StoreView.info,
      '/catalog' => StoreView.catalog,
      '/' || '' => StoreView.shop,
      _ => null,
    };
  }

  String _routeForView(StoreView view) {
    return switch (view) {
      StoreView.shop => '/',
      StoreView.catalog => '/catalog',
      StoreView.detail => '/',
      StoreView.cart => '/cart',
      StoreView.checkout => '/checkout',
      StoreView.account => '/account',
      StoreView.info => '/info',
      StoreView.admin => '/admin',
      StoreView.paymentSuccess => '/payment-success',
      StoreView.paymentFailure => '/payment-failed',
    };
  }

  void _handleBrowserRouteChange(String route) {
    final view = _viewForBrowserRoute(route);
    if (view == null || !mounted) {
      return;
    }
    setState(() {
      _lastBrowserRoute = route;
      _view = view;
    });
  }

  void _scheduleBrowserRouteSync() {
    final route = _routeForView(_view);
    if (route == _lastBrowserRoute) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final nextRoute = _routeForView(_view);
      if (nextRoute == _lastBrowserRoute) {
        return;
      }
      pushBrowserRoute(nextRoute);
      _lastBrowserRoute = nextRoute;
    });
  }

  Future<void> _restoreAuthSession() async {
    CustomerAccount? customer;
    BackendUser? backendUser;
    try {
      final customerRow = await _gateway.restoreCustomerSession();
      if (customerRow != null) {
        customer = CustomerAccount.fromRow(customerRow);
      }
      final backendRow = await _gateway.restoreBackendSession();
      if (backendRow != null) {
        backendUser = BackendUser.fromRow(backendRow);
      }
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _currentCustomer = customer;
      _currentBackendUser = backendUser;
      if (backendUser != null) {
        _adminPreviewMode = true;
      }
    });
    if (customer != null || backendUser != null) {
      await _loadStoreData();
    }
  }

  Future<void> _loadStoreData() async {
    Future<T> fallback<T>(Future<T> Function() load, T value) async {
      try {
        return await load();
      } catch (error, stackTrace) {
        // Track error but allow graceful fallback
        ErrorTracker().captureException(
          error,
          stackTrace: stackTrace,
          contexts: {'operation': 'store_data_load', 'data_type': T.toString()},
        );
        return value;
      }
    }

    final categories = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchCategories,
      [],
    );
    final products = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchProducts,
      [],
    );
    if (mounted) {
      setState(() {
        if (categories.isNotEmpty) {
          _categories
            ..clear()
            ..addAll(categories.map(Category.fromRow));
        }
        if (products.isNotEmpty) {
          _products
            ..clear()
            ..addAll(products.map(Fragrance.fromRow));
        }
      });
    }
    final contentBlocks = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchContentBlocks,
      [],
    );
    final coupons = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchCouponRules,
      [],
    );
    final paymentMethods = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchPaymentMethods,
      [],
    );
    final shippingOptions = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchShippingOptions,
      [],
    );
    final taxRules = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchTaxRules,
      [],
    );
    final brands = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchBrands,
      [],
    );
    final fragranceNotes = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchFragranceNotes,
      [],
    );
    final fragranceFamilies = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchFragranceFamilies,
      [],
    );
    final fragranceSeasons = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchFragranceSeasons,
      [],
    );
    final fragranceOccasions = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchFragranceOccasions,
      [],
    );
    final orders = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchOrders,
      [],
    );
    final customers = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchCustomerAccounts,
      [],
    );
    final siteStatus = await fallback<Map<String, dynamic>?>(
      _gateway.fetchSiteStatus,
      null,
    );
    final emailSettings = await fallback<Map<String, dynamic>?>(
      _gateway.fetchEmailServerSettings,
      null,
    );
    final shippingCredentials = await fallback<Map<String, dynamic>?>(
      _gateway.fetchShippingCarrierCredentials,
      null,
    );
    final carrierCredentialRows = <String, Map<String, dynamic>?>{};
    for (final carrier in _shippingCredentials.keys) {
      carrierCredentialRows[carrier] = await fallback<Map<String, dynamic>?>(
        () => _gateway.fetchShippingCarrierCredentialsForCarrier(carrier),
        null,
      );
    }
    final storeInfo = await fallback<Map<String, dynamic>?>(
      _gateway.fetchStoreInfo,
      null,
    );
    final backendUsers = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchBackendUsers,
      [],
    );
    final reviews = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchReviews,
      [],
    );
    final notifications = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchNotifications,
      [],
    );

    if (!mounted) {
      return;
    }

    const allowedPaymentProviders = {
      'stripe',
      'apple pay',
      'google pay',
      'square',
      'paypal',
    };

    setState(() {
      _contentBlocks
        ..clear()
        ..addAll(contentBlocks.map(ContentBlock.fromRow));
      _coupons
        ..clear()
        ..addAll(coupons.map(CouponRule.fromRow));
      if (paymentMethods.isNotEmpty) {
        _paymentMethods
          ..clear()
          ..addAll(
            paymentMethods
                .map(PaymentMethodConfig.fromRow)
                .where(
                  (method) => allowedPaymentProviders.contains(
                    method.provider.toLowerCase(),
                  ),
                ),
          );
      }
      if (shippingOptions.isNotEmpty) {
        _shippingOptions
          ..clear()
          ..addAll(shippingOptions.map(ShippingOption.fromRow));
        _shippingOptions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
      if (taxRules.isNotEmpty) {
        _taxRules
          ..clear()
          ..addAll(taxRules.map(TaxRule.fromRow));
      }
      if (brands.isNotEmpty) {
        _brands
          ..clear()
          ..addAll(brands.map(BrandProfile.fromRow));
      }
      if (fragranceNotes.isNotEmpty) {
        _noteGuide
          ..clear()
          ..addAll(fragranceNotes.map(FragranceNoteGuide.fromRow));
      }
      _replaceOptionList(_familyOptions, fragranceFamilies);
      _replaceOptionList(_seasonOptions, fragranceSeasons);
      _replaceOptionList(_occasionOptions, fragranceOccasions);
      if (orders.isNotEmpty) {
        _orders
          ..clear()
          ..addAll(orders.map(Order.fromRow));
      }
      if (customers.isNotEmpty) {
        _customers
          ..clear()
          ..addAll(customers.map(CustomerAccount.fromRow));
      }
      if (reviews.isNotEmpty) {
        final loadedReviews = reviews.map(ReviewSummary.fromRow).toList();
        _productReviews
          ..clear()
          ..addAll(
            loadedReviews.where(
              (review) =>
                  review.scope.toLowerCase() == 'product' ||
                  review.scope.toLowerCase() == 'fragrance',
            ),
          );
        _companyReviews
          ..clear()
          ..addAll(
            loadedReviews.where(
              (review) => review.scope.toLowerCase() == 'company',
            ),
          );
      }
      if (notifications.isNotEmpty) {
        _notifications
          ..clear()
          ..addAll(notifications.map(StoreNotification.fromRow));
      }
      if (siteStatus != null) {
        final status = SiteStatus.fromRow(siteStatus);
        _siteStatus
          ..isLive = status.isLive
          ..measurementSystem = status.measurementSystem
          ..message = status.message
          ..showNoteEncyclopedia = status.showNoteEncyclopedia
          ..showIngredientProfiles = status.showIngredientProfiles
          ..showBrandProfile = status.showBrandProfile
          ..showRecommendations = status.showRecommendations
          ..showLatestFragranceNews = status.showLatestFragranceNews
          ..showCommunity = status.showCommunity
          ..showCompanyReviews = status.showCompanyReviews
          ..homeShelfMode = status.homeShelfMode
          ..featuredProductIds = List.of(status.featuredProductIds)
          ..returnPolicy = status.returnPolicy
          ..googleAnalyticsMeasurementId = status.googleAnalyticsMeasurementId;
        configureGoogleAnalytics(_siteStatus.googleAnalyticsMeasurementId);
        trackGoogleAnalyticsPage(_view.name);
      }
      if (emailSettings != null) {
        final settings = EmailServerSettings.fromRow(emailSettings);
        _emailSettings
          ..fromName = settings.fromName
          ..fromEmail = settings.fromEmail
          ..imapHost = settings.imapHost
          ..imapPort = settings.imapPort
          ..smtpHost = settings.smtpHost
          ..smtpPort = settings.smtpPort
          ..username = settings.username
          ..useSsl = settings.useSsl;
      }
      final legacyValue =
          shippingCredentials != null && shippingCredentials['value'] is Map
          ? (shippingCredentials['value'] as Map).cast<Object?, Object?>()
          : const <Object?, Object?>{};
      for (final carrier in _shippingCredentials.keys) {
        final providerSetting = carrierCredentialRows[carrier];
        if (providerSetting != null && providerSetting['value'] is Map) {
          _shippingCredentials[carrier] = ShippingCarrierCredentials.fromJson(
            providerSetting['value'],
          );
          continue;
        }
        _shippingCredentials[carrier] = ShippingCarrierCredentials.fromJson(
          legacyValue[carrier],
        );
      }
      if (storeInfo != null) {
        _storeInfo = StoreInfo.fromRow(storeInfo);
      }
      final activeShippingOptions = _enabledShippingOptions;
      if (activeShippingOptions.isNotEmpty &&
          !activeShippingOptions.any(
            (option) => option.id == _selectedShippingOptionId,
          )) {
        _selectedShippingOptionId = activeShippingOptions.first.id;
      }
      if (backendUsers.isNotEmpty) {
        _backendUsers
          ..clear()
          ..addAll(backendUsers.map(BackendUser.fromRow));
      }
    });
    unawaited(_loadFragranceNews());
  }

  Future<void> _loadFragranceNews() async {
    try {
      final rssArticles = await loadFragranceRssArticles();
      if (!mounted || rssArticles.isEmpty) {
        return;
      }
      setState(() {
        _newsItems
          ..clear()
          ..addAll(
            rssArticles.map(
              (article) => NewsItem(
                source: article.source,
                title: article.title,
                summary: article.summary,
                url: article.url,
              ),
            ),
          );
      });
    } catch (_) {
      // RSS feeds are non-critical; products and checkout should still render.
    }
  }

  void _replaceOptionList(
    List<String> target,
    List<Map<String, dynamic>> rows,
  ) {
    final names = rows
        .map((row) => '${row['name'] ?? ''}'.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return;
    }
    target
      ..clear()
      ..addAll(names);
  }

  List<Fragrance> get _visibleProducts {
    var active = _products.where((product) => product.isActive).toList();
    if (_filter != 'All') {
      final category = _categories.firstWhere(
        (item) => item.name == _filter,
        orElse: () =>
            Category(id: -1, name: _filter, description: '', sortOrder: 0),
      );
      active = active
          .where((product) => product.categoryId == category.id)
          .toList();
    }
    if (_query.trim().isNotEmpty) {
      final query = _query.toLowerCase();
      active = active
          .where((product) => _productSearchText(product).contains(query))
          .toList();
    }
    active.sort((a, b) {
      return switch (_sort) {
        'Price low' => a.price.compareTo(b.price),
        'Price high' => b.price.compareTo(a.price),
        'Best sellers' => b.sold.compareTo(a.sold),
        _ => a.id.compareTo(b.id),
      };
    });
    return active;
  }

  String _productSearchText(Fragrance product) {
    return [
      product.name,
      product.type,
      product.brand,
      product.vendor,
      product.sku,
      product.description,
      product.vibe,
      product.performance,
      product.comparison,
      product.fragranceProfile,
      product.ingredients,
      product.notes,
      product.topNotes,
      product.heartNotes,
      product.baseNotes,
      product.concentration,
      product.gender,
      product.season,
      product.occasion,
      product.family,
      product.itemLocation,
    ].join(' ').toLowerCase();
  }

  List<Fragrance> get _homeProducts {
    final active = _products.where((product) => product.isActive).toList();
    if (_siteStatus.homeShelfMode == 'Featured products' &&
        _siteStatus.featuredProductIds.isNotEmpty) {
      final featured = <Fragrance>[];
      for (final id in _siteStatus.featuredProductIds) {
        for (final product in active) {
          if (product.id == id && !featured.any((item) => item.id == id)) {
            featured.add(product);
          }
        }
      }
      if (featured.isNotEmpty) {
        return featured.take(4).toList();
      }
    }
    active.sort((a, b) {
      return switch (_siteStatus.homeShelfMode) {
        'Most favorited' =>
          (_wishlistProductIds.contains(b.id) ? 1 : 0).compareTo(
            _wishlistProductIds.contains(a.id) ? 1 : 0,
          ),
        'Top rated' => b.rating.compareTo(a.rating),
        'Newest' => b.id.compareTo(a.id),
        'Price low' => a.price.compareTo(b.price),
        'Price high' => b.price.compareTo(a.price),
        _ => b.sold.compareTo(a.sold),
      };
    });
    return active.take(4).toList();
  }

  String get _homeShelfTitle => _siteStatus.homeShelfMode;

  void _showStatusSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCatalog({String? query, String? filter}) {
    setState(() {
      if (query != null) {
        _query = query;
      }
      if (filter != null) {
        _filter = filter;
      }
      _view = StoreView.catalog;
    });
  }

  BrandProfile get _egbeAnomProfile {
    return _brands.firstWhere(
      (brand) => brand.name.toLowerCase().replaceAll(' ', '') == 'egbeanom',
      orElse: () => BrandProfile(
        id: 1,
        name: 'EgbeAnom',
        description:
            'A fragrance house focused on expressive perfume, cologne, and body oil rituals.',
        country: 'US',
        history:
            'EgbeAnom is built as a single-house fragrance experience: every scent, oil, recommendation, and order flow centers on the EgbeAnom catalog.',
        sortOrder: 1,
      ),
    );
  }

  int get _cartCount => _cart.fold(0, (total, line) => total + line.quantity);
  double get _cartSubtotal =>
      _cart.fold(0, (total, line) => total + line.total);
  double get _tax {
    final activeRules = _taxRules.where((rule) => rule.isEnabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (activeRules.isEmpty) {
      return 0;
    }
    final combinedRate = activeRules.fold<double>(
      0,
      (total, rule) => total + rule.rate,
    );
    return _cartSubtotal * combinedRate;
  }

  List<ShippingOption> get _enabledShippingOptions =>
      _shippingOptions.where((option) => option.isEnabled).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  ShippingOption get _selectedShippingOption {
    final options = _enabledShippingOptions;
    if (options.isEmpty) {
      throw StateError('No enabled shipping options are configured.');
    }
    return options.firstWhere(
      (option) => option.id == _selectedShippingOptionId,
      orElse: () => options.first,
    );
  }

  double get _shipping => _cartSubtotal > 125 || _cartSubtotal == 0
      ? 0
      : (_enabledShippingOptions.isEmpty ? 0 : _selectedShippingOption.price);
  double get _cartTotal => _cartSubtotal + _tax + _shipping;

  void _recordDailyEvent({
    int newUsers = 0,
    int visits = 0,
    int orders = 0,
    double revenue = 0,
  }) {
    final now = DateTime.now();
    final label = '${now.month}/${now.day}';
    final index = _dailyMetrics.indexWhere((metric) => metric.day == label);
    if (index == -1) {
      _dailyMetrics.add(
        DailyMetric(
          day: label,
          newUsers: newUsers,
          visits: visits,
          orders: orders,
          revenue: revenue,
        ),
      );
    } else {
      final metric = _dailyMetrics[index];
      _dailyMetrics[index] = DailyMetric(
        day: metric.day,
        newUsers: metric.newUsers + newUsers,
        visits: metric.visits + visits,
        orders: metric.orders + orders,
        revenue: metric.revenue + revenue,
      );
    }
  }

  void _recordActivePageView() {
    final page = _view.name;
    if (_lastTrackedPage == page) {
      return;
    }
    _lastTrackedPage = page;
    trackGoogleAnalyticsPage(page);
    final index = _activeUserSessions.indexWhere(
      (session) => session.id == _visitorSessionId,
    );
    final visitor =
        _currentCustomer?.email ??
        _currentBackendUser?.email ??
        'Guest visitor';
    if (index == -1) {
      _activeUserSessions.add(
        ActiveUserSession(
          id: _visitorSessionId,
          visitor: visitor,
          currentPage: page,
          source: currentTrafficSource(),
          referrer: currentTrafficReferrer(),
          device: currentDeviceLabel(),
          startedAt: _visitorStartedAt,
          lastSeenAt: DateTime.now(),
        ),
      );
    } else {
      _activeUserSessions[index]
        ..visitor = visitor
        ..currentPage = page
        ..lastSeenAt = DateTime.now();
    }
    _recordDailyEvent(visits: 1);
  }

  void _addToCart(Fragrance product, ProductVariant variant) {
    if (variant.stock <= 0) {
      return;
    }

    setState(() {
      final index = _cart.indexWhere(
        (line) =>
            line.product.id == product.id && line.variant?.id == variant.id,
      );
      if (index == -1) {
        _cart.add(CartLine(product: product, variant: variant));
      } else if (_cart[index].quantity < _cart[index].stockAvailable) {
        _cart[index].quantity++;
      }
      _view = StoreView.cart;
    });
  }

  void _buyNow(Fragrance product, ProductVariant variant) {
    if (variant.stock <= 0) {
      return;
    }

    setState(() {
      _cart
        ..clear()
        ..add(CartLine(product: product, variant: variant));
      _view = StoreView.checkout;
    });
  }

  void _openBrand(String brand) {
    setState(() {
      _infoPage = StoreInfoPage.brandProfile;
      _view = StoreView.info;
    });
  }

  void _openProduct(Fragrance product) {
    setState(() {
      _selectedProduct = product;
      _view = StoreView.detail;
    });
  }

  void _openInfoPage(StoreInfoPage page) {
    if (!_siteStatus.isInfoPageVisible(page)) {
      return;
    }
    setState(() {
      _infoPage = page;
      _view = StoreView.info;
    });
  }

  List<Order> get _currentCustomerOrders {
    final customer = _currentCustomer;
    if (customer == null) {
      return [];
    }
    return _orders.where((order) => order.email == customer.email).toList();
  }

  List<Fragrance> get _personalRecommendations {
    final orderedProducts = _currentCustomerOrders
        .expand((order) => order.lines.map((line) => line.product))
        .toList();
    if (orderedProducts.isEmpty) {
      return [];
    }
    final orderedIds = orderedProducts.map((product) => product.id).toSet();
    final likedTerms = orderedProducts
        .expand(
          (product) => [
            product.type,
            product.family,
            product.season,
            product.occasion,
            product.topNotes,
            product.heartNotes,
            product.baseNotes,
            product.notes,
          ],
        )
        .join(' ')
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((term) => term.length > 3)
        .toSet();
    final candidates = _products
        .where(
          (product) => product.isActive && !orderedIds.contains(product.id),
        )
        .toList();
    candidates.sort(
      (a, b) => _recommendationScore(
        b,
        likedTerms,
      ).compareTo(_recommendationScore(a, likedTerms)),
    );
    return candidates.take(6).toList();
  }

  List<String> get _pendingFragranceNotes {
    return const [];
  }

  int _recommendationScore(Fragrance product, Set<String> likedTerms) {
    final haystack =
        '${product.type} ${product.family} ${product.season} ${product.occasion} ${product.description} ${product.vibe} ${product.performance} ${product.comparison} ${product.fragranceProfile} ${product.topNotes} ${product.heartNotes} ${product.baseNotes} ${product.notes}'
            .toLowerCase();
    return likedTerms.where(haystack.contains).length * 10 + product.sold;
  }

  void _openCheckout() {
    if (_cart.isEmpty || _enabledShippingOptions.isEmpty) {
      if (_enabledShippingOptions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipping options are not configured yet.'),
          ),
        );
      }
      return;
    }
    _hydrateCheckoutFields();
    setState(() => _view = StoreView.checkout);
    unawaited(_refreshSelectedShippingRate());
  }

  void _hydrateCheckoutFields() {
    final customer = _currentCustomer;
    if (customer == null) {
      return;
    }
    _checkoutEmail = customer.email;
    _checkoutShippingAddress = ShippingAddress(
      firstName: customer.name.split(' ').first,
      lastName: customer.name.split(' ').skip(1).join(' '),
      addressLine1: customer.addressLine1,
      addressLine2: customer.addressLine2,
      city: customer.city,
      state: customer.state,
      postalCode: customer.postalCode,
      country: customer.country,
      phone: _checkoutPhone,
      email: customer.email,
    );
  }

  Future<void> _refreshSelectedShippingRate() async {
    final customer = _currentCustomer;
    final option = _selectedShippingOption;
    final destinationZip = customer?.postalCode.trim().isNotEmpty == true
        ? customer!.postalCode.trim()
        : _checkoutShippingAddress.postalCode.trim();
    if (_refreshingShippingRate ||
        option.carrier.trim().toUpperCase() != 'USPS' ||
        destinationZip.isEmpty ||
        _storeInfo.postalCode.trim().isEmpty ||
        !(_shippingCredentials['USPS']?.isConfigured ?? false)) {
      return;
    }
    _refreshingShippingRate = true;
    try {
      final package = _packageMetricsForLines(_cart);
      final quotes = await _gateway.quoteShippingRates(
        ShippingRateRequest(
          carrier: 'USPS',
          service: option.service,
          originZip: _storeInfo.postalCode,
          destinationZip: destinationZip,
          weightOz: package['weightOz'] as double,
          lengthIn: package['lengthIn'] as double,
          widthIn: package['widthIn'] as double,
          heightIn: package['heightIn'] as double,
        ),
      );
      if (!mounted || quotes.isEmpty) {
        return;
      }
      final quote = quotes.firstWhere(
        (item) =>
            item.service.trim().toUpperCase() ==
            option.service.trim().toUpperCase(),
        orElse: () => quotes.first,
      );
      setState(() {
        option.price = quote.amount;
        if (quote.estimatedDays.trim().isNotEmpty) {
          option.estimatedDays = quote.estimatedDays;
        }
      });
    } catch (_) {
      // Preserve the last configured storefront rate when USPS quoting fails.
    } finally {
      _refreshingShippingRate = false;
    }
  }

  void _changeQuantity(CartLine line, int delta) {
    setState(() {
      line.quantity += delta;
      if (line.quantity <= 0) {
        _cart.remove(line);
      } else if (line.quantity > line.stockAvailable) {
        line.quantity = line.stockAvailable;
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) {
      return;
    }

    final customer = _currentCustomer;
    final guestName =
        '${_checkoutShippingAddress.firstName} ${_checkoutShippingAddress.lastName}'
            .trim();
    if (guestName.isEmpty || _checkoutEmail.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a shipping name and email before checkout.'),
        ),
      );
      return;
    }
    final customerName = customer?.name ?? guestName;
    final email = customer?.email ?? _checkoutEmail.trim();
    final orderId = 'EA-${1049 + _orders.length}';
    final shippingOption = _selectedShippingOption;
    late final Order order;
    final lines = _cart
        .map(
          (line) => CartLine(
            product: line.product,
            variant: line.variant,
            quantity: line.quantity,
          ),
        )
        .toList();

    setState(() {
      for (final line in _cart) {
        line.product.stock -= line.quantity;
        line.variant?.stock -= line.quantity;
        line.product.sold += line.quantity;
      }
      if (customer != null) {
        customer.orders += 1;
        customer.lifetimeValue += _cartTotal;
        if (customer.referralCredits > 0) {
          customer.referralCredits = math
              .max(0, customer.referralCredits - 5)
              .toDouble();
        }
      }
      order = Order(
        id: orderId,
        customer: customerName,
        email: email,
        total: _cartTotal,
        itemCount: _cartCount,
        status: 'Paid',
        financialStatus: 'Paid',
        fulfillmentStatus: 'Unfulfilled',
        shippingCarrier: shippingOption.carrier,
        shippingService: shippingOption.service,
        shippingPriority: shippingOption.priority,
        shippingTotal: _shipping,
        shippingAddress: customer == null
            ? ShippingAddress(
                firstName: _checkoutShippingAddress.firstName,
                lastName: _checkoutShippingAddress.lastName,
                addressLine1: _checkoutShippingAddress.addressLine1,
                addressLine2: _checkoutShippingAddress.addressLine2,
                city: _checkoutShippingAddress.city,
                state: _checkoutShippingAddress.state,
                postalCode: _checkoutShippingAddress.postalCode,
                country: _checkoutShippingAddress.country,
                phone: _checkoutPhone,
                email: email,
              )
            : ShippingAddress(
                firstName: customerName.split(' ').first,
                lastName: customerName.split(' ').skip(1).join(' '),
                addressLine1: customer.addressLine1,
                addressLine2: customer.addressLine2,
                city: customer.city,
                state: customer.state,
                postalCode: customer.postalCode,
                country: customer.country,
                phone: _checkoutPhone,
                email: email,
              ),
        createdAt: DateTime.now(),
        lines: lines,
      );
      _orders.insert(0, order);
      _lastCompletedOrder = order;
      _recordDailyEvent(orders: 1, revenue: _cartTotal);
      _notifications.insert(
        0,
        StoreNotification(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}',
          type: 'order',
          title: 'New purchase',
          message: '$orderId from $customerName needs fulfillment.',
          createdAt: DateTime.now(),
        ),
      );
      _notifications.insert(
        0,
        StoreNotification(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}-receipt',
          type: 'email',
          title: 'Order confirmation queued',
          message:
              'Order received and paid confirmation queued for $email using the Order received template.',
          createdAt: DateTime.now(),
        ),
      );
      _cart.clear();
      _view = StoreView.paymentSuccess;
    });
    _gateway.upsertOrder(_orderRow(order));
    _gateway.insertOrderItems(_orderItemRows(order));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order $orderId placed and admin notified.')),
    );
  }

  List<Map<String, dynamic>> _orderItemRows(Order order) {
    return [
      for (final line in order.lines)
        {
          'order_id': order.id,
          'product_id': line.product.id,
          'sku': line.sku,
          'product_name': line.product.name,
          'size': line.size,
          'quantity': line.quantity,
          'unit_price': line.unitPrice,
          'line_total': line.total,
          'item_location': line.product.itemLocation,
          'product_photo_url': line.product.primaryPhotoUrl,
        },
    ];
  }

  void _submitCompanySurvey({
    required Order order,
    required int rating,
    required String title,
    required String body,
    required bool anonymous,
    required bool wouldRecommend,
  }) {
    final review = ReviewSummary(
      id: DateTime.now().millisecondsSinceEpoch,
      scope: 'company',
      author: anonymous ? 'Verified customer' : order.customer,
      rating: rating.toDouble(),
      title: title.trim().isEmpty ? 'Verified purchase review' : title.trim(),
      body: body.trim(),
      status: 'pending',
    );
    setState(() {
      _companyReviews.insert(0, review);
      _notifications.insert(
        0,
        StoreNotification(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}',
          type: 'review',
          title: 'Company review awaiting approval',
          message: 'Verified order ${order.id} submitted a company survey.',
          createdAt: DateTime.now(),
        ),
      );
    });
    _gateway.upsertReview(_reviewRow(review));
    _gateway.insertOrderSurvey({
      'id': 'SUR-${DateTime.now().millisecondsSinceEpoch}',
      'order_id': order.id,
      'customer_email': order.email,
      'author': anonymous ? 'Verified customer' : order.customer,
      'rating': rating,
      'title': review.title,
      'body': review.body,
      'would_recommend': wouldRecommend,
      'is_anonymous': anonymous,
      'status': 'pending',
    });
  }

  Future<void> _createAccount(
    String name,
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    CustomerAccount? existing;
    for (final customer in _customers) {
      if (customer.email == cleanEmail) {
        existing = customer;
        break;
      }
    }
    if (existing != null) {
      await _login(cleanEmail, password);
      return;
    }
    final created = CustomerAccount(
      id: 'CUS-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Customer' : name.trim(),
      email: cleanEmail,
      joinedDaysAgo: 0,
      orders: 0,
      lifetimeValue: 0,
      segment: 'New',
      referralCode: cleanEmail.split('@').first.toUpperCase(),
      referralCredits: 0,
      isNew: true,
    );

    CustomerAccount account = created;
    try {
      final saved = await _gateway.createCustomerAccount(
        created.toRow(),
        password,
      );
      if (saved != null) {
        account = CustomerAccount.fromRow(saved);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account creation failed: $error')),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _currentCustomer = account;
      _accountStartsCreating = false;
      if (existing == null) {
        _customers.insert(0, account);
        _recordDailyEvent(newUsers: 1);
      }
      _view = StoreView.account;
    });
  }

  Future<void> _login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    CustomerAccount? match;
    try {
      final row = await _gateway.loginCustomer(cleanEmail, password);
      if (row != null) {
        match = CustomerAccount.fromRow(row);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $error')));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email or password was not recognized.')),
      );
      return;
    }
    setState(() {
      _currentCustomer = match;
      _accountStartsCreating = false;
      _view = StoreView.account;
    });
  }

  Future<void> _loginWithOAuth(String provider) async {
    try {
      await _gateway.loginCustomerWithOAuth(provider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('OAuth login failed: $error')));
      }
    }
  }

  void _logout() {
    setState(() {
      _currentCustomer = null;
      _accountStartsCreating = false;
    });
  }

  Future<void> _loginBackendUser(String email, String password) async {
    setState(() => _adminLoginError = '');
    BackendUser? match;
    try {
      final row = await _gateway.loginBackendUser(
        email.trim().toLowerCase(),
        password,
      );
      if (row != null) {
        match = BackendUser.fromRow(row);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _adminLoginError = 'Admin login failed: $error');
      }
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _currentBackendUser = match;
      if (match == null) {
        _adminLoginError = 'Email or password was not recognized.';
        return;
      }
      _adminPreviewMode = true;
      _view = StoreView.admin;
    });
  }

  void _logoutBackendUser() {
    unawaited(_gateway.logoutBackendUser());
    setState(() {
      _currentBackendUser = null;
      _adminPreviewMode = false;
      _view = StoreView.shop;
    });
  }

  void _toggleFavorite(Fragrance product) {
    setState(() {
      if (_wishlistProductIds.contains(product.id)) {
        _wishlistProductIds.remove(product.id);
      } else {
        _wishlistProductIds.add(product.id);
      }
    });
  }

  void _submitProductReview(
    Fragrance product,
    int rating,
    String title,
    String body,
  ) {
    final customer = _currentCustomer;
    if (customer == null) {
      return;
    }
    if (body.trim().isEmpty && title.trim().isEmpty) {
      return;
    }
    final review = ReviewSummary(
      id: DateTime.now().millisecondsSinceEpoch,
      author: customer.name,
      rating: rating.clamp(1, 5).toDouble(),
      title: title.trim().isEmpty ? 'Customer comment' : title.trim(),
      body: body.trim(),
      scope: 'Fragrance',
      status: 'pending',
      productId: product.id,
      customerEmail: customer.email,
    );
    setState(() {
      _productReviews.insert(0, review);
      _notifications.insert(
        0,
        StoreNotification(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}',
          type: 'review',
          title: 'Review awaiting approval',
          message: '${review.author} commented on ${product.name}.',
          createdAt: DateTime.now(),
        ),
      );
    });
    _gateway.upsertReview(_reviewRow(review));
  }

  Future<void> _upsertProduct(Fragrance product) async {
    try {
      await _gateway.upsertProduct(_productRow(product));
      await _gateway.replaceProductVariants(
        product.id,
        product.variants
            .map((variant) => _variantRow(product.id, variant))
            .toList(),
      );
      await _autoApproveProductNotes(product);
    } catch (error) {
      throw StateError(
        'Could not save product ${product.name.isEmpty ? product.id : product.name}: $error',
      );
    }
    setState(() {
      final index = _products.indexWhere((item) => item.id == product.id);
      if (index == -1) {
        _products.add(product);
      } else {
        _products[index] = product;
      }
    });
  }

  Future<void> _autoApproveProductNotes(Fragrance product) async {
    final approved = _noteGuide
        .map((note) => note.name.trim().toLowerCase())
        .where((note) => note.isNotEmpty)
        .toSet();
    final newNotes = <String>{};
    for (final value in [
      product.notes,
      product.topNotes,
      product.heartNotes,
      product.baseNotes,
    ]) {
      for (final note in value.split(',')) {
        final clean = note.trim();
        if (clean.isNotEmpty && !approved.contains(clean.toLowerCase())) {
          newNotes.add(clean);
        }
      }
    }
    if (newNotes.isEmpty) {
      return;
    }
    setState(() {
      for (final noteName in newNotes) {
        _noteGuide.add(
          FragranceNoteGuide(
            name: noteName,
            tier: 'Custom',
            family: product.family.isEmpty ? 'Fragrance note' : product.family,
            description:
                '$noteName is used in ${product.name} and was added by the store admin.',
            pairings: product.name,
          ),
        );
      }
      _noteGuide.sort((a, b) => a.name.compareTo(b.name));
    });
    for (final noteName in newNotes) {
      await _gateway.upsertFragranceNote({
        'id': noteName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        'name': noteName,
        'note_type': 'Custom',
        'family': product.family.isEmpty ? 'Fragrance note' : product.family,
        'description':
            '$noteName is used in ${product.name} and was added by the store admin.',
        'pairings': product.name,
      });
    }
  }

  Future<List<ProductImage>> _uploadProductImages(
    Fragrance product,
    List<UploadedImageFile> files,
  ) async {
    await _gateway.upsertProduct(_productRow(product));
    final uploaded = <ProductImage>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final url = await _gateway.uploadProductImageBytes(
        productId: product.id,
        fileName: file.name,
        bytes: file.bytes,
        contentType: file.contentType,
        sortOrder: product.images.length + uploaded.length + 1,
        isPrimary: product.images.isEmpty && uploaded.isEmpty,
      );
      uploaded.add(
        ProductImage(
          id: DateTime.now().millisecondsSinceEpoch + i,
          url: url,
          altText: file.name,
          sortOrder: product.images.length + uploaded.length + 1,
          isPrimary: product.images.isEmpty && uploaded.isEmpty,
        ),
      );
    }
    return uploaded;
  }

  Map<String, dynamic> _productRow(Fragrance product) {
    return {
      'id': product.id,
      'category_id': product.categoryId,
      'brand_id': product.brandId,
      'name': product.name,
      'fragrance_type': product.type,
      'brand': product.brand,
      'vendor': product.vendor,
      'item_location': product.itemLocation,
      'sku': product.sku,
      'notes': product.notes,
      'size': product.size,
      'price': product.price,
      'cost': product.cost,
      'stock': product.stock,
      'sold': product.sold,
      'reorder_point': product.reorderPoint,
      'photo_url': product.primaryPhotoUrl,
      'featured_color':
          '#${product.featuredColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'is_active': product.isActive,
      'description': product.description,
      'vibe': product.vibe,
      'performance': product.performance,
      'comparison': product.comparison,
      'fragrance_profile': product.fragranceProfile,
      'ingredients': product.ingredients,
      'top_notes': product.topNotes,
      'heart_notes': product.heartNotes,
      'base_notes': product.baseNotes,
      'concentration': product.concentration,
      'gender': product.gender,
      'season': product.season,
      'occasion': product.occasion,
      'family': product.family,
      'rating': product.rating,
      'review_count': product.reviewCount,
      'weight_oz': product.weightOz,
      'length_in': product.lengthIn,
      'width_in': product.widthIn,
      'height_in': product.heightIn,
    };
  }

  Map<String, dynamic> _variantRow(int productId, ProductVariant variant) {
    return {
      'product_id': productId,
      'size': variant.size,
      'sku': variant.sku,
      'price': variant.price,
      'stock': variant.stock,
      'reorder_point': variant.reorderPoint,
      'is_active': variant.isActive,
    };
  }

  Future<void> _updateOrder(Order order) async {
    setState(() {
      final index = _orders.indexWhere((item) => item.id == order.id);
      if (index != -1) {
        _orders[index] = order;
      }
    });
    try {
      await _gateway.upsertOrder(_orderRow(order));
      _showStatusSnack('Order saved.');
    } catch (error) {
      _showStatusSnack('Order save failed: $error');
    }
  }

  void _updateOrdersWithEmail(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  ) {
    final saves = <Future<void>>[];
    setState(() {
      for (final order in orders) {
        order
          ..fulfillmentStatus = fulfillmentStatus
          ..labelStatus = labelStatus
          ..status = fulfillmentStatus == 'Sent'
              ? 'Shipped'
              : fulfillmentStatus == 'Being picked'
              ? 'Picking'
              : order.status;
        _notifications.insert(
          0,
          StoreNotification(
            id: 'N-${DateTime.now().millisecondsSinceEpoch}-${order.id}',
            type: 'email',
            title: 'Order update email queued',
            message:
                '${order.id} ${fulfillmentStatus.toLowerCase()} notice queued for ${order.email}.',
            createdAt: DateTime.now(),
          ),
        );
        saves.add(_gateway.upsertOrder(_orderRow(order)));
      }
    });
    unawaited(
      Future.wait(saves)
          .then(
            (_) => _showStatusSnack(
              '${orders.length} order status update(s) saved.',
            ),
          )
          .catchError(
            (Object error) =>
                _showStatusSnack('Order status update failed: $error'),
          ),
    );
  }

  Map<String, dynamic> _orderRow(Order order) {
    return {
      'order_number': order.id,
      'customer_name': order.customer,
      'email': order.email,
      'status': order.status,
      'financial_status': order.financialStatus,
      'fulfillment_status': order.fulfillmentStatus,
      'shipping_total': order.shippingTotal,
      'grand_total': order.total,
      'item_count': order.itemCount,
      'shipping_carrier': order.shippingCarrier,
      'shipping_service': order.shippingService,
      'shipping_priority': order.shippingPriority,
      'tracking_number': order.trackingNumber,
      'label_status': order.labelStatus,
      'shipping_address': order.shippingAddress.toJson(),
    };
  }

  Map<String, dynamic> _packageRowForOrder(Order order) {
    return _packageMetricsForLines(order.lines);
  }

  Map<String, dynamic> _packageMetricsForLines(List<CartLine> lines) {
    if (lines.isEmpty) {
      return {
        'weightOz': 8.0,
        'lengthIn': 6.0,
        'widthIn': 3.0,
        'heightIn': 3.0,
      };
    }
    var weightOz = 0.0;
    var maxLength = 0.0;
    var maxWidth = 0.0;
    var totalHeight = 0.0;
    for (final line in lines) {
      final quantity = line.quantity;
      weightOz += line.product.weightOz * quantity;
      maxLength = math.max(maxLength, line.product.lengthIn);
      maxWidth = math.max(maxWidth, line.product.widthIn);
      totalHeight += math.max(0.5, line.product.heightIn) * quantity;
    }
    return {
      'weightOz': weightOz <= 0 ? 8.0 : weightOz,
      'lengthIn': maxLength <= 0 ? 6.0 : maxLength,
      'widthIn': maxWidth <= 0 ? 3.0 : maxWidth,
      'heightIn': totalHeight <= 0 ? 3.0 : totalHeight,
    };
  }

  Future<ShippingLabelResult> _createShippingLabel(Order order) async {
    final result = await _gateway.createUspsLabel(
      order: _orderRow(order),
      storeInfo: _storeInfo.toRow(),
      package: _packageRowForOrder(order),
    );
    downloadBase64File(
      fileName: result.labelFileName,
      base64Contents: result.labelBase64,
      mimeType: result.labelContentType,
    );
    setState(() {
      order
        ..trackingNumber = result.trackingNumber
        ..labelStatus = result.labelStatus
        ..fulfillmentStatus = 'Label created'
        ..status = 'Label created'
        ..shippingCarrier = 'USPS';
      if (result.postage > 0) {
        order.shippingTotal = result.postage;
      }
      if (result.estimatedDays.trim().isNotEmpty) {
        _notifications.insert(
          0,
          StoreNotification(
            id: 'N-${DateTime.now().millisecondsSinceEpoch}-${order.id}-label',
            type: 'shipping',
            title: 'USPS label created',
            message:
                '${order.id} label created for ${result.trackingNumber} (${result.estimatedDays}).',
            createdAt: DateTime.now(),
          ),
        );
      }
    });
    await _gateway.upsertOrder(_orderRow(order));
    return result;
  }

  Map<String, dynamic> _reviewRow(ReviewSummary review) {
    return {
      'id': '${review.id}',
      'scope': review.scope,
      'product_id': review.productId,
      'customer_email': review.customerEmail,
      'author': review.author,
      'rating': review.rating,
      'title': review.title,
      'body': review.body,
      'status': review.status,
    };
  }

  Map<String, dynamic> _couponRow(CouponRule coupon) {
    final code = coupon.code.trim().toUpperCase();
    return {
      'code': code,
      'name': coupon.name,
      'discount_type': coupon.type,
      'value': coupon.value,
      'minimum_spend': coupon.minimumSpend,
      'usage_limit': coupon.usageLimit,
      'used': coupon.used,
      'starts_on': coupon.starts,
      'ends_on': coupon.ends,
      'is_active': coupon.isActive,
      'is_archived': coupon.isArchived,
    };
  }

  Map<String, dynamic> _paymentMethodRow(PaymentMethodConfig method) {
    return {
      'name': method.name,
      'provider': method.provider,
      'status': method.status,
      'fee': method.fee,
      'settlement': method.settlement,
      'is_enabled': method.isEnabled,
      'mode': method.mode,
      'public_key': method.publicKey,
      'merchant_id': method.merchantId,
      'api_secret': method.apiSecret,
      'webhook_url': method.webhookUrl,
      'statement_descriptor': method.statementDescriptor,
    };
  }

  Future<void> _updateReview(ReviewSummary review, String status) async {
    final previousStatus = review.status;
    final isDeleteAction = status == 'rejected';
    setState(() {
      review.status = status;
      _notifications.insert(
        0,
        StoreNotification(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}',
          type: 'review',
          title: 'Review $status',
          message: '${review.author} review marked $status.',
          createdAt: DateTime.now(),
        ),
      );
    });
    try {
      await _gateway.updateReviewStatus('${review.id}', status);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDeleteAction ? 'Review deleted.' : 'Review approved.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        review.status = previousStatus;
        _notifications.insert(
          0,
          StoreNotification(
            id: 'N-${DateTime.now().millisecondsSinceEpoch}',
            type: 'review',
            title: 'Review update failed',
            message: '$error',
            createdAt: DateTime.now(),
          ),
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Review update failed: $error')));
    }
  }

  void _sendCustomerEmail(String audience, String subject, String body) {
    setState(() {
      _notifications.insert(
        0,
        StoreNotification(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}',
          type: 'email',
          title: 'Email queued',
          message: '$subject queued for $audience.',
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _updateEmailSettings(EmailServerSettings settings) async {
    setState(() {
      _emailSettings
        ..fromName = settings.fromName
        ..fromEmail = settings.fromEmail
        ..imapHost = settings.imapHost
        ..imapPort = settings.imapPort
        ..smtpHost = settings.smtpHost
        ..smtpPort = settings.smtpPort
        ..username = settings.username
        ..useSsl = settings.useSsl;
    });
    try {
      await _gateway.upsertEmailServerSettings(_emailSettings.toJson());
      _showStatusSnack('Email settings saved.');
    } catch (error) {
      _showStatusSnack('Email settings save failed: $error');
    }
  }

  Future<void> _saveShippingCredentials(
    String carrier,
    ShippingCarrierCredentials credentials,
  ) async {
    setState(() {
      _shippingCredentials[carrier] = credentials;
    });
    try {
      await _gateway.upsertShippingCarrierCredentialsForCarrier(
        carrier,
        credentials.toJson(),
      );
      _showStatusSnack('$carrier credentials saved.');
    } catch (error) {
      _showStatusSnack('$carrier credentials save failed: $error');
    }
  }

  Future<void> _updateSiteStatus(SiteStatus status) async {
    final previous = SiteStatus(
      isLive: _siteStatus.isLive,
      measurementSystem: _siteStatus.measurementSystem,
      message: _siteStatus.message,
      showNoteEncyclopedia: _siteStatus.showNoteEncyclopedia,
      showIngredientProfiles: _siteStatus.showIngredientProfiles,
      showBrandProfile: _siteStatus.showBrandProfile,
      showRecommendations: _siteStatus.showRecommendations,
      showLatestFragranceNews: _siteStatus.showLatestFragranceNews,
      showCommunity: _siteStatus.showCommunity,
      showCompanyReviews: _siteStatus.showCompanyReviews,
      homeShelfMode: _siteStatus.homeShelfMode,
      featuredProductIds: List.of(_siteStatus.featuredProductIds),
      returnPolicy: _siteStatus.returnPolicy,
      googleAnalyticsMeasurementId: _siteStatus.googleAnalyticsMeasurementId,
    );
    setState(() {
      _siteStatus
        ..isLive = status.isLive
        ..measurementSystem = status.measurementSystem
        ..message = status.message
        ..showNoteEncyclopedia = status.showNoteEncyclopedia
        ..showIngredientProfiles = status.showIngredientProfiles
        ..showBrandProfile = status.showBrandProfile
        ..showRecommendations = status.showRecommendations
        ..showLatestFragranceNews = status.showLatestFragranceNews
        ..showCommunity = status.showCommunity
        ..showCompanyReviews = status.showCompanyReviews
        ..homeShelfMode = status.homeShelfMode
        ..featuredProductIds = List.of(status.featuredProductIds)
        ..returnPolicy = status.returnPolicy
        ..googleAnalyticsMeasurementId = status.googleAnalyticsMeasurementId;
    });
    try {
      await _gateway.upsertSiteStatus(_siteStatus.toJson());
      configureGoogleAnalytics(_siteStatus.googleAnalyticsMeasurementId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _siteStatus
            ..isLive = previous.isLive
            ..measurementSystem = previous.measurementSystem
            ..message = previous.message
            ..showNoteEncyclopedia = previous.showNoteEncyclopedia
            ..showIngredientProfiles = previous.showIngredientProfiles
            ..showBrandProfile = previous.showBrandProfile
            ..showRecommendations = previous.showRecommendations
            ..showLatestFragranceNews = previous.showLatestFragranceNews
            ..showCommunity = previous.showCommunity
            ..showCompanyReviews = previous.showCompanyReviews
            ..homeShelfMode = previous.homeShelfMode
            ..featuredProductIds = List.of(previous.featuredProductIds)
            ..returnPolicy = previous.returnPolicy
            ..googleAnalyticsMeasurementId =
                previous.googleAnalyticsMeasurementId;
        });
      }
      rethrow;
    }
  }

  Future<void> _upsertBackendUser(BackendUser user) async {
    setState(() {
      final index = _backendUsers.indexWhere((item) => item.id == user.id);
      if (index == -1) {
        _backendUsers.add(user);
      } else {
        _backendUsers[index] = user;
      }
    });
    try {
      await _gateway.upsertBackendUser({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'is_active': user.isActive,
        'is_blocked': user.isBlocked,
        'created_ip': user.createdIp,
        'last_login_ip': user.lastLoginIp,
        'blocked_reason': user.blockedReason,
      });
      _showStatusSnack('Backend user saved.');
    } catch (error) {
      _showStatusSnack('Backend user save failed: $error');
    }
  }

  Future<void> _upsertCustomer(CustomerAccount customer) async {
    setState(() {
      final index = _customers.indexWhere((item) => item.id == customer.id);
      if (index == -1) {
        _customers.add(customer);
      } else {
        _customers[index] = customer;
      }
    });
    try {
      await _gateway.upsertCustomer(customer.toRow());
      _showStatusSnack('Customer saved.');
    } catch (error) {
      _showStatusSnack('Customer save failed: $error');
    }
  }

  Future<void> _blockIpAddress(String ipAddress) async {
    final clean = ipAddress.trim();
    if (clean.isEmpty) {
      return;
    }
    try {
      await _gateway.upsertBlockedIp({
        'ip_address': clean,
        'reason': 'Blocked from admin account tools',
        'is_active': true,
      });
      _showStatusSnack('Blocked IP address $clean.');
    } catch (error) {
      _showStatusSnack('IP block save failed: $error');
    }
  }

  Widget _storefrontGate(Widget child) {
    if (_siteStatus.isLive) {
      return child;
    }
    if (_adminPreviewMode) {
      return Stack(
        children: [
          child,
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              color: const Color(0xFF172026),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Admin preview: storefront is currently in maintenance mode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return MaintenanceView(
      message: _siteStatus.message,
      onAdminAccess: () => setState(() {
        _view = StoreView.admin;
      }),
    );
  }

  Future<void> _removeProduct(Fragrance product) async {
    final wasActive = product.isActive;
    setState(() {
      product.isActive = false;
      _cart.removeWhere((line) => line.product.id == product.id);
    });
    try {
      await _gateway.deleteProduct(product.id);
      _showStatusSnack('Fragrance deleted.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => product.isActive = wasActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fragrance delete failed: $error')),
      );
    }
  }

  Future<void> _approveFragranceNote(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return;
    }
    final exists = _noteGuide.any(
      (note) => note.name.toLowerCase() == clean.toLowerCase(),
    );
    if (!exists) {
      final note = FragranceNoteGuide(
        name: clean,
        tier: 'Custom',
        family: 'Pending family',
        description: 'Approved from a product-specific fragrance note.',
        pairings: '',
      );
      setState(() => _noteGuide.add(note));
    }
    try {
      await _gateway.upsertFragranceNote({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': clean,
        'note_type': 'Custom',
        'family': 'Pending family',
        'description': 'Approved from a product-specific fragrance note.',
      });
      _showStatusSnack('Fragrance note approved.');
    } catch (error) {
      _showStatusSnack('Fragrance note approval failed: $error');
    }
  }

  Future<void> _upsertCategory(Category category) async {
    final existingIndex = _categories.indexWhere(
      (item) => item.id == category.id,
    );
    final saved = await _gateway.upsertCategory({
      if (existingIndex != -1) 'id': category.id,
      'name': category.name,
      'description': category.description,
      'sort_order': category.sortOrder,
      'is_visible': category.isVisible,
    });
    final categoryToStore = saved == null ? category : Category.fromRow(saved);
    setState(() {
      final index = _categories.indexWhere(
        (item) => item.id == categoryToStore.id,
      );
      if (index == -1) {
        _categories.add(categoryToStore);
      } else {
        _categories[index] = categoryToStore;
      }
      _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
  }

  Future<void> _removeCategory(Category category) async {
    setState(() {
      category.isVisible = false;
      if (_filter == category.name) {
        _filter = 'All';
      }
    });
    try {
      await _gateway.upsertCategory({
        'id': category.id,
        'name': category.name,
        'description': category.description,
        'sort_order': category.sortOrder,
        'is_visible': category.isVisible,
      });
      _showStatusSnack('Category hidden.');
    } catch (error) {
      _showStatusSnack('Category update failed: $error');
    }
  }

  Future<void> _upsertCoupon(CouponRule coupon) async {
    final saved = await _gateway.upsertCouponRule(_couponRow(coupon));
    if (saved == null) {
      throw StateError('Promotion save did not return the saved database row.');
    }
    final savedCoupon = CouponRule.fromRow(saved);
    if (savedCoupon.isActive != coupon.isActive ||
        savedCoupon.isArchived != coupon.isArchived) {
      throw StateError(
        'Promotion save did not persist the requested active/archive status.',
      );
    }
    setState(() {
      final index = _coupons.indexWhere(
        (item) => item.code == savedCoupon.code,
      );
      if (index == -1) {
        _coupons.add(savedCoupon);
      } else {
        _coupons[index] = savedCoupon;
      }
    });
  }

  Future<void> _togglePayment(PaymentMethodConfig method) async {
    setState(() => method.isEnabled = !method.isEnabled);
    try {
      await _gateway.upsertPaymentMethod(_paymentMethodRow(method));
      _showStatusSnack(
        '${method.name} ${method.isEnabled ? 'enabled' : 'disabled'}.',
      );
    } catch (error) {
      _showStatusSnack('Payment method update failed: $error');
    }
  }

  Future<void> _savePayment(PaymentMethodConfig method) async {
    setState(() {
      final index = _paymentMethods.indexWhere(
        (item) => item.provider == method.provider && item.name == method.name,
      );
      if (index == -1) {
        _paymentMethods.add(method);
      } else {
        _paymentMethods[index] = method;
      }
    });
    try {
      await _gateway.upsertPaymentMethod(_paymentMethodRow(method));
      await _gateway.upsertPaymentProcessorCredentials(method.provider, {
        'publicKey': method.publicKey,
        'merchantId': method.merchantId,
        'apiSecret': method.apiSecret,
        'webhookUrl': method.webhookUrl,
      });
      _showStatusSnack('Payment method saved.');
    } catch (error) {
      _showStatusSnack('Payment method save failed: $error');
    }
  }

  Future<void> _saveShippingOption(ShippingOption option) async {
    setState(() {
      final index = _shippingOptions.indexWhere((item) => item.id == option.id);
      if (index == -1) {
        _shippingOptions.add(option);
      } else {
        _shippingOptions[index] = option;
      }
      _shippingOptions.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final active = _enabledShippingOptions;
      if (active.isNotEmpty &&
          !active.any((item) => item.id == _selectedShippingOptionId)) {
        _selectedShippingOptionId = active.first.id;
      }
    });
    try {
      await _gateway.upsertShippingOption(option.toRow());
      _showStatusSnack('Shipping option saved.');
    } catch (error) {
      _showStatusSnack('Shipping option save failed: $error');
    }
  }

  Future<void> _deleteShippingOption(ShippingOption option) async {
    setState(() {
      _shippingOptions.removeWhere((item) => item.id == option.id);
      final active = _enabledShippingOptions;
      if (_selectedShippingOptionId == option.id && active.isNotEmpty) {
        _selectedShippingOptionId = active.first.id;
      }
    });
    try {
      await _gateway.deleteShippingOption(option.id);
      _showStatusSnack('Shipping option deleted.');
    } catch (error) {
      _showStatusSnack('Shipping option delete failed: $error');
    }
  }

  Future<void> _saveStoreInfo(StoreInfo info) async {
    setState(() => _storeInfo = info);
    await _gateway.upsertStoreInfo(info.toRow());
  }

  Future<String> _uploadStoreAsset(UploadedImageFile file) {
    return _gateway.uploadSiteAssetBytes(
      fileName: file.name,
      bytes: file.bytes,
      contentType: file.contentType,
    );
  }

  Future<void> _saveTaxRule(TaxRule rule) async {
    setState(() {
      final index = _taxRules.indexWhere((item) => item.id == rule.id);
      if (index == -1) {
        _taxRules.add(rule);
      } else {
        _taxRules[index] = rule;
      }
      _taxRules.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
    await _gateway.upsertTaxRule(rule.toRow());
  }

  Future<void> _deleteTaxRule(TaxRule rule) async {
    setState(() {
      _taxRules.removeWhere((item) => item.id == rule.id);
    });
    await _gateway.deleteTaxRule(rule.id);
  }

  Future<void> _upsertContent(ContentBlock block) async {
    setState(() {
      final index = _contentBlocks.indexWhere((item) => item.id == block.id);
      if (index == -1) {
        _contentBlocks.add(block);
      } else {
        _contentBlocks[index] = block;
      }
      _contentBlocks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
    try {
      await _gateway.upsertContentBlock({
        'id': block.id,
        'title': block.title,
        'placement': block.placement,
        'body': block.body,
        'sort_order': block.sortOrder,
        'is_visible': block.isVisible,
      });
      _showStatusSnack('Content block saved.');
    } catch (error) {
      _showStatusSnack('Content block save failed: $error');
    }
  }

  void _sendContactMessage(
    String name,
    String email,
    String subject,
    String message,
  ) {
    final notification = StoreNotification(
      id: 'N-contact-${DateTime.now().millisecondsSinceEpoch}',
      type: 'contact',
      title: subject.trim().isEmpty ? 'Customer message' : subject.trim(),
      message: '$name <$email>\n$message',
      createdAt: DateTime.now(),
    );
    setState(() => _notifications.insert(0, notification));
    _gateway.insertNotification(notification.toRow());
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBrowserRouteSync();
    _recordActivePageView();
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          _NavButton(
            label: 'Home',
            icon: Icons.home_outlined,
            selected: _view == StoreView.shop,
            onPressed: () => setState(() => _view = StoreView.shop),
          ),
          _NavButton(
            label: 'Shop',
            icon: Icons.storefront,
            selected: _view == StoreView.catalog || _view == StoreView.detail,
            onPressed: () => _openCatalog(query: '', filter: 'All'),
          ),
          _NavButton(
            label: 'Cart',
            icon: Icons.shopping_bag_outlined,
            selected: _view == StoreView.cart || _view == StoreView.checkout,
            badge: _cartCount,
            onPressed: () => setState(() => _view = StoreView.cart),
          ),
          _NavButton(
            label: 'Contact',
            icon: Icons.support_agent_outlined,
            selected:
                _view == StoreView.info && _infoPage == StoreInfoPage.contact,
            onPressed: () => _openInfoPage(StoreInfoPage.contact),
          ),
          _AccountMenuButton(
            customer: _currentCustomer,
            selected: _view == StoreView.account,
            onOpenAccount: () => setState(() {
              _accountStartsCreating = false;
              _view = StoreView.account;
            }),
            onCreateAccount: () => setState(() {
              _accountStartsCreating = true;
              _view = StoreView.account;
            }),
            onOpenAdminSignIn: () => setState(() => _view = StoreView.admin),
            showAdminSignIn: _currentBackendUser == null,
            onLogout: _logout,
          ),
          if (_currentBackendUser != null)
            _NavButton(
              label: 'Admin',
              icon: Icons.dashboard_customize_outlined,
              selected: _view == StoreView.admin,
              onPressed: () => setState(() => _view = StoreView.admin),
            ),
          if (_currentBackendUser != null)
            TextButton.icon(
              onPressed: _logoutBackendUser,
              icon: const Icon(Icons.logout),
              label: const Text('Admin logout'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: _activeView()),
    );
  }

  Widget _activeView() {
    return switch (_view) {
      StoreView.shop => _storefrontGate(
        ShopView(
          products: _homeProducts,
          shelfTitle: _homeShelfTitle,
          categories: _categories
              .where((category) => category.isVisible)
              .toList(),
          contentBlocks: _contentBlocks
              .where((block) => block.isVisible)
              .toList(),
          query: _query,
          onSearch: (value) => _openCatalog(query: value),
          onOpenCatalog: () => _openCatalog(),
          onOpenCategory: (category) => _openCatalog(filter: category.name),
          onViewDetails: _openProduct,
          onOpenInfoPage: _openInfoPage,
          newsItems: _newsItems,
          siteStatus: _siteStatus,
          companyReviews: _companyReviews
              .where((review) => review.status == 'approved')
              .toList(),
        ),
      ),
      StoreView.catalog => _storefrontGate(
        CatalogView(
          products: _visibleProducts,
          categories: _categories
              .where((category) => category.isVisible)
              .toList(),
          filter: _filter,
          query: _query,
          sort: _sort,
          onFilterChanged: (value) => setState(() => _filter = value),
          onQueryChanged: (value) => setState(() => _query = value),
          onSortChanged: (value) => setState(() => _sort = value),
          onBack: () => setState(() => _view = StoreView.shop),
          onViewDetails: _openProduct,
        ),
      ),
      StoreView.detail => _storefrontGate(
        FragranceDetailView(
          product: _selectedProduct,
          onBack: () => _openCatalog(query: '', filter: 'All'),
          onAddToCart: _addToCart,
          onBuyNow: _buyNow,
          onBrandSelected: _openBrand,
          paymentMethods: _paymentMethods
              .where((method) => method.isEnabled)
              .toList(),
          shippingOptions: _enabledShippingOptions,
          returnPolicy: _siteStatus.returnPolicy,
          measurementSystem: _siteStatus.measurementSystem,
          reviews: _productReviews.where((review) {
            final isSelectedProduct = review.productId == _selectedProduct?.id;
            final isApproved = review.status == 'approved';
            final isOwnPending =
                _currentCustomer != null &&
                review.customerEmail.toLowerCase() ==
                    _currentCustomer!.email.toLowerCase();
            return isSelectedProduct && (isApproved || isOwnPending);
          }).toList(),
          canSubmitReview: _currentCustomer != null,
          isFavorite: _selectedProduct == null
              ? false
              : _wishlistProductIds.contains(_selectedProduct!.id),
          onToggleFavorite: _toggleFavorite,
          onSubmitReview: _submitProductReview,
        ),
      ),
      StoreView.cart => _storefrontGate(
        CartView(
          lines: _cart,
          subtotal: _cartSubtotal,
          tax: _tax,
          shipping: _shipping,
          total: _cartTotal,
          onQuantityChanged: _changeQuantity,
          onCheckout: _openCheckout,
        ),
      ),
      StoreView.checkout => _storefrontGate(
        CheckoutView(
          lines: _cart,
          subtotal: _cartSubtotal,
          tax: _tax,
          shipping: _shipping,
          total: _cartTotal,
          checkoutEmail: _checkoutEmail,
          checkoutPhone: _checkoutPhone,
          shippingAddress: _checkoutShippingAddress,
          onCheckoutEmailChanged: (value) =>
              setState(() => _checkoutEmail = value),
          onCheckoutPhoneChanged: (value) =>
              setState(() => _checkoutPhone = value),
          onShippingAddressChanged: (value) {
            setState(() => _checkoutShippingAddress = value);
            unawaited(_refreshSelectedShippingRate());
          },
          shippingOptions: _enabledShippingOptions,
          selectedShippingOptionId: _selectedShippingOptionId,
          onShippingOptionChanged: (value) {
            setState(() => _selectedShippingOptionId = value);
            unawaited(_refreshSelectedShippingRate());
          },
          onBackToCart: () => setState(() => _view = StoreView.cart),
          onPlaceOrder: _checkout,
          paymentMethods: _paymentMethods
              .where((method) => method.isEnabled)
              .toList(),
        ),
      ),
      StoreView.account => _storefrontGate(
        AccountView(
          customer: _currentCustomer,
          orders: _orders
              .where((order) => order.email == _currentCustomer?.email)
              .toList(),
          storeInfo: _storeInfo,
          wishlistProducts: _products
              .where((product) => _wishlistProductIds.contains(product.id))
              .toList(),
          initialCreating: _accountStartsCreating,
          onCreateAccount: _createAccount,
          onLogin: _login,
          onOAuthLogin: _loginWithOAuth,
          onLogout: _logout,
        ),
      ),
      StoreView.info => _storefrontGate(
        InfoView(
          page: _infoPage,
          notes: _noteGuide,
          ingredients: _ingredientGuide,
          brand: _egbeAnomProfile,
          customer: _currentCustomer,
          orders: _currentCustomerOrders,
          recommendations: _personalRecommendations,
          onBack: () => setState(() => _view = StoreView.shop),
          onOpenProduct: _openProduct,
          onOpenAccount: () => setState(() => _view = StoreView.account),
          onSendContactMessage: _sendContactMessage,
        ),
      ),
      StoreView.admin =>
        _currentBackendUser == null
            ? AdminLoginView(
                error: _adminLoginError,
                onLogin: _loginBackendUser,
              )
            : AdminView(
                products: _products
                    .where((product) => product.isActive)
                    .toList(),
                categories: _categories,
                orders: _orders,
                activeCarts: [
                  if (_cart.isNotEmpty)
                    ActiveCart(
                      id: 'LIVE-SESSION',
                      customer: 'Current shopper',
                      minutesAgo: 0,
                      lines: _cart,
                    ),
                  ..._marketplaceCarts,
                ],
                customers: _customers,
                dailyMetrics: _dailyMetrics,
                coupons: _coupons,
                paymentMethods: _paymentMethods,
                shippingOptions: _shippingOptions,
                shippingCredentials: _shippingCredentials,
                noteOptions: _noteGuide.map((note) => note.name).toList(),
                pendingNoteOptions: _pendingFragranceNotes,
                familyOptions: _familyOptions,
                seasonOptions: _seasonOptions,
                occasionOptions: _occasionOptions,
                contentBlocks: _contentBlocks,
                reviews: [..._productReviews, ..._companyReviews],
                notifications: _notifications,
                siteStatus: _siteStatus,
                storeInfo: _storeInfo,
                taxRules: _taxRules,
                measurementSystem: _siteStatus.measurementSystem,
                backendUsers: _backendUsers,
                activeUserSessions: _activeUserSessions,
                emailSettings: _emailSettings,
                onSave: _upsertProduct,
                onRemove: _removeProduct,
                onUploadImages: _uploadProductImages,
                onSaveCategory: _upsertCategory,
                onRemoveCategory: _removeCategory,
                onSaveCoupon: _upsertCoupon,
                onTogglePayment: _togglePayment,
                onSavePayment: _savePayment,
                onSaveShippingOption: _saveShippingOption,
                onDeleteShippingOption: _deleteShippingOption,
                onSaveShippingCredentials: _saveShippingCredentials,
                onSaveStoreInfo: _saveStoreInfo,
                onUploadStoreAsset: _uploadStoreAsset,
                onSaveTaxRule: _saveTaxRule,
                onDeleteTaxRule: _deleteTaxRule,
                onSaveContent: _upsertContent,
                onUpdateOrder: _updateOrder,
                onCreateShippingLabel: _createShippingLabel,
                onBatchUpdateOrders: _updateOrdersWithEmail,
                onUpdateReview: _updateReview,
                onSendEmail: _sendCustomerEmail,
                onSaveEmailSettings: _updateEmailSettings,
                onUpdateSiteStatus: _updateSiteStatus,
                onSaveCustomer: _upsertCustomer,
                onBlockIp: _blockIpAddress,
                onSaveBackendUser: _upsertBackendUser,
                onApproveFragranceNote: _approveFragranceNote,
              ),
      StoreView.paymentSuccess => _storefrontGate(
        PaymentReturnView(
          isSuccess: true,
          onContinueShopping: () => setState(() => _view = StoreView.shop),
          onViewAccount: () => setState(() => _view = StoreView.account),
          completedOrder: _lastCompletedOrder,
          onSubmitSurvey: _submitCompanySurvey,
        ),
      ),
      StoreView.paymentFailure => _storefrontGate(
        PaymentReturnView(
          isSuccess: false,
          onContinueShopping: () => setState(() => _view = StoreView.shop),
          onViewCart: () => setState(() => _view = StoreView.cart),
        ),
      ),
    };
  }
}
