import 'dart:typed_data';

import 'package:egbeanom/services/shipping_rate_gateway.dart';

class StoreDataGateway {
  const StoreDataGateway();

  Future<List<Map<String, dynamic>>> fetchProducts() async => [];
  Future<List<Map<String, dynamic>>> fetchProductsPage({
    int limit = 100,
    int offset = 0,
    String search = '',
    String categoryId = '',
  }) async => [];
  Future<List<Map<String, dynamic>>> fetchCategories() async => [];
  Future<List<Map<String, dynamic>>> fetchContentBlocks() async => [];
  Future<List<Map<String, dynamic>>> fetchCouponRules() async => [];
  Future<List<Map<String, dynamic>>> fetchPaymentMethods() async => [];
  Future<List<Map<String, dynamic>>> fetchShippingOptions() async => [];
  Future<List<Map<String, dynamic>>> fetchTaxRules() async => [];
  Future<List<Map<String, dynamic>>> fetchBrands() async => [];
  Future<List<Map<String, dynamic>>> fetchFragranceNotes() async => [];
  Future<List<Map<String, dynamic>>> fetchFragranceFamilies() async => [];
  Future<List<Map<String, dynamic>>> fetchFragranceSeasons() async => [];
  Future<List<Map<String, dynamic>>> fetchFragranceOccasions() async => [];
  Future<List<Map<String, dynamic>>> fetchOrders() async => [];
  Future<List<Map<String, dynamic>>> fetchOrdersPage({
    int limit = 100,
    int offset = 0,
    String search = '',
    String status = '',
    String financialStatus = '',
    String shippingPriority = '',
  }) async => [];
  Future<List<Map<String, dynamic>>> fetchCustomerAccounts() async => [];
  Future<List<Map<String, dynamic>>> fetchCustomerAccountsPage({
    int limit = 100,
    int offset = 0,
    String search = '',
  }) async => [];
  Future<List<Map<String, dynamic>>> fetchMailingListSubscribers() async => [];
  Future<List<Map<String, dynamic>>> fetchReviews() async => [];
  Future<List<Map<String, dynamic>>> fetchReviewsPage({
    int limit = 100,
    int offset = 0,
    String status = '',
    String search = '',
  }) async => [];
  Future<List<Map<String, dynamic>>> fetchNotifications() async => [];
  Future<List<Map<String, dynamic>>> fetchDailyMetrics() async => [];
  Future<List<Map<String, dynamic>>> fetchDailyMetricsPage({
    int limit = 366,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) async => [];
  Future<List<Map<String, dynamic>>> fetchActiveUserSessions() async => [];
  Future<List<Map<String, dynamic>>> fetchAnalyticsEvents({
    int limit = 1000,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) async => [];
  Future<List<Map<String, dynamic>>> fetchActiveCarts() async => [];
  Future<List<Map<String, dynamic>>> fetchEmailMessages() async => [];
  Future<Map<String, dynamic>?> fetchSiteStatus() async => null;
  Future<Map<String, dynamic>?> fetchEmailServerSettings() async => null;
  Future<Map<String, dynamic>?> fetchShippingCarrierCredentials() async => null;
  Future<Map<String, dynamic>?> fetchShippingCarrierCredentialsForCarrier(
    String carrier,
  ) async => null;
  Future<Map<String, dynamic>?> fetchStoreInfo() async => null;
  Future<List<Map<String, dynamic>>> fetchBackendUsers() async => [];

  Future<void> upsertProduct(Map<String, dynamic> product) async {}
  Future<void> deleteProduct(int productId) async {}
  Future<void> replaceProductVariants(
    int productId,
    List<Map<String, dynamic>> variants,
  ) async {}
  Future<void> replaceProductImages(
    int productId,
    List<Map<String, dynamic>> images,
  ) async {}
  Future<Map<String, dynamic>?> upsertCategory(
    Map<String, dynamic> category,
  ) async => category;
  Future<Map<String, dynamic>?> upsertCouponRule(
    Map<String, dynamic> coupon,
  ) async => coupon;
  Future<Map<String, dynamic>?> findRedeemableCoupon(String code) async => null;
  Future<void> upsertFragranceNote(Map<String, dynamic> note) async {}
  Future<void> upsertPaymentMethod(Map<String, dynamic> method) async {}
  Future<void> upsertContentBlock(Map<String, dynamic> block) async {}
  Future<void> upsertOrder(Map<String, dynamic> order) async {}
  Future<void> upsertShippingOption(Map<String, dynamic> option) async {}
  Future<void> deleteShippingOption(String optionId) async {}
  Future<void> upsertStoreInfo(Map<String, dynamic> info) async {}
  Future<void> upsertTaxRule(Map<String, dynamic> rule) async {}
  Future<void> deleteTaxRule(String ruleId) async {}
  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {}
  Future<bool> decrementInventoryForOrder({
    required String orderNumber,
    required String email,
  }) async => true;
  Future<bool> restockInventoryForOrder({
    required String orderNumber,
    required String email,
  }) async => true;
  Future<void> submitReturnRequest({
    required String orderNumber,
    required String email,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {}
  Future<void> upsertReview(Map<String, dynamic> review) async {}
  Future<void> updateReviewStatus(String reviewId, String status) async {}
  Future<void> deleteReview(String reviewId) async {}
  Future<void> insertOrderSurvey(Map<String, dynamic> survey) async {}
  Future<void> insertNotification(Map<String, dynamic> notification) async {}
  Future<void> updateNotificationReadStatus(
    String notificationId,
    bool isRead,
  ) async {}
  Future<void> insertAdminAuditLog(Map<String, dynamic> audit) async {}
  Future<List<Map<String, dynamic>>> fetchWishlist(String email) async => [];
  Future<void> addWishlistItem({
    required String email,
    required int productId,
  }) async {}
  Future<void> removeWishlistItem({
    required String email,
    required int productId,
  }) async {}
  Future<void> upsertActiveCart(Map<String, dynamic> cart) async {}
  Future<void> markActiveCartRecovered(String cartId) async {}
  Future<void> incrementDailyMetric(Map<String, dynamic> metric) async {}
  Future<void> upsertActiveUserSession(Map<String, dynamic> session) async {}
  Future<void> insertAnalyticsEvent(Map<String, dynamic> event) async {}
  Future<Map<String, dynamic>?> createCustomerAccount(
    Map<String, dynamic> customer,
    String password,
  ) async => customer;
  Future<Map<String, dynamic>?> loginCustomer(
    String email,
    String password,
  ) async => null;
  Future<void> loginCustomerWithOAuth(String provider) async {}

  void redirectBrowserTo(String url) {}
  Future<Map<String, dynamic>?> loginBackendUser(
    String email,
    String password,
  ) async => null;
  Future<Map<String, dynamic>?> restoreCustomerSession() async => null;
  Future<Map<String, dynamic>?> restoreBackendSession() async => null;
  Future<void> logoutBackendUser() async {}
  Future<void> upsertCustomer(Map<String, dynamic> customer) async {}
  Future<void> upsertMailingListSubscriber(
    Map<String, dynamic> subscriber,
  ) async {}
  Future<void> upsertBlockedIp(Map<String, dynamic> blockedIp) async {}
  Future<void> upsertSiteStatus(Map<String, dynamic> value) async {}
  Future<void> upsertEmailServerSettings(Map<String, dynamic> value) async {}
  Future<Map<String, dynamic>> sendEmail({
    required String kind,
    required List<String> recipients,
    required String subject,
    required String htmlBody,
    String textBody = '',
    String orderId = '',
    String event = '',
    String accountId = '',
  }) async => {'sent': recipients.length};
  Future<Map<String, dynamic>> syncInboundEmail({
    String accountId = '',
  }) async => {'imported': 0};
  Future<void> updateEmailMessageReadStatus(
    String messageId,
    bool isRead, {
    String serverMessageId = '',
    String mailbox = 'INBOX',
    String accountId = '',
    int serverUid = 0,
  }) async {}
  Future<void> upsertShippingCarrierCredentials(
    Map<String, dynamic> value,
  ) async {}
  Future<void> upsertShippingCarrierCredentialsForCarrier(
    String carrier,
    Map<String, dynamic> value,
  ) async {}

  Future<Map<String, dynamic>?> fetchPaymentProcessorCredentials(
    String provider,
  ) async => null;

  Future<void> upsertPaymentProcessorCredentials(
    String provider,
    Map<String, dynamic> value,
  ) async {}

  Future<void> upsertBackendUser(Map<String, dynamic> user) async {}
  Future<List<ShippingRateQuote>> quoteShippingRates(
    ShippingRateRequest request,
  ) async => const [];

  Future<String> createStripeCheckoutSession({
    required String orderNumber,
    required String mode,
    required String successUrl,
    required String cancelUrl,
  }) async => '';

  Future<String> createStripeRefund({
    required String orderNumber,
    required double amount,
    required String reason,
  }) async => 'test_refund_$orderNumber';

  Future<ShippingLabelResult> createUspsLabel({
    required Map<String, dynamic> order,
    required Map<String, dynamic> storeInfo,
    required Map<String, dynamic> package,
  }) async => createShippingLabel(
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
  }) async => const ShippingLabelResult(
    trackingNumber: '',
    labelStatus: 'Not requested',
    labelFileName: 'usps-label.pdf',
    labelContentType: 'application/pdf',
    labelBase64: '',
  );

  Future<Map<String, dynamic>> refreshTrackingStatus({
    required String orderNumber,
  }) async => {};

  Future<String> uploadProductImageBytes({
    required int productId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    required int sortOrder,
    required bool isPrimary,
  }) async => '';
  Future<String> uploadSiteAssetBytes({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async => '';
}
