-- Add email column to mobile_app_users table

-- Add the column
ALTER TABLE mobile_app_users
ADD COLUMN email VARCHAR(255) UNIQUE;

-- Update the table to set a default value for existing records
-- You might want to update this with actual emails for existing users
UPDATE mobile_app_users
SET email = CONCAT(username, '@example.com')
WHERE email IS NULL;

-- Make email column NOT NULL after populating existing records
ALTER TABLE mobile_app_users
ALTER COLUMN email SET NOT NULL;