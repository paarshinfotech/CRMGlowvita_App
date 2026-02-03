import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_Profile.dart';
import 'expenses.dart';
import 'staff.dart';

import 'vendor_model.dart';

class ProfilePage extends StatelessWidget {
  final VendorProfile? profile;
  const ProfilePage({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Personal area',
          style: GoogleFonts.poppins(fontSize: 14.sp),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.businessName ?? 'Shivani Deshmukh',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Container(
                    padding: EdgeInsets.all(2.w), // Border width
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.w,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          (profile != null && profile!.profileImage.isNotEmpty)
                              ? NetworkImage(profile!.profileImage)
                              : const AssetImage('assets/images/profile.jpeg')
                                  as ImageProvider,
                      backgroundColor: Colors.white,
                      child: (profile == null || profile!.profileImage.isEmpty)
                          ? Icon(Icons.person, size: 18.sp, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Section 1
            _sectionCard(context, [
              _profileTile(context, Icons.person, 'Profile'),
              _profileTile(context, Icons.people_alt, 'Staff'),
              _profileTile(context, Icons.currency_rupee, 'Expenses'),
              _profileTile(context, Icons.star_border, 'Reviews'),
              _profileTile(context, Icons.settings, 'Personal settings'),
            ]),

            SizedBox(height: 15.h),

            // Section 2
            _sectionCard(context, [
              _profileTile(context, Icons.help_outline, 'Help and support'),
              _profileTile(context, Icons.language, 'English',
                  iconEmoji: '🇬🇧'),
              _profileTile(context, Icons.logout, 'Log out'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _profileTile(BuildContext context, IconData icon, String title,
      {String? iconEmoji}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      leading: iconEmoji != null
          ? Text(iconEmoji, style: TextStyle(fontSize: 12.sp))
          : Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 12.sp),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 11.sp),
      onTap: () {
        switch (title) {
          case 'Profile':
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => My_Profile()));
            break;
          case 'Staff':
            Navigator.push(context, MaterialPageRoute(builder: (_) => Staff()));
            break;
          case 'Expenses':
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExpensesPage()));
            break;
          case 'Reviews':
            //   Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()));
            break;
          case 'Personal settings':
            //  Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalSettingsPage()));
            break;
          case 'Help and support':
            //   Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
            break;
          case 'Log out':
            //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            break;
          default:
            break;
        }
      },
    );
  }
}
