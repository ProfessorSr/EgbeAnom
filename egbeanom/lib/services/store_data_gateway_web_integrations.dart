part of 'store_data_gateway_web.dart';

extension StoreDataGatewayIntegrations on StoreDataGateway {
  Future<void> updateEmailMessageReadStatus(
    String messageId,
    bool isRead, {
    String serverMessageId = '',
    String mailbox = 'INBOX',
    String accountId = '',
    int serverUid = 0,
  }) async {
    await _function(
      'fetch-email',
      body: {
        'action': 'set_read',
        'id': messageId,
        'message_id': serverMessageId.trim().isNotEmpty
            ? serverMessageId.trim()
            : messageId,
        'mailbox': mailbox.trim().isEmpty ? 'INBOX' : mailbox.trim(),
        'is_read': isRead,
        if (serverUid > 0) 'uid': serverUid,
        if (accountId.trim().isNotEmpty) 'account_id': accountId.trim(),
      },
    );
  }

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

  Future<String> createStripeRefund({
    required String orderNumber,
    required double amount,
    required String reason,
  }) async {
    final response = await _function(
      'stripe-refund',
      body: {'orderNumber': orderNumber, 'amount': amount, 'reason': reason},
    );
    final refundId = '${response['refundId'] ?? response['id'] ?? ''}'.trim();
    if (refundId.isEmpty) {
      throw StateError('Stripe refund did not return a refund id.');
    }
    return refundId;
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
}
