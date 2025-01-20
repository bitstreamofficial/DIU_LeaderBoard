// lib/services/connection_handler.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionHandler {
  static final ConnectionHandler _instance = ConnectionHandler._internal();
  factory ConnectionHandler() => _instance;
  ConnectionHandler._internal();

  StreamSubscription? connectivitySubscription;
  bool isDialogShowing = false;

  void initialize(BuildContext context) {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        showNoInternetDialog(context);
      } else {
        // If internet is restored and dialog is showing, dismiss it
        if (isDialogShowing && context.mounted) {
          Navigator.of(context).pop();
          isDialogShowing = false;
        }
      }
    });
  }

  Future<bool> checkInternet() async {
    final results = await Connectivity().checkConnectivity();
    return results != ConnectivityResult.none;
  }

  void showNoInternetDialog(BuildContext context) {
    if (!isDialogShowing && context.mounted) {
      isDialogShowing = true;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF262626),
              title: const Row(
                children: [
                  Icon(
                    Icons.signal_wifi_off, 
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No Internet Connection',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: const Text(
                'Please check your internet connection and try again.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () async {
                    if (await checkInternet()) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        isDialogShowing = false;
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        isDialogShowing = false;
                        // Show the dialog again after a brief delay
                          showNoInternetDialog(context);
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void dispose() {
    connectivitySubscription?.cancel();
  }
}