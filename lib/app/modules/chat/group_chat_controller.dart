import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';

class GroupChatController extends GetxController {
  final ChatService _chatService = Get.find<ChatService>();
  final AuthService _authService = Get.find<AuthService>();

  late String groupId;
  late String groupName;

  String? get myUid => _authService.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    groupId = (args['groupId'] ?? '').toString();
    groupName = (args['name'] ?? 'Group').toString();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream() {
    return _chatService.groupMessagesStream(groupId);
  }

  Future<void> sendText(String text) async {
    final uid = myUid;
    if (uid == null) return;

    await _chatService.sendGroupText(groupId: groupId, myUid: uid, text: text);
  }

  Future<void> markRead() async {
    final uid = myUid;
    if (uid == null) return;

    await _chatService.markGroupAsRead(groupId: groupId, myUid: uid);
  }

  Future<void> editMyTextMessage({
    required String messageId,
    required String text,
  }) async {
    final uid = myUid;
    if (uid == null) return;

    await _chatService.editTextMessage(
      roomId: groupId,
      messageId: messageId,
      myUid: uid,
      newText: text,
      isGroup: true,
    );
  }

  Future<void> deleteMyTextMessage(String messageId) async {
    final uid = myUid;
    if (uid == null) return;

    await _chatService.deleteTextMessage(
      roomId: groupId,
      messageId: messageId,
      myUid: uid,
      isGroup: true,
    );
  }

  Future<void> leaveGroup() async {
    final uid = myUid;
    if (uid == null) return;

    await _chatService.leaveGroup(groupId: groupId, userId: uid);
  }

  Future<void> addMembers(List<String> userIds) async {
    await _chatService.addMembersToGroup(groupId: groupId, memberIds: userIds);
  }
}