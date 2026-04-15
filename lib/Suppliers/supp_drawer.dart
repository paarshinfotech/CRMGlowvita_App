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
import 'supp_profile.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';

// Drawer implementation for the app
class SupplierDrawer extends StatefulWidget {
  final String currentPage;
  final String userName;

  const SupplierDrawer({
    Key? key,
    required this.currentPage,
    this.userName = ' ',
  }) : super(key: key);

  @override
  State<SupplierDrawer> createState() => _SupplierDrawerState();
}

class _SupplierDrawerState extends State<SupplierDrawer> {
  SupplierProfile? _supplierProfile;

  @override
  void initState() {
    super.initState();
    _loadSupplierProfile();
  }

  Future<void> _loadSupplierProfile() async {
    try {
      final profile = await ApiService.getSupplierProfile();
      if (mounted) {
        setState(() {
          _supplierProfile = profile;
        });
      }
    } catch (e) {
      print('Error loading supplier profile in drawer: $e');
    }
  }

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
                child: SizedBox(
                  height: 60 * scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8 * scale),
                        child: Image.asset(
                          'assets/images/favicon.jpg',
                          height: 50 * scale,
                          width: 50 * scale,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('assets/images/logo.png',
                                  height: 50 * scale),
                        ),
                      ),
                      // Back Button on the right
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            size: 28 * baseFontScale,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuppProfilePage()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 16 * scale,
                ),
                child: Container(
                  padding: EdgeInsets.all(12 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20 * scale,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          ((_supplierProfile?.shopName ?? widget.userName)
                                  .trim()
                                  .isNotEmpty)
                              ? (_supplierProfile?.shopName ?? widget.userName)
                                  .trim()[0]
                                  .toUpperCase()
                              : 'S',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18 * scale,
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_supplierProfile?.shopName ?? widget.userName)
                                      .trim()
                                      .isNotEmpty
                                  ? (_supplierProfile?.shopName ??
                                      widget.userName)
                                  : 'Supplier',
                              style: GoogleFonts.poppins(
                                fontSize: 13 * baseFontScale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              'Supplier Account',
                              style: GoogleFonts.poppins(
                                fontSize: 11 * baseFontScale,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey[100]),
            SizedBox(height: 10 * scale),

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
                      isSelected: widget.currentPage == 'Dashboard',
                      onTap: () =>
                          _navigateTo(context, const Supp_DashboardPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventory',
                      isSelected: widget.currentPage == 'Inventory',
                      onTap: () =>
                          _navigateTo(context, const SuppInventoryPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'Products',
                      isSelected: widget.currentPage == 'Products',
                      onTap: () => _navigateTo(context, const SuppProducts()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.group_outlined,
                      title: 'Clients',
                      isSelected: widget.currentPage == 'Clients',
                      onTap: () => _navigateTo(context, const SuppClient()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.question_answer_outlined,
                      title: 'Product Questions',
                      isSelected: widget.currentPage == 'Product Questions',
                      onTap: () => _navigateTo(
                          context, const SuppProductQuestionsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outline_rounded,
                      title: 'Reviews',
                      isSelected: widget.currentPage == 'Reviews',
                      onTap: () =>
                          _navigateTo(context, const SuppReviewsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      title: 'Orders',
                      isSelected: widget.currentPage == 'Orders',
                      onTap: () => _navigateTo(context, const SuppOrdersPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Sales',
                      isSelected: widget.currentPage == 'Sales',
                      onTap: () => _navigateTo(context, const SuppSalesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Invoice Management',
                      isSelected: widget.currentPage == 'Invoice Management',
                      onTap: () => _navigateTo(
                          context, const SuppInvoiceManagementPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.money_off_csred_outlined,
                      title: 'Expenses',
                      isSelected: widget.currentPage == 'Expenses',
                      onTap: () =>
                          _navigateTo(context, const SuppExpensesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.local_offer_outlined,
                      title: 'Offers and Coupons',
                      isSelected: widget.currentPage == 'Offers and Coupons',
                      onTap: () =>
                          _navigateTo(context, const SuppOffersCouponsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.people_outline,
                      title: 'Referrals',
                      isSelected: widget.currentPage == 'Referrals',
                      onTap: () =>
                          _navigateTo(context, const SuppReferralsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.campaign_outlined,
                      title: 'Marketing',
                      isSelected: widget.currentPage == 'Marketing',
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
                      isSelected: widget.currentPage == 'Notifications',
                      onTap: () =>
                          _navigateTo(context, const SuppNotificationsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.assessment_outlined,
                      title: 'Reports',
                      isSelected: widget.currentPage == 'Reports',
                      onTap: () =>
                          _navigateTo(context, const SuppReportsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      isSelected: widget.currentPage == 'Wallet',
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
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12 * scale),
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
          color: isSelected ? Colors.white : Colors.black54,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14 * baseFontScale,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
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
