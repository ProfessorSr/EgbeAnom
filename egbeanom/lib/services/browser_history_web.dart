// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

String currentBrowserRoute() {
  final location = html.window.location;
  final path = location.pathname?.isEmpty == false ? location.pathname! : '/';
  final search = location.search ?? '';
  return '$path$search';
}

void pushBrowserRoute(String route) {
  if (currentBrowserRoute() == route) {
    return;
  }
  html.window.history.pushState(null, '', route);
}

void replaceBrowserRoute(String route) {
  if (currentBrowserRoute() == route) {
    return;
  }
  html.window.history.replaceState(null, '', route);
}

Stream<String> browserRouteChanges() =>
    html.window.onPopState.map((_) => currentBrowserRoute());
