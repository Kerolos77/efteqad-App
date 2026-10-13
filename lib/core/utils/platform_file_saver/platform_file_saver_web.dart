import 'dart:js_interop';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

Future<String?> saveAndShareFileImpl({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
  bool openFile = false,
}) async {
  final blobParts = [bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return fileName;
}

Future<Uint8List?> readPickedFileBytesImpl(dynamic file) async {
  if (file is PlatformFile) {
    return file.bytes;
  }
  return null;
}
