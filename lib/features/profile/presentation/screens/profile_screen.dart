import 'package:flutter/material.dart';

import '../../../messaging/presentation/widgets/coming_soon_widget.dart';

/// Profile screen placeholder
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: const Center(
        child: ComingSoonWidget(
          icon: Icons.person_outline,
          title: 'Profile Coming Soon',
          description:
              'View and edit your profile, manage preferences, and control your location sharing settings.\n\nThis feature will be available in a future update.',
        ),
      ),
    );
  }
}
