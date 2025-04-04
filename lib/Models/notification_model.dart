class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        // Check for both 'id' and 'notification_id' fields
        id: json['id'] ?? json['notification_id'] ?? 0,
        title: json['title'] ?? 'إشعار جديد',
        message: json['message'] ?? 'لا يوجد محتوى للإشعار',
        // If type is not provided, determine it based on title or related_request_id
        type: json['type'] ??
            (json['related_request_id'] != null ? 'property' : 'system'),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        isRead: json['is_read'] ?? false,
      );
    } catch (e) {
      print('Error parsing notification: $e');
      // Return a default notification with error info
      return NotificationModel(
        id: 0,
        title: 'خطأ في التحميل',
        message: 'فشل في تحميل بيانات الإشعار',
        type: 'error',
        createdAt: DateTime.now(),
        isRead: false,
      );
    }
  }
}
