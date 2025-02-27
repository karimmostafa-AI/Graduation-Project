-- Add property_address field to property_requests table
ALTER TABLE property_requests
ADD COLUMN property_address VARCHAR(500);

-- Update constraints on property_type to handle new types
COMMENT ON COLUMN property_requests.property_type IS 'Type of property (e.g., شقة, فيلا, أرض, محل تجاري, مكتب, سيارة)';

-- Create index on property_address for better performance
CREATE INDEX idx_property_requests_address ON property_requests(property_address);

-- Update existing records with default address for non-null property_type records that don't have an address
UPDATE property_requests
SET property_address = 'عنوان غير متاح'
WHERE property_address IS NULL AND property_type IS NOT NULL AND property_type != 'سيارة';