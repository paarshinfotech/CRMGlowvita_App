import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io';

class InAppUpdateService {
  static Future<void> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          final status = await InAppUpdate.startFlexibleUpdate();
          if (status == AppUpdateResult.success) {
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }
}
