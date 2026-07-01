/// Shared value enums for the testing domain. Ported from the iOS domain layer.
library;

/// Overall / per-substance outcome of a test. Raw values match the iOS
/// `SampleResult` JSON encoding so persisted records stay compatible.
enum SampleResult {
  none('None'),
  positive('Positive'),
  negative('Negative'),
  weakPositive('WeakPositive');

  const SampleResult(this.raw);
  final String raw;

  static SampleResult fromRaw(String? raw) => SampleResult.values.firstWhere(
        (e) => e.raw == raw,
        orElse: () => SampleResult.none,
      );
}

/// Physical form of the test consumable.
enum TestCategory {
  strip(0),
  cassette(1);

  const TestCategory(this.code);
  final int code;

  static TestCategory fromCode(int? code) =>
      code == 1 ? TestCategory.cassette : TestCategory.strip;
}

/// Which reader-measured dimension is compared against the control line.
enum JudgeType {
  area('Area'),
  height('Height');

  const JudgeType(this.raw);
  final String raw;

  static JudgeType fromRaw(String? raw) =>
      raw == 'Area' ? JudgeType.area : JudgeType.height;
}

/// Direction of the positive/negative threshold comparison.
enum JudgingDirection {
  positive('PositiveJudgement'),
  reverse('ReverseJudgement');

  const JudgingDirection(this.raw);
  final String raw;

  static JudgingDirection fromRaw(String? raw) => raw == 'PositiveJudgement'
      ? JudgingDirection.positive
      : JudgingDirection.reverse;
}

/// Qualitative (line intensity) vs quantitative (numeric payload) tests.
enum MeasurementMethod {
  qualitative,
  quantitative;

  static MeasurementMethod fromRaw(String? raw) =>
      raw == 'Quantitative' ? quantitative : qualitative;
}

/// The families of hardware readers, detected from the advertised BLE name.
enum SupportedReaderType {
  truckReader,
  portableReader,
  portableReaderConnect;

  /// Mirrors iOS `BTDevice.getReaderType(from:)`.
  static SupportedReaderType fromDeviceName(String? name) {
    final n = name ?? '';
    if (n.startsWith('PRC')) return SupportedReaderType.portableReaderConnect;
    if (n.startsWith('PR')) return SupportedReaderType.portableReader;
    if (n.contains('TR') || n.contains('Helmen')) {
      return SupportedReaderType.truckReader;
    }
    if (n.startsWith('MS-H0')) return SupportedReaderType.portableReaderConnect;
    return SupportedReaderType.portableReader;
  }
}
