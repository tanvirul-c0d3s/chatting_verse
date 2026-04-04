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

class GroupItem {
  final String groupId;
  final String name;
  final List<String> members;
  final String lastMessage;
  final Timestamp? lastMessageAt;
  final int unreadCount;

  GroupItem({
    required this.groupId,
    required this.name,
    required this.members,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });
}

class ChatRequestItem {
  final String requestId;
  final String senderId;
  final String receiverId;
  final String status;

  ChatRequestItem({
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.status,
  });
}

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ChatService _chatService = Get.find<ChatService>();

  final users = <HomeUserItem>[].obs;
  final groups = <GroupItem>[].obs;
  final allUsers = <AppUser>[].obs;
  final incomingRequests = <ChatRequestItem>[].obs;
  final isLoading = false.obs;

  StreamSubscription<List<AppUser>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _groupsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _sentRequestsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _receivedRequestsSubscription;

  final Map<String, AppUser> _usersMap = {};
  final Map<String, Map<String, dynamic>> _roomsMap = {};
  final Map<String, ChatRequestItem> _requestsMap = {};

  @override
  void onClose() {
    _usersSubscription?.cancel();
    _roomsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _sentRequestsSubscription?.cancel();
    _receivedRequestsSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadUsers() async {
    final myUid = _authService.currentUser?.uid;

    if (myUid == null) {
      users.clear();
      groups.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    await _usersSubscription?.cancel();
    await _roomsSubscription?.cancel();
    await _groupsSubscription?.cancel();
    await _sentRequestsSubscription?.cancel();
    await _receivedRequestsSubscription?.cancel();

    _usersSubscription = _authService.allUsersExceptMe(myUid).listen(
          (event) {
        _usersMap
          ..clear()
          ..addEntries(event.map((user) => MapEntry(user.uid, user)));
        allUsers.assignAll(event);
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

    _groupsSubscription = _chatService.groupChatsStream(myUid).listen(
          (snapshot) {
        final sortedDocs = [...snapshot.docs]..sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aTs =
              (aData['updatedAt'] as Timestamp?) ??
                  (aData['lastMessageAt'] as Timestamp?) ??
                  (aData['createdAt'] as Timestamp?);
          final bTs =
              (bData['updatedAt'] as Timestamp?) ??
                  (bData['lastMessageAt'] as Timestamp?) ??
                  (bData['createdAt'] as Timestamp?);

          final aMs = aTs?.millisecondsSinceEpoch ?? 0;
          final bMs = bTs?.millisecondsSinceEpoch ?? 0;
          return bMs.compareTo(aMs);
        });

        final items = sortedDocs.map((doc) {
          final data = doc.data();
          final unreadRaw = data['unreadCounts'];
          final unreadMap = unreadRaw is Map
              ? Map<String, dynamic>.from(unreadRaw)
              : <String, dynamic>{};

          return GroupItem(
            groupId: doc.id,
            name: (data['name'] ?? 'Group').toString(),
            members: List<String>.from(data['members'] ?? const []),
            lastMessage: (data['lastMessage'] ?? '').toString(),
            lastMessageAt: data['lastMessageAt'] as Timestamp?,
            unreadCount:
            unreadMap[myUid] is num ? (unreadMap[myUid] as num).toInt() : 0,
          );
        }).toList();

        groups.assignAll(items);
      },
      onError: (error) {
        Get.snackbar('Groups', 'Failed to load groups: $error');
      },
    );

    _sentRequestsSubscription = _chatService.sentRequestsStream(myUid).listen(
          (snapshot) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          _requestsMap[doc.id] = ChatRequestItem(
            requestId: doc.id,
            senderId: (data['senderId'] ?? '').toString(),
            receiverId: (data['receiverId'] ?? '').toString(),
            status: (data['status'] ?? '').toString(),
          );
        }
        _combineUsersWithRooms(myUid);
      },
    );

    _receivedRequestsSubscription = _chatService
        .receivedRequestsStream(myUid)
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _requestsMap[doc.id] = ChatRequestItem(
          requestId: doc.id,
          senderId: (data['senderId'] ?? '').toString(),
          receiverId: (data['receiverId'] ?? '').toString(),
          status: (data['status'] ?? '').toString(),
        );
      }

      incomingRequests.assignAll(
        _requestsMap.values.where(
              (item) =>
          item.receiverId == myUid &&
              item.status == 'pending' &&
              _usersMap[item.senderId] != null,
        ),
      );

      _combineUsersWithRooms(myUid);
    });
  }

  Future<void> sendRequest(String targetUid) async {
    final myUid = _authService.currentUser?.uid;
    if (myUid == null) return;

    await _chatService.sendChatRequest(myUid: myUid, otherUid: targetUid);
    Get.snackbar('Success', 'Chat request sent');
  }

  Future<void> acceptRequest(ChatRequestItem request) async {
    await _chatService.updateRequestStatus(
      requestId: request.requestId,
      status: 'accepted',
    );

    await _chatService.ensureRoom(request.senderId, request.receiverId);
  }

  Future<void> rejectRequest(ChatRequestItem request) async {
    await _chatService.updateRequestStatus(
      requestId: request.requestId,
      status: 'rejected',
    );
  }

  Future<String?> createGroup({
    required String name,
    required List<String> selectedMemberIds,
  }) async {
    final myUid = _authService.currentUser?.uid;
    if (myUid == null) return null;

    if (name.trim().isEmpty || selectedMemberIds.isEmpty) {
      Get.snackbar('Group', 'Please add group name and select members');
      return null;
    }

    final groupId = await _chatService.createGroup(
      creatorId: myUid,
      name: name.trim(),
      memberIds: selectedMemberIds,
    );

    return groupId;
  }

  String requestStatusFor(String userId) {
    final myUid = _authService.currentUser?.uid;
    if (myUid == null) return '';

    final requestId = getChatRoomId(myUid, userId);
    final request = _requestsMap[requestId];
    if (request == null) return '';

    if (request.status == 'accepted') return 'accepted';

    if (request.status == 'pending') {
      if (request.senderId == myUid) return 'pending_sent';
      if (request.receiverId == myUid) return 'pending_received';
    }

    return request.status;
  }

  AppUser? userById(String uid) => _usersMap[uid];

  void _combineUsersWithRooms(String myUid) {
    final acceptedUserIds = <String>{};

    for (final request in _requestsMap.values) {
      if (request.status != 'accepted') continue;
      if (request.senderId == myUid) {
        acceptedUserIds.add(request.receiverId);
      }
      if (request.receiverId == myUid) {
        acceptedUserIds.add(request.senderId);
      }
    }

    final items = acceptedUserIds
        .map((uid) {
      final user = _usersMap[uid];
      if (user == null) return null;

      final roomId = getChatRoomId(myUid, user.uid);
      final room = _roomsMap[roomId];
      final unreadMapRaw = room?['unreadCounts'];
      final unreadCounts = unreadMapRaw is Map
          ? Map<String, dynamic>.from(unreadMapRaw)
          : <String, dynamic>{};
      final unreadRaw = unreadCounts[myUid];

      return HomeUserItem(
        user: user,
        roomId: roomId,
        lastMessage: (room?['lastMessage'] ?? '').toString(),
        lastMessageType: (room?['lastMessageType'] ?? 'text').toString(),
        lastMessageAt: room?['lastMessageAt'] as Timestamp?,
        unreadCount: unreadRaw is num ? unreadRaw.toInt() : 0,
      );
    })
        .whereType<HomeUserItem>()
        .toList();

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