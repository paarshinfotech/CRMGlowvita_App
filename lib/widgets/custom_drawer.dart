import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dashboard.dart';
import '../calender.dart';
import '../appointment.dart';
import '../staff.dart';
import '../clients.dart';
import '../products.dart';
import '../services.dart';
import '../orders.dart';
import '../referral.dart';
import '../reports.dart';
import '../Notification.dart';
import '../shipping.dart';
import '../Settlements.dart';
import '../Offer&Coupons.dart';
import '../reviews.dart';
import '../product_questions.dart';
import '../marketplace.dart';
import '../invoice_management.dart';
import '../expenses.dart';
import '../sales.dart';
import '../add_ons.dart';
import '../wedding_packages.dart';
import '../login.dart';

// Drawer implementation for the app
class CustomDrawer extends StatelessWidget {
  final String currentPage;
  final String userName;
  final String userType;
  final String profileImageUrl;

  const CustomDrawer({
    Key? key,
    required this.currentPage,
    this.userName = 'HarshalSpa',
    this.userType = 'Vendor Account',
    this.profileImageUrl = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    // Global scale for paddings / sizes
    final double scale = (width / 375).clamp(0.85, 1.1);
    // Font scale for text
    final double baseFontScale = (width / 375).clamp(0.85, 1.0);

    // Clamp text scaling from system so drawer doesn't break on huge fonts
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.1,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Header with logo and back button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 12 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Glow',
                            style: GoogleFonts.poppins(
                              fontSize: 20 * baseFontScale,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Vita',
                            style: GoogleFonts.poppins(
                              fontSize: 20 * baseFontScale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF457BFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        size: 25 * baseFontScale,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            // User Info Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 16 * scale,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20 * scale,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? Icon(Icons.person,
                            size: 20 * scale, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 14 * baseFontScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userType,
                          style: GoogleFonts.poppins(
                            fontSize: 11 * baseFontScale,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[100]),
            SizedBox(height: 10 * scale),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      isSelected: currentPage == 'Dashboard',
                      onTap: () => _navigateTo(context, const DashboardPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.calendar_today_outlined,
                      title: 'Calendar',
                      isSelected: currentPage == 'Calendar',
                      onTap: () => _navigateTo(context, const Calendar()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.event_note_outlined,
                      title: 'Appointments',
                      isSelected: currentPage == 'Appointments',
                      onTap: () => _navigateTo(context, const Appointment()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.people_outline,
                      title: 'Staff',
                      isSelected: currentPage == 'Staff',
                      onTap: () => _navigateTo(context, const Staff()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.people_outline,
                      title: 'Clients',
                      isSelected: currentPage == 'Clients',
                      onTap: () => _navigateTo(context, const Client()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_outlined,
                      title: 'Customer Summary',
                      isSelected: currentPage == 'Customer Summary',
                      onTap: () {}, // TODO: Implement Customer Summary page
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.design_services_outlined,
                      title: 'Services',
                      isSelected: currentPage == 'Services',
                      onTap: () => _navigateTo(context, Services()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.add_circle_outline,
                      title: 'Add Ons',
                      isSelected: currentPage == 'Add Ons',
                      onTap: () => _navigateTo(context, const AddOnsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.card_giftcard,
                      title: 'Wedding Package',
                      isSelected: currentPage == 'Wedding Package',
                      onTap: () =>
                          _navigateTo(context, const WeddingPackagePage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      title: 'Products',
                      isSelected: currentPage == 'Products',
                      onTap: () {
                        _navigateTo(
                          context,
                          const Products(),
                        );
                      },
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.question_answer_outlined,
                      title: 'Product Questions',
                      isSelected: currentPage == 'Product Questions',
                      onTap: () => _navigateTo(
                        context,
                        const ProductQuestionsPage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Reviews',
                      isSelected: currentPage == 'Reviews',
                      onTap: () => _navigateTo(context, const ReviewsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.store_outlined,
                      title: 'Marketplace',
                      isSelected: currentPage == 'Marketplace',
                      onTap: () => _navigateTo(
                        context,
                        const MarketplacePage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.trending_up_outlined,
                      title: 'Sales',
                      isSelected: currentPage == 'Sales',
                      onTap: () => _navigateTo(context, const SalesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.receipt_outlined,
                      title: 'Invoice Management',
                      isSelected: currentPage == 'Invoice Management',
                      onTap: () => _navigateTo(
                        context,
                        const InvoiceManagementPage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      title: 'Orders',
                      isSelected: currentPage == 'Orders',
                      onTap: () => _navigateTo(context, OrdersPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.local_shipping_outlined,
                      title: 'Shipping',
                      isSelected: currentPage == 'Shipping',
                      onTap: () => _navigateTo(
                        context,
                        const ShippingPage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_outlined,
                      title: 'Settlements',
                      isSelected: currentPage == 'Settlements',
                      onTap: () => _navigateTo(context, SettlementsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Expenses',
                      isSelected: currentPage == 'Expenses',
                      onTap: () => _navigateTo(
                        context,
                        const ExpensesPage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.local_offer_outlined,
                      title: 'Offers & Coupons',
                      isSelected: currentPage == 'Offers & Coupons',
                      onTap: () => _navigateTo(context, OffersCouponsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.card_giftcard_outlined,
                      title: 'Referrals',
                      isSelected: currentPage == 'Referrals',
                      onTap: () => _navigateTo(context, const ReferralProg()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.campaign_outlined,
                      title: 'Marketing',
                      isSelected: currentPage == 'Marketing',
                      onTap: () {},
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      isSelected: currentPage == 'Notifications',
                      onTap: () => _navigateTo(
                        context,
                        const NotificationPage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_outlined,
                      title: 'Reports',
                      isSelected: currentPage == 'Reports',
                      onTap: () => _navigateTo(context, const ReportsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                  ],
                ),
              ),
            ),

            // Sign Out Button
            Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: InkWell(
                onTap: () => _handleSignOut(context, baseFontScale, scale),
                borderRadius: BorderRadius.circular(8 * scale),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 12 * scale,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_outlined,
                        size: 16 * baseFontScale,
                        color: Colors.grey[700],
                      ),
                      SizedBox(width: 12 * scale),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(
                          fontSize: 13 * baseFontScale,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required double scale,
    required double baseFontScale,
    bool hasNotification = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2 * scale),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F0FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12 * scale),
        border: isSelected
            ? Border(
                right: BorderSide(
                  color: const Color(0xFF457BFF),
                  width: 3,
                ),
              )
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 4 * scale,
        ),
        leading: Icon(
          icon,
          size: 20 * baseFontScale,
          color: isSelected ? const Color(0xFF457BFF) : Colors.black54,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14 * baseFontScale,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF457BFF) : Colors.black87,
          ),
        ),
        trailing: hasNotification
            ? Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _handleSignOut(
    BuildContext context,
    double baseFontScale,
    double scale,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Sign Out',
            style: GoogleFonts.poppins(
              fontSize: 13 * baseFontScale,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.poppins(
              fontSize: 11 * baseFontScale,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 11 * baseFontScale,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                // Clear the auth token on logout
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                await prefs.remove('access_token');
                await prefs.remove('refresh_token');
                await prefs.remove('user_role');
                await prefs.remove('user_id');
                await prefs.remove('user_data');

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF457BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 11 * baseFontScale,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
