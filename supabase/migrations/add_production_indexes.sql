-- Production Performance Indexes
-- Apply these indexes to improve query performance on frequently accessed columns.
-- Generated: June 22, 2026

-- Dashboard queries frequently filter by created_at
CREATE INDEX IF NOT EXISTS idx_orders_created_at_desc 
ON public.orders(created_at DESC);

-- Customer lookups by email
CREATE INDEX IF NOT EXISTS idx_store_customers_email 
ON public.store_customers(email);

-- Review filtering by status
CREATE INDEX IF NOT EXISTS idx_store_reviews_status 
ON public.store_reviews(status);

-- Customer order history
CREATE INDEX IF NOT EXISTS idx_orders_customer_email 
ON public.orders(email);

-- Product lookups by category
CREATE INDEX IF NOT EXISTS idx_products_category_id 
ON public.products(category_id) 
WHERE is_active = true;

-- Product lookups by brand
CREATE INDEX IF NOT EXISTS idx_products_brand_id 
ON public.products(brand_id) 
WHERE is_active = true;

-- Order items lookups
CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
ON public.order_items(order_id);

-- Daily metrics time-series queries
CREATE INDEX IF NOT EXISTS idx_analytics_daily_metrics_day_desc
ON public.analytics_daily_metrics(day DESC);

-- Event-level analytics queries for GA-style reports
CREATE INDEX IF NOT EXISTS idx_analytics_events_occurred_desc
ON public.analytics_events(occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_event_occurred
ON public.analytics_events(event_name, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_session
ON public.analytics_events(session_id);

-- Settings lookups by key (frequently accessed)
CREATE INDEX IF NOT EXISTS idx_site_settings_key 
ON public.site_settings(key);

-- Backend user lookups
CREATE INDEX IF NOT EXISTS idx_backend_users_email 
ON public.backend_users(email);

-- Payment method lookups
CREATE INDEX IF NOT EXISTS idx_payment_methods_provider 
ON public.payment_methods(provider);

-- Review customer email lookups
CREATE INDEX IF NOT EXISTS idx_store_reviews_customer_email 
ON public.store_reviews(customer_email);

-- Composite index for dashboard filtering
CREATE INDEX IF NOT EXISTS idx_orders_status_date 
ON public.orders(financial_status, created_at DESC);

-- ANALYZE tables to update query planner statistics
ANALYZE public.orders;
ANALYZE public.order_items;
ANALYZE public.store_customers;
ANALYZE public.store_reviews;
ANALYZE public.products;
ANALYZE public.analytics_daily_metrics;
ANALYZE public.analytics_events;
ANALYZE public.site_settings;
ANALYZE public.backend_users;
ANALYZE public.payment_methods;
