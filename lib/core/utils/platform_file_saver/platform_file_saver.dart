import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import 'platform_file_saver_stub.dart'
    if (dart.library.io) 'platform_file_saver_io.dart'
    if (dart.library.js_interop) 'platform_file_saver_web.dart';

class PlatformFileSaver {
  const PlatformFileSaver._();

  /// Saves bytes as a file and shares/downloads it appropriately for the platform.
  static Future<String?> saveAndShareFile({
    required Uint8List bytes,
    required String fileName,
    String? shareText,
    bool openFile = false,
  }) {
    return saveAndShareFileImpl(
      bytes: bytes,
      fileName: fileName,
      shareText: shareText,
      openFile: openFile,
    );
  }

  /// Saves bytes as a file and downloads or saves it to disk.
  static Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    return saveAndShareFileImpl(
      bytes: bytes,
      fileName: fileName,
    );
  }

  /// Reads bytes from a picked [PlatformFile] on either Web or Mobile.
  static Future<Uint8List?> readPickedFileBytes(PlatformFile file) {
    return readPickedFileBytesImpl(file);
  }
}
