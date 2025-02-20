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

class _MyAppState extends State<MyApp> {
  SuppressionStatus _suppressionStatus = SuppressionStatus.notSuppressed;
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
    try {
      var result = await NfcWalletSuppression.requestSuppression();
      if (!mounted) return;
      setState(() {
        _error = null;
        _suppressionStatus = result;
      });
    } catch (error, _) {
      setState(() {
        _error = 'Error requesting suppression: $error';
      });
    }
  }

  Future<void> _onReleaseSuppression() async {
    try {
      var result = await NfcWalletSuppression.releaseSuppression();
      if (!mounted) return;
      setState(() {
        _error = null;
        _suppressionStatus = result;
      });
    } catch (error, _) {
      setState(() {
        _error = 'Error releasing suppression';
      });
    }
  }

  Future<void> _checkIsSuppressed() async {
    try {
      var result = await NfcWalletSuppression.isSuppressed();
      if (!mounted) return;
      setState(() {
        _error = null;
        _suppressionStatus =
            result
                ? SuppressionStatus.suppressed
                : SuppressionStatus.notSuppressed;
      });
    } catch (error, _) {
      setState(() {
        _error = 'Error checking suppression status: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                'Suppression status: ${_suppressionStatus.name}\n${_error ?? ''}',
              ),
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
