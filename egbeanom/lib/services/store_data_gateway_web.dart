// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:egbeanom/services/shipping_rate_gateway.dart';

part 'store_data_gateway_web_fetches.dart';
part 'store_data_gateway_web_mutations.dart';
part 'store_data_gateway_web_auth.dart';
part 'store_data_gateway_web_integrations.dart';

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
