/*import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register.dart';

class OtpVerification extends StatefulWidget {
  final String mobile;
  const OtpVerification({super.key, required this.mobile});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash.png'),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
            ),
          ),

          // Blurred Content Container
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'Verify OTP',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(1.5, 1.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Enter the OTP sent to ${widget.mobile}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),

                        // OTP Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 2.0,
                            ),
                            decoration: InputDecoration(
                              label: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'Enter OTP',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              hintText: '------',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                color: Colors.grey.shade400,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (otpController.text.isNotEmpty) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Signup(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 9.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.2),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            child: const Text('VERIFY'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
