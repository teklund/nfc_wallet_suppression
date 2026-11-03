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
    expect(
      find.textContaining('suppressed: the wallet stays hidden'),
      findsOne,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(fake.methodCalls.last, 'releaseSuppression');
  });

  testWidgets('shows a request held while NFC is off', (tester) async {
    fake.requestResult = const SuppressionResult(
      status: SuppressionStatus.nfcDisabled,
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Show ticket'));
    await tester.pumpAndSettle();

    expect(find.textContaining('starts by itself'), findsOne);
  });
}
