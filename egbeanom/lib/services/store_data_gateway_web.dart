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

  String? get _accessToken => html.window.localStorage[_accessTokenKey];
  String? get _refreshToken => html.window.localStorage[_refreshTokenKey];

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final data = await _rest(
      'products',
      query: {
        'select': '*,product_images(*),product_variants(*)',
        'order': 'sort_order.asc,name.asc',
      },
    );
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
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final orders = _rows(
      await _rest('orders', query: {'select': '*', 'order': 'created_at.desc'}),
    );
    try {
      final items = _rows(await _rest('order_items', query: {'select': '*'}));
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
      _list('store_customers', order: 'name.asc,email.asc');
  Future<List<Map<String, dynamic>>> fetchReviews() =>
      _list('store_reviews', order: 'created_at.desc');
  Future<List<Map<String, dynamic>>> fetchNotifications() =>
      _list('admin_notifications', order: 'created_at.desc');
  Future<List<Map<String, dynamic>>> fetchBackendUsers() =>
      _list('backend_users', order: 'name.asc,email.asc');

  Future<Map<String, dynamic>?> fetchSiteStatus() =>
      _setting('storefront_status');
  Future<Map<String, dynamic>?> fetchEmailServerSettings() =>
      _setting('email_server_settings');
  Future<Map<String, dynamic>?> fetchShippingCarrierCredentials() =>
      _setting('shipping_carrier_credentials');
  Future<Map<String, dynamic>?> fetchShippingCarrierCredentialsForCarrier(
    String carrier,
  ) => _setting(_shippingCarrierCredentialsKey(carrier));
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

  Future<void> upsertFragranceNote(Map<String, dynamic> note) =>
      _upsert('fragrance_notes', note);
  Future<void> upsertPaymentMethod(Map<String, dynamic> method) =>
      _upsert('payment_methods', method);
  Future<void> upsertContentBlock(Map<String, dynamic> block) =>
      _upsert('content_blocks', block);
  Future<void> upsertOrder(Map<String, dynamic> order) =>
      _upsert('orders', order);
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

  Future<void> upsertReview(Map<String, dynamic> review) =>
      _upsert('store_reviews', review);
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
  Future<void> upsertEmailServerSettings(Map<String, dynamic> value) => _upsert(
    'site_settings',
    {'key': 'email_server_settings', 'value': value, 'is_public': false},
  );
  Future<void> upsertShippingCarrierCredentials(Map<String, dynamic> value) =>
      _upsert('site_settings', {
        'key': 'shipping_carrier_credentials',
        'value': value,
        'is_public': false,
      });
  Future<void> upsertShippingCarrierCredentialsForCarrier(
    String carrier,
    Map<String, dynamic> value,
  ) => _upsert('site_settings', {
    'key': _shippingCarrierCredentialsKey(carrier),
    'value': value,
    'is_public': false,
  });

  Future<Map<String, dynamic>?> fetchPaymentProcessorCredentials(
    String provider,
  ) => _setting(_paymentProcessorCredentialsKey(provider));

  Future<void> upsertPaymentProcessorCredentials(
    String provider,
    Map<String, dynamic> value,
  ) => _upsert('site_settings', {
    'key': _paymentProcessorCredentialsKey(provider),
    'value': value,
    'is_public': false,
  });

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
          'p_encryption_key': 'decode(\'$encryptionKey\', \'hex\')',
        },
      );

      if (response is! Map) {
        return null;
      }

      final jsonStr = response['p_decrypted'] ?? response;
      return jsonStr is String ? jsonDecode(jsonStr) : jsonStr;
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
          'p_encryption_key': 'decode(\'$encryptionKey\', \'hex\')',
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
          'p_encryption_key': 'decode(\'$encryptionKey\', \'hex\')',
        },
      );

      if (response is! Map) {
        return null;
      }

      final jsonStr = response['p_decrypted'] ?? response;
      return jsonStr is String ? jsonDecode(jsonStr) : jsonStr;
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
          'p_encryption_key': 'decode(\'$encryptionKey\', \'hex\')',
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

  Future<ShippingLabelResult> createUspsLabel({
    required Map<String, dynamic> order,
    required Map<String, dynamic> storeInfo,
    required Map<String, dynamic> package,
  }) async {
    final response = await _function(
      'usps-shipping',
      body: {
        'action': 'createLabel',
        'order': order,
        'storeInfo': storeInfo,
        'package': package,
      },
    );
    return ShippingLabelResult.fromJson(response);
  }

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

  Future<List<Map<String, dynamic>>> _list(
    String table, {
    required String order,
  }) async {
    final data = await _rest(table, query: {'select': '*', 'order': order});
    return _rows(data);
  }

  Future<Map<String, dynamic>?> _setting(String key) async {
    final data = await _rest(
      'site_settings',
      query: {'select': '*', 'key': 'eq.$key', 'limit': '1'},
    );
    final rows = _rows(data);
    return rows.isEmpty ? null : rows.first;
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
    await _rest(table, method: 'POST', body: rows);
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
        sendData: body == null ? null : jsonEncode(body),
      ).timeout(const Duration(seconds: 20));
    } catch (error) {
      throw StateError(
        _networkFailureMessage('Supabase database $method $table', error),
      );
    }
    return _decodeResponse(request, 'Supabase request failed');
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

  dynamic _decodeResponse(html.HttpRequest request, String label) {
    final status = request.status ?? 0;
    final raw = request.responseText ?? '';
    final decoded = raw.trim().isEmpty ? null : _tryDecodeJson(raw);
    if (status < 200 || status >= 300) {
      final message = decoded is Map
          ? (decoded['msg'] ?? decoded['message'] ?? decoded['error'])
          : raw;
      throw StateError('$label: $message');
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
      html.window.localStorage[_accessTokenKey] = accessToken;
    }
    if (refreshToken is String && refreshToken.isNotEmpty) {
      html.window.localStorage[_refreshTokenKey] = refreshToken;
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
      html.window.localStorage[_accessTokenKey] = accessToken;
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      html.window.localStorage[_refreshTokenKey] = refreshToken;
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
