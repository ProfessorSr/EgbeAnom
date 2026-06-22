import 'dart:convert';

class ShippingRateRequest {
  const ShippingRateRequest({
    required this.carrier,
    required this.service,
    required this.originZip,
    required this.destinationZip,
    required this.weightOz,
    required this.lengthIn,
    required this.widthIn,
    required this.heightIn,
  });

  final String carrier;
  final String service;
  final String originZip;
  final String destinationZip;
  final double weightOz;
  final double lengthIn;
  final double widthIn;
  final double heightIn;
}

class ShippingCarrierCredentials {
  const ShippingCarrierCredentials({
    this.customerId = '',
    this.accountNumber = '',
    this.apiKey = '',
    this.apiSecret = '',
    this.meterNumber = '',
    this.clientId = '',
    this.clientSecret = '',
  });

  final String customerId;
  final String accountNumber;
  final String apiKey;
  final String apiSecret;
  final String meterNumber;
  final String clientId;
  final String clientSecret;

  bool get isConfigured =>
      customerId.isNotEmpty ||
      accountNumber.isNotEmpty ||
      apiKey.isNotEmpty ||
      clientId.isNotEmpty;
}

class ShippingRateQuote {
  const ShippingRateQuote({
    required this.carrier,
    required this.service,
    required this.amount,
    required this.currency,
    required this.estimatedDays,
  });

  final String carrier;
  final String service;
  final double amount;
  final String currency;
  final String estimatedDays;
}

class ShippingRateGateway {
  const ShippingRateGateway();

  Future<List<ShippingRateQuote>> quote({
    required ShippingRateRequest request,
    required ShippingCarrierCredentials credentials,
  }) async {
    if (!credentials.isConfigured) {
      return const [];
    }
    return switch (request.carrier.toUpperCase()) {
      'UPS' => _quoteUps(request, credentials),
      'DHL' => _quoteDhl(request, credentials),
      'FEDEX' => _quoteFedEx(request, credentials),
      'USPS' => _quoteUsps(request, credentials),
      _ => const [],
    };
  }

  Future<List<ShippingRateQuote>> _quoteUps(
    ShippingRateRequest request,
    ShippingCarrierCredentials credentials,
  ) async {
    final payload = {
      'RateRequest': {
        'Request': {
          'TransactionReference': {'CustomerContext': 'EgbeAnom'},
        },
        'Shipment': _packagePayload(request, credentials),
      },
    };
    return _notYetSubmitted('UPS', request, payload);
  }

  Future<List<ShippingRateQuote>> _quoteFedEx(
    ShippingRateRequest request,
    ShippingCarrierCredentials credentials,
  ) async {
    final payload = {
      'accountNumber': {'value': credentials.accountNumber},
      'requestedShipment': _packagePayload(request, credentials),
    };
    return _notYetSubmitted('FedEx', request, payload);
  }

  Future<List<ShippingRateQuote>> _quoteDhl(
    ShippingRateRequest request,
    ShippingCarrierCredentials credentials,
  ) async {
    final payload = {
      'customerDetails': {
        'shipperDetails': {'postalCode': request.originZip},
      },
      'accounts': [
        {'number': credentials.accountNumber, 'typeCode': 'shipper'},
      ],
      'packages': [_packagePayload(request, credentials)],
    };
    return _notYetSubmitted('DHL', request, payload);
  }

  Future<List<ShippingRateQuote>> _quoteUsps(
    ShippingRateRequest request,
    ShippingCarrierCredentials credentials,
  ) async {
    final payload = {
      'originZIPCode': request.originZip,
      'destinationZIPCode': request.destinationZip,
      'weight': request.weightOz,
      'length': request.lengthIn,
      'width': request.widthIn,
      'height': request.heightIn,
      'mailClass': request.service,
      'customerRegistrationId': credentials.customerId,
    };
    return _notYetSubmitted('USPS', request, payload);
  }

  Map<String, Object> _packagePayload(
    ShippingRateRequest request,
    ShippingCarrierCredentials credentials,
  ) {
    return {
      'shipperAccount': credentials.accountNumber,
      'originZip': request.originZip,
      'destinationZip': request.destinationZip,
      'service': request.service,
      'package': {
        'weightOz': request.weightOz,
        'lengthIn': request.lengthIn,
        'widthIn': request.widthIn,
        'heightIn': request.heightIn,
      },
    };
  }

  Future<List<ShippingRateQuote>> _notYetSubmitted(
    String carrier,
    ShippingRateRequest request,
    Map<String, Object?> payload,
  ) async {
    // Keep secrets and carrier calls server-side. The encoded payload lets the
    // backend adapter log exactly what would be sent once credentials are added.
    jsonEncode(payload);
    return [
      ShippingRateQuote(
        carrier: carrier,
        service: request.service,
        amount: 0,
        currency: 'USD',
        estimatedDays: 'Carrier-calculated after credentials are connected',
      ),
    ];
  }
}
