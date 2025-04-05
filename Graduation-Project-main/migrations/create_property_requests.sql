CREATE TABLE IF NOT EXISTS property_requests (
    request_id SERIAL PRIMARY KEY,
    property_id VARCHAR(16) UNIQUE NOT NULL,
    seller_wallet_address VARCHAR(42) NOT NULL,
    buyer_wallet_address VARCHAR(42) NOT NULL,
    full_description TEXT NOT NULL,
    property_price DECIMAL(20,8) NOT NULL,
    ownership_document VARCHAR(255),
    token_id BIGINT,
    status VARCHAR(20) DEFAULT 'pending',
    transaction_hash VARCHAR(66),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
