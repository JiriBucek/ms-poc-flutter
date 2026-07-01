import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milksafe_flutter/app/app.dart';
import 'package:milksafe_flutter/app/providers.dart';
import 'package:milksafe_flutter/features/bluetooth/data/fake_reader.dart';
import 'package:milksafe_flutter/features/testing/data/test_record_repository.dart';
import 'package:milksafe_flutter/features/testing/domain/test_sample.dart';

/// In-memory record store so the flow test doesn't touch path_provider / disk.
class _InMemoryRecords implements TestRecordRepository {
  final List<TestSample> _items = [];

  @override
  Future<List<TestSample>> loadAll() async => List.of(_items);

  @override
  Future<void> save(TestSample sample) async => _items.insert(0, sample);

  @override
  Future<void> clear() async => _items.clear();
}

void main() {
  testWidgets('run-test flow: home → type → device → ready → perform → result',
      (tester) async {
    final records = _InMemoryRecords();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerRepositoryProvider.overrideWithValue(FakeReader()),
          testRecordRepositoryProvider.overrideWithValue(records),
        ],
        child: const MilkSafeApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Home → Start test
    expect(find.text('Start test'), findsOneWidget);
    await tester.tap(find.text('Start test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Test type selection
    expect(find.text('Choose test to run'), findsOneWidget);
    await tester.tap(find.text('MilkSafe™').first);
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Device selection: wait for the simulated reader, select + connect
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('PR-Simulator'), findsOneWidget);
    await tester.tap(find.text('PR-Simulator'));
    await tester.pump();
    await tester.tap(find.text('Start test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Ready screen
    expect(find.text('Ready to test'), findsOneWidget);
    await tester.tap(find.text('Reader is ready. Start test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Perform → result
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Run new test'), findsOneWidget);
    expect(records.loadAll(), completion(hasLength(1)));
  });
}
