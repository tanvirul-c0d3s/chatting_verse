import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final user = Rxn<AppUser>();
  final isLoading = false.obs;

  StreamSubscription<AppUser>? _profileSubscription;

  @override
  void onClose() {
    _profileSubscription?.cancel();
    super.onClose();
  }

  Future<void> clearSessionStream() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    user.value = null;
    isLoading.value = false;
  }

  Future<void> loadProfile() async {
    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      user.value = null;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    await _profileSubscription?.cancel();

    _profileSubscription = _authService.getMyProfile(uid).listen(
          (profile) {
        user.value = profile;
        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar('Profile Error', error.toString());
      },
    );
  }
}