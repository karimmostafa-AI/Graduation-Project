-- Remove the UNIQUE constraint from username in mobile_app_users table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'mobile_app_users_username_key' 
    AND conrelid = 'mobile_app_users'::regclass
  ) THEN
    ALTER TABLE mobile_app_users DROP CONSTRAINT mobile_app_users_username_key;
  END IF;
END $$;