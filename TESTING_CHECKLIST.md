# Production Testing Checklist - Phase 4-5

**Objective**: Verify all production systems are working correctly before launch  
**Estimated Time**: 45 minutes  
**Status**: Ready to execute

---

## Pre-Testing Setup

### 1. Test Environment Preparation
- [ ] App deployed to production
- [ ] Database migrations applied
- [ ] Encryption key set in environment
- [ ] Sentry DSN configured
- [ ] Edge Functions deployed

### 2. Test Accounts Created
- [ ] Admin backend user account
- [ ] Regular customer account
- [ ] Test payment method (Stripe test card)
- [ ] Test shipping address

### 3. Test Data Ready
- [ ] Sample products in database
- [ ] Shipping carriers configured (UPS, DHL, FedEx)
- [ ] Payment processors configured

---

## Test Suite 1: Security & Encryption

### Test 1.1: Verify Encryption Key Not Exposed
```bash
# Check: No ENCRYPTION_KEY in frontend code
cd egbeanom
grep -r "ENCRYPTION_KEY" build/web/
# Expected: No results

# Check: No credentials in browser console
# Open DevTools Console
# Execute: window.localStorage.getItem('egbeanom.supabase.access_token')
# Expected: JWT token only (not credentials)
```
**Status**: ⬜ Not Started

### Test 1.2: Verify RLS Policies Block Non-Admin Access
```sql
-- Login with non-admin user account in SQL Editor
-- Try to access encrypted credentials
SELECT * FROM public.encrypted_credentials;

-- Expected: Error "new row violates row-level security policy"
```
**Status**: ⬜ Not Started

### Test 1.3: Verify RLS Policies Allow Admin Access
```sql
-- Login with admin backend user
SELECT * FROM public.encrypted_credentials;

-- Expected: Results shown (encrypted_credentials table data)
```
**Status**: ⬜ Not Started

### Test 1.4: Verify Credential Audit Logging
```sql
-- Check audit log for recent accesses
SELECT provider_type, provider_name, action, accessed_by, accessed_at
FROM credential_access_log
ORDER BY accessed_at DESC
LIMIT 5;

-- Expected: Multiple entries showing access history
```
**Status**: ⬜ Not Started

---

## Test Suite 2: Input Validation

### Test 2.1: Email Validation
```dart
// In checkout form, try:
// Valid: user@example.com → ✓ Accept
// Invalid: invalid-email → ✗ Show error
// Invalid: @example.com → ✗ Show error
// Invalid: user@.com → ✗ Show error
```
**Status**: ⬜ Not Started

### Test 2.2: Price Validation
```dart
// In product management, try:
// Valid: 29.99 → ✓ Accept
// Invalid: -5 → ✗ Show error
// Invalid: 0 → ✗ Show error (below minimum 0.01)
// Invalid: 1,000,000 → ✗ Show error (above maximum 999,999.99)
```
**Status**: ⬜ Not Started

### Test 2.3: Address Validation
```dart
// In checkout form, try:
// Valid: "123 Main St", "New York", "NY", "10001" → ✓ Accept
// Invalid: "", "New York", "NY", "10001" → ✗ Show error (missing street)
// Invalid: "123 Main St", "", "NY", "10001" → ✗ Show error (missing city)
// Invalid: "123 Main St", "New York", "XY", "10001" → ✗ Show error (invalid state)
```
**Status**: ⬜ Not Started

### Test 2.4: Inventory Validation
```dart
// In inventory management, try:
// Valid: 100 units → ✓ Accept
// Invalid: -5 units → ✗ Show error
// Invalid: "abc" units → ✗ Show error (not a number)
```
**Status**: ⬜ Not Started

---

## Test Suite 3: Seed Data Isolation

### Test 3.1: Verify No Seed Brands in Production
```dart
// In main.dart:
// Build app with: --dart-define=DEBUG=false
// Load app
// Check: No "Test Brand 1", "Test Brand 2" in UI
// Check: localStorage doesn't contain seed brands
```
**Status**: ⬜ Not Started

### Test 3.2: Verify No Seed Products in Production
```dart
// Load app
// Check: Products page only shows database products (not seed data)
// No "Test Perfume 1" in product list
```
**Status**: ⬜ Not Started

### Test 3.3: Verify Seed Data in Debug Build
```dart
// Build app with: --dart-define=DEBUG=true (or use debug run)
// Load app
// Check: Seed brands appear in sidebar
// Check: Seed customers appear in admin panel
```
**Status**: ⬜ Not Started

---

## Test Suite 4: Database Performance

### Test 4.1: Verify Index on orders.created_at
```sql
-- Check index exists and is being used
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE created_at > now() - interval '7 days'
ORDER BY created_at DESC
LIMIT 10;

-- Expected output should include:
-- "Index Scan using idx_orders_created_at"
-- Query time: < 100ms
```
**Status**: ⬜ Not Started

### Test 4.2: Verify Index on store_customers.email
```sql
-- Check index exists and is being used
EXPLAIN ANALYZE
SELECT * FROM store_customers 
WHERE email = 'user@example.com';

-- Expected output should include:
-- "Index Scan using idx_store_customers_email"
-- Query time: < 10ms
```
**Status**: ⬜ Not Started

### Test 4.3: Verify Index on daily_metrics.date
```sql
-- Check index on dashboard metric queries
EXPLAIN ANALYZE
SELECT * FROM daily_metrics 
WHERE date = CURRENT_DATE;

-- Expected output should include:
-- "Index Scan using idx_daily_metrics_date"
-- Query time: < 50ms
```
**Status**: ⬜ Not Started

### Test 4.4: Dashboard Load Time
```dart
// In app, navigate to Admin Dashboard
// Measure load time:
// Before indexes: ~2-3 seconds
// After indexes: ~500-800ms
// Expected: At least 50% improvement
```
**Status**: ⬜ Not Started

---

## Test Suite 5: Error Logging

### Test 5.1: Verify Sentry Initialization
```dart
// In app, check:
// 1. No errors on app startup
// 2. Sentry badge shows in browser (if enabled)
// 3. ErrorTracker.initialize() called in main.dart
```
**Status**: ⬜ Not Started

### Test 5.2: Trigger and Verify Error Logging
```dart
// In app, trigger a test error (add to any screen):
// throw Exception('Test error for Sentry');

// Check Sentry dashboard:
// 1. Error appears within 10 seconds
// 2. Error shows correct source file
// 3. Stack trace is readable
// 4. User info not exposed (email/tokens filtered)
```
**Status**: ⬜ Not Started

### Test 5.3: Verify Sensitive Data Filtering
```dart
// Trigger error with sensitive data
// throw Exception('Failed with token: eyJhbGciOiJIUzI1NiIs...');

// Check Sentry:
// Token should be: [REDACTED]
// Not actual token value
```
**Status**: ⬜ Not Started

---

## Test Suite 6: Shipping APIs

### Test 6.1: USPS Shipping Rate Quote
```dart
// In checkout, select a shipping address
// Request USPS rate quote
// Expected:
// ✓ Within 5 seconds
// ✓ Multiple rate options shown
// ✓ Each rate includes: name, price, days
```
**Status**: ⬜ Not Started

### Test 6.2: UPS Shipping Rate Quote
```dart
// In checkout, select shipping method: UPS
// Request rate quote
// Expected:
// ✓ Real API call to UPS (check network tab)
// ✓ Rates returned within 5 seconds
// ✓ If API unavailable, fallback rates shown
```
**Status**: ⬜ Not Started

### Test 6.3: DHL Shipping Rate Quote
```dart
// In checkout, select shipping method: DHL
// Request rate quote
// Expected:
// ✓ Real API call to DHL (check network tab)
// ✓ Rates returned within 5 seconds
// ✓ If API unavailable, fallback rates shown
```
**Status**: ⬜ Not Started

### Test 6.4: FedEx Shipping Rate Quote
```dart
// In checkout, select shipping method: FedEx
// Request rate quote
// Expected:
// ✓ Real API call to FedEx (check network tab)
// ✓ Rates returned within 5 seconds
// ✓ If API unavailable, fallback rates shown
```
**Status**: ⬜ Not Started

### Test 6.5: Invalid Carrier Credentials Fallback
```dart
// Simulate invalid carrier credentials
// Try to get shipping quote
// Expected:
// ✓ API error caught gracefully
// ✓ Fallback mock rates shown
// ✓ User sees rates (no broken UI)
// ✓ Error logged to Sentry
```
**Status**: ⬜ Not Started

---

## Test Suite 7: Payment Processing

### Test 7.1: Stripe Payment Processing
```dart
// In checkout, select payment method: Stripe
// Card: 4242 4242 4242 4242
// Exp: 04/26
// CVC: 424

// Expected:
// ✓ Payment processed successfully
// ✓ Order created in database
// ✓ Confirmation email sent
// ✓ Order appears in admin dashboard
// ✓ Payment appears in Stripe dashboard
```
**Status**: ⬜ Not Started

### Test 7.2: PayPal Payment Processing
```dart
// In checkout, select payment method: PayPal
// Click "Pay with PayPal"
// Login with test account

// Expected:
// ✓ PayPal login modal appears
// ✓ Redirects back to app after payment
// ✓ Order created in database
// ✓ Payment appears in PayPal dashboard
```
**Status**: ⬜ Not Started

### Test 7.3: Square Payment Processing
```dart
// In checkout, select payment method: Square
// Card: 4111 1111 1111 1111 (test card)
// Exp: 04/26
// CVC: 424

// Expected:
// ✓ Payment processed successfully
// ✓ Order created in database
```
**Status**: ⬜ Not Started

### Test 7.4: Payment Processor Credential Isolation
```sql
-- Check that credentials are separate per provider
SELECT provider_name, created_at FROM encrypted_credentials
WHERE provider_type = 'payment_processor';

-- Expected:
-- ✓ stripe entry (separate encrypted credential)
-- ✓ paypal entry (separate encrypted credential)
-- ✓ square entry (separate encrypted credential)
-- ✓ Each has unique credentials
```
**Status**: ⬜ Not Started

---

## Test Suite 8: RLS (Row-Level Security)

### Test 8.1: Customer Can Only See Own Orders
```dart
// Login as customer A
// Check orders page
// Expected: Only customer A's orders shown

// Switch to customer B
// Check orders page
// Expected: Only customer B's orders shown
// NOT customer A's orders
```
**Status**: ⬜ Not Started

### Test 8.2: Customer Cannot See Backend Settings
```dart
// Login as regular customer
// Try to access: /admin/settings
// Try to access: /admin/credentials
// Expected: 
// ✓ Access denied (redirected to login or home)
// ✓ No error messages exposed
```
**Status**: ⬜ Not Started

### Test 8.3: Backend Admin Can Access All Data
```dart
// Login as backend admin
// Can access: Orders from any customer
// Can access: Settings page
// Can access: Payment processors
// Can access: Shipping carriers
// Expected: All accessible
```
**Status**: ⬜ Not Started

---

## Test Suite 9: Load Testing

### Test 9.1: Dashboard with 1000+ Orders
```sql
-- Create test data
INSERT INTO orders (customer_id, total, status, created_at)
SELECT 
  (ARRAY[1,2,3,4,5])[floor(random()*5)+1],
  random()*1000,
  'completed',
  now() - (random() * interval '30 days')
FROM generate_series(1, 1000);

-- Load dashboard in app
-- Expected:
// ✓ Loads within 2 seconds
// ✓ Charts render smoothly
// ✓ No browser crashes
```
**Status**: ⬜ Not Started

### Test 9.2: Concurrent Users
```bash
# Simulate 10 concurrent users viewing dashboard
ab -n 100 -c 10 https://your-store.com/admin/dashboard

# Expected:
# ✓ 95th percentile response time < 2s
# ✓ 0 failed requests
```
**Status**: ⬜ Not Started

---

## Test Suite 10: End-to-End Workflow

### Test 10.1: Complete Purchase Flow
```dart
// 1. Browse products
// ✓ Products load, pagination works
// ✓ Search filters work
// ✓ Sorting works

// 2. Add to cart
// ✓ Item added to cart
// ✓ Cart count updates
// ✓ Can continue shopping

// 3. Checkout
// ✓ Cart items shown correctly
// ✓ Discount code validates (if applicable)
// ✓ Shipping method selectable
// ✓ Shipping rates calculated

// 4. Payment
// ✓ Payment processor selectable
// ✓ Payment processes successfully
// ✓ No errors shown to user

// 5. Confirmation
// ✓ Order confirmation page shown
// ✓ Order details correct
// ✓ Confirmation email received
// ✓ Order appears in admin dashboard
```
**Status**: ⬜ Not Started

---

## Test Suite 11: Error Recovery

### Test 11.1: Network Error Recovery
```dart
// In checkout, go offline (airplane mode)
// Try to submit payment
// Expected:
// ✓ Error message shown (not crash)
// ✓ User can go back and retry
// ✓ Error logged to Sentry
// ✓ User not charged
```
**Status**: ⬜ Not Started

### Test 11.2: API Timeout Recovery
```dart
// Simulate API timeout (throttle network)
// Try to get shipping quote
// Expected:
// ✓ After 5 seconds, fallback rates shown
// ✓ No crash or infinite loading
// ✓ Error logged to Sentry
```
**Status**: ⬜ Not Started

---

## Scoring & Sign-Off

### Test Results Summary
```
Total Tests: 40
Passed: ___
Failed: ___
Not Started: ___
```

### Pass Criteria
- [ ] All security tests pass (Suite 1)
- [ ] All input validation tests pass (Suite 2)
- [ ] All seed data tests pass (Suite 3)
- [ ] All performance tests pass (Suite 4)
- [ ] All error logging tests pass (Suite 5)
- [ ] All API tests pass (Suites 6-7)
- [ ] All RLS tests pass (Suite 8)
- [ ] All load tests pass (Suite 9)
- [ ] End-to-end flow complete (Suite 10)
- [ ] Error recovery works (Suite 11)

### Sign-Off
- [ ] QA Lead: Tested and verified
- [ ] Backend Lead: Verified secure
- [ ] DevOps Lead: Monitoring configured
- [ ] CEO: Approved for production

**Date Tested**: ___________  
**Tested By**: ___________  
**Sign-Off**: ___________

---

## Rollback Procedures

If any test fails:

1. **Identify failed component**
   - Note which test(s) failed
   - Record error messages

2. **Document issue**
   - Create GitHub issue with: Test number, error, steps to reproduce
   - Assign to relevant team member

3. **Rollback if critical**
   - If payment processing fails: Rollback app immediately
   - If database issues: Restore from backup
   - If encryption fails: Switch to plaintext credentials

4. **Fix and retry**
   - Fix identified issue
   - Repeat failed test suite
   - Get sign-off before retrying full suite

---

## Success Criteria

✅ **Production Ready When**:
- All 40 tests pass
- No critical errors in Sentry during testing
- All APIs respond within expected time
- Payment processing works with all processors
- Database queries run in < 100ms
- RLS policies block unauthorized access
- Error logging captures all issues
- Team members signed off

---

**Generated**: June 22, 2026  
**Status**: Ready for execution  
**Estimated Duration**: 45 minutes  
**Critical Path**: Suites 1, 6-8 (security and payments)
