import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'expenses.dart';
import 'my_profile.dart';
import 'notification.dart';
import 'profile.dart';
import 'staff.dart';
import 'reports.dart';
import 'referral.dart';
import 'settings.dart';
import 'widgets/custom_drawer.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _MoreState();
}

class _MoreState extends State<More> {
  @override
  Widget build(BuildContext context) {
    // Define color palette
    const Color primaryBlue = Color(0xFF457BFF);
    const Color backgroundLight = Color(0xFFF7F9FD);
    const Color textDark = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF6B7280);

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'More'),
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60.h,
        titleSpacing: 0,
        automaticallyImplyLeading: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF1F6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'More Options',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications, size: 18.sp),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                },
                tooltip: 'Notifications',
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5.w),
                  ),
                  child: CircleAvatar(
                    radius: 15.r,
                    backgroundImage: const AssetImage('assets/images/profile.jpeg'),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Center(
            child: Column(
              children: [
                Wrap(
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: [
                    _buildMenuItem(
                      icon: Icons.bar_chart_outlined,
                      title: 'Reports',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReportsPage()),
                        );
                      },
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.redeem,
                      title: 'Referrals',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReferralProg()),
                        );
                      },
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.sentiment_satisfied_alt,
                      title: 'Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const My_Profile()),
                        );
                      },
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.currency_rupee,
                      title: 'Expenses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExpensesPage()),
                        );
                      },
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.campaign_outlined,
                      title: 'Marketing',
                      onTap: () {},
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.groups_outlined,
                      title: 'Staff',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Staff()),
                        );
                      },
                      primaryBlue: primaryBlue,
                    ),_buildMenuItem(
                      icon: Icons.star_outlined,
                      title: 'Reviews',
                      onTap: () {},
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Settings()),
                        );
                      },
                      primaryBlue: primaryBlue,
                    ),
                    _buildMenuItem(
                      icon: Icons.push_pin,
                      title: 'Custom Push',
                      onTap: () {},
                      primaryBlue: primaryBlue,
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    required Color primaryBlue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 140.w,
        height: 80.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24.sp, color: primaryBlue),
            SizedBox(height: 8.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue, size: 20.sp),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      tileColor: Colors.white,
      trailing: Icon(Icons.arrow_forward_ios, size: 15.sp, color: Colors.black54),
    );
  }
}