-- Remove existing tables to ensure clean slate
DROP TABLE IF EXISTS property_requests;
DROP TABLE IF EXISTS mobile_app_users;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS managers;

-- Create managers table with all required columns
CREATE TABLE managers (
    manager_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create employees table
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'employee',
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create mobile_app_users table
CREATE TABLE mobile_app_users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    national_id VARCHAR(14) UNIQUE NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create property_requests table
CREATE TABLE property_requests (
    request_id SERIAL PRIMARY KEY,
    seller_wallet_address VARCHAR(42) NOT NULL,
    buyer_wallet_address VARCHAR(42) NOT NULL,
    full_description TEXT,
    property_price DECIMAL(15,2) NOT NULL,
    ownership_document TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_wallet_address) REFERENCES mobile_app_users(wallet_address),
    FOREIGN KEY (buyer_wallet_address) REFERENCES mobile_app_users(wallet_address)
);

-- Add indexes for better query performance
CREATE INDEX idx_managers_active ON managers(active);
CREATE INDEX idx_employees_active ON employees(active);
CREATE INDEX idx_mobile_app_users_active ON mobile_app_users(active);
CREATE INDEX idx_property_requests_status ON property_requests(status);
