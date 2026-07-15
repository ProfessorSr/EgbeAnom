part of '../main.dart';

class SiteStatus {
  SiteStatus({
    this.isLive = true,
    this.measurementSystem = MeasurementSystem.standard,
    this.message =
        'We are polishing the shelves and upgrading the experience just for you. Please check back soon.',
    this.returnPolicy =
        'Unopened items may be returned within 14 days of delivery. Fragrance oils and opened personal-care products are final sale unless they arrive damaged or incorrect.',
    this.googleAnalyticsMeasurementId = '',
    this.showNoteEncyclopedia = true,
    this.showIngredientProfiles = true,
    this.showBrandProfile = true,
    this.showRecommendations = true,
    this.showLatestFragranceNews = true,
    this.showCommunity = true,
    this.showCompanyReviews = true,
    this.showMailingListSignup = true,
    this.showLiveChat = true,
    this.homeShelfMode = 'Best sellers',
    List<int>? featuredProductIds,
  }) : featuredProductIds = featuredProductIds ?? [];

  bool isLive;
  MeasurementSystem measurementSystem;
  String message;
  String returnPolicy;
  String googleAnalyticsMeasurementId;
  bool showNoteEncyclopedia;
  bool showIngredientProfiles;
  bool showBrandProfile;
  bool showRecommendations;
  bool showLatestFragranceNews;
  bool showCommunity;
  bool showCompanyReviews;
  bool showMailingListSignup;
  bool showLiveChat;
  String homeShelfMode;
  List<int> featuredProductIds;

  factory SiteStatus.fromRow(Map<String, dynamic> row) {
    final value = row['value'];
    if (value is Map) {
      return SiteStatus(
        isLive: value['is_live'] != false,
        measurementSystem: _asString(value['measurement_system']) == 'metric'
            ? MeasurementSystem.metric
            : MeasurementSystem.standard,
        message: _asString(
          value['maintenance_message'],
          fallback:
              'We are polishing the shelves and upgrading the experience just for you. Please check back soon.',
        ),
        returnPolicy: _asString(
          value['return_policy'],
          fallback:
              'Unopened items may be returned within 14 days of delivery. Fragrance oils and opened personal-care products are final sale unless they arrive damaged or incorrect.',
        ),
        googleAnalyticsMeasurementId: _asString(
          value['google_analytics_measurement_id'],
        ),
        showNoteEncyclopedia: value['show_note_encyclopedia'] != false,
        showIngredientProfiles: value['show_ingredient_profiles'] != false,
        showBrandProfile: value['show_brand_profile'] != false,
        showRecommendations: value['show_recommendations'] != false,
        showLatestFragranceNews: value['show_latest_fragrance_news'] != false,
        showCommunity: value['show_community'] != false,
        showCompanyReviews: value['show_company_reviews'] != false,
        showMailingListSignup: value['show_mailing_list_signup'] != false,
        showLiveChat: value['show_live_chat'] != false,
        homeShelfMode: _asString(
          value['home_shelf_mode'],
          fallback: 'Best sellers',
        ),
        featuredProductIds: value['featured_product_ids'] is List
            ? (value['featured_product_ids'] as List)
                  .map(_asInt)
                  .where((id) => id > 0)
                  .toList()
            : const [],
      );
    }
    return SiteStatus();
  }

  Map<String, dynamic> toJson() => {
    'is_live': isLive,
    'measurement_system': measurementSystem == MeasurementSystem.metric
        ? 'metric'
        : 'standard',
    'maintenance_message': message,
    'return_policy': returnPolicy,
    'google_analytics_measurement_id': googleAnalyticsMeasurementId,
    'show_note_encyclopedia': showNoteEncyclopedia,
    'show_ingredient_profiles': showIngredientProfiles,
    'show_brand_profile': showBrandProfile,
    'show_recommendations': showRecommendations,
    'show_latest_fragrance_news': showLatestFragranceNews,
    'show_community': showCommunity,
    'show_company_reviews': showCompanyReviews,
    'show_mailing_list_signup': showMailingListSignup,
    'show_live_chat': showLiveChat,
    'home_shelf_mode': homeShelfMode,
    'featured_product_ids': featuredProductIds,
  };

  bool isInfoPageVisible(StoreInfoPage page) {
    return switch (page) {
      StoreInfoPage.notes => showNoteEncyclopedia,
      StoreInfoPage.ingredients => showIngredientProfiles,
      StoreInfoPage.brandProfile => showBrandProfile,
      StoreInfoPage.recommendations => showRecommendations,
      StoreInfoPage.ratings ||
      StoreInfoPage.wishlist ||
      StoreInfoPage.collections => showCommunity,
      StoreInfoPage.contact => true,
    };
  }
}

class StoreInfo {
  StoreInfo({
    this.storeName = 'EgbeAnom Fragrance',
    this.displayName = 'EgbeAnom Fragrance',
    this.bannerUrl = '',
    this.logoUrl = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.county = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'US',
    this.email = '',
    this.phone = '',
    this.fax = '',
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.tiktokUrl = '',
    this.xUrl = '',
    this.youtubeUrl = '',
  });

  String storeName;
  String displayName;
  String bannerUrl;
  String logoUrl;
  String addressLine1;
  String addressLine2;
  String city;
  String county;
  String state;
  String postalCode;
  String country;
  String email;
  String phone;
  String fax;
  String facebookUrl;
  String instagramUrl;
  String tiktokUrl;
  String xUrl;
  String youtubeUrl;

  factory StoreInfo.fromRow(Map<String, dynamic> row) {
    return StoreInfo(
      storeName: _asString(row['store_name'], fallback: 'EgbeAnom Fragrance'),
      displayName: _asString(
        row['display_name'],
        fallback: 'EgbeAnom Fragrance',
      ),
      bannerUrl: _asString(row['banner_url']),
      logoUrl: _asString(row['logo_url']),
      addressLine1: _asString(row['address_line1']),
      addressLine2: _asString(row['address_line2']),
      city: _asString(row['city']),
      county: _asString(row['county']),
      state: _asString(row['state']),
      postalCode: _asString(row['postal_code']),
      country: _asString(row['country'], fallback: 'US'),
      email: _asString(row['email']),
      phone: _asString(row['phone']),
      fax: _asString(row['fax']),
      facebookUrl: _asString(row['facebook_url']),
      instagramUrl: _asString(row['instagram_url']),
      tiktokUrl: _asString(row['tiktok_url']),
      xUrl: _asString(row['x_url']),
      youtubeUrl: _asString(row['youtube_url']),
    );
  }

  Map<String, dynamic> toRow() => {
    'id': 'primary',
    'store_name': storeName,
    'display_name': displayName,
    'banner_url': bannerUrl,
    'logo_url': logoUrl,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city': city,
    'county': county,
    'state': state,
    'postal_code': postalCode,
    'country': country,
    'email': email,
    'phone': phone,
    'fax': fax,
    'facebook_url': facebookUrl,
    'instagram_url': instagramUrl,
    'tiktok_url': tiktokUrl,
    'x_url': xUrl,
    'youtube_url': youtubeUrl,
  };
}

class TaxRule {
  TaxRule({
    required this.id,
    required this.name,
    this.country = 'US',
    this.state = '',
    this.county = '',
    this.city = '',
    this.postalCodePrefix = '',
    this.taxType = 'sales',
    this.rate = 0,
    this.isVat = false,
    this.isEnabled = true,
    this.sortOrder = 10,
  });

  final String id;
  String name;
  String country;
  String state;
  String county;
  String city;
  String postalCodePrefix;
  String taxType;
  double rate;
  bool isVat;
  bool isEnabled;
  int sortOrder;

  factory TaxRule.fromRow(Map<String, dynamic> row) {
    return TaxRule(
      id: _asString(row['id']),
      name: _asString(row['name']),
      country: _asString(row['country'], fallback: 'US'),
      state: _asString(row['state']),
      county: _asString(row['county']),
      city: _asString(row['city']),
      postalCodePrefix: _asString(row['postal_code_prefix']),
      taxType: _asString(row['tax_type'], fallback: 'sales'),
      rate: _asDouble(row['rate']),
      isVat: row['is_vat'] == true,
      isEnabled: row['is_enabled'] != false,
      sortOrder: _asInt(row['sort_order'], fallback: 10),
    );
  }

  Map<String, dynamic> toRow() => {
    'id': id,
    'name': name,
    'country': country,
    'state': state,
    'county': county,
    'city': city,
    'postal_code_prefix': postalCodePrefix,
    'tax_type': taxType,
    'rate': rate,
    'is_vat': isVat,
    'is_enabled': isEnabled,
    'sort_order': sortOrder,
  };
}

class TaxBreakdownLine {
  const TaxBreakdownLine({
    required this.name,
    required this.jurisdiction,
    required this.rate,
    required this.amount,
  });

  final String name;
  final String jurisdiction;
  final double rate;
  final double amount;

  factory TaxBreakdownLine.fromRow(Map<String, dynamic> row) {
    return TaxBreakdownLine(
      name: _asString(row['name']),
      jurisdiction: _asString(row['jurisdiction']),
      rate: _asDouble(row['rate']),
      amount: _asDouble(row['amount']),
    );
  }

  Map<String, dynamic> toRow() => {
    'name': name,
    'jurisdiction': jurisdiction,
    'rate': rate,
    'amount': amount,
  };
}

class BackendUser {
  BackendUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.isBlocked = false,
    this.createdIp = '',
    this.lastLoginIp = '',
    this.blockedReason = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.county = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'US',
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  String name;
  String email;
  String role;
  bool isActive;
  bool isBlocked;
  String createdIp;
  String lastLoginIp;
  String blockedReason;
  String addressLine1;
  String addressLine2;
  String city;
  String county;
  String state;
  String postalCode;
  String country;
  DateTime? createdAt;
  DateTime? lastLoginAt;

  factory BackendUser.fromRow(Map<String, dynamic> row) {
    return BackendUser(
      id: _asString(row['id']),
      name: _asString(row['name']),
      email: _asString(row['email']),
      role: _asString(row['role'], fallback: 'staff'),
      isActive: row['is_active'] != false,
      isBlocked: row['is_blocked'] == true,
      createdIp: _asString(row['created_ip']),
      lastLoginIp: _asString(row['last_login_ip']),
      blockedReason: _asString(row['blocked_reason']),
      addressLine1: _asString(row['address_line1']),
      addressLine2: _asString(row['address_line2']),
      city: _asString(row['city']),
      county: _asString(row['county']),
      state: _asString(row['state']),
      postalCode: _asString(row['postal_code']),
      country: _asString(row['country'], fallback: 'US'),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      lastLoginAt: DateTime.tryParse(_asString(row['last_login_at'])),
    );
  }
}
