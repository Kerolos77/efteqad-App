import 'dart:typed_data';

Future<String?> saveAndShareFileImpl({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
  bool openFile = false,
}) {
  throw UnsupportedError('Cannot save file without platform implementation');
}

Future<Uint8List?> readPickedFileBytesImpl(dynamic file) {
  throw UnsupportedError('Cannot read file without platform implementation');
}
