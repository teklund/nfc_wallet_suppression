import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  SuppressionStatus _suppressionStatus = SuppressionStatus.notSuppressed;
  String? _error;
  bool _isLoading = false;
  bool _isSupported = false;

  // Track if we should try to restore suppression when app resumes
  bool _shouldRestoreSuppression = true;
  // Track if suppression was active before we were backgrounded
  bool _wasSuppressedBeforeBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background
      _wasSuppressedBeforeBackground =
          _suppressionStatus == SuppressionStatus.suppressed;
    } else if (state == AppLifecycleState.resumed) {
      // App is returning to foreground
      if (_shouldRestoreSuppression && _wasSuppressedBeforeBackground) {
        _restoreSuppression();
      }
    }
  }

  Future<void> _restoreSuppression() async {
    // Only attempt if supported
    if (!_isSupported) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring NFC suppression...')),
    );

    await _onRequestSuppression();
  }

  Future<void> initPlatformState() async {
    try {
      // Check platform support first
      final supported = await NfcWalletSuppression.isSupported();

      if (!mounted) return;

      // If supported, check current status
      if (supported) {
        final isSuppressed = await NfcWalletSuppression.isSuppressed();
        setState(() {
          _isSupported = supported;
          _suppressionStatus = isSuppressed
              ? SuppressionStatus.suppressed
              : SuppressionStatus.notSuppressed;
        });
      } else {
        setState(() {
          _isSupported = supported;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Initialization error: $error';
      });
    }
  }

  Future<void> _onRequestSuppression() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await NfcWalletSuppression.requestSuppression();
      if (!mounted) return;
      setState(() {
        _suppressionStatus = result;
        _isLoading = false;
      });
    } catch (error, _) {
      if (!mounted) return;
      setState(() {
        _error = 'Error requesting suppression: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _onReleaseSuppression() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await NfcWalletSuppression.releaseSuppression();
      if (!mounted) return;
      setState(() {
        _suppressionStatus = result;
        _isLoading = false;
      });
    } catch (error, _) {
      if (!mounted) return;
      setState(() {
        _error = 'Error releasing suppression: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIsSuppressed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await NfcWalletSuppression.isSuppressed();
      if (!mounted) return;
      setState(() {
        _suppressionStatus = result
            ? SuppressionStatus.suppressed
            : SuppressionStatus.notSuppressed;
        _isLoading = false;
      });
    } catch (error, _) {
      if (!mounted) return;
      setState(() {
        _error = 'Error checking suppression status: $error';
        _isLoading = false;
      });
    }
  }

  Widget _buildPlatformInfo() {
    if (!_isSupported) {
      return const Card(
        margin: EdgeInsets.all(16),
        color: Colors.orange,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Platform not supported',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'This device does not support NFC wallet suppression.\n'
                'iOS requires 12.0+ and iPhone 7+.\n'
                'Android requires NFC hardware.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Platform supported',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54),
            SwitchListTile(
              title: const Text('Auto-restore on resume',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Best practice for seamless UX',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              value: _shouldRestoreSuppression,
              onChanged: (value) =>
                  setState(() => _shouldRestoreSuppression = value),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.green.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = _suppressionStatus == SuppressionStatus.suppressed
        ? Colors.blue
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    _suppressionStatus == SuppressionStatus.suppressed
                        ? Icons.block
                        : Icons.nfc,
                    color: color),
                const SizedBox(width: 8),
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _suppressionStatus.name,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('NFC Wallet Suppression'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPlatformInfo(),
                _buildStatusCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _isLoading || !_isSupported
                            ? null
                            : _onRequestSuppression,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.block),
                        label: const Text('Request Suppression'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _isLoading || !_isSupported
                            ? null
                            : _onReleaseSuppression,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.nfc),
                        label: const Text('Release Suppression'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _checkIsSuppressed,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check Status'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'About NFC Wallet Suppression:\n\n'
                    'This plugin temporarily disables Apple Pay and Google Pay '
                    'during NFC tag reading to prevent wallet apps from interfering '
                    'with your app\'s NFC operations.\n\n'
                    'iOS: Uses PKPassLibrary (requires iOS 12.0+, iPhone 7+)\n'
                    'Android: Uses NFC Reader Mode (requires API 21+, NFC hardware)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
