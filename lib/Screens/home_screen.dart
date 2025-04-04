import 'package:app/Components/app_header.dart';
import 'package:app/Components/quick_actions.dart';
import 'package:app/Screens/chat_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  // Format name to show only first name and truncate if needed
  String _formatUserName() {
    // Extract the first name (split by space and take first part)
    final firstName = userName.split(' ')[0];

    // Check if first name is longer than 8 characters
    if (firstName.length > 8) {
      // Return first 6 characters followed by "..."
      return '${firstName.substring(0, 6)}...';
    }

    // Return the full first name if it's not too long
    return firstName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(180),
        child: AppHeader(userName: _formatUserName()),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ChatScreen()));
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.chat),
        tooltip: 'Chat with AI Assistant',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}
