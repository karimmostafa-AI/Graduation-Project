-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  notification_id SERIAL PRIMARY KEY,
  user_wallet_address VARCHAR(42) NOT NULL,
  title VARCHAR(100) NOT NULL,
  message TEXT NOT NULL,
  related_request_id INTEGER,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_wallet_address) REFERENCES mobile_app_users(wallet_address),
  FOREIGN KEY (related_request_id) REFERENCES property_requests(request_id) ON DELETE CASCADE
);

-- Add index for better query performance
CREATE INDEX idx_notifications_user_wallet ON notifications(user_wallet_address);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);