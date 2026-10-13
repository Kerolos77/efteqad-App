import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveAndShareFileImpl({
  required Uint8List bytes,
  required String fileName,
  String? shareText,
  bool openFile = false,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes);

  if (openFile) {
    try {
      await OpenFilex.open(file.path);
    } catch (_) {}
  }

  await Share.shareXFiles(
    [XFile(file.path)],
    text: shareText,
  );

  return file.path;
}

Future<Uint8List?> readPickedFileBytesImpl(dynamic file) async {
  if (file is PlatformFile) {
    if (file.bytes != null) return file.bytes;
    if (file.path != null) {
      return await File(file.path!).readAsBytes();
    }
  }
  return null;
}
