// services/app_update_service.dart
//
// Conditional export:
// - Android/iOS/desktop compilation uses the native implementation.
// - Flutter Web uses a no-op implementation.
//
// This prevents the Android-only in_app_update plugin from being imported
// into the web compilation unit.

export 'app_update_service_web.dart'
    if (dart.library.io) 'app_update_service_mobile.dart';
