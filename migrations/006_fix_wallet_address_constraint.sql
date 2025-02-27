-- Add unique constraint to wallet_address if it doesn't exist

-- Check if the unique constraint already exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'mobile_app_users_wallet_address_key'
    ) THEN
        -- Add unique constraint
        ALTER TABLE mobile_app_users
        ADD CONSTRAINT mobile_app_users_wallet_address_key UNIQUE (wallet_address);
    END IF;
END $$;