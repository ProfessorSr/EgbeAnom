part of '../main.dart';

extension _StoreRewardProgram on _StoreShellState {
  CouponRule? get _validAppliedCoupon {
    final coupon = _appliedCoupon;
    if (coupon == null) {
      return null;
    }
    return _couponValidationMessage(coupon).isEmpty ? coupon : null;
  }

  double get _itemDiscount {
    final coupon = _validAppliedCoupon;
    if (coupon == null) {
      return 0;
    }
    return switch (coupon.type) {
      'Percent' => _cartSubtotal * coupon.value.clamp(0, 100) / 100,
      'Fixed amount' => math.min(_cartSubtotal, math.max(0, coupon.value)),
      'Buy X get Y' => _buyXGetYDiscount(coupon),
      _ => 0,
    };
  }

  double _buyXGetYDiscount(CouponRule coupon) {
    final buyQuantity = coupon.buyQuantity;
    final getQuantity = coupon.getQuantity;
    if (buyQuantity <= 0 || getQuantity <= 0 || coupon.getPrice < 0) {
      return 0;
    }
    final groupSize = buyQuantity + getQuantity;
    final unitPrices = <double>[
      for (final line in _cart)
        for (var i = 0; i < line.quantity; i++) line.unitPrice,
    ]..sort();
    final eligibleCount = (unitPrices.length ~/ groupSize) * getQuantity;
    if (eligibleCount <= 0) {
      return 0;
    }
    return unitPrices.take(eligibleCount).fold<double>(0, (total, price) {
      return total + math.max(0, price - coupon.getPrice);
    });
  }

  double get _shippingDiscount => _validAppliedCoupon?.type == 'Free shipping'
      ? _shippingBeforeDiscount
      : 0;

  double get _codeCredit {
    final coupon = _validAppliedCoupon;
    if (coupon == null) {
      return 0;
    }
    if (coupon.type == 'Gift card') {
      return math.min(_preCreditTotal, math.max(0, coupon.remainingBalance));
    }
    if (coupon.type == 'Referral credit') {
      return math.min(_preCreditTotal, math.max(0, coupon.value));
    }
    if (coupon.type == 'Loyalty credit') {
      return math.min(_preCreditTotal, math.max(0, coupon.value));
    }
    return 0;
  }

  double get _discountTotal => _itemDiscount + _shippingDiscount + _codeCredit;

  Future<void> _applyPromoCode() async {
    final code = _promoCode.trim().toUpperCase();
    if (code.isEmpty) {
      _updateStoreState(() => _promoMessage = 'Enter a promotional code.');
      return;
    }
    CouponRule? coupon;
    for (final item in _coupons) {
      if (item.code.trim().toUpperCase() == code) {
        coupon = item;
        break;
      }
    }
    if (coupon == null) {
      try {
        final row = await _gateway.findRedeemableCoupon(code);
        if (row != null) {
          coupon = CouponRule.fromRow(row);
        }
      } catch (_) {}
    }
    coupon ??= _referralCouponForCode(code);
    coupon ??= _loyaltyCouponForCode(code);
    if (coupon == null) {
      _updateStoreState(() {
        _appliedCoupon = null;
        _promoMessage = 'Code not found.';
      });
      return;
    }
    final matchedCoupon = coupon;
    final message = _couponValidationMessage(matchedCoupon);
    _updateStoreState(() {
      if (message.isEmpty) {
        _promoCode = code;
        _appliedCoupon = matchedCoupon;
        _promoMessage = _appliedCodeMessage(matchedCoupon);
      } else {
        _appliedCoupon = null;
        _promoMessage = message;
      }
    });
  }

  CouponRule? _referralCouponForCode(String code) {
    final currentEmail = _currentCustomer?.email.trim().toLowerCase() ?? '';
    for (final customer in _customers) {
      final referralCode = customer.referralCode.trim().toUpperCase();
      if (referralCode == code &&
          customer.email.trim().toLowerCase() != currentEmail) {
        return CouponRule(
          code: code,
          name: 'Referral reward',
          type: 'Referral credit',
          value: 5,
          minimumSpend: 0,
          usageLimit: 0,
          used: 0,
          starts: '',
          ends: '',
          isActive: true,
        );
      }
    }
    return null;
  }

  CouponRule? _loyaltyCouponForCode(String code) {
    if (code != 'LOYALTY') {
      return null;
    }
    final customer = _currentCustomer;
    if (customer == null) {
      return CouponRule(
        code: code,
        name: 'Loyalty credit',
        type: 'Loyalty credit',
        value: 0,
        minimumSpend: 0,
        usageLimit: 0,
        used: 0,
        starts: '',
        ends: '',
        isActive: false,
      );
    }
    final earnedCredit = (customer.loyaltyPoints ~/ 100) * 5.0;
    final availableCredit = earnedCredit + customer.referralCredits;
    return CouponRule(
      code: code,
      name: 'Loyalty and referral credit',
      type: 'Loyalty credit',
      value: availableCredit,
      minimumSpend: 0,
      usageLimit: 0,
      used: 0,
      starts: '',
      ends: '',
      isActive: true,
    );
  }

  String _appliedCodeMessage(CouponRule coupon) {
    if (coupon.type == 'Gift card') {
      return '${coupon.code} applied. Balance available: ${currency(coupon.remainingBalance)}.';
    }
    if (coupon.type == 'Referral credit') {
      return 'Referral code applied for ${currency(coupon.value)} off.';
    }
    if (coupon.type == 'Loyalty credit') {
      return 'Loyalty credit applied for up to ${currency(coupon.value)}.';
    }
    return '${coupon.code} applied.';
  }

  String _couponValidationMessage(CouponRule coupon) {
    if (!coupon.isActive || coupon.isArchived) {
      return 'This promotional code is not active.';
    }
    if (coupon.type == 'Gift card' && coupon.remainingBalance <= 0) {
      return 'This gift card has no remaining balance.';
    }
    if (coupon.type == 'Loyalty credit' && coupon.value <= 0) {
      return 'No loyalty or referral credit is available yet.';
    }
    if (coupon.type == 'Referral credit' && coupon.value <= 0) {
      return 'This referral code is not available.';
    }
    if (coupon.type == 'Buy X get Y') {
      if (coupon.buyQuantity <= 0 || coupon.getQuantity <= 0) {
        return 'This promotional code is missing buy/get quantities.';
      }
      if (_cartCount < coupon.buyQuantity + coupon.getQuantity) {
        return 'Add ${coupon.buyQuantity + coupon.getQuantity} eligible item(s) to use ${coupon.code}.';
      }
    }
    if (coupon.usageLimit > 0 && coupon.used >= coupon.usageLimit) {
      return 'This promotional code has reached its usage limit.';
    }
    if (_cartSubtotal < coupon.minimumSpend) {
      return 'Minimum spend for ${coupon.code} is ${currency(coupon.minimumSpend)}.';
    }
    final now = DateTime.now();
    final starts = DateTime.tryParse(coupon.starts.trim());
    if (starts != null && now.isBefore(starts)) {
      return 'This promotional code is not active yet.';
    }
    final ends = DateTime.tryParse(coupon.ends.trim());
    if (ends != null) {
      final endOfDay = DateTime(ends.year, ends.month, ends.day, 23, 59, 59);
      if (now.isAfter(endOfDay)) {
        return 'This promotional code has expired.';
      }
    }
    return '';
  }

  Future<void> _settlePaidOrderRewards(Order order) async {
    final code = order.couponCode.trim().toUpperCase();
    CouponRule? coupon;
    for (final item in _coupons) {
      if (item.code.trim().toUpperCase() == code) {
        coupon = item;
        break;
      }
    }
    if (coupon == null && code.isNotEmpty) {
      try {
        final row = await _gateway.findRedeemableCoupon(code);
        if (row != null) {
          coupon = CouponRule.fromRow(row);
        }
      } catch (_) {}
    }
    if (coupon != null) {
      coupon.used += 1;
      if (coupon.type == 'Gift card') {
        coupon.remainingBalance = math.max(
          0,
          coupon.remainingBalance - order.discountTotal,
        );
      }
      try {
        await _gateway.upsertCouponRule(_couponRow(coupon));
      } catch (error) {
        _showStatusSnack(
          'Payment succeeded, but promotion update failed: $error',
        );
      }
    }

    final customer = _currentCustomer;
    if (customer != null) {
      customer.orders += 1;
      customer.lifetimeValue += order.total;
      if (code == 'LOYALTY' && order.discountTotal > 0) {
        var remainingCredit = order.discountTotal;
        final referralUse = math.min(customer.referralCredits, remainingCredit);
        customer.referralCredits -= referralUse;
        remainingCredit -= referralUse;
        if (remainingCredit > 0) {
          final pointsToUse = math.min(
            customer.loyaltyPoints,
            ((remainingCredit / 5).ceil() * 100),
          );
          customer.loyaltyPoints -= pointsToUse;
        }
      }
      customer.loyaltyPoints += order.total.floor();
      try {
        await _gateway.upsertCustomer(customer.toRow());
      } catch (_) {}
    }

    if (code.isNotEmpty && coupon == null && code != 'LOYALTY') {
      for (final referrer in _customers) {
        if (referrer.referralCode.trim().toUpperCase() == code &&
            referrer.email.trim().toLowerCase() !=
                order.email.trim().toLowerCase()) {
          referrer.referralCredits += 5;
          try {
            await _gateway.upsertCustomer(referrer.toRow());
          } catch (_) {}
          break;
        }
      }
    }
  }
}
