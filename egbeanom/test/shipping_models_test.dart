import 'package:flutter_test/flutter_test.dart';
import 'package:egbeanom/services/shipping_rate_gateway.dart';

void main() {
  group('ShippingCarrierCredentials', () {
    test('isConfigured is false for empty credentials', () {
      const creds = ShippingCarrierCredentials();
      expect(creds.isConfigured, isFalse);
    });

    test('isConfigured is true when account number is present', () {
      const creds = ShippingCarrierCredentials(accountNumber: '123456');
      expect(creds.isConfigured, isTrue);
    });

    test('fromJson parses known fields safely', () {
      final creds = ShippingCarrierCredentials.fromJson({
        'account_number': 'A1',
        'api_key': 'key',
        'client_id': 'client',
      });
      expect(creds.accountNumber, 'A1');
      expect(creds.apiKey, 'key');
      expect(creds.clientId, 'client');
      expect(creds.isConfigured, isTrue);
    });
  });

  group('ShippingLabelResult', () {
    test('fromJson applies defaults for missing fields', () {
      final label = ShippingLabelResult.fromJson(const {});
      expect(label.labelStatus, 'Label printed');
      expect(label.labelFileName, 'usps-label.pdf');
      expect(label.labelContentType, 'application/pdf');
      expect(label.postage, 0);
    });

    test('fromJson maps provided fields', () {
      final label = ShippingLabelResult.fromJson(const {
        'trackingNumber': '1Z999',
        'labelStatus': 'Label printed',
        'labelFileName': 'label.pdf',
        'labelContentType': 'application/pdf',
        'labelBase64': 'ZmFrZQ==',
        'trackingUrl': 'https://track.example/1Z999',
        'postage': 8.45,
        'estimatedDays': '2 days',
      });
      expect(label.trackingNumber, '1Z999');
      expect(label.labelBase64, 'ZmFrZQ==');
      expect(label.postage, 8.45);
      expect(label.estimatedDays, '2 days');
    });
  });
}
