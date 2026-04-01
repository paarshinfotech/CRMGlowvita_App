import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../my_Profile.dart';

class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ApiService.vendorProfileNotifier,
      builder: (context, profile, _) {
        if (profile == null) return const SizedBox.shrink();

        final sub = profile.subscription;
        final bool isActive = sub != null && sub.status.toLowerCase() == 'active';
        final bool isExpired = sub != null && sub.endDate != null && sub.endDate!.isBefore(DateTime.now());
        
        if (isActive && !isExpired) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF44336).withOpacity(0.95), // Red with slight transparency
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Subscription Expired",
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Renew now to access all modules.",
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              TextButton(
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
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                ),
                child: Text(
                  "RENEW",
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF44336),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
