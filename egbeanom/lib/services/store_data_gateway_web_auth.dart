part of 'store_data_gateway_web.dart';

extension StoreDataGatewayAuth on StoreDataGateway {
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
    final uri = Uri.parse('${StoreDataGateway._supabaseUrl}/auth/v1/authorize')
        .replace(
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
      'created_ip': source?['created_ip'] ?? '',
      'last_login_ip': source?['last_login_ip'] ?? '',
      'created_source': source?['created_source'] ?? '',
      'last_login_source': source?['last_login_source'] ?? '',
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
    html.window.sessionStorage.remove(StoreDataGateway._accessTokenKey);
    html.window.sessionStorage.remove(StoreDataGateway._refreshTokenKey);
    html.window.localStorage.remove(StoreDataGateway._accessTokenKey);
    html.window.localStorage.remove(StoreDataGateway._refreshTokenKey);
  }

  Future<void> upsertCustomer(Map<String, dynamic> customer) =>
      _upsert('store_customers', customer..remove('password'));
  Future<void> upsertMailingListSubscriber(Map<String, dynamic> subscriber) =>
      _rest(
        'mailing_list_subscribers',
        method: 'POST',
        query: {'on_conflict': 'email'},
        body: subscriber,
        prefer: 'resolution=merge-duplicates',
        returnRepresentation: false,
      );
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
    String accountId = '',
  }) => _function(
    'send-email',
    body: {
      'kind': kind,
      if (accountId.trim().isNotEmpty) 'account_id': accountId.trim(),
      'recipients': recipients,
      'subject': subject,
      'htmlBody': htmlBody,
      'textBody': textBody,
      'orderId': orderId,
      'event': event,
    },
  );
  Future<Map<String, dynamic>> syncInboundEmail({String accountId = ''}) =>
      _function(
        'fetch-email',
        body: {
          'mailbox': 'INBOX',
          'limit': 30,
          if (accountId.trim().isNotEmpty) 'account_id': accountId.trim(),
        },
      );
}
