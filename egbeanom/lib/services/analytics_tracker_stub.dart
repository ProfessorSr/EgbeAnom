void configureGoogleAnalytics(String measurementId) {}

void trackGoogleAnalyticsPage(String pageName) {}

void trackGoogleAnalyticsEvent(
  String eventName, {
  String page = '',
  double value = 0,
  String currency = 'USD',
  String itemName = '',
  String orderId = '',
}) {}

String currentTrafficSource() => 'Direct';

String currentTrafficReferrer() => 'Direct';

String currentDeviceLabel() => 'Unknown device';

String currentClientSourceType() => 'Unknown browser';

Future<String> currentClientIpAddress() async => '';
