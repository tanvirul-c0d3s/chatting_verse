import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadProfileBytes({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage
        .ref()
        .child('profile_images/$uid/${_uuid.v4()}.jpg');

    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadChatFileBytes({
    required String roomId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ext = p.extension(fileName).toLowerCase();
    final safeName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = _storage.ref().child('chat_media/$roomId/$safeName');

    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: _resolveContentType(ext)),
    );

    return await snapshot.ref.getDownloadURL();
  }

  String _resolveContentType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      default:
        return 'application/octet-stream';
    }
  }
}