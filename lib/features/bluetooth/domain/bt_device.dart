import 'package:equatable/equatable.dart';

import '../../testing/domain/enums.dart';

/// A reader peripheral, decoupled from any specific BLE library. The data layer
/// maps platform peripherals into this; the rest of the app only sees this.
class BtDevice extends Equatable {
  BtDevice({
    required this.id,
    required String name,
    required this.readerType,
    this.rssi,
  }) : name = _cleanName(name);

  /// Stable platform identifier for the peripheral (remoteId).
  final String id;
  final String name;
  final SupportedReaderType readerType;
  final int? rssi;

  static String _cleanName(String name) => name.replaceAll('(BT)', '').trim();

  /// Builds from a raw advertised name, inferring the reader family.
  factory BtDevice.fromAdvertisement({
    required String id,
    required String name,
    int? rssi,
  }) =>
      BtDevice(
        id: id,
        name: name,
        readerType: SupportedReaderType.fromDeviceName(name),
        rssi: rssi,
      );

  @override
  List<Object?> get props => [id, name, readerType];
}
