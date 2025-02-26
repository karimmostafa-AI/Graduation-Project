import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ApiClient {
  // Create a single Dio instance with a CookieJar
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.8:5000/api',
      connectTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(CookieManager(CookieJar()));
}