import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileBytes({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<String> uploadChatFileBytes({
    required String roomId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ext = p.extension(fileName);
    final safeName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = _storage.ref().child('chat_media/$roomId/$safeName');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }
}