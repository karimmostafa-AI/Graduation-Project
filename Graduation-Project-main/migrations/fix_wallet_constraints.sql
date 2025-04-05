-- Drop existing foreign key constraints if they exist
ALTER TABLE property_requests 
    DROP CONSTRAINT IF EXISTS property_requests_buyer_wallet_address_fkey,
    DROP CONSTRAINT IF EXISTS property_requests_seller_wallet_address_fkey;

-- Update mobile_app_users table
ALTER TABLE mobile_app_users
    ALTER COLUMN wallet_address TYPE VARCHAR(255);

-- Update property_requests table
ALTER TABLE property_requests
    ALTER COLUMN buyer_wallet_address TYPE VARCHAR(255),
    ALTER COLUMN seller_wallet_address TYPE VARCHAR(255);

-- Add new foreign key constraints with ON INSERT CASCADE
ALTER TABLE property_requests
    ADD CONSTRAINT property_requests_buyer_wallet_address_fkey 
    FOREIGN KEY (buyer_wallet_address) 
    REFERENCES mobile_app_users(wallet_address) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE property_requests
    ADD CONSTRAINT property_requests_seller_wallet_address_fkey 
    FOREIGN KEY (seller_wallet_address) 
    REFERENCES mobile_app_users(wallet_address) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_mobile_app_users_wallet 
ON mobile_app_users(wallet_address);
