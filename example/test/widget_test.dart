import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/testing.dart';
import 'package:nfc_wallet_suppression_example/main.dart';

void main() {
  late FakeNfcWalletSuppression fake;

  setUp(() {
    fake = FakeNfcWalletSuppression();
    NfcWalletSuppressionPlatform.instance = fake;
  });

  testWidgets('the suppression screen requests suppression when shown and '
      'releases it when closed', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(fake.methodCalls, ['isSupported', 'isSuppressed']);

    await tester.tap(find.text('Open Suppression Screen'));
    await tester.pumpAndSettle();
    expect(fake.methodCalls, [
      'isSupported',
      'isSuppressed',
      'requestSuppression',
    ]);
    expect(find.text('request → suppressed'), findsOne);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(fake.methodCalls, [
      'isSupported',
      'isSuppressed',
      'requestSuppression',
      'releaseSuppression',
      'isSuppressed',
    ]);
  });

  testWidgets('closing the suppression screen ends a hold requested on the '
      'home screen, and the home screen shows it', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Suppression'));
    await tester.pumpAndSettle();
    expect(find.text('Suppression in effect'), findsOne);

    await tester.tap(find.text('Open Suppression Screen'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final calls = fake.methodCalls;
    expect(calls.sublist(calls.length - 2), [
      'releaseSuppression',
      'isSuppressed',
    ]);
    expect(find.text('Suppression not in effect'), findsOne);
    expect(find.textContaining('after the suppression screen'), findsOne);
  });

  testWidgets('reopening the suppression screen while the old one is still '
      'closing keeps suppression held', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Open Suppression Screen'));
    await tester.pumpAndSettle();

    // The closing screen is disposed only after its exit animation, after the
    // new one has made its request.
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Open Suppression Screen'));
    await tester.pumpAndSettle();

    expect(find.byType(SuppressionScreen), findsOne);
    expect(fake.methodCalls, isNot(contains('releaseSuppression')));
    expect(fake.suppressed, isTrue);
  });

  testWidgets('an unsupported device says so, but the suppression screen '
      'still opens', (tester) async {
    fake.supported = false;
    fake.requestResult = const SuppressionResult(
      status: SuppressionStatus.notSupported,
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Not supported on this device'), findsOne);
    final request = find.widgetWithText(FilledButton, 'Request Suppression');
    expect(tester.widget<FilledButton>(request).onPressed, isNull);

    await tester.tap(find.text('Open Suppression Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(SuppressionScreen), findsOne);
  });

  testWidgets('request and release show their results and check again', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Supported on this device'), findsOne);
    expect(find.text('No call yet'), findsOne);
    expect(find.text('Suppression not in effect'), findsOne);

    await tester.tap(find.text('Request Suppression'));
    await tester.pumpAndSettle();
    expect(find.text('request → suppressed'), findsOne);
    expect(find.textContaining('Held.'), findsOne);
    expect(find.text('Suppression in effect'), findsOne);
    expect(find.textContaining('after request'), findsOne);

    await tester.tap(find.text('Release Suppression'));
    await tester.pumpAndSettle();
    expect(find.text('release → notSuppressed'), findsOne);
    expect(find.text('Suppression not in effect'), findsOne);
    expect(find.textContaining('after release'), findsOne);
  });

  testWidgets('shows the diagnostic', (tester) async {
    fake.requestResult = const SuppressionResult(
      status: SuppressionStatus.nfcDisabled,
      description: 'NFC adapter is disabled',
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Suppression'));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostic: NFC adapter is disabled'), findsOne);
  });

  Future<void> returnToForeground(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('checks again when the app returns to the foreground', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Suppression not in effect'), findsOne);

    // The hold resumed while the app was away.
    fake.suppressed = true;
    await returnToForeground(tester);
    expect(find.text('Suppression in effect'), findsOne);
    expect(find.textContaining('on return'), findsOne);
  });

  testWidgets('the shield follows the check, not the last call', (
    tester,
  ) async {
    fake.requestResult = const SuppressionResult(
      status: SuppressionStatus.nfcDisabled,
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Suppression'));
    await tester.pumpAndSettle();
    // Held, but not in effect while NFC is off.
    expect(find.text('Suppression not in effect'), findsOne);
    expect(find.byIcon(Icons.shield), findsNothing);

    // NFC was switched on while the app was away.
    fake.suppressed = true;
    await returnToForeground(tester);
    expect(find.text('Suppression in effect'), findsOne);
    expect(find.byIcon(Icons.shield), findsOne);
  });

  // A status added later fails here until the example explains it.
  const explanations = {
    SuppressionStatus.suppressed: 'Held.',
    SuppressionStatus.nfcDisabled: 'NFC was off.',
    SuppressionStatus.notSupported: "This device can't suppress",
    SuppressionStatus.denied: 'Refused.',
    SuppressionStatus.unknown: 'The outcome is unclear',
    SuppressionStatus.unavailable: 'Not suppressed: no Activity was attached',
    SuppressionStatus.canceled: 'Not suppressed.',
    SuppressionStatus.alreadyPresenting: 'Not suppressed.',
    SuppressionStatus.notSuppressed: 'Not suppressed.',
  };
  for (final status in SuppressionStatus.values) {
    testWidgets('explains ${status.name}', (tester) async {
      fake.requestResult = SuppressionResult(status: status);
      await tester.pumpWidget(const ExampleApp());
      await tester.tap(find.text('Open Suppression Screen'));
      await tester.pumpAndSettle();

      final text = explanations[status];
      expect(text, isNotNull, reason: 'No explanation for $status');
      expect(find.text('request → ${status.name}'), findsOne);
      expect(find.textContaining(text!), findsOne);
    });
  }
}
