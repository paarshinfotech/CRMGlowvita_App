import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';

class SupplierSubscriptionWrapper extends StatelessWidget {
  final Widget child;
  final double topOffset;

  const SupplierSubscriptionWrapper({
    super.key,
    required this.child,
    this.topOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SupplierProfile?>(
      valueListenable: ApiService.supplierProfileNotifier,
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
            child,
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
            Positioned.fill(
              top: topOffset,
              child: const ModalBarrier(dismissible: false, color: Colors.transparent),
            ),
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
                            // TODO: Implement Supplier Plan Dialog if needed
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please contact admin to renew subscription')),
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
