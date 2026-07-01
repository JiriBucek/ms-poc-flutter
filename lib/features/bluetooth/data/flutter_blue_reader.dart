import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../testing/domain/enums.dart';
import '../../testing/domain/test_type.dart';
import '../domain/ble_command.dart';
import '../domain/ble_constants.dart';
import '../domain/ble_output.dart';
import '../domain/bt_device.dart';
import '../domain/reader_repository.dart';

/// Real reader implementation backed by `flutter_blue_plus`.
///
/// This is the only file in the app that knows about a concrete BLE library;
/// it maps the platform GATT world onto [ReaderRepository]. Ported from the
/// CoreBluetooth `BluetoothManager`.
class FlutterBlueReader implements ReaderRepository {
  FlutterBlueReader() {
    _adapterSub = FlutterBluePlus.adapterState
        .map(_mapAdapterState)
        .listen(_adapterController.add);
  }

  final _adapterController = StreamController<BtAdapterState>.broadcast();
  final _connectionController =
      StreamController<ReaderConnectionState>.broadcast();

  StreamSubscription<BtAdapterState>? _adapterSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _inputChar;
  BluetoothCharacteristic? _outputChar;
  BtDevice? _connectedDevice;

  @override
  Stream<BtAdapterState> get adapterState => _adapterController.stream;

  @override
  BtAdapterState get currentAdapterState =>
      _mapAdapterState(FlutterBluePlus.adapterStateNow);

  @override
  Stream<ReaderConnectionState> get connectionState =>
      _connectionController.stream;

  @override
  BtDevice? get connectedDevice => _connectedDevice;

  /// Waits (briefly) for the adapter to be powered on before scanning, so the
  /// first scan after launch isn't dropped because BLE wasn't ready yet.
  Future<void> _ensureAdapterOn() async {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) return;
    try {
      await FlutterBluePlus.adapterState
          .firstWhere((s) => s == BluetoothAdapterState.on)
          .timeout(const Duration(seconds: 6));
    } catch (_) {/* proceed; scan will surface any real error */}
  }

  @override
  Stream<List<BtDevice>> scanForReaders() async* {
    await _ensureAdapterOn();

    final services =
        BleConstants.serviceUuids.map((u) => Guid(u)).toList(growable: false);
    if (!FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.startScan(
        withServices: services,
        // Scan for the whole time the screen is open (stopped on dispose),
        // so a slow-to-advertise reader still appears without re-entering.
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: false,
      );
    }

    yield* FlutterBluePlus.scanResults.map((results) {
      final devices = <BtDevice>[];
      // Keep an already-connected reader visible even though it no longer
      // advertises — lets the user start another test without power-cycling.
      final connected = _connectedDevice;
      if (connected != null) devices.add(connected);

      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        if (name.isEmpty) continue;
        final id = r.device.remoteId.str;
        if (devices.any((d) => d.id == id)) continue;
        devices.add(BtDevice.fromAdvertisement(id: id, name: name, rssi: r.rssi));
      }
      return devices;
    });
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> connect(BtDevice device) async {
    // Already connected to this reader with characteristics bound — reuse it.
    if (_connectedDevice?.id == device.id &&
        _inputChar != null &&
        _outputChar != null &&
        _device?.isConnected == true) {
      _connectionController.add(ReaderConnectionState.connected);
      return;
    }

    await stopScan();
    _connectionController.add(ReaderConnectionState.connecting);

    final target = BluetoothDevice.fromId(device.id);
    _device = target;

    await _connSub?.cancel();
    _connSub = target.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _inputChar = null;
        _outputChar = null;
        _connectedDevice = null;
        _connectionController.add(ReaderConnectionState.disconnected);
      }
    });

    await target.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 20),
    );
    final services = await target.discoverServices();
    _bindCharacteristics(device, services);

    if (_inputChar == null || _outputChar == null) {
      await target.disconnect();
      throw const BtException('Reader services not found');
    }

    // Subscribe to reader → app notifications.
    if (_outputChar!.properties.notify) {
      await _outputChar!.setNotifyValue(true);
    }

    _connectedDevice = device;
    _connectionController.add(ReaderConnectionState.connected);
  }

  void _bindCharacteristics(BtDevice device, List<BluetoothService> services) {
    final isTruck = device.readerType == SupportedReaderType.truckReader;
    final inputUuid =
        isTruck ? BleConstants.inputCharTruck : BleConstants.inputCharPortable;
    final outputUuid = isTruck
        ? BleConstants.outputCharTruck
        : BleConstants.outputCharPortable;

    for (final service in services) {
      for (final c in service.characteristics) {
        if (_uuidEquals(c.uuid, inputUuid)) _inputChar = c;
        if (_uuidEquals(c.uuid, outputUuid)) _outputChar = c;
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _device?.disconnect();
    _inputChar = null;
    _outputChar = null;
    _connectedDevice = null;
    _connectionController.add(ReaderConnectionState.disconnected);
  }

  @override
  Future<List<int>> runTest(TestType testType, {String? payload}) async {
    final input = _inputChar;
    final output = _outputChar;
    final device = _connectedDevice;
    if (input == null || output == null || device == null) {
      throw const BtException('Not connected to a reader');
    }

    final config =
        RunTestConfig.forTest(testType, device.readerType, payload: payload);
    final command = testType.measurementMethod == MeasurementMethod.quantitative
        ? BleCommand.runQuantitativeTest(config)
        : BleCommand.runTest(config);
    // Portable reader expects writeWithResponse; others writeWithoutResponse.
    final withoutResponse =
        device.readerType != SupportedReaderType.portableReader;

    final completer = Completer<List<int>>();
    final buffer = <int>[];
    var receiving = false;
    late StreamSubscription<List<int>> sub;

    sub = output.onValueReceived.listen((value) {
      if (!receiving) {
        if (BleOutputKind.classify(value) != BleOutputKind.testResult) {
          return; // ignore unrelated frames
        }
        if (!BleOutputKind.isSuccessStatus(value)) {
          sub.cancel();
          if (!completer.isCompleted) {
            completer.completeError(BtException(
              'Test failed',
              testError: BleTestResultError.classify(value),
            ));
          }
          return;
        }
        receiving = true;
      }
      buffer.addAll(value);
      if (isCompleteResponse(buffer)) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(List.of(buffer));
      }
    });

    await input.write(command.data, withoutResponse: withoutResponse);

    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        sub.cancel();
        throw const BtException('Timed out waiting for test result');
      },
    );
  }

  @override
  Future<double?> batteryLevel() async {
    final input = _inputChar;
    final output = _outputChar;
    if (input == null || output == null) return null;

    final completer = Completer<List<int>>();
    late StreamSubscription<List<int>> sub;
    sub = output.onValueReceived.listen((value) {
      if (BleOutputKind.classify(value) == BleOutputKind.powerStatus) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(value);
      }
    });
    await input.write(const BleCommand.powerStatus().data, withoutResponse: true);

    try {
      final data = await completer.future.timeout(const Duration(seconds: 5));
      if (data.length < 4) return null;
      final raw = (data[2] << 8) + data[3];
      if (raw < 2000) return 0;
      return (raw - 2000) / 1800.0;
    } on TimeoutException {
      sub.cancel();
      return null;
    }
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _connSub?.cancel();
    _adapterController.close();
    _connectionController.close();
  }

  BtAdapterState _mapAdapterState(BluetoothAdapterState s) => switch (s) {
        BluetoothAdapterState.on => BtAdapterState.poweredOn,
        BluetoothAdapterState.off => BtAdapterState.poweredOff,
        BluetoothAdapterState.turningOn => BtAdapterState.poweredOff,
        BluetoothAdapterState.turningOff => BtAdapterState.poweredOff,
        BluetoothAdapterState.unauthorized => BtAdapterState.unauthorized,
        BluetoothAdapterState.unavailable => BtAdapterState.unavailable,
        _ => BtAdapterState.unknown,
      };

  /// Compares a [Guid] against a 128-bit uuid string, tolerating the 16-bit
  /// short form some platforms report (e.g. "1000").
  bool _uuidEquals(Guid guid, String full) => _norm(guid.str) == _norm(full);

  String _norm(String s) {
    final v = s.toLowerCase().replaceAll('-', '');
    if (v.length == 4) return '0000$v${'00001000800000805f9b34fb'}';
    return v;
  }
}
