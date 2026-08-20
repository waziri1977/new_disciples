// services/app_update_service_web.dart

import 'package:flutter/material.dart';

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    // Flutter Web has no Google Play in-app update flow.
    // Web deployments receive the newest application files from the server.
    return;
  }
}
