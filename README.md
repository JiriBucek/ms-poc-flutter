# MilkSafe — Flutter rewrite (Proof of Concept)

A ground-up Flutter reimplementation of the native iOS `milksafe-ios-app`
(UIKit + VIPER). This PoC establishes the production architecture and proves the
riskiest part of the port — the Bluetooth reader protocol — end to end.

## What works today

- **Run-test vertical slice**: pick a test type → scan & connect a reader →
  run a test → decode the result → save it → see it in history (with detail).
- **Real GATT protocol**, ported verbatim from the iOS `BluetoothManager` /
  `BluetoothDataProcessor` (service/characteristic UUIDs, command framing,
  multi-packet response assembly, qualitative + quantitative decoding).
- **Decoder verified** against the exact byte fixtures from the iOS
  `BluetoothDataProcessorTests` — see `test/ble_result_decoder_test.dart`.
- **Fake reader** that replays real captured frames, so the app runs fully on
  desktop / simulator / CI without hardware (auto-selected off-device).

## Architecture (Riverpod + layered, feature-first)

```
lib/
  app/            App shell: MaterialApp.router, theme, routes, DI providers
  core/           Cross-cutting helpers (byte utils)
  features/
    bluetooth/    The reader layer — the seam to hardware
      domain/     BtDevice, ReaderRepository (interface), BLE commands/outputs,
                  constants (UUIDs). No Flutter, no BLE library.
      data/       FlutterBlueReader (real GATT), FakeReader (in-memory),
                  BleResultDecoder (pure port of BluetoothDataProcessor)
    testing/      The test/domain feature
      domain/     TestType, TestSample, enums (pure, JSON (de)serialisable)
      data/       TestTypeRepository (bundled catalogue),
                  TestRecordRepository (local JSON persistence)
      application/ Riverpod controllers (run-test, connection, history)
      presentation/ Pages + widgets
```

**Layering rule**: `presentation → application → domain ← data`. The domain
layer has zero framework dependencies. UI and controllers depend only on the
`ReaderRepository` interface, never on `flutter_blue_plus`, so hardware, fakes,
and tests are interchangeable. Every future screen slots into this same shape.

## Run it

```sh
flutter pub get
flutter test                       # decoder vectors + e2e flow
flutter run                        # desktop/simulator uses the fake reader
flutter run -d <iphone>            # real device uses the real GATT client
```

Bundle id: `software.inflow.milksafeFlutter`.

## Scope of the PoC vs. the full app

Implemented: the core loop above. Deliberately deferred (the pattern is proven,
these are repetitions of it): onboarding, operator-id/route/QR/temperature/
incubation steps, firmware-update-over-BLE, PDF export, photo documentation,
6-language localisation, backend OAuth sync (`TestGroupSyncer`), analytics.
