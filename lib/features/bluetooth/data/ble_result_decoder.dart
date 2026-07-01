import 'dart:convert';

import '../../../core/utils/byte_utils.dart';
import '../../testing/domain/enums.dart';
import '../../testing/domain/test_sample.dart';
import '../../testing/domain/test_type.dart';
import '../domain/ble_constants.dart';

/// Context data attached to a decoded sample that doesn't come from the reader.
class DecodeContext {
  const DecodeContext({
    this.deviceName,
    this.operatorId,
    this.route,
    this.username,
    this.appVersion,
    this.localGroupId,
  });

  final String? deviceName;
  final String? operatorId;
  final String? route;
  final String? username;
  final String? appVersion;
  final String? localGroupId;
}

class _RawItem {
  _RawItem(this.position, this.height, this.area);
  final int position;
  final int height;
  final int area;
  String value = '';
  SampleResultSubstance? item;
  SampleResult? result;
}

/// Turns raw reader bytes into a [TestSample]. A faithful, self-contained port
/// of the iOS `BluetoothDataProcessor` — no I/O, no Bluetooth, no Flutter, so
/// it can be unit-tested against the same fixtures the iOS suite uses.
class BleResultDecoder {
  const BleResultDecoder();

  /// Decodes [data] for [testType]. Returns `null` when the reading is
  /// unreliable (control line too weak) or malformed.
  TestSample? decode(
    List<int> data,
    TestType testType, {
    DecodeContext context = const DecodeContext(),
  }) {
    if (testType.measurementMethod == MeasurementMethod.quantitative) {
      return _decodeQuantitative(data, testType, context);
    }
    return _decodeQualitative(data, testType, context);
  }

  // MARK: - Qualitative

  TestSample? _decodeQualitative(
    List<int> data,
    TestType testType,
    DecodeContext ctx,
  ) {
    final parsed = _parseRaw(data);
    if (parsed == null || parsed.isEmpty) return null;

    // First set is the control line; the rest are substance lines.
    final control = parsed.removeAt(0);
    if (control.height < BleConstants.minControlHeight) {
      return null; // unreliable reading
    }

    var total = SampleResult.negative;
    final sorted = testType.sortedSubstances;

    for (var i = 0; i < parsed.length; i++) {
      final item = parsed[i];

      var compare = switch (testType.judgeType) {
        JudgeType.area => item.area / control.area,
        JudgeType.height => item.height / control.height,
      };
      compare = compare > 5.0 ? 5.0 : compare;
      compare = (compare * 100).roundToDouble() / 100;
      item.value = compare.toStringAsFixed(2);

      final itemIndex = sorted.length - i - 1;
      if (i >= sorted.length) break;
      final substance = sorted[itemIndex];
      item.item = SampleResultSubstance(id: substance.id, name: substance.name);

      final result = _classify(
        testType.judgingDirection,
        compare,
        testType.positiveValue,
        testType.negativeValue,
      );
      item.result = result;

      if (result == SampleResult.weakPositive && total == SampleResult.negative) {
        total = SampleResult.weakPositive;
      } else if (result == SampleResult.positive) {
        total = SampleResult.positive;
      }
    }

    return _buildSample(
      rawData: data,
      total: total,
      items: _sampleItems(parsed),
      testType: testType,
      ctx: ctx,
    );
  }

  List<_RawItem>? _parseRaw(List<int> data) {
    const length = BleConstants.testResultStandardLength;
    if (data.length < 6) return null;

    // Strip command + status (2) and the 4 trailing control bytes.
    final valuesData = data.sublist(2, data.length - 4);
    final amountOfSets = data.length ~/ length;
    final result = <_RawItem>[];

    for (var i = 0; i < amountOfSets; i++) {
      if ((i * length) + length > valuesData.length) return null;
      final set = valuesData.sublist(i * length, i * length + length);
      result.add(_RawItem(
        uint16BE(set, 0), // position
        uint16BE(set, 2), // height
        uint16BE(set, 4), // area
      ));
    }
    return result;
  }

  SampleResult _classify(
    JudgingDirection direction,
    double compare,
    double positive,
    double negative,
  ) {
    final hasWeakBand = positive != negative;
    if (direction == JudgingDirection.positive) {
      if (compare > positive) return SampleResult.positive;
      if (hasWeakBand && compare > negative) return SampleResult.weakPositive;
      return SampleResult.negative;
    } else {
      if (compare < positive) return SampleResult.positive;
      if (hasWeakBand && compare <= negative) return SampleResult.weakPositive;
      return SampleResult.negative;
    }
  }

  List<SampleResultItem> _sampleItems(List<_RawItem> raw) {
    final out = <SampleResultItem>[];
    for (final r in raw) {
      final substance = r.item;
      final result = r.result;
      if (substance != null && result != null && r.value.isNotEmpty) {
        out.add(SampleResultItem(
          substance: substance,
          level: r.value,
          result: result,
        ));
      }
    }
    return out.reversed.toList();
  }

  // MARK: - Quantitative

  TestSample? _decodeQuantitative(
    List<int> data,
    TestType testType,
    DecodeContext ctx,
  ) {
    final range = testType.quantitativeRange;
    final firstSubstance = testType.sortedSubstances.firstOrNull;
    if (range == null || firstSubstance == null || data.length < 32) return null;

    final text = utf8.decode(data, allowMalformed: true);
    final parts = text.split('#');
    if (parts.length > 4 && parts[4] == 'Invalid') return null;
    final testValue = parts.length > 2 ? double.tryParse(parts[2]) : null;
    if (testValue == null) return null;

    SampleResult total;
    if (testValue >= range.measurableRangeMin && testValue <= range.measurableRangeMax) {
      total = (testValue >= range.negativeRangeMin && testValue <= range.negativeRangeMax)
          ? SampleResult.negative
          : SampleResult.positive;
    } else if (testValue < range.negativeRangeMin) {
      total = SampleResult.negative;
    } else {
      total = SampleResult.positive;
    }

    final item = SampleResultItem(
      substance:
          SampleResultSubstance(id: firstSubstance.id, name: firstSubstance.name),
      level: testValue.toString(),
      result: total,
    );

    return _buildSample(
      rawData: data,
      total: total,
      items: [item],
      testType: testType,
      ctx: ctx,
    );
  }

  // MARK: - Shared

  TestSample _buildSample({
    required List<int> rawData,
    required SampleResult total,
    required List<SampleResultItem> items,
    required TestType testType,
    required DecodeContext ctx,
  }) {
    return TestSample(
      localId: DateTime.now().millisecondsSinceEpoch,
      result: total,
      testType: SampleTestType.fromTestType(testType),
      testDate: DateTime.now(),
      substances: items,
      readerData: rawData,
      readerSerialNumber: ctx.deviceName,
      operatorId: ctx.operatorId,
      route: ctx.route,
      username: ctx.username,
      appVersion: ctx.appVersion,
      testCategory: testType.category,
      localGroupId: ctx.localGroupId,
    );
  }
}
