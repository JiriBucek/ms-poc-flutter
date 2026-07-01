import 'ble_constants.dart';

/// Classification of a response frame from the reader, keyed on its first byte.
/// Ported from iOS `BMOutput`.
enum BleOutputKind {
  powerStatus,
  testResult,
  updateStarted,
  setTemperature,
  readerStatus,
  prepareForFirmwareUpdate,
  updateFirmware,
  noResponse,
  responseUnknown;

  static BleOutputKind classify(List<int>? value) {
    if (value == null || value.isEmpty) return BleOutputKind.noResponse;
    switch (value[0]) {
      case 0x26:
        return BleOutputKind.powerStatus;
      case 0x01:
      case 0x02:
        return BleOutputKind.testResult;
      case 0x22:
        return BleOutputKind.updateStarted;
      case 0x30:
        return BleOutputKind.setTemperature;
      case 0x31:
        return BleOutputKind.readerStatus;
      case 0x34:
        return BleOutputKind.prepareForFirmwareUpdate;
      case 0x35:
        return BleOutputKind.updateFirmware;
      default:
        return BleOutputKind.responseUnknown;
    }
  }

  /// Status byte (index 1) is non-zero on success for most commands.
  static bool isSuccessStatus(List<int>? value) {
    if (value == null || value.length < 2) return false;
    return value[1] != 0x00;
  }
}

/// Failure classification for a test-result frame. Ported from iOS
/// `BMTestResultError`.
enum BleTestResultError {
  failure,
  reserve,
  pollute,
  invalid,
  other;

  static BleTestResultError classify(List<int>? bytes) {
    if (bytes == null || bytes.length < 2) return BleTestResultError.other;
    switch (bytes[1]) {
      case 0x00:
        return BleTestResultError.failure;
      case 0x02:
        return BleTestResultError.reserve;
      case 0x03:
        return BleTestResultError.pollute;
      case 0x04:
        return BleTestResultError.invalid;
      default:
        return BleTestResultError.other;
    }
  }
}

/// True once [buffer] ends with the terminator sequence — i.e. the last packet
/// of a multi-part response has arrived.
bool isCompleteResponse(List<int> buffer) {
  if (buffer.length < 4) return false;
  final tail = buffer.sublist(buffer.length - 4);
  for (var i = 0; i < 4; i++) {
    if (tail[i] != BleConstants.endResponseBytes[i]) return false;
  }
  return true;
}
