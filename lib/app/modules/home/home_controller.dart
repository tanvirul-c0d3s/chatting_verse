import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../utils/helpers.dart';

class HomeUserItem {
  final AppUser user;
  final String roomId;
  final String lastMessage;
  final String lastMessageType;
  final Timestamp? lastMessageAt;
  final int unreadCount;

  HomeUserItem({
    required this.user,
    required this.roomId,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.unreadCount,
  });
}

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ChatService _chatService = Get.find<ChatService>();

  final users = <HomeUserItem>[].obs;
  final isLoading = false.obs;

  StreamSubscription<List<AppUser>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSubscription;

  final Map<String, AppUser> _usersMap = {};
  final Map<String, Map<String, dynamic>> _roomsMap = {};

  @override
  void onClose() {
    _usersSubscription?.cancel();
    _roomsSubscription?.cancel();
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
    await _roomsSubscription?.cancel();

    _usersSubscription = _authService.allUsersExceptMe(myUid).listen(
          (event) {
        _usersMap
          ..clear()
          ..addEntries(event.map((user) => MapEntry(user.uid, user)));
        _combineUsersWithRooms(myUid);
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar('Error', error.toString());
      },
    );

    _roomsSubscription = _chatService.roomsStream(myUid).listen(
          (snapshot) {
        _roomsMap
          ..clear()
          ..addEntries(
            snapshot.docs.map((doc) => MapEntry(doc.id, doc.data())),
          );
        _combineUsersWithRooms(myUid);
      },
      onError: (error) {
        isLoading.value = false;
        Get.snackbar('Error', error.toString());
      },
    );
  }

  void _combineUsersWithRooms(String myUid) {
    final items = _usersMap.values.map((user) {
      final roomId = getChatRoomId(myUid, user.uid);
      final room = _roomsMap[roomId];
      final unreadCounts = room?['unreadCounts'] as Map<String, dynamic>?;
      final unreadRaw = unreadCounts?[myUid];

      return HomeUserItem(
        user: user,
        roomId: roomId,
        lastMessage: (room?['lastMessage'] ?? '').toString(),
        lastMessageType: (room?['lastMessageType'] ?? 'text').toString(),
        lastMessageAt: room?['lastMessageAt'] as Timestamp?,
        unreadCount: unreadRaw is num ? unreadRaw.toInt() : 0,
      );
    }).toList();

    // Messenger style sorting:
    // newest conversation first, unread only visual highlight
    items.sort((a, b) {
      final aMillis = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
      final bMillis = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;

      if (aMillis != bMillis) {
        return bMillis.compareTo(aMillis);
      }

      return a.user.fullName.toLowerCase().compareTo(
        b.user.fullName.toLowerCase(),
      );
    });

    users.assignAll(items);
    isLoading.value = false;
  }
}