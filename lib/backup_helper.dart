// backup_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:karsinta/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupHelper {
  // Vientitoiminto: tallennetaan tietokannan tiedot JSON-tiedostoon
  static Future<void> exportData() async {
    final db = await DatabaseHelper.instance.database;

    final stuff = await db.query('stuff');
    final categories = await db.query('categories');

    final data = {
      'stuff': stuff,
      'categories': categories,
    };

    final jsonString = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.json');

    await file.writeAsString(jsonString);
    debugPrint('Varmuuskopio tallennettu: ${file.path}');

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Tässä varmuuskopio sovelluksesta Simppeliksi!',
    );
  }

  //IMPORTDATA
  static Future<void> importData() async {
    debugPrint('importData() käynnistetty');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      debugPrint('Käyttäjä ei valinnut tiedostoa');
      return;
    }

    final filePath = result.files.single.path!;
    final file = File(filePath);

    try {
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      final db = await DatabaseHelper.instance.database;

      await db.delete('stuff');
      await db.delete('categories');

      for (var category in data['categories']) {
        await db.insert('categories', Map<String, dynamic>.from(category));
      }

      for (var item in data['stuff']) {
        await db.insert('stuff', Map<String, dynamic>.from(item));
      }

      debugPrint('Tiedot tuotu onnistuneesti');
    } catch (e) {
      debugPrint('Virhe tuonnissa: $e');
    }
  }
}
