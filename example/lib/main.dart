import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Wallet Suppression',
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

/// Calls the API directly, for trying it on a device, and opens the
/// suppression screen: the pattern to copy.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycle;
  bool? _isSupported;
  String? _lastCall;
  SuppressionResult? _result;
  bool? _isInEffect;

  /// When and why [_isInEffect] was last checked.
  String _checked = '';

  @override
  void initState() {
    super.initState();
    // Display only: a hold resumes by itself, so there is nothing to request
    // again.
    _lifecycle = AppLifecycleListener(onResume: () => _check('on return'));
    _checkSupport();
    _check('on start');
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// A snapshot: whether suppression is in effect right now.
  Future<void> _check(String when) async {
    final isInEffect = await NfcWalletSuppression.isSuppressed();
    if (!mounted) return;
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _isInEffect = isInEffect;
      _checked = '$time, $when';
    });
  }

  Future<void> _checkSupport() async {
    final isSupported = await NfcWalletSuppression.isSupported();
    if (!mounted) return;
    setState(() => _isSupported = isSupported);
  }

  Future<void> _call(
    String name,
    Future<SuppressionResult> Function() call,
  ) async {
    final result = await call();
    if (!mounted) return;
    setState(() {
      _lastCall = name;
      _result = result;
    });
    await _check('after $name');
  }

  Future<void> _openSuppressionScreen() async {
    final route = MaterialPageRoute<void>(
      builder: (_) => const SuppressionScreen(),
    );
    unawaited(Navigator.of(context).push(route));
    // Its release ends any hold, including one requested here. Completes once
    // the screen is gone, so after that release.
    await route.completed;
    await _check('after the suppression screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Wallet Suppression'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SupportCard(isSupported: _isSupported),
          const SizedBox(height: 16),
          StatusCard(
            call: _lastCall,
            result: _result,
            isInEffect: _isInEffect,
            checked: _checked,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            // Offer suppression only where it can be attempted.
            onPressed: _isSupported != true
                ? null
                : () =>
                      _call('request', NfcWalletSuppression.requestSuppression),
            icon: const Icon(Icons.block),
            label: const Text('Request Suppression'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () =>
                _call('release', NfcWalletSuppression.releaseSuppression),
            icon: const Icon(Icons.nfc),
            label: const Text('Release Suppression'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _check('by you'),
            icon: const Icon(Icons.refresh),
            label: const Text('Check Status'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openSuppressionScreen,
            icon: const Icon(Icons.contactless_outlined),
            label: const Text('Open Suppression Screen'),
          ),
          const SizedBox(height: 24),
          Text(
            'Keeps Apple Wallet (Apple Pay) and other wallet apps from popping '
            'up at NFC readers while this app is in the foreground. It does '
            'not read or write NFC tags.\n\n'
            'The buttons call the plugin directly; one release ends any hold. '
            'The suppression screen shows the pattern to copy: suppression '
            'only while a screen is open.\n\n'
            'iOS: PassKit automatic pass presentation suppression (needs an '
            'Apple entitlement).\n'
            'Android: NFC reader mode (needs NFC hardware).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Holds suppression while at least one screen that needs it is open.
///
/// Screens overlap during route transitions: a closing screen is disposed
/// only after its exit animation, so its release can arrive after the next
/// screen's request. One release ends the hold, so only the last screen to
/// close may release.
abstract final class WalletSuppression {
  static int _screens = 0;

  static Future<SuppressionResult> acquire() {
    _screens++;
    return NfcWalletSuppression.requestSuppression();
  }

  static void release() {
    _screens--;
    if (_screens == 0) unawaited(NfcWalletSuppression.releaseSuppression());
  }
}

/// The screen shown at the reader. Suppression is requested when it appears
/// and released, through [WalletSuppression], when the last one closes.
class SuppressionScreen extends StatefulWidget {
  const SuppressionScreen({super.key});

  @override
  State<SuppressionScreen> createState() => _SuppressionScreenState();
}

class _SuppressionScreenState extends State<SuppressionScreen> {
  SuppressionResult? _result;

  @override
  void initState() {
    super.initState();
    // Request when the screen appears, not when the user reaches the reader:
    // on iOS, suppression starts only once the request completes.
    _request();
  }

  @override
  void dispose() {
    // Whatever the request returned: release is idempotent.
    WalletSuppression.release();
    super.dispose();
  }

  Future<void> _request() async {
    final result = await WalletSuppression.acquire();
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppression Screen'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(
            Icons.contactless_outlined,
            size: 96,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Hold the phone to the reader. The wallet should not appear while '
            'this screen is open.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            result == null ? 'Requesting…' : 'request → ${result.status.name}',
            textAlign: TextAlign.center,
          ),
          if (result != null)
            Text(explain(result.status), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Whether [NfcWalletSuppression.isSupported] says suppression can be
/// attempted on this device.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key, required this.isSupported});

  final bool? isSupported;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (isSupported) {
      null => const Card(child: ListTile(title: Text('Checking support…'))),
      true => Card(
        color: colors.primaryContainer,
        child: ListTile(
          iconColor: colors.onPrimaryContainer,
          textColor: colors.onPrimaryContainer,
          leading: const Icon(Icons.check_circle),
          title: const Text('Supported on this device'),
        ),
      ),
      false => Card(
        color: colors.errorContainer,
        child: ListTile(
          iconColor: colors.onErrorContainer,
          textColor: colors.onErrorContainer,
          leading: const Icon(Icons.warning_amber),
          title: const Text('Not supported on this device'),
          subtitle: const Text(
            'Android needs NFC hardware; iOS needs the Wallet pass library.',
          ),
        ),
      ),
    };
  }
}

/// Whether suppression was in effect at the last check, and the last call's
/// result.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    this.call,
    this.result,
    this.isInEffect,
    this.checked = '',
  });

  /// The call that returned [result]: `request` or `release`.
  final String? call;
  final SuppressionResult? result;
  final bool? isInEffect;

  /// When and why [isInEffect] was checked, if shown.
  final String checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final result = this.result;
    final isInEffect = this.isInEffect;
    // From the check, not the last call: a held request is not always in
    // effect.
    final isOn = isInEffect ?? false;
    final details = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text('Current Status', style: theme.textTheme.titleMedium),
            Row(
              spacing: 8,
              children: [
                Icon(
                  isOn ? Icons.shield : Icons.shield_outlined,
                  color: isOn ? colors.primary : colors.onSurfaceVariant,
                ),
                Flexible(
                  child: Text(
                    switch (isInEffect) {
                      null => 'Checking…',
                      true => 'Suppression in effect',
                      false => 'Suppression not in effect',
                    },
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isOn ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (checked.isNotEmpty) Text('Checked $checked', style: details),
            const Divider(height: 16),
            Text('Last call', style: theme.textTheme.titleSmall),
            Text(
              result == null ? 'No call yet' : '$call → ${result.status.name}',
            ),
            // The explanations are written for request results.
            if (result != null && call == 'request')
              Text(explain(result.status)),
            // The platform's own text, for logs. Not user-facing copy, and its
            // wording is not part of the API.
            if (result?.description case final description?)
              Text('Diagnostic: $description', style: details),
          ],
        ),
      ),
    );
  }
}

/// What a request's [status] means here.
String explain(SuppressionStatus status) {
  return switch (status) {
    SuppressionStatus.suppressed =>
      'Held. It pauses in the background and resumes by itself.',
    SuppressionStatus.nfcDisabled =>
      'NFC was off. Suppression starts by itself once it is switched on.',
    SuppressionStatus.notSupported => "This device can't suppress the wallet.",
    SuppressionStatus.denied =>
      'Refused. On iOS this usually means a missing suppression '
          'entitlement, or Wallet was showing a pass.',
    SuppressionStatus.unknown =>
      'The outcome is unclear; Check Status on the home screen shows whether '
          'it took effect.',
    SuppressionStatus.unavailable =>
      'Not suppressed: no Activity was attached.',
    // New statuses may be added, so always keep a fallback.
    _ => 'Not suppressed.',
  };
}
