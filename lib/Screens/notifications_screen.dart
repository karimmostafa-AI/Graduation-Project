import 'package:flutter/material.dart';
import 'package:app/Models/notification_model.dart';
import 'package:app/utils/api_client.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiClient.dio.get('/user/notifications');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if data is null
        if (data == null) {
          throw Exception('استجابة API غير صالحة: لا توجد بيانات');
        }

        // Check success flag with proper null handling
        if (data['success'] == true) {
          // Use null-aware operator and check if it's actually a List
          final List<dynamic>? notificationsJson =
              data['notifications'] as List<dynamic>?;

          if (notificationsJson != null) {
            // Debug print to see what's coming from the API
            print(
                'First notification data: ${notificationsJson.isNotEmpty ? notificationsJson.first : "No notifications"}');
          }

          if (notificationsJson == null) {
            setState(() {
              _notifications = [];
              _isLoading = false;
            });
            return;
          }

          setState(() {
            try {
              _notifications = notificationsJson
                  .map((json) => NotificationModel.fromJson(json))
                  .toList();
            } catch (e) {
              print('Error parsing notifications: $e');
              _notifications = [];
              _hasError = true;
              _errorMessage = 'خطأ في تنسيق البيانات: ${e.toString()}';
            }
            _isLoading = false;
          });
        } else {
          throw Exception(
              'فشل تحميل الإشعارات: ${data['message'] ?? 'خطأ غير معروف'}');
        }
      } else {
        throw Exception('فشل تحميل الإشعارات: ${response.statusCode}');
      }
    } catch (e) {
      print('Notification fetch error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    // Don't attempt to mark notifications with ID 0 as read
    if (notificationId == 0) {
      print('Skipping mark as read for error notification with ID 0');
      return;
    }

    try {
      final response =
          await ApiClient.dio.patch('/notifications/$notificationId/read');

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications.map((notification) {
            if (notification.id == notificationId) {
              return NotificationModel(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                createdAt: notification.createdAt,
                isRead: true,
              );
            }
            return notification;
          }).toList();
        });
      } else {
        throw Exception('فشل تحديث الإشعار: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فشل في تحديث حالة الإشعار'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'إغلاق',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // First mark as read
    if (!notification.isRead && notification.id != 0) {
      await _markAsRead(notification.id);
    }

    // Then show notification details
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      'تفاصيل الإشعار',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Notification content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Icon and title
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          NotificationCard(
                                  notification: notification, onTap: () {})
                              ._getIconForType(notification.type),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24),

                      // Date and time
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(Icons.access_time, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year} - ${notification.createdAt.hour}:${notification.createdAt.minute}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Full message
                      Text(
                        'المحتوى:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notification.message,
                          style: TextStyle(fontSize: 16, height: 1.5),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ),

                      // If there's additional property-specific info for property type
                      if (notification.type.toLowerCase() == 'property') ...[
                        SizedBox(height: 24),
                        Text(
                          'معلومات إضافية:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'رقم الطلب: ${notification.id}\nنوع الإشعار: ${_getNotificationType(notification.type)}',
                            style: TextStyle(fontSize: 16),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'property':
        return 'عقاري';
      case 'transaction':
        return 'معاملة';
      case 'system':
        return 'نظام';
      case 'error':
        return 'خطأ';
      default:
        return 'إشعار';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'حدث خطأ: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchNotifications,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد إشعارات',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                          );
                        },
                      ),
                    ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Don't make error notifications clickable
    final bool isErrorNotification =
        notification.id == 0 || notification.type == 'error';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: InkWell(
        onTap: isErrorNotification
            ? null
            : onTap, // Don't trigger onTap for error notifications
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // For RTL Arabic layout
            children: [
              Row(
                textDirection: TextDirection.rtl, // For RTL Arabic layout
                children: [
                  _getIconForType(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: notification.isRead || isErrorNotification
                            ? Colors.black87
                            : Theme.of(context).primaryColor,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (!isErrorNotification) // Only show timestamp for real notifications
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              if (!notification.isRead && !isErrorNotification)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Make the method non-private so it can be accessed
  Widget _getIconForType(String type) {
    IconData iconData;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'property':
        iconData = Icons.home;
        iconColor = Colors.blue;
        break;
      case 'transaction':
        iconData = Icons.receipt;
        iconColor = Colors.green;
        break;
      case 'system':
        iconData = Icons.notifications;
        iconColor = Colors.orange;
        break;
      case 'error':
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.circle_notifications;
        iconColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 22,
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return 'منذ ${(difference.inDays / 365).floor()} سنة';
    } else if (difference.inDays > 30) {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
