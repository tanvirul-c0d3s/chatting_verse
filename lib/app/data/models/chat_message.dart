import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String fileUrl;
  final String fileName;
  final String thumbnailUrl;
  final String type;
  final Timestamp? createdAt;
  final List<dynamic> seenBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.fileUrl,
    required this.fileName,
    required this.thumbnailUrl,
    required this.type,
    this.createdAt,
    required this.seenBy,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: map['createdAt'],
      seenBy: map['seenBy'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'thumbnailUrl': thumbnailUrl,
      'type': type,
      'createdAt': createdAt,
      'seenBy': seenBy,
    };
  }
}