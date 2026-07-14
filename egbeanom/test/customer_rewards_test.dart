import 'package:egbeanom/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Customer rewards and gift cards', () {
    test('CouponRule parses gift card balance fields', () {
      final coupon = CouponRule.fromRow({
        'code': 'GIFT100',
        'name': 'Gift card',
        'discount_type': 'Gift card',
        'value': 100,
        'remaining_balance': 72.50,
        'recipient_email': 'friend@example.com',
        'minimum_spend': 0,
        'usage_limit': 0,
        'used': 1,
        'starts_on': '',
        'ends_on': '',
        'is_active': true,
        'is_archived': false,
      });

      expect(coupon.code, 'GIFT100');
      expect(coupon.type, 'Gift card');
      expect(coupon.value, 100);
      expect(coupon.remainingBalance, 72.50);
      expect(coupon.recipientEmail, 'friend@example.com');
      expect(coupon.isActive, isTrue);
    });

    test('CustomerAccount parses loyalty and referral fields', () {
      final customer = CustomerAccount.fromRow({
        'id': 'CUS-1',
        'name': 'Avery Customer',
        'email': 'avery@example.com',
        'orders': 3,
        'lifetime_value': 210.25,
        'segment': 'Loyal',
        'referral_code': 'AVERY',
        'referral_credits': 15,
        'loyalty_points': 425,
        'referred_by': 'FRIEND',
      });

      expect(customer.referralCode, 'AVERY');
      expect(customer.referralCredits, 15);
      expect(customer.loyaltyPoints, 425);
      expect(customer.referredBy, 'FRIEND');
      expect(customer.toRow()['loyalty_points'], 425);
      expect(customer.toRow()['referred_by'], 'FRIEND');
    });
  });
}
