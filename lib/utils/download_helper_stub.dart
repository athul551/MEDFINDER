import 'dart:typed_data';

Future<void> downloadBytes(Uint8List bytes, String filename, String mimeType) async {
  // Not supported on this platform.
  throw UnsupportedError('Download not supported on this platform');
}
