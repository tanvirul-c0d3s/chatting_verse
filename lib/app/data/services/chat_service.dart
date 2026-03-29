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
        'lastMessageAt': FieldValue.serverTimestamp(),
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
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': [myUid],
    });

    await _firestore.collection('chat_rooms').doc(roomId).set({
      'roomId': roomId,
      'participants': [myUid, otherUid],
      'lastMessage': trimmed,
      'lastMessageType': 'text',
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendMedia({
    required String myUid,
    required String otherUid,
    required String fileUrl,
    required String fileName,
    required String type,
  }) async {
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
      'text': '',
      'fileUrl': fileUrl,
      'fileName': fileName,
      'thumbnailUrl': '',
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': [myUid],
    });

    await _firestore.collection('chat_rooms').doc(roomId).set({
      'roomId': roomId,
      'participants': [myUid, otherUid],
      'lastMessage': type.toUpperCase(),
      'lastMessageType': type,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}