import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final isRoomReady = false.obs;

  bool _didMarkInitialRead = false;

  String? get myUid => _authService.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();

    otherUser = Get.arguments as AppUser;

    final currentUid = myUid;
    if (currentUid == null) {
      Future.microtask(() {
        Get.back();
        Get.snackbar('Session expired', 'Please login again');
      });
      return;
    }

    roomId = getChatRoomId(currentUid, otherUser.uid);
    _initRoom(currentUid);
  }

  Future<void> _initRoom(String currentUid) async {
    try {
      isRoomReady.value = false;

      await _chatService.ensureRoom(currentUid, otherUser.uid);

      isRoomReady.value = true;

      await markMessagesAsRead();
    } catch (e) {
      isRoomReady.value = false;
      Get.snackbar('Chat Error', e.toString());
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream() {
    return _chatService.messagesStream(roomId);
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final currentUid = myUid;
    if (currentUid == null) return;

    await _chatService.sendText(
      myUid: currentUid,
      otherUid: otherUser.uid,
      text: trimmed,
    );
  }

  Future<void> markMessagesAsRead() async {
    if (!isRoomReady.value) return;

    final currentUid = myUid;
    if (currentUid == null) return;

    try {
      await _chatService.markRoomAsRead(
        roomId: roomId,
        myUid: currentUid,
      );
    } catch (_) {
      // user ke snackbar dekhabo na
      // silently ignore korchi
    }
  }

  Future<void> markMessagesAsReadOnce() async {
    if (_didMarkInitialRead) return;

    _didMarkInitialRead = true;
    await markMessagesAsRead();
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

      final currentUid = myUid;
      if (currentUid == null) return;

      final url = await _storageService.uploadChatFileBytes(
        roomId: roomId,
        fileName: file.name,
        bytes: bytes,
      );

      await _chatService.sendMedia(
        myUid: currentUid,
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