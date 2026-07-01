import 'dart:typed_data';

import '../../testing/domain/enums.dart';
import '../../testing/domain/test_type.dart';

/// Commands written to the reader's input characteristic.
///
/// Ported from iOS `BMCommand`. Each command knows its command byte and how to
/// serialise itself to the exact wire format the firmware expects.
sealed class BleCommand {
  const BleCommand();

  /// The leading command byte (also used to classify the response).
  int get commandByte;

  /// The full payload written to the characteristic.
  Uint8List get data;

  const factory BleCommand.powerStatus() = _PowerStatus;
  const factory BleCommand.truckReaderStatus() = _TruckReaderStatus;
  factory BleCommand.setTemperature(double celsius) = _SetTemperature;
  factory BleCommand.runTest(RunTestConfig config) = _RunTest;
  factory BleCommand.runQuantitativeTest(RunTestConfig config) =
      _RunQuantitativeTest;
}

/// Parameters for a run-test command.
class RunTestConfig {
  const RunTestConfig({
    required this.numberOfLines,
    this.cassetteType,
    this.quantitativePayload,
  });

  final int numberOfLines;

  /// Only sent to the truck reader; portable readers ignore/omit it.
  final TestCategory? cassetteType;
  final String? quantitativePayload;

  /// Builds the config appropriate for [testType] on [readerType].
  factory RunTestConfig.forTest(
    TestType testType,
    SupportedReaderType readerType, {
    String? payload,
  }) {
    TestCategory? cassetteType;
    if (readerType == SupportedReaderType.truckReader ||
        readerType == SupportedReaderType.portableReaderConnect) {
      cassetteType = testType.category;
    }
    return RunTestConfig(
      numberOfLines: testType.testCount,
      cassetteType: cassetteType,
      quantitativePayload: payload,
    );
  }
}

class _PowerStatus extends BleCommand {
  const _PowerStatus();
  @override
  int get commandByte => 0x26;
  @override
  Uint8List get data => Uint8List.fromList([commandByte]);
}

class _TruckReaderStatus extends BleCommand {
  const _TruckReaderStatus();
  @override
  int get commandByte => 0x31;
  @override
  Uint8List get data => Uint8List.fromList([commandByte]);
}

class _SetTemperature extends BleCommand {
  const _SetTemperature(this.celsius);
  final double celsius;
  @override
  int get commandByte => 0x30;
  @override
  Uint8List get data {
    // Temp is transmitted x10 (37.5°C -> 375), high byte first.
    final t = (celsius * 10).round();
    return Uint8List.fromList([
      commandByte,
      0x01,
      (t >> 8) & 0xFF,
      t & 0xFF,
    ]);
  }
}

class _RunTest extends BleCommand {
  const _RunTest(this.config);
  final RunTestConfig config;
  @override
  int get commandByte => 0x01;
  @override
  Uint8List get data {
    final bytes = <int>[commandByte, config.numberOfLines & 0xFF];
    switch (config.cassetteType) {
      case TestCategory.cassette:
        bytes.add(0x01);
      case TestCategory.strip:
        bytes.add(0x02);
      case null:
        break;
    }
    return Uint8List.fromList(bytes);
  }
}

class _RunQuantitativeTest extends BleCommand {
  const _RunQuantitativeTest(this.config);
  final RunTestConfig config;
  @override
  int get commandByte => 0x02;
  @override
  Uint8List get data {
    final payload = config.quantitativePayload;
    if (payload == null) return Uint8List(0);
    return Uint8List.fromList([commandByte, ...payload.codeUnits]);
  }
}
