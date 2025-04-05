-- Update the property_requests table with correct field lengths
ALTER TABLE property_requests 
    ALTER COLUMN seller_wallet_address TYPE VARCHAR(100),
    ALTER COLUMN buyer_wallet_address TYPE VARCHAR(100);
