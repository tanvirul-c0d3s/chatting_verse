import 'package:get/get.dart';

import '../data/services/auth_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/session_service.dart';
import '../data/services/storage_service.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/home/home_controller.dart';
import '../modules/profile/profile_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SessionService(), permanent: true);
    Get.put(StorageService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(ChatService(), permanent: true);

    Get.put(AuthController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
  }
}