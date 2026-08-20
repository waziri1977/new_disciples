// services/app_update_service_mobile.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    // in_app_update is Google Play / Android specific.
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final AppUpdateInfo updateInfo =
          await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (!context.mounted) return;

        _showUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Available',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'A new version of New Disciples is available. '
            'Please update now to get the latest features '
            'and improvements.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('LATER'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  await InAppUpdate.performImmediateUpdate();
                } catch (e) {
                  debugPrint('Update failed: $e');
                }
              },
              child: const Text('UPDATE NOW'),
            ),
          ],
        );
      },
    );
  }
}
