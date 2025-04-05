-- Update wallet address column lengths in both tables
ALTER TABLE property_requests 
    ALTER COLUMN seller_wallet_address TYPE VARCHAR(100),
    ALTER COLUMN buyer_wallet_address TYPE VARCHAR(100);

ALTER TABLE mobile_app_users
    ALTER COLUMN wallet_address TYPE VARCHAR(100);
