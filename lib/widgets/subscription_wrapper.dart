import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../my_Profile.dart';

class SubscriptionWrapper extends StatelessWidget {
  final Widget child;
  final double topOffset; // New parameter to allow AppBar/Drawer interactions

  const SubscriptionWrapper({
    super.key,
    required this.child,
    this.topOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ApiService.vendorProfileNotifier,
      builder: (context, profile, _) {
        if (profile == null) return child;

        final sub = profile.subscription;
        final bool isActive = sub != null && sub.status.toLowerCase() == 'active';
        final bool isExpired = sub != null && sub.endDate != null && sub.endDate!.isBefore(DateTime.now());
        
        final bool shouldShowError = !isActive || isExpired;

        if (!shouldShowError) {
          return child;
        }

        return Stack(
          children: [
            // Original UI (e.g. the page body)
            child,
            
            // Blur overlay with clip to avoid covering the Top Area (AppBar)
            Positioned.fill(
              top: topOffset,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            
            // Disable interaction with the body but NOT the Top Area
            Positioned.fill(
              top: topOffset,
              child: const ModalBarrier(dismissible: false, color: Colors.transparent),
            ),

            // Expiry Banner (Placed at the very top of EVERYTHING, but typically we want it below AppBar)
            // But if we want it *on* all pages except drawer, we keep it at top: 0
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 2,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF44336), 
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Subscription Expired",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Please renew to continue accessing this module.",
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ChangePlanDialog(
                                currentPlan: profile.subscription?.plan,
                                onPlanChanged: () {
                                  ApiService.getVendorProfile();
                                },
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFF44336),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                          ),
                          child: Text(
                            "RENEW",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
