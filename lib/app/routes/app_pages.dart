import 'package:get/get.dart';

import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/chat/chat_screen.dart';
import '../modules/chat/group_chat_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/profile/edit_profile_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/user_info/user_info_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
    ),
    GetPage(
      name: AppRoutes.groupChat,
      page: () => const GroupChatScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.userInfo,
      page: () => const UserInfoScreen(),
    ),
  ];
}