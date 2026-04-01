import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_theme.dart';
import 'utils/navigator_key.dart';
import 'intro_page.dart';
import 'Dashboard.dart';
import 'Suppliers/supp_dashboard.dart';
import 'widgets/subscription_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('❌ Firebase Initialization Error: $e');
    debugPrint('Ensure google-services.json is in android/app/');
  }

  // Set background messaging handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'GlowVita Salon CRM',
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          theme: AppTheme.lightTheme,
          builder: (context, materialChild) {
            // Check if we should show the global banner
            // We'll use a simple approach: if not My Profile, show it.
            return Scaffold(
              body: Column(
                children: [
                  // This will be above the Navigator, pushing everything down
                  // It will be visible on all pages except we can't easily filter here
                  // BUT the user said "dont disable the profile page and put that error msg... after the appbar"
                  // If we put it here, it's BEFORE the appbar.
                  Expanded(child: materialChild!),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('user_role');

    Timer(const Duration(seconds: 5), () {
      if (token != null && token.isNotEmpty) {
        if (role == 'supplier') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'Supplier Dashboard'),
              builder: (_) => const Supp_DashboardPage(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'Dashboard'),
              builder: (_) => const DashboardPage(),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'Intro'),
            builder: (context) => const IntroPage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/splash_screen.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 1,
            left: 1,
            child: Image.asset(
              'assets/images/splash_img.png',
              width: screenSize.width * 0.50,
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: screenSize.width * 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
