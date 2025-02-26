import 'package:app/Screens/cars_screen.dart';
import 'package:app/Screens/contracts_screen.dart';
import 'package:app/Screens/properties_screen.dart';
import 'package:app/Screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:app/Screens/authentication_screen.dart';
import 'header_icon.dart';
import 'color_palette.dart';
import 'package:app/utils/api_client.dart';

class AppHeader extends StatelessWidget {
  final String userName;

  const AppHeader({Key? key, required this.userName}) : super(key: key);

  void navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Updated logout function using Dio with cookie management
  Future<void> _logout(BuildContext context) async {
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

      if (response.statusCode == 200 || response.statusCode == 204) {
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
          // Add a row to hold both the welcome text and logout button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'تسجيل الخروج',
                onPressed: () => _logout(context),
              ),
              // Welcome text
              Text(
                "مرحباً، $userName",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
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
