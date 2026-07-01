/// English UI strings, resolved from the iOS localization keys. Centralised so
/// the (future) localisation layer can swap languages without touching widgets.
class S {
  S._();

  // Home
  static const settings = 'Settings';
  static const loginNow = 'Login now';
  static const startTest = 'Start test';
  static const testRecords = 'Test records';

  // Device selection
  static const chooseScannerHeader =
      'Which serial number is printed on your scanner?';
  static const lookingForReaders = 'Looking for readers';
  static const connecting = 'Connecting';

  // Test type selection
  static const chooseTestTitle = 'Choose test to run';
  static const next = 'Next';
  static const quant = 'Quant';

  // Ready device
  static const readyToTest = 'Ready to test';
  static const testLabel = 'Test:';
  static const operatorLabel = 'Operator ID:';
  static const routeLabel = 'Route:';
  static const insertStripHelp = 'Insert strip in reader and press the button.';
  static const readyBtn = 'Reader is ready. Start test';

  // Perform test
  static const testIsRunning = 'Test is running. Please wait';

  // Result
  static const testIsPositive = 'Test is positive';
  static const testIsNegative = 'Test is negative';
  static const testIsWeakPositive = 'Test is weak positive';
  static const runNewTest = 'Run new test';
  static const dateTimeLabel = 'Date & time:';
  static const readerLabel = 'Reader:';
  static const batchNumberLabel = 'Batch number:';
  static const uploadStatusLabel = 'Upload status:';
  static const notSynced = 'Not synced';
}
