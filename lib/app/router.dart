import 'package:go_router/go_router.dart';

import '../features/testing/domain/test_sample.dart';
import '../features/testing/presentation/history_page.dart';
import '../features/testing/presentation/home_page.dart';
import '../features/testing/presentation/record_detail_page.dart';
import '../features/testing/presentation/run_test/devices_page.dart';
import '../features/testing/presentation/run_test/perform_test_page.dart';
import '../features/testing/presentation/run_test/ready_device_page.dart';
import '../features/testing/presentation/run_test/result_page.dart';
import '../features/testing/presentation/run_test/test_type_page.dart';

/// App navigation graph. The run-test flow is modelled as a stack of screens
/// (test type → device → ready → perform → result), mirroring the iOS
/// RunTest coordinator's push-based navigation.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
    GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
    GoRoute(
      path: '/record',
      builder: (_, state) => RecordDetailPage(sample: state.extra as TestSample),
    ),
    GoRoute(path: '/run/test-type', builder: (_, _) => const TestTypePage()),
    GoRoute(path: '/run/device', builder: (_, _) => const DevicesPage()),
    GoRoute(path: '/run/ready', builder: (_, _) => const ReadyDevicePage()),
    GoRoute(path: '/run/perform', builder: (_, _) => const PerformTestPage()),
    GoRoute(path: '/run/result', builder: (_, _) => const ResultPage()),
  ],
);
