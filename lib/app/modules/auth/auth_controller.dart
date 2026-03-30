import 'dart:async';
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
      try {
        fcmToken = await _notificationService
            .getFcmToken()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        fcmToken = '';
      }

      final credential = await _authService.register(
        fullName: fullName,
        address: address,
        email: email,
        password: password,
        photoUrl: '',
        fcmToken: fcmToken,
      ).timeout(const Duration(seconds: 20));

      final uid = credential.user!.uid;
      String photoUrl = '';

      if (imageBytes != null) {
        photoUrl = await _storageService.uploadProfileBytes(
          uid: uid,
          bytes: imageBytes,
        ).timeout(const Duration(seconds: 30));

        await _authService.updateProfile(
          uid: uid,
          fullName: fullName,
          address: address,
          photoUrl: photoUrl,
        ).timeout(const Duration(seconds: 15));
      }

      await _sessionService.saveLogin(
        uid: uid,
        email: email,
      ).timeout(const Duration(seconds: 10));

      Get.snackbar('Success', 'Registration successful');
      Get.offAllNamed(AppRoutes.home);
    } on TimeoutException {
      Get.snackbar(
        'Register Failed',
        'Request timed out. Please check internet and try again.',
      );
    } catch (e) {
      Get.snackbar('Register Failed', e.toString());
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