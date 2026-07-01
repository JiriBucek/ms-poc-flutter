import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/bluetooth/data/fake_reader.dart';
import '../features/bluetooth/data/flutter_blue_reader.dart';
import '../features/bluetooth/data/ble_result_decoder.dart';
import '../features/bluetooth/domain/reader_repository.dart';
import '../features/testing/data/test_record_repository.dart';
import '../features/testing/data/test_type_repository.dart';

/// True when there is no real BLE stack to talk to (desktop / web / tests), so
/// the app transparently falls back to [FakeReader]. On iOS/Android the real
/// GATT client is used.
bool get useFakeReader {
  if (kIsWeb) return true;
  return defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.android;
}

/// The seam between app and hardware. Override this in tests to inject a fake.
final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final repo = useFakeReader ? FakeReader() : FlutterBlueReader();
  ref.onDispose(repo.dispose);
  return repo;
});

final resultDecoderProvider =
    Provider<BleResultDecoder>((ref) => const BleResultDecoder());

final testTypeRepositoryProvider =
    Provider<TestTypeRepository>((ref) => const TestTypeRepository());

final testRecordRepositoryProvider =
    Provider<TestRecordRepository>((ref) => const TestRecordRepository());
