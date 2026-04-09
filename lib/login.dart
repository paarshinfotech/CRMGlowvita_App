import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'Dashboard.dart';
import 'register.dart';
import 'Suppliers/supp_dashboard.dart';
import 'Suppliers/supp_register.dart';
import 'services/api_service.dart';
import 'forgot_password.dart';
import 'services/notification_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  static const Color _primary = Color(0xFF3B1F2B);
  static const Color _primaryLight = Color(0xFF5C3347);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final String token = data['access_token'];
        if (token.isEmpty) throw Exception('Token not received from server');

        await prefs.setString('token', token);
        await prefs.setString('user_role', data['role'] ?? 'vendor');
        await prefs.setString('user_id', data['user']['_id'] ?? '');
        await prefs.setString('user_data', jsonEncode(data['user']));

        try {
          String? fcmToken = await NotificationService.getSavedToken();
          if (fcmToken != null) {
            await NotificationService().syncTokenWithServer(fcmToken);
          }
        } catch (e) {
          debugPrint('Notification sync error: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? "Login Successful"),
            backgroundColor: Colors.green,
          ));

          final String role = data['role'];
          if (role == 'vendor') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DashboardPage()));
          } else if (role == 'supplier') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const Supp_DashboardPage()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DashboardPage()));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? "Invalid email or password"),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Network error. Please try again."),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Decorative background circles (Increased sizes) ────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350.w,
              height: 350.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: -50,
            child: Container(
              width: 230.w,
              height: 230.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withOpacity(0.035),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    //    crossAxisAlignment: CrossAxisAlignment.center,
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SizedBox(height: 5.h),

                      // ── Logo ──────────
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 200.w,
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(height: 5.h),

                      // ── Welcome ───────────────────────────
                      Text(
                        'Welcome',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Sign in to continue your GlowVita journey',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 18.h),

                      // ── Email field ───────────────────────
                      _buildField(
                        controller: emailController,
                        hint: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        suffixIcon: Icon(Icons.email_outlined,
                            color: Colors.grey.shade400, size: 14.sp),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter your email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v))
                            return 'Enter a valid email address';
                          return null;
                        },
                      ),

                      SizedBox(height: 10.h),

                      // ── Password field ────────────────────
                      _buildField(
                        controller: passwordController,
                        hint: 'Password',
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade400,
                            size: 14.sp,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter your password';
                          if (v.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),

                      // ── Forgot password ───────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage()),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4.h),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700, // Changed to Blue
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // ── Login button (Reduced size) ──────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 42.h, // Reduced height
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 16.h,
                                  width: 16.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp, // Reduced font
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 45.h),

                      // ── Join our platform divider ─────────
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade200, thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Text(
                              'Join our platform',
                              style: GoogleFonts.poppins(
                                fontSize: 9.sp, // Reduced font
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade200, thickness: 1)),
                        ],
                      ),

                      SizedBox(height: 18.h),

                      // ── Vendor + Supplier buttons (Reduced size) ─────────
                      Row(
                        children: [
                          // Vendor — dark filled
                          Expanded(
                            child: SizedBox(
                              height: 38.h, // Reduced height
                              child: ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(
                                        initialRole: 'vendor'),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  'Vendor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.sp, // Reduced font
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Supplier — white outlined
                          Expanded(
                            child: SizedBox(
                              height: 38.h, // Reduced height
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SupplierRegisterPage(),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _primary,
                                  side: BorderSide(color: _primary, width: 2.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  'Supplier',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.sp, // Reduced font
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text field (Reduced height and font) ─────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
          fontSize: 10.sp, color: Colors.black87), // Reduced font
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey.shade400),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 10.w),
          child: suffixIcon,
        ),
        suffixIconConstraints: BoxConstraints(minWidth: 30.w, minHeight: 30.h),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w, vertical: 10.h), // Reduced height
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF3B1F2B), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
    );
  }
}
