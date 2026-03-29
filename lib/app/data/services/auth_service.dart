import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String currentAppId = 'chat_verse';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authChanges() {
    return _auth.authStateChanges();
  }

  Future<UserCredential> register({
    required String fullName,
    required String address,
    required String email,
    required String password,
    required String photoUrl,
    required String fcmToken,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'address': address,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': true,
      'fcmToken': fcmToken,
      'appId': currentAppId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'appId': currentAppId,
    });

    return credential;
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;

    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }

    await _auth.signOut();
  }

  Stream<AppUser> getMyProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => AppUser.fromMap(doc.data() ?? {}),
    );
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String address,
    required String photoUrl,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'address': address,
      'photoUrl': photoUrl,
      'appId': currentAppId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppUser>> allUsersExceptMe(String myUid) {
    return _firestore
        .collection('users')
        .where('appId', isEqualTo: currentAppId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((e) => AppUser.fromMap(e.data()))
          .where((user) => user.uid != myUid)
          .toList(),
    );
  }

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) return null;

    return AppUser.fromMap(doc.data()!);
  }
}