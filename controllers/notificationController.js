const pool = require('../db');

// Create a new notification
exports.createNotification = async (userWalletAddress, title, message, requestId = null) => {
  try {
    const query = `
      INSERT INTO notifications (user_wallet_address, title, message, related_request_id)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `;
    const values = [userWalletAddress, title, message, requestId];
    const result = await pool.query(query, values);
    return result.rows[0];
  } catch (error) {
    console.error('خطأ في إنشاء الإشعار:', error);
    throw error;
  }
};

// Get all notifications for a user
exports.getUserNotifications = async (req, res) => {
  try {
    const userWalletAddress = req.user.wallet_address;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    
    if (!userWalletAddress) {
      return res.status(400).json({ error: 'لم يتم العثور على عنوان المحفظة في الرمز المميز' });
    }
    
    const query = `
      SELECT *
      FROM notifications
      WHERE user_wallet_address = $1
      ORDER BY created_at DESC
      LIMIT $2 OFFSET $3
    `;
    const result = await pool.query(query, [userWalletAddress, limit, offset]);
    
    // Get total count for pagination
    const countQuery = `
      SELECT COUNT(*) as total, 
             COUNT(CASE WHEN is_read = false THEN 1 END) as unread
      FROM notifications
      WHERE user_wallet_address = $1
    `;
    const countResult = await pool.query(countQuery, [userWalletAddress]);
    
    return res.json({ 
      success: true,
      notifications: result.rows.map(notification => ({
        id: notification.notification_id, // Add id alias for notification_id
        notification_id: notification.notification_id, // Keep the original for backward compatibility
        title: notification.title,
        message: notification.message,
        type: "system", // Add default type field for the Flutter app
        is_read: notification.is_read,
        created_at: notification.created_at,
        related_request_id: notification.related_request_id,
        status: notification.is_read ? 'مقروء' : 'غير مقروء'
      })),
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit,
        offset
      },
      unread_count: parseInt(countResult.rows[0].unread)
    });
  } catch (error) {
    console.error('خطأ في جلب الإشعارات:', error);
    return res.status(500).json({ 
      error: 'خطأ في النظام',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get unread notifications count for a user
exports.getNotificationsCount = async (req, res) => {
  try {
    // Get wallet address from JWT token
    const userWalletAddress = req.user.wallet_address;
    
    if (!userWalletAddress) {
      return res.status(400).json({ error: 'لم يتم العثور على عنوان المحفظة في الرمز المميز' });
    }
    
    const query = `
      SELECT COUNT(*) as unread_count
      FROM notifications
      WHERE user_wallet_address = $1 AND is_read = false
    `;
    const result = await pool.query(query, [userWalletAddress]);
    
    return res.json({ 
      success: true,
      unread_count: parseInt(result.rows[0].unread_count)
    });
  } catch (error) {
    console.error('خطأ في جلب عدد الإشعارات:', error);
    return res.status(500).json({ 
      error: 'خطأ في النظام',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userWalletAddress = req.user.wallet_address;
    
    console.log(`Attempting to mark notification ${id} as read for user ${userWalletAddress}`);
    
    // Validate notification ID
    if (!id || id === '0' || isNaN(parseInt(id))) {
      console.log(`Invalid notification ID: ${id}`);
      return res.status(400).json({ error: 'معرف الإشعار غير صالح', details: 'Invalid notification ID' });
    }
    
    if (!userWalletAddress) {
    }
    
    const query = `
      UPDATE notifications
      SET is_read = true
      WHERE notification_id = $1 AND user_wallet_address = $2
      RETURNING *
    `;
    const result = await pool.query(query, [id, userWalletAddress]);
    
    if (result.rows.length === 0) {
      // Check if notification exists at all
      const checkQuery = `SELECT notification_id FROM notifications WHERE notification_id = $1`;
      const checkResult = await pool.query(checkQuery, [id]);
      
      if (checkResult.rows.length === 0) {
        console.log(`Notification with ID ${id} does not exist`);
        return res.status(404).json({ 
          error: 'الإشعار غير موجود', 
          details: 'Notification not found' 
        });
      } else {
        console.log(`Notification with ID ${id} exists but does not belong to user ${userWalletAddress}`);
        return res.status(403).json({ 
          error: 'غير مصرح بالوصول إلى هذا الإشعار',
          details: 'Notification exists but does not belong to this user' 
        });
      }
    }
    
    console.log(`Successfully marked notification ${id} as read for user ${userWalletAddress}`);
    return res.json({
      success: true,
      notification: {
        ...result.rows[0],
        status: 'مقروء'
      }
    });
  } catch (error) {
    console.error('خطأ في تحديد الإشعار كمقروء:', error);
    return res.status(500).json({ 
      error: 'خطأ في النظام',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};


