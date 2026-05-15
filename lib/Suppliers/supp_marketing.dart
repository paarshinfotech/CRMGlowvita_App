import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'supp_drawer.dart';
import 'supp_subscription_wrapper.dart';
import 'supp_notifications.dart';
import 'supp_profile.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';
import '../marketing/social_post_creator.dart';
import '../marketing/social_media_marketing.dart';
import '../marketing/message_blast.dart';

class SuppMarketingPage extends StatefulWidget {
  const SuppMarketingPage({super.key});

  @override
  State<SuppMarketingPage> createState() => _SuppMarketingPageState();
}

class _SuppMarketingPageState extends State<SuppMarketingPage> {
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
      drawer: const SupplierDrawer(currentPage: 'Marketing'),
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
          'Marketing',
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
      body: SupplierSubscriptionWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _buildMarketingCard(
                title: 'Social Post Creator',
                description: 'Create and schedule social media posts',
                icon: Icons.add_comment_outlined,
                iconColor: Colors.blue.shade100,
                iconTextColor: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SocialPostCreatorPage(),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              _buildMarketingCard(
                title: 'Social Media Marketing',
                description: 'Create and manage marketing campaigns',
                icon: Icons.campaign_outlined,
                iconColor: Colors.purple.shade50,
                iconTextColor: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SocialMediaMarketingPage(),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              _buildMarketingCard(
                title: 'Message Blast',
                description: 'Send bulk SMS to your customers',
                icon: Icons.messenger_outline,
                iconColor: Colors.blue.shade50,
                iconTextColor: Colors.blueAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessageBlastPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketingCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: iconTextColor, size: 22.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 7.5.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
