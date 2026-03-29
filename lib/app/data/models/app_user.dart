import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String address;
  final String email;
  final String photoUrl;
  final bool isOnline;
  final String fcmToken;
  final String appId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastSeen;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.address,
    required this.email,
    required this.photoUrl,
    required this.isOnline,
    required this.fcmToken,
    required this.appId,
    this.createdAt,
    this.updatedAt,
    this.lastSeen,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      fcmToken: map['fcmToken'] ?? '',
      appId: map['appId'] ?? '',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      lastSeen: map['lastSeen'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'address': address,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'appId': appId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
    };
  }
}