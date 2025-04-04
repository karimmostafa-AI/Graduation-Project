import 'package:app/Screens/authentication_screen.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';

class ApiClient {
  // Create a single Dio instance with a CookieJar
  static final Dio dio = Dio(
    BaseOptions(
      //             public device IP address and port
      baseUrl: 'http://Your public ip:5000/api',
      connectTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )
    ..interceptors.add(InterceptorsWrapper(
      onError: (e, handler) async {
        if (e.response?.statusCode == 401 &&
            e.response?.data['expiredAt'] != null) {
          // Token expired
          final navigatorKey = GlobalKey<NavigatorState>();
          if (navigatorKey.currentState != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content:
                    Text('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى'),
                backgroundColor: Colors.orange,
              ),
            );

            // Navigate to login
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => AuthenticationScreen()),
              (route) => false,
            );
          }
        }
        return handler.next(e);
      },
    ))
    ..interceptors.add(CookieManager(CookieJar()));
}
