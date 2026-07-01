import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/test_sample.dart';

/// Loads and mutates the persisted list of test records. The UI watches this;
/// the run-test flow appends to it on a successful test.
class HistoryController extends AsyncNotifier<List<TestSample>> {
  @override
  Future<List<TestSample>> build() {
    return ref.read(testRecordRepositoryProvider).loadAll();
  }

  Future<void> add(TestSample sample) async {
    final repo = ref.read(testRecordRepositoryProvider);
    await repo.save(sample);
    state = AsyncData(await repo.loadAll());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(testRecordRepositoryProvider).loadAll(),
    );
  }

  Future<void> clear() async {
    await ref.read(testRecordRepositoryProvider).clear();
    state = const AsyncData([]);
  }
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<TestSample>>(
  HistoryController.new,
);
