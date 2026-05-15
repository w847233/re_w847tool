import 'package:flutter/material.dart';

extension LatestSnackBarMessenger on ScaffoldMessengerState {
  void showLatestSnackBar(SnackBar snackBar) {
    clearSnackBars();
    removeCurrentSnackBar();
    showSnackBar(snackBar);
  }

  void showLatestSnackMessage(String message, {Color? backgroundColor}) {
    showLatestSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}
