/// Input validation helpers for production-ready data validation.
/// All validators follow a consistent pattern: return error message or null if valid.
library;

class Validators {
  /// Validates email format (simplified)
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final trimmed = email.trim().toLowerCase();
    // Simple email validation: must have @ and at least one character on each side
    if (!trimmed.contains('@') || trimmed.startsWith('@') || trimmed.endsWith('@')) {
      return 'Invalid email format';
    }
    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }
    if (parts[1].isEmpty || !parts[1].contains('.')) {
      return 'Invalid email format';
    }
    if (trimmed.length > 254) {
      return 'Email is too long (max 254 characters)';
    }
    return null;
  }

  /// Validates price is positive and within acceptable range
  static String? validatePrice(dynamic price) {
    if (price == null) {
      return 'Price is required';
    }
    final numPrice = price is num ? price : double.tryParse(price.toString());
    if (numPrice == null) {
      return 'Price must be a valid number';
    }
    if (numPrice <= 0) {
      return 'Price must be greater than 0';
    }
    if (numPrice > 999999.99) {
      return 'Price exceeds maximum allowed (999,999.99)';
    }
    // Check for reasonable decimal places
    if (numPrice.toStringAsFixed(2) != numPrice.toString()) {
      return 'Price must have at most 2 decimal places';
    }
    return null;
  }

  /// Validates US ZIP code format (5 or 9 digits)
  static String? validateZipCode(String? zip) {
    if (zip == null || zip.isEmpty) {
      return 'ZIP code is required';
    }
    final trimmed = zip.trim().replaceAll('-', '');
    if (!RegExp(r'^\d{5}(-?\d{4})?$').hasMatch(trimmed)) {
      return 'ZIP code must be 5 or 9 digits (e.g., 12345 or 12345-6789)';
    }
    return null;
  }

  /// Validates US state code (2 letters)
  static String? validateState(String? state) {
    if (state == null || state.isEmpty) {
      return 'State is required';
    }
    const validStates = {
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
    };
    final upper = state.trim().toUpperCase();
    if (!validStates.contains(upper)) {
      return 'Invalid US state code';
    }
    return null;
  }

  /// Validates address has required fields
  static String? validateAddress(String? line1, String? city, String? state, String? zip) {
    if (line1 == null || line1.trim().isEmpty) {
      return 'Address line 1 is required';
    }
    if (line1.trim().length > 100) {
      return 'Address line 1 is too long (max 100 characters)';
    }
    if (city == null || city.trim().isEmpty) {
      return 'City is required';
    }
    if (city.trim().length > 50) {
      return 'City is too long (max 50 characters)';
    }
    final stateError = validateState(state);
    if (stateError != null) return stateError;
    final zipError = validateZipCode(zip);
    if (zipError != null) return zipError;
    return null;
  }

  /// Validates product quantity is positive integer
  static String? validateQuantity(dynamic quantity) {
    if (quantity == null) {
      return 'Quantity is required';
    }
    final numQty = quantity is int ? quantity : int.tryParse(quantity.toString());
    if (numQty == null) {
      return 'Quantity must be a whole number';
    }
    if (numQty < 1) {
      return 'Quantity must be at least 1';
    }
    if (numQty > 999) {
      return 'Quantity exceeds maximum (999)';
    }
    return null;
  }

  /// Validates weight in ounces (for shipping)
  static String? validateWeight(dynamic weight) {
    if (weight == null) {
      return 'Weight is required';
    }
    final numWeight = weight is num ? weight : double.tryParse(weight.toString());
    if (numWeight == null) {
      return 'Weight must be a valid number';
    }
    if (numWeight <= 0) {
      return 'Weight must be greater than 0';
    }
    if (numWeight > 999999) {
      return 'Weight exceeds maximum (999,999 oz = ~62,500 lbs)';
    }
    return null;
  }

  /// Validates product name/title
  static String? validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Product name is required';
    }
    if (name.trim().length < 3) {
      return 'Product name must be at least 3 characters';
    }
    if (name.trim().length > 200) {
      return 'Product name is too long (max 200 characters)';
    }
    return null;
  }

  /// Validates inventory stock is non-negative integer
  static String? validateInventory(dynamic stock) {
    if (stock == null) {
      return 'Stock quantity is required';
    }
    final numStock = stock is int ? stock : int.tryParse(stock.toString());
    if (numStock == null) {
      return 'Stock must be a whole number';
    }
    if (numStock < 0) {
      return 'Stock cannot be negative';
    }
    if (numStock > 999999) {
      return 'Stock quantity exceeds maximum (999,999)';
    }
    return null;
  }

  /// Validates coupon code format
  static String? validateCouponCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'Coupon code is required';
    }
    final trimmed = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{3,20}$').hasMatch(trimmed)) {
      return 'Coupon code must be 3-20 alphanumeric characters';
    }
    return null;
  }

  /// Validates phone number (basic US format)
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (trimmed.length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  /// Validates inventory availability for order
  static String? validateInventoryAvailable(int available, int requested) {
    if (requested > available) {
      return 'Only $available in stock (requested $requested)';
    }
    return null;
  }
}
