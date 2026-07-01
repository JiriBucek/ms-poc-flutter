import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../bluetooth/domain/bt_device.dart';
import '../../bluetooth/domain/reader_repository.dart';

/// Live list of readers discovered while scanning. Auto-disposes so scanning
/// stops when no screen is watching it.
final scanResultsProvider = StreamProvider.autoDispose<List<BtDevice>>((ref) {
  final repo = ref.watch(readerRepositoryProvider);
  ref.onDispose(repo.stopScan);
  return repo.scanForReaders();
});

class ConnectionState {
  const ConnectionState({this.device, this.connecting = false, this.error});

  final BtDevice? device;
  final bool connecting;
  final String? error;

  bool get isConnected => device != null;
}

/// Owns connect/disconnect to the active reader and exposes the connected
/// device to the rest of the flow.
class ConnectionController extends Notifier<ConnectionState> {
  @override
  ConnectionState build() {
    final repo = ref.read(readerRepositoryProvider);
    final sub = repo.connectionState.listen((s) {
      if (s == ReaderConnectionState.disconnected) {
        state = const ConnectionState();
      }
    });
    ref.onDispose(sub.cancel);
    return ConnectionState(device: repo.connectedDevice);
  }

  Future<void> connect(BtDevice device) async {
    state = const ConnectionState(connecting: true);
    try {
      await ref.read(readerRepositoryProvider).connect(device);
      state = ConnectionState(device: device);
    } catch (e) {
      state = ConnectionState(error: _message(e));
    }
  }

  Future<void> disconnect() async {
    await ref.read(readerRepositoryProvider).disconnect();
    state = const ConnectionState();
  }

  String _message(Object e) =>
      e is BtException ? e.message : 'Failed to connect to reader';
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionState>(
  ConnectionController.new,
);
