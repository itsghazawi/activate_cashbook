import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'signer.dart';

/// Backups of the customers log.
class LogBackup {
  LogBackup._();

  static String _fileName() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'activate-backup-${n.year}-${two(n.month)}-${two(n.day)}.json';
  }

  static String encode(List<Activation> list) => jsonEncode({
        'app': 'activate',
        'exportedAt': DateTime.now().toIso8601String(),
        'history': list.map((e) => e.toJson()).toList(),
      });

  /// Opens the share sheet so the file can be saved in the Google Drive app.
  static Future<void> toDrive(List<Activation> list) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${_fileName()}');
    await f.writeAsString(encode(list));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(f.path, mimeType: 'application/json')],
      title: 'اختر Google Drive لحفظ النسخة',
      subject: 'نسخة سجل Activate',
    ));
  }

  /// Saves the file on the phone (user picks the folder). True if saved.
  static Future<bool> toPhone(List<Activation> list) async {
    final uri = await FilePicker.saveFile(
      fileName: _fileName(),
      bytes: Uint8List.fromList(utf8.encode(encode(list))),
      mimeType: 'application/json',
      dialogTitle: 'حفظ نسخة السجل',
    );
    return uri != null;
  }

  /// Picks a backup file and merges it into [current].
  /// Returns null if cancelled, or (merged list, number added). Throws on a bad file.
  static Future<(List<Activation>, int)?> pickAndMerge(List<Activation> current, {String title = 'اختر ملف نسخة السجل'}) async {
    final picked = await FilePicker.pickFile(dialogTitle: title);
    if (picked == null) return null;
    final j = jsonDecode(await picked.xFile.readAsString());
    if (j is! Map || j['app'] != 'activate') throw const FormatException('bad');
    final list = (j['history'] as List).map((e) => Activation.fromJson(Map<String, dynamic>.from(e))).toList();
    final have = current.map((e) => e.device).toSet();
    final added = list.where((e) => !have.contains(e.device)).toList();
    final merged = [...current, ...added]..sort((a, b) => b.at.compareTo(a.at));
    return (merged, added.length);
  }
}
