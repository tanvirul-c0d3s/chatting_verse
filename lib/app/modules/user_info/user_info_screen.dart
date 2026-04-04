import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../chat/chat_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/user_avatar.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  static const Color _primary = Color(0xFF0A84FF);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _textDark = Color(0xFF1C1C1E);

  bool _isUnfriending = false;

  AppUser? _resolveUser() {
    final dynamic args = Get.arguments;

    if (args is AppUser) return args;

    if (args is Map) {
      try {
        return AppUser.fromMap(Map<String, dynamic>.from(args));
      } catch (_) {
        // ignore and fallback
      }
    }

    if (Get.isRegistered<ChatController>()) {
      return Get.find<ChatController>().otherUser;
    }

    return null;
  }

  Future<void> _handleUnfriend(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend user?'),
        content: Text(
          'You will remove ${user.fullName} from your friend list and this chat will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isUnfriending) return;

    final authService = Get.find<AuthService>();
    final chatService = Get.find<ChatService>();
    final myUid = authService.currentUser?.uid;

    if (myUid == null) {
      Get.snackbar('Session expired', 'Please login again.');
      return;
    }

    setState(() => _isUnfriending = true);

    try {
      await chatService.unfriend(myUid: myUid, otherUid: user.uid);

      if (!mounted) return;

      Get.snackbar('Unfriended', '${user.fullName} has been removed.');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar('Unfriend failed', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUnfriending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _resolveUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('User Info'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'User data not found.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please open this screen from chat header info button.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _textDark,
        title: const Text(
          'User Info',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF56B2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      imageUrl: user.photoUrl,
                      radius: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: user.isOnline
                          ? Colors.green.withOpacity(.18)
                          : Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: user.isOnline
                            ? Colors.green.withOpacity(.25)
                            : Colors.white.withOpacity(.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: user.isOnline
                                ? Colors.greenAccent
                                : Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Full Name',
                    value: user.fullName.isEmpty ? 'Not available' : user.fullName,
                  ),
                  const SizedBox(height: 14),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email Address',
                    value: user.email.isEmpty ? 'Not available' : user.email,
                  ),
                  const SizedBox(height: 14),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    value: user.address.isEmpty ? 'Not available' : user.address,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUnfriending ? null : () => _handleUnfriend(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.withOpacity(.45),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isUnfriending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.person_remove_alt_1_rounded),
                label: Text(
                  _isUnfriending ? 'Unfriending...' : 'Unfriend',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  static const Color _primary = Color(0xFF0A84FF);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _textDark = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}