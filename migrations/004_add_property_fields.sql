-- Add property_type and transaction_date columns to property_requests table
ALTER TABLE property_requests
ADD COLUMN property_type VARCHAR(50),
ADD COLUMN transaction_date TIMESTAMP;

-- Update existing records with default values
-- You might want to adjust these defaults based on your needs
UPDATE property_requests
SET 
  property_type = 'unknown',
  transaction_date = created_at
WHERE property_type IS NULL OR transaction_date IS NULL;

-- Add a comment describing what these fields are for
COMMENT ON COLUMN property_requests.property_type IS 'Type of property (e.g., apartment, house, land, etc.)';
COMMENT ON COLUMN property_requests.transaction_date IS 'Date when the transaction is scheduled to occur';

-- Create an index for better query performance on property_type
CREATE INDEX idx_property_requests_property_type ON property_requests(property_type);