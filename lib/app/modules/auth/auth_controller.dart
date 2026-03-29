import 'dart:typed_data';

import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();
  final SessionService _sessionService = Get.find<SessionService>();
  final NotificationService _notificationService =
  Get.find<NotificationService>();

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    _authService.authChanges().listen((user) {
      if (user != null) {
        _sessionService.saveLogin(
          uid: user.uid,
          email: user.email ?? '',
        );
      }
    });
  }

  Future<void> register({
    required String fullName,
    required String address,
    required String email,
    required String password,
    required Uint8List? imageBytes,
  }) async {
    try {
      isLoading.value = true;

      String fcmToken = '';
      print('step 1 start');

      final credential = await _authService.register(
        fullName: fullName,
        address: address,
        email: email,
        password: password,
        photoUrl: '',
        fcmToken: fcmToken,
      );
      print('step 2 auth done');

      final uid = credential.user!.uid;
      String photoUrl = '';

      if (imageBytes != null) {
        print('step 3 upload start');

        photoUrl = await _storageService.uploadProfileBytes(
          uid: uid,
          bytes: imageBytes,
        );
        print('step 4 upload done');

        await _authService.updateProfile(
          uid: uid,
          fullName: fullName,
          address: address,
          photoUrl: photoUrl,
        );
        print('step 5 profile updated');

      }

      await _sessionService.saveLogin(
        uid: uid,
        email: email,
      );
      print('step 6 session saved');


      Get.snackbar('Success', 'Registration successful');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar('Register Failed', e.toString());
      print('REGISTER ERROR: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final result = await _authService.login(
        email: email,
        password: password,
      );

      await _sessionService.saveLogin(
        uid: result.user!.uid,
        email: email,
      );

      Get.snackbar(
        'Success',
        'Login successful',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      await _authService.logout();
      await _sessionService.clear();

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Logout Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}