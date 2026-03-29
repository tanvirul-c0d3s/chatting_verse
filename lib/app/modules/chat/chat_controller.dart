import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/storage_service.dart';
import '../../utils/helpers.dart';

class ChatController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ChatService _chatService = Get.find<ChatService>();
  final StorageService _storageService = Get.find<StorageService>();

  late AppUser otherUser;
  late String roomId;

  final isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    otherUser = Get.arguments as AppUser;

    final myUid = _authService.currentUser!.uid;
    roomId = getChatRoomId(myUid, otherUser.uid);

    _chatService.ensureRoom(myUid, otherUser.uid);
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _chatService.sendText(
      myUid: _authService.currentUser!.uid,
      otherUid: otherUser.uid,
      text: trimmed,
    );
  }

  Future<void> pickAndSendMedia(String type) async {
    try {
      isUploading.value = true;

      FileType fileType = FileType.any;
      List<String>? allowedExtensions;

      if (type == 'image') {
        fileType = FileType.image;
      } else if (type == 'video') {
        fileType = FileType.video;
      } else if (type == 'audio') {
        fileType = FileType.custom;
        allowedExtensions = ['mp3', 'wav', 'm4a', 'aac'];
      }

      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: false,
        withData: true,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) return;

      final url = await _storageService.uploadChatFileBytes(
        roomId: roomId,
        fileName: file.name,
        bytes: bytes,
      );

      await _chatService.sendMedia(
        myUid: _authService.currentUser!.uid,
        otherUid: otherUser.uid,
        fileUrl: url,
        fileName: file.name,
        type: type,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isUploading.value = false;
    }
  }
}