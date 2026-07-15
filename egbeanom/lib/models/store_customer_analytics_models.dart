part of '../main.dart';

class EmailServerSettings {
  EmailServerSettings({
    this.id = 'default',
    this.label = 'Default mailbox',
    this.provider = 'generic',
    this.fromName = 'Egbe Anom',
    this.fromEmail = 'orders@egbeanom.com',
    this.imapHost = '',
    this.imapPort = 993,
    this.smtpHost = '',
    this.smtpPort = 587,
    this.username = '',
    this.password = '',
    this.useSsl = false,
    List<EmailServerSettings>? accounts,
  });

  String id;
  String label;
  String provider;
  String fromName;
  String fromEmail;
  String imapHost;
  int imapPort;
  String smtpHost;
  int smtpPort;
  String username;
  String password;
  bool useSsl;
  List<EmailServerSettings> accounts = [];

  String get displayLabel {
    final cleanLabel = label.trim();
    if (cleanLabel.isNotEmpty && cleanLabel != 'Default mailbox') {
      return cleanLabel;
    }
    return fromEmail.trim().isNotEmpty ? fromEmail.trim() : 'Default mailbox';
  }

  List<EmailServerSettings> get allAccounts {
    if (accounts.isNotEmpty) {
      return accounts;
    }
    return [copyWithoutAccounts()];
  }

  EmailServerSettings copyWithoutAccounts() {
    return EmailServerSettings(
      id: id,
      label: label,
      provider: provider,
      fromName: fromName,
      fromEmail: fromEmail,
      imapHost: imapHost,
      imapPort: imapPort,
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      username: username,
      password: password,
      useSsl: useSsl,
    );
  }

  factory EmailServerSettings.fromRow(Map<String, dynamic> row) {
    final value = row['value'];
    if (value is Map) {
      final parsedAccounts = <EmailServerSettings>[];
      final accountRows = value['accounts'];
      if (accountRows is List) {
        for (final accountRow in accountRows) {
          if (accountRow is Map) {
            parsedAccounts.add(
              EmailServerSettings.fromJson(accountRow.cast<String, dynamic>()),
            );
          }
        }
      }
      final fallback = EmailServerSettings.fromJson(
        value.cast<String, dynamic>(),
      );
      final accounts = parsedAccounts.isEmpty ? [fallback] : parsedAccounts;
      final defaultId = _asString(
        value['default_account_id'],
        fallback: accounts.first.id,
      );
      final primary = accounts.firstWhere(
        (account) => account.id == defaultId,
        orElse: () => accounts.first,
      );
      primary.accounts = accounts;
      return primary;
    }
    return EmailServerSettings();
  }

  factory EmailServerSettings.fromJson(Map<String, dynamic> value) {
    return EmailServerSettings(
      id: _asString(
        value['id'],
        fallback: _asString(value['from_email'], fallback: 'default')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-|-$'), ''),
      ),
      label: _asString(value['label'], fallback: 'Default mailbox'),
      provider: _asString(value['provider'], fallback: 'generic'),
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
      password: _asString(value['password']),
      useSsl: value['use_ssl'] == true,
    );
  }

  Map<String, dynamic> accountJson() => {
    'id': id,
    'label': label,
    'provider': provider,
    'from_name': fromName,
    'from_email': fromEmail,
    'imap_host': imapHost,
    'imap_port': imapPort,
    'smtp_host': smtpHost,
    'smtp_port': smtpPort,
    'username': username,
    'password': password,
    'use_ssl': useSsl,
  };

  Map<String, dynamic> toJson() {
    final normalizedAccounts = allAccounts.map((account) {
      final copy = account.copyWithoutAccounts();
      return copy.accountJson();
    }).toList();
    final primary = normalizedAccounts.firstWhere(
      (account) => account['id'] == id,
      orElse: () => normalizedAccounts.first,
    );
    return {
      ...primary,
      'default_account_id': primary['id'],
      'accounts': normalizedAccounts,
    };
  }
}

class EmailMessage {
  EmailMessage({
    required this.id,
    required this.messageId,
    this.serverUid = 0,
    this.accountId = 'default',
    this.accountEmail = '',
    required this.mailbox,
    required this.fromEmail,
    required this.fromName,
    required this.toEmail,
    required this.subject,
    required this.preview,
    required this.textBody,
    required this.htmlBody,
    required this.receivedAt,
    this.isRead = false,
    this.orderNumber = '',
  });

  final String id;
  final String messageId;
  final int serverUid;
  final String accountId;
  final String accountEmail;
  final String mailbox;
  final String fromEmail;
  final String fromName;
  final String toEmail;
  final String subject;
  final String preview;
  final String textBody;
  final String htmlBody;
  final DateTime receivedAt;
  bool isRead;
  final String orderNumber;

  factory EmailMessage.fromRow(Map<String, dynamic> row) {
    return EmailMessage(
      id: _asString(row['id']),
      messageId: _asString(row['message_id']),
      serverUid: _asInt(row['server_uid']),
      accountId: _asString(row['account_id'], fallback: 'default'),
      accountEmail: _asString(row['account_email']),
      mailbox: _asString(row['mailbox'], fallback: 'INBOX'),
      fromEmail: _asString(row['from_email']),
      fromName: _asString(row['from_name']),
      toEmail: _asString(row['to_email']),
      subject: _asString(row['subject'], fallback: '(No subject)'),
      preview: _asString(row['preview']),
      textBody: _asString(row['text_body']),
      htmlBody: _asString(row['html_body']),
      receivedAt:
          DateTime.tryParse(_asString(row['received_at'])) ?? DateTime.now(),
      isRead: row['is_read'] == true,
      orderNumber: _asString(row['order_number']),
    );
  }
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
    this.loyaltyPoints = 0,
    this.referredBy = '',
    this.acceptsMarketing = false,
    this.isNew = false,
    this.isBlocked = false,
    this.createdIp = '',
    this.lastLoginIp = '',
    this.createdSource = '',
    this.lastLoginSource = '',
    this.blockedReason = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.county = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'US',
    this.billingAddressLine1 = '',
    this.billingAddressLine2 = '',
    this.billingCity = '',
    this.billingCounty = '',
    this.billingState = '',
    this.billingPostalCode = '',
    this.billingCountry = 'US',
    this.phone = '',
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  String name;
  String email;
  final int joinedDaysAgo;
  int orders;
  double lifetimeValue;
  String segment;
  String referralCode;
  double referralCredits;
  int loyaltyPoints;
  String referredBy;
  bool acceptsMarketing;
  final bool isNew;
  bool isBlocked;
  String createdIp;
  String lastLoginIp;
  String createdSource;
  String lastLoginSource;
  String blockedReason;
  String addressLine1;
  String addressLine2;
  String city;
  String county;
  String state;
  String postalCode;
  String country;
  String billingAddressLine1;
  String billingAddressLine2;
  String billingCity;
  String billingCounty;
  String billingState;
  String billingPostalCode;
  String billingCountry;
  String phone;
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
      referralCredits: _asDouble(row['referral_credits']),
      loyaltyPoints: _asInt(row['loyalty_points']),
      referredBy: _asString(row['referred_by']),
      acceptsMarketing: row['accepts_marketing'] == true,
      isBlocked: row['is_blocked'] == true,
      createdIp: _asString(row['created_ip']),
      lastLoginIp: _asString(row['last_login_ip']),
      createdSource: _asString(row['created_source']),
      lastLoginSource: _asString(row['last_login_source']),
      blockedReason: _asString(row['blocked_reason']),
      addressLine1: _asString(row['address_line1']),
      addressLine2: _asString(row['address_line2']),
      city: _asString(row['city']),
      county: _asString(row['county']),
      state: _asString(row['state']),
      postalCode: _asString(row['postal_code']),
      country: _asString(row['country'], fallback: 'US'),
      billingAddressLine1: _asString(row['billing_address_line1']),
      billingAddressLine2: _asString(row['billing_address_line2']),
      billingCity: _asString(row['billing_city']),
      billingCounty: _asString(row['billing_county']),
      billingState: _asString(row['billing_state']),
      billingPostalCode: _asString(row['billing_postal_code']),
      billingCountry: _asString(row['billing_country'], fallback: 'US'),
      phone: _asString(row['phone']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      lastLoginAt: DateTime.tryParse(_asString(row['last_login_at'])),
    );
  }

  CustomerAccount copyWith({
    String? name,
    String? email,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? county,
    String? state,
    String? postalCode,
    String? country,
    String? billingAddressLine1,
    String? billingAddressLine2,
    String? billingCity,
    String? billingCounty,
    String? billingState,
    String? billingPostalCode,
    String? billingCountry,
    double? referralCredits,
    int? loyaltyPoints,
    String? referralCode,
    String? referredBy,
    String? segment,
    bool? acceptsMarketing,
  }) {
    return CustomerAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      joinedDaysAgo: joinedDaysAgo,
      orders: orders,
      lifetimeValue: lifetimeValue,
      segment: segment ?? this.segment,
      referralCode: referralCode ?? this.referralCode,
      referralCredits: referralCredits ?? this.referralCredits,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      referredBy: referredBy ?? this.referredBy,
      acceptsMarketing: acceptsMarketing ?? this.acceptsMarketing,
      isNew: isNew,
      isBlocked: isBlocked,
      createdIp: createdIp,
      lastLoginIp: lastLoginIp,
      createdSource: createdSource,
      lastLoginSource: lastLoginSource,
      blockedReason: blockedReason,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      county: county ?? this.county,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      billingAddressLine1: billingAddressLine1 ?? this.billingAddressLine1,
      billingAddressLine2: billingAddressLine2 ?? this.billingAddressLine2,
      billingCity: billingCity ?? this.billingCity,
      billingCounty: billingCounty ?? this.billingCounty,
      billingState: billingState ?? this.billingState,
      billingPostalCode: billingPostalCode ?? this.billingPostalCode,
      billingCountry: billingCountry ?? this.billingCountry,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
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
    'loyalty_points': loyaltyPoints,
    'referred_by': referredBy,
    'accepts_marketing': acceptsMarketing,
    'is_blocked': isBlocked,
    'created_ip': createdIp,
    'last_login_ip': lastLoginIp,
    'created_source': createdSource,
    'last_login_source': lastLoginSource,
    'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
    'blocked_reason': blockedReason,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city': city,
    'county': county,
    'state': state,
    'postal_code': postalCode,
    'country': country,
    'billing_address_line1': billingAddressLine1,
    'billing_address_line2': billingAddressLine2,
    'billing_city': billingCity,
    'billing_county': billingCounty,
    'billing_state': billingState,
    'billing_postal_code': billingPostalCode,
    'billing_country': billingCountry,
    'phone': phone,
  };
}

class MailingListSubscriber {
  MailingListSubscriber({
    required this.email,
    this.name = '',
    this.source = 'Storefront',
    this.isActive = true,
    this.subscribedAt,
    this.updatedAt,
  });

  final String email;
  String name;
  String source;
  bool isActive;
  DateTime? subscribedAt;
  DateTime? updatedAt;

  factory MailingListSubscriber.fromRow(Map<String, dynamic> row) {
    return MailingListSubscriber(
      email: _asString(row['email']).trim().toLowerCase(),
      name: _asString(row['name']),
      source: _asString(row['source'], fallback: 'Storefront'),
      isActive: row['is_active'] != false,
      subscribedAt: DateTime.tryParse(_asString(row['subscribed_at'])),
      updatedAt: DateTime.tryParse(_asString(row['updated_at'])),
    );
  }

  Map<String, dynamic> toRow() => {
    'email': email.trim().toLowerCase(),
    'name': name,
    'source': source,
    'is_active': isActive,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
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

  factory DailyMetric.fromRow(Map<String, dynamic> row) {
    return DailyMetric(
      day: _asString(row['label'], fallback: _asString(row['day'])),
      newUsers: _asInt(row['new_users']),
      visits: _asInt(row['visits']),
      orders: _asInt(row['orders']),
      revenue: _asDouble(row['revenue']),
    );
  }
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

  factory ActiveUserSession.fromRow(Map<String, dynamic> row) {
    final now = DateTime.now();
    return ActiveUserSession(
      id: _asString(row['id']),
      visitor: _asString(row['visitor'], fallback: 'Guest visitor'),
      currentPage: _asString(row['current_page']),
      source: _asString(row['source'], fallback: 'Direct'),
      referrer: _asString(row['referrer'], fallback: 'Direct'),
      device: _asString(row['device'], fallback: 'Unknown device'),
      startedAt: DateTime.tryParse(_asString(row['started_at'])) ?? now,
      lastSeenAt: DateTime.tryParse(_asString(row['last_seen_at'])) ?? now,
    );
  }
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.id,
    required this.sessionId,
    required this.visitor,
    required this.eventName,
    required this.page,
    required this.source,
    required this.referrer,
    required this.device,
    this.productId,
    this.productName = '',
    this.orderId = '',
    this.value = 0,
    this.currency = 'USD',
    this.metadata = const {},
    required this.occurredAt,
  });

  final String id;
  final String sessionId;
  final String visitor;
  final String eventName;
  final String page;
  final String source;
  final String referrer;
  final String device;
  final int? productId;
  final String productName;
  final String orderId;
  final double value;
  final String currency;
  final Map<String, dynamic> metadata;
  final DateTime occurredAt;

  factory AnalyticsEvent.fromRow(Map<String, dynamic> row) {
    return AnalyticsEvent(
      id: _asString(row['id']),
      sessionId: _asString(row['session_id']),
      visitor: _asString(row['visitor'], fallback: 'Guest visitor'),
      eventName: _asString(row['event_name']),
      page: _asString(row['page']),
      source: _asString(row['source'], fallback: 'Direct'),
      referrer: _asString(row['referrer'], fallback: 'Direct'),
      device: _asString(row['device'], fallback: 'Unknown device'),
      productId: row['product_id'] == null ? null : _asInt(row['product_id']),
      productName: _asString(row['product_name']),
      orderId: _asString(row['order_id']),
      value: _asDouble(row['value']),
      currency: _asString(row['currency'], fallback: 'USD'),
      metadata: row['metadata'] is Map
          ? Map<String, dynamic>.from(row['metadata'] as Map)
          : const {},
      occurredAt:
          DateTime.tryParse(_asString(row['occurred_at'])) ?? DateTime.now(),
    );
  }
}
