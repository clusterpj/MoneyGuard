import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('MoneyGuard UI Walkthrough', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    Future<void> takeScreenshot(String name) async {
      // Small delay to allow animations to settle
      await Future.delayed(const Duration(seconds: 1));
      final List<int> pixels = await driver.screenshot();
      final File file = File('test_driver/screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(pixels);
      print('Screenshot saved: $name.png');
    }

    test('Capture UI State', () async {
      // Assume logged in or wait for it.
      print('Waiting for Dashboard...');
      await driver.waitFor(
        find.text('MoneyGuard'),
        timeout: const Duration(seconds: 20),
      );

      print('Step 2: Capture Dashboard');
      await takeScreenshot('02_dashboard_screen');

      // 3. Add Expense Screen (via FAB)
      final fabFinder = find.byValueKey('addExpenseFab');
      await driver.tap(fabFinder);

      // Wait for bottom sheet or simple navigation? Logic here might vary.
      // Assuming navigation to /expenses/add or similar via QuickAddSheet
      // The QuickAddSheet pops up. Let's just capture the Sheet.
      await Future.delayed(const Duration(seconds: 1));
      print('Step 3: Capture QuickAdd Sheet');
      await takeScreenshot('03_quick_add_sheet');

      // Tap "Scan Receipt / Import"
      final scanFinder = find.text('Scan Receipt / Import');
      await driver.tap(scanFinder);

      // Wait for Import Screen
      await driver.waitFor(find.text('Import Transactions'));
      print('Step 4: Capture Import Screen');
      await takeScreenshot('04_import_screen');

      // Go back
      final backButton = find.pageBack();
      await driver.tap(backButton);

      // Close Sheet if still open (tapping outside usually works, or back button)
      // If we are back at dashboard, good.
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
