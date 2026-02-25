import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'intro_page.dart';
import 'calender.dart';
import 'Suppliers/supp_dashboard.dart';

void main() {
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
          title: 'GlowVita Salon CRM',
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          theme: AppTheme.lightTheme,
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
            MaterialPageRoute(builder: (_) => const Supp_DashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Calendar()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroPage()),
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
