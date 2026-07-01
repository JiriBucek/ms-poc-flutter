import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/test_type.dart';

/// Loads the catalogue of test types. For the PoC these ship as a bundled asset
/// (the same `all-test-types-production.json` the iOS app bundles). In the full
/// app this layer also fetches/caches site-specific configs from the backend.
class TestTypeRepository {
  const TestTypeRepository();

  static const _assetPath = 'assets/test_types.json';

  Future<List<TestType>> loadTestTypes() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    final types = data.map(TestType.fromJson).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return types;
  }
}
