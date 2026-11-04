import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/testing.dart';
import 'package:nfc_wallet_suppression_example/main.dart';

void main() {
  late FakeNfcWalletSuppression fake;

  setUp(() {
    fake = FakeNfcWalletSuppression();
    NfcWalletSuppressionPlatform.instance = fake;
  });

  testWidgets('the ticket requests suppression when shown and releases it '
      'when closed', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(fake.methodCalls, ['isSupported']);

    await tester.tap(find.text('Show ticket'));
    await tester.pumpAndSettle();
    expect(fake.methodCalls, [
      'isSupported',
      'requestSuppression',
      'isSuppressed',
    ]);
    expect(find.textContaining('suppressed: held'), findsOne);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(fake.methodCalls, [
      'isSupported',
      'requestSuppression',
      'isSuppressed',
      'releaseSuppression',
    ]);
  });

  testWidgets('reopening the ticket while the old one is still closing keeps '
      'suppression held', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Show ticket'));
    await tester.pumpAndSettle();

    // The closing ticket is disposed only after its exit animation, after the
    // new ticket has made its request.
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Show ticket'));
    await tester.pumpAndSettle();

    expect(find.byType(TicketScreen), findsOne);
    expect(fake.methodCalls, isNot(contains('releaseSuppression')));
    expect(fake.suppressed, isTrue);
  });

  testWidgets('an unsupported device is not offered suppression, but the '
      'ticket still opens', (tester) async {
    fake.supported = false;
    fake.requestResult = const SuppressionResult(
      status: SuppressionStatus.notSupported,
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.textContaining("This device can't keep it"), findsOne);
    expect(find.textContaining('Open the ticket'), findsNothing);

    await tester.tap(find.text('Show ticket'));
    await tester.pumpAndSettle();
    expect(find.byType(TicketScreen), findsOne);
  });

  // A status added later fails here until the example explains it.
  const explanations = {
    SuppressionStatus.suppressed: 'held.',
    SuppressionStatus.nfcDisabled: 'NFC is off.',
    SuppressionStatus.notSupported: "this device can't suppress",
    SuppressionStatus.denied: 'refused.',
    SuppressionStatus.unknown: 'the outcome is unclear',
    SuppressionStatus.unavailable: 'not suppressed: no Activity is attached',
    SuppressionStatus.canceled: 'not suppressed.',
    SuppressionStatus.alreadyPresenting: 'not suppressed.',
    SuppressionStatus.notSuppressed: 'not suppressed.',
  };
  for (final status in SuppressionStatus.values) {
    testWidgets('explains ${status.name}', (tester) async {
      fake.requestResult = SuppressionResult(status: status);
      await tester.pumpWidget(const ExampleApp());
      await tester.tap(find.text('Show ticket'));
      await tester.pumpAndSettle();

      final text = explanations[status];
      expect(text, isNotNull, reason: 'No explanation for $status');
      expect(find.textContaining('${status.name}: $text'), findsOne);
    });
  }
}
