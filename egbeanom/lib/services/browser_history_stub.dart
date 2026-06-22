import 'dart:async';

String currentBrowserRoute() => '/';

void pushBrowserRoute(String route) {}

void replaceBrowserRoute(String route) {}

Stream<String> browserRouteChanges() => const Stream.empty();
