import 'dart:typed_data';

class StoreDataGateway {
  const StoreDataGateway();

  Future<List<Map<String, dynamic>>> fetchProducts() async => [];
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
  Future<List<Map<String, dynamic>>> fetchCustomerAccounts() async => [];
  Future<List<Map<String, dynamic>>> fetchReviews() async => [];
  Future<List<Map<String, dynamic>>> fetchNotifications() async => [];
  Future<Map<String, dynamic>?> fetchSiteStatus() async => null;
  Future<Map<String, dynamic>?> fetchEmailServerSettings() async => null;
  Future<Map<String, dynamic>?> fetchStoreInfo() async => null;
  Future<List<Map<String, dynamic>>> fetchBackendUsers() async => [];

  Future<void> upsertProduct(Map<String, dynamic> product) async {}
  Future<void> deleteProduct(int productId) async {}
  Future<void> replaceProductVariants(
    int productId,
    List<Map<String, dynamic>> variants,
  ) async {}
  Future<Map<String, dynamic>?> upsertCategory(
    Map<String, dynamic> category,
  ) async => category;
  Future<void> upsertCouponRule(Map<String, dynamic> coupon) async {}
  Future<void> upsertFragranceNote(Map<String, dynamic> note) async {}
  Future<void> upsertPaymentMethod(Map<String, dynamic> method) async {}
  Future<void> upsertContentBlock(Map<String, dynamic> block) async {}
  Future<void> upsertOrder(Map<String, dynamic> order) async {}
  Future<void> upsertShippingOption(Map<String, dynamic> option) async {}
  Future<void> deleteShippingOption(String optionId) async {}
  Future<void> upsertStoreInfo(Map<String, dynamic> info) async {}
  Future<void> upsertTaxRule(Map<String, dynamic> rule) async {}
  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {}
  Future<void> upsertReview(Map<String, dynamic> review) async {}
  Future<void> updateReviewStatus(String reviewId, String status) async {}
  Future<void> insertOrderSurvey(Map<String, dynamic> survey) async {}
  Future<void> insertNotification(Map<String, dynamic> notification) async {}
  Future<Map<String, dynamic>?> createCustomerAccount(
    Map<String, dynamic> customer,
    String password,
  ) async => customer;
  Future<Map<String, dynamic>?> loginCustomer(
    String email,
    String password,
  ) async => null;
  Future<void> loginCustomerWithOAuth(String provider) async {}
  Future<Map<String, dynamic>?> loginBackendUser(
    String email,
    String password,
  ) async => null;
  Future<Map<String, dynamic>?> restoreCustomerSession() async => null;
  Future<Map<String, dynamic>?> restoreBackendSession() async => null;
  Future<void> logoutBackendUser() async {}
  Future<void> upsertCustomer(Map<String, dynamic> customer) async {}
  Future<void> upsertBlockedIp(Map<String, dynamic> blockedIp) async {}
  Future<void> upsertSiteStatus(Map<String, dynamic> value) async {}
  Future<void> upsertEmailServerSettings(Map<String, dynamic> value) async {}
  Future<void> upsertBackendUser(Map<String, dynamic> user) async {}

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
