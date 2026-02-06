import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/app_theme.dart';
import 'login.dart';

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
          title: 'GlowVita',
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
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
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
              width: screenSize.width * 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
