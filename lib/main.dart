import 'package:flutter/material.dart';
import 'package:app/utils/constants.dart';
import 'package:app/screens/splash_screen.dart';
 // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
        ),
      ),
      // We keep the SplashScreen as the initial screen
      // It should navigate to HomeScreen after the splash duration
      home: const SplashScreen(),
    );
  }
}
