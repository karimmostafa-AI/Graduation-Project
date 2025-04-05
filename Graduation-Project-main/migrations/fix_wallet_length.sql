ALTER TABLE property_requests
    ALTER COLUMN seller_wallet_address TYPE VARCHAR(255),
    ALTER COLUMN buyer_wallet_address TYPE VARCHAR(255);

ALTER TABLE mobile_app_users
    ALTER COLUMN wallet_address TYPE VARCHAR(255);

-- Also fix existing data if needed
UPDATE property_requests
SET seller_wallet_address = TRIM(seller_wallet_address),
    buyer_wallet_address = TRIM(buyer_wallet_address);

UPDATE mobile_app_users
SET wallet_address = TRIM(wallet_address);
