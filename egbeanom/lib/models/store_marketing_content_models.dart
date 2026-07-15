part of '../main.dart';

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
    this.remainingBalance = 0,
    this.recipientEmail = '',
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
  double remainingBalance;
  String recipientEmail;
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
      remainingBalance: _asDouble(row['remaining_balance']),
      recipientEmail: _asString(row['recipient_email']),
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
    this.checkoutUrl = '',
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
  String checkoutUrl;
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
      checkoutUrl: _asString(
        row['checkout_url'],
        fallback: _asString(row['webhook_url']),
      ),
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

class InternationalTaxRate {
  const InternationalTaxRate({
    required this.code,
    required this.country,
    required this.rate,
  });

  final String code;
  final String country;
  final double rate;

  String get displayName => '$country (${(rate * 100).toStringAsFixed(1)}%)';
}

const List<InternationalTaxRate> standardInternationalTaxRates = [
  InternationalTaxRate(code: 'AR', country: 'Argentina', rate: 0.21),
  InternationalTaxRate(code: 'AU', country: 'Australia', rate: 0.10),
  InternationalTaxRate(code: 'AT', country: 'Austria', rate: 0.20),
  InternationalTaxRate(code: 'BE', country: 'Belgium', rate: 0.21),
  InternationalTaxRate(code: 'BG', country: 'Bulgaria', rate: 0.20),
  InternationalTaxRate(code: 'BR', country: 'Brazil', rate: 0.17),
  InternationalTaxRate(code: 'CA', country: 'Canada', rate: 0.05),
  InternationalTaxRate(code: 'CL', country: 'Chile', rate: 0.19),
  InternationalTaxRate(code: 'CO', country: 'Colombia', rate: 0.19),
  InternationalTaxRate(code: 'HR', country: 'Croatia', rate: 0.25),
  InternationalTaxRate(code: 'CY', country: 'Cyprus', rate: 0.19),
  InternationalTaxRate(code: 'CZ', country: 'Czech Republic', rate: 0.21),
  InternationalTaxRate(code: 'DK', country: 'Denmark', rate: 0.25),
  InternationalTaxRate(code: 'EG', country: 'Egypt', rate: 0.14),
  InternationalTaxRate(code: 'EE', country: 'Estonia', rate: 0.22),
  InternationalTaxRate(code: 'FI', country: 'Finland', rate: 0.255),
  InternationalTaxRate(code: 'FR', country: 'France', rate: 0.20),
  InternationalTaxRate(code: 'DE', country: 'Germany', rate: 0.19),
  InternationalTaxRate(code: 'GH', country: 'Ghana', rate: 0.15),
  InternationalTaxRate(code: 'GR', country: 'Greece', rate: 0.24),
  InternationalTaxRate(code: 'HU', country: 'Hungary', rate: 0.27),
  InternationalTaxRate(code: 'IS', country: 'Iceland', rate: 0.24),
  InternationalTaxRate(code: 'IN', country: 'India', rate: 0.18),
  InternationalTaxRate(code: 'IE', country: 'Ireland', rate: 0.23),
  InternationalTaxRate(code: 'IL', country: 'Israel', rate: 0.18),
  InternationalTaxRate(code: 'IT', country: 'Italy', rate: 0.22),
  InternationalTaxRate(code: 'JP', country: 'Japan', rate: 0.10),
  InternationalTaxRate(code: 'KE', country: 'Kenya', rate: 0.16),
  InternationalTaxRate(code: 'LV', country: 'Latvia', rate: 0.21),
  InternationalTaxRate(code: 'LT', country: 'Lithuania', rate: 0.21),
  InternationalTaxRate(code: 'LU', country: 'Luxembourg', rate: 0.17),
  InternationalTaxRate(code: 'MY', country: 'Malaysia', rate: 0.08),
  InternationalTaxRate(code: 'MT', country: 'Malta', rate: 0.18),
  InternationalTaxRate(code: 'MX', country: 'Mexico', rate: 0.16),
  InternationalTaxRate(code: 'MA', country: 'Morocco', rate: 0.20),
  InternationalTaxRate(code: 'NL', country: 'Netherlands', rate: 0.21),
  InternationalTaxRate(code: 'NZ', country: 'New Zealand', rate: 0.15),
  InternationalTaxRate(code: 'NG', country: 'Nigeria', rate: 0.075),
  InternationalTaxRate(code: 'NO', country: 'Norway', rate: 0.25),
  InternationalTaxRate(code: 'PL', country: 'Poland', rate: 0.23),
  InternationalTaxRate(code: 'PT', country: 'Portugal', rate: 0.23),
  InternationalTaxRate(code: 'RO', country: 'Romania', rate: 0.19),
  InternationalTaxRate(code: 'SA', country: 'Saudi Arabia', rate: 0.15),
  InternationalTaxRate(code: 'SG', country: 'Singapore', rate: 0.09),
  InternationalTaxRate(code: 'SK', country: 'Slovakia', rate: 0.20),
  InternationalTaxRate(code: 'SI', country: 'Slovenia', rate: 0.22),
  InternationalTaxRate(code: 'ZA', country: 'South Africa', rate: 0.15),
  InternationalTaxRate(code: 'KR', country: 'South Korea', rate: 0.10),
  InternationalTaxRate(code: 'ES', country: 'Spain', rate: 0.21),
  InternationalTaxRate(code: 'SE', country: 'Sweden', rate: 0.25),
  InternationalTaxRate(code: 'CH', country: 'Switzerland', rate: 0.081),
  InternationalTaxRate(code: 'TR', country: 'Turkey', rate: 0.20),
  InternationalTaxRate(code: 'AE', country: 'United Arab Emirates', rate: 0.05),
  InternationalTaxRate(code: 'GB', country: 'United Kingdom', rate: 0.20),
];

const Map<String, String> countryAliases = {
  'USA': 'US',
  'U.S.': 'US',
  'U.S.A.': 'US',
  'UNITED STATES': 'US',
  'UNITED STATES OF AMERICA': 'US',
  'AMERICA': 'US',
  'UK': 'GB',
  'U.K.': 'GB',
  'GREAT BRITAIN': 'GB',
  'BRITAIN': 'GB',
  'ENGLAND': 'GB',
  'SCOTLAND': 'GB',
  'WALES': 'GB',
  'SOUTH KOREA': 'KR',
  'KOREA': 'KR',
  'CZECHIA': 'CZ',
};

String normalizeCountryCode(String value) {
  final clean = value.trim().toUpperCase();
  if (clean.isEmpty) {
    return '';
  }
  if (clean.length == 2) {
    return clean;
  }
  final alias = countryAliases[clean];
  if (alias != null) {
    return alias;
  }
  for (final rate in standardInternationalTaxRates) {
    if (rate.country.toUpperCase() == clean) {
      return rate.code;
    }
  }
  return clean;
}

String countryNameForCode(String value) {
  final code = normalizeCountryCode(value);
  for (final rate in standardInternationalTaxRates) {
    if (rate.code == code) {
      return rate.country;
    }
  }
  if (code == 'US') {
    return 'United States';
  }
  return value.trim().isEmpty ? code : value.trim();
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
    return value.isFinite ? value : fallback;
  }
  if (value is num) {
    final parsed = value.toDouble();
    return parsed.isFinite ? parsed : fallback;
  }
  final parsed = double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) {
    return fallback;
  }
  return parsed;
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
