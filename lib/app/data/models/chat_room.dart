import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String roomId;
  final List<dynamic> participants;
  final String lastMessage;
  final String lastMessageType;
  final Timestamp? lastMessageAt;

  ChatRoom({
    required this.roomId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageType,
    this.lastMessageAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      roomId: map['roomId'] ?? '',
      participants: map['participants'] ?? [],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: map['lastMessageType'] ?? 'text',
      lastMessageAt: map['lastMessageAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageAt': lastMessageAt,
    };
  }
}