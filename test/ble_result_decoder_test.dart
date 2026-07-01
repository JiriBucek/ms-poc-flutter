import 'package:flutter_test/flutter_test.dart';
import 'package:milksafe_flutter/features/bluetooth/data/ble_result_decoder.dart';
import 'package:milksafe_flutter/features/testing/domain/enums.dart';
import 'package:milksafe_flutter/features/testing/domain/test_type.dart';

/// Builds a MilkSafe-style test type (Height judge, reverse direction,
/// pos 0.9 / neg 1.1 — matching every entry in all-test-types-production.json).
TestType _milkSafeType({required String name, required int substanceCount}) {
  return TestType(
    id: name.hashCode,
    name: name,
    judgeType: JudgeType.height,
    judgingDirection: JudgingDirection.reverse,
    category: TestCategory.strip,
    positiveValue: 0.9,
    negativeValue: 1.1,
    substances: List.generate(
      substanceCount,
      (i) => TestTypeSubstance(id: i + 1, name: 'Substance $i', readerIndex: i),
    ),
  );
}

void main() {
  const decoder = BleResultDecoder();

  // These are the exact byte fixtures + expected outcomes from the iOS
  // BluetoothDataProcessorTests suite. If the Dart port drifts from the Swift
  // algorithm, one of these will fail.
  final cases = <({String name, int subs, List<int> bytes, SampleResult want})>[
    (
      name: 'MilkSafe™ 3BTC',
      subs: 4,
      want: SampleResult.positive,
      bytes: [1, 1, 0, 254, 1, 199, 0, 0, 0, 1, 244, 0, 5, 0, 0, 0, 2, 248, 0,
        170, 0, 0, 0, 3, 253, 0, 64, 0, 0, 0, 5, 13, 1, 90, 0, 0, 0, 92, 114, 92, 110],
    ),
    (
      name: 'MilkSafe™ 3BTC',
      subs: 4,
      want: SampleResult.negative,
      bytes: [1, 1, 0, 254, 0, 163, 0, 0, 0, 1, 247, 1, 65, 0, 0, 0, 3, 10, 1,
        53, 0, 0, 0, 4, 18, 1, 177, 0, 0, 0, 5, 12, 3, 173, 0, 0, 0, 92, 114, 92, 110],
    ),
    (
      name: 'MilkSafe™ 4BTSC',
      subs: 4,
      want: SampleResult.positive,
      bytes: [1, 1, 0, 233, 0, 203, 0, 0, 0, 1, 244, 0, 6, 0, 0, 0, 2, 222, 0,
        128, 0, 0, 0, 3, 235, 0, 84, 0, 0, 0, 5, 13, 1, 35, 0, 0, 0, 92, 114, 92, 110],
    ),
    (
      name: 'MilkSafe™ 4BTSC',
      subs: 4,
      want: SampleResult.negative,
      bytes: [1, 1, 0, 214, 0, 186, 0, 0, 0, 1, 221, 2, 20, 0, 0, 0, 2, 228, 3,
        72, 0, 0, 0, 3, 248, 1, 124, 0, 0, 0, 5, 9, 3, 87, 0, 0, 0, 92, 114, 92, 110],
    ),
    (
      name: 'MilkSafe™ 2BC',
      subs: 3,
      want: SampleResult.positive,
      bytes: [1, 1, 1, 181, 1, 153, 0, 0, 0, 2, 177, 0, 16, 0, 0, 0, 3, 211, 0,
        191, 0, 0, 0, 5, 13, 0, 215, 0, 0, 0, 92, 114, 92, 110],
    ),
  ];

  group('BleResultDecoder matches iOS BluetoothDataProcessor', () {
    for (final c in cases) {
      test('${c.name} → ${c.want.name}', () {
        final type = _milkSafeType(name: c.name, substanceCount: c.subs);
        final sample = decoder.decode(c.bytes, type);
        expect(sample, isNotNull, reason: 'decode returned null');
        expect(sample!.result, c.want);
        expect(sample.substances, isNotEmpty);
      });
    }
  });

  test('rejects an unreliable reading (control line too weak)', () {
    // Control height byte pair 0,40 → 40 (< minControlHeight 60).
    final type = _milkSafeType(name: 'MilkSafe™ 2BC', substanceCount: 3);
    final bytes = [1, 1, 0, 40, 0, 10, 0, 0, 0, 2, 177, 0, 16, 0, 0, 0, 3, 211,
      0, 191, 0, 0, 0, 5, 13, 0, 215, 0, 0, 0, 92, 114, 92, 110];
    expect(decoder.decode(bytes, type), isNull);
  });
}
