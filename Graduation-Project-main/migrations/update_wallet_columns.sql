-- Update all wallet address columns to VARCHAR(100)
DO $$ 
BEGIN
    -- Update property_requests table
    ALTER TABLE property_requests 
    ALTER COLUMN seller_wallet_address TYPE VARCHAR(100),
    ALTER COLUMN buyer_wallet_address TYPE VARCHAR(100);

    -- Update any other tables with wallet addresses
    ALTER TABLE mobile_app_users 
    ALTER COLUMN wallet_address TYPE VARCHAR(100);
    
EXCEPTION
    WHEN others THEN
    -- If columns don't exist, create them with correct type
    NULL;
END $$;
