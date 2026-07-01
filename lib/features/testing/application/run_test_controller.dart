import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../bluetooth/data/ble_result_decoder.dart';
import '../../bluetooth/domain/reader_repository.dart';
import '../domain/test_sample.dart';
import '../domain/test_type.dart';
import 'history_controller.dart';

/// Available test types (bundled catalogue).
final testTypesProvider = FutureProvider<List<TestType>>((ref) {
  return ref.read(testTypeRepositoryProvider).loadTestTypes();
});

enum RunPhase { idle, running, success, failure }

class RunTestState {
  const RunTestState({
    this.testType,
    this.phase = RunPhase.idle,
    this.result,
    this.errorMessage,
  });

  final TestType? testType;
  final RunPhase phase;
  final TestSample? result;
  final String? errorMessage;

  bool get canRun => testType != null && phase != RunPhase.running;
}

/// Orchestrates a single test run: command the reader, decode the reply, persist
/// the record, and surface success/failure. This is the Flutter analogue of the
/// iOS `PerformTest` VIPER module, minus the incubation/QR steps the PoC omits.
class RunTestController extends Notifier<RunTestState> {
  @override
  RunTestState build() => const RunTestState();

  void selectTestType(TestType type) {
    state = RunTestState(testType: type);
  }

  void reset() => state = const RunTestState();

  Future<void> run() async {
    final testType = state.testType;
    if (testType == null) return;

    state = RunTestState(testType: testType, phase: RunPhase.running);

    final reader = ref.read(readerRepositoryProvider);
    final decoder = ref.read(resultDecoderProvider);

    try {
      final device = reader.connectedDevice;
      final raw = await reader.runTest(testType);
      final sample = decoder.decode(
        raw,
        testType,
        context: DecodeContext(
          deviceName: device?.name,
          appVersion: '1.0.0-poc',
        ),
      );

      if (sample == null) {
        state = RunTestState(
          testType: testType,
          phase: RunPhase.failure,
          errorMessage:
              'Reading was unreliable (control line too weak). Please retry.',
        );
        return;
      }

      await ref.read(historyControllerProvider.notifier).add(sample);
      state = RunTestState(
        testType: testType,
        phase: RunPhase.success,
        result: sample,
      );
    } on BtException catch (e) {
      state = RunTestState(
        testType: testType,
        phase: RunPhase.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = RunTestState(
        testType: testType,
        phase: RunPhase.failure,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }
}

final runTestControllerProvider =
    NotifierProvider<RunTestController, RunTestState>(RunTestController.new);
