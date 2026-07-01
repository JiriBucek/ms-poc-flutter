import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A single antibiotic/substance a test line reports on.
class TestTypeSubstance extends Equatable {
  const TestTypeSubstance({
    required this.id,
    required this.name,
    required this.readerIndex,
  });

  final int id;
  final String name;

  /// Order in which the reader emits this substance's line.
  final int readerIndex;

  factory TestTypeSubstance.fromJson(Map<String, dynamic> json) {
    final substance = json['substance'] as Map<String, dynamic>;
    return TestTypeSubstance(
      id: substance['id'] as int,
      name: substance['name'] as String,
      readerIndex: json['readerIndex'] as int,
    );
  }

  @override
  List<Object?> get props => [id, name, readerIndex];
}

/// Numeric acceptance bands for a quantitative test.
class QuantitativeRange extends Equatable {
  const QuantitativeRange({
    required this.measurableRangeMin,
    required this.measurableRangeMax,
    required this.negativeRangeMin,
    required this.negativeRangeMax,
  });

  final double measurableRangeMin;
  final double measurableRangeMax;
  final double negativeRangeMin;
  final double negativeRangeMax;

  factory QuantitativeRange.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num).toDouble();
    return QuantitativeRange(
      measurableRangeMin: d('measurableRangeMin'),
      measurableRangeMax: d('measurableRangeMax'),
      negativeRangeMin: d('negativeRangeMin'),
      negativeRangeMax: d('negativeRangeMax'),
    );
  }

  @override
  List<Object?> get props =>
      [measurableRangeMin, measurableRangeMax, negativeRangeMin, negativeRangeMax];
}

/// A kind of test the reader can run (e.g. "MilkSafe™ 4BTSC"), including the
/// thresholds and substances used to interpret the raw reading.
///
/// Ported from iOS `TestType`.
class TestType extends Equatable {
  const TestType({
    required this.id,
    required this.name,
    required this.judgeType,
    required this.judgingDirection,
    required this.category,
    required this.positiveValue,
    required this.negativeValue,
    required this.substances,
    this.measurementMethod = MeasurementMethod.qualitative,
    this.temperature,
    this.incubationTime,
    this.quantitativeRange,
  });

  final int id;
  final String name;
  final JudgeType judgeType;
  final JudgingDirection judgingDirection;
  final TestCategory category;
  final double positiveValue;
  final double negativeValue;
  final List<TestTypeSubstance> substances;
  final MeasurementMethod measurementMethod;
  final double? temperature;
  final int? incubationTime;
  final QuantitativeRange? quantitativeRange;

  /// Number of test lines the reader should measure.
  int get testCount => substances.length;

  /// Substances ordered by the reader's emission order.
  List<TestTypeSubstance> get sortedSubstances {
    final copy = [...substances]..sort((a, b) => a.readerIndex.compareTo(b.readerIndex));
    return copy;
  }

  factory TestType.fromJson(Map<String, dynamic> json) {
    final substances = (json['substances'] as List<dynamic>? ?? [])
        .map((e) => TestTypeSubstance.fromJson(e as Map<String, dynamic>))
        .toList();
    return TestType(
      id: json['id'] as int,
      name: json['name'] as String,
      judgeType: JudgeType.fromRaw(json['judgeType'] as String?),
      judgingDirection: JudgingDirection.fromRaw(json['judgingDirection'] as String?),
      category: TestCategory.fromCode((json['category'] as num?)?.toInt()),
      positiveValue: (json['positiveValue'] as num).toDouble(),
      negativeValue: (json['negativeValue'] as num).toDouble(),
      substances: substances,
      measurementMethod: MeasurementMethod.fromRaw(json['measurementMethod'] as String?),
      temperature: (json['temperature'] as num?)?.toDouble(),
      incubationTime: (json['incubationTime'] as num?)?.toInt(),
      quantitativeRange: json['quantitativeRange'] == null
          ? null
          : QuantitativeRange.fromJson(json['quantitativeRange'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [id, name, substances];
}
