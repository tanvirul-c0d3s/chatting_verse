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

  Stream<QuerySnapshot<Map<String, dynamic>>> roomsStream(String myUid) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
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
      'unreadCounts.$otherUid': FieldValue.increment(1),
      'unreadCounts.$myUid': 0,
    }, SetOptions(merge: true));
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
}