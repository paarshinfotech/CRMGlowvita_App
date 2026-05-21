import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import '../utils/navigator_key.dart';
import '../register.dart';
import '../Suppliers/supp_register.dart';

class ReferralController extends ChangeNotifier {
  // Singleton instance
  static final ReferralController _instance = ReferralController._internal();
  factory ReferralController() => _instance;
  ReferralController._internal();

  final _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  String? _capturedReferralCode;
  String? _capturedRole;

  void init() {
    // 1. Handle app launch from a link click (App was closed)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // 2. Stream links if the app is already open in the background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // 3. Fallback for new installations (Install Referrer)
    _initReferrer();
  }

  Future<void> _initReferrer() async {
    // Install referrer only works on Android devices
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android)) return;

    try {
      // Query the Play Store API for installation details
      ReferrerDetails details =
          await AndroidPlayInstallReferrer.installReferrer;

      if (details.installReferrer != null &&
          details.installReferrer!.isNotEmpty) {
        final referrer = details.installReferrer!;
        debugPrint('Play Store Install Referrer: $referrer');
        // e.g., "ref=CODE123&role=vendor" or url encoded "ref%3DCODE123%26role%3Dvendor"

        // Decode in case it's URL encoded
        final decodedReferrer = Uri.decodeComponent(referrer);

        _extractDataFromReferrer(decodedReferrer);
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get install referrer: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');

    // Support either uri query parameters directly (e.g. ?code=X&role=Y)
    // or referrer format if it's passed somehow
    if (uri.queryParameters.containsKey('ref') ||
        uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['ref'] ?? uri.queryParameters['code'];
      final role = uri.queryParameters['role'];

      if (code != null) {
        _capturedReferralCode = code;
        _capturedRole = role;
        _navigateToRegistration();
      }
    }
  }

  void _extractDataFromReferrer(String referrerString) {
    // Expected format: ref=XYZ&role=vendor
    try {
      final uri = Uri.parse('http://dummy.com/path?$referrerString');
      final code = uri.queryParameters['ref'];
      final role = uri.queryParameters['role'];

      if (code != null && code.isNotEmpty) {
        _capturedReferralCode = code;
        _capturedRole = role;

        // Use a short delay to ensure UI is mounted if called during startup
        Future.delayed(const Duration(seconds: 2), () {
          _navigateToRegistration();
        });
      }
    } catch (e) {
      debugPrint('Error parsing referrer string: $e');
    }
  }

  void _navigateToRegistration() {
    if (navigatorKey.currentState == null) return;
    if (_capturedReferralCode == null) return;

    final context = navigatorKey.currentState!.context;
    final String role = _capturedRole?.toLowerCase() ?? '';
    final String code = _capturedReferralCode!;

    if (role == 'supplier') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SupplierRegisterPage(initialReferralCode: code),
        ),
      );
    } else {
      // Default to vendor registration
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterPage(initialReferralCode: code),
        ),
      );
    }

    // Clear after navigation
    _capturedReferralCode = null;
    _capturedRole = null;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
