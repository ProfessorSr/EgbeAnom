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
  Timer? _adminNotificationPollTimer;
  bool _pollingAdminAttention = false;
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
  final List<AnalyticsEvent> _analyticsEvents = [];
  AdminSection _adminInitialSection = AdminSection.overview;

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
  String _promoCode = '';
  CouponRule? _appliedCoupon;
  String _promoMessage = '';
  String _selectedCheckoutPaymentProvider = '';
  bool _placingOrder = false;
  bool _creatingCheckoutAccount = false;
  bool _processingPaymentReturn = false;
  String _pendingPaymentOrderId = '';

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
  final List<MailingListSubscriber> _mailingListSubscribers = [];
  final List<EmailMessage> _emailMessages = [];
  final List<StoreNotification> _notifications = [];
  bool _adminPreviewMode = false;
  bool _refreshingShippingRate = false;

  final List<ActiveCart> _marketplaceCarts = [];

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
    _adminNotificationPollTimer?.cancel();
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
    unawaited(_handlePaymentReturnRoute(route, view));
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
        customer = await _captureCustomerAccessMetadata(customer);
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
    if (backendUser != null) {
      _startAdminAttentionPolling();
    }
    if (customer != null) {
      await _loadWishlistForCustomer(customer);
    }
  }

  Future<void> _loadStoreData() async {
    Future<T> fallback<T>(Future<T> Function() load, T value) async {
      try {
        return await load();
      } catch (error, stackTrace) {
        debugPrint(
          'Store data load failed for ${T.toString()}: $error\n$stackTrace',
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
    final paymentProcessorCredentials = <String, Map<String, dynamic>>{};
    for (final row in paymentMethods) {
      final provider = '${row['provider'] ?? ''}'.trim().toLowerCase();
      if (provider.isEmpty ||
          paymentProcessorCredentials.containsKey(provider)) {
        continue;
      }
      final credential = await fallback<Map<String, dynamic>?>(
        () => _gateway.fetchPaymentProcessorCredentials(provider),
        null,
      );
      if (credential != null && credential['value'] is Map) {
        paymentProcessorCredentials[provider] = (credential['value'] as Map)
            .cast<String, dynamic>();
      }
    }
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
    final mailingListSubscribers = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchMailingListSubscribers,
      [],
    );
    final emailMessages = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchEmailMessages,
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
    final dailyMetrics = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchDailyMetrics,
      [],
    );
    final activeUserSessions = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchActiveUserSessions,
      [],
    );
    final analyticsEvents = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchAnalyticsEvents,
      [],
    );
    final activeCarts = await fallback<List<Map<String, dynamic>>>(
      _gateway.fetchActiveCarts,
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
                .map((row) {
                  final method = PaymentMethodConfig.fromRow(row);
                  final credential =
                      paymentProcessorCredentials[method.provider
                          .toLowerCase()];
                  if (credential != null) {
                    method.checkoutUrl =
                        _firstNonEmptyString([
                          credential['checkoutUrl'],
                          credential['checkout_url'],
                          method.checkoutUrl,
                          method.webhookUrl,
                        ]) ??
                        '';
                    method.webhookUrl =
                        _firstNonEmptyString([
                          credential['webhookUrl'],
                          credential['webhook_url'],
                          method.webhookUrl,
                        ]) ??
                        '';
                  }
                  return method;
                })
                .where(
                  (method) => allowedPaymentProviders.contains(
                    method.provider.toLowerCase(),
                  ),
                ),
          );
        final enabled = _paymentMethods.where((method) => method.isEnabled);
        if (enabled.isNotEmpty &&
            !enabled.any(
              (method) => method.provider == _selectedCheckoutPaymentProvider,
            )) {
          _selectedCheckoutPaymentProvider = enabled.first.provider;
        }
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
      if (mailingListSubscribers.isNotEmpty) {
        _mailingListSubscribers
          ..clear()
          ..addAll(mailingListSubscribers.map(MailingListSubscriber.fromRow));
      }
      if (emailMessages.isNotEmpty) {
        _emailMessages
          ..clear()
          ..addAll(emailMessages.map(EmailMessage.fromRow));
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
      if (dailyMetrics.isNotEmpty) {
        _dailyMetrics
          ..clear()
          ..addAll(dailyMetrics.map(DailyMetric.fromRow));
      }
      if (activeUserSessions.isNotEmpty) {
        _activeUserSessions
          ..clear()
          ..addAll(activeUserSessions.map(ActiveUserSession.fromRow));
      }
      if (analyticsEvents.isNotEmpty) {
        _analyticsEvents
          ..clear()
          ..addAll(analyticsEvents.map(AnalyticsEvent.fromRow));
      }
      _marketplaceCarts
        ..clear()
        ..addAll(
          activeCarts
              .where(
                (row) =>
                    '${row['status'] ?? 'active'}'.toLowerCase() != 'recovered',
              )
              .map(_activeCartFromRow),
        );
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
          ..showMailingListSignup = status.showMailingListSignup
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
          ..provider = settings.provider
          ..fromName = settings.fromName
          ..fromEmail = settings.fromEmail
          ..imapHost = settings.imapHost
          ..imapPort = settings.imapPort
          ..smtpHost = settings.smtpHost
          ..smtpPort = settings.smtpPort
          ..username = settings.username
          ..password = settings.password
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
    final route = currentBrowserRoute();
    final returnView = _viewForBrowserRoute(route);
    if (returnView == StoreView.paymentSuccess ||
        returnView == StoreView.paymentFailure) {
      unawaited(_handlePaymentReturnRoute(route, returnView!));
    }
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

  String? _firstNonEmptyString(List<Object?> values) {
    for (final value in values) {
      final text = '${value ?? ''}'.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
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
      final tokens = _searchTokens(_query);
      final scored =
          active
              .map(
                (product) =>
                    MapEntry(product, _productSearchScore(product, tokens)),
              )
              .where((entry) => entry.value > 0)
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      active = scored.map((entry) => entry.key).toList();
    }
    if (_query.trim().isEmpty || _sort != 'Featured') {
      active.sort((a, b) {
        return switch (_sort) {
          'Price low' => a.price.compareTo(b.price),
          'Price high' => b.price.compareTo(a.price),
          'Best sellers' => b.sold.compareTo(a.sold),
          _ => a.id.compareTo(b.id),
        };
      });
    }
    return active;
  }

  List<String> _searchTokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.length > 1)
      .toList();

  int _productSearchScore(Fragrance product, List<String> tokens) {
    if (tokens.isEmpty) {
      return 0;
    }
    final fields = {
      product.name.toLowerCase(): 12,
      product.sku.toLowerCase(): 10,
      product.brand.toLowerCase(): 8,
      product.type.toLowerCase(): 7,
      product.notes.toLowerCase(): 6,
      product.topNotes.toLowerCase(): 6,
      product.heartNotes.toLowerCase(): 6,
      product.baseNotes.toLowerCase(): 6,
      product.vibe.toLowerCase(): 5,
      product.performance.toLowerCase(): 5,
      product.fragranceProfile.toLowerCase(): 5,
      product.description.toLowerCase(): 4,
      product.comparison.toLowerCase(): 4,
      product.season.toLowerCase(): 3,
      product.occasion.toLowerCase(): 3,
      product.family.toLowerCase(): 3,
      product.gender.toLowerCase(): 2,
      product.concentration.toLowerCase(): 2,
    };
    var score = 0;
    for (final token in tokens) {
      var tokenMatched = false;
      for (final entry in fields.entries) {
        if (entry.key == token) {
          score += entry.value * 2;
          tokenMatched = true;
        } else if (entry.key.contains(token)) {
          score += entry.value;
          tokenMatched = true;
        }
      }
      if (!tokenMatched) {
        return 0;
      }
    }
    return score + product.sold + product.rating.round();
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

  void _updateStoreState(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

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
    if (query != null && query.trim().isNotEmpty) {
      _recordAnalyticsEvent(
        'search',
        page: StoreView.catalog.name,
        metadata: {'search_term': query.trim()},
      );
    }
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
  double get _discountedSubtotal => math.max(0, _cartSubtotal - _itemDiscount);
  List<TaxBreakdownLine> get _taxBreakdown => _matchedTaxRules
      .map(
        (rule) => TaxBreakdownLine(
          name: rule.name,
          jurisdiction: _taxJurisdiction(rule),
          rate: rule.rate,
          amount: _discountedSubtotal * rule.rate,
        ),
      )
      .where((line) => line.amount > 0)
      .toList();
  double get _tax =>
      _taxBreakdown.fold(0, (total, line) => total + line.amount);

  List<TaxRule> get _matchedTaxRules {
    final rules =
        _effectiveTaxRules
            .where((rule) => rule.isEnabled)
            .where(_taxRuleMatches)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rules;
  }

  List<TaxRule> get _effectiveTaxRules {
    final rules = [..._taxRules];
    final existingVatCountries = {
      for (final rule in rules)
        if (_taxRuleScope(rule) == 'vat') normalizeCountryCode(rule.country),
    };
    for (final rate in standardInternationalTaxRates) {
      if (existingVatCountries.contains(rate.code)) {
        continue;
      }
      rules.add(
        TaxRule(
          id: 'vat-${rate.code.toLowerCase()}',
          name: '${rate.country} VAT/GST',
          country: rate.code,
          taxType: 'vat',
          rate: rate.rate,
          isVat: true,
          isEnabled: true,
          sortOrder: 50,
        ),
      );
    }
    return rules;
  }

  bool _taxRuleMatches(TaxRule rule) {
    final customer = _checkoutShippingAddress;
    final scope = _taxRuleScope(rule);
    if (scope == 'vat') {
      final storeCountry = normalizeCountryCode(_storeInfo.country);
      final customerCountry = normalizeCountryCode(customer.country);
      final ruleCountry = normalizeCountryCode(rule.country);
      return customerCountry.isNotEmpty &&
          customerCountry != storeCountry &&
          customerCountry == ruleCountry;
    }
    if (scope == 'other') {
      return true;
    }
    final storeCountry = normalizeCountryCode(_storeInfo.country);
    final customerCountry = normalizeCountryCode(customer.country);
    final ruleCountry = normalizeCountryCode(rule.country);
    if (storeCountry.isEmpty ||
        customerCountry != storeCountry ||
        ruleCountry != storeCountry) {
      return false;
    }
    if (scope == 'state') {
      return _sameText(rule.state, _storeInfo.state) &&
          _sameText(customer.state, _storeInfo.state);
    }
    if (scope == 'county') {
      return _sameText(rule.state, _storeInfo.state) &&
          _sameText(customer.state, _storeInfo.state) &&
          _sameText(rule.county, _storeInfo.county) &&
          _sameText(customer.county, _storeInfo.county);
    }
    if (scope == 'city') {
      return _sameText(rule.state, _storeInfo.state) &&
          _sameText(customer.state, _storeInfo.state) &&
          _sameText(rule.county, _storeInfo.county) &&
          _sameText(customer.county, _storeInfo.county) &&
          _sameText(rule.city, _storeInfo.city) &&
          _sameText(customer.city, _storeInfo.city);
    }
    return false;
  }

  String _taxRuleScope(TaxRule rule) {
    final type = rule.taxType.trim().toLowerCase();
    if (type == 'state' ||
        type == 'county' ||
        type == 'city' ||
        type == 'other' ||
        type == 'vat') {
      return type;
    }
    if (rule.city.trim().isNotEmpty) {
      return 'city';
    }
    if (rule.county.trim().isNotEmpty) {
      return 'county';
    }
    if (rule.state.trim().isNotEmpty) {
      return 'state';
    }
    return '';
  }

  bool _sameText(String left, String right) =>
      left.trim().toLowerCase() == right.trim().toLowerCase() &&
      left.trim().isNotEmpty &&
      right.trim().isNotEmpty;

  String _taxJurisdiction(TaxRule rule) {
    final scope = _taxRuleScope(rule);
    if (scope == 'city') {
      return 'City';
    }
    if (scope == 'county') {
      return 'County';
    }
    if (scope == 'state') {
      return 'State';
    }
    if (scope == 'other') {
      return rule.name.trim().isEmpty ? 'Other' : rule.name;
    }
    if (scope == 'vat') {
      return '${countryNameForCode(rule.country)} VAT/GST';
    }
    return rule.taxType;
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

  double get _shippingBeforeDiscount =>
      _cartSubtotal > 125 || _cartSubtotal == 0
      ? 0
      : (_enabledShippingOptions.isEmpty
            ? 0
            : _shippingForOption(_selectedShippingOption));

  double _shippingForOption(ShippingOption option) {
    return option.chargeType == 'per_item'
        ? option.price * _cartCount
        : option.price;
  }

  double get _shipping =>
      math.max(0, _shippingBeforeDiscount - _shippingDiscount);
  double get _preCreditTotal => _discountedSubtotal + _tax + _shipping;
  double get _cartTotal => math.max(0, _preCreditTotal - _codeCredit);

  void _recordDailyEvent({
    int newUsers = 0,
    int visits = 0,
    int orders = 0,
    double revenue = 0,
  }) {
    final now = DateTime.now();
    final label = '${now.month}/${now.day}';
    final dayKey = _analyticsDayKey(now);
    unawaited(
      _gateway
          .incrementDailyMetric({
            'day': dayKey,
            'label': label,
            'new_users': newUsers,
            'visits': visits,
            'orders': orders,
            'revenue': revenue,
          })
          .catchError((_) {}),
    );
    final index = _dailyMetrics.indexWhere(
      (metric) => metric.day == label || metric.day == dayKey,
    );
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

  String _analyticsDayKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
    final session = _activeUserSessions.firstWhere(
      (session) => session.id == _visitorSessionId,
    );
    unawaited(
      _gateway
          .upsertActiveUserSession(_activeUserSessionRow(session))
          .catchError((_) {}),
    );
    _recordDailyEvent(visits: 1);
    _recordAnalyticsEvent('page_view', page: page);
  }

  Map<String, dynamic> _activeUserSessionRow(ActiveUserSession session) {
    return {
      'id': session.id,
      'visitor': session.visitor,
      'current_page': session.currentPage,
      'source': session.source,
      'referrer': session.referrer,
      'device': session.device,
      'started_at': session.startedAt.toUtc().toIso8601String(),
      'last_seen_at': session.lastSeenAt.toUtc().toIso8601String(),
    };
  }

  void _recordAnalyticsEvent(
    String eventName, {
    String? page,
    Fragrance? product,
    Order? order,
    double? value,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    final visitor =
        _currentCustomer?.email ??
        _currentBackendUser?.email ??
        'Guest visitor';
    final currentPage = page ?? _view.name;
    final event = AnalyticsEvent(
      id: 'EVT-${now.microsecondsSinceEpoch}-${math.Random().nextInt(99999)}',
      sessionId: _visitorSessionId,
      visitor: visitor,
      eventName: eventName,
      page: currentPage,
      source: currentTrafficSource(),
      referrer: currentTrafficReferrer(),
      device: currentDeviceLabel(),
      productId: product?.id,
      productName: product?.name ?? '',
      orderId: order?.id ?? '',
      value: value ?? order?.total ?? product?.price ?? 0,
      currency: 'USD',
      metadata: metadata,
      occurredAt: now,
    );
    void updateEvents() {
      _analyticsEvents.insert(0, event);
      if (_analyticsEvents.length > 1000) {
        _analyticsEvents.removeRange(1000, _analyticsEvents.length);
      }
    }

    if (mounted &&
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      setState(updateEvents);
    } else {
      updateEvents();
    }
    unawaited(_gateway.insertAnalyticsEvent(_analyticsEventRow(event)));
    trackGoogleAnalyticsEvent(
      eventName,
      page: currentPage,
      value: event.value,
      currency: event.currency,
      itemName: event.productName,
      orderId: event.orderId,
    );
  }

  Map<String, dynamic> _analyticsEventRow(AnalyticsEvent event) {
    return {
      'id': event.id,
      'session_id': event.sessionId,
      'visitor': event.visitor,
      'event_name': event.eventName,
      'page': event.page,
      'source': event.source,
      'referrer': event.referrer,
      'device': event.device,
      'product_id': event.productId,
      'product_name': event.productName,
      'order_id': event.orderId,
      'value': event.value,
      'currency': event.currency,
      'metadata': event.metadata,
      'occurred_at': event.occurredAt.toUtc().toIso8601String(),
    };
  }

  ActiveCart _activeCartFromRow(Map<String, dynamic> row) {
    final lines = <CartLine>[];
    final rawLines = row['lines'];
    if (rawLines is List) {
      for (final rawLine in rawLines) {
        if (rawLine is! Map) {
          continue;
        }
        final line = rawLine.cast<String, dynamic>();
        final productId = _asInt(line['product_id']);
        final product = _products.firstWhere(
          (item) => item.id == productId,
          orElse: () => Fragrance(
            id: productId,
            name: _asString(line['product_name'], fallback: 'Cart item'),
            type: _asString(line['product_type'], fallback: 'Fragrance'),
            brand: _asString(line['brand']),
            notes: '',
            size: _asString(line['size']),
            price: _asDouble(line['unit_price']),
            stock: 0,
            sold: 0,
            featuredColor: const Color(0xFFC88F52),
            sku: _asString(line['sku']),
            photoUrl: _asString(line['photo_url']),
            vendor: '',
            categoryId: 0,
          ),
        );
        ProductVariant? variant;
        for (final option in product.variants) {
          if (option.id == _asInt(line['variant_id'])) {
            variant = option;
            break;
          }
        }
        lines.add(
          CartLine(
            product: product,
            variant: variant,
            quantity: math.max(1, _asInt(line['quantity'], fallback: 1)),
          ),
        );
      }
    }
    final lastSeen =
        DateTime.tryParse(_asString(row['last_seen_at'])) ?? DateTime.now();
    final minutesAgo = math.max(
      0,
      DateTime.now().difference(lastSeen).inMinutes,
    );
    return ActiveCart(
      id: _asString(row['id'], fallback: 'CART'),
      customer: _asString(row['customer_name'], fallback: 'Guest shopper'),
      minutesAgo: minutesAgo,
      lines: lines,
    );
  }

  Map<String, dynamic> _activeCartRow({String status = 'active'}) {
    final customer = _currentCustomer;
    final email = (customer?.email ?? _checkoutEmail).trim().toLowerCase();
    final name = customer?.name.trim().isNotEmpty == true
        ? customer!.name.trim()
        : [
            _checkoutShippingAddress.firstName,
            _checkoutShippingAddress.lastName,
          ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': 'CART-$_visitorSessionId',
      'customer_email': email,
      'customer_name': name.isEmpty ? 'Guest shopper' : name,
      'status': status,
      'item_count': _cartCount,
      'subtotal': _cartSubtotal,
      'lines': _cart
          .map(
            (line) => {
              'product_id': line.product.id,
              'variant_id': line.variant?.id,
              'product_name': line.product.name,
              'product_type': line.product.type,
              'brand': line.product.brand,
              'sku': line.sku,
              'size': line.size,
              'quantity': line.quantity,
              'unit_price': line.unitPrice,
              'photo_url': line.product.photoUrl,
            },
          )
          .toList(),
      'last_seen_at': now,
    };
  }

  void _syncActiveCart({String status = 'active'}) {
    if (_cart.isEmpty) {
      unawaited(_gateway.markActiveCartRecovered('CART-$_visitorSessionId'));
      return;
    }
    unawaited(_gateway.upsertActiveCart(_activeCartRow(status: status)));
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
    _syncActiveCart();
    _recordAnalyticsEvent(
      'add_to_cart',
      page: StoreView.cart.name,
      product: product,
      value: variant.price,
      metadata: {'sku': variant.sku, 'size': variant.size, 'quantity': 1},
    );
    _recordAnalyticsEvent(
      'view_cart',
      page: StoreView.cart.name,
      value: _cartTotal,
      metadata: {'items': _cartCount},
    );
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
    _syncActiveCart();
    _recordAnalyticsEvent(
      'add_to_cart',
      page: StoreView.checkout.name,
      product: product,
      value: variant.price,
      metadata: {'sku': variant.sku, 'size': variant.size, 'quantity': 1},
    );
    _recordAnalyticsEvent(
      'begin_checkout',
      page: StoreView.checkout.name,
      value: _cartTotal,
      metadata: {'items': _cartCount, 'source': 'buy_now'},
    );
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
    _recordAnalyticsEvent(
      'view_item',
      page: StoreView.detail.name,
      product: product,
      value: product.price,
      metadata: {'sku': product.sku, 'type': product.type},
    );
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
    _syncActiveCart();
    _recordAnalyticsEvent(
      'begin_checkout',
      page: StoreView.checkout.name,
      value: _cartTotal,
      metadata: {'items': _cartCount, 'source': 'cart'},
    );
    unawaited(_refreshSelectedShippingRate());
  }

  void _hydrateCheckoutFields() {
    final customer = _currentCustomer;
    if (customer == null) {
      return;
    }
    _checkoutEmail = customer.email;
    _checkoutPhone = customer.phone;
    _checkoutShippingAddress = ShippingAddress(
      firstName: customer.name.split(' ').first,
      lastName: customer.name.split(' ').skip(1).join(' '),
      addressLine1: customer.addressLine1,
      addressLine2: customer.addressLine2,
      city: customer.city,
      county: customer.county,
      state: customer.state,
      postalCode: customer.postalCode,
      country: customer.country,
      phone: customer.phone,
      email: customer.email,
    );
  }

  void _removePromoCode() {
    setState(() {
      _promoCode = '';
      _appliedCoupon = null;
      _promoMessage = '';
    });
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
    _syncActiveCart();
  }

  Future<void> _checkout() async {
    if (_placingOrder || _cart.isEmpty) {
      return;
    }
    final appliedCoupon = _validAppliedCoupon;
    if (_appliedCoupon != null && appliedCoupon == null) {
      setState(() {
        _promoMessage = _couponValidationMessage(_appliedCoupon!);
      });
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
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    final shippingAddress = ShippingAddress(
      firstName: _checkoutShippingAddress.firstName,
      lastName: _checkoutShippingAddress.lastName,
      addressLine1: _checkoutShippingAddress.addressLine1,
      addressLine2: _checkoutShippingAddress.addressLine2,
      city: _checkoutShippingAddress.city,
      county: _checkoutShippingAddress.county,
      state: _checkoutShippingAddress.state,
      postalCode: _checkoutShippingAddress.postalCode,
      country: _checkoutShippingAddress.country,
      phone: _checkoutPhone,
      email: email,
    );

    final addressError = Validators.validateAddress(
      shippingAddress.addressLine1,
      shippingAddress.city,
      shippingAddress.state,
      shippingAddress.postalCode,
    );
    if (addressError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(addressError)));
      return;
    }

    if (_checkoutPhone.trim().isNotEmpty) {
      final phoneError = Validators.validatePhone(_checkoutPhone.trim());
      if (phoneError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(phoneError)));
        return;
      }
    }

    for (final line in _cart) {
      final quantityError = Validators.validateQuantity(line.quantity);
      if (quantityError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(quantityError)));
        return;
      }
      final inventoryError = Validators.validateInventoryAvailable(
        line.stockAvailable,
        line.quantity,
      );
      if (inventoryError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(inventoryError)));
        return;
      }
    }

    final orderId = 'EA-${DateTime.now().microsecondsSinceEpoch}';
    final checkoutToken = _newCheckoutToken();
    final selectedPaymentMethod = _selectedPaymentMethod;
    if (selectedPaymentMethod == null) {
      _showStatusSnack('Select an enabled payment provider to continue.');
      return;
    }
    if (selectedPaymentMethod.mode.trim().toLowerCase() != 'live') {
      _showStatusSnack(
        '${selectedPaymentMethod.name} is running in test mode. No real charge will be captured.',
      );
    }
    final stripeProvider = selectedPaymentMethod.provider
        .trim()
        .toLowerCase()
        .contains('stripe');
    String checkoutUrl = '';
    if (!stripeProvider) {
      checkoutUrl = await _resolveCheckoutUrl(selectedPaymentMethod);
      if (checkoutUrl.isEmpty) {
        _showStatusSnack(
          '${selectedPaymentMethod.name} checkout URL is missing. Save the provider checkout URL in admin before placing orders.',
        );
        return;
      }
    }
    final shippingOption = _selectedShippingOption;
    final lines = _cart
        .map(
          (line) => CartLine(
            product: line.product,
            variant: line.variant,
            quantity: line.quantity,
          ),
        )
        .toList();
    final order = Order(
      id: orderId,
      customer: customerName,
      email: email,
      total: _cartTotal,
      subtotal: _cartSubtotal,
      discountTotal: _discountTotal,
      couponCode: appliedCoupon?.code ?? '',
      itemCount: _cartCount,
      status: 'Pending',
      checkoutToken: checkoutToken,
      financialStatus: 'Unpaid',
      fulfillmentStatus: 'Pending',
      shippingCarrier: shippingOption.carrier,
      shippingService: shippingOption.service,
      shippingPriority: shippingOption.priority,
      shippingTotal: _shipping,
      taxBreakdown: _taxBreakdown,
      shippingAddress: shippingAddress,
      createdAt: DateTime.now(),
      lines: lines,
    );

    setState(() => _placingOrder = true);
    try {
      await _gateway.upsertOrder(_orderRow(order));
      await _gateway.insertOrderItems(_orderItemRows(order));
      _recordOrderReceivedNotification(order);
    } catch (error) {
      if (mounted) {
        setState(() => _placingOrder = false);
      }
      _showStatusSnack('Order could not be created before payment: $error');
      return;
    }

    late final String redirectUrl;
    try {
      final success = Uri.base.replace(
        path: '/payment-success',
        queryParameters: {
          'payment': 'success',
          'order': order.id,
          'provider': selectedPaymentMethod.provider.toLowerCase(),
        },
      );
      final failure = Uri.base.replace(
        path: '/payment-failed',
        queryParameters: {
          'payment': 'failed',
          'order': order.id,
          'provider': selectedPaymentMethod.provider.toLowerCase(),
        },
      );
      redirectUrl = stripeProvider
          ? await _gateway.createStripeCheckoutSession(
              orderNumber: order.id,
              mode: selectedPaymentMethod.mode,
              successUrl: success.toString(),
              cancelUrl: failure.toString(),
            )
          : _paymentProcessorUrlForOrder(
              method: selectedPaymentMethod,
              checkoutUrl: checkoutUrl,
              order: order,
            );
    } catch (error) {
      if (mounted) {
        setState(() => _placingOrder = false);
      }
      _showStatusSnack('Could not open payment provider: $error');
      return;
    }

    _savePendingCheckoutDraft(order);
    if (!mounted) {
      return;
    }

    setState(() {
      _placingOrder = false;
      _pendingPaymentOrderId = order.id;
      if (!_orders.any((item) => item.id == order.id)) {
        _orders.insert(0, order);
      }
    });
    _recordOrderReceivedNotification(order);
    _recordAnalyticsEvent(
      'add_payment_info',
      page: StoreView.checkout.name,
      order: order,
      metadata: {
        'provider': selectedPaymentMethod.provider,
        'mode': selectedPaymentMethod.mode,
        'items': order.itemCount,
      },
    );

    _showStatusSnack('Redirecting to secure payment for order $orderId...');
    _gateway.redirectBrowserTo(redirectUrl);
  }

  void _recordOrderReceivedNotification(Order order) {
    final notificationId = 'N-order-received-${order.id}';
    if (_notifications.any(
      (notification) => notification.id == notificationId,
    )) {
      return;
    }
    final notification = StoreNotification(
      id: notificationId,
      type: 'order',
      title: 'New order received',
      message:
          '${order.id} was created for ${order.customer} and is waiting for payment.',
      createdAt: DateTime.now(),
    );
    _addAdminNotification(notification, persist: true, urgent: true);
  }

  String _newCheckoutToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random.secure();
    return List.generate(40, (_) => chars[random.nextInt(chars.length)]).join();
  }

  PaymentMethodConfig? get _selectedPaymentMethod {
    final enabled = _paymentMethods
        .where((method) => method.isEnabled)
        .toList();
    if (enabled.isEmpty) {
      return null;
    }
    return enabled.firstWhere(
      (method) => method.provider == _selectedCheckoutPaymentProvider,
      orElse: () => enabled.first,
    );
  }

  String _paymentProcessorUrlForOrder({
    required PaymentMethodConfig method,
    required String checkoutUrl,
    required Order order,
  }) {
    final base = Uri.parse(checkoutUrl.trim());
    final success = Uri.base.replace(
      path: '/payment-success',
      queryParameters: {
        'payment': 'success',
        'order': order.id,
        'provider': method.provider.toLowerCase(),
      },
    );
    final failure = Uri.base.replace(
      path: '/payment-failed',
      queryParameters: {
        'payment': 'failed',
        'order': order.id,
        'provider': method.provider.toLowerCase(),
      },
    );
    final mergedQuery = <String, String>{
      ...base.queryParameters,
      'order_number': order.id,
      'amount': order.total.toStringAsFixed(2),
      'currency': 'USD',
      'customer_email': order.email,
      'success_url': success.toString(),
      'cancel_url': failure.toString(),
      'return_success_url': success.toString(),
      'return_failure_url': failure.toString(),
    };
    return base.replace(queryParameters: mergedQuery).toString();
  }

  Future<String> _resolveCheckoutUrl(PaymentMethodConfig method) async {
    final inline = method.checkoutUrl.trim();
    if (inline.isNotEmpty) {
      return inline;
    }
    try {
      final credential = await _gateway.fetchPaymentProcessorCredentials(
        method.provider,
      );
      final value = credential?['value'];
      if (value is Map) {
        final checkoutUrl = _firstNonEmptyString([
          value['checkoutUrl'],
          value['checkout_url'],
          method.checkoutUrl,
          method.webhookUrl,
        ]);
        return checkoutUrl ?? '';
      }
    } catch (_) {}
    return method.webhookUrl.trim();
  }

  Future<void> _handlePaymentReturnRoute(String route, StoreView view) async {
    if (_processingPaymentReturn || !mounted) {
      return;
    }
    if (view != StoreView.paymentSuccess && view != StoreView.paymentFailure) {
      return;
    }
    final uri = Uri.tryParse(route) ?? Uri.base;
    final orderId = uri.queryParameters['order']?.trim().isNotEmpty == true
        ? uri.queryParameters['order']!.trim()
        : _pendingPaymentOrderId;
    if (orderId.isEmpty) {
      return;
    }

    _processingPaymentReturn = true;
    try {
      if (view == StoreView.paymentSuccess) {
        final provider = uri.queryParameters['provider']?.toLowerCase() ?? '';
        if (provider.contains('stripe')) {
          await _handleStripePaymentSuccessReturn(orderId);
          if (mounted) {
            setState(() {});
          }
          return;
        }
        final existingIndex = _orders.indexWhere(
          (order) => order.id == orderId,
        );
        final draftOrder = _restorePendingCheckoutDraft(orderId);
        final order = existingIndex != -1 ? _orders[existingIndex] : draftOrder;
        if (order == null) {
          throw StateError(
            'Could not restore the completed order after payment success.',
          );
        }
        final wasPaid = order.financialStatus.toLowerCase() == 'paid';
        if (existingIndex == -1) {
          final draftWasSaved = _pendingCheckoutDraftWasSaved(orderId);
          order
            ..status = 'Pending'
            ..financialStatus = 'Paid'
            ..fulfillmentStatus = 'Pending';
          await _gateway.upsertOrder(_orderRow(order));
          if (!draftWasSaved) {
            await _gateway.insertOrderItems(_orderItemRows(order));
          }
          _orders.insert(0, order);
        } else if (!wasPaid) {
          order
            ..status = 'Pending'
            ..financialStatus = 'Paid'
            ..fulfillmentStatus = 'Pending';
          await _gateway.upsertOrder(_orderRow(order));
        }

        if (!wasPaid) {
          for (final line in order.lines) {
            line.product.stock = math.max(
              0,
              line.product.stock - line.quantity,
            );
            if (line.variant != null) {
              line.variant!.stock = math.max(
                0,
                line.variant!.stock - line.quantity,
              );
            }
            line.product.sold += line.quantity;
          }
          try {
            await _gateway.decrementInventoryForOrder(
              orderNumber: order.id,
              email: order.email,
            );
          } catch (error) {
            _showStatusSnack(
              'Payment succeeded, but inventory update failed: $error',
            );
          }
          await _settlePaidOrderRewards(order);
          _recordDailyEvent(orders: 1, revenue: order.total);
          _recordAnalyticsEvent('purchase', page: view.name, order: order);
          unawaited(_sendOrderEmail(order, 'payment_success'));
        }
        order
          ..status = 'Pending'
          ..financialStatus = 'Paid'
          ..fulfillmentStatus = 'Pending';
        _savePendingCheckoutDraft(order);
        _lastCompletedOrder = order;
        unawaited(_gateway.markActiveCartRecovered('CART-$_visitorSessionId'));
        _cart.clear();
        _promoCode = '';
        _appliedCoupon = null;
        _promoMessage = '';
        _pendingPaymentOrderId = '';
      } else {
        clearPendingCheckoutDraft();
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          final order = _orders[index];
          if (order.status.toLowerCase() != 'cancelled') {
            order
              ..status = 'Cancelled'
              ..financialStatus = 'Unpaid';
            await _gateway.upsertOrder(_orderRow(order));
          }
          unawaited(_sendOrderEmail(order, 'payment_failed'));
          _recordAnalyticsEvent(
            'payment_failed',
            page: view.name,
            order: order,
          );
          final notification = StoreNotification(
            id: 'N-${DateTime.now().millisecondsSinceEpoch}-${order.id}-payment-failed',
            type: 'payment',
            title: 'Payment not completed',
            message:
                '${order.id} payment was cancelled or failed. Recovery email queued for ${order.email}.',
            createdAt: DateTime.now(),
          );
          _notifications.insert(0, notification);
          unawaited(_gateway.insertNotification(notification.toRow()));
        }
        _pendingPaymentOrderId = '';
      }
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        _showStatusSnack('Payment return handling failed: $error');
      }
    } finally {
      _processingPaymentReturn = false;
    }
  }

  Future<void> _handleStripePaymentSuccessReturn(String orderId) async {
    final existingIndex = _orders.indexWhere((order) => order.id == orderId);
    final draftOrder = _restorePendingCheckoutDraft(orderId);
    var order = existingIndex != -1 ? _orders[existingIndex] : draftOrder;
    final wasPaid = order?.financialStatus.toLowerCase() == 'paid';

    for (var attempt = 0; attempt < 8; attempt += 1) {
      final liveOrder = await _fetchLiveOrder(orderId);
      if (liveOrder != null) {
        order = liveOrder;
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    if (order == null) {
      throw StateError(
        'Could not restore the completed order after payment success.',
      );
    }

    final index = _orders.indexWhere((item) => item.id == order!.id);
    if (index == -1) {
      _orders.insert(0, order);
    } else {
      _orders[index] = order;
    }

    final isPaid = order.financialStatus.toLowerCase() == 'paid';
    if (isPaid && !wasPaid) {
      await _settlePaidOrderRewards(order);
      _recordDailyEvent(orders: 1, revenue: order.total);
      _recordAnalyticsEvent(
        'purchase',
        page: StoreView.paymentSuccess.name,
        order: order,
      );
      unawaited(_sendOrderEmail(order, 'payment_success'));
      unawaited(_gateway.markActiveCartRecovered('CART-$_visitorSessionId'));
      _cart.clear();
      _promoCode = '';
      _appliedCoupon = null;
      _promoMessage = '';
    }

    _savePendingCheckoutDraft(order);
    _lastCompletedOrder = order;
    _pendingPaymentOrderId = '';
  }

  Future<Order?> _fetchLiveOrder(String orderId) async {
    try {
      final rows = await _gateway.fetchOrders();
      for (final row in rows) {
        final id = '${row['order_number'] ?? row['id']}'.trim();
        if (id == orderId) {
          return Order.fromRow(row);
        }
      }
    } catch (_) {}
    return null;
  }

  void _savePendingCheckoutDraft(Order order) {
    final row = _orderRow(order);
    row['created_at'] = order.createdAt?.toIso8601String();
    savePendingCheckoutDraft({
      'order': row,
      'order_items': _orderItemRows(order),
      'admin_order_saved': true,
    });
  }

  bool _pendingCheckoutDraftWasSaved(String orderId) {
    final draft = loadPendingCheckoutDraft();
    if (draft == null) {
      return false;
    }
    final orderRow = draft['order'];
    if (orderRow is! Map) {
      return false;
    }
    final draftOrderId = '${orderRow['order_number'] ?? orderRow['id'] ?? ''}'
        .trim();
    return draftOrderId == orderId && draft['admin_order_saved'] == true;
  }

  Order? _restorePendingCheckoutDraft(String orderId) {
    final draft = loadPendingCheckoutDraft();
    if (draft == null) {
      return null;
    }
    final orderRow = draft['order'];
    final orderItems = draft['order_items'];
    if (orderRow is! Map) {
      return null;
    }
    final row = Map<String, dynamic>.from(orderRow.cast<String, dynamic>());
    final draftOrderId = '${row['order_number'] ?? row['id'] ?? ''}'.trim();
    if (draftOrderId != orderId) {
      return null;
    }
    row['order_items'] = orderItems is List
        ? orderItems
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : const <Map<String, dynamic>>[];
    return Order.fromRow(row);
  }

  Order? _restoreAnyPendingCheckoutDraft() {
    final draft = loadPendingCheckoutDraft();
    if (draft == null) {
      return null;
    }
    final orderRow = draft['order'];
    final orderItems = draft['order_items'];
    if (orderRow is! Map) {
      return null;
    }
    final row = Map<String, dynamic>.from(orderRow.cast<String, dynamic>());
    row['order_items'] = orderItems is List
        ? orderItems
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : const <Map<String, dynamic>>[];
    return Order.fromRow(row);
  }

  Order? _paymentReturnOrderForCurrentRoute() {
    final route = currentBrowserRoute();
    final isSuccessRoute =
        _viewForBrowserRoute(route) == StoreView.paymentSuccess;
    Order? successAware(Order? order) {
      if (!isSuccessRoute || order == null) {
        return order;
      }
      return order
        ..status = 'Pending'
        ..financialStatus = 'Paid'
        ..fulfillmentStatus = 'Pending';
    }

    if (_lastCompletedOrder != null) {
      return successAware(_lastCompletedOrder);
    }
    final uri = Uri.tryParse(route) ?? Uri.base;
    final routeOrderId = uri.queryParameters['order']?.trim() ?? '';
    if (routeOrderId.isNotEmpty) {
      final index = _orders.indexWhere((order) => order.id == routeOrderId);
      if (index != -1) {
        return successAware(_orders[index]);
      }
      final draftOrder = _restorePendingCheckoutDraft(routeOrderId);
      if (draftOrder != null) {
        return successAware(draftOrder);
      }
    }
    if (_pendingPaymentOrderId.isNotEmpty) {
      final index = _orders.indexWhere(
        (order) => order.id == _pendingPaymentOrderId,
      );
      if (index != -1) {
        return successAware(_orders[index]);
      }
    }
    return successAware(_restoreAnyPendingCheckoutDraft());
  }

  List<Map<String, dynamic>> _orderItemRows(Order order) {
    return [
      for (final line in order.lines)
        {
          'order_id': order.id,
          'checkout_token': order.checkoutToken,
          'product_id': line.product.id,
          'variant_id': line.variant?.id,
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

  Future<void> _submitCompanySurvey({
    required Order order,
    required int rating,
    required String title,
    required String body,
    required bool anonymous,
    required bool wouldRecommend,
  }) async {
    final review = ReviewSummary(
      id: DateTime.now().millisecondsSinceEpoch,
      scope: 'Company',
      author: anonymous ? 'Verified customer' : order.customer,
      rating: rating.toDouble(),
      title: title.trim().isEmpty ? 'Verified purchase review' : title.trim(),
      body: body.trim(),
      status: 'pending',
      customerEmail: order.email,
    );
    await _gateway.upsertReview(_reviewRow(review));
    try {
      await _gateway.insertOrderSurvey({
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
    } catch (error) {
      _showStatusSnack('Review saved, but survey details failed: $error');
    }
    _recordAnalyticsEvent(
      'generate_lead',
      page: StoreView.paymentSuccess.name,
      order: order,
      metadata: {
        'lead_type': 'post_purchase_survey',
        'rating': rating,
        'would_recommend': wouldRecommend,
      },
    );
    clearPendingCheckoutDraft();
    replaceBrowserRoute('/');
    setState(() {
      _view = StoreView.shop;
      _lastBrowserRoute = '/';
      _lastCompletedOrder = null;
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
  }

  Future<void> _createAccount(
    String name,
    String email,
    String password, {
    ShippingAddress? shippingAddress,
    bool stayOnCheckout = false,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emailError)));
      }
      return;
    }
    if (password.trim().length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters.'),
          ),
        );
      }
      return;
    }
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
      addressLine1: shippingAddress?.addressLine1 ?? '',
      addressLine2: shippingAddress?.addressLine2 ?? '',
      city: shippingAddress?.city ?? '',
      county: shippingAddress?.county ?? '',
      state: shippingAddress?.state ?? '',
      postalCode: shippingAddress?.postalCode ?? '',
      country: shippingAddress?.country ?? 'US',
    );
    await _captureCustomerAccessMetadata(
      created,
      isNewAccount: true,
      persist: false,
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
      _view = stayOnCheckout ? StoreView.checkout : StoreView.account;
      _checkoutEmail = account.email;
      _checkoutShippingAddress = ShippingAddress(
        firstName: shippingAddress?.firstName ?? account.name.split(' ').first,
        lastName:
            shippingAddress?.lastName ??
            account.name.split(' ').skip(1).join(' '),
        addressLine1: shippingAddress?.addressLine1 ?? account.addressLine1,
        addressLine2: shippingAddress?.addressLine2 ?? account.addressLine2,
        city: shippingAddress?.city ?? account.city,
        county: shippingAddress?.county ?? account.county,
        state: shippingAddress?.state ?? account.state,
        postalCode: shippingAddress?.postalCode ?? account.postalCode,
        country: shippingAddress?.country ?? account.country,
        phone: _checkoutPhone,
        email: account.email,
      );
    });
    if (stayOnCheckout && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Your checkout details are still editable.',
          ),
        ),
      );
    }
    unawaited(_saveWishlistForCustomer(account));
    _syncActiveCart();
  }

  Future<void> _createCheckoutAccount(String password) async {
    if (_currentCustomer != null || _creatingCheckoutAccount) {
      return;
    }
    final name =
        '${_checkoutShippingAddress.firstName} ${_checkoutShippingAddress.lastName}'
            .trim();
    if (name.isEmpty || _checkoutEmail.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter your name and email in checkout before creating an account.',
          ),
        ),
      );
      return;
    }
    final shippingAddress = ShippingAddress(
      firstName: _checkoutShippingAddress.firstName,
      lastName: _checkoutShippingAddress.lastName,
      addressLine1: _checkoutShippingAddress.addressLine1,
      addressLine2: _checkoutShippingAddress.addressLine2,
      city: _checkoutShippingAddress.city,
      county: _checkoutShippingAddress.county,
      state: _checkoutShippingAddress.state,
      postalCode: _checkoutShippingAddress.postalCode,
      country: _checkoutShippingAddress.country,
      phone: _checkoutPhone,
      email: _checkoutEmail.trim(),
    );
    setState(() => _creatingCheckoutAccount = true);
    try {
      await _createAccount(
        name,
        _checkoutEmail.trim(),
        password,
        shippingAddress: shippingAddress,
        stayOnCheckout: true,
      );
    } finally {
      if (mounted) {
        setState(() => _creatingCheckoutAccount = false);
      }
    }
  }

  Future<void> _login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    CustomerAccount? match;
    try {
      final row = await _gateway.loginCustomer(cleanEmail, password);
      if (row != null) {
        match = CustomerAccount.fromRow(row);
        match = await _captureCustomerAccessMetadata(match);
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
    await _loadWishlistForCustomer(match);
    _syncActiveCart();
  }

  Future<void> _loadWishlistForCustomer(CustomerAccount customer) async {
    try {
      final rows = await _gateway.fetchWishlist(customer.email);
      if (!mounted) {
        return;
      }
      setState(() {
        _wishlistProductIds
          ..clear()
          ..addAll(rows.map((row) => _asInt(row['product_id'])));
      });
    } catch (_) {
      // Wishlist should never block sign-in or checkout.
    }
  }

  Future<CustomerAccount> _captureCustomerAccessMetadata(
    CustomerAccount customer, {
    bool isNewAccount = false,
    bool persist = true,
  }) async {
    final sourceType = currentClientSourceType();
    final ipAddress = await currentClientIpAddress();
    final now = DateTime.now();
    customer
      ..lastLoginAt = now
      ..lastLoginSource = sourceType;
    if (ipAddress.isNotEmpty) {
      customer.lastLoginIp = ipAddress;
    }
    if (isNewAccount) {
      if (customer.createdSource.trim().isEmpty) {
        customer.createdSource = sourceType;
      }
      if (ipAddress.isNotEmpty && customer.createdIp.trim().isEmpty) {
        customer.createdIp = ipAddress;
      }
    }
    if (persist) {
      try {
        await _gateway.upsertCustomer(customer.toRow());
      } catch (_) {
        // Access metadata is helpful, but it should never block sign-in.
      }
    }
    return customer;
  }

  Future<void> _saveWishlistForCustomer(CustomerAccount customer) async {
    for (final productId in _wishlistProductIds) {
      await _gateway.addWishlistItem(
        email: customer.email,
        productId: productId,
      );
    }
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
      _wishlistProductIds.clear();
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
        _adminNotificationPollTimer?.cancel();
        return;
      }
      _adminPreviewMode = true;
      _view = StoreView.admin;
    });
    if (match != null) {
      unawaited(
        _loadStoreData().then((_) {
          if (_currentBackendUser != null) {
            _startAdminAttentionPolling();
          }
        }),
      );
    }
  }

  void _logoutBackendUser() {
    unawaited(_gateway.logoutBackendUser());
    _adminNotificationPollTimer?.cancel();
    setState(() {
      _currentBackendUser = null;
      _adminPreviewMode = false;
      _view = StoreView.shop;
    });
  }

  void _toggleFavorite(Fragrance product) {
    final customer = _currentCustomer;
    final willRemove = _wishlistProductIds.contains(product.id);
    setState(() {
      if (willRemove) {
        _wishlistProductIds.remove(product.id);
      } else {
        _wishlistProductIds.add(product.id);
      }
    });
    if (customer == null) {
      _showStatusSnack('Sign in or create an account to save wishlist items.');
      return;
    }
    final action = willRemove
        ? _gateway.removeWishlistItem(
            email: customer.email,
            productId: product.id,
          )
        : _gateway.addWishlistItem(
            email: customer.email,
            productId: product.id,
          );
    unawaited(
      action.catchError(
        (Object error) => _showStatusSnack('Wishlist save failed: $error'),
      ),
    );
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
      await _gateway.replaceProductImages(
        product.id,
        _productImageRows(product),
      );
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
    _recordAdminAudit(
      action: 'upsert',
      entityType: 'product',
      entityId: '${product.id}',
      summary: 'Product saved: ${product.name}',
      metadata: {'sku': product.sku, 'stock': product.stock},
    );
  }

  List<Map<String, dynamic>> _productImageRows(Fragrance product) {
    return [
      for (var i = 0; i < product.images.length; i++)
        {
          'product_id': product.id,
          'url': product.images[i].url,
          'alt_text': product.images[i].altText,
          'sort_order': i + 1,
          'is_primary': product.images[i].isPrimary,
        },
    ];
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
    final existingIndex = _orders.indexWhere((item) => item.id == order.id);
    final previous = existingIndex == -1
        ? null
        : _orders[existingIndex].fulfillmentStatus;
    final previousReturnStatus = existingIndex == -1
        ? null
        : _orders[existingIndex].returnStatus;
    setState(() {
      if (existingIndex != -1) {
        _orders[existingIndex] = order;
      }
    });
    try {
      await _gateway.upsertOrder(_orderRow(order));
      if (_normalizeFinancialStatus(order.financialStatus) == 'refunded' ||
          order.returnRestocked) {
        try {
          await _gateway.restockInventoryForOrder(
            orderNumber: order.id,
            email: order.email,
          );
        } catch (error) {
          _showStatusSnack('Order saved, but inventory restock failed: $error');
        }
      }
      final event =
          _emailEventForFulfillmentChange(previous, order.fulfillmentStatus) ??
          _emailEventForFulfillmentChange(null, order.fulfillmentStatus);
      if (event != null) {
        unawaited(_sendOrderEmail(order, event));
      }
      final returnEvent = _emailEventForReturnChange(
        previousReturnStatus,
        order.returnStatus,
      );
      if (returnEvent != null) {
        unawaited(_sendOrderEmail(order, returnEvent));
      }
      _recordAdminAudit(
        action: 'update',
        entityType: 'order',
        entityId: order.id,
        summary:
            'Order updated: ${order.status}, ${order.financialStatus}, ${order.fulfillmentStatus}',
        metadata: {
          'return_status': order.returnStatus,
          'refund_status': order.refundStatus,
        },
      );
      _showStatusSnack('Order saved.');
    } catch (error) {
      _showStatusSnack('Order save failed: $error');
    }
  }

  Future<void> _requestOrderReturn(Order order) async {
    final index = _orders.indexWhere((item) => item.id == order.id);
    final notification = StoreNotification(
      id: 'N-return-${DateTime.now().millisecondsSinceEpoch}-${order.id}',
      type: 'return',
      title: 'Return request for ${order.id}',
      message:
          '${order.customer} requested return/refund for ${order.returnItems.length} item(s).\n${order.returnReason}',
      createdAt: DateTime.now(),
    );
    setState(() {
      if (index == -1) {
        _orders.insert(0, order);
      } else {
        _orders[index] = order;
      }
      _notifications.insert(0, notification);
    });
    try {
      await _gateway.submitReturnRequest(
        orderNumber: order.id,
        email: order.email,
        reason: order.returnReason,
        items: order.returnItems.map((item) => item.toJson()).toList(),
      );
      await _gateway.insertNotification(notification.toRow());
      _recordAdminAudit(
        action: 'return_request',
        entityType: 'order',
        entityId: order.id,
        summary: 'Customer requested return/refund for ${order.id}',
        metadata: {
          'return_items': order.returnItems
              .map((item) => item.toJson())
              .toList(),
          'return_reason': order.returnReason,
        },
      );
    } catch (error) {
      _showStatusSnack(
        'Return request was saved on this order, but admin notification sync needs attention: $error',
      );
    }
  }

  Future<String> _createStripeRefund(
    Order order,
    double amount,
    String reason,
  ) async {
    if (amount <= 0) {
      throw StateError('Refund amount must be greater than 0.');
    }
    try {
      final refundId = await _gateway.createStripeRefund(
        orderNumber: order.id,
        amount: amount,
        reason: reason,
      );
      _recordAdminAudit(
        action: 'stripe_refund',
        entityType: 'order',
        entityId: order.id,
        summary: 'Stripe refund $refundId created for ${currency(amount)}',
        metadata: {'refund_id': refundId, 'amount': amount, 'reason': reason},
      );
      return refundId;
    } catch (error) {
      _showStatusSnack('Stripe refund failed: $error');
      rethrow;
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
          ..status =
              fulfillmentStatus == 'Sent' || fulfillmentStatus == 'Shipped'
              ? 'Shipped'
              : fulfillmentStatus;
        final event = fulfillmentStatus == 'Label created'
            ? null
            : _emailEventForFulfillmentChange(null, fulfillmentStatus);
        if (event != null) {
          unawaited(_sendOrderEmail(order, event));
        }
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
    final status = _normalizeOrderStatus(order.status);
    final financialStatus = _normalizeFinancialStatus(order.financialStatus);
    final fulfillmentStatus = _normalizeFulfillmentStatus(
      order.fulfillmentStatus,
    );
    final trackingNumber = order.trackingNumber.trim();
    final trackingStatus = order.trackingStatus.trim().isNotEmpty
        ? order.trackingStatus.trim()
        : trackingNumber.isEmpty
        ? ''
        : 'Tracking available';
    final trackingUrl = order.trackingUrl.trim().isNotEmpty
        ? order.trackingUrl.trim()
        : _trackingUrlForCarrier(
            carrier: order.shippingCarrier,
            trackingNumber: trackingNumber,
          );
    return {
      'order_number': order.id,
      'customer_name': order.customer,
      'email': order.email,
      'checkout_token': order.checkoutToken,
      'status': status,
      'financial_status': financialStatus,
      'fulfillment_status': fulfillmentStatus,
      'subtotal': order.subtotal,
      'discount_total': order.discountTotal,
      'tax_total': order.taxBreakdown.fold(
        0.0,
        (total, line) => total + line.amount,
      ),
      'shipping_total': order.shippingTotal,
      'grand_total': order.total,
      'coupon_code': order.couponCode,
      'item_count': order.itemCount,
      'shipping_carrier': order.shippingCarrier,
      'shipping_service': order.shippingService,
      'shipping_priority': order.shippingPriority,
      'tracking_number': trackingNumber,
      'tracking_status': trackingStatus,
      'tracking_url': trackingUrl,
      'tracking_last_checked_at': order.trackingLastCheckedAt
          ?.toUtc()
          .toIso8601String(),
      'label_status': order.labelStatus,
      'refund_status': order.refundStatus,
      'refund_total': order.refundTotal,
      'refund_reference': order.refundReference,
      'refund_reason': order.refundReason,
      'refunded_at': order.refundedAt?.toUtc().toIso8601String(),
      'return_status': order.returnStatus,
      'return_reason': order.returnReason,
      'return_items': order.returnItems.map((item) => item.toJson()).toList(),
      'return_admin_comment': order.returnAdminComment,
      'return_condition': order.returnCondition,
      'refund_option': order.refundOption,
      'stripe_refund_id': order.stripeRefundId,
      'rma_number': order.rmaNumber,
      'rma_created_at': order.rmaCreatedAt?.toUtc().toIso8601String(),
      'return_requested_at': order.returnRequestedAt?.toUtc().toIso8601String(),
      'return_decision_at': order.returnDecisionAt?.toUtc().toIso8601String(),
      'return_restocked': order.returnRestocked,
      'returned_at': order.returnedAt?.toUtc().toIso8601String(),
      'shipping_address': order.shippingAddress.toJson(),
    };
  }

  String _normalizeOrderStatus(String value) {
    final clean = value.trim().toLowerCase();
    return switch (clean) {
      'pending' => 'pending',
      'paid' => 'paid',
      'invoice created' => 'invoice_created',
      'awaiting return item' => 'awaiting_return_item',
      'packing' => 'packing',
      'picking' || 'being picked' => 'picking',
      'label printed' || 'label created' || 'label_created' => 'label_created',
      'shipped' || 'sent' => 'shipped',
      'cancelled' => 'cancelled',
      'refunded' => 'refunded',
      _ => 'pending',
    };
  }

  String _normalizeFinancialStatus(String value) {
    final clean = value.trim().toLowerCase();
    return switch (clean) {
      'unpaid' => 'unpaid',
      'authorized' => 'authorized',
      'paid' => 'paid',
      'partially refunded' || 'partially_refunded' => 'partially_refunded',
      'refunded' => 'refunded',
      'voided' => 'voided',
      _ => 'unpaid',
    };
  }

  String _normalizeFulfillmentStatus(String value) {
    final clean = value.trim().toLowerCase();
    return switch (clean) {
      'pending' || 'unfulfilled' => 'Pending',
      'processing' => 'Processing',
      'invoice created' || 'invoice_created' => 'Invoice created',
      'awaiting return item' ||
      'awaiting_return_item' => 'Awaiting return item',
      'being picked' || 'picking' => 'Being picked',
      'packing' => 'Packing',
      'label printed' || 'label created' || 'label_created' => 'Label created',
      'sent' || 'shipped' => 'Shipped',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => 'Pending',
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
    try {
      if (_orderBlocksFulfillment(order)) {
        throw StateError(
          'This order is cancelled or refunded and cannot be fulfilled.',
        );
      }
      _validateShippingAddressForLabel(order);
      final carrier = order.shippingCarrier.trim().isEmpty
          ? 'USPS'
          : order.shippingCarrier.trim().toUpperCase();
      final credentials = _shippingCredentials[carrier];
      final result = (credentials?.isConfigured ?? false)
          ? await _gateway.createShippingLabel(
              carrier: carrier,
              order: _orderRow(order),
              storeInfo: _storeInfo.toRow(),
              package: _packageRowForOrder(order),
            )
          : _createAddressOnlyLabel(order, carrier);

      if (result.labelBase64.isNotEmpty) {
        downloadBase64File(
          fileName: result.labelFileName,
          base64Contents: result.labelBase64,
          mimeType: result.labelContentType,
        );
      }
      setState(() {
        final trackingUrl = _trackingUrlForCarrier(
          carrier: carrier,
          trackingNumber: result.trackingNumber,
        );
        order
          ..trackingNumber = result.trackingNumber
          ..trackingStatus = result.trackingNumber.trim().isEmpty
              ? 'Tracking pending'
              : 'Label created'
          ..trackingUrl = trackingUrl
          ..trackingLastCheckedAt = DateTime.now()
          ..labelStatus = 'Label created'
          ..fulfillmentStatus = 'Label created'
          ..status = 'Label created'
          ..shippingCarrier = carrier;
        if (result.postage > 0) {
          order.shippingTotal = result.postage;
        }
        if (result.estimatedDays.trim().isNotEmpty) {
          _notifications.insert(
            0,
            StoreNotification(
              id: 'N-${DateTime.now().millisecondsSinceEpoch}-${order.id}-label',
              type: 'shipping',
              title: '$carrier label created',
              message: result.trackingNumber.trim().isNotEmpty
                  ? '${order.id} $carrier label created for ${result.trackingNumber} (${result.estimatedDays}).'
                  : '${order.id} address label created (${result.estimatedDays}).',
              createdAt: DateTime.now(),
            ),
          );
        }
      });
      await _gateway.upsertOrder(_orderRow(order));
      unawaited(_sendOrderEmail(order, 'label_created'));
      return result;
    } catch (error) {
      final notification = StoreNotification(
        id: 'N-${DateTime.now().millisecondsSinceEpoch}-${order.id}-label-failed',
        type: 'shipping',
        title: 'Label creation failed',
        message: '${order.id} label creation failed: $error',
        createdAt: DateTime.now(),
      );
      if (mounted) {
        setState(() => _notifications.insert(0, notification));
      }
      unawaited(_gateway.insertNotification(notification.toRow()));
      rethrow;
    }
  }

  bool _orderBlocksFulfillment(Order order) {
    final status = order.status.trim().toLowerCase();
    final financial = order.financialStatus.trim().toLowerCase();
    final fulfillment = order.fulfillmentStatus.trim().toLowerCase();
    return status == 'cancelled' ||
        status == 'refunded' ||
        financial == 'refunded' ||
        fulfillment == 'cancelled';
  }

  void _validateShippingAddressForLabel(Order order) {
    final address = order.shippingAddress;
    final recipient = [
      address.firstName,
      address.lastName,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    if ((recipient.isEmpty && order.customer.trim().isEmpty) ||
        address.addressLine1.trim().isEmpty ||
        address.city.trim().isEmpty ||
        address.state.trim().isEmpty ||
        address.postalCode.trim().isEmpty ||
        address.country.trim().isEmpty) {
      throw StateError(
        'Shipping label requires recipient name, street, city, state, postal code, and country.',
      );
    }
  }

  String _trackingUrlForCarrier({
    required String carrier,
    required String trackingNumber,
  }) {
    final tracking = trackingNumber.trim();
    if (tracking.isEmpty) {
      return '';
    }
    final encoded = Uri.encodeComponent(tracking);
    return switch (carrier.trim().toUpperCase()) {
      'UPS' => 'https://www.ups.com/track?tracknum=$encoded',
      'FEDEX' => 'https://www.fedex.com/fedextrack/?trknbr=$encoded',
      'DHL' =>
        'https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=$encoded',
      _ => 'https://tools.usps.com/go/TrackConfirmAction?tLabels=$encoded',
    };
  }

  ShippingLabelResult _createAddressOnlyLabel(Order order, String carrier) {
    final title = 'Address label ${order.id}';
    printHtmlDocument(title, _addressLabelHtml(order, carrier, _storeInfo));
    return const ShippingLabelResult(
      trackingNumber: '',
      labelStatus: 'Label created',
      labelFileName: '',
      labelContentType: 'text/html',
      labelBase64: '',
      estimatedDays: 'Address label only (no postage)',
      postage: 0,
    );
  }

  Map<String, dynamic> _reviewRow(ReviewSummary review) {
    return {
      'scope': review.scope,
      'product_id': review.productId,
      'customer_email': review.customerEmail,
      'author': review.author,
      'rating': review.rating.round().clamp(1, 5),
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
      'buy_quantity': coupon.buyQuantity,
      'get_quantity': coupon.getQuantity,
      'get_price': coupon.getPrice,
      'remaining_balance': coupon.remainingBalance,
      'recipient_email': coupon.recipientEmail,
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
      // Stored in the existing webhook_url column for backward compatibility.
      'webhook_url': method.checkoutUrl,
      'statement_descriptor': method.statementDescriptor,
    };
  }

  Future<void> _updateReview(ReviewSummary review, String status) async {
    final previousStatus = review.status;
    final isDeleteAction = status == 'delete';
    try {
      if (isDeleteAction) {
        await _gateway.deleteReview('${review.id}');
      } else {
        await _gateway.updateReviewStatus('${review.id}', status);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        if (isDeleteAction) {
          _productReviews.removeWhere((item) => item.id == review.id);
          _companyReviews.removeWhere((item) => item.id == review.id);
        } else {
          review.status = status;
        }
        _notifications.insert(
          0,
          StoreNotification(
            id: 'N-${DateTime.now().millisecondsSinceEpoch}',
            type: 'review',
            title: isDeleteAction ? 'Review deleted' : 'Review $status',
            message: isDeleteAction
                ? '${review.author} review was deleted.'
                : '${review.author} review marked $status.',
            createdAt: DateTime.now(),
          ),
        );
      });
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
    unawaited(_sendManualCustomerEmail(audience, subject, body));
  }

  Future<void> _syncInboundEmail() async {
    try {
      final result = await _gateway.syncInboundEmail();
      final rows = await _gateway.fetchEmailMessages();
      if (!mounted) {
        return;
      }
      setState(() {
        _emailMessages
          ..clear()
          ..addAll(rows.map(EmailMessage.fromRow));
      });
      final imported = result['imported'] ?? result['synced'] ?? 0;
      _showStatusSnack('Inbox synced. $imported new message(s).');
    } catch (error) {
      _showStatusSnack('Inbox sync failed: $error');
    }
  }

  void _markEmailMessageRead(EmailMessage message, bool isRead) {
    setState(() => message.isRead = isRead);
    unawaited(
      _gateway
          .updateEmailMessageReadStatus(message.id, isRead)
          .catchError((_) {}),
    );
  }

  Future<void> _sendManualCustomerEmail(
    String audience,
    String subject,
    String body,
  ) async {
    final recipients = _emailRecipientsForAudience(audience);
    if (recipients.isEmpty) {
      _showStatusSnack('No email recipients found for $audience.');
      return;
    }
    try {
      final htmlBody = _manualEmailHtml(
        subject.trim().isEmpty ? 'EgbeAnom update' : subject.trim(),
        body,
      );
      await _gateway.sendEmail(
        kind: 'manual',
        recipients: recipients,
        subject: subject.trim().isEmpty ? 'EgbeAnom update' : subject.trim(),
        htmlBody: htmlBody,
        textBody: _plainTextFromHtml(htmlBody),
      );
      _recordEmailNotification(
        title: 'Email sent',
        message: '$subject sent to ${recipients.length} recipient(s).',
      );
      _showStatusSnack('Email sent to ${recipients.length} recipient(s).');
    } catch (error) {
      _recordEmailNotification(
        title: 'Email failed',
        message: '$subject failed for $audience: $error',
      );
      _showStatusSnack('Email send failed: $error');
    }
  }

  List<String> _emailRecipientsForAudience(String audience) {
    final cleanAudience = audience.trim().toLowerCase();
    if (cleanAudience == 'non-account mailing list') {
      return _nonAccountMailingListRecipients();
    }
    if (cleanAudience == 'account mailing list') {
      return _accountMailingListRecipients();
    }
    if (cleanAudience == 'all mailing list' ||
        cleanAudience == 'mailing list') {
      return {
        ..._accountMailingListRecipients(),
        ..._nonAccountMailingListRecipients(),
      }.toList();
    }
    if (Validators.validateEmail(cleanAudience) == null) {
      return [cleanAudience];
    }
    Iterable<CustomerAccount> matches;
    if (cleanAudience == 'all customers') {
      matches = _customers;
    } else if (cleanAudience == 'vip customers') {
      matches = _customers.where(
        (customer) => customer.segment.toLowerCase().contains('vip'),
      );
    } else if (cleanAudience == 'new customers') {
      matches = _customers.where((customer) => customer.isNew);
    } else {
      matches = _customers.where(
        (customer) => customer.email.toLowerCase() == cleanAudience,
      );
    }
    return matches
        .map((customer) => customer.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _accountMailingListRecipients() {
    return _customers
        .where((customer) => customer.acceptsMarketing)
        .map((customer) => customer.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _nonAccountMailingListRecipients() {
    final accountEmails = _customers
        .map((customer) => customer.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    return _mailingListSubscribers
        .where((subscriber) => subscriber.isActive)
        .map((subscriber) => subscriber.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty && !accountEmails.contains(email))
        .toSet()
        .toList();
  }

  Future<void> _updateAccountMailingList(bool subscribed) async {
    final customer = _currentCustomer;
    if (customer == null) {
      return;
    }
    await _upsertCustomer(customer.copyWith(acceptsMarketing: subscribed));
  }

  Future<void> _joinMailingList(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final emailError = Validators.validateEmail(cleanEmail);
    if (emailError != null) {
      _showStatusSnack(emailError);
      throw StateError(emailError);
    }
    final subscriber = MailingListSubscriber(
      email: cleanEmail,
      source: currentClientSourceType(),
      isActive: true,
    );
    try {
      await _gateway.upsertMailingListSubscriber(subscriber.toRow());
      setState(() {
        final index = _mailingListSubscribers.indexWhere(
          (item) => item.email == cleanEmail,
        );
        if (index == -1) {
          _mailingListSubscribers.insert(0, subscriber);
        } else {
          _mailingListSubscribers[index] = subscriber;
        }
      });
      _showStatusSnack('You are on the mailing list.');
    } catch (error) {
      _showStatusSnack('Mailing list signup failed: $error');
      rethrow;
    }
  }

  Future<void> _sendOrderEmail(Order order, String event) async {
    if (order.email.trim().isEmpty) {
      return;
    }
    final subject = _orderEmailSubject(order, event);
    final htmlBody = _orderEmailHtml(order, event);
    try {
      await _gateway.sendEmail(
        kind: 'order_event',
        recipients: [order.email.trim().toLowerCase()],
        subject: subject,
        htmlBody: htmlBody,
        textBody: _plainTextFromHtml(htmlBody),
        orderId: order.id,
        event: event,
      );
      _recordEmailNotification(
        title: 'Customer email sent',
        message: '$subject sent to ${order.email}.',
      );
    } catch (error) {
      _recordEmailNotification(
        title: 'Customer email failed',
        message: '$subject failed for ${order.email}: $error',
      );
    }
  }

  String? _emailEventForFulfillmentChange(String? previous, String current) {
    final before = _normalizeFulfillmentStatus(previous ?? '').toLowerCase();
    final after = _normalizeFulfillmentStatus(current).toLowerCase();
    if (before == after) {
      return null;
    }
    return switch (after) {
      'processing' => 'processing',
      'label created' => 'label_created',
      'shipped' => 'sent',
      _ => null,
    };
  }

  String? _emailEventForReturnChange(String? previous, String current) {
    final before = (previous ?? '').trim().toLowerCase();
    final after = current.trim().toLowerCase();
    if (before == after) {
      return null;
    }
    return switch (after) {
      'awaiting return item' => 'return_approved',
      'return approved' => 'return_approved',
      'return rejected' => 'return_denied',
      _ => null,
    };
  }

  String _orderEmailSubject(Order order, String event) {
    return switch (event) {
      'payment_success' => 'Your EgbeAnom invoice for order ${order.id}',
      'payment_failed' => 'Your EgbeAnom payment was not completed',
      'processing' => 'Your EgbeAnom order is being prepared',
      'label_created' => 'Your EgbeAnom shipping label is ready',
      'sent' => 'Your EgbeAnom order is on the way',
      'return_approved' => 'Your EgbeAnom return was approved',
      'return_denied' => 'Your EgbeAnom return request update',
      _ => 'EgbeAnom order update ${order.id}',
    };
  }

  String _orderEmailHtml(Order order, String event) {
    final escapedOrderId = htmlEscape.convert(order.id);
    final tracking = order.trackingNumber.trim().isEmpty
        ? 'Tracking will be shared as soon as it is available.'
        : '${htmlEscape.convert(order.shippingCarrier)} ${htmlEscape.convert(order.trackingNumber)}';
    final intro = switch (event) {
      'payment_success' =>
        'Thank you for your purchase. Your payment was received and your invoice is below.',
      'payment_failed' =>
        'Your payment was not completed. You can return to your cart and try another payment method when you are ready.',
      'processing' => 'Your order is now being picked and packed with care.',
      'label_created' =>
        'Your shipping label has been created. Tracking information is below.',
      'sent' => 'Your order has been marked as sent and is on the way.',
      'return_approved' =>
        'Your return request was approved. Your RMA number is ${htmlEscape.convert(order.rmaNumber)}. Print the RMA/return label from your account and include the RMA in your package.',
      'return_denied' =>
        'Your return request was reviewed and could not be approved. ${htmlEscape.convert(order.returnAdminComment)}',
      _ => 'Your order has been updated.',
    };
    final rows = order.lines.isEmpty
        ? '<tr><td><strong>EgbeAnom order</strong><br><em>Fragrance order</em></td><td>${order.itemCount}</td><td>${currency(order.total)}</td></tr>'
        : order.lines
              .map(
                (line) =>
                    '<tr><td><strong>${htmlEscape.convert(line.product.name)}</strong><br><em>${htmlEscape.convert(line.product.concentration)}</em><br><span>${htmlEscape.convert(line.sku)} • ${htmlEscape.convert(line.size)}</span></td><td>${line.quantity}</td><td>${currency(line.total)}</td></tr>',
              )
              .join();
    final tax = _orderTaxTotal(order);
    final summaryRows = [
      _emailSummaryRow('SUBTOTAL', currency(order.subtotal)),
      if (order.discountTotal > 0)
        _emailSummaryRow('DISCOUNT', '-${currency(order.discountTotal)}'),
      _emailSummaryRow('SHIPPING', currency(order.shippingTotal)),
      _emailSummaryRow('TAX', currency(tax)),
      _emailSummaryRow('TOTAL', currency(order.total), grand: true),
    ].join();
    final trackingBlock = (event == 'label_created' || event == 'sent')
        ? '<p class="email-note"><strong>Tracking:</strong> $tracking</p>'
        : '';
    final rmaBlock = event == 'return_approved'
        ? '<p class="email-note"><strong>RMA:</strong> ${htmlEscape.convert(order.rmaNumber)}</p>'
        : '';
    return _egbeEmailShell(
      title: 'Order $escapedOrderId',
      preheader: intro,
      bodyHtml:
          '''
        <p class="email-intro">$intro</p>
        <table class="email-table">
          <thead>
            <tr><th>Item Description</th><th>Qty</th><th>Total</th></tr>
          </thead>
          <tbody>$rows</tbody>
        </table>
        <table class="email-summary">$summaryRows</table>
        $trackingBlock
        $rmaBlock
      ''',
    );
  }

  String _manualEmailHtml(String subject, String body) {
    return _egbeEmailShell(
      title: htmlEscape.convert(subject),
      preheader: _plainTextFromHtml(body),
      bodyHtml: _manualEmailBodyContent(body),
    );
  }

  String _manualEmailBodyContent(String body) {
    final trimmed = body.trim();
    final bodyMatch = RegExp(
      r'<body[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (bodyMatch != null) {
      return bodyMatch.group(1) ?? '';
    }
    final looksHtml = RegExp(
      r'<[a-z][\s\S]*>',
      caseSensitive: false,
    ).hasMatch(trimmed);
    if (looksHtml) {
      return trimmed;
    }
    return '<p class="email-intro">${htmlEscape.convert(trimmed).replaceAll('\n', '<br>')}</p>';
  }

  String _emailSummaryRow(String label, String value, {bool grand = false}) {
    return '<tr class="${grand ? 'grand' : ''}"><td>$label</td><td>$value</td></tr>';
  }

  String _egbeEmailShell({
    required String title,
    required String preheader,
    required String bodyHtml,
  }) {
    final storeName = htmlEscape.convert(_storeInfo.displayName);
    final logoUrl = htmlEscape.convert(_storeInfo.logoUrl.trim());
    final logoHtml = logoUrl.isEmpty
        ? ''
        : '<td class="email-logo-cell"><img class="email-logo" src="$logoUrl" alt="$storeName logo"></td>';
    final contact = [_storeInfo.email, _storeInfo.phone]
        .where((item) => item.trim().isNotEmpty)
        .map(htmlEscape.convert)
        .join(' • ');
    final address = _emailFooterAddress();
    final unsubscribeEmail = _storeInfo.email.trim().isEmpty
        ? 'support@egbeanom.com'
        : _storeInfo.email.trim();
    final unsubscribeHref =
        'mailto:${Uri.encodeComponent(unsubscribeEmail)}'
        '?subject=${Uri.encodeComponent('Unsubscribe from EgbeAnom emails')}';
    final appOrigin = Uri.base.hasScheme && Uri.base.host.isNotEmpty
        ? Uri.base.origin
        : '';
    final qrCodeUrl = appOrigin.isEmpty
        ? 'assets/assets/images/egbeanom_qr_code.png'
        : '$appOrigin/assets/assets/images/egbeanom_qr_code.png';
    final safePreheader = htmlEscape.convert(preheader);
    return '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      body { margin: 0; padding: 0; background: #f7f2e8; color: #121212; font-family: Arial, sans-serif; }
      .preheader { display: none; max-height: 0; overflow: hidden; opacity: 0; color: transparent; }
      .email-doc { max-width: 840px; margin: 0 auto; background: #fff; border: 1px solid #b7892f; }
      .email-top { background: #fff; color: #121212; padding: 30px 38px 24px; border-bottom: 3px solid #d3a13c; }
      .email-brand-table { width: 100%; border-collapse: collapse; }
      .email-brand-table td { vertical-align: middle; padding: 0; }
      .email-brand { font-family: Georgia, 'Times New Roman', serif; font-size: 42px; line-height: 1; font-weight: 400; margin: 0; }
      .email-tagline { color: #333; font-family: Georgia, 'Times New Roman', serif; font-size: 17px; line-height: 1.35; margin: 10px 0 0; }
      .email-logo-cell { width: 112px; text-align: right; padding-left: 18px !important; }
      .email-logo { display: inline-block; width: 96px; max-width: 96px; height: auto; border: 0; }
      .email-body { padding: 34px 42px; }
      .email-title { color: #b8842b; text-transform: uppercase; letter-spacing: 1px; font-size: 22px; margin: 0 0 14px; }
      .email-intro { font-size: 16px; line-height: 1.5; margin: 0 0 18px; }
      .email-table { width: 100%; border-collapse: collapse; margin-top: 18px; }
      .email-table th { background: transparent; color: #7d5a1e; border: 1px solid #d8bd80; padding: 12px; text-align: left; text-transform: uppercase; font-size: 13px; }
      .email-table td { border: 1px solid #d8bd80; padding: 12px; vertical-align: top; font-size: 15px; }
      .email-table em { font-family: Georgia, 'Times New Roman', serif; color: #333; }
      .email-table span { color: #555; font-size: 12px; }
      .email-summary { width: 100%; border-collapse: collapse; margin-top: 18px; }
      .email-summary td { border: 1px solid #d8bd80; padding: 12px 16px; font-size: 15px; }
      .email-summary td:last-child { text-align: right; }
      .email-summary .grand td { font-size: 20px; font-weight: 700; }
      .email-note { border: 1px solid #d8bd80; padding: 12px 16px; margin: 18px 0 0; }
      .email-footer { border-top: 1px solid #d8bd80; padding: 22px 42px 28px; font-size: 13px; color: #555; }
      .email-footer-title { color: #b8842b; text-transform: uppercase; font-weight: 700; margin-bottom: 6px; }
      .email-footer p { margin: 8px 0 0; line-height: 1.45; }
      .email-footer a { color: #7d5a1e; font-weight: 700; }
      .email-footer-small { font-size: 12px; color: #666; }
      .email-footer-table { width: 100%; border-collapse: collapse; }
      .email-footer-table td { vertical-align: bottom; padding: 0; }
      .email-footer-qr-cell { width: 128px; text-align: right; padding-left: 24px !important; }
      .email-footer-qr { width: 112px; max-width: 112px; height: auto; border: 1px solid #d8bd80; display: inline-block; }
      @media only screen and (max-width: 620px) {
        .email-doc { width: 100% !important; border-left: 0 !important; border-right: 0 !important; }
        .email-top, .email-body, .email-footer { padding-left: 20px !important; padding-right: 20px !important; }
        .email-brand { font-size: 32px !important; }
        .email-logo-cell { width: 78px !important; padding-left: 10px !important; }
        .email-logo { width: 68px !important; max-width: 68px !important; }
        .email-footer-qr-cell { width: 76px !important; padding-left: 10px !important; }
        .email-footer-qr { width: 64px !important; max-width: 64px !important; }
      }
    </style>
  </head>
  <body>
    <div class="preheader">$safePreheader</div>
    <div class="email-doc">
      <div class="email-top">
        <table class="email-brand-table" role="presentation">
          <tr>
            <td>
              <h1 class="email-brand">$storeName</h1>
              <p class="email-tagline">Where Elegance Speaks.<br>Scents Last Forever.</p>
            </td>
            $logoHtml
          </tr>
        </table>
      </div>
      <div class="email-body">
        <h2 class="email-title">$title</h2>
        $bodyHtml
      </div>
      <div class="email-footer">
        <table class="email-footer-table" role="presentation">
          <tr>
            <td>
              <div class="email-footer-title">Customer Support</div>
              ${contact.isEmpty ? 'Thank you for choosing EgbeAnom.' : contact}
              ${address.isEmpty ? '' : '<p>$address</p>'}
              <p>
                You are receiving this email because you purchased from EgbeAnom,
                created an account, requested an update, or joined our mailing list.
              </p>
              <p>
                To stop receiving marketing emails, reply with "Unsubscribe" or email
                <a href="$unsubscribeHref">$unsubscribeEmail</a>.
              </p>
              <p class="email-footer-small">
                Order, payment, shipping, return, refund, account, and security emails
                may still be sent when needed to service your account or purchase.
              </p>
              <p>Thank you for choosing EgbeAnom.</p>
            </td>
            <td class="email-footer-qr-cell">
              <img class="email-footer-qr" src="$qrCodeUrl" alt="EgbeAnom website QR code">
            </td>
          </tr>
        </table>
      </div>
    </div>
  </body>
</html>
''';
  }

  String _emailFooterAddress() {
    final parts =
        [
              _storeInfo.addressLine1,
              _storeInfo.addressLine2,
              [
                _storeInfo.city,
                _storeInfo.state,
                _storeInfo.postalCode,
              ].where((item) => item.trim().isNotEmpty).join(' '),
              _storeInfo.country,
            ]
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .map(htmlEscape.convert)
            .toList();
    return parts.isEmpty ? '' : parts.join('<br>');
  }

  String _plainTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _recordEmailNotification({
    required String title,
    required String message,
  }) {
    if (!mounted) {
      return;
    }
    final notification = StoreNotification(
      id: 'N-${DateTime.now().millisecondsSinceEpoch}-email',
      type: 'email',
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    setState(() {
      _notifications.insert(0, notification);
    });
    unawaited(_gateway.insertNotification(notification.toRow()));
  }

  void _recordAdminAudit({
    required String action,
    required String entityType,
    required String entityId,
    required String summary,
    Map<String, dynamic> metadata = const {},
  }) {
    unawaited(
      _gateway
          .insertAdminAuditLog({
            'action': action,
            'entity_type': entityType,
            'entity_id': entityId,
            'summary': summary,
            'metadata': metadata,
          })
          .catchError((_) {}),
    );
  }

  Future<void> _updateEmailSettings(EmailServerSettings settings) async {
    setState(() {
      _emailSettings
        ..provider = settings.provider
        ..fromName = settings.fromName
        ..fromEmail = settings.fromEmail
        ..imapHost = settings.imapHost
        ..imapPort = settings.imapPort
        ..smtpHost = settings.smtpHost
        ..smtpPort = settings.smtpPort
        ..username = settings.username
        ..password = settings.password
        ..useSsl = settings.useSsl;
    });
    try {
      await _gateway.upsertEmailServerSettings(_emailSettings.toJson());
      _recordAdminAudit(
        action: 'update',
        entityType: 'email_settings',
        entityId: _emailSettings.provider,
        summary: 'Email SMTP settings updated',
      );
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
      _recordAdminAudit(
        action: 'update',
        entityType: 'shipping_credentials',
        entityId: carrier,
        summary: '$carrier shipping credentials updated',
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
      showMailingListSignup: _siteStatus.showMailingListSignup,
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
        ..showMailingListSignup = status.showMailingListSignup
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
            ..showMailingListSignup = previous.showMailingListSignup
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
      _recordAdminAudit(
        action: 'upsert',
        entityType: 'backend_user',
        entityId: user.id,
        summary: 'Backend user saved: ${user.email}',
        metadata: {'role': user.role, 'is_active': user.isActive},
      );
      _showStatusSnack('Backend user saved.');
    } catch (error) {
      _showStatusSnack('Backend user save failed: $error');
    }
  }

  Future<void> _upsertCustomer(CustomerAccount customer) async {
    final previousCustomerEmail = _currentCustomer?.id == customer.id
        ? _currentCustomer?.email.trim().toLowerCase()
        : null;
    final emailError = Validators.validateEmail(customer.email);
    if (emailError != null) {
      _showStatusSnack('Customer save failed: $emailError');
      return;
    }
    if (customer.addressLine1.trim().isNotEmpty ||
        customer.city.trim().isNotEmpty ||
        customer.state.trim().isNotEmpty ||
        customer.postalCode.trim().isNotEmpty) {
      final addressError = Validators.validateAddress(
        customer.addressLine1,
        customer.city,
        customer.state,
        customer.postalCode,
      );
      if (addressError != null) {
        _showStatusSnack('Customer save failed: $addressError');
        return;
      }
    }
    setState(() {
      final index = _customers.indexWhere((item) => item.id == customer.id);
      if (index == -1) {
        _customers.add(customer);
      } else {
        _customers[index] = customer;
      }
      if (_currentCustomer?.id == customer.id) {
        _currentCustomer = customer;
        if (previousCustomerEmail != null &&
            previousCustomerEmail != customer.email.trim().toLowerCase()) {
          for (final order in _orders.where(
            (order) =>
                order.email.trim().toLowerCase() == previousCustomerEmail,
          )) {
            order.email = customer.email;
          }
        }
        _checkoutEmail = customer.email;
        _checkoutPhone = customer.phone;
        _checkoutShippingAddress = ShippingAddress(
          firstName: customer.name.split(' ').first,
          lastName: customer.name.split(' ').skip(1).join(' '),
          addressLine1: customer.addressLine1,
          addressLine2: customer.addressLine2,
          city: customer.city,
          county: customer.county,
          state: customer.state,
          postalCode: customer.postalCode,
          country: customer.country,
          email: customer.email,
          phone: customer.phone,
        );
      }
    });
    try {
      await _gateway.upsertCustomer(customer.toRow());
      _recordAdminAudit(
        action: 'upsert',
        entityType: 'customer',
        entityId: customer.id,
        summary: 'Customer saved: ${customer.email}',
      );
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
    _syncActiveCart();
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
      _recordAdminAudit(
        action: 'toggle',
        entityType: 'payment_method',
        entityId: method.provider,
        summary: '${method.name} ${method.isEnabled ? 'enabled' : 'disabled'}',
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
        'checkoutUrl': method.checkoutUrl,
        'webhookUrl': method.webhookUrl,
      });
      _recordAdminAudit(
        action: 'upsert',
        entityType: 'payment_settings',
        entityId: method.provider,
        summary: 'Payment method saved: ${method.name}',
      );
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
      _recordAdminAudit(
        action: 'upsert',
        entityType: 'shipping_option',
        entityId: option.id,
        summary: 'Shipping option saved: ${option.name}',
      );
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
      _recordAdminAudit(
        action: 'delete',
        entityType: 'shipping_option',
        entityId: option.id,
        summary: 'Shipping option deleted: ${option.name}',
      );
      _showStatusSnack('Shipping option deleted.');
    } catch (error) {
      _showStatusSnack('Shipping option delete failed: $error');
    }
  }

  Future<void> _saveStoreInfo(StoreInfo info) async {
    setState(() => _storeInfo = info);
    await _gateway.upsertStoreInfo(info.toRow());
    _recordAdminAudit(
      action: 'update',
      entityType: 'store_info',
      entityId: 'primary',
      summary: 'Store information updated',
    );
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
    _recordAdminAudit(
      action: 'upsert',
      entityType: 'tax_rule',
      entityId: rule.id,
      summary: 'Tax rule saved: ${rule.name}',
    );
  }

  Future<void> _deleteTaxRule(TaxRule rule) async {
    setState(() {
      _taxRules.removeWhere((item) => item.id == rule.id);
    });
    await _gateway.deleteTaxRule(rule.id);
    _recordAdminAudit(
      action: 'delete',
      entityType: 'tax_rule',
      entityId: rule.id,
      summary: 'Tax rule deleted: ${rule.name}',
    );
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

  int get _adminUnreadNotificationCount =>
      _notifications.where((notification) => !notification.isRead).length;

  int get _pendingReviewCount => [
    ..._productReviews,
    ..._companyReviews,
  ].where((review) => review.status.toLowerCase() == 'pending').length;

  int get _returnRequestCount =>
      _orders.where((order) => order.returnStatus == 'Return requested').length;

  Map<AdminSection, int> get _adminSectionAttentionCounts {
    final unreadByType = <String, int>{};
    for (final notification in _notifications) {
      if (notification.isRead) {
        continue;
      }
      final type = notification.type.trim().toLowerCase();
      unreadByType[type] = (unreadByType[type] ?? 0) + 1;
    }

    final orderNotificationCount =
        (unreadByType['order'] ?? 0) +
        (unreadByType['payment'] ?? 0) +
        (unreadByType['return'] ?? 0) +
        (unreadByType['shipping'] ?? 0);
    final reviewNotificationCount = unreadByType['review'] ?? 0;
    final emailNotificationCount =
        (unreadByType['email'] ?? 0) +
        (unreadByType['contact'] ?? 0) +
        _emailMessages.where((message) => !message.isRead).length;

    final counts = <AdminSection, int>{};
    void add(AdminSection section, int count) {
      if (count > 0) {
        counts[section] = count;
      }
    }

    add(AdminSection.notifications, _adminUnreadNotificationCount);
    add(
      AdminSection.orders,
      orderNotificationCount > _returnRequestCount
          ? orderNotificationCount
          : _returnRequestCount,
    );
    add(
      AdminSection.reviews,
      reviewNotificationCount > _pendingReviewCount
          ? reviewNotificationCount
          : _pendingReviewCount,
    );
    add(AdminSection.email, emailNotificationCount);
    return counts;
  }

  void _startAdminAttentionPolling() {
    _adminNotificationPollTimer?.cancel();
    _adminNotificationPollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshAdminAttention()),
    );
  }

  Future<void> _refreshAdminAttention() async {
    if (_currentBackendUser == null || _pollingAdminAttention) {
      return;
    }
    _pollingAdminAttention = true;
    final knownNotificationIds = _notifications
        .map((notification) => notification.id)
        .toSet();
    final knownOrderIds = _orders.map((order) => order.id).toSet();
    try {
      final notificationRows = await _gateway.fetchNotifications();
      final incomingNotifications = notificationRows
          .map(StoreNotification.fromRow)
          .where(
            (notification) => !knownNotificationIds.contains(notification.id),
          )
          .toList();
      if (incomingNotifications.isNotEmpty && mounted) {
        setState(() {
          _notifications.insertAll(0, incomingNotifications);
        });
        for (final notification in incomingNotifications) {
          _presentAdminNotificationAlert(notification);
        }
      }

      final orderRows = await _gateway.fetchOrders();
      final incomingOrders = orderRows
          .map(Order.fromRow)
          .where((order) => !knownOrderIds.contains(order.id))
          .toList();
      if (incomingOrders.isNotEmpty && mounted) {
        setState(() {
          _orders.insertAll(0, incomingOrders);
        });
        for (final order in incomingOrders) {
          _recordOrderReceivedNotification(order);
        }
      }
    } catch (_) {
      // Polling should never interrupt an active admin session.
    } finally {
      _pollingAdminAttention = false;
    }
  }

  void _addAdminNotification(
    StoreNotification notification, {
    bool persist = false,
    bool urgent = false,
  }) {
    if (_notifications.any((item) => item.id == notification.id)) {
      return;
    }
    if (mounted) {
      setState(() => _notifications.insert(0, notification));
    } else {
      _notifications.insert(0, notification);
    }
    if (persist) {
      unawaited(
        _gateway.insertNotification(notification.toRow()).catchError((_) {}),
      );
    }
    if (urgent) {
      _presentAdminNotificationAlert(notification);
    }
  }

  AdminSection _adminSectionForNotification(StoreNotification notification) {
    return switch (notification.type.trim().toLowerCase()) {
      'order' || 'payment' || 'return' || 'shipping' => AdminSection.orders,
      'review' => AdminSection.reviews,
      'email' || 'contact' => AdminSection.email,
      _ => AdminSection.notifications,
    };
  }

  void _openAdminNotification(StoreNotification notification) {
    _markNotificationRead(notification);
    _openAdminSection(_adminSectionForNotification(notification));
  }

  void _presentAdminNotificationAlert(StoreNotification notification) {
    if (_currentBackendUser == null) {
      return;
    }
    showAdminBrowserAlert(
      title: notification.title,
      body: notification.message,
    );
    playAdminAlertSound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentBackendUser == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          behavior: SnackBarBehavior.floating,
          content: Text('${notification.title}: ${notification.message}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openAdminNotification(notification),
          ),
        ),
      );
    });
  }

  Future<void> _enableAdminBrowserAlerts() async {
    final enabled = await requestAdminBrowserAlertPermission();
    if (!mounted) {
      return;
    }
    if (enabled) {
      showAdminBrowserAlert(
        title: 'EgbeAnom admin alerts enabled',
        body: 'New orders and urgent admin items will notify this computer.',
      );
      playAdminAlertSound();
      _showStatusSnack('Browser notifications and sound are enabled.');
    } else {
      _showStatusSnack(
        'Browser notifications were not enabled. Check this browser permission.',
      );
    }
  }

  void _openAdminSection(AdminSection section) {
    setState(() {
      _adminInitialSection = section;
      _view = StoreView.admin;
    });
  }

  void _markNotificationRead(StoreNotification notification) {
    if (notification.isRead) {
      return;
    }
    setState(() => notification.isRead = true);
    unawaited(
      _gateway
          .updateNotificationReadStatus(notification.id, true)
          .catchError((_) {}),
    );
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
            _AdminNotificationBell(
              unreadCount: _adminUnreadNotificationCount,
              pendingReviewCount: _pendingReviewCount,
              returnRequestCount: _returnRequestCount,
              notifications: _notifications,
              onOpenNotifications: () =>
                  _openAdminSection(AdminSection.notifications),
              onOpenReviews: () => _openAdminSection(AdminSection.reviews),
              onOpenReturns: () => _openAdminSection(AdminSection.orders),
              onEnableBrowserAlerts: _enableAdminBrowserAlerts,
              onNotificationSelected: (notification) {
                _openAdminNotification(notification);
              },
            ),
          if (_currentBackendUser != null)
            _NavButton(
              label: 'Admin',
              icon: Icons.dashboard_customize_outlined,
              selected: _view == StoreView.admin,
              onPressed: () => _openAdminSection(AdminSection.overview),
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
          customer: _currentCustomer,
          onJoinMailingList: _joinMailingList,
          onUpdateAccountMailingList: _updateAccountMailingList,
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
          discount: _discountTotal,
          taxBreakdown: _taxBreakdown,
          tax: _tax,
          shipping: _shipping,
          total: _cartTotal,
          promoCode: _promoCode,
          appliedCouponCode: _validAppliedCoupon?.code ?? '',
          promoMessage: _promoMessage,
          checkoutEmail: _checkoutEmail,
          checkoutPhone: _checkoutPhone,
          shippingAddress: _checkoutShippingAddress,
          onCheckoutEmailChanged: (value) {
            setState(() => _checkoutEmail = value);
            _syncActiveCart();
          },
          onCheckoutPhoneChanged: (value) {
            setState(() => _checkoutPhone = value);
            _syncActiveCart();
          },
          onShippingAddressChanged: (value) {
            setState(() => _checkoutShippingAddress = value);
            _syncActiveCart();
            unawaited(_refreshSelectedShippingRate());
          },
          onPromoCodeChanged: (value) => setState(() => _promoCode = value),
          onApplyPromoCode: () => unawaited(_applyPromoCode()),
          onRemovePromoCode: _removePromoCode,
          shippingOptions: _enabledShippingOptions,
          selectedShippingOptionId: _selectedShippingOptionId,
          onShippingOptionChanged: (value) {
            setState(() => _selectedShippingOptionId = value);
            unawaited(_refreshSelectedShippingRate());
          },
          onBackToCart: () => setState(() => _view = StoreView.cart),
          onPlaceOrder: () => unawaited(_checkout()),
          onCreateAccountFromCheckout: _currentCustomer == null
              ? (password) => _createCheckoutAccount(password)
              : null,
          creatingAccount: _creatingCheckoutAccount,
          paymentMethods: _paymentMethods
              .where((method) => method.isEnabled)
              .toList(),
          selectedPaymentProvider: _selectedCheckoutPaymentProvider,
          onPaymentProviderChanged: (provider) =>
              setState(() => _selectedCheckoutPaymentProvider = provider),
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
          onSaveCustomer: _upsertCustomer,
          onRequestReturn: _requestOrderReturn,
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
                initialSection: _adminInitialSection,
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
                  ..._marketplaceCarts.where(
                    (cart) => cart.id != 'CART-$_visitorSessionId',
                  ),
                ],
                customers: _customers,
                mailingListSubscribers: _mailingListSubscribers,
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
                emailMessages: _emailMessages,
                sectionAttentionCounts: _adminSectionAttentionCounts,
                siteStatus: _siteStatus,
                storeInfo: _storeInfo,
                taxRules: _taxRules,
                measurementSystem: _siteStatus.measurementSystem,
                backendUsers: _backendUsers,
                activeUserSessions: _activeUserSessions,
                analyticsEvents: _analyticsEvents,
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
                onCreateStripeRefund: _createStripeRefund,
                onCreateShippingLabel: _createShippingLabel,
                onBatchUpdateOrders: _updateOrdersWithEmail,
                onUpdateReview: _updateReview,
                onSendEmail: _sendCustomerEmail,
                onSyncInboundEmail: _syncInboundEmail,
                onEmailMessageRead: _markEmailMessageRead,
                onSaveEmailSettings: _updateEmailSettings,
                onUpdateSiteStatus: _updateSiteStatus,
                onSaveCustomer: _upsertCustomer,
                onBlockIp: _blockIpAddress,
                onSaveBackendUser: _upsertBackendUser,
                onApproveFragranceNote: _approveFragranceNote,
                onNotificationRead: _markNotificationRead,
                onNotificationOpen: _openAdminNotification,
              ),
      StoreView.paymentSuccess => _storefrontGate(
        PaymentReturnView(
          isSuccess: true,
          onContinueShopping: () => setState(() => _view = StoreView.shop),
          onViewAccount: () => setState(() => _view = StoreView.account),
          completedOrder: _paymentReturnOrderForCurrentRoute(),
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

class _AdminNotificationBell extends StatelessWidget {
  const _AdminNotificationBell({
    required this.unreadCount,
    required this.pendingReviewCount,
    required this.returnRequestCount,
    required this.notifications,
    required this.onOpenNotifications,
    required this.onOpenReviews,
    required this.onOpenReturns,
    required this.onEnableBrowserAlerts,
    required this.onNotificationSelected,
  });

  final int unreadCount;
  final int pendingReviewCount;
  final int returnRequestCount;
  final List<StoreNotification> notifications;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenReturns;
  final VoidCallback onEnableBrowserAlerts;
  final ValueChanged<StoreNotification> onNotificationSelected;

  int get _attentionCount =>
      unreadCount + pendingReviewCount + returnRequestCount;

  @override
  Widget build(BuildContext context) {
    final recentUnread = notifications
        .where((notification) => !notification.isRead)
        .take(5)
        .toList();
    return PopupMenuButton<Object>(
      tooltip: 'Admin notifications',
      offset: const Offset(0, 46),
      onSelected: (value) {
        if (value == 'alerts') {
          onOpenNotifications();
        } else if (value == 'reviews') {
          onOpenReviews();
        } else if (value == 'returns') {
          onOpenReturns();
        } else if (value == 'browser-alerts') {
          onEnableBrowserAlerts();
        } else if (value is StoreNotification) {
          onNotificationSelected(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<Object>(
          enabled: false,
          child: Text(
            _attentionCount == 0
                ? 'No urgent admin alerts'
                : '$_attentionCount admin alert(s)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (pendingReviewCount > 0)
          PopupMenuItem<Object>(
            value: 'reviews',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Reviews awaiting approval'),
              trailing: Text('$pendingReviewCount'),
            ),
          ),
        if (returnRequestCount > 0)
          PopupMenuItem<Object>(
            value: 'returns',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_return_outlined),
              title: const Text('Return requests'),
              trailing: Text('$returnRequestCount'),
            ),
          ),
        if (recentUnread.isEmpty)
          const PopupMenuItem<Object>(
            enabled: false,
            child: Text('No unread notification messages.'),
          )
        else
          for (final notification in recentUnread)
            PopupMenuItem<Object>(
              value: notification,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_notificationIcon(notification.type)),
                title: Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        const PopupMenuDivider(),
        const PopupMenuItem<Object>(
          value: 'browser-alerts',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.campaign_outlined),
            title: Text('Enable desktop alerts'),
            subtitle: Text('Browser notification with sound'),
          ),
        ),
        const PopupMenuItem<Object>(
          value: 'alerts',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.notifications_outlined),
            title: Text('View all alerts'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              _attentionCount > 0
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              color: Colors.white,
            ),
            if (_attentionCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _attentionCount > 99 ? '99+' : '$_attentionCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _notificationIcon(String type) {
  return switch (type) {
    'order' => Icons.shopping_bag_outlined,
    'return' => Icons.assignment_return_outlined,
    'review' => Icons.rate_review_outlined,
    'email' => Icons.outgoing_mail,
    'payment' => Icons.payments_outlined,
    _ => Icons.notifications_outlined,
  };
}
