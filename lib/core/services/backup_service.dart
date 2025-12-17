import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/app_database.dart';

class BackupEntry {
  const BackupEntry({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String name;
  final String path;
  final DateTime createdAt;
  final int sizeBytes;

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$sizeBytes B';
  }
}

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  Future<BackupEntry> createBackup({String? label}) async {
    final dbPath = await _database.databasePath;
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('database_missing');
    }

    final backupDirectory = await _ensureBackupDirectory();
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileLabel = _sanitizeLabel(label);
    final baseName = (fileLabel?.isNotEmpty ?? false)
        ? fileLabel!
        : 'backup';
    final backupPath = join(backupDirectory.path, '${baseName}_$timeStamp.db');
    final backupFile = await dbFile.copy(backupPath);
    final stat = await backupFile.stat();

    return BackupEntry(
      name: basename(backupFile.path),
      path: backupFile.path,
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<List<BackupEntry>> listBackups() async {
    final directory = await _ensureBackupDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => extension(file.path) == '.db')
        .toList();

    final entries = <BackupEntry>[];
    for (final file in files) {
      final stat = await file.stat();
      entries.add(
        BackupEntry(
          name: basename(file.path),
          path: file.path,
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> importBackup(String filePath) async {
    final backupFile = File(filePath);
    if (!await backupFile.exists()) {
      throw Exception('backup_missing');
    }
    final dbPath = await _database.databasePath;
    await _database.closeDatabase();
    await backupFile.copy(dbPath);
    await _database.reopenDatabase();
  }

  Future<Directory> _ensureBackupDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(join(documents.path, 'backups'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<bool> deleteBackup(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String? _sanitizeLabel(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    final cleaned = trimmed.replaceAll(invalidChars, '').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.replaceAll(RegExp(r'\s+'), '_');
  }
}
