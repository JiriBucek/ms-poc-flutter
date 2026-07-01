import '../../testing/domain/test_type.dart';
import 'ble_output.dart';
import 'bt_device.dart';

/// Adapter power/permission state, decoupled from the BLE library.
enum BtAdapterState { unknown, unauthorized, unavailable, poweredOff, poweredOn }

/// Connection lifecycle for the active reader.
enum ReaderConnectionState { disconnected, connecting, connected }

/// Error surfaced by the reader layer.
class BtException implements Exception {
  const BtException(this.message, {this.testError});
  final String message;

  /// Present when a test frame reported a specific failure code.
  final BleTestResultError? testError;

  @override
  String toString() => 'BtException($message${testError != null ? ', $testError' : ''})';
}

/// The single seam between the app and the physical reader. Everything above
/// this interface (controllers, UI) is Bluetooth-library agnostic, so the real
/// GATT client and a fake can be swapped freely for tests and hardware-free
/// runs. Mirrors the responsibilities of iOS `BluetoothManagerProtocol`.
abstract interface class ReaderRepository {
  /// Current adapter power/permission state, updated as it changes.
  Stream<BtAdapterState> get adapterState;

  /// Snapshot of the adapter state right now.
  BtAdapterState get currentAdapterState;

  /// Connection state of the active reader.
  Stream<ReaderConnectionState> get connectionState;

  /// The reader we are currently connected to, if any.
  BtDevice? get connectedDevice;

  /// Continuously emits the set of discovered readers while scanning.
  Stream<List<BtDevice>> scanForReaders();

  Future<void> stopScan();

  /// Connects, discovers services and subscribes to notifications.
  Future<void> connect(BtDevice device);

  Future<void> disconnect();

  /// Runs [testType] and returns the fully assembled raw reader bytes.
  ///
  /// Throws [BtException] on failure (incl. a classified [BleTestResultError]).
  Future<List<int>> runTest(TestType testType, {String? payload});

  /// Battery level in 0..1, or null if unavailable.
  Future<double?> batteryLevel();

  void dispose();
}
