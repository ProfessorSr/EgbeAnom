part of 'store_data_gateway_web.dart';

extension StoreDataGatewayMutations on StoreDataGateway {
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

  Future<void> replaceProductImages(
    int productId,
    List<Map<String, dynamic>> images,
  ) async {
    try {
      await _rest(
        'product_images',
        method: 'DELETE',
        query: {'product_id': 'eq.$productId'},
      );
    } catch (error) {
      throw StateError('Product image cleanup failed: $error');
    }
    if (images.isNotEmpty) {
      try {
        await _insert('product_images', images);
      } catch (error) {
        throw StateError('Product image save failed: $error');
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
    for (final marker in StoreDataGateway._missingLiveColumns) {
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
        StoreDataGateway._missingLiveColumns.add('orders.$missingColumn');
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

  Future<void> submitReturnRequest({
    required String orderNumber,
    required String email,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _rpc('submit_return_request', {
      'p_order_number': orderNumber,
      'p_email': email.trim(),
      'p_return_reason': reason.trim(),
      'p_return_items': items,
    });
    if (response != true && '$response'.toLowerCase() != 'true') {
      throw StateError('Return request could not be submitted.');
    }
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
  Future<void> deleteReview(String reviewId) =>
      _rest('store_reviews', method: 'DELETE', query: {'id': 'eq.$reviewId'});
  Future<void> insertOrderSurvey(Map<String, dynamic> survey) =>
      _insert('order_surveys', survey);
  Future<void> insertNotification(Map<String, dynamic> notification) =>
      _insert('admin_notifications', notification);
  Future<void> updateNotificationReadStatus(
    String notificationId,
    bool isRead,
  ) => _rest(
    'admin_notifications',
    method: 'PATCH',
    query: {'id': 'eq.$notificationId'},
    body: {'is_read': isRead},
    returnRepresentation: false,
  );
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
}
