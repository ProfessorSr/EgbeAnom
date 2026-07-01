part of '../main.dart';

enum StoreView {
  shop,
  catalog,
  detail,
  cart,
  checkout,
  account,
  info,
  admin,
  paymentSuccess,
  paymentFailure,
}

enum StoreInfoPage {
  notes,
  ingredients,
  brandProfile,
  recommendations,
  ratings,
  wishlist,
  collections,
  contact,
}

enum MeasurementSystem { standard, metric }

extension MeasurementSystemLabel on MeasurementSystem {
  String get label => this == MeasurementSystem.metric ? 'Metric' : 'Standard';
}

class Fragrance {
  Fragrance({
    required this.id,
    required this.name,
    required this.type,
    required this.brand,
    required this.notes,
    required this.size,
    required this.price,
    this.cost = 0,
    required this.stock,
    required this.sold,
    required this.featuredColor,
    required this.sku,
    required this.photoUrl,
    required this.vendor,
    required this.categoryId,
    this.brandId,
    this.reorderPoint = 8,
    this.isActive = true,
    this.description = '',
    this.vibe = '',
    this.performance = '',
    this.comparison = '',
    this.fragranceProfile = '',
    this.ingredients = '',
    this.topNotes = '',
    this.heartNotes = '',
    this.baseNotes = '',
    this.concentration = '',
    this.gender = '',
    this.season = '',
    this.occasion = '',
    this.family = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.weightOz = 8,
    this.lengthIn = 6,
    this.widthIn = 3,
    this.heightIn = 3,
    this.itemLocation = '',
    List<ProductImage>? images,
    List<ProductVariant>? variants,
  }) : images = images ?? [],
       variants = variants ?? [];

  final int id;
  String name;
  String type;
  String brand;
  String notes;
  String size;
  double price;
  double cost;
  int stock;
  int sold;
  Color featuredColor;
  String sku;
  String photoUrl;
  String vendor;
  int categoryId;
  int? brandId;
  int reorderPoint;
  bool isActive;
  String description;
  String vibe;
  String performance;
  String comparison;
  String fragranceProfile;
  String ingredients;
  String topNotes;
  String heartNotes;
  String baseNotes;
  String concentration;
  String gender;
  String season;
  String occasion;
  String family;
  double rating;
  int reviewCount;
  double weightOz;
  double lengthIn;
  double widthIn;
  double heightIn;
  String itemLocation;
  List<ProductImage> images;
  List<ProductVariant> variants;

  String shippingSize(MeasurementSystem system) {
    if (system == MeasurementSystem.metric) {
      return '${(weightOz * 28.3495).toStringAsFixed(0)} g • ${(lengthIn * 2.54).toStringAsFixed(1)} x ${(widthIn * 2.54).toStringAsFixed(1)} x ${(heightIn * 2.54).toStringAsFixed(1)} cm';
    }
    return '${weightOz.toStringAsFixed(1)} oz • ${lengthIn.toStringAsFixed(1)} x ${widthIn.toStringAsFixed(1)} x ${heightIn.toStringAsFixed(1)} in';
  }

  String get primaryPhotoUrl {
    if (images.isEmpty) {
      return photoUrl;
    }
    for (final image in images) {
      if (image.isPrimary) {
        return image.url;
      }
    }
    return images.first.url;
  }

  factory Fragrance.fromRow(Map<String, dynamic> row) {
    final imageRows = row['product_images'];
    final variantRows = row['product_variants'];
    final parsedImages = <ProductImage>[];
    final parsedVariants = <ProductVariant>[];
    if (imageRows is List) {
      for (final imageRow in imageRows) {
        if (imageRow is Map) {
          parsedImages.add(
            ProductImage.fromRow(imageRow.cast<String, dynamic>()),
          );
        }
      }
    }
    if (variantRows is List) {
      for (final variantRow in variantRows) {
        if (variantRow is Map) {
          parsedVariants.add(
            ProductVariant.fromRow(variantRow.cast<String, dynamic>()),
          );
        }
      }
    }
    return Fragrance(
      id: _asInt(row['id']),
      name: _asString(row['name']),
      type: _asString(row['fragrance_type']),
      brand: _asString(row['brand']),
      notes: _asString(row['notes']),
      size: _asString(row['size']),
      price: _asDouble(row['price']),
      cost: _asDouble(row['cost']),
      stock: _asInt(row['stock']),
      sold: _asInt(row['sold']),
      featuredColor: _colorFromHex(
        _asString(row['featured_color'], fallback: '#C88F52'),
      ),
      sku: _asString(row['sku']),
      photoUrl: _asString(row['photo_url']),
      vendor: _asString(row['vendor']),
      categoryId: _asInt(row['category_id']),
      brandId: row['brand_id'] == null ? null : _asInt(row['brand_id']),
      reorderPoint: _asInt(row['reorder_point'], fallback: 8),
      isActive: row['is_active'] != false,
      description: _asString(row['description']),
      vibe: _asString(row['vibe']),
      performance: _asString(row['performance']),
      comparison: _asString(row['comparison']),
      fragranceProfile: _asString(row['fragrance_profile']),
      ingredients: _asString(row['ingredients']),
      topNotes: _asString(row['top_notes'], fallback: _asString(row['notes'])),
      heartNotes: _asString(
        row['heart_notes'],
        fallback: _asString(row['notes']),
      ),
      baseNotes: _asString(
        row['base_notes'],
        fallback: _asString(row['notes']),
      ),
      concentration: _asString(row['concentration']),
      gender: _asString(row['gender']),
      season: _asString(row['season']),
      occasion: _asString(row['occasion']),
      family: _asString(row['family']),
      rating: _asDouble(row['rating']),
      reviewCount: _asInt(row['review_count']),
      weightOz: _asDouble(row['weight_oz'], fallback: 8),
      lengthIn: _asDouble(row['length_in'], fallback: 6),
      widthIn: _asDouble(row['width_in'], fallback: 3),
      heightIn: _asDouble(row['height_in'], fallback: 3),
      itemLocation: _asString(row['item_location']),
      images: parsedImages,
      variants: parsedVariants,
    );
  }
}

class ProductVariant {
  ProductVariant({
    required this.id,
    required this.size,
    required this.sku,
    required this.price,
    required this.stock,
    this.reorderPoint = 8,
    this.isActive = true,
  });

  final int id;
  String size;
  String sku;
  double price;
  int stock;
  int reorderPoint;
  bool isActive;

  factory ProductVariant.fromRow(Map<String, dynamic> row) {
    return ProductVariant(
      id: _asInt(row['id']),
      size: _asString(row['size']),
      sku: _asString(row['sku']),
      price: _asDouble(row['price']),
      stock: _asInt(row['stock']),
      reorderPoint: _asInt(row['reorder_point'], fallback: 8),
      isActive: row['is_active'] != false,
    );
  }
}

class ProductImage {
  ProductImage({
    required this.id,
    required this.url,
    required this.altText,
    required this.sortOrder,
    this.isPrimary = false,
  });

  final int id;
  String url;
  String altText;
  int sortOrder;
  bool isPrimary;

  factory ProductImage.fromRow(Map<String, dynamic> row) {
    return ProductImage(
      id: _asInt(row['id']),
      url: _asString(row['url']),
      altText: _asString(row['alt_text']),
      sortOrder: _asInt(row['sort_order'], fallback: 10),
      isPrimary: row['is_primary'] == true,
    );
  }
}

class BrandProfile {
  BrandProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.country,
    required this.sortOrder,
    this.history = '',
    this.foundedYear,
    this.logoUrl = '',
    this.isVisible = true,
  });

  final int id;
  String name;
  String description;
  String country;
  int sortOrder;
  String history;
  int? foundedYear;
  String logoUrl;
  bool isVisible;

  factory BrandProfile.fromRow(Map<String, dynamic> row) {
    return BrandProfile(
      id: _asInt(row['id']),
      name: _asString(row['name']),
      description: _asString(
        row['description'],
        fallback: _asString(row['history']),
      ),
      country: _asString(row['country'], fallback: 'US'),
      sortOrder: _asInt(row['sort_order'], fallback: 10),
      history: _asString(row['history']),
      foundedYear: row['founded_year'] == null
          ? null
          : _asInt(row['founded_year']),
      logoUrl: _asString(row['logo_url']),
      isVisible: row['is_visible'] != false,
    );
  }
}

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

class CartLine {
  CartLine({required this.product, this.variant, this.quantity = 1});

  final Fragrance product;
  final ProductVariant? variant;
  int quantity;

  String get size =>
      variant?.size.trim().isNotEmpty == true ? variant!.size : product.size;
  String get sku =>
      variant?.sku.trim().isNotEmpty == true ? variant!.sku : product.sku;
  double get unitPrice => variant?.price ?? product.price;
  int get stockAvailable => variant?.stock ?? product.stock;
  double get total => unitPrice * quantity;
}

class ShippingAddress {
  ShippingAddress({
    this.firstName = '',
    this.lastName = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.county = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'US',
    this.phone = '',
    this.email = '',
  });

  String firstName;
  String lastName;
  String addressLine1;
  String addressLine2;
  String city;
  String county;
  String state;
  String postalCode;
  String country;
  String phone;
  String email;

  bool get isComplete =>
      addressLine1.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      postalCode.trim().isNotEmpty;

  factory ShippingAddress.fromJson(Object? value) {
    if (value is Map) {
      final data = value.cast<Object?, Object?>();
      return ShippingAddress(
        firstName: _asString(data['first_name']),
        lastName: _asString(data['last_name']),
        addressLine1: _asString(data['address_line1']),
        addressLine2: _asString(data['address_line2']),
        city: _asString(data['city']),
        county: _asString(data['county']),
        state: _asString(data['state']),
        postalCode: _asString(data['postal_code']),
        country: _asString(data['country'], fallback: 'US'),
        phone: _asString(data['phone']),
        email: _asString(data['email']),
      );
    }
    return ShippingAddress();
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city': city,
    'county': county,
    'state': state,
    'postal_code': postalCode,
    'country': country,
    'phone': phone,
    'email': email,
  };
}

class Order {
  Order({
    required this.id,
    required this.customer,
    required this.email,
    required this.total,
    required this.itemCount,
    required this.status,
    this.financialStatus = 'Pending',
    this.fulfillmentStatus = 'Unfulfilled',
    this.shippingCarrier = '',
    this.shippingService = '',
    this.shippingPriority = 'Standard',
    this.shippingTotal = 0,
    this.subtotal = 0,
    this.discountTotal = 0,
    this.couponCode = '',
    this.taxBreakdown = const [],
    this.trackingNumber = '',
    this.labelStatus = 'Not requested',
    ShippingAddress? shippingAddress,
    this.createdAt,
    List<CartLine>? lines,
  }) : shippingAddress = shippingAddress ?? ShippingAddress(),
       lines = lines ?? [];

  final String id;
  String customer;
  String email;
  double total;
  final int itemCount;
  String status;
  String financialStatus;
  String fulfillmentStatus;
  String shippingCarrier;
  String shippingService;
  String shippingPriority;
  double shippingTotal;
  double subtotal;
  double discountTotal;
  String couponCode;
  List<TaxBreakdownLine> taxBreakdown;
  String trackingNumber;
  String labelStatus;
  ShippingAddress shippingAddress;
  DateTime? createdAt;
  final List<CartLine> lines;

  factory Order.fromRow(Map<String, dynamic> row) {
    final lineRows = row['order_items'];
    final parsedLines = <CartLine>[];
    if (lineRows is List) {
      for (final lineRow in lineRows) {
        if (lineRow is Map) {
          final data = lineRow.cast<String, dynamic>();
          final product = Fragrance(
            id: _asInt(data['product_id']),
            name: _asString(data['product_name'], fallback: 'Order item'),
            type: 'Fragrance',
            brand: '',
            notes: '',
            size: _asString(data['size']),
            price: _asDouble(data['unit_price']),
            stock: 0,
            sold: 0,
            featuredColor: const Color(0xFFC88F52),
            sku: _asString(data['sku']),
            photoUrl: _asString(data['product_photo_url']),
            vendor: '',
            categoryId: 1,
            itemLocation: _asString(data['item_location']),
          );
          parsedLines.add(
            CartLine(
              product: product,
              quantity: _asInt(data['quantity'], fallback: 1),
            ),
          );
        }
      }
    }
    final taxRows = row['tax_breakdown'];
    final taxBreakdown = <TaxBreakdownLine>[];
    if (taxRows is List) {
      for (final taxRow in taxRows) {
        if (taxRow is Map) {
          taxBreakdown.add(
            TaxBreakdownLine.fromRow(taxRow.cast<String, dynamic>()),
          );
        }
      }
    }
    return Order(
      id: _asString(row['order_number'], fallback: _asString(row['id'])),
      customer: _asString(row['customer_name']),
      email: _asString(row['email']),
      total: _asDouble(row['grand_total']),
      itemCount: _asInt(row['item_count'], fallback: 1),
      status: _asString(row['status'], fallback: 'Pending'),
      financialStatus: _asString(row['financial_status'], fallback: 'Pending'),
      fulfillmentStatus: _asString(
        row['fulfillment_status'],
        fallback: 'Unfulfilled',
      ),
      shippingCarrier: _asString(row['shipping_carrier']),
      shippingService: _asString(row['shipping_service']),
      shippingPriority: _asString(
        row['shipping_priority'],
        fallback: 'Standard',
      ),
      shippingTotal: _asDouble(row['shipping_total']),
      subtotal: _asDouble(row['subtotal']),
      discountTotal: _asDouble(row['discount_total']),
      couponCode: _asString(row['coupon_code']),
      taxBreakdown: taxBreakdown,
      trackingNumber: _asString(row['tracking_number']),
      labelStatus: _asString(row['label_status'], fallback: 'Not requested'),
      shippingAddress: ShippingAddress.fromJson(row['shipping_address']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      lines: parsedLines,
    );
  }
}

class ShippingOption {
  ShippingOption({
    required this.id,
    required this.name,
    required this.carrier,
    required this.service,
    required this.priority,
    required this.price,
    this.chargeType = 'per_order',
    this.estimatedDays = '3-5 business days',
    this.isEnabled = true,
    this.sortOrder = 10,
  });

  final String id;
  String name;
  String carrier;
  String service;
  String priority;
  double price;
  String chargeType;
  String estimatedDays;
  bool isEnabled;
  int sortOrder;

  factory ShippingOption.fromRow(Map<String, dynamic> row) {
    return ShippingOption(
      id: _asString(row['id'], fallback: _asString(row['code'])),
      name: _asString(row['name']),
      carrier: _asString(row['carrier']),
      service: _asString(row['service']),
      priority: _asString(row['priority'], fallback: 'Standard'),
      price: _asDouble(row['price']),
      chargeType: _asString(row['charge_type'], fallback: 'per_order'),
      estimatedDays: _asString(
        row['estimated_days'],
        fallback: '3-5 business days',
      ),
      isEnabled: row['is_enabled'] != false,
      sortOrder: _asInt(row['sort_order'], fallback: 10),
    );
  }

  Map<String, dynamic> toRow() => {
    'id': id,
    'name': name,
    'carrier': carrier,
    'service': service,
    'priority': priority,
    'price': price,
    'charge_type': chargeType,
    'estimated_days': estimatedDays,
    'is_enabled': isEnabled,
    'sort_order': sortOrder,
  };
}

class EmailServerSettings {
  EmailServerSettings({
    this.fromName = 'Egbe Anom',
    this.fromEmail = 'orders@egbeanom.com',
    this.imapHost = '',
    this.imapPort = 993,
    this.smtpHost = '',
    this.smtpPort = 587,
    this.username = '',
    this.useSsl = true,
  });

  String fromName;
  String fromEmail;
  String imapHost;
  int imapPort;
  String smtpHost;
  int smtpPort;
  String username;
  bool useSsl;

  factory EmailServerSettings.fromRow(Map<String, dynamic> row) {
    final value = row['value'];
    if (value is Map) {
      return EmailServerSettings(
        fromName: _asString(value['from_name'], fallback: 'Egbe Anom'),
        fromEmail: _asString(
          value['from_email'],
          fallback: 'orders@egbeanom.com',
        ),
        imapHost: _asString(value['imap_host']),
        imapPort: _asInt(value['imap_port'], fallback: 993),
        smtpHost: _asString(value['smtp_host']),
        smtpPort: _asInt(value['smtp_port'], fallback: 587),
        username: _asString(value['username']),
        useSsl: value['use_ssl'] != false,
      );
    }
    return EmailServerSettings();
  }

  Map<String, dynamic> toJson() => {
    'from_name': fromName,
    'from_email': fromEmail,
    'imap_host': imapHost,
    'imap_port': imapPort,
    'smtp_host': smtpHost,
    'smtp_port': smtpPort,
    'username': username,
    'use_ssl': useSsl,
  };
}

class CustomerAccount {
  CustomerAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.joinedDaysAgo,
    required this.orders,
    required this.lifetimeValue,
    required this.segment,
    this.referralCode = '',
    this.referralCredits = 0,
    this.isNew = false,
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
  final String name;
  final String email;
  final int joinedDaysAgo;
  int orders;
  double lifetimeValue;
  String segment;
  String referralCode;
  double referralCredits;
  final bool isNew;
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

  factory CustomerAccount.fromRow(Map<String, dynamic> row) {
    final email = _asString(row['email']);
    return CustomerAccount(
      id: _asString(row['id']),
      name: _asString(row['name'], fallback: 'Customer'),
      email: email,
      joinedDaysAgo: _asInt(row['joined_days_ago']),
      orders: _asInt(row['orders'], fallback: _asInt(row['orders_count'])),
      lifetimeValue: _asDouble(
        row['lifetime_value'],
        fallback: _asDouble(row['total_spend']),
      ),
      segment: _asString(
        row['segment'],
        fallback: _asString(row['favorite_family'], fallback: 'Customer'),
      ),
      referralCode: _asString(
        row['referral_code'],
        fallback: email.split('@').first.toUpperCase(),
      ),
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

  Map<String, dynamic> toRow() => {
    'id': id,
    'name': name,
    'email': email,
    'joined_days_ago': joinedDaysAgo,
    'orders': orders,
    'lifetime_value': lifetimeValue,
    'segment': segment,
    'referral_code': referralCode,
    'referral_credits': referralCredits,
    'is_blocked': isBlocked,
    'created_ip': createdIp,
    'last_login_ip': lastLoginIp,
    'blocked_reason': blockedReason,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city': city,
    'county': county,
    'state': state,
    'postal_code': postalCode,
    'country': country,
  };
}

class StoreNotification {
  StoreNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  factory StoreNotification.fromRow(Map<String, dynamic> row) {
    return StoreNotification(
      id: _asString(row['id']),
      type: _asString(row['type'], fallback: 'info'),
      title: _asString(row['title'], fallback: 'Notification'),
      message: _asString(row['message']),
      createdAt:
          DateTime.tryParse(_asString(row['created_at'])) ?? DateTime.now(),
      isRead: row['is_read'] == true,
    );
  }

  Map<String, dynamic> toRow() => {
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
  };
}

class ReviewSummary {
  ReviewSummary({
    required this.id,
    required this.author,
    required this.rating,
    required this.title,
    required this.body,
    required this.scope,
    this.status = 'approved',
    this.productId,
    this.customerEmail = '',
  });

  final int id;
  final String author;
  final double rating;
  final String title;
  final String body;
  final String scope;
  String status;
  final int? productId;
  final String customerEmail;

  factory ReviewSummary.fromRow(Map<String, dynamic> row) {
    return ReviewSummary(
      id: _asInt(row['id']),
      author: _asString(row['author'], fallback: 'Customer'),
      rating: _asDouble(row['rating'], fallback: 5),
      title: _asString(row['title']),
      body: _asString(row['body']),
      scope: _asString(row['scope'], fallback: 'product'),
      status: _asString(row['status'], fallback: 'pending'),
      productId: row['product_id'] == null ? null : _asInt(row['product_id']),
      customerEmail: _asString(row['customer_email']),
    );
  }
}

class ActiveCart {
  ActiveCart({
    required this.id,
    required this.customer,
    required this.minutesAgo,
    required this.lines,
  });

  final String id;
  final String customer;
  final int minutesAgo;
  final List<CartLine> lines;

  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);
  double get value => lines.fold(0, (total, line) => total + line.total);
}

class DailyMetric {
  const DailyMetric({
    required this.day,
    required this.newUsers,
    required this.visits,
    required this.orders,
    required this.revenue,
  });

  final String day;
  final int newUsers;
  final int visits;
  final int orders;
  final double revenue;
}

class ActiveUserSession {
  ActiveUserSession({
    required this.id,
    required this.visitor,
    required this.currentPage,
    required this.source,
    required this.referrer,
    required this.device,
    required this.startedAt,
    required this.lastSeenAt,
  });

  final String id;
  String visitor;
  String currentPage;
  String source;
  String referrer;
  String device;
  DateTime startedAt;
  DateTime lastSeenAt;

  int get minutesActive =>
      math.max(0, DateTime.now().difference(startedAt).inMinutes);
  int get secondsSinceSeen =>
      math.max(0, DateTime.now().difference(lastSeenAt).inSeconds);
}

class EmailTemplate {
  EmailTemplate({
    required this.key,
    required this.name,
    required this.subject,
    required this.htmlBody,
  });

  final String key;
  String name;
  String subject;
  String htmlBody;
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
    this.isVisible = true,
  });

  final int id;
  String name;
  String description;
  int sortOrder;
  bool isVisible;

  factory Category.fromRow(Map<String, dynamic> row) {
    return Category(
      id: _asInt(row['id']),
      name: _asString(row['name']),
      description: _asString(row['description']),
      sortOrder: _asInt(row['sort_order'], fallback: 10),
      isVisible: row['is_visible'] != false,
    );
  }
}

class CouponRule {
  CouponRule({
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    required this.minimumSpend,
    required this.usageLimit,
    required this.used,
    required this.starts,
    required this.ends,
    this.buyQuantity = 0,
    this.getQuantity = 0,
    this.getPrice = 0,
    this.isActive = true,
    this.isArchived = false,
  });

  String code;
  String name;
  String type;
  double value;
  double minimumSpend;
  int usageLimit;
  int used;
  String starts;
  String ends;
  int buyQuantity;
  int getQuantity;
  double getPrice;
  bool isActive;
  bool isArchived;

  factory CouponRule.fromRow(Map<String, dynamic> row) {
    return CouponRule(
      code: _asString(row['code']),
      name: _asString(row['name']),
      type: _asString(row['discount_type'], fallback: 'Percent'),
      value: _asDouble(row['value']),
      minimumSpend: _asDouble(row['minimum_spend']),
      usageLimit: _asInt(row['usage_limit'], fallback: 100),
      used: _asInt(row['used']),
      starts: _asString(row['starts_on']),
      ends: _asString(row['ends_on']),
      buyQuantity: _asInt(row['buy_quantity']),
      getQuantity: _asInt(row['get_quantity']),
      getPrice: _asDouble(row['get_price']),
      isActive: row['is_active'] != false,
      isArchived: row['is_archived'] == true,
    );
  }
}

class PaymentMethodConfig {
  PaymentMethodConfig({
    required this.name,
    required this.provider,
    required this.status,
    required this.fee,
    required this.settlement,
    this.isEnabled = true,
    this.mode = 'Test',
    this.publicKey = '',
    this.merchantId = '',
    this.apiSecret = '',
    this.webhookUrl = '',
    this.statementDescriptor = '',
  });

  String name;
  String provider;
  String status;
  String fee;
  String settlement;
  bool isEnabled;
  String mode;
  String publicKey;
  String merchantId;
  String apiSecret;
  String webhookUrl;
  String statementDescriptor;

  factory PaymentMethodConfig.fromRow(Map<String, dynamic> row) {
    return PaymentMethodConfig(
      name: _asString(row['name']),
      provider: _asString(row['provider']),
      status: _asString(row['status'], fallback: 'Not connected'),
      fee: _asString(row['fee']),
      settlement: _asString(row['settlement']),
      isEnabled: row['is_enabled'] != false,
      mode: _asString(row['mode'], fallback: 'Test'),
      publicKey: _asString(row['public_key']),
      merchantId: _asString(row['merchant_id']),
      apiSecret: _asString(row['api_secret']),
      webhookUrl: _asString(row['webhook_url']),
      statementDescriptor: _asString(
        row['statement_descriptor'],
        fallback: 'EGBE ANOM',
      ),
    );
  }
}

class NewsItem {
  const NewsItem({
    required this.source,
    required this.title,
    required this.summary,
    required this.url,
  });

  final String source;
  final String title;
  final String summary;
  final String url;
}

class FragranceNoteGuide {
  const FragranceNoteGuide({
    required this.name,
    required this.tier,
    required this.family,
    required this.description,
    required this.pairings,
  });

  factory FragranceNoteGuide.fromRow(Map<String, dynamic> row) =>
      FragranceNoteGuide(
        name: _asString(row['name']),
        tier: _asString(row['note_type'], fallback: 'ingredient'),
        family: _asString(row['family']),
        description: _asString(row['description']),
        pairings: _asString(row['pairings']),
      );

  final String name;
  final String tier;
  final String family;
  final String description;
  final String pairings;
}

class IngredientGuide {
  const IngredientGuide({
    required this.name,
    required this.profile,
    required this.role,
    required this.safety,
  });

  final String name;
  final String profile;
  final String role;
  final String safety;
}

class ContentBlock {
  ContentBlock({
    required this.id,
    required this.title,
    required this.placement,
    required this.body,
    required this.sortOrder,
    this.isVisible = true,
  });

  final int id;
  String title;
  String placement;
  String body;
  int sortOrder;
  bool isVisible;

  factory ContentBlock.fromRow(Map<String, dynamic> row) {
    return ContentBlock(
      id: _asInt(row['id']),
      title: _asString(row['title']),
      placement: _asString(row['placement']),
      body: _asString(row['body']),
      sortOrder: _asInt(row['sort_order'], fallback: 10),
      isVisible: row['is_visible'] != false,
    );
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? fallback;
}

double _asDouble(Object? value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? fallback;
}

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value';
  return text.isEmpty ? fallback : text;
}

Color _colorFromHex(String value) {
  final clean = value.replaceFirst('#', '');
  final hex = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFFC88F52);
}
