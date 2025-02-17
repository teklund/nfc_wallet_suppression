import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool _isSupressing = false;
  String? _error;

  final _nfcWalletSuppressionPlugin = NfcWalletSuppression();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _nfcWalletSuppressionPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _onRequestSuppression() async {
    var result = await NfcWalletSuppression().requestSuppression();
    if (result == true) {
      setState(() {
        _error = null;
        _isSupressing = true;
      });
    } else {
      setState(() {
        _error = 'Error requesting suppression';
      });
    }
  }

  Future<void> _onReleaseSuppression() async {
    var result = await NfcWalletSuppression().releaseSuppression();
    if (result == true) {
      setState(() {
        _error = null;
        _isSupressing = false;
      });
    } else {
      setState(() {
        _error = 'Error releasing suppression';
      });
    }
  }

  Future<void> _checkIsSuppressed() async {
    var result = await NfcWalletSuppression().isSuppressed();
    if (result != null) {
      setState(() {
        _error = null;
        _isSupressing = result;
      });
    } else {
      setState(() {
        _error = 'Error checking suppression status';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String suppressionStatus = _isSupressing ? 'Suppressed' : 'Not suppressed';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text('Running on: $_platformVersion'),
              Text('Suppression status: $suppressionStatus\n${_error ?? ''}'),
              FilledButton(onPressed: _onRequestSuppression, child: Text('Request suppression')),
              FilledButton(onPressed: _onReleaseSuppression, child: Text('Release suppression')),
              FilledButton(onPressed: _checkIsSuppressed, child: Text('Check suppression')),
            ],
          ),
        ),
      ),
    );
  }
}
