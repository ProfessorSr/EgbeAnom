part of 'store_data_gateway_web.dart';

extension StoreDataGatewayFetches on StoreDataGateway {
  Future<List<Map<String, dynamic>>> fetchProducts() =>
      fetchProductsPage(limit: 500);

  Future<List<Map<String, dynamic>>> fetchProductsPage({
    int limit = 100,
    int offset = 0,
    String search = '',
    String categoryId = '',
  }) async {
    final query = {
      'select': '*,product_images(*),product_variants(*)',
      'order': 'sort_order.asc,name.asc',
      'limit': '${_boundedLimit(limit)}',
      'offset': '${_boundedOffset(offset)}',
    };
    final normalizedSearch = search.trim();
    if (normalizedSearch.isNotEmpty) {
      final pattern = _ilikePattern(normalizedSearch);
      query['or'] =
          '(name.ilike.$pattern,sku.ilike.$pattern,type.ilike.$pattern)';
    }
    if (categoryId.trim().isNotEmpty &&
        categoryId.trim().toLowerCase() != 'all') {
      query['category_id'] = 'eq.${categoryId.trim()}';
    }
    final data = await _rest('products', query: query);
    return _rows(data);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() =>
      _list('categories', order: 'sort_order.asc,name.asc');
  Future<List<Map<String, dynamic>>> fetchContentBlocks() =>
      _list('content_blocks', order: 'sort_order.asc,title.asc');
  Future<List<Map<String, dynamic>>> fetchCouponRules() =>
      _list('coupon_rules', order: 'code.asc');
  Future<List<Map<String, dynamic>>> fetchPaymentMethods() =>
      _list('payment_methods', order: 'provider.asc,name.asc');
  Future<List<Map<String, dynamic>>> fetchShippingOptions() =>
      _list('shipping_options', order: 'sort_order.asc,carrier.asc');
  Future<List<Map<String, dynamic>>> fetchTaxRules() =>
      _list('tax_rules', order: 'sort_order.asc,name.asc');
  Future<List<Map<String, dynamic>>> fetchBrands() =>
      _list('brand_profiles', order: 'sort_order.asc,name.asc');
  Future<List<Map<String, dynamic>>> fetchFragranceNotes() =>
      _list('fragrance_notes', order: 'name.asc');
  Future<List<Map<String, dynamic>>> fetchFragranceFamilies() =>
      _list('fragrance_families', order: 'name.asc');
  Future<List<Map<String, dynamic>>> fetchFragranceSeasons() =>
      _list('fragrance_seasons', order: 'sort_order.asc,name.asc');
  Future<List<Map<String, dynamic>>> fetchFragranceOccasions() =>
      _list('fragrance_occasions', order: 'sort_order.asc,name.asc');
  Future<List<Map<String, dynamic>>> fetchOrders() =>
      fetchOrdersPage(limit: 500);

  Future<List<Map<String, dynamic>>> fetchOrdersPage({
    int limit = 100,
    int offset = 0,
    String search = '',
    String status = '',
    String financialStatus = '',
    String shippingPriority = '',
  }) async {
    final query = {
      'select': '*',
      'order': 'created_at.desc',
      'limit': '${_boundedLimit(limit)}',
      'offset': '${_boundedOffset(offset)}',
    };
    final normalizedSearch = search.trim();
    if (normalizedSearch.isNotEmpty) {
      final pattern = _ilikePattern(normalizedSearch);
      query['or'] =
          '(order_number.ilike.$pattern,customer_name.ilike.$pattern,email.ilike.$pattern,tracking_number.ilike.$pattern)';
    }
    if (_isConcreteFilter(status)) {
      query['status'] = 'eq.${status.trim()}';
    }
    if (_isConcreteFilter(financialStatus)) {
      query['financial_status'] = 'eq.${financialStatus.trim()}';
    }
    if (_isConcreteFilter(shippingPriority)) {
      query['shipping_priority'] = 'eq.${shippingPriority.trim()}';
    }
    final orders = _rows(await _rest('orders', query: query));
    try {
      final orderIds = orders
          .map((order) => '${order['order_number'] ?? order['id']}'.trim())
          .where((id) => id.isNotEmpty)
          .toList();
      final items = orderIds.isEmpty
          ? <Map<String, dynamic>>[]
          : _rows(
              await _rest(
                'order_items',
                query: {
                  'select': '*',
                  'order_id': 'in.(${orderIds.join(',')})',
                  'order': 'id.asc',
                },
              ),
            );
      for (final order in orders) {
        final orderKey = '${order['order_number'] ?? order['id']}';
        order['order_items'] = items
            .where((item) => '${item['order_id']}' == orderKey)
            .toList();
      }
    } catch (_) {
      for (final order in orders) {
        order['order_items'] = const <Map<String, dynamic>>[];
      }
    }
    return orders;
  }

  Future<List<Map<String, dynamic>>> fetchCustomerAccounts() =>
      fetchCustomerAccountsPage(limit: 500);
  Future<List<Map<String, dynamic>>> fetchCustomerAccountsPage({
    int limit = 100,
    int offset = 0,
    String search = '',
  }) {
    final query = {
      'select': '*',
      'order': 'name.asc,email.asc',
      'limit': '${_boundedLimit(limit)}',
      'offset': '${_boundedOffset(offset)}',
    };
    final normalizedSearch = search.trim();
    if (normalizedSearch.isNotEmpty) {
      final pattern = _ilikePattern(normalizedSearch);
      query['or'] =
          '(name.ilike.$pattern,email.ilike.$pattern,phone.ilike.$pattern)';
    }
    return _listQuery('store_customers', query);
  }

  Future<List<Map<String, dynamic>>> fetchMailingListSubscribers() =>
      _list('mailing_list_subscribers', order: 'subscribed_at.desc,email.asc');

  Future<List<Map<String, dynamic>>> fetchReviews() =>
      fetchReviewsPage(limit: 500);
  Future<List<Map<String, dynamic>>> fetchReviewsPage({
    int limit = 100,
    int offset = 0,
    String status = '',
    String search = '',
  }) {
    final query = {
      'select': '*',
      'order': 'created_at.desc',
      'limit': '${_boundedLimit(limit)}',
      'offset': '${_boundedOffset(offset)}',
    };
    if (_isConcreteFilter(status)) {
      query['status'] = 'eq.${status.trim()}';
    }
    final normalizedSearch = search.trim();
    if (normalizedSearch.isNotEmpty) {
      final pattern = _ilikePattern(normalizedSearch);
      query['or'] =
          '(customer_name.ilike.$pattern,email.ilike.$pattern,product_name.ilike.$pattern,comment.ilike.$pattern)';
    }
    return _listQuery('store_reviews', query);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() =>
      _list('admin_notifications', order: 'created_at.desc');
  Future<List<Map<String, dynamic>>> fetchDailyMetrics() =>
      fetchDailyMetricsPage(limit: 366);
  Future<List<Map<String, dynamic>>> fetchDailyMetricsPage({
    int limit = 366,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) {
    final query = {
      'select': '*',
      'order': 'day.asc',
      'limit': '${_boundedLimit(limit, max: 1095)}',
      'offset': '${_boundedOffset(offset)}',
    };
    if (from != null && to != null) {
      query['and'] =
          '(day.gte.${from.toIso8601String().split('T').first},day.lte.${to.toIso8601String().split('T').first})';
    } else if (from != null) {
      query['day'] = 'gte.${from.toIso8601String().split('T').first}';
    } else if (to != null) {
      query['day'] = 'lte.${to.toIso8601String().split('T').first}';
    }
    return _listQuery('analytics_daily_metrics', query);
  }

  Future<List<Map<String, dynamic>>> fetchActiveUserSessions() async {
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: 30))
        .toUtc()
        .toIso8601String();
    final data = await _rest(
      'analytics_sessions',
      query: {
        'select': '*',
        'last_seen_at': 'gte.$cutoff',
        'order': 'last_seen_at.desc',
      },
    );
    return _rows(data);
  }

  Future<List<Map<String, dynamic>>> fetchAnalyticsEvents({
    int limit = 1000,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) {
    final query = {
      'select': '*',
      'order': 'occurred_at.desc',
      'limit': '${_boundedLimit(limit, max: 5000)}',
      'offset': '${_boundedOffset(offset)}',
    };
    if (from != null && to != null) {
      query['and'] =
          '(occurred_at.gte.${from.toUtc().toIso8601String()},occurred_at.lte.${to.toUtc().toIso8601String()})';
    } else if (from != null) {
      query['occurred_at'] = 'gte.${from.toUtc().toIso8601String()}';
    } else if (to != null) {
      query['occurred_at'] = 'lte.${to.toUtc().toIso8601String()}';
    }
    return _listQuery('analytics_events', query);
  }

  Future<List<Map<String, dynamic>>> fetchActiveCarts() => _listQuery(
    'active_carts',
    {'select': '*', 'status': 'eq.active', 'order': 'last_seen_at.desc'},
  );
  Future<List<Map<String, dynamic>>> fetchEmailMessages() =>
      _list('email_messages', order: 'received_at.desc');

  Future<List<Map<String, dynamic>>> fetchBackendUsers() =>
      _list('backend_users', order: 'name.asc,email.asc');

  Future<Map<String, dynamic>?> fetchSiteStatus() =>
      _setting('storefront_status');
  Future<Map<String, dynamic>?> fetchEmailServerSettings() async {
    final encrypted = await _fetchCredential(
      providerType: 'email_server',
      providerName: 'default',
    );
    if (encrypted != null) {
      return {'key': 'email_server_settings', 'value': encrypted};
    }
    return _setting('email_server_settings');
  }

  Future<Map<String, dynamic>?> fetchShippingCarrierCredentials() async {
    final encrypted = await _fetchCredential(
      providerType: 'shipping_carrier',
      providerName: 'default',
    );
    if (encrypted != null) {
      return {'key': 'shipping_carrier_credentials', 'value': encrypted};
    }
    return _setting('shipping_carrier_credentials');
  }

  Future<Map<String, dynamic>?> fetchShippingCarrierCredentialsForCarrier(
    String carrier,
  ) async {
    final providerName = carrier.trim().toLowerCase();
    final encrypted = await _fetchCredential(
      providerType: 'shipping_carrier',
      providerName: providerName,
    );
    if (encrypted != null) {
      return {
        'key': _shippingCarrierCredentialsKey(carrier),
        'value': encrypted,
      };
    }
    return _setting(_shippingCarrierCredentialsKey(carrier));
  }

  Future<Map<String, dynamic>?> fetchStoreInfo() async {
    final data = await _rest(
      'store_info',
      query: {'select': '*', 'id': 'eq.primary', 'limit': '1'},
    );
    final rows = _rows(data);
    return rows.isEmpty ? null : rows.first;
  }
}
