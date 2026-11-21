import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> saveTextFile(
    String filename, String content, String mimeType) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(bytes, mimeType: mimeType, name: filename)],
    fileNameOverrides: [filename],
    subject: filename,
  ));
}
