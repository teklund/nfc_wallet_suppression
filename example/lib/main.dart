import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NFC Wallet Suppression',
      home: HomeScreen(),
    );
  }
}

/// A screen that doesn't need suppression: the wallet works as usual here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _isSupported;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final isSupported = await NfcWalletSuppression.isSupported();
    if (!mounted) return;
    setState(() => _isSupported = isSupported);
  }

  @override
  Widget build(BuildContext context) {
    final isSupported = _isSupported;
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Wallet Suppression')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'The wallet works as usual on this screen. Open the ticket to keep '
            'it from popping up at NFC readers while the ticket is shown.',
          ),
          const SizedBox(height: 8),
          Text(
            'Supported on this device: '
            '${isSupported == null ? '…' : (isSupported ? 'yes' : 'no')}',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TicketScreen()),
            ),
            child: const Text('Show ticket'),
          ),
        ],
      ),
    );
  }
}

/// The screen shown at the reader. Suppression is requested when it appears
/// and released when it closes.
class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  SuppressionResult? _result;
  bool? _isInEffect;

  @override
  void initState() {
    super.initState();
    // Request when the screen appears, not when the user reaches the reader:
    // on iOS, suppression starts only once the request completes.
    _request();
  }

  @override
  void dispose() {
    // Release whatever the request returned: release is idempotent, and calls
    // run in the order they were made, so there is no need to wait.
    unawaited(NfcWalletSuppression.releaseSuppression());
    super.dispose();
  }

  Future<void> _request() async {
    final result = await NfcWalletSuppression.requestSuppression();
    if (!mounted) return;
    setState(() => _result = result);
    await _checkInEffect();
  }

  /// A snapshot: whether suppression is in effect right now.
  Future<void> _checkInEffect() async {
    final isInEffect = await NfcWalletSuppression.isSuppressed();
    if (!mounted) return;
    setState(() => _isInEffect = isInEffect);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isInEffect = _isInEffect;
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Hold the phone to the reader. The wallet should not appear while '
            'this screen is open.',
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Request'),
            subtitle: Text(
              result == null
                  ? 'Requesting…'
                  : '${result.status.name}: ${_explain(result)}',
            ),
          ),
          ListTile(
            title: const Text('In effect at last check'),
            subtitle: Text(
              isInEffect == null ? '…' : (isInEffect ? 'yes' : 'no'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Check again',
              onPressed: _checkInEffect,
            ),
          ),
          // The platform's own text, for logs. Not user-facing copy, and its
          // wording is not part of the API.
          if (result?.description case final description?)
            ListTile(
              title: const Text('Diagnostic'),
              subtitle: Text(description),
            ),
        ],
      ),
    );
  }

  String _explain(SuppressionResult result) {
    return switch (result.status) {
      SuppressionStatus.suppressed => 'the wallet stays hidden at NFC readers.',
      SuppressionStatus.nfcDisabled =>
        'NFC is off. Suppression starts by itself once it is switched on.',
      SuppressionStatus.notSupported =>
        "this device can't suppress the wallet.",
      // New statuses may be added, so always keep a fallback.
      _ =>
        result.isRetryable
            ? 'not suppressed; requesting again may help.'
            : 'not suppressed.',
    };
  }
}
