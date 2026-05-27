import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadPrescription({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('prescriptions/$userId/$timestamp.jpg');
    final metadata = SettableMetadata(contentType: contentType);
    return _uploadWithRetries(ref, bytes, metadata, onProgress: onProgress);
  }

  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('profile_images/$userId/$timestamp.jpg');
    final metadata = SettableMetadata(contentType: contentType);
    return _uploadWithRetries(ref, bytes, metadata, onProgress: onProgress);
  }

  Future<String> _uploadWithRetries(
    Reference ref,
    Uint8List bytes,
    SettableMetadata metadata, {
    void Function(double progress)? onProgress,
  }) async {
    final timeouts = [
      const Duration(seconds: 30),
      const Duration(seconds: 60),
      const Duration(seconds: 120),
    ];

    for (var attempt = 0; attempt < timeouts.length; attempt++) {
      try {
        final task = ref.putData(bytes, metadata);
        StreamSubscription<TaskSnapshot>? sub;
        if (onProgress != null) {
          sub = task.snapshotEvents.listen((s) {
            if (s.totalBytes > 0) {
              try {
                onProgress(s.bytesTransferred / s.totalBytes);
              } catch (_) {}
            }
          });
        }

        final snapshot = await task.timeout(
          timeouts[attempt],
          onTimeout: () => throw Exception('Upload timed out'),
        );

        await sub?.cancel();
        return snapshot.ref.getDownloadURL();
      } catch (e) {
        if (attempt == timeouts.length - 1) rethrow;
        // backoff before retrying
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
      }
    }
    throw Exception('Upload failed');
  }
}
