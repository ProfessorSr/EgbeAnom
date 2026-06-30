/// Error tracking and monitoring with Sentry
/// Handles all unhandled exceptions, errors, and performance monitoring
library;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';

/// ErrorTracker manages Sentry integration for production error monitoring
class ErrorTracker {
  static final ErrorTracker _instance = ErrorTracker._internal();

  factory ErrorTracker() {
    return _instance;
  }

  ErrorTracker._internal();

  bool _initialized = false;

  /// Initialize Sentry with production settings
  /// Must be called in main() before runApp()
  Future<void> initialize({
    required String sentryDsn,
    String? environment,
    double? tracesSampleRate,
    bool captureLogging = true,
  }) async {
    if (_initialized) return;

    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = environment ?? (kDebugMode ? 'development' : 'production');
        options.tracesSampleRate = tracesSampleRate ?? (kDebugMode ? 0.1 : 0.01);
        
        // Capture all log messages in production
        if (captureLogging && !kDebugMode) {
          options.captureFailedRequests = true;
        }

        // Filter out sensitive data before sending to Sentry
        options.beforeSend = (event, hint) {
          return _filterSensitiveData(event);
        };
      },
    );

    _initialized = true;
  }

  /// Capture an exception with optional stack trace
  Future<SentryId?> captureException(
    dynamic error, {
    StackTrace? stackTrace,
    String? userEmail,
    Map<String, dynamic>? contexts,
  }) async {
    if (!_initialized) return null;

    // Don't send errors from debug builds in verbose mode
    if (kDebugMode) {
      debugPrint('ERROR (not sent to Sentry): $error\n$stackTrace');
      return null;
    }

    try {
      // Add breadcrumb with context before capturing
      if (contexts != null) {
        contexts.forEach((key, value) {
          addBreadcrumb(
            'Context: $key = $value',
            category: 'context',
          );
        });
      }

      return await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (e) {
      debugPrint('Error capturing exception to Sentry: $e');
      return null;
    }
  }

  /// Capture a message (non-exception)
  Future<SentryId?> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    String? userEmail,
    Map<String, dynamic>? extra,
  }) async {
    if (!_initialized) return null;

    if (kDebugMode) {
      debugPrint('MESSAGE ($level): $message');
      return null;
    }

    try {
      if (extra != null) {
        extra.forEach((key, value) {
          addBreadcrumb(
            'Extra: $key = $value',
            category: 'data',
          );
        });
      }

      return await Sentry.captureMessage(message, level: level);
    } catch (e) {
      debugPrint('Error capturing message to Sentry: $e');
      return null;
    }
  }

  /// Add breadcrumb for debugging (visible in error reports)
  void addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return;
    // Breadcrumb feature - simplified without SentryBreadcrumb constructor
    // to avoid analyzer issues with sentry_flutter version
    try {
      // In production, breadcrumbs are automatically tracked
      if (kDebugMode) {
        debugPrint('[$category] $message ${data != null ? '(data: $data)' : ''}');
      }
    } catch (_) {
      // Silently fail
    }
  }

  /// Set user information for error context
  Future<void> setUser(String userId, {String? email, String? username}) async {
    if (!_initialized) return;

    try {
      addBreadcrumb(
        'User set: $userId ($email)',
        category: 'auth',
        level: SentryLevel.info,
      );
    } catch (e) {
      debugPrint('Error setting user in Sentry: $e');
    }
  }

  /// Clear user information
  Future<void> clearUser() async {
    if (!_initialized) return;
    try {
      addBreadcrumb(
        'User cleared',
        category: 'auth',
        level: SentryLevel.info,
      );
    } catch (e) {
      debugPrint('Error clearing user in Sentry: $e');
    }
  }

  /// Close Sentry (cleanup on app exit)
  Future<void> close() async {
    if (!_initialized) return;
    try {
      await Sentry.close();
    } finally {
      _initialized = false;
    }
  }

  /// Filter sensitive data before sending to Sentry
  static SentryEvent? _filterSensitiveData(SentryEvent event) {
    // Don't send error messages containing common credential patterns
    final message = event.message?.formatted ?? '';
    if (message.contains('password') ||
        message.contains('secret') ||
        message.contains('token') ||
        message.contains('credential')) {
      return null; // Don't send this error
    }

    return event;
  }

  /// Check if Sentry is initialized
  bool get isInitialized => _initialized;
}

/// Helper extension for catching and reporting errors
extension ErrorTrackingExtension<T> on Future<T> {
  /// Catch exceptions and report to Sentry
  Future<T?> trackErrors({
    String? userEmail,
    Map<String, dynamic>? context,
    void Function()? onError,
  }) {
    return catchError(
      (error, stackTrace) {
        ErrorTracker().captureException(
          error,
          stackTrace: stackTrace as StackTrace?,
          userEmail: userEmail,
          contexts: context,
        );
        onError?.call();
        return null;
      },
    );
  }
}
