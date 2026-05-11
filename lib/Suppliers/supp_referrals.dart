import 'package:flutter/material.dart';
import 'supp_notifications.dart';
import 'supp_profile.dart';
import 'package:glowvita/supplier_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'supp_drawer.dart';
import '../services/api_service.dart';

class SuppReferralsPage extends StatefulWidget {
  const SuppReferralsPage({super.key});

  @override
  State<SuppReferralsPage> createState() => _SuppReferralsPageState();
}

class _SuppReferralsPageState extends State<SuppReferralsPage> {
  SupplierProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getSupplierProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading supplier profile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    final displayName = _profile?.shopName ?? 'S';
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14.sp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SupplierDrawer(currentPage: 'Referrals'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Referral',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuppNotificationsPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuppProfilePage()),
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: ClipOval(
                  child: (_profile != null && _profile!.profileImage.isNotEmpty)
                      ? Image.network(
                          _profile!.profileImage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => _buildInitialAvatar(),
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                              ? child
                              : const CircularProgressIndicator(),
                        )
                      : _buildInitialAvatar(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            _buildHeroCard(),
            SizedBox(height: 20.h),
            Text(
              'How It Works',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 15.h),
            _buildHowItWorks(),
            SizedBox(height: 25.h),
            _buildStatsCards(),
            SizedBox(height: 25.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Tracking',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildTrackingItem(
              name: 'Olivia Cameron',
              studio: 'Elegance Beauty Studio',
              amount: '₹ 73,655',
              date: '25 Jan 2026',
              status: 'Pending',
              statusColor: Colors.orange.shade100,
              statusTextColor: Colors.orange.shade800,
              imageUrl: 'https://i.pravatar.cc/150?u=2',
            ),
            SizedBox(height: 12.h),
            _buildTrackingItem(
              name: 'Priya Sharma',
              studio: 'Style Studio',
              amount: '₹ 15,485',
              date: '21 Jan 2026',
              status: 'Approved',
              statusColor: Colors.green.shade100,
              statusTextColor: Colors.green.shade800,
              imageUrl: 'https://i.pravatar.cc/150?u=3',
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A2C3C), Color(0xFF8E5D78)],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grow Together, Earn',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Together',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(
            'Invite fellow professionals to our platform. When they join, you both get rewarded. It\'s our way of saying thank you for helping our community grow.',
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'https://partners.glowvitasalon.com',
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Copy Link',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A2C3C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 12.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Strengthen your professional network.',
                style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 1.h, width: 250.w, color: Colors.grey.shade300),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepIcon(Icons.link),
                _buildStepIcon(Icons.person_add_outlined),
                _buildStepIcon(Icons.card_giftcard),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepText(
              '1. Share Your Link',
              'Share your link with salon owners and beauty professionals.',
            ),
            _buildStepText(
              '2. They Sign Up',
              'Your colleague signs up on our platform using your referral link.',
            ),
            _buildStepText(
              '3. Earn Your Bonus',
              'Once their account is approved and they meet criteria, you\'ll receive a ₹0 bonus.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18.sp, color: Colors.blue),
    );
  }

  Widget _buildStepText(String title, String desc) {
    return SizedBox(
      width: 100.w,
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 8.sp,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildStatCard(
          '205',
          'Total Referrals',
          Icons.people_outline,
          Colors.orange,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          '106',
          'Successful Referrals',
          Icons.check_circle_outline,
          Colors.green,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          '₹ 73,655',
          'Total Bonus Earned',
          Icons.card_giftcard,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 12.sp, color: color),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 7.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingItem({
    required String name,
    required String studio,
    required String amount,
    required String date,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String imageUrl,
  }) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundImage: NetworkImage(imageUrl),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      studio,
                      style: GoogleFonts.poppins(
                        fontSize: 7.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: statusTextColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
