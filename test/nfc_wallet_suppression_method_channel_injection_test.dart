import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_method_channel.dart';

/// Demonstrates custom method channel injection for advanced testing scenarios.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannel Injection Tests', () {
    test('can inject custom method channel', () {
      // Create a custom method channel
      const customChannel = MethodChannel('custom_test_channel');

      // Inject it into the implementation
      final platform =
          MethodChannelNfcWalletSuppression(channel: customChannel);

      // Verify it's using the custom channel
      expect(platform.methodChannel.name, 'custom_test_channel');
    });

    test('custom channel allows isolated testing', () async {
      // Create isolated test channel
      const testChannel = MethodChannel('isolated_test_channel');
      final platform = MethodChannelNfcWalletSuppression(channel: testChannel);

      // Set up mock handler for this specific channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSupported') {
          return true;
        }
        return false;
      });

      // Test with isolated channel
      final isSupported = await platform.isSupported();
      expect(isSupported, isTrue);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
    });

    test('multiple instances can use different channels', () async {
      const channel1 = MethodChannel('channel_1');
      const channel2 = MethodChannel('channel_2');

      final platform1 = MethodChannelNfcWalletSuppression(channel: channel1);
      final platform2 = MethodChannelNfcWalletSuppression(channel: channel2);

      // Set up different behaviors for each channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel1, (MethodCall methodCall) async {
        return true; // channel1 returns true
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel2, (MethodCall methodCall) async {
        return false; // channel2 returns false
      });

      // Verify each instance uses its own channel
      final result1 = await platform1.isSupported();
      final result2 = await platform2.isSupported();

      expect(result1, isTrue);
      expect(result2, isFalse);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel1, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel2, null);
    });

    test('can test method call arguments with custom channel', () async {
      const testChannel = MethodChannel('test_args_channel');
      final platform = MethodChannelNfcWalletSuppression(channel: testChannel);

      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
        capturedCall = methodCall;
        return 'Success';
      });

      await platform.requestSuppression();

      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, 'requestSuppression');
      expect(capturedCall!.arguments, isNull); // No arguments for this method

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
    });

    test('can simulate method call latency', () async {
      const testChannel = MethodChannel('latency_test_channel');
      final platform = MethodChannelNfcWalletSuppression(channel: testChannel);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
        // Simulate network/processing delay
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      final stopwatch = Stopwatch()..start();
      await platform.isSupported();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds,
          greaterThan(90)); // Allow some variance

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
    });

    test('can test exception handling with custom channel', () async {
      const testChannel = MethodChannel('exception_test_channel');
      final platform = MethodChannelNfcWalletSuppression(channel: testChannel);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'TEST_ERROR',
          message: 'Custom test error',
        );
      });

      // isSuppressed should catch the exception and return false
      final result = await platform.isSuppressed();
      expect(result, isFalse);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
    });
  });

  group('Default Channel Behavior', () {
    test('uses default channel when none provided', () {
      final platform = MethodChannelNfcWalletSuppression();
      expect(platform.methodChannel.name, 'nfc_wallet_suppression');
    });
  });
}
