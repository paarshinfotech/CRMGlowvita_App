import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/custom_drawer.dart';
import 'Notification.dart';
import 'my_Profile.dart';
import 'vendor_model.dart';
import 'services/api_service.dart';

class ReferralProg extends StatefulWidget {
  const ReferralProg({super.key});

  @override
  State<ReferralProg> createState() => _ReferralProgState();
}

class _ReferralProgState extends State<ReferralProg> {
  VendorProfile? _profile;
  ReferralSettings? _referralSettings;
  bool _isLoadingSettings = true;

  int _totalReferrals = 0;
  int _successfulReferrals = 0;
  double _totalBonusEarned = 0.0;
  List<dynamic> _recentTracking = [];
  bool _isLoadingStats = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchReferralSettings();
    _fetchReferralStats();
    _fetchReferralHistory();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ApiService.getVendorProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchReferralSettings() async {
    try {
      final settings = await ReferralApi.getReferralSettings();
      if (mounted) {
        setState(() {
          _referralSettings = settings;
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching referral settings: $e');
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _fetchReferralStats() async {
    try {
      final stats = await ReferralApi.getReferralStats();
      if (mounted && stats != null) {
        setState(() {
          _totalReferrals =
              (stats['totalReferrals'] ?? stats['total'] ?? 0) as int;
          _successfulReferrals =
              (stats['successfulReferrals'] ?? stats['successful'] ?? 0) as int;
          _totalBonusEarned =
              (stats['totalBonusEarned'] ?? stats['totalBonus'] ?? 0.0)
                  .toDouble();
          _isLoadingStats = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchReferralHistory() async {
    try {
      final history = await ReferralApi.getReferralHistory();
      if (mounted && history != null) {
        setState(() {
          _recentTracking = history;
          _isLoadingHistory = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      debugPrint('Error fetching referral history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Widget _buildInitialAvatar() {
    final displayName = _profile?.businessName ?? 'G';
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
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
      drawer: const CustomDrawer(currentPage: 'Referrals'),
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
          'Refer a Vendor',
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
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const My_Profile()),
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
                fontSize: 12.sp,
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
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_isLoadingHistory)
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4A2C3C),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_recentTracking.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_outlined,
                        color: Colors.grey.shade400,
                        size: 36.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No referral activity yet',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentTracking.map((item) {
                final String name =
                    item['name'] ??
                    item['fullName'] ??
                    item['refereeName'] ??
                    'Colleague';
                final String studio =
                    item['businessName'] ?? item['studio'] ?? 'Salon/Studio';
                final double amtVal = (item['amount'] ?? item['bonus'] ?? 0.0)
                    .toDouble();
                final String amount =
                    '₹ ${amtVal % 1 == 0 ? amtVal.toInt() : amtVal.toStringAsFixed(2)}';
                final String date = item['date'] ?? item['createdAt'] ?? '';
                final String status = item['status'] ?? 'Pending';

                Color statusColor = Colors.orange.shade100;
                Color statusTextColor = Colors.orange.shade800;
                if (status.toLowerCase() == 'approved' ||
                    status.toLowerCase() == 'success') {
                  statusColor = Colors.green.shade100;
                  statusTextColor = Colors.green.shade800;
                } else if (status.toLowerCase() == 'failed' ||
                    status.toLowerCase() == 'rejected') {
                  statusColor = Colors.red.shade100;
                  statusTextColor = Colors.red.shade800;
                }

                final String fallbackImg =
                    'https://i.pravatar.cc/150?u=${Uri.encodeComponent(name)}';
                final String imageUrl =
                    item['profileImage'] ?? item['imageUrl'] ?? fallbackImg;

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildTrackingItem(
                    name: name,
                    studio: studio,
                    amount: amount,
                    date: date,
                    status: status,
                    statusColor: statusColor,
                    statusTextColor: statusTextColor,
                    imageUrl: imageUrl.isNotEmpty ? imageUrl : fallbackImg,
                  ),
                );
              }),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final String referralCode = _profile?.referralCode ?? '';
    final String playStoreLink =
        'https://play.google.com/store/apps/details?id=com.paarsh.glowvitacrm&referrer=ref%3D$referralCode%26role%3Dvendor';

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

          // Referral Code display
          Text(
            'Your Referral Code',
            style: GoogleFonts.poppins(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 14.sp,
                  color: Colors.white70,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    referralCode.isNotEmpty ? referralCode : '—',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                if (referralCode.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Copy',
                        style: GoogleFonts.poppins(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A2C3C),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 15.h),

          // Share Button — shares only the Play Store download link
          GestureDetector(
            onTap: () {
              Share.share(
                'Join me on GlowVita and let\'s grow our business together!\n\n'
                'Download the app here: $playStoreLink',
                subject: 'Join GlowVita',
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.share,
                    size: 14.sp,
                    color: const Color(0xFF4A2C3C),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Share Invitation',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A2C3C),
                    ),
                  ),
                ],
              ),
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

  Widget _buildLinkRow(String link, String buttonLabel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              link,
              style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$buttonLabel copied to clipboard!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Copy',
                style: GoogleFonts.poppins(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A2C3C),
                ),
              ),
            ),
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
              'Once their account is approved and they meet criteria, you\'ll receive a '
                  '${_referralSettings != null ? _referralSettings!.referrerBonus.formattedValue : "₹0"} bonus.',
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
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 7.sp,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 11.sp, color: iconColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.poppins(
                  fontSize: 7.sp,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A2C3C),
          ),
        ),
      ],
    );
  }

  Widget _buildPillInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 9.sp, color: Colors.grey.shade500),
                SizedBox(width: 4.w),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 6.5.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return Container(
        height: 60.h,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Color(0xFF4A2C3C),
            strokeWidth: 2,
          ),
        ),
      );
    }
    return Row(
      children: [
        _buildStatCard(
          '$_totalReferrals',
          'Total Referrals',
          Icons.people_outline,
          Colors.orange,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          '$_successfulReferrals',
          'Successful Referrals',
          Icons.check_circle_outline,
          Colors.green,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          '₹ ${_totalBonusEarned % 1 == 0 ? _totalBonusEarned.toInt() : _totalBonusEarned.toStringAsFixed(2)}',
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
                fontSize: 6.sp,
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
