# AGENTS.md — MilkSafe Flutter rewrite

Working notes for AI agents (and humans) continuing this project. Read this
first. It captures what the app is, what's built, how it's structured, how to
build/deploy to a device, the reverse-engineered Bluetooth protocol, and the
concrete gotchas hit along the way.

Last updated: 2026-07-01.

---

## 1. What this is

A ground-up **Flutter rewrite** of the native iOS app `milksafe-ios-app`
(UIKit + VIPER, ~33k LOC, ~315 Swift files). MilkSafe is a Chr. Hansen product:
the phone app talks over **Bluetooth LE** to a handheld reader that tests cow
milk for antibiotic residues, then shows and stores the result.

The goal agreed with the product owner (Jiří Buček): a **complete 1:1 rewrite**
— same functionality, same UI. Strategy: build the architecture + one real
vertical slice first (done, proven on-device with the real reader), then port
the remaining screens page-by-page on the same pattern.

### Source repos on this machine
- iOS (source of truth): `/Users/butcha/Developer/Milksafe/milksafe-ios-app`
- This Flutter app: `/Users/butcha/Developer/Milksafe/flutter_poc`
- Others for context: `milksafe-android-app`, `milksafe-react-js-web`,
  `MilkSafe%20Cloud`, `milksafe-docs-wiki.js`, and `/Users/butcha/Developer/hive`.

### iOS app facts worth knowing
- **UIKit + VIPER** (Interactor/Presenter/Coordinator/Protocols). 30 view
  controllers, 10 coordinators. Storyboards + programmatic views.
- **Offline-first**: test records persist locally as Codable JSON in the app
  documents dir; a background syncer (`TestGroupSyncer`) POSTs them to a REST
  backend via **OAuth**. Firebase is **only** Analytics + Crashlytics (no
  Firestore, no Firebase auth).
- Frameworks: CoreBluetooth, Combine, PDFKit, Vision (QR/OCR), AVFoundation
  (camera), Kingfisher (image cache), Rye (toasts), Zip.
- 6 localisations: en, de, es, fr, pt-PT, ru.
- Fonts: **NeuzeitGro** family. Colours defined in code (`Style.swift`), not
  asset catalogues.

---

## 2. Current status — what's DONE

Deployed and verified on a real iPhone (iPhone 15, iOS 26.5) against the real
reader hardware. A real milk test runs and the result is saved and shown.

Implemented, end to end:
- **Run-test vertical slice** as separate screens (iOS-style push navigation):
  Home → Choose test → Choose reader (scan/connect) → Ready to test → Test
  running → Result (saved) → History (list + detail).
- **Real GATT protocol** ported from iOS `BluetoothManager` +
  `BluetoothDataProcessor` (see §5). Verified: a real reader test produced a
  correct result on-device.
- **Design system** ported 1:1 from `Style.swift`: NeuzeitGro fonts, exact
  colour palette, 64 image assets, and CH button/label styles.
- **Decoder correctness proven**: `test/ble_result_decoder_test.dart` runs the
  exact byte fixtures + expected outcomes from the iOS
  `BluetoothDataProcessorTests` suite. All pass — the Dart decode is
  byte-for-byte faithful to Swift.
- **End-to-end widget test**: `test/run_test_flow_test.dart` drives the whole
  flow with an injected fake reader + in-memory store.

Run `flutter test` → 7 tests pass. `flutter analyze` → 0 errors (2 info lints).

### UI review feedback already applied (from on-device comparison)
- Back buttons are blue (chPrimaryDark), not black.
- Test-type cells match `TestTypeCell` (centred brand Bold-22 + name Bold-48,
  1px black border, off-white "Quant" pill, blue when selected).
- Scanner hero images are edge-to-edge (full width).
- Removed a stray Bluetooth icon from the reader cell.
- Substance rows match `SampleItemStackView`: white row `Name: value Result
  [icon]`, black text, only a red-X/green-check icon is coloured (no coloured
  boxes). Removed the coloured group banner (iOS shows it only in multi-test
  flows).
- Home Settings + result Home buttons enlarged.
- Bluetooth: scan waits for adapter power-on and scans 30s; connection is kept
  alive across tests; `connect()` is idempotent and an already-connected reader
  stays visible/pre-selected → no more power-cycling between tests.

---

## 3. What's NOT done yet (the page-by-page backlog)

Everything below exists in iOS and is deliberately deferred. Each is a
repetition of the established pattern (domain model → repository → controller →
screen). Rough priority order:

1. **Full run-test flow steps** the PoC skips: Operator ID, Route selection, QR
   cassette scan (`mobile_scanner`), quantitative payload scan, Temperature +
   Incubation (truck reader), Ready-device variants, confirmation/retest flow
   (positive → confirmation test → group result).
2. **Onboarding**: Welcome, Username, Password.
3. **Test records** list: grouping into `TestRecordsGroup`, filters, share,
   PDF export (`pdf` pkg), photo documentation (camera), annotations.
4. **Settings**: language, test brand, test settings (enable/disable test
   types, QR toggles).
5. **Firmware update over BLE** (DFU-style; protocol already mapped in §5 —
   commands 0x22/0x34/0x35, 17-byte chunks). Non-trivial.
6. **Backend sync**: OAuth login, `MilkSafeAPI`, `TestGroupSyncer`, sites,
   server-driven test-type configs, feedback. Currently local-only.
7. **Localisation** (6 languages). Strings currently hard-coded English in
   `lib/app/strings.dart` — designed to become the l10n seam.
8. **Analytics / Crashlytics** (Firebase) if desired.

---

## 4. Architecture

**Riverpod 3 + layered, feature-first.** Layering rule:
`presentation → application → domain ← data`. The `domain/` layer has zero
framework dependencies. UI/controllers depend only on the `ReaderRepository`
*interface*, never on `flutter_blue_plus` — so hardware, the fake, and tests are
interchangeable.

```
lib/
  main.dart                     ProviderScope + MilkSafeApp
  app/
    app.dart                    MaterialApp.router
    router.dart                 go_router graph (run-test flow = screen stack)
    providers.dart              DI: readerRepositoryProvider (real vs fake),
                                decoder, test-type & record repositories
    strings.dart                English UI strings (future l10n seam)
    theme.dart                  AppTheme: ThemeData + result colour semantics
    theme/
      colors.dart               AppColors — 1:1 from iOS Style.swift
      app_text.dart             AppText — NeuzeitGro styles (title/subtitle/…)
      app_images.dart           AppImages — asset path catalogue
    widgets/
      ch_buttons.dart           CHFilledButton / CHOutlinedButton / CHPlainButton
  core/
    utils/byte_utils.dart       uint16BE, hexString, chunked
  features/
    bluetooth/                  the reader layer (the seam to hardware)
      domain/
        ble_constants.dart      GATT UUIDs, terminator, result geometry
        ble_command.dart        BleCommand (sealed) → wire bytes  [pure]
        ble_output.dart         response classification + errors    [pure]
        bt_device.dart          BtDevice (library-agnostic)
        reader_repository.dart  ReaderRepository interface, BtException, states
      data/
        ble_result_decoder.dart BleResultDecoder — pure port of the iOS
                                BluetoothDataProcessor (qualitative + quant)
        flutter_blue_reader.dart Real GATT client (ONLY file that imports
                                flutter_blue_plus)
        fake_reader.dart        In-memory reader replaying real captured frames
      application/              (providers live with the testing feature)
    testing/                    the test/domain feature
      domain/
        enums.dart              SampleResult, TestCategory, JudgeType,
                                JudgingDirection, MeasurementMethod,
                                SupportedReaderType
        test_type.dart          TestType, TestTypeSubstance, QuantitativeRange
        test_sample.dart        TestSample (+ nested), JSON (de)serialisable
      data/
        test_type_repository.dart   loads bundled assets/test_types.json
        test_record_repository.dart local JSON persistence (path_provider)
      application/
        connection_controller.dart  scanResultsProvider + ConnectionController
        run_test_controller.dart     testTypesProvider + RunTestController
        history_controller.dart      HistoryController (AsyncNotifier)
      presentation/
        home_page.dart
        history_page.dart
        record_detail_page.dart
        run_test/
          test_type_page.dart
          devices_page.dart
          ready_device_page.dart
          perform_test_page.dart
          result_page.dart
        widgets/
          test_result_view.dart      shared result presentation
assets/
  test_types.json               copied from iOS all-test-types-production.json
  fonts/NeuzeitGro-*.otf         4 weights (Lig/Reg/Bol/Bla) → weight 300/400/700/900
  images/*.png                  64 assets extracted from iOS asset catalogue
test/
  ble_result_decoder_test.dart  decode vs iOS fixtures (correctness proof)
  run_test_flow_test.dart       full-flow widget test (fake reader + in-memory)
```

Key packages: `flutter_riverpod ^3.3`, `flutter_blue_plus ^2.3`,
`go_router ^17`, `path_provider`, `equatable`, `intl`, `uuid`.

### Data flow of a test
`RunTestController.run()` → `ReaderRepository.runTest(testType)` returns raw
assembled bytes → `BleResultDecoder.decode(bytes, testType)` → `TestSample?`
(null = unreliable) → `HistoryController.add()` persists → result screen.

### Conventions for new screens
- One feature folder, split domain/data/application/presentation.
- Models: immutable, `Equatable`, hand-written `fromJson`/`toJson` (no codegen).
- State: `Notifier`/`AsyncNotifier` + `NotifierProvider`. `StreamProvider
  .autoDispose` for scans.
- UI: use `AppColors`, `AppText`, `AppImages`, `CH*` buttons, and `S` strings —
  don't hardcode colours/sizes/text. Read the iOS view for exact values.

---

## 5. Bluetooth / GATT protocol (reverse-engineered from iOS)

Ported verbatim; see `ble_constants.dart`, `ble_command.dart`, `ble_output.dart`,
`ble_result_decoder.dart`.

### Service / characteristic UUIDs
Scan filters on services `00001000-…` (portable) and `0000a002-…` (truck).
- Portable reader: service `00001000-0000-1000-8000-00805f9b34fb`,
  input(write) `00001001-…`, output(notify) `00001002-…`.
- Truck reader: service `0000a002-…`, input `0000c303-…`, output `0000c305-…`.
- Response terminator (end of multi-packet): bytes `[0x5C,0x72,0x5C,0x6E]`
  (literal ASCII `\r\n`).

### Reader type detection (from advertised name)
starts `PRC` → portableReaderConnect; starts `PR` → portableReader; contains
`TR` or `Helmen` → truckReader; starts `MS-H0` → portableReaderConnect; else
portableReader. Name cleanup: strip `(BT)`.

### Commands (first byte = command code)
- `0x26` powerStatus (battery)
- `0x01` runTest → `[0x01, numLines, (truck only: 0x01 cassette / 0x02 strip)]`
- `0x02` runQuantitativeTest → `[0x02, …utf8(payload)]`
- `0x30` setTemperature → `[0x30, 0x01, (temp*10)>>8, (temp*10)&0xFF]`
- `0x31` truckReaderStatus
- Firmware: `0x22` startUpdate, `0x34` prepareForFirmwareUpdate,
  `0x35` updateFirmware (17-byte chunks + XOR checksum + terminator)
- Write type: portable reader → **withResponse**; truck / PRC → **withoutResponse**.

### Response handling
Classify by first byte (same codes). Success = status byte (index 1) != 0x00.
Test-result frames arrive in **multiple notification packets**; append until the
buffer's last 4 bytes == terminator, then decode.
Test-result error codes (byte[1]): 0x00 failure, 0x02 reserve, 0x03 pollute,
0x04 invalid.

### Qualitative decode (`BleResultDecoder`, matches iOS exactly)
- `testResultStandardLength = 7` bytes per "set".
- Strip cmd+status (2) and trailing 4 control bytes → values; `sets =
  len ~/ 7`. Each set: position=uint16BE(0), height=uint16BE(2),
  area=uint16BE(4) (big-endian, first two bytes).
- Set 0 = **control line** → removed. If `control.height < 60` → reading
  **unreliable** → return null.
- Per substance: `compare = (judgeType==area ? item.area/control.area :
  item.height/control.height)`, clamp ≤5.0, round 2dp. Classify by direction:
  - positive dir: `>positiveValue`→positive; `>negativeValue` (and pos≠neg)
    →weakPositive; else negative.
  - reverse dir: `<positiveValue`→positive; `<=negativeValue` (and pos≠neg)
    →weakPositive; else negative.
  - Overall: any positive→positive; any weakPositive (no positive)→weakPositive;
    else negative.
- Substance mapping uses `testType.sortedSubstances` (by `readerIndex`), indexed
  in reverse.
- All bundled MilkSafe tests: `judgeType=Height`, `judgingDirection=Reverse`,
  `positiveValue=0.9`, `negativeValue=1.1`.

### Quantitative decode
UTF-8 string split on `#`: field[2]=value (double), field[1]=batch,
field[4]=="Invalid"→null. Requires len≥32 and a `quantitativeRange`; classify
value against measurable/negative ranges.

### Battery
`value = uint16BE(bytes[2..4])`; level = `value<2000 ? 0 : (value-2000)/1800.0`.

---

## 6. Build, run, deploy

Toolchain is installed on this machine: **Flutter 3.44 (Dart 3.12)** and
**CocoaPods 1.16** via Homebrew; **Xcode 26.5**. `flutter` is at
`/opt/homebrew/bin/flutter` — if not on PATH: `export PATH="/opt/homebrew/bin:$PATH"`.

```sh
flutter pub get
flutter analyze
flutter test
flutter run                 # desktop/web/simulator → auto-uses FakeReader
```

### Deploying to the physical iPhone — IMPORTANT gotchas
Signing is configured: Apple Development team `5QYJV2P8HK` (Jiří Buček), bundle
id `software.inflow.milksafeFlutter`.

1. **iOS 14+ blocks debug (JIT) apps** from launching outside Flutter tooling.
   For a build that runs from the home screen you MUST use **`--release`**
   (or profile). `flutter build ios --debug` installs but won't launch standalone.
2. Enable **Developer Mode** on the device once (Settings → Privacy & Security →
   Developer Mode → on → restart).
3. `flutter install` / `flutter run` sometimes reports **"No target device
   found"** even though `flutter devices` lists the phone. Work around it with
   Apple's `devicectl` directly:

```sh
export PATH="/opt/homebrew/bin:$PATH"
cd /Users/butcha/Developer/Milksafe/flutter_poc

# 1) build a signed release
flutter build ios --release

# 2) find the device id
xcrun devicectl list devices        # note the identifier (paired iPhone)

# 3) install + launch
DEV=<device-identifier>
xcrun devicectl device install app --device $DEV build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device $DEV software.inflow.milksafeFlutter
```

The paired device we used: name `Buča`, devicectl id
`1090657F-213F-537D-9673-260BD7A8C795`, flutter id
`00008120-000E203A3E05A01E`. (These are device-specific; re-query.)

First launch may require trusting the developer profile under Settings →
General → VPN & Device Management, and granting the Bluetooth prompt
(`NSBluetoothAlwaysUsageDescription` is set in `ios/Runner/Info.plist`).

---

## 7. Lessons learned / gotchas

- **flutter_blue_plus 2.x** `BluetoothDevice.connect()` now requires a
  `license:` arg → pass `License.nonprofit` (`License.free` is deprecated).
- **Riverpod 3** `AsyncValue` has no `valueOrNull` here — use `.asData?.value`.
- **flutter_blue_plus Guid** may report 16-bit short UUIDs (e.g. `1000`) or full
  128-bit depending on platform — `FlutterBlueReader._uuidEquals` normalises
  both before comparing. Keep that when adding characteristics.
- **iOS asset catalogue** mixes PNG imagesets and PDF (vector) imagesets. PNGs
  were copied directly (picking @2x/@3x); the 16 PDF-only ones were rasterised
  with `sips -s format png -Z 144`. If you need crisper vector icons later,
  convert to SVG + `flutter_svg` instead.
- **Fonts**: NeuzeitGro registered as one family with weights 300/400/700/900 →
  `AppText.light/regular/bold/black` map to those.
- **Widget tests can't touch path_provider** — override
  `testRecordRepositoryProvider` with an in-memory fake (see the flow test).
- **CircularProgressIndicator animates forever** → `pumpAndSettle` hangs in
  widget tests. Use explicit `pump(Duration(...))` steps.
- The reader sends test results as **several BLE notifications**; you must
  buffer until the terminator, not decode the first packet.

---

## 8. How to pick up next

1. `flutter pub get && flutter test` to confirm green.
2. Deploy per §6 and eyeball against the iOS app.
3. Pick the next item from §3. For a run-test sub-step (e.g. Operator ID / Route
   / QR), read the matching iOS scene under
   `milksafe-ios-app/App/Source/Scenes/Home/RunTest/<Step>/` (ViewController +
   Presenter + Models) for the exact layout/strings, add a domain model +
   controller if needed, build the screen with the design-system widgets, and
   slot it into the `go_router` flow before/after the existing screens per the
   iOS RunTest coordinator order:
   operatorId → route → testType → (quant payload) → (QR cassette) → device →
   (truck: temperature → incubation) → ready → perform → result.
4. Keep matching from the iOS **code** (colours/fonts/strings are all there). A
   **Figma** exists with the design and would help nail exact spacing/margins —
   ask the owner for it if pixel-perfect spacing is required.
5. Update this file when you finish something or learn something.

### Reference material in-repo
- iOS design system: `milksafe-ios-app/App/Source/Misc/Style/Style.swift`
- iOS BLE: `App/Dependencies/Bluetooth/{BluetoothManager,BluetoothModels,
  BluetoothDataProcessor}.swift`, `App/Source/Misc/Constants.swift`
- iOS test fixtures: `MilkSafeTests/BluetoothDataProcessorTests/`
- iOS run-test flow: `App/Source/Scenes/Home/RunTest/`
- iOS strings: `milksafe-ios-app/Localization/` (+ `App/*.lproj`)
