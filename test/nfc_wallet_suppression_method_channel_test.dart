import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNfcWalletSuppression platform =
      MethodChannelNfcWalletSuppression();
  const MethodChannel channel = MethodChannel('nfc_wallet_suppression');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return false;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isSuppressed_returnsFalse', () async {
    expect(await platform.isSuppressed(), isFalse);
  });

  test('isSuppressed_returnsTrue', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return true;
    });
    expect(await platform.isSuppressed(), isTrue);
  });

  test('isSuppressed_handlesNull', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
    expect(await platform.isSuppressed(), isFalse);
  });

  test('requestSuppression_returnsSuppressedOnSuccess', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return 'Success';
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.suppressed);
  });

  test('requestSuppression_handlesNotSupportedError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'NOT_SUPPORTED');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.notSupported);
  });

  test('requestSuppression_handlesAlreadyPresentingError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'ALREADY_PRESENTING');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.alreadyPresenting);
  });

  test('requestSuppression_handlesCancelledError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'CANCELLED');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.cancelled);
  });

  test('requestSuppression_handlesDeniedError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'DENIED');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.denied);
  });

  test('requestSuppression_handlesUnavailableError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'UNAVAILABLE');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.unavailable);
  });

  test('requestSuppression_handlesUnknownError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'UNKNOWN');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.unknown);
  });

  test('requestSuppression_handlesUnexpectedErrorCode', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'UNEXPECTED_CODE');
    });
    final status = await platform.requestSuppression();
    expect(status, SuppressionStatus.unknown);
  });

  test('releaseSuppression_returnsNotSuppressedOnSuccess', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return 'Success';
    });
    final status = await platform.releaseSuppression();
    expect(status, SuppressionStatus.notSuppressed);
  });

  test('releaseSuppression_handlesNotSupportedError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'NOT_SUPPORTED');
    });
    final status = await platform.releaseSuppression();
    expect(status, SuppressionStatus.notSupported);
  });

  test('releaseSuppression_handlesUnavailableError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'UNAVAILABLE');
    });
    final status = await platform.releaseSuppression();
    expect(status, SuppressionStatus.unavailable);
  });

  test('releaseSuppression_handlesUnknownError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'UNKNOWN');
    });
    final status = await platform.releaseSuppression();
    expect(status, SuppressionStatus.unknown);
  });
}
