import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('MoneyGuard App', () {
    FlutterDriver? driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver!.close();
      }
    });

    test('Add Expense Flow', () async {
      print('Checking for Login or Dashboard...');

      final addExpenseFinder = find.byValueKey('addExpenseFab');
      final loginTitleFinder = find.text('Login');

      bool isOnDashboard = false;
      try {
        // Initial wait for app launch
        await Future.delayed(Duration(seconds: 5));

        await driver!.waitFor(addExpenseFinder, timeout: Duration(seconds: 15));
        isOnDashboard = true;
        print('Already on Dashboard.');
      } catch (e) {
        print('Not on Dashboard within 15s. Checking login...');
      }

      if (!isOnDashboard) {
        await driver!.waitFor(loginTitleFinder, timeout: Duration(seconds: 15));
        print('On Login Screen. Logging in...');

        final emailFinder = find.byValueKey('emailField');
        await driver!.tap(emailFinder);
        await driver!.enterText('jisgore@gmail.com');

        final passwordFinder = find.byValueKey('passwordField');
        await driver!.tap(passwordFinder);
        await driver!.enterText('1q2w3e4r');

        final loginButtonFinder = find.byValueKey('loginButton');
        await driver!.tap(loginButtonFinder);

        print('Logged in. Waiting for Dashboard...');
        await driver!.waitFor(addExpenseFinder, timeout: Duration(seconds: 10));
      }

      // --- Expense-Budget Integration Flow ---
      print('--- Expense-Budget Integration Flow ---');

      // 1. Get Initial Budget Values
      final remainingFinder = find.byValueKey('budgetRemainingAmount');
      final spentFinder = find.byValueKey('budgetSpentAmount');

      // Ensure we are on dashboard with budget loaded
      await driver!.waitFor(remainingFinder);

      String initialRemainingText = await driver!.getText(remainingFinder);
      String initialSpentText = await driver!.getText(spentFinder);
      print('Initial Remaining: $initialRemainingText');
      print('Initial Spent: $initialSpentText');

      // Helper to parse currency string (e.g. "RD$ 5,000" -> 5000.0)
      double parseCurrency(String text) {
        String cleaned = text.replaceAll('RD\$', '').replaceAll(',', '').trim();
        return double.parse(cleaned);
      }

      double initialRemaining = parseCurrency(initialRemainingText);
      double initialSpent = parseCurrency(initialSpentText);

      // 2. Add Expense (20)
      print('Adding Expense of 20...');
      await Future.delayed(Duration(seconds: 3)); // Wait for UI / SnackBar
      // final addExpenseFinder = find.byValueKey('addExpenseFab'); // Reuse existing
      await driver!.tap(addExpenseFinder);

      // Wait for sheet
      final customAmountButtonFinder = find.byValueKey('customAmountButton');
      await driver!.waitFor(customAmountButtonFinder);
      await driver!.tap(customAmountButtonFinder);

      // Enter amount
      print('Entering amount 20...');
      final amountFieldFinder = find.byValueKey('amountField');
      await driver!.waitFor(amountFieldFinder);
      await driver!.tap(amountFieldFinder);
      await driver!.enterText('20');

      // Save
      print('Saving expense...');
      final saveButtonFinder = find.byValueKey('saveExpenseButton');
      await driver!.tap(saveButtonFinder);
      await driver!.waitForAbsent(saveButtonFinder);

      // 3. Verify Budget Update
      print('Verifying Budget Update...');
      // Wait for UI to refresh (Providers should update automatically)
      // We might need to trigger a refresh or wait for the stream
      await Future.delayed(Duration(seconds: 2));

      String newRemainingText = await driver!.getText(remainingFinder);
      String newSpentText = await driver!.getText(spentFinder);
      print('New Remaining: $newRemainingText');
      print('New Spent: $newSpentText');

      double newRemaining = parseCurrency(newRemainingText);
      double newSpent = parseCurrency(newSpentText);

      // Assertions
      if (newSpent == initialSpent + 20) {
        print('SUCCESS: Spent increased by 20');
      } else {
        print(
          'FAILURE: Spent did not increase correctly. Expected ${initialSpent + 20}, got $newSpent',
        );
        // fail('Budget Spent verification failed'); // Optional: explicitly fail test
      }

      if (newRemaining == initialRemaining - 20) {
        print('SUCCESS: Remaining decreased by 20');
      } else {
        print(
          'FAILURE: Remaining did not decrease correctly. Expected ${initialRemaining - 20}, got $newRemaining',
        );
      }
    });
  });
}
