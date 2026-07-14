// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

const _checkoutDraftKey = 'egbeanom.pending_checkout_draft';

void savePendingCheckoutDraft(Map<String, dynamic> draft) {
  html.window.sessionStorage[_checkoutDraftKey] = jsonEncode(draft);
}

Map<String, dynamic>? loadPendingCheckoutDraft() {
  final raw = html.window.sessionStorage[_checkoutDraftKey];
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final decoded = jsonDecode(raw);
  if (decoded is Map) {
    return decoded.cast<String, dynamic>();
  }
  return null;
}

void clearPendingCheckoutDraft() {
  html.window.sessionStorage.remove(_checkoutDraftKey);
}
