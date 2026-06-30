# Production Implementation Guide

This guide covers the implementation of critical production-ready features for EgbeAnom.

## 1. Error Logging with Sentry

### Setup

Add Sentry SDK to `pubspec.yaml`:
```yaml
dependencies:
  sentry_flutter: ^8.0.0
```

### Implementation

Update `lib/main.dart`:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://YOUR_SENTRY_DSN@sentry.io/PROJECT_ID';
      options.environment = kDebugMode ? 'development' : 'production';
      options.tracesSampleRate = kDebugMode ? 0.1 : 0.01; // 1-10% in production
      options.beforeSend = (event, hint) {
        // Filter out sensitive data
        if (event.request?.url != null) {
          // Strip auth tokens from URLs
          event.request!.url = event.request!.url!.replaceAll(
            RegExp(r'access_token=[^&]*'),
            'access_token=***',
          );
        }
        return event;
      };
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### Usage

Wrap async operations:
```dart
// Automatic error tracking
Future<void> fetchData() async {
  try {
    // your code
  } catch (error, stackTrace) {
    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}

// Track performance
final transaction = Sentry.startTransaction(
  'checkout_flow',
  'process',
);
// ... do work
await transaction.finish();
```

### Monitoring

- Dashboard: https://sentry.io/organizations/YOUR_ORG/issues/
- Set up alerts for error rates > 1%
- Review daily error reports
- Track performance metrics

---

## 2. Credential Encryption with Supabase Vault

### Setup (PostgreSQL)

Create encryption vault:
```sql
-- Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create vault table
CREATE TABLE IF NOT EXISTS public.encrypted_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_type text NOT NULL, -- 'payment_processor', 'shipping_carrier'
  provider_name text NOT NULL, -- 'stripe', 'ups', 'dhl', 'fedex'
  credentials_encrypted text NOT NULL, -- encrypted JSON
  access_key text NOT NULL, -- for decryption (store securely)
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE public.encrypted_credentials ENABLE ROW LEVEL SECURITY;

-- Only admins can access
CREATE POLICY "admins manage encrypted credentials" 
ON public.encrypted_credentials 
FOR ALL 
USING (public.is_backend_admin()) 
WITH CHECK (public.is_backend_admin());
```

### Encryption Function

```sql
CREATE OR REPLACE FUNCTION public.encrypt_credentials(
  p_credentials jsonb,
  p_encryption_key text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN encode(
    pgp_sym_encrypt(
      p_credentials::text,
      p_encryption_key,
      'cipher-algo=aes256'
    ),
    'hex'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.decrypt_credentials(
  p_encrypted text,
  p_encryption_key text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN pgp_sym_decrypt(
    decode(p_encrypted, 'hex'),
    p_encryption_key
  )::jsonb;
END;
$$;
```

### Dart Integration

```dart
// In store_data_gateway_web.dart

Future<Map<String, dynamic>?> fetchEncryptedCredentials(
  String provider,
  String encryptionKey,
) async {
  try {
    final response = await _rest(
      'encrypted_credentials',
      query: {
        'select': 'id,credentials_encrypted',
        'provider_name': provider,
        'limit': 1,
      },
    );
    
    if (response is! List || response.isEmpty) {
      return null;
    }
    
    // Decrypt on client side
    final encrypted = response[0]['credentials_encrypted'];
    // Decrypt implementation (requires secure key management)
    
    return null; // Return decrypted credentials
  } catch (error) {
    return null;
  }
}
```

---

## 3. Input Validation Integration

Use validators in forms:

```dart
import 'package:egbeanom/models/validators.dart';

// Email field
TextField(
  onChanged: (value) {
    final error = Validators.validateEmail(value);
    setState(() {
      _emailError = error;
    });
  },
  decoration: InputDecoration(
    errorText: _emailError,
  ),
),

// Price field
TextField(
  onChanged: (value) {
    final error = Validators.validatePrice(value);
    setState(() {
      _priceError = error;
    });
  },
),

// Address validation
final addressError = Validators.validateAddress(
  _address1,
  _city,
  _state,
  _zip,
);
```

---

## 4. Seed Data Conditional Loading

Update `lib/app/store_shell.dart`:

```dart
const bool _includeDevSeedData = !kReleaseMode;

// In state initialization:
final List<BrandProfile> _brands = _includeDevSeedData 
  ? List.of(buildSeedBrands()) 
  : [];

final List<NewsItem> _newsItems = _includeDevSeedData 
  ? List.of(buildSeedNewsItems()) 
  : [];
```

Build for production:
```bash
flutter build web --release --dart-define=kReleaseMode=true
```

---

## 5. Database Backup Strategy

### Daily Backups (Supabase)
- Automatic backups enabled (check in Supabase dashboard)
- Set retention to 30 days minimum

### Monitoring
- Set up alerts for database size changes
- Monitor slow queries (> 1s)
- Review index usage monthly

---

## 6. Security Checklist

- [ ] All passwords/API keys stored in environment variables
- [ ] Credentials encrypted at rest
- [ ] HTTPS enforced everywhere
- [ ] CORS properly configured (not *)
- [ ] Auth tokens have expiration
- [ ] RLS policies tested and verified
- [ ] Sensitive logs redacted
- [ ] Rate limiting implemented
- [ ] Webhook signatures verified
- [ ] SQL injection prevention (prepared statements)

---

## 7. Deployment Checklist

### Before Production Launch
- [ ] Run database indexes migration
- [ ] Set up Sentry account and DSN
- [ ] Configure environment variables (no hardcoded secrets)
- [ ] Run `flutter analyze` - no warnings
- [ ] Run full test suite - all passing
- [ ] Verify seed data disabled in production build
- [ ] Test payment processor webhooks
- [ ] Test shipping provider APIs with credentials
- [ ] Verify backup strategy working
- [ ] Set up monitoring and alerts

### After Launch
- [ ] Monitor Sentry dashboard daily
- [ ] Review database query performance
- [ ] Track API error rates
- [ ] Monitor uptime (set up ping monitoring)
- [ ] Weekly security audit
- [ ] Monthly database maintenance
- [ ] Quarterly credential rotation

---

## 8. Ongoing Maintenance

### Daily
- Check Sentry for critical errors
- Monitor database performance
- Review API logs for anomalies

### Weekly
- Run database VACUUM and ANALYZE
- Review slow query logs
- Check backup completion

### Monthly
- Rotate credentials
- Security audit logs
- Performance analysis
- Update dependencies

### Quarterly
- Full security assessment
- Load testing
- Disaster recovery drill
- Compliance audit
