import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final users = <AppUser>[].obs;
  final isLoading = false.obs;

  StreamSubscription<List<AppUser>>? _usersSubscription;

  @override
  void onClose() {
    _usersSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadUsers() async {
    final myUid = _authService.currentUser?.uid;

    if (myUid == null) {
      users.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    await _usersSubscription?.cancel();

    _usersSubscription = _authService.allUsersExceptMe(myUid).listen(
          (event) {
        users.assignAll(event);
        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar('Error', error.toString());
      },
    );
  }
}