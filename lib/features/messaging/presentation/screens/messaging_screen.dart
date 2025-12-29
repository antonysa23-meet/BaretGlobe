import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/coming_soon_widget.dart';

/// Messaging screen placeholder
class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
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
