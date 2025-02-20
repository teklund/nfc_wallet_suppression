import 'dart:async';

import 'package:flutter/foundation.dart';
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

class _MyAppState extends State<MyApp> {
  bool _isSuppressed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _checkIsSuppressed();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
      });
    }
  }

  Future<void> _onRequestSuppression() async {
    var result = await NfcWalletSuppression.requestSuppression();
    if (!mounted) return;
    if (result == true) {
      setState(() {
        _error = null;
        _isSuppressed = true;
      });
    } else {
      setState(() {
        _error = 'Error requesting suppression';
      });
    }
  }

  Future<void> _onReleaseSuppression() async {
    var result = await NfcWalletSuppression.releaseSuppression();
    if (!mounted) return;
    if (result == true) {
      setState(() {
        _error = null;
        _isSuppressed = false;
      });
    } else {
      setState(() {
        _error = 'Error releasing suppression';
      });
    }
  }

  Future<void> _checkIsSuppressed() async {
    var result = await NfcWalletSuppression.isSuppressed();
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _error = null;
        _isSuppressed = result;
      });
    } else {
      setState(() {
        _error = 'Error checking suppression status';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String suppressionStatus = _isSuppressed ? 'Suppressed' : 'Not suppressed';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text('Suppression status: $suppressionStatus\n${_error ?? ''}'),
              FilledButton(
                onPressed: _onRequestSuppression,
                child: Text('Request suppression'),
              ),
              FilledButton(
                onPressed: _onReleaseSuppression,
                child: Text('Release suppression'),
              ),
              FilledButton(
                onPressed: _checkIsSuppressed,
                child: Text('Check suppression'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
