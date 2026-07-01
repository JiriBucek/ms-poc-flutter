import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../application/history_controller.dart';
import '../domain/test_sample.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test history'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(historyControllerProvider.notifier).refresh(),
          ),
          if (historyAsync.asData?.value.isNotEmpty ?? false)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(historyControllerProvider.notifier).clear(),
            ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (samples) {
          if (samples.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: samples.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _HistoryTile(sample: samples[i]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.sample});
  final TestSample sample;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.resultColor(sample.result);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(AppTheme.resultIcon(sample.result), color: color),
        ),
        title: Text(sample.testType.name),
        subtitle: Text(DateFormat('d MMM yyyy, HH:mm').format(sample.testDate)),
        trailing: Text(
          AppTheme.resultLabel(sample.result),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        onTap: () => context.push('/record', extra: sample),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('No tests yet'),
          const SizedBox(height: 4),
          Text('Run a test to see it here',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
