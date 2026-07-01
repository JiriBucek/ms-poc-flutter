import 'dart:async';
import 'dart:math';

import '../../testing/domain/enums.dart';
import '../../testing/domain/test_type.dart';
import '../domain/bt_device.dart';
import '../domain/reader_repository.dart';

/// In-memory [ReaderRepository] for running the app without hardware (desktop,
/// simulator, widget tests). It returns byte frames captured from real readers
/// (the same fixtures the iOS unit tests use), so the decode path is exercised
/// for real — only the transport is faked.
class FakeReader implements ReaderRepository {
  final _connectionController =
      StreamController<ReaderConnectionState>.broadcast();
  BtDevice? _connectedDevice;

  /// Real captured frames — index 0 is used as a "positive" reading.
  static const List<List<int>> _sampleFrames = [
    // MilkSafe™ 4BTSC — positive (from iOS BluetoothDataProcessorTests)
    [1, 1, 0, 233, 0, 203, 0, 0, 0, 1, 244, 0, 6, 0, 0, 0, 2, 222, 0, 128, 0, 0,
      0, 3, 235, 0, 84, 0, 0, 0, 5, 13, 1, 35, 0, 0, 0, 92, 114, 92, 110],
    // MilkSafe™ 4BTSC — negative
    [1, 1, 0, 214, 0, 186, 0, 0, 0, 1, 221, 2, 20, 0, 0, 0, 2, 228, 3, 72, 0, 0,
      0, 3, 248, 1, 124, 0, 0, 0, 5, 9, 3, 87, 0, 0, 0, 92, 114, 92, 110],
  ];

  @override
  Stream<BtAdapterState> get adapterState =>
      Stream.value(BtAdapterState.poweredOn);

  @override
  BtAdapterState get currentAdapterState => BtAdapterState.poweredOn;

  @override
  Stream<ReaderConnectionState> get connectionState =>
      _connectionController.stream;

  @override
  BtDevice? get connectedDevice => _connectedDevice;

  @override
  Stream<List<BtDevice>> scanForReaders() async* {
    yield [];
    await Future<void>.delayed(const Duration(milliseconds: 700));
    yield [
      BtDevice(
        id: 'FAKE-PR-0001',
        name: 'PR-Simulator',
        readerType: SupportedReaderType.portableReader,
        rssi: -52,
      ),
    ];
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(BtDevice device) async {
    _connectionController.add(ReaderConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _connectedDevice = device;
    _connectionController.add(ReaderConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _connectedDevice = null;
    _connectionController.add(ReaderConnectionState.disconnected);
  }

  @override
  Future<List<int>> runTest(TestType testType, {String? payload}) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // Randomly pick a positive/negative captured frame for demo variety.
    return _sampleFrames[Random().nextInt(_sampleFrames.length)];
  }

  @override
  Future<double?> batteryLevel() async => 0.82;

  @override
  void dispose() => _connectionController.close();
}
