# Sentry Setup Guide for EgbeAnom

This guide walks through setting up production error tracking with Sentry.

## 1. Create Sentry Account & Project

### Step 1: Create Sentry Account
1. Go to https://sentry.io/signup/
2. Sign up with email or GitHub account
3. Create an organization (e.g., "egbeanom")

### Step 2: Create Flutter Project
1. In Sentry dashboard, click "Projects" → "Create Project"
2. Select "Flutter" as platform
3. Name: "egbeanom-app" (or your choice)
4. Create project

### Step 3: Get Your DSN
1. After creating project, go to Settings → Client Keys (DSN)
2. Copy the full DSN (looks like: `https://xxxxx@xxxxx.ingest.sentry.io/123456`)
3. Keep this safe - it's public but shouldn't be shared

---

## 2. Build & Run with Sentry

### Development (No Error Tracking)
```bash
cd egbeanom
flutter run
# Errors print to console but don't send to Sentry
```

### Production Build with Sentry
```bash
cd egbeanom
flutter build web --release \
  --dart-define=SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/123456
```

Replace `xxxxx` with your actual DSN.

### Run Locally (Test Sentry)
```bash
# Start local dev server with Sentry enabled
flutter run \
  --dart-define=SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/123456
```

---

## 3. Configure Sentry Dashboard

### Alert Rules
1. Go to Sentry project → Alerts
2. Create alert: "Error rate > 1%"
   - Condition: Error count > 100 in 1 hour
   - Action: Send Slack/Email notification

3. Create alert: "New Issue"
   - Condition: Any new error type
   - Action: Notify team

### Performance Monitoring
1. Go to Settings → Performance
2. Enable "Performance Monitoring"
3. Set sample rate to 1% (for web: `tracesSampleRate: 0.01`)

### Team Setup
1. Go to Settings → Teams
2. Add team members
3. Assign member to egbeanom project

### Integrations
1. Go to Settings → Integrations
2. Configure Slack integration (recommended)
   - Install Sentry app to Slack workspace
   - Link to #egbeanom-alerts channel
   - Enable notifications for new issues

---

## 4. Test Sentry Integration

### Trigger a Test Error
Add this to any screen build method temporarily:

```dart
@override
Widget build(BuildContext context) {
  // Test: Uncomment to trigger error
  // throw Exception('Test Sentry Error');
  
  return const Placeholder();
}
```

Then run:
```bash
flutter run --dart-define=SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/123456
```

Trigger the error → Check Sentry dashboard within 10 seconds.

### Test Error Reporting
```dart
import 'package:egbeanom/services/error_tracker.dart';

// In your code
try {
  // risky operation
} catch (error, stackTrace) {
  await ErrorTracker().captureException(
    error,
    stackTrace: stackTrace,
    userEmail: 'admin@egbeanom.com',
  );
}
```

---

## 5. Monitoring Production Issues

### Daily Checks
- Visit https://sentry.io/organizations/[ORG]/issues/
- Look for new errors
- Check error trend graph
- Review top 5 most common errors

### Review Dashboard
**Key Metrics**:
- Total errors (this hour, this week, this month)
- Error rate trend
- Most impacted users
- Top error types

### Typical Error Causes & Fixes
| Error | Cause | Fix |
|-------|-------|-----|
| `404 Not Found` | Missing API endpoint | Check shipping provider API URLs |
| `401 Unauthorized` | Bad credentials | Verify API keys in site_settings |
| `Connection timeout` | Network issue | Check API provider status page |
| `Null pointer exception` | Missing data | Add null checks before use |
| `CORS error` | Browser security | Check Supabase CORS settings |

---

## 6. Filtering & Privacy

### What Gets Sent to Sentry
✅ Error messages (sanitized)
✅ Stack traces
✅ Browser info
✅ User email (if provided)
✅ Request URL (tokens removed)

### What Doesn't Get Sent
❌ Passwords
❌ API keys
❌ Credit card info
❌ Personal addresses
❌ Authentication tokens

This is automatically handled by `error_tracker.dart` in the `_filterSensitiveData()` method.

### Custom Filtering
If you need to exclude specific errors:

```dart
try {
  // code
} catch (error) {
  // Don't send if error message contains 'ignore me'
  if (!error.toString().contains('ignore me')) {
    ErrorTracker().captureException(error);
  }
}
```

---

## 7. Error Tracking Best Practices

### 1. Always Set User Email on Login
```dart
// When user logs in
await ErrorTracker().setUser(
  userId,
  email: userEmail,
  username: displayName,
);
```

### 2. Use Breadcrumbs for Debugging
```dart
ErrorTracker().addBreadcrumb(
  'Started payment processing',
  category: 'checkout',
  data: {'order_id': order.id},
);

// ... do payment work ...

ErrorTracker().addBreadcrumb(
  'Payment completed',
  category: 'checkout',
  data: {'status': 'success'},
);

// If error occurs, breadcrumbs show what led to it
```

### 3. Track Performance-Critical Operations
```dart
final transaction = ErrorTracker().startTransaction(
  'checkout_flow',
  operation: 'process',
);

try {
  // Process checkout
  transaction.setData('item_count', items.length);
  transaction.setData('total_price', total);
  
  await processPayment();
  
  transaction.setData('payment_status', 'success');
} finally {
  await transaction.finish();
}
```

### 4. Log Important Business Events
```dart
ErrorTracker().addBreadcrumb(
  'Customer placed order',
  category: 'business',
  level: SentryLevel.info,
  data: {
    'order_id': order.id,
    'customer_email': customer.email,
    'total': order.total,
  },
);
```

---

## 8. Deployment Steps

### 1. Before Deploying to Production
```bash
# Test with Sentry enabled
flutter build web --release \
  --dart-define=SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/123456

# Test on staging server for 24 hours
# Verify no false alerts
# Check performance impact (should be minimal)
```

### 2. Deploy to Production
- Merge feature branch to `main`
- Build with: `flutter build web --release --dart-define=SENTRY_DSN=...`
- Upload to production server
- Test live: https://your-store.com
- Monitor Sentry dashboard

### 3. First Week Monitoring
- Check Sentry daily
- Fix critical errors immediately
- Document patterns in error logs
- Adjust alert thresholds if too noisy

---

## 9. Troubleshooting

### Sentry Not Receiving Errors
1. Check DSN is correct (contains project ID)
2. Verify build includes `--dart-define=SENTRY_DSN=...`
3. Check network: Is client reaching Sentry?
4. Check privacy: Are errors being filtered out?

**Debug**: Add print statement in main.dart:
```dart
if (sentryDsn.isNotEmpty) {
  print('Initializing Sentry with DSN: $sentryDsn');
}
```

### Too Many Notifications
1. Increase error threshold in alert rules
2. Disable notifications for low-priority errors
3. Group similar errors together in Sentry settings

### Performance Degradation
1. Reduce `tracesSampleRate` (current: 1% for production)
2. Disable performance monitoring if not needed
3. Profile with Flutter DevTools to confirm Sentry is bottleneck

---

## 10. Environment Variable Cheat Sheet

### Development
```bash
# No Sentry (default)
flutter run
```

### Staging (Test Sentry)
```bash
flutter build web --release \
  --dart-define=SENTRY_DSN=https://YOUR_DSN@sentry.io/PROJECT_ID
```

### Production
```bash
flutter build web --release \
  --dart-define=SENTRY_DSN=https://YOUR_PRODUCTION_DSN@sentry.io/PROJECT_ID
```

Store the DSN in your deployment system (GitHub Secrets, CI/CD, etc.) instead of hardcoding.

---

## 11. CI/CD Integration (GitHub Actions Example)

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Flutter app
        run: |
          cd egbeanom
          flutter build web --release \
            --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
      
      - name: Deploy to production
        run: |
          # Your deployment commands here
```

Add `SENTRY_DSN` as a GitHub Secret for automatic deployment.

---

## 12. Monthly Maintenance

- [ ] Review error trends
- [ ] Check for new error patterns
- [ ] Update alert thresholds if needed
- [ ] Archive old resolved issues
- [ ] Review team member access
- [ ] Check integration status

---

**Next Steps**:
1. Create Sentry account and project
2. Get DSN
3. Test build: `flutter build web --release --dart-define=SENTRY_DSN=...`
4. Trigger test error to verify setup
5. Deploy to production with Sentry enabled
6. Monitor first week for issues
