import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../utils/helpers.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> groupMessagesStream(String groupId) {
    return _firestore
        .collection('chat_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> roomsStream(String myUid) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> groupChatsStream(String myUid) {
    return _firestore
        .collection('chat_groups')
        .where('members', arrayContains: myUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sentRequestsStream(String myUid) {
    return _firestore
        .collection('chat_requests')
        .where('senderId', isEqualTo: myUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> receivedRequestsStream(
      String myUid,
      ) {
    return _firestore
        .collection('chat_requests')
        .where('receiverId', isEqualTo: myUid)
        .snapshots();
  }

  Future<void> sendChatRequest({
    required String myUid,
    required String otherUid,
  }) async {
    final requestId = getChatRoomId(myUid, otherUid);
    final requestRef = _firestore.collection('chat_requests').doc(requestId);

    final existing = await requestRef.get();
    final existingData = existing.data();

    if (existing.exists && existingData != null) {
      final status = (existingData['status'] ?? '').toString();

      if (status == 'accepted' || status == 'pending') {
        return;
      }
    }

    await requestRef.set({
      'requestId': requestId,
      'senderId': myUid,
      'receiverId': otherUid,
      'participants': [myUid, otherUid],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _firestore.collection('chat_requests').doc(requestId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
  }) async {
    final groupId = _uuid.v4();
    final members = {...memberIds, creatorId}.toList();

    await _firestore.collection('chat_groups').doc(groupId).set({
      'groupId': groupId,
      'name': name,
      'members': members,
      'admins': [creatorId],
      'createdBy': creatorId,
      'lastMessage': '',
      'lastMessageType': 'text',
      'lastMessageAt': null,
      'unreadCounts': {for (final member in members) member: 0},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return groupId;
  }

  Future<void> addMembersToGroup({
    required String groupId,
    required List<String> memberIds,
  }) async {
    if (memberIds.isEmpty) return;

    final ref = _firestore.collection('chat_groups').doc(groupId);
    await ref.update({
      'members': FieldValue.arrayUnion(memberIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snap = await ref.get();
    final data = snap.data() ?? {};
    final unreadRaw = data['unreadCounts'];
    final unreadCounts = unreadRaw is Map
        ? Map<String, dynamic>.from(unreadRaw)
        : <String, dynamic>{};

    for (final m in memberIds) {
      unreadCounts.putIfAbsent(m, () => 0);
    }

    await ref.set({
      'unreadCounts': unreadCounts,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> ensureRoom(String myUid, String otherUid) async {
    final roomId = getChatRoomId(myUid, otherUid);

    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      await roomRef.set({
        'roomId': roomId,
        'participants': [myUid, otherUid],
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageAt': null,
        'unreadCounts': {
          myUid: 0,
          otherUid: 0,
        },
      });
    }

    return roomId;
  }

  Future<void> sendText({
    required String myUid,
    required String otherUid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final roomId = await ensureRoom(myUid, otherUid);
    final id = _uuid.v4();

    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(id)
        .set({
      'id': id,
      'senderId': myUid,
      'receiverId': otherUid,
      'text': trimmed,
      'fileUrl': '',
      'fileName': '',
      'thumbnailUrl': '',
      'type': 'text',
      'isEdited': false,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': [myUid],
    });

    await _firestore.collection('chat_rooms').doc(roomId).set({
      'roomId': roomId,
      'participants': [myUid, otherUid],
      'lastMessage': trimmed,
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts.$otherUid': FieldValue.increment(1),
      'unreadCounts.$myUid': 0,
    }, SetOptions(merge: true));
  }

  Future<void> sendGroupText({
    required String groupId,
    required String myUid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final id = _uuid.v4();

    await _firestore
        .collection('chat_groups')
        .doc(groupId)
        .collection('messages')
        .doc(id)
        .set({
      'id': id,
      'senderId': myUid,
      'receiverId': '',
      'text': trimmed,
      'fileUrl': '',
      'fileName': '',
      'thumbnailUrl': '',
      'type': 'text',
      'isEdited': false,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': [myUid],
    });

    final groupDoc =
    await _firestore.collection('chat_groups').doc(groupId).get();
    final members = List<String>.from(groupDoc.data()?['members'] ?? const []);

    final unreadUpdate = <String, dynamic>{};
    for (final member in members) {
      unreadUpdate['unreadCounts.$member'] =
      member == myUid ? 0 : FieldValue.increment(1);
    }

    await _firestore.collection('chat_groups').doc(groupId).set({
      'lastMessage': trimmed,
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...unreadUpdate,
    }, SetOptions(merge: true));
  }

  Future<void> editTextMessage({
    required String roomId,
    required String messageId,
    required String myUid,
    required String newText,
    bool isGroup = false,
  }) async {
    final parent = isGroup ? 'chat_groups' : 'chat_rooms';
    final msgRef = _firestore
        .collection(parent)
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    final msgDoc = await msgRef.get();
    final data = msgDoc.data();
    if (data == null) return;

    if (data['senderId'] != myUid || data['type'] != 'text') return;

    await msgRef.update({
      'text': newText.trim(),
      'isEdited': true,
    });

    final parentRef = _firestore.collection(parent).doc(roomId);
    final parentDoc = await parentRef.get();
    if ((parentDoc.data()?['lastMessage'] ?? '').toString() ==
        (data['text'] ?? '').toString()) {
      await parentRef.set({
        'lastMessage': newText.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteTextMessage({
    required String roomId,
    required String messageId,
    required String myUid,
    bool isGroup = false,
  }) async {
    final parent = isGroup ? 'chat_groups' : 'chat_rooms';
    final msgRef = _firestore
        .collection(parent)
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    final msgDoc = await msgRef.get();
    final data = msgDoc.data();
    if (data == null) return;

    if (data['senderId'] != myUid || data['type'] != 'text') return;

    await msgRef.update({
      'text': 'This message was deleted',
      'isDeleted': true,
      'isEdited': false,
    });
  }

  Future<void> markRoomAsRead({
    required String roomId,
    required String myUid,
  }) async {
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);

    await roomRef.set({
      'unreadCounts.$myUid': 0,
    }, SetOptions(merge: true));

    final messages = await roomRef
        .collection('messages')
        .where('receiverId', isEqualTo: myUid)
        .limit(100)
        .get();

    if (messages.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in messages.docs) {
      final seenBy = List<String>.from(doc.data()['seenBy'] ?? const []);
      if (!seenBy.contains(myUid)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([myUid]),
        });
      }
    }

    await batch.commit();
  }

  Future<void> markGroupAsRead({
    required String groupId,
    required String myUid,
  }) async {
    final groupRef = _firestore.collection('chat_groups').doc(groupId);
    await groupRef.set({
      'unreadCounts.$myUid': 0,
    }, SetOptions(merge: true));
  }
}