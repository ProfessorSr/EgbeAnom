part of '../main.dart';

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
