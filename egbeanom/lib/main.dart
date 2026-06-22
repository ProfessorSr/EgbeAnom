import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:egbeanom/services/analytics_tracker_stub.dart'
    if (dart.library.html) 'package:egbeanom/services/analytics_tracker_web.dart';
import 'package:egbeanom/services/admin_browser_actions_stub.dart'
    if (dart.library.html) 'package:egbeanom/services/admin_browser_actions_web.dart';
import 'package:egbeanom/services/browser_history_stub.dart'
    if (dart.library.html) 'package:egbeanom/services/browser_history_web.dart';
import 'package:egbeanom/services/external_link_launcher_stub.dart'
    if (dart.library.html) 'package:egbeanom/services/external_link_launcher_web.dart';
import 'package:egbeanom/services/shipping_rate_gateway.dart';
import 'package:egbeanom/services/store_data_gateway.dart';
import 'package:egbeanom/services/rss_feed_loader_stub.dart'
    if (dart.library.html) 'package:egbeanom/services/rss_feed_loader_web.dart';
import 'package:egbeanom/widgets/photo_upload_picker_stub.dart'
    if (dart.library.html) 'package:egbeanom/widgets/photo_upload_picker_web.dart';

part 'app/store_shell.dart';
part 'data/seed_data.dart';
part 'models/store_models.dart';
part 'screens/admin_view.dart';
part 'screens/cart_view.dart';
part 'screens/fragrance_detail_view.dart';
part 'screens/info_view.dart';
part 'screens/shop_view.dart';
part 'widgets/navigation.dart';
part 'widgets/product_media.dart';
part 'widgets/shared.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EgbeAnomStoreApp());
}

class EgbeAnomStoreApp extends StatelessWidget {
  const EgbeAnomStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF172026);
    const accent = Color(0xFFC88F52);

    return MaterialApp(
      title: 'Egbe Anom Fragrances',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
          titleLarge: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: ink),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: Color(0xFF172026)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD8D1C7)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2DCD2)),
          ),
        ),
        useMaterial3: true,
      ),
      home: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const StoreShell(),
      ),
    );
  }
}
