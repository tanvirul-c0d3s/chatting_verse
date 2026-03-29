import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../widgets/user_avatar.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser user = Get.arguments as AppUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserAvatar(
              imageUrl: user.photoUrl,
              radius: 55,
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(user.email),
            const SizedBox(height: 10),
            Text(
              user.address,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text(user.isOnline ? 'Online' : 'Offline'),
            ),
          ],
        ),
      ),
    );
  }
}