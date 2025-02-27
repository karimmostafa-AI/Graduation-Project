-- Add phone_number column to mobile_app_users if it doesn't exist

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'mobile_app_users' AND column_name = 'phone_number'
    ) THEN
        -- Add phone_number column if it doesn't exist
        ALTER TABLE mobile_app_users
        ADD COLUMN phone_number VARCHAR(20);
    END IF;
END $$;