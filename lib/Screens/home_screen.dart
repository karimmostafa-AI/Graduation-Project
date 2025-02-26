import 'package:app/Components/app_header.dart';
import 'package:app/Components/quick_actions.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(180),
        child: AppHeader(userName: "أحمد"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuickActions(),
            const SizedBox(height: 20),
            // RecentTransactions(),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavBar(),
    );
  }
}
