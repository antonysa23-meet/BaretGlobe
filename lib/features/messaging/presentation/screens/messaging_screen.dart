import 'package:flutter/material.dart';

import '../widgets/coming_soon_widget.dart';

/// Messaging screen placeholder
class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/Baret.png',
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 80,
        ),
      ),
      body: const Center(
        child: ComingSoonWidget(
          icon: Icons.message_outlined,
          title: 'Messages Coming Soon',
          description:
              'Chat with fellow Baret Scholars alumni from around the world.\n\nThis feature will be available in a future update.',
        ),
      ),
    );
  }
}
