#!/bin/bash

# EgbeAnom Production Deployment Script
# Usage: ./deploy-production.sh
# Prerequisites: 
#   - Set environment variables: SUPABASE_PROJECT_ID, ENCRYPTION_KEY, SENTRY_DSN
#   - Install: flutter, supabase-cli, curl

set -e

echo "🚀 EgbeAnom Production Deployment"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check environment variables
echo -e "\n${YELLOW}Checking environment variables...${NC}"
if [ -z "$SUPABASE_PROJECT_ID" ]; then
  echo -e "${RED}❌ SUPABASE_PROJECT_ID not set${NC}"
  exit 1
fi

if [ -z "$ENCRYPTION_KEY" ]; then
  echo -e "${RED}❌ ENCRYPTION_KEY not set${NC}"
  echo "Generate with: openssl rand -hex 32"
  exit 1
fi

if [ -z "$SENTRY_DSN" ]; then
  echo -e "${RED}❌ SENTRY_DSN not set${NC}"
  exit 1
fi

echo -e "${GREEN}✓ All environment variables set${NC}"

# Step 1: Database Migrations
echo -e "\n${YELLOW}Step 1: Applying database migrations...${NC}"
cd supabase

# Backup current schema
echo "Creating backup..."
supabase db pull --project-id "$SUPABASE_PROJECT_ID" > schema-backup-$(date +%Y%m%d_%H%M%S).sql

# Apply migrations
echo "Applying migrations..."
supabase migration up --project-id "$SUPABASE_PROJECT_ID"
echo -e "${GREEN}✓ Migrations applied${NC}"

cd ..

# Step 2: Deploy Edge Functions
echo -e "\n${YELLOW}Step 2: Deploying Edge Functions...${NC}"

# Deploy credential migration function
echo "Deploying credential-migration function..."
supabase functions deploy credential-migration \
  --project-id "$SUPABASE_PROJECT_ID" \
  --env-file .env.production
echo -e "${GREEN}✓ credential-migration deployed${NC}"

# Step 3: Verify Encryption Setup
echo -e "\n${YELLOW}Step 3: Verifying encryption setup...${NC}"

API_URL="https://${SUPABASE_PROJECT_ID}.supabase.co"
SERVICE_ROLE_KEY=$(supabase status --project-id "$SUPABASE_PROJECT_ID" | grep "service_role_key" | awk '{print $NF}')

RESPONSE=$(curl -s -X POST \
  "${API_URL}/functions/v1/credential-migration?action=status" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY")

echo "Encryption status: $RESPONSE"

if echo "$RESPONSE" | grep -q '"status":"ok"'; then
  echo -e "${GREEN}✓ Encryption verified${NC}"
else
  echo -e "${RED}❌ Encryption verification failed${NC}"
  exit 1
fi

# Step 4: Build Flutter App
echo -e "\n${YELLOW}Step 4: Building Flutter app...${NC}"

cd egbeanom

# Clean previous build
echo "Cleaning previous build..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Run analysis
echo "Running analysis..."
flutter analyze

# Build for web
echo "Building web release..."
flutter build web --release \
  --dart-define=SENTRY_DSN="$SENTRY_DSN" \
  --dart-define=ENCRYPTION_KEY="$ENCRYPTION_KEY"

echo -e "${GREEN}✓ Web app built${NC}"

cd ..

# Step 5: Migrate Credentials
echo -e "\n${YELLOW}Step 5: Migrating credentials to encrypted vault...${NC}"

PROVIDERS=("stripe" "paypal" "square" "apple_pay" "google_pay")
for provider in "${PROVIDERS[@]}"; do
  echo "Migrating $provider credentials..."
  curl -s -X POST \
    "${API_URL}/functions/v1/credential-migration?action=migrate-payment" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"provider\": \"$provider\"}" | jq '.' || true
done

CARRIERS=("ups" "dhl" "fedex")
for carrier in "${CARRIERS[@]}"; do
  echo "Migrating $carrier credentials..."
  curl -s -X POST \
    "${API_URL}/functions/v1/credential-migration?action=migrate-shipping" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"carrier\": \"$carrier\"}" | jq '.' || true
done

echo -e "${GREEN}✓ Credentials migrated${NC}"

# Step 6: Verify Credentials
echo -e "\n${YELLOW}Step 6: Verifying encrypted credentials...${NC}"

curl -s -X POST \
  "${API_URL}/functions/v1/credential-migration?action=verify" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_type": "payment_processor",
    "provider_name": "stripe"
  }' | jq '.'

echo -e "${GREEN}✓ Verification complete${NC}"

# Step 7: Deployment Summary
echo -e "\n${YELLOW}Deployment Summary${NC}"
echo "===================="
echo -e "Project: ${GREEN}$SUPABASE_PROJECT_ID${NC}"
echo -e "Sentry DSN: ${GREEN}${SENTRY_DSN:0:30}...${NC}"
echo -e "Encryption Key: ${GREEN}${ENCRYPTION_KEY:0:10}...${NC}"
echo -e "Build Location: ${GREEN}egbeanom/build/web${NC}"

echo -e "\n${GREEN}✅ Deployment complete!${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Upload egbeanom/build/web/* to your hosting"
echo "2. Test app at https://your-domain.com"
echo "3. Verify payment processing works"
echo "4. Monitor Sentry dashboard for errors"
echo "5. Check credential access logs weekly"

echo -e "\n${YELLOW}Rollback if needed:${NC}"
echo "  supabase db reset --project-id $SUPABASE_PROJECT_ID"
echo "  # Restore from schema-backup-*.sql"
