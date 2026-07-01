/// Low-level byte helpers shared across the Bluetooth layer.
///
/// Ported from the iOS `Array<UInt8>` extensions (`shortValue`, hex printing).
library;

/// Big-endian unsigned 16-bit value from the two bytes at [offset].
///
/// Mirrors the iOS `shortValue()` extension: `(b0 << 8) + b1`.
int uint16BE(List<int> bytes, [int offset = 0]) {
  return ((bytes[offset] & 0xFF) << 8) + (bytes[offset + 1] & 0xFF);
}

/// Uppercase hex string of a byte list, e.g. `01 1A FF`. Used for debug logs.
String hexString(List<int> bytes) {
  return bytes
      .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}

/// Splits [bytes] into chunks of at most [size] elements.
List<List<int>> chunked(List<int> bytes, int size) {
  final out = <List<int>>[];
  for (var i = 0; i < bytes.length; i += size) {
    out.add(bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size));
  }
  return out;
}
