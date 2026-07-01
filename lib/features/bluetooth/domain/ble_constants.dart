/// GATT service/characteristic UUIDs and framing constants for the MilkSafe
/// reader. Ported verbatim from the iOS `Constants.swift`.
library;

class BleConstants {
  BleConstants._();

  /// Services advertised by supported readers — passed to the scanner filter.
  static const List<String> serviceUuids = [
    '00001000-0000-1000-8000-00805f9b34fb', // portable reader
    '0000a002-0000-1000-8000-00805f9b34fb', // truck reader
  ];

  // Portable reader (PR / PRC / MS-H0)
  static const String primaryServicePortable =
      '00001000-0000-1000-8000-00805f9b34fb';
  static const String inputCharPortable =
      '00001001-0000-1000-8000-00805f9b34fb';
  static const String outputCharPortable =
      '00001002-0000-1000-8000-00805f9b34fb';

  // Truck reader (TR / Helmen)
  static const String primaryServiceTruck =
      '0000a002-0000-1000-8000-00805f9b34fb';
  static const String inputCharTruck = '0000c303-0000-1000-8000-00805f9b34fb';
  static const String outputCharTruck = '0000c305-0000-1000-8000-00805f9b34fb';

  /// Marks the final packet of a multi-part response. ASCII for the literal
  /// text `\r\n` (i.e. backslash-r-backslash-n), not the control characters.
  static const List<int> endResponseBytes = [0x5C, 0x72, 0x5C, 0x6E];

  /// Bytes per parsed result "set": position(2) + height(2) + area(2) + pad(1).
  static const int testResultStandardLength = 7;

  /// A control-line intensity below this makes the whole reading unreliable.
  static const int minControlHeight = 60;
}
