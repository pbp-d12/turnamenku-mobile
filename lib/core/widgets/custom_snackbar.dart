import 'package:flutter/material.dart';

enum SnackbarStatus { success, error, info }

class CustomSnackbar {
  static void show(
    BuildContext context,
    String message,
    SnackbarStatus status,
  ) {
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case SnackbarStatus.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        break;
      case SnackbarStatus.error:
        backgroundColor = Colors.red.shade600;
        icon = Icons.error_outline;
        break;
      case SnackbarStatus.info:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
