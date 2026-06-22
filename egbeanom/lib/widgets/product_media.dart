part of '../main.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    required this.product,
    this.sourceOverride,
    this.iconSize = 34,
  });

  final Fragrance product;
  final String? sourceOverride;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ProductImageView(
      source: sourceOverride ?? product.primaryPhotoUrl,
      fallbackColor: product.featuredColor,
      iconSize: iconSize,
    );
  }
}

class ProductImageView extends StatelessWidget {
  const ProductImageView({
    super.key,
    required this.source,
    required this.fallbackColor,
    this.iconSize = 34,
  });

  final String source;
  final Color fallbackColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final clean = source.trim();
    if (clean.isEmpty) {
      return _fallback();
    }

    if (clean.startsWith('data:image/')) {
      final comma = clean.indexOf(',');
      if (comma != -1) {
        try {
          final bytes = base64Decode(clean.substring(comma + 1));
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {
          return _fallback();
        }
      }
    }

    if (clean.startsWith('assets/')) {
      return Image.asset(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return Image.network(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Icon(
      Icons.image_not_supported_outlined,
      color: fallbackColor,
      size: iconSize,
    );
  }
}
