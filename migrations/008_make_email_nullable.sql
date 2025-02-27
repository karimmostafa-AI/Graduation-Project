-- Make email column nullable in mobile_app_users table
ALTER TABLE mobile_app_users
ALTER COLUMN email DROP NOT NULL;