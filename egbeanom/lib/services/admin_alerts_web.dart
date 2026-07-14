// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<bool> requestAdminBrowserAlertPermission() async {
  try {
    if (!html.Notification.supported) {
      return false;
    }
    if (html.Notification.permission == 'granted') {
      return true;
    }
    if (html.Notification.permission == 'denied') {
      return false;
    }
    return await html.Notification.requestPermission() == 'granted';
  } catch (_) {
    return false;
  }
}

void showAdminBrowserAlert({required String title, required String body}) {
  try {
    if (!html.Notification.supported ||
        html.Notification.permission != 'granted') {
      return;
    }
    html.Notification(
      title,
      body: body,
      icon: 'icons/Icon-192.png',
      tag: 'egbeanom-admin-alert',
    );
  } catch (_) {}
}

void playAdminAlertSound() {
  try {
    final audio = html.AudioElement(
      'data:audio/wav;base64,UklGRpQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YXAAAACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAkJmfr7r8/v78urnnkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQj4+Qm6mTj4+QkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkA==',
    )..volume = 0.55;
    unawaited(audio.play());
  } catch (_) {}
}
