import 'package:flutter/material.dart';
import '../../login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supp_dashboard.dart';
import 'supp_inventory.dart';
import 'supp_products.dart';
import 'supp_clients.dart';
import 'supp_product_questions.dart';
import 'supp_reviews.dart';
import 'supp_orders.dart';
import 'supp_sales.dart';
import 'supp_invoice_management.dart';
import 'supp_expenses.dart';
import 'supp_offers_coupons.dart';
import 'supp_referrals.dart';
import 'supp_marketing.dart';
import 'supp_notifications.dart';
import 'supp_reports.dart';
import 'supp_wallet.dart';
import '../intro_page.dart';

// Drawer implementation for the app
class SupplierDrawer extends StatelessWidget {
  final String currentPage;
  final String userName;
  final String userType;

  const SupplierDrawer({
    Key? key,
    required this.currentPage,
    this.userName = 'Supplier Account',
    this.userType = 'Pro Supplier',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    // Global scale for paddings / sizes
    final double scale = (width / 375).clamp(0.85, 1.1);
    // Font scale for text
    final double baseFontScale = (width / 375).clamp(0.8, 1.0);

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4 * scale,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4 * scale),
                          child: Image.asset(
                            'assets/images/favicon.jpg',
                            height: 24 * scale,
                            width: 24 * scale,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('assets/images/logo.png',
                                    height: 24 * scale),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        size: 22 * baseFontScale,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            // User Info Section
            Container(
              padding: EdgeInsets.all(10 * scale),
              margin: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36 * scale,
                    height: 36 * scale,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                        style: GoogleFonts.poppins(
                          fontSize: 14 * baseFontScale,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 13 * baseFontScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
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

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      isSelected: currentPage == 'Dashboard',
                      onTap: () =>
                          _navigateTo(context, const Supp_DashboardPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventory',
                      isSelected: currentPage == 'Inventory',
                      onTap: () =>
                          _navigateTo(context, const SuppInventoryPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'Products',
                      isSelected: currentPage == 'Products',
                      onTap: () => _navigateTo(context, const SuppProducts()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.group_outlined,
                      title: 'Clients',
                      isSelected: currentPage == 'Clients',
                      onTap: () => _navigateTo(context, const SuppClient()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.question_answer_outlined,
                      title: 'Product Questions',
                      isSelected: currentPage == 'Product Questions',
                      onTap: () => _navigateTo(
                          context, const SuppProductQuestionsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outline_rounded,
                      title: 'Reviews',
                      isSelected: currentPage == 'Reviews',
                      onTap: () =>
                          _navigateTo(context, const SuppReviewsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      title: 'Orders',
                      isSelected: currentPage == 'Orders',
                      onTap: () => _navigateTo(context, const SuppOrdersPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Sales',
                      isSelected: currentPage == 'Sales',
                      onTap: () => _navigateTo(context, const SuppSalesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Invoice Management',
                      isSelected: currentPage == 'Invoice Management',
                      onTap: () => _navigateTo(
                          context, const SuppInvoiceManagementPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.money_off_csred_outlined,
                      title: 'Expenses',
                      isSelected: currentPage == 'Expenses',
                      onTap: () =>
                          _navigateTo(context, const SuppExpensesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.local_offer_outlined,
                      title: 'Offers and Coupons',
                      isSelected: currentPage == 'Offers and Coupons',
                      onTap: () =>
                          _navigateTo(context, const SuppOffersCouponsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.people_outline,
                      title: 'Referrals',
                      isSelected: currentPage == 'Referrals',
                      onTap: () =>
                          _navigateTo(context, const SuppReferralsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.campaign_outlined,
                      title: 'Marketing',
                      isSelected: currentPage == 'Marketing',
                      onTap: () =>
                          _navigateTo(context, const SuppMarketingPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      hasNotification: true,
                      isSelected: currentPage == 'Notifications',
                      onTap: () =>
                          _navigateTo(context, const SuppNotificationsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.assessment_outlined,
                      title: 'Reports',
                      isSelected: currentPage == 'Reports',
                      onTap: () =>
                          _navigateTo(context, const SuppReportsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      isSelected: currentPage == 'Wallet',
                      onTap: () => _navigateTo(context, const SuppWalletPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                  ],
                ),
              ),
            ),

            // Sign Out Button
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
              ),
              child: ListTile(
                onTap: () => _handleSignOut(context, baseFontScale, scale),
                leading: Icon(Icons.logout_outlined,
                    size: 18 * baseFontScale, color: Colors.red[400]),
                title: Text('Sign Out',
                    style: GoogleFonts.poppins(
                        fontSize: 13 * baseFontScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700])),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale)),
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
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon,
            size: 18 * baseFontScale,
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.black87),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 12 * baseFontScale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.black87)),
        trailing: hasNotification
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle))
            : null,
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _handleSignOut(
      BuildContext context, double baseFontScale, double scale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out',
            style: GoogleFonts.poppins(
                fontSize: 14 * baseFontScale, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.poppins(fontSize: 12 * baseFontScale)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(fontSize: 12 * baseFontScale))),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const IntroPage()),
                  (route) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor),
            child: Text('Sign Out',
                style: TextStyle(
                    fontSize: 12 * baseFontScale, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
