-- Complete fix for property_requests table constraints and columns

-- First, start a transaction for safety
BEGIN;

-- 1. Fix the email constraint in mobile_app_users if not already fixed
ALTER TABLE mobile_app_users ALTER COLUMN email DROP NOT NULL;

-- 2. Add phone_number column to mobile_app_users if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mobile_app_users' AND column_name = 'phone_number'
    ) THEN
        ALTER TABLE mobile_app_users ADD COLUMN phone_number VARCHAR(20);
    END IF;
END $$;

-- 3. Check and drop the incorrect constraint names
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'property_requests_seller_phone_number_fkey'
    ) THEN
        ALTER TABLE property_requests DROP CONSTRAINT property_requests_seller_phone_number_fkey;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'property_requests_buyer_phone_number_fkey'
    ) THEN
        ALTER TABLE property_requests DROP CONSTRAINT property_requests_buyer_phone_number_fkey;
    END IF;
END $$;

-- 4. Check and drop the correct constraints if they exist (to rebuild them)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'property_requests_seller_wallet_address_fkey'
    ) THEN
        ALTER TABLE property_requests DROP CONSTRAINT property_requests_seller_wallet_address_fkey;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'property_requests_buyer_wallet_address_fkey'
    ) THEN
        ALTER TABLE property_requests DROP CONSTRAINT property_requests_buyer_wallet_address_fkey;
    END IF;
END $$;

-- 5. Ensure the property_type and transaction_date columns exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'property_requests' AND column_name = 'property_type'
    ) THEN
        ALTER TABLE property_requests ADD COLUMN property_type VARCHAR(50);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'property_requests' AND column_name = 'transaction_date'
    ) THEN
        ALTER TABLE property_requests ADD COLUMN transaction_date TIMESTAMP;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'property_requests' AND column_name = 'property_address'
    ) THEN
        ALTER TABLE property_requests ADD COLUMN property_address VARCHAR(500);
    END IF;
END $$;

-- 6. Add foreign key constraints with the correct column names
ALTER TABLE property_requests
ADD CONSTRAINT property_requests_seller_wallet_address_fkey
FOREIGN KEY (seller_wallet_address) REFERENCES mobile_app_users(wallet_address);

ALTER TABLE property_requests
ADD CONSTRAINT property_requests_buyer_wallet_address_fkey
FOREIGN KEY (buyer_wallet_address) REFERENCES mobile_app_users(wallet_address);

-- 7. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_property_requests_seller_wallet ON property_requests(seller_wallet_address);
CREATE INDEX IF NOT EXISTS idx_property_requests_buyer_wallet ON property_requests(buyer_wallet_address);
CREATE INDEX IF NOT EXISTS idx_property_requests_property_type ON property_requests(property_type);
CREATE INDEX IF NOT EXISTS idx_property_requests_status ON property_requests(status);

-- 8. Update default values for property_type and transaction_date if null
UPDATE property_requests
SET 
  property_type = 'unknown',
  transaction_date = created_at
WHERE property_type IS NULL OR transaction_date IS NULL;

COMMIT;