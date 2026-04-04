import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../utils/helpers.dart';

class ChatController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ChatService _chatService = Get.find<ChatService>();

  late AppUser otherUser;
  late String roomId;

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

  Future<void> editMyTextMessage({
    required String messageId,
    required String text,
  }) async {
    final currentUid = myUid;
    if (currentUid == null) return;

    await _chatService.editTextMessage(
      roomId: roomId,
      messageId: messageId,
      myUid: currentUid,
      newText: text,
    );
  }

  Future<void> deleteMyTextMessage(String messageId) async {
    final currentUid = myUid;
    if (currentUid == null) return;

    await _chatService.deleteTextMessage(
      roomId: roomId,
      messageId: messageId,
      myUid: currentUid,
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
      // silently ignore
    }
  }

  Future<void> markMessagesAsReadOnce() async {
    if (_didMarkInitialRead) return;

    _didMarkInitialRead = true;
    await markMessagesAsRead();
  }
}