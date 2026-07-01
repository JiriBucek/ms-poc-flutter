import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'test_type.dart';

/// A substance identity carried on a result item.
class SampleResultSubstance extends Equatable {
  const SampleResultSubstance({required this.id, required this.name});
  final int id;
  final String name;

  factory SampleResultSubstance.fromJson(Map<String, dynamic> j) =>
      SampleResultSubstance(id: j['id'] as int, name: j['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  List<Object?> get props => [id, name];
}

/// Per-substance outcome within a sample.
class SampleResultItem extends Equatable {
  const SampleResultItem({
    required this.substance,
    required this.level,
    required this.result,
  });

  final SampleResultSubstance substance;

  /// Comparison value vs the control line, formatted "%.2f" (matches iOS).
  final String level;
  final SampleResult result;

  factory SampleResultItem.fromJson(Map<String, dynamic> j) => SampleResultItem(
        substance:
            SampleResultSubstance.fromJson(j['substance'] as Map<String, dynamic>),
        level: j['level'] as String,
        result: SampleResult.fromRaw(j['result'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'substance': substance.toJson(),
        'level': level,
        'result': result.raw,
      };

  @override
  List<Object?> get props => [substance, level, result];
}

/// Snapshot of the test type stored on a sample.
class SampleTestType extends Equatable {
  const SampleTestType({
    required this.id,
    required this.name,
    required this.category,
  });

  final int id;
  final String name;
  final TestCategory category;

  factory SampleTestType.fromTestType(TestType t) =>
      SampleTestType(id: t.id, name: t.name, category: t.category);

  factory SampleTestType.fromJson(Map<String, dynamic> j) => SampleTestType(
        id: j['id'] as int,
        name: j['name'] as String,
        category: TestCategory.fromCode((j['category'] as num?)?.toInt()),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'category': category.code};

  @override
  List<Object?> get props => [id, name, category];
}

/// A completed milk test — the primary record persisted locally and later
/// synced. Ported from iOS `TestSample`. Fields not needed for the PoC vertical
/// slice are kept optional so the full model can grow into this class.
class TestSample extends Equatable {
  const TestSample({
    required this.localId,
    required this.result,
    required this.testType,
    required this.testDate,
    required this.substances,
    this.id,
    this.readerData,
    this.readerSerialNumber,
    this.operatorId,
    this.route,
    this.username,
    this.appVersion,
    this.testCategory,
    this.localGroupId,
    this.batchNumber,
  });

  final int? id; // remote id (assigned by backend)
  final int? localId; // Date().millisecondsSinceEpoch based
  final SampleResult result;
  final SampleTestType testType;
  final DateTime testDate;
  final List<SampleResultItem> substances;
  final List<int>? readerData; // raw assembled reader bytes
  final String? readerSerialNumber;
  final String? operatorId;
  final String? route;
  final String? username;
  final String? appVersion;
  final TestCategory? testCategory;
  final String? localGroupId;
  final String? batchNumber;

  factory TestSample.fromJson(Map<String, dynamic> j) => TestSample(
        id: j['id'] as int?,
        localId: j['localId'] as int?,
        result: SampleResult.fromRaw(j['result'] as String?),
        testType:
            SampleTestType.fromJson(j['testType'] as Map<String, dynamic>),
        testDate: DateTime.parse(j['testDate'] as String),
        substances: (j['substances'] as List<dynamic>? ?? [])
            .map((e) => SampleResultItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        readerData: (j['readerData'] as List<dynamic>?)?.cast<int>(),
        readerSerialNumber: j['readerSerialNumber'] as String?,
        operatorId: j['operatorId'] as String?,
        route: j['route'] as String?,
        username: j['username'] as String?,
        appVersion: j['appVersion'] as String?,
        testCategory: j['testCategory'] == null
            ? null
            : TestCategory.fromCode((j['testCategory'] as num).toInt()),
        localGroupId: j['localGroupId'] as String?,
        batchNumber: j['batchNumber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'localId': localId,
        'result': result.raw,
        'testType': testType.toJson(),
        'testDate': testDate.toIso8601String(),
        'substances': substances.map((e) => e.toJson()).toList(),
        'readerData': readerData,
        'readerSerialNumber': readerSerialNumber,
        'operatorId': operatorId,
        'route': route,
        'username': username,
        'appVersion': appVersion,
        'testCategory': testCategory?.code,
        'localGroupId': localGroupId,
        'batchNumber': batchNumber,
      };

  @override
  List<Object?> get props => [localId, result, testType, testDate, substances];
}
