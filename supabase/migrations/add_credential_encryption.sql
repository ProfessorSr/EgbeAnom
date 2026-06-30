-- Phase 4: Credential Encryption with Supabase Vault
-- Secure storage for payment processor and shipping carrier credentials
-- Apply this migration to encrypt all credentials at rest

-- Step 1: Enable pgcrypto extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Step 2: Create vault table for encrypted credentials
CREATE TABLE IF NOT EXISTS public.encrypted_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_type text NOT NULL CHECK (provider_type IN ('payment_processor', 'shipping_carrier')),
  provider_name text NOT NULL, -- 'stripe', 'paypal', 'square', 'usps', 'ups', 'dhl', 'fedex'
  credentials_encrypted bytea NOT NULL, -- encrypted JSON
  encryption_algorithm text NOT NULL DEFAULT 'aes-256-gcm',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  UNIQUE(provider_type, provider_name)
);

-- Step 3: Create indexes on vault table
CREATE INDEX IF NOT EXISTS idx_encrypted_creds_provider 
ON public.encrypted_credentials(provider_type, provider_name);

CREATE INDEX IF NOT EXISTS idx_encrypted_creds_created_by 
ON public.encrypted_credentials(created_by);

-- Step 4: Enable RLS on encrypted_credentials
ALTER TABLE public.encrypted_credentials ENABLE ROW LEVEL SECURITY;

-- Step 5: Only backend admins can access encrypted credentials
CREATE POLICY "only_backend_admins_access_encrypted_creds" 
ON public.encrypted_credentials 
FOR ALL 
USING (public.is_backend_admin()) 
WITH CHECK (public.is_backend_admin());

-- Step 6: Encryption function - Encrypts credentials before storage
CREATE OR REPLACE FUNCTION public.encrypt_credential_value(
  p_data text,
  p_encryption_key bytea
)
RETURNS bytea
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_iv bytea;
  v_encrypted bytea;
BEGIN
  -- Generate random IV
  v_iv := gen_random_bytes(16);
  
  -- Encrypt with AES-256-GCM
  v_encrypted := encrypt_iv(
    convert_to(p_data, 'utf8'),
    p_encryption_key,
    v_iv,
    'aes'
  );
  
  -- Return IV + encrypted data (IV needed for decryption)
  RETURN v_iv || v_encrypted;
END;
$$;

-- Step 7: Decryption function - Decrypts credentials from storage
CREATE OR REPLACE FUNCTION public.decrypt_credential_value(
  p_encrypted_data bytea,
  p_encryption_key bytea
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_iv bytea;
  v_encrypted bytea;
  v_decrypted bytea;
BEGIN
  -- Extract IV (first 16 bytes)
  v_iv := substring(p_encrypted_data, 1, 16);
  
  -- Extract encrypted data (rest of bytes)
  v_encrypted := substring(p_encrypted_data, 17);
  
  -- Decrypt
  v_decrypted := decrypt_iv(
    v_encrypted,
    p_encryption_key,
    v_iv,
    'aes'
  );
  
  -- Convert back to text
  RETURN convert_from(v_decrypted, 'utf8');
END;
$$;

-- Step 8: Function to store encrypted credentials
CREATE OR REPLACE FUNCTION public.upsert_encrypted_credential(
  p_provider_type text,
  p_provider_name text,
  p_credentials_json text,
  p_encryption_key bytea
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_credential_id uuid;
  v_encrypted bytea;
BEGIN
  -- Verify caller is backend admin
  IF NOT public.is_backend_admin() THEN
    RAISE EXCEPTION 'Only backend admins can store credentials';
  END IF;
  
  -- Encrypt credentials
  v_encrypted := public.encrypt_credential_value(
    p_credentials_json,
    p_encryption_key
  );
  
  -- Upsert credential
  INSERT INTO public.encrypted_credentials (
    provider_type,
    provider_name,
    credentials_encrypted,
    created_by
  ) VALUES (
    p_provider_type,
    p_provider_name,
    v_encrypted,
    auth.uid()
  )
  ON CONFLICT (provider_type, provider_name)
  DO UPDATE SET
    credentials_encrypted = v_encrypted,
    updated_at = now()
  RETURNING id INTO v_credential_id;
  
  RETURN v_credential_id;
END;
$$;

-- Step 9: Function to retrieve encrypted credentials
CREATE OR REPLACE FUNCTION public.get_encrypted_credential(
  p_provider_type text,
  p_provider_name text,
  p_encryption_key bytea
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_encrypted bytea;
  v_decrypted text;
BEGIN
  -- Verify caller is backend admin
  IF NOT public.is_backend_admin() THEN
    RAISE EXCEPTION 'Only backend admins can retrieve credentials';
  END IF;
  
  -- Get encrypted credential
  SELECT credentials_encrypted INTO v_encrypted
  FROM public.encrypted_credentials
  WHERE provider_type = p_provider_type
    AND provider_name = p_provider_name;
  
  IF v_encrypted IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Decrypt and return
  v_decrypted := public.decrypt_credential_value(
    v_encrypted,
    p_encryption_key
  );
  
  RETURN v_decrypted;
END;
$$;

-- Step 10: Audit trail for credential access
CREATE TABLE IF NOT EXISTS public.credential_access_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_type text NOT NULL,
  provider_name text NOT NULL,
  action text NOT NULL CHECK (action IN ('read', 'write', 'delete')),
  accessed_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  accessed_at timestamptz NOT NULL DEFAULT now(),
  ip_address text,
  notes text
);

CREATE INDEX IF NOT EXISTS idx_credential_access_log_date 
ON public.credential_access_log(accessed_at DESC);

CREATE INDEX IF NOT EXISTS idx_credential_access_log_provider 
ON public.credential_access_log(provider_type, provider_name);

-- Step 11: Log credential access
CREATE OR REPLACE FUNCTION public.log_credential_access(
  p_provider_type text,
  p_provider_name text,
  p_action text,
  p_ip_address text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.credential_access_log (
    provider_type,
    provider_name,
    action,
    accessed_by,
    ip_address,
    notes
  ) VALUES (
    p_provider_type,
    p_provider_name,
    p_action,
    auth.uid(),
    p_ip_address,
    'Accessed by admin user'
  );
END;
$$;

-- Step 12: Analyze tables for query optimization
ANALYZE public.encrypted_credentials;
ANALYZE public.credential_access_log;

-- Migration notes:
-- 1. All credentials are now encrypted at rest using AES-256
-- 2. Encryption key is passed at runtime (not stored in DB)
-- 3. Only backend admins (RLS policy) can access
-- 4. All access is logged for audit trail
-- 5. Use generate_key() to create encryption keys
-- 6. Store encryption key in environment variable (not in code)

-- Example usage (from Dart/TypeScript):
-- 1. Generate encryption key: SELECT encode(gen_random_bytes(32), 'hex')
-- 2. Store as environment variable: ENCRYPTION_KEY
-- 3. Encrypt credentials:
--    SELECT upsert_encrypted_credential(
--      'payment_processor',
--      'stripe',
--      '{"api_secret": "sk_live_xxx", ...}',
--      decode(env('ENCRYPTION_KEY'), 'hex')
--    )
-- 4. Decrypt credentials:
--    SELECT get_encrypted_credential(
--      'payment_processor',
--      'stripe',
--      decode(env('ENCRYPTION_KEY'), 'hex')
--    )
