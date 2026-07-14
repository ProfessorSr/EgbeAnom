// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:egbeanom/services/shipping_rate_gateway.dart';

class StoreDataGateway {
  const StoreDataGateway();

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _productBucket = String.fromEnvironment(
    'SUPABASE_PRODUCT_BUCKET',
    defaultValue: 'product-images',
  );
  static const _accessTokenKey = 'egbeanom.supabase.access_token';
  static const _refreshTokenKey = 'egbeanom.supabase.refresh_token';
  static final Set<String> _missingLiveColumns = {};

  String? get _accessToken => html.window.sessionStorage[_accessTokenKey];
  String? get _refreshToken => html.window.sessionStorage[_refreshTokenKey];

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

  Future<List<Map<String, dynamic>>> fetchActiveCarts() =>
      _list('active_carts', order: 'last_seen_at.desc');

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

  Future<void> upsertProduct(Map<String, dynamic> product) async {
    final id = product['id'];
    if (id is num && id > 0) {
      final body = Map<String, dynamic>.from(product)..remove('id');
      try {
        final data = await _rest(
          'products',
          method: 'PATCH',
          query: {'id': 'eq.$id'},
          body: body,
        );
        if (_rows(data).isNotEmpty) {
          return;
        }
      } catch (error) {
        throw StateError('Product row update failed: $error');
      }
    }
    try {
      await _upsert('products', product);
    } catch (error) {
      throw StateError('Product row insert failed: $error');
    }
  }

  Future<void> deleteProduct(int productId) async {
    await _rest('products', method: 'DELETE', query: {'id': 'eq.$productId'});
  }

  Future<void> replaceProductVariants(
    int productId,
    List<Map<String, dynamic>> variants,
  ) async {
    try {
      await _rest(
        'product_variants',
        method: 'DELETE',
        query: {'product_id': 'eq.$productId'},
      );
    } catch (error) {
      throw StateError('Product size cleanup failed: $error');
    }
    if (variants.isNotEmpty) {
      try {
        await _insert('product_variants', variants);
      } catch (error) {
        throw StateError('Product size save failed: $error');
      }
    }
  }

  Future<Map<String, dynamic>?> upsertCategory(
    Map<String, dynamic> category,
  ) async {
    final id = category['id'];
    final body = Map<String, dynamic>.from(category);
    if (id is num && id > 0) {
      body.remove('id');
      try {
        final data = await _rest(
          'categories',
          method: 'PATCH',
          query: {'id': 'eq.$id'},
          body: body,
        );
        final rows = _rows(data);
        if (rows.isNotEmpty) {
          return rows.first;
        }
      } catch (error) {
        throw StateError('Category row update failed: $error');
      }
    }
    body.remove('id');
    try {
      final data = await _rest('categories', method: 'POST', body: body);
      final rows = _rows(data);
      return rows.isEmpty ? null : rows.first;
    } catch (error) {
      throw StateError('Category row insert failed: $error');
    }
  }

  Future<Map<String, dynamic>?> upsertCouponRule(
    Map<String, dynamic> coupon,
  ) async {
    final row = Map<String, dynamic>.from(coupon)..remove('id');
    try {
      await _rest(
        'coupon_rules',
        method: 'POST',
        query: {'on_conflict': 'code'},
        body: row,
        prefer: 'resolution=merge-duplicates',
        returnRepresentation: false,
      );
    } catch (error) {
      if (!_isBrowserReadableResponseFailure(error)) {
        rethrow;
      }
    }
    final code = '${row['code'] ?? ''}'.trim();
    if (code.isEmpty) {
      return null;
    }
    final data = await _rest(
      'coupon_rules',
      query: {'select': '*', 'code': 'eq.$code', 'limit': '1'},
    );
    final rows = _rows(data);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> findRedeemableCoupon(String code) async {
    final response = await _rpc('find_redeemable_coupon', {'p_code': code});
    final rows = _rows(response);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertFragranceNote(Map<String, dynamic> note) =>
      _upsert('fragrance_notes', note);
  Future<void> upsertPaymentMethod(Map<String, dynamic> method) async {
    final row = Map<String, dynamic>.from(method)..remove('id');
    final provider = '${row['provider'] ?? ''}'.trim();
    final name = '${row['name'] ?? ''}'.trim();
    if (provider.isEmpty || name.isEmpty) {
      throw StateError('Payment method requires a provider and name.');
    }
    final existing = await _rest(
      'payment_methods',
      query: {
        'select': 'id',
        'provider': 'eq.$provider',
        'name': 'eq.$name',
        'limit': '1',
      },
    );
    final rows = _rows(existing);
    if (rows.isEmpty) {
      await _rest(
        'payment_methods',
        method: 'POST',
        body: row,
        returnRepresentation: false,
      );
      return;
    }
    await _rest(
      'payment_methods',
      method: 'PATCH',
      query: {'id': 'eq.${rows.first['id']}'},
      body: row,
      returnRepresentation: false,
    );
  }

  Future<void> upsertContentBlock(Map<String, dynamic> block) =>
      _upsert('content_blocks', block);
  Future<void> upsertOrder(Map<String, dynamic> order) async {
    final row = Map<String, dynamic>.from(order)..remove('id');
    final copy = Map<String, dynamic>.from(row);
    for (final marker in _missingLiveColumns) {
      if (!marker.startsWith('orders.')) {
        continue;
      }
      copy.remove(marker.substring('orders.'.length));
    }
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        if (_isPendingCheckoutInsert(copy)) {
          try {
            await _rest(
              'orders',
              method: 'POST',
              body: copy,
              returnRepresentation: false,
            );
          } catch (error) {
            if (!_isDuplicateRowFailure('$error')) {
              rethrow;
            }
            await _patchOrderByOrderNumber(copy);
          }
        } else {
          await _patchOrderByOrderNumber(copy);
        }
        return;
      } catch (error) {
        final missingColumn = _missingColumnFromError('$error');
        if (missingColumn == null) {
          rethrow;
        }
        _missingLiveColumns.add('orders.$missingColumn');
        copy.remove(missingColumn);
      }
    }
    throw StateError('Could not save order with the live Supabase schema.');
  }

  bool _isPendingCheckoutInsert(Map<String, dynamic> order) {
    final status = '${order['status'] ?? ''}'.trim().toLowerCase();
    final financialStatus = '${order['financial_status'] ?? ''}'
        .trim()
        .toLowerCase();
    return status == 'pending' && financialStatus == 'unpaid';
  }

  bool _isDuplicateRowFailure(String message) {
    final lower = message.toLowerCase();
    return lower.contains('duplicate key') ||
        lower.contains('23505') ||
        lower.contains('409');
  }

  Future<void> _patchOrderByOrderNumber(Map<String, dynamic> order) async {
    final orderNumber = '${order['order_number'] ?? ''}'.trim();
    if (orderNumber.isEmpty) {
      throw StateError('Order save requires an order number.');
    }
    if (_shouldMarkCheckoutPaidWithRpc(order)) {
      final marked = await _markCheckoutOrderPaid(orderNumber, order);
      if (marked) {
        return;
      }
    }
    await _rest(
      'orders',
      method: 'PATCH',
      query: {'order_number': 'eq.$orderNumber'},
      body: order,
      returnRepresentation: false,
    );
  }

  bool _shouldMarkCheckoutPaidWithRpc(Map<String, dynamic> order) {
    final financialStatus = '${order['financial_status'] ?? ''}'
        .trim()
        .toLowerCase();
    final email = '${order['email'] ?? ''}'.trim();
    return _accessToken == null &&
        financialStatus == 'paid' &&
        email.isNotEmpty;
  }

  Future<bool> _markCheckoutOrderPaid(
    String orderNumber,
    Map<String, dynamic> order,
  ) async {
    final response = await _rpc('mark_checkout_order_paid', {
      'p_order_number': orderNumber,
      'p_email': '${order['email'] ?? ''}'.trim(),
      'p_payment_provider': '${order['payment_provider'] ?? ''}'.trim(),
      'p_payment_reference': '${order['payment_reference'] ?? ''}'.trim(),
    });
    return response == true || '$response'.toLowerCase() == 'true';
  }

  Future<bool> decrementInventoryForOrder({
    required String orderNumber,
    required String email,
  }) async {
    final response = await _rpc('decrement_inventory_for_order', {
      'p_order_number': orderNumber,
      'p_email': email.trim(),
    });
    return response == true || '$response'.toLowerCase() == 'true';
  }

  Future<bool> restockInventoryForOrder({
    required String orderNumber,
    required String email,
  }) async {
    final response = await _rpc('restock_inventory_for_order', {
      'p_order_number': orderNumber,
      'p_email': email.trim(),
    });
    return response == true || '$response'.toLowerCase() == 'true';
  }

  Future<void> upsertShippingOption(Map<String, dynamic> option) =>
      _upsert('shipping_options', option);
  Future<void> deleteShippingOption(String optionId) async {
    await _rest(
      'shipping_options',
      method: 'DELETE',
      query: {'id': 'eq.$optionId'},
    );
  }

  Future<void> upsertStoreInfo(Map<String, dynamic> info) =>
      _upsert('store_info', info);
  Future<void> upsertTaxRule(Map<String, dynamic> rule) =>
      _upsert('tax_rules', rule);
  Future<void> deleteTaxRule(String ruleId) async {
    await _rest('tax_rules', method: 'DELETE', query: {'id': 'eq.$ruleId'});
  }

  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {
    if (items.isNotEmpty) {
      await _insert('order_items', items);
    }
  }

  Future<void> upsertReview(Map<String, dynamic> review) async {
    await _insert('store_reviews', review);
  }

  Future<void> updateReviewStatus(String reviewId, String status) => _rest(
    'store_reviews',
    method: 'PATCH',
    query: {'id': 'eq.$reviewId'},
    body: {'status': status},
  );
  Future<void> insertOrderSurvey(Map<String, dynamic> survey) =>
      _insert('order_surveys', survey);
  Future<void> insertNotification(Map<String, dynamic> notification) =>
      _insert('admin_notifications', notification);
  Future<void> insertAdminAuditLog(Map<String, dynamic> audit) =>
      _insert('admin_audit_log', audit);
  Future<List<Map<String, dynamic>>> fetchWishlist(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const [];
    }
    final data = await _rest(
      'customer_wishlist',
      query: {
        'select': '*',
        'customer_email': 'eq.$cleanEmail',
        'order': 'created_at.desc',
      },
    );
    return _rows(data);
  }

  Future<void> addWishlistItem({
    required String email,
    required int productId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || productId <= 0) {
      return;
    }
    await _rest(
      'customer_wishlist',
      method: 'POST',
      query: {'on_conflict': 'customer_email,product_id'},
      body: {'customer_email': cleanEmail, 'product_id': productId},
      prefer: 'resolution=merge-duplicates',
      returnRepresentation: false,
    );
  }

  Future<void> removeWishlistItem({
    required String email,
    required int productId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || productId <= 0) {
      return;
    }
    await _rest(
      'customer_wishlist',
      method: 'DELETE',
      query: {
        'customer_email': 'eq.$cleanEmail',
        'product_id': 'eq.$productId',
      },
      returnRepresentation: false,
    );
  }

  Future<void> upsertActiveCart(Map<String, dynamic> cart) async {
    await _rest(
      'active_carts',
      method: 'POST',
      query: {'on_conflict': 'id'},
      body: cart,
      prefer: 'resolution=merge-duplicates',
      returnRepresentation: false,
    );
  }

  Future<void> markActiveCartRecovered(String cartId) async {
    final cleanId = cartId.trim();
    if (cleanId.isEmpty) {
      return;
    }
    await _rest(
      'active_carts',
      method: 'PATCH',
      query: {'id': 'eq.$cleanId'},
      body: {
        'status': 'recovered',
        'recovered_at': DateTime.now().toUtc().toIso8601String(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      returnRepresentation: false,
    );
  }

  Future<void> incrementDailyMetric(Map<String, dynamic> metric) async {
    await _rpc('increment_daily_analytics', {
      'p_day': metric['day'],
      'p_label': metric['label'],
      'p_new_users': metric['new_users'] ?? 0,
      'p_visits': metric['visits'] ?? 0,
      'p_orders': metric['orders'] ?? 0,
      'p_revenue': metric['revenue'] ?? 0,
    });
  }

  Future<void> upsertActiveUserSession(Map<String, dynamic> session) async {
    await _rpc('upsert_analytics_session', {
      'p_id': session['id'],
      'p_visitor': session['visitor'],
      'p_current_page': session['current_page'],
      'p_source': session['source'],
      'p_referrer': session['referrer'],
      'p_device': session['device'],
      'p_started_at': session['started_at'],
      'p_last_seen_at': session['last_seen_at'],
    });
  }

  Future<void> insertAnalyticsEvent(Map<String, dynamic> event) =>
      _insert('analytics_events', event);

  Future<Map<String, dynamic>?> createCustomerAccount(
    Map<String, dynamic> customer,
    String password,
  ) async {
    final email = '${customer['email'] ?? ''}'.trim().toLowerCase();
    final auth = await _auth('signup', {
      'email': email,
      'password': password,
      'data': {'name': customer['name'] ?? 'Customer'},
    });
    _storeSession(auth);
    if (_accessToken == null) {
      throw StateError(
        'Supabase created the auth user but did not return a session. '
        'Confirm the email address, then log in.',
      );
    }
    final user = _authUser(auth);
    final row = {
      ...customer,
      'email': email,
      if (user != null) 'auth_user_id': user['id'],
      'last_login_at': DateTime.now().toUtc().toIso8601String(),
    }..remove('password');
    try {
      await _upsertProfile('store_customers', row);
    } catch (_) {
      return _fallbackCustomerProfile(user, email, row);
    }
    return row;
  }

  Future<Map<String, dynamic>?> loginCustomer(
    String email,
    String password,
  ) async {
    final auth = await _auth('token?grant_type=password', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    _storeSession(auth);
    final user = _authUser(auth);
    late final List<Map<String, dynamic>> rows;
    try {
      rows = await _profileRowsForAuthUser(
        table: 'store_customers',
        user: user,
        email: email.trim().toLowerCase(),
      );
    } catch (_) {
      return _fallbackCustomerProfile(user, email.trim().toLowerCase(), null);
    }
    var profile = _rows(rows).isEmpty ? null : _rows(rows).first;
    if (profile == null && user != null) {
      profile = {
        'id': 'CUS-${DateTime.now().millisecondsSinceEpoch}',
        'auth_user_id': user['id'],
        'name': user['user_metadata'] is Map
            ? (user['user_metadata']['name'] ?? 'Customer')
            : 'Customer',
        'email': email.trim().toLowerCase(),
        'joined_days_ago': 0,
        'orders': 0,
        'lifetime_value': 0,
        'segment': 'New',
        'referral_code': email.split('@').first.toUpperCase(),
        'referral_credits': 0,
        'loyalty_points': 0,
        'referred_by': '',
        'last_login_at': DateTime.now().toUtc().toIso8601String(),
      };
      try {
        await _upsertProfile('store_customers', profile);
      } catch (_) {
        return profile;
      }
    }
    if (profile == null || profile['is_blocked'] == true) {
      return null;
    }
    if (user != null && profile['auth_user_id'] == null) {
      profile['auth_user_id'] = user['id'];
    }
    profile['last_login_at'] = DateTime.now().toUtc().toIso8601String();
    try {
      await _upsertProfile('store_customers', profile);
    } catch (_) {
      return profile;
    }
    return profile;
  }

  Future<void> loginCustomerWithOAuth(String provider) async {
    _ensureConfigured();
    final current = html.window.location.href;
    final uri = Uri.parse('$_supabaseUrl/auth/v1/authorize').replace(
      queryParameters: {
        'provider': provider.toLowerCase(),
        'redirect_to': current,
      },
    );
    html.window.location.assign(uri.toString());
  }

  void redirectBrowserTo(String url) {
    html.window.location.assign(url);
  }

  Future<Map<String, dynamic>?> loginBackendUser(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final auth = await _auth('token?grant_type=password', {
      'email': cleanEmail,
      'password': password,
    });
    _storeSession(auth);
    final user = _authUser(auth);
    final fallback = _fallbackBackendProfile(user, cleanEmail);
    if (fallback != null) {
      return fallback;
    }
    late final List<Map<String, dynamic>> rows;
    try {
      rows = await _profileRowsForAuthUser(
        table: 'backend_users',
        user: user,
        email: cleanEmail,
      );
    } catch (error) {
      final fallback = _fallbackBackendProfile(user, cleanEmail);
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
    final profile = _rows(rows).isEmpty ? null : _rows(rows).first;
    if (profile == null ||
        profile['is_active'] == false ||
        profile['is_blocked'] == true) {
      _clearSession();
      return null;
    }
    if (user != null && profile['auth_user_id'] == null) {
      profile['auth_user_id'] = user['id'];
    }
    profile['last_login_at'] = DateTime.now().toUtc().toIso8601String();
    try {
      await _upsertProfile('backend_users', profile);
    } catch (_) {
      // The auth session is already stored and the backend profile has been
      // verified. Do not fail login just because the best-effort last-login
      // profile update was blocked by browser response/CORS handling.
    }
    return profile;
  }

  Future<Map<String, dynamic>?> restoreCustomerSession() async {
    _captureOAuthCallbackSession();
    final user = await _currentAuthUser();
    if (user == null) {
      return null;
    }
    final email = '${user['email'] ?? ''}'.trim().toLowerCase();
    Map<String, dynamic>? profile;
    try {
      profile = await _profileForAuthUser(
        table: 'store_customers',
        user: user,
        email: email,
      );
    } catch (_) {
      return _fallbackCustomerProfile(user, email, null);
    }
    if (profile == null || profile['is_blocked'] == true) {
      return _fallbackCustomerProfile(user, email, null);
    }
    if (profile['auth_user_id'] == null) {
      profile['auth_user_id'] = user['id'];
      try {
        await _upsertProfile('store_customers', profile);
      } catch (_) {
        return profile;
      }
    }
    return profile;
  }

  Future<Map<String, dynamic>?> restoreBackendSession() async {
    _captureOAuthCallbackSession();
    final user = await _currentAuthUser();
    if (user == null) {
      return null;
    }
    final email = '${user['email'] ?? ''}'.trim().toLowerCase();
    final fallback = _fallbackBackendProfile(user, email);
    if (fallback != null) {
      return fallback;
    }
    Map<String, dynamic>? profile;
    try {
      profile = await _profileForAuthUser(
        table: 'backend_users',
        user: user,
        email: email,
      );
    } catch (_) {
      return _fallbackBackendProfile(user, email);
    }
    if (profile == null ||
        profile['is_active'] == false ||
        profile['is_blocked'] == true) {
      return _fallbackBackendProfile(user, email);
    }
    if (profile['auth_user_id'] == null) {
      profile['auth_user_id'] = user['id'];
      await _upsertProfile('backend_users', profile);
    }
    return profile;
  }

  Map<String, dynamic>? _fallbackBackendProfile(
    Map<String, dynamic>? user,
    String email,
  ) {
    // No fallback profiles - require explicit backend_users table entry for admin access
    return null;
  }

  Map<String, dynamic> _fallbackCustomerProfile(
    Map<String, dynamic>? user,
    String email,
    Map<String, dynamic>? source,
  ) {
    final cleanEmail = email.trim().toLowerCase();
    final metadata = user != null && user['user_metadata'] is Map
        ? user['user_metadata'] as Map
        : const {};
    final name = source == null
        ? (metadata['name'] ?? 'Customer')
        : (source['name'] ?? metadata['name'] ?? 'Customer');
    return {
      'id': source?['id'] ?? 'CUS-${DateTime.now().millisecondsSinceEpoch}',
      'auth_user_id': user == null ? null : user['id'],
      'name': name,
      'email': cleanEmail,
      'joined_days_ago': source?['joined_days_ago'] ?? 0,
      'orders': source?['orders'] ?? 0,
      'lifetime_value': source?['lifetime_value'] ?? 0,
      'segment': source?['segment'] ?? 'Customer',
      'referral_code':
          source?['referral_code'] ?? cleanEmail.split('@').first.toUpperCase(),
      'referral_credits': source?['referral_credits'] ?? 0,
      'loyalty_points': source?['loyalty_points'] ?? 0,
      'referred_by': source?['referred_by'] ?? '',
      'last_login_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> logoutBackendUser() async {
    if (_accessToken != null) {
      await _auth('logout', const {}, tokenOverride: _accessToken);
    }
    _clearSession();
  }

  void _clearSession() {
    html.window.sessionStorage.remove(_accessTokenKey);
    html.window.sessionStorage.remove(_refreshTokenKey);
    html.window.localStorage.remove(_accessTokenKey);
    html.window.localStorage.remove(_refreshTokenKey);
  }

  Future<void> upsertCustomer(Map<String, dynamic> customer) =>
      _upsert('store_customers', customer..remove('password'));
  Future<void> upsertBlockedIp(Map<String, dynamic> blockedIp) =>
      _upsert('blocked_ips', blockedIp);
  Future<void> upsertSiteStatus(Map<String, dynamic> value) => _upsert(
    'site_settings',
    {'key': 'storefront_status', 'value': value, 'is_public': true},
  );
  Future<void> upsertEmailServerSettings(Map<String, dynamic> value) =>
      _upsertCredential(
        providerType: 'email_server',
        providerName: 'default',
        credential: value,
      );

  Future<Map<String, dynamic>> sendEmail({
    required String kind,
    required List<String> recipients,
    required String subject,
    required String htmlBody,
    String textBody = '',
    String orderId = '',
    String event = '',
  }) => _function(
    'send-email',
    body: {
      'kind': kind,
      'recipients': recipients,
      'subject': subject,
      'htmlBody': htmlBody,
      'textBody': textBody,
      'orderId': orderId,
      'event': event,
    },
  );
  Future<void> upsertShippingCarrierCredentials(Map<String, dynamic> value) =>
      _upsertCredential(
        providerType: 'shipping_carrier',
        providerName: 'default',
        credential: value,
      );
  Future<void> upsertShippingCarrierCredentialsForCarrier(
    String carrier,
    Map<String, dynamic> value,
  ) => _upsertCredential(
    providerType: 'shipping_carrier',
    providerName: carrier.trim().toLowerCase(),
    credential: value,
  );

  Future<Map<String, dynamic>?> fetchPaymentProcessorCredentials(
    String provider,
  ) async {
    final providerName = provider.trim().toLowerCase();
    final encrypted = await _fetchCredential(
      providerType: 'payment_processor',
      providerName: providerName,
    );
    if (encrypted != null) {
      return {
        'key': _paymentProcessorCredentialsKey(provider),
        'value': encrypted,
      };
    }
    return _setting(_paymentProcessorCredentialsKey(provider));
  }

  Future<void> upsertPaymentProcessorCredentials(
    String provider,
    Map<String, dynamic> value,
  ) => _upsertCredential(
    providerType: 'payment_processor',
    providerName: provider.trim().toLowerCase(),
    credential: value,
  );

  /// Fetch encrypted payment processor credentials from vault
  /// Uses encrypted_credentials table with pgcrypto encryption
  Future<Map<String, dynamic>?> fetchEncryptedPaymentCredentials(
    String provider, {
    String? encryptionKey,
  }) async {
    try {
      // If encryption key not provided, skip encrypted fetch
      if (encryptionKey == null || encryptionKey.isEmpty) {
        return null;
      }

      // Call RPC function to get encrypted credential
      final response = await _rest(
        'rpc/get_encrypted_credential',
        method: 'POST',
        body: {
          'p_provider_type': 'payment_processor',
          'p_provider_name': provider.toLowerCase().trim(),
          'p_encryption_key_hex': encryptionKey,
        },
      );

      return response is String ? jsonDecode(response) : null;
    } catch (_) {
      return null;
    }
  }

  /// Store encrypted payment processor credentials in vault
  Future<void> upsertEncryptedPaymentCredentials(
    String provider,
    Map<String, dynamic> credentials, {
    required String encryptionKey,
  }) async {
    try {
      // Call RPC function to store encrypted credential
      await _rest(
        'rpc/upsert_encrypted_credential',
        method: 'POST',
        body: {
          'p_provider_type': 'payment_processor',
          'p_provider_name': provider.toLowerCase().trim(),
          'p_credentials_json': jsonEncode(credentials),
          'p_encryption_key_hex': encryptionKey,
        },
      );
    } catch (error) {
      throw Exception('Failed to store encrypted credentials: $error');
    }
  }

  /// Fetch encrypted shipping carrier credentials from vault
  Future<Map<String, dynamic>?> fetchEncryptedShippingCredentials(
    String carrier, {
    String? encryptionKey,
  }) async {
    try {
      if (encryptionKey == null || encryptionKey.isEmpty) {
        return null;
      }

      final response = await _rest(
        'rpc/get_encrypted_credential',
        method: 'POST',
        body: {
          'p_provider_type': 'shipping_carrier',
          'p_provider_name': carrier.toLowerCase().trim(),
          'p_encryption_key_hex': encryptionKey,
        },
      );

      return response is String ? jsonDecode(response) : null;
    } catch (_) {
      return null;
    }
  }

  /// Store encrypted shipping carrier credentials in vault
  Future<void> upsertEncryptedShippingCredentials(
    String carrier,
    Map<String, dynamic> credentials, {
    required String encryptionKey,
  }) async {
    try {
      await _rest(
        'rpc/upsert_encrypted_credential',
        method: 'POST',
        body: {
          'p_provider_type': 'shipping_carrier',
          'p_provider_name': carrier.toLowerCase().trim(),
          'p_credentials_json': jsonEncode(credentials),
          'p_encryption_key_hex': encryptionKey,
        },
      );
    } catch (error) {
      throw Exception('Failed to store encrypted shipping credentials: $error');
    }
  }

  /// Get encryption key from environment (should be set in deployment)
  static String? getEncryptionKeyFromEnvironment() {
    return String.fromEnvironment('ENCRYPTION_KEY', defaultValue: '').isEmpty
        ? null
        : String.fromEnvironment('ENCRYPTION_KEY');
  }

  Future<void> upsertBackendUser(Map<String, dynamic> user) =>
      _upsert('backend_users', user..remove('password'));

  Future<List<ShippingRateQuote>> quoteShippingRates(
    ShippingRateRequest request,
  ) async {
    final response = await _function(
      'usps-shipping',
      body: {'action': 'quoteRates', 'request': request.toJson()},
    );
    final quotes = response['quotes'];
    if (quotes is! List) {
      return const [];
    }
    return quotes
        .whereType<Map>()
        .map(
          (quote) => ShippingRateQuote.fromJson(quote.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<String> createStripeCheckoutSession({
    required String orderNumber,
    required String mode,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _function(
      'stripe-checkout-session',
      body: {
        'orderNumber': orderNumber,
        'mode': mode,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      },
    );
    final url = '${response['url'] ?? ''}'.trim();
    if (url.isEmpty) {
      throw StateError(
        'Stripe checkout session did not return a checkout URL.',
      );
    }
    return url;
  }

  Future<ShippingLabelResult> createUspsLabel({
    required Map<String, dynamic> order,
    required Map<String, dynamic> storeInfo,
    required Map<String, dynamic> package,
  }) => createShippingLabel(
    carrier: 'USPS',
    order: order,
    storeInfo: storeInfo,
    package: package,
  );

  Future<ShippingLabelResult> createShippingLabel({
    required String carrier,
    required Map<String, dynamic> order,
    required Map<String, dynamic> storeInfo,
    required Map<String, dynamic> package,
  }) async {
    final functionName = switch (carrier.trim().toUpperCase()) {
      'UPS' => 'ups-shipping',
      'DHL' => 'dhl-shipping',
      'FEDEX' => 'fedex-shipping',
      _ => 'usps-shipping',
    };
    final response = await _function(
      functionName,
      body: {
        'action': 'createLabel',
        'order': order,
        'storeInfo': storeInfo,
        'package': package,
      },
    );
    return ShippingLabelResult.fromJson(response);
  }

  Future<Map<String, dynamic>> refreshTrackingStatus({
    required String orderNumber,
  }) => _function('tracking-status', body: {'orderNumber': orderNumber});

  Future<Map<String, dynamic>?> _profileForAuthUser({
    required String table,
    required Map<String, dynamic> user,
    required String email,
  }) async {
    final profiles = await _profileRowsForAuthUser(
      table: table,
      user: user,
      email: email,
    );
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<List<Map<String, dynamic>>> _profileRowsForAuthUser({
    required String table,
    required Map<String, dynamic>? user,
    required String email,
  }) async {
    final userId = user == null ? null : user['id'];
    final hasAuthUserId = !_missingLiveColumns.contains('$table.auth_user_id');
    if (email.isNotEmpty) {
      final rows = await _rest(
        table,
        query: {'select': '*', 'email': 'eq.$email', 'limit': '1'},
      );
      final emailRows = _rows(rows);
      if (emailRows.isNotEmpty || !hasAuthUserId) {
        return emailRows;
      }
    }
    try {
      final rows = await _rest(
        table,
        query: {
          'select': '*',
          if (hasAuthUserId &&
              userId is String &&
              userId.isNotEmpty &&
              email.isNotEmpty)
            'or': '(auth_user_id.eq.$userId,email.eq.$email)'
          else if (hasAuthUserId && userId is String && userId.isNotEmpty)
            'auth_user_id': 'eq.$userId'
          else
            'email': 'eq.$email',
          'limit': '1',
        },
      );
      return _rows(rows);
    } catch (error) {
      final missingColumn = _missingColumnFromError('$error');
      if (missingColumn != null) {
        _missingLiveColumns.add('$table.$missingColumn');
      }
      if (missingColumn != 'auth_user_id' || email.isEmpty) {
        rethrow;
      }
      final rows = await _rest(
        table,
        query: {'select': '*', 'email': 'eq.$email', 'limit': '1'},
      );
      return _rows(rows);
    }
  }

  Future<void> _upsertProfile(String table, Map<String, dynamic> row) async {
    final copy = Map<String, dynamic>.from(row);
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await _upsert(table, copy);
        return;
      } catch (error) {
        final missingColumn = _missingColumnFromError('$error');
        if (missingColumn == null) {
          rethrow;
        }
        _missingLiveColumns.add('$table.$missingColumn');
        copy.remove(missingColumn);
      }
    }
    throw StateError('Could not save profile with the live Supabase schema.');
  }

  String? _missingColumnFromError(String message) {
    final missing = RegExp("'([^']+)' column").firstMatch(message);
    if (missing != null) {
      return missing.group(1);
    }
    final identity = RegExp(
      r'Column "?([^"\\]+)"? is an identity column',
    ).firstMatch(message);
    if (identity != null) {
      return identity.group(1);
    }
    final nonDefault = RegExp(
      r'non-DEFAULT value into column "?([^"\\]+)"?',
    ).firstMatch(message);
    return nonDefault?.group(1);
  }

  Future<String> uploadProductImageBytes({
    required int productId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    required int sortOrder,
    required bool isPrimary,
  }) async {
    _ensureConfigured();
    _validateImageUpload(
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
    final cleanName = fileName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-');
    final storagePath =
        'products/$productId/${DateTime.now().millisecondsSinceEpoch}-$cleanName';
    final encodedPath = storagePath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        '$_supabaseUrl/storage/v1/object/$_productBucket/$encodedPath',
        method: 'POST',
        requestHeaders: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer ${_accessToken ?? _supabaseAnonKey}',
          'Content-Type': contentType,
          'x-upsert': 'true',
        },
        sendData: bytes.buffer,
      ).timeout(const Duration(seconds: 30));
    } catch (error) {
      throw StateError(
        'Supabase Storage upload did not complete. Confirm the product-images '
        'bucket exists, storage policies allow the signed-in admin to upload, '
        'and the app is running with the current Supabase publishable key. '
        'Original error: $error',
      );
    }
    if (request.status == null ||
        request.status! < 200 ||
        request.status! >= 300) {
      throw StateError(
        'Supabase Storage upload failed: ${request.responseText}',
      );
    }
    final publicUrl =
        '$_supabaseUrl/storage/v1/object/public/$_productBucket/$encodedPath';
    await _upsert('product_images', {
      'product_id': productId,
      'url': publicUrl,
      'storage_path': storagePath,
      'content_type': contentType,
      'file_size': bytes.length,
      'alt_text': fileName,
      'sort_order': sortOrder,
      'is_primary': isPrimary,
    });
    return publicUrl;
  }

  Future<String> uploadSiteAssetBytes({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _ensureConfigured();
    _validateImageUpload(
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
    final cleanName = fileName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-');
    final storagePath =
        'site/${DateTime.now().millisecondsSinceEpoch}-$cleanName';
    final encodedPath = storagePath
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        '$_supabaseUrl/storage/v1/object/$_productBucket/$encodedPath',
        method: 'POST',
        requestHeaders: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer ${_accessToken ?? _supabaseAnonKey}',
          'Content-Type': contentType,
          'x-upsert': 'true',
        },
        sendData: bytes.buffer,
      ).timeout(const Duration(seconds: 30));
    } catch (error) {
      throw StateError(
        'Supabase Storage upload did not complete for the site banner. '
        'Confirm bucket policies allow the signed-in admin to upload. '
        'Original error: $error',
      );
    }
    if (request.status == null ||
        request.status! < 200 ||
        request.status! >= 300) {
      throw StateError(
        'Supabase Storage upload failed: ${request.responseText}',
      );
    }
    return '$_supabaseUrl/storage/v1/object/public/$_productBucket/$encodedPath';
  }

  void _validateImageUpload({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) {
    const maxBytes = 8 * 1024 * 1024;
    final extension = fileName
        .split(RegExp(r'[/\\]'))
        .last
        .split('.')
        .last
        .toLowerCase();
    final normalizedType = contentType.trim().toLowerCase();
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    const allowedMimeTypes = {
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
    };
    if (bytes.isEmpty) {
      throw StateError('Upload failed: image file is empty.');
    }
    if (bytes.length > maxBytes) {
      throw StateError('Upload failed: image files must be 8 MB or smaller.');
    }
    if (!allowedExtensions.contains(extension)) {
      throw StateError('Upload failed: image must be JPG, PNG, WEBP, or GIF.');
    }
    if (!allowedMimeTypes.contains(normalizedType)) {
      throw StateError('Upload failed: unsupported image type $contentType.');
    }
  }

  Future<List<Map<String, dynamic>>> _list(
    String table, {
    required String order,
  }) async {
    final data = await _rest(table, query: {'select': '*', 'order': order});
    return _rows(data);
  }

  Future<List<Map<String, dynamic>>> _listQuery(
    String table,
    Map<String, String> query,
  ) async {
    final data = await _rest(table, query: query);
    return _rows(data);
  }

  int _boundedLimit(int value, {int max = 500}) {
    if (value <= 0) {
      return 100;
    }
    return value > max ? max : value;
  }

  int _boundedOffset(int value) => value < 0 ? 0 : value;

  bool _isConcreteFilter(String value) {
    final clean = value.trim().toLowerCase();
    return clean.isNotEmpty && clean != 'all';
  }

  String _ilikePattern(String value) {
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', r'\%')
        .replaceAll('*', r'\*');
    return '*$escaped*';
  }

  Future<Map<String, dynamic>?> _setting(String key) async {
    final data = await _rest(
      'site_settings',
      query: {'select': '*', 'key': 'eq.$key', 'limit': '1'},
    );
    final rows = _rows(data);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> _fetchCredential({
    required String providerType,
    required String providerName,
  }) async {
    try {
      final response = await _function(
        'credential-vault',
        body: {
          'action': 'get',
          'providerType': providerType,
          'providerName': providerName,
        },
      );
      final credential = response['credential'];
      return credential is Map ? credential.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _upsertCredential({
    required String providerType,
    required String providerName,
    required Map<String, dynamic> credential,
  }) async {
    await _function(
      'credential-vault',
      body: {
        'action': 'upsert',
        'providerType': providerType,
        'providerName': providerName,
        'credential': credential,
      },
    );
  }

  String _shippingCarrierCredentialsKey(String carrier) {
    final normalized = carrier.trim().toLowerCase();
    return 'shipping_carrier_credentials_$normalized';
  }

  String _paymentProcessorCredentialsKey(String provider) {
    final normalized = provider.trim().toLowerCase();
    return 'payment_processor_credentials_$normalized';
  }

  Future<void> _upsert(
    String table,
    Map<String, dynamic> row, {
    bool returnRepresentation = true,
  }) async {
    await _rest(
      table,
      method: 'POST',
      body: row,
      prefer: 'resolution=merge-duplicates',
      returnRepresentation: returnRepresentation,
    );
  }

  Future<void> _insert(String table, Object rows) async {
    await _rest(table, method: 'POST', body: rows, returnRepresentation: false);
  }

  Future<dynamic> _rest(
    String table, {
    String method = 'GET',
    Map<String, String>? query,
    Object? body,
    String? prefer,
    bool returnRepresentation = true,
  }) async {
    _ensureConfigured();
    final uri = Uri.parse(
      '$_supabaseUrl/rest/v1/$table',
    ).replace(queryParameters: query);
    String? encodedBody;
    if (body != null) {
      final safeBody = _sanitizeJsonValue(body, '$table.body');
      try {
        encodedBody = jsonEncode(safeBody);
      } catch (error) {
        throw StateError(
          'Supabase database $method $table payload could not be encoded as JSON: $error',
        );
      }
    }
    final headers = {
      'apikey': _supabaseAnonKey,
      'Authorization': 'Bearer ${_accessToken ?? _supabaseAnonKey}',
      if (method != 'GET') 'Content-Type': 'application/json',
      if (method == 'POST' || method == 'PATCH')
        'Prefer':
            '${prefer == null ? '' : '$prefer,'}return=${returnRepresentation ? 'representation' : 'minimal'}',
    };
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        uri.toString(),
        method: method,
        requestHeaders: headers,
        sendData: encodedBody,
      ).timeout(const Duration(seconds: 20));
    } catch (error) {
      throw StateError(
        _networkFailureMessage('Supabase database $method $table', error),
      );
    }
    return _decodeResponse(request, 'Supabase request failed');
  }

  Future<dynamic> _rpc(String name, Map<String, dynamic> body) async {
    _ensureConfigured();
    final safeBody = _sanitizeJsonValue(body, 'rpc.$name.body');
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        '$_supabaseUrl/rest/v1/rpc/$name',
        method: 'POST',
        requestHeaders: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer ${_accessToken ?? _supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        sendData: jsonEncode(safeBody),
      ).timeout(const Duration(seconds: 20));
    } catch (error) {
      throw StateError(_networkFailureMessage('Supabase RPC $name', error));
    }
    return _decodeResponse(request, 'Supabase RPC $name failed');
  }

  Future<Map<String, dynamic>> _function(
    String name, {
    required Map<String, dynamic> body,
  }) async {
    _ensureConfigured();
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        '$_supabaseUrl/functions/v1/$name',
        method: 'POST',
        requestHeaders: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer ${_accessToken ?? _supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        sendData: jsonEncode(body),
      ).timeout(const Duration(seconds: 45));
    } catch (error) {
      if (name == 'send-email') {
        throw StateError(
          'Supabase function send-email did not return a browser-readable '
          'response. This usually means the function crashed during startup '
          'or CORS blocked the admin page origin. Confirm the latest '
          'send-email function is deployed, then check Supabase function logs. '
          'Original error: $error',
        );
      }
      throw StateError(
        _networkFailureMessage('Supabase function $name', error),
      );
    }
    final decoded = _decodeResponse(request, 'Supabase function $name failed');
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> _currentAuthUser() async {
    if (_accessToken == null) {
      return null;
    }
    try {
      return await _fetchAuthUser();
    } catch (_) {
      final refreshToken = _refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }
      try {
        final auth = await _auth('token?grant_type=refresh_token', {
          'refresh_token': refreshToken,
        });
        _storeSession(auth);
        return await _fetchAuthUser();
      } catch (_) {
        html.window.sessionStorage.remove(_accessTokenKey);
        html.window.sessionStorage.remove(_refreshTokenKey);
        html.window.localStorage.remove(_accessTokenKey);
        html.window.localStorage.remove(_refreshTokenKey);
        return null;
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchAuthUser() async {
    _ensureConfigured();
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        '$_supabaseUrl/auth/v1/user',
        method: 'GET',
        requestHeaders: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
    } catch (error) {
      throw StateError(_networkFailureMessage('Supabase Auth user', error));
    }
    final decoded = _decodeResponse(request, 'Supabase Auth user failed');
    return decoded is Map ? decoded.cast<String, dynamic>() : null;
  }

  Future<Map<String, dynamic>> _auth(
    String path,
    Map<String, dynamic> body, {
    String? tokenOverride,
  }) async {
    _ensureConfigured();
    late final html.HttpRequest request;
    try {
      request = await html.HttpRequest.request(
        '$_supabaseUrl/auth/v1/$path',
        method: 'POST',
        requestHeaders: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer ${tokenOverride ?? _supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        sendData: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));
    } catch (error) {
      throw StateError(_networkFailureMessage('Supabase Auth', error));
    }
    final decoded = _decodeResponse(request, 'Supabase Auth request failed');
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  String _networkFailureMessage(String label, Object error) {
    final raw = '$error';
    if (raw.contains('ProgressEvent')) {
      return '$label did not return a browser-readable response. Check the '
          'Supabase URL/key used to launch Flutter, confirm this localhost '
          'origin is allowed in Supabase Auth URL settings, and retry after a '
          'full debug restart.';
    }
    return '$label request failed before a response was received: $raw';
  }

  bool _isBrowserReadableResponseFailure(Object error) {
    final raw = '$error';
    return raw.contains('did not return a browser-readable response') ||
        raw.contains('request failed before a response was received');
  }

  dynamic _sanitizeJsonValue(dynamic value, String path) {
    if (value == null || value is String || value is bool) {
      return value;
    }
    if (value is num) {
      return value.isFinite ? value : 0;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is List) {
      return [
        for (var i = 0; i < value.length; i++)
          _sanitizeJsonValue(value[i], '$path[$i]'),
      ];
    }
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = '${entry.key}';
        sanitized[key] = _sanitizeJsonValue(entry.value, '$path.$key');
      }
      return sanitized;
    }
    throw StateError(
      'Unsupported value in Supabase payload at $path (${value.runtimeType}).',
    );
  }

  dynamic _decodeResponse(html.HttpRequest request, String label) {
    final status = request.status ?? 0;
    final raw = request.responseText ?? '';
    final decoded = raw.trim().isEmpty ? null : _tryDecodeJson(raw);
    if (status < 200 || status >= 300) {
      if (decoded is Map) {
        final message =
            '${decoded['msg'] ?? decoded['message'] ?? decoded['error'] ?? 'HTTP $status'}';
        final code = '${decoded['code'] ?? ''}'.trim();
        final details = '${decoded['details'] ?? ''}'.trim();
        final hint = '${decoded['hint'] ?? ''}'.trim();
        final extras = <String>[
          if (code.isNotEmpty) 'code=$code',
          if (details.isNotEmpty) 'details=$details',
          if (hint.isNotEmpty) 'hint=$hint',
        ];
        final suffix = extras.isEmpty ? '' : ' (${extras.join('; ')})';
        throw StateError('$label: $message$suffix');
      }
      throw StateError('$label: ${raw.isEmpty ? 'HTTP $status' : raw}');
    }
    return decoded;
  }

  dynamic _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  List<Map<String, dynamic>> _rows(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((row) {
        return row.cast<String, dynamic>();
      }).toList();
    }
    return [];
  }

  Map<String, dynamic>? _authUser(Map<String, dynamic> auth) {
    final user = auth['user'];
    return user is Map ? user.cast<String, dynamic>() : null;
  }

  void _storeSession(Map<String, dynamic> auth) {
    final accessToken = auth['access_token'];
    final refreshToken = auth['refresh_token'];
    if (accessToken is String && accessToken.isNotEmpty) {
      html.window.sessionStorage[_accessTokenKey] = accessToken;
      html.window.localStorage.remove(_accessTokenKey);
    }
    if (refreshToken is String && refreshToken.isNotEmpty) {
      html.window.sessionStorage[_refreshTokenKey] = refreshToken;
      html.window.localStorage.remove(_refreshTokenKey);
    }
  }

  void _captureOAuthCallbackSession() {
    final fragment = html.window.location.hash;
    if (!fragment.contains('access_token=')) {
      return;
    }
    final params = Uri.splitQueryString(fragment.replaceFirst('#', ''));
    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];
    if (accessToken != null && accessToken.isNotEmpty) {
      html.window.sessionStorage[_accessTokenKey] = accessToken;
      html.window.localStorage.remove(_accessTokenKey);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      html.window.sessionStorage[_refreshTokenKey] = refreshToken;
      html.window.localStorage.remove(_refreshTokenKey);
    }
    html.window.history.replaceState(
      null,
      html.document.title,
      html.window.location.pathname,
    );
  }

  void _ensureConfigured() {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
        'Supabase is not configured. Build with --dart-define=SUPABASE_URL=... '
        'and --dart-define=SUPABASE_ANON_KEY=....',
      );
    }
  }
}
