import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme/app_images.dart';
import '../../../../app/widgets/ch_buttons.dart';
import '../../application/connection_controller.dart';
import '../../../bluetooth/domain/bt_device.dart';

/// Step 2 — pick and connect a reader. Matches the iOS Devices screen: scanner
/// hero image, "which serial number…" header, a radio list of readers, and a
/// "Start test" button that connects then advances to the ready screen.
class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  BtDevice? _selected;

  Future<void> _connectAndContinue() async {
    final device = _selected;
    if (device == null) return;
    // connect() is idempotent — reuses an existing session for the same reader.
    await ref.read(connectionControllerProvider.notifier).connect(device);
    if (!mounted) return;
    if (ref.read(connectionControllerProvider).isConnected) {
      context.push('/run/ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanResultsProvider);
    final conn = ref.watch(connectionControllerProvider);
    // Default the selection to an already-connected reader so the user can
    // immediately start another test without re-scanning.
    final effective = _selected ?? conn.device;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppImages.stripScanner,
                width: double.infinity, fit: BoxFit.fitWidth),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(S.chooseScannerHeader, style: AppText.title),
            ),
            Expanded(
              child: scan.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Scan error: $e')),
                data: (devices) {
                  if (devices.isEmpty) {
                    return _Searching();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: devices.length,
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      final selected = effective?.id == d.id;
                      return _DeviceCell(
                        device: d,
                        selected: selected,
                        onTap: () => setState(() => _selected = d),
                      );
                    },
                  );
                },
              ),
            ),
            if (conn.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(conn.error!,
                    style: AppText.regular(15, color: AppColors.warning)),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: CHFilledButton(
                title: conn.connecting ? S.connecting : S.startTest,
                onPressed: (effective == null || conn.connecting)
                    ? null
                    : () {
                        _selected ??= effective;
                        _connectAndContinue();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text(S.lookingForReaders,
              style: AppText.regular(18, color: AppColors.subtitleGrey)),
        ],
      ),
    );
  }
}

class _DeviceCell extends StatelessWidget {
  const _DeviceCell({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final BtDevice device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.lightGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(device.name,
                  style: AppText.bold(20, color: AppColors.black)),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.darkGrey,
            ),
          ],
        ),
      ),
    );
  }
}
