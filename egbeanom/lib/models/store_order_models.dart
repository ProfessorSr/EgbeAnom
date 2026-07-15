part of '../main.dart';

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
    this.checkoutToken = '',
    this.financialStatus = 'Pending',
    this.fulfillmentStatus = 'Pending',
    this.shippingCarrier = '',
    this.shippingService = '',
    this.shippingPriority = 'Standard',
    this.shippingTotal = 0,
    this.subtotal = 0,
    this.discountTotal = 0,
    this.couponCode = '',
    this.taxBreakdown = const [],
    this.trackingNumber = '',
    this.trackingStatus = '',
    this.trackingUrl = '',
    this.trackingLastCheckedAt,
    this.labelStatus = 'Not requested',
    this.refundStatus = 'Not refunded',
    this.refundTotal = 0,
    this.refundReference = '',
    this.refundReason = '',
    this.refundedAt,
    this.returnStatus = 'No return',
    this.returnReason = '',
    this.returnItems = const [],
    this.returnAdminComment = '',
    this.returnCondition = '',
    this.refundOption = '',
    this.stripeRefundId = '',
    this.rmaNumber = '',
    this.rmaCreatedAt,
    this.returnRequestedAt,
    this.returnDecisionAt,
    this.returnRestocked = false,
    this.returnedAt,
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
  String checkoutToken;
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
  String trackingStatus;
  String trackingUrl;
  DateTime? trackingLastCheckedAt;
  String labelStatus;
  String refundStatus;
  double refundTotal;
  String refundReference;
  String refundReason;
  DateTime? refundedAt;
  String returnStatus;
  String returnReason;
  List<ReturnRequestItem> returnItems;
  String returnAdminComment;
  String returnCondition;
  String refundOption;
  String stripeRefundId;
  String rmaNumber;
  DateTime? rmaCreatedAt;
  DateTime? returnRequestedAt;
  DateTime? returnDecisionAt;
  bool returnRestocked;
  DateTime? returnedAt;
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
    final returnItems = <ReturnRequestItem>[];
    final returnRows = row['return_items'];
    if (returnRows is List) {
      for (final returnRow in returnRows) {
        if (returnRow is Map) {
          returnItems.add(
            ReturnRequestItem.fromRow(returnRow.cast<String, dynamic>()),
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
      checkoutToken: _asString(row['checkout_token']),
      financialStatus: _asString(row['financial_status'], fallback: 'Pending'),
      fulfillmentStatus: _asString(
        row['fulfillment_status'],
        fallback: 'Pending',
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
      trackingStatus: _asString(row['tracking_status']),
      trackingUrl: _asString(row['tracking_url']),
      trackingLastCheckedAt: DateTime.tryParse(
        _asString(row['tracking_last_checked_at']),
      ),
      labelStatus: _asString(row['label_status'], fallback: 'Not requested'),
      refundStatus: _asString(row['refund_status'], fallback: 'Not refunded'),
      refundTotal: _asDouble(row['refund_total']),
      refundReference: _asString(row['refund_reference']),
      refundReason: _asString(row['refund_reason']),
      refundedAt: DateTime.tryParse(_asString(row['refunded_at'])),
      returnStatus: _asString(row['return_status'], fallback: 'No return'),
      returnReason: _asString(row['return_reason']),
      returnItems: returnItems,
      returnAdminComment: _asString(row['return_admin_comment']),
      returnCondition: _asString(row['return_condition']),
      refundOption: _asString(row['refund_option']),
      stripeRefundId: _asString(row['stripe_refund_id']),
      rmaNumber: _asString(row['rma_number']),
      rmaCreatedAt: DateTime.tryParse(_asString(row['rma_created_at'])),
      returnRequestedAt: DateTime.tryParse(
        _asString(row['return_requested_at']),
      ),
      returnDecisionAt: DateTime.tryParse(_asString(row['return_decision_at'])),
      returnRestocked: row['return_restocked'] == true,
      returnedAt: DateTime.tryParse(_asString(row['returned_at'])),
      shippingAddress: ShippingAddress.fromJson(row['shipping_address']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      lines: parsedLines,
    );
  }
}

class ReturnRequestItem {
  const ReturnRequestItem({
    required this.sku,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
  });

  final String sku;
  final String productName;
  final String size;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;

  factory ReturnRequestItem.fromLine(CartLine line) {
    return ReturnRequestItem(
      sku: line.sku,
      productName: line.product.name,
      size: line.size,
      quantity: line.quantity,
      unitPrice: line.unitPrice,
    );
  }

  factory ReturnRequestItem.fromRow(Map<String, dynamic> row) {
    return ReturnRequestItem(
      sku: _asString(row['sku']),
      productName: _asString(row['product_name'], fallback: 'Return item'),
      size: _asString(row['size']),
      quantity: _asInt(row['quantity'], fallback: 1),
      unitPrice: _asDouble(row['unit_price']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'product_name': productName,
    'size': size,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
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
