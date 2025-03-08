import 'package:app/Screens/cars_screen.dart';
import 'package:app/Screens/contracts_screen.dart';
import 'package:app/Screens/notifications_screen.dart'; // Add this import
import 'package:app/Screens/profile_screen.dart';
import 'package:app/Screens/properties_screen.dart';
import 'package:app/Screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/Screens/authentication_screen.dart';
import 'header_icon.dart';
import 'color_palette.dart';
import 'package:app/utils/api_client.dart';

class AppHeader extends StatefulWidget {
  final String userName;

  const AppHeader({Key? key, required this.userName}) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Update the endpoint to match what's in routes.js
      final response = await ApiClient.dio.get('/user/notifications/count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _unreadCount = response.data['unread_count'] ?? 0;
          _isLoadingNotifications = false;
        });
      } else {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingNotifications = false;
      });
      print('Error fetching notification count: $e');
    }
  }

  void navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Updated logout function using Dio with cookie management
  Future<void> _logout(BuildContext context) async {
    // Existing logout code...
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Make API request using the shared Dio instance
      final response = await ApiClient.dio.post('/auth/logout');

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الخروج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
        );
      } else {
        // Show error message
        final errorData = response.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'فشل تسجيل الخروج'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الاتصال: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          // Add a row to hold the welcome text and buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'تسجيل الخروج',
                onPressed: () => _logout(context),
              ),

              // Notification button with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 28),
                    tooltip: 'الإشعارات',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsScreen()),
                      ).then((_) =>
                          _fetchNotificationCount()); // Refresh count after returning
                    },
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_isLoadingNotifications)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              ),

              // Welcome text
              Text(
                "مرحباً، ${widget.userName}",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),

              // Profile button
              IconButton(
                icon: Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(userName: widget.userName),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HeaderIcon(
                  icon: Icons.apartment,
                  label: "عقارات",
                  onTap: () => navigateTo(context, PropertiesScreen())),
              HeaderIcon(
                  icon: Icons.directions_car,
                  label: "سيارات",
                  onTap: () => navigateTo(context, CarsScreen())),
              HeaderIcon(
                  icon: Icons.assignment,
                  label: "العقود",
                  onTap: () => navigateTo(context, ContractsScreen())),
              HeaderIcon(
                  icon: Icons.qr_code,
                  label: "المسح",
                  onTap: () => navigateTo(context, ScanScreen())),
            ],
          ),
        ],
      ),
    );
  }
}
