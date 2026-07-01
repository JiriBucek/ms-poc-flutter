import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/test_sample.dart';

/// Local persistence for completed test records.
///
/// Mirrors the iOS approach: a JSON document in the app's documents directory.
/// The full app namespaces this per-user and layers a background syncer on top;
/// the PoC keeps a single local list, which the interface below can grow from.
class TestRecordRepository {
  const TestRecordRepository();

  static const _fileName = 'milksafe_test_samples.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// All stored samples, newest first.
  Future<List<TestSample>> loadAll() async {
    final file = await _file();
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TestSample.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt file — start clean rather than crash the app.
      return [];
    }
  }

  /// Prepends [sample] and persists the full list.
  Future<void> save(TestSample sample) async {
    final all = await loadAll();
    final updated = [sample, ...all];
    await _writeAll(updated);
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }

  Future<void> _writeAll(List<TestSample> samples) async {
    final file = await _file();
    final data = samples.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }
}
