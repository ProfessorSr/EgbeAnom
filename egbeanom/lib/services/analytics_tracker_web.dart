// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

String _measurementId = '';

void configureGoogleAnalytics(String measurementId) {
  final clean = measurementId.trim();
  if (clean.isEmpty || clean == _measurementId) {
    return;
  }
  _measurementId = clean;

  if (html.document.getElementById('egbeanom-ga-script') == null) {
    final script = html.ScriptElement()
      ..id = 'egbeanom-ga-script'
      ..async = true
      ..src = 'https://www.googletagmanager.com/gtag/js?id=$clean';
    html.document.head?.append(script);
  }

  final config = html.ScriptElement()
    ..id = 'egbeanom-ga-config'
    ..text =
        '''
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '$clean');
''';
  html.document.head?.append(config);
}

void trackGoogleAnalyticsPage(String pageName) {
  if (_measurementId.isEmpty) {
    return;
  }
  final clean = pageName.replaceAll("'", r"\'");
  final script = html.ScriptElement()
    ..text =
        "window.gtag && window.gtag('event', 'page_view', {page_title: '$clean'});";
  html.document.body?.append(script);
  script.remove();
}

void trackGoogleAnalyticsEvent(
  String eventName, {
  String page = '',
  double value = 0,
  String currency = 'USD',
  String itemName = '',
  String orderId = '',
}) {
  if (_measurementId.isEmpty) {
    return;
  }
  final cleanEvent = eventName.replaceAll("'", r"\'");
  final cleanPage = page.replaceAll("'", r"\'");
  final cleanCurrency = currency.replaceAll("'", r"\'");
  final cleanItem = itemName.replaceAll("'", r"\'");
  final cleanOrder = orderId.replaceAll("'", r"\'");
  final script = html.ScriptElement()
    ..text =
        "window.gtag && window.gtag('event', '$cleanEvent', {page_title: '$cleanPage', value: $value, currency: '$cleanCurrency', item_name: '$cleanItem', transaction_id: '$cleanOrder'});";
  html.document.body?.append(script);
  script.remove();
}

String currentTrafficReferrer() {
  final referrer = html.document.referrer.trim();
  if (referrer.isEmpty) {
    return 'Direct';
  }
  return Uri.tryParse(referrer)?.host ?? referrer;
}

String currentTrafficSource() {
  final referrer = currentTrafficReferrer().toLowerCase();
  if (referrer == 'direct') {
    return 'Direct';
  }
  if (referrer.contains('google') ||
      referrer.contains('bing') ||
      referrer.contains('yahoo')) {
    return 'Organic search';
  }
  if (referrer.contains('instagram') ||
      referrer.contains('facebook') ||
      referrer.contains('tiktok') ||
      referrer.contains('x.com') ||
      referrer.contains('twitter')) {
    return 'Social';
  }
  return 'Referral';
}

String currentDeviceLabel() {
  final width = html.window.innerWidth ?? 0;
  if (width < 700) {
    return 'Mobile';
  }
  if (width < 1100) {
    return 'Tablet';
  }
  return 'Desktop';
}
