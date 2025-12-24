import 'package:flutter/material.dart';
import '../../login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard.dart';
import 'supp_products.dart';
import 'supp_product_questions.dart';
import 'supp_reviews.dart';
import 'supp_orders.dart';
import 'supp_sales.dart';
import 'supp_invoice_management.dart';
import 'supp_shipping.dart';
import 'supp_expenses.dart';
import 'supp_settlement.dart';

// Drawer implementation for the app
class SupplierDrawer extends StatelessWidget {
  final String currentPage;
  final String userName;
  final String userType;

  const SupplierDrawer({
    Key? key,
    required this.currentPage,
    this.userName = 'SupplierAccount',
    this.userType = 'Supplier Account',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    // Global scale for paddings / sizes
    final double scale = (width / 375).clamp(0.85, 1.1);
    // Font scale for text
    final double baseFontScale = (width / 375).clamp(0.85, 1.0);

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
                    color: Colors.black.withValues(alpha: 0.05),
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

            // User Info Section
            Container(
              padding: EdgeInsets.all(12 * scale),
              margin: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 12 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Row(
                children: [                  // User Avatar
                  Container(
                    width: 40 * scale,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF457BFF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                        style: GoogleFonts.poppins(
                          fontSize: 15 * baseFontScale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF457BFF),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * baseFontScale,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6 * scale,
                                vertical: 1 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF457BFF),
                                borderRadius:
                                    BorderRadius.circular(12 * scale),
                              ),
                              child: Text(
                                'PRO',
                                style: GoogleFonts.poppins(
                                  fontSize: 9 * baseFontScale,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3 * scale),
                        Row(
                          children: [
                            Container(
                              width: 5 * scale,
                              height: 5 * scale,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5 * scale),
                            Flexible(
                              child: Text(
                                userType,
                                style: GoogleFonts.poppins(
                                  fontSize: 13 * baseFontScale,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // MENU Label
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 6 * scale,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: GoogleFonts.poppins(
                    fontSize: 17 * baseFontScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF457BFF),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

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
                      onTap: () =>
                          _navigateTo(context, const DashboardPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      title: 'Products',
                      isSelected: currentPage == 'Products',
                      onTap: () {
                        // Sample product data with varied states
                        final List<Map<String, dynamic>> productsList = [
                          {
                            'id': '1',
                            'name': 'Hydrating Face Serum',
                            'description':
                                'Deeply hydrating serum with hyaluronic acid and vitamin E for glowing skin.',
                            'category': 'Skin Care',
                            'images': [],
                            'price': '1299',
                            'sale_price': '999',
                            'stock_quantity': 45,
                            'status': 'Approved',
                            'rating': 4.8,
                          },
                          {
                            'id': '2',
                            'name': 'Luxury Body Butter',
                            'description':
                                'Rich, creamy body butter infused with shea butter and coconut oil.',
                            'category': 'Body Care',
                            'images': [],
                            'price': '899',
                            'sale_price': '749',
                            'stock_quantity': 0,
                            'status': 'Approved',
                            'rating': 4.5,
                          },
                          {
                            'id': '3',
                            'name': 'Argan Oil Hair Mask',
                            'description':
                                'Professional hair mask with pure argan oil for damaged hair repair.',
                            'category': 'Hair Care',
                            'images': [],
                            'price': '1599',
                            'sale_price': '1299',
                            'stock_quantity': 28,
                            'status': 'Pending',
                            'rating': 4.6,
                          },
                          {
                            'id': '4',
                            'name': 'Matte Lipstick Set',
                            'description':
                                'Premium matte lipstick collection with 6 vibrant shades.',
                            'category': 'Makeup',
                            'images': [],
                            'price': '2499',
                            'sale_price': '1999',
                            'stock_quantity': 15,
                            'status': 'Approved',
                            'rating': 4.7,
                          },
                          {
                            'id': '5',
                            'name': 'Gel Nail Polish Kit',
                            'description':
                                'Complete gel nail polish kit with UV lamp and 8 color options.',
                            'category': 'Nails Care',
                            'images': [],
                            'price': '3299',
                            'sale_price': '2799',
                            'stock_quantity': 12,
                            'status': 'Disapproved',
                            'rating': 4.3,
                          },
                          {
                            'id': '6',
                            'name': 'Beard Growth Oil',
                            'description':
                                'Natural beard growth oil with jojoba, castor, and almond oil blend.',
                            'category': 'Males Grooming',
                            'images': [],
                            'price': '799',
                            'sale_price': '649',
                            'stock_quantity': 35,
                            'status': 'Approved',
                            'rating': 4.4,
                          },
                          {
                            'id': '7',
                            'name':
                                'Professional Makeup Brush Set',
                            'description':
                                '12-piece professional makeup brush set with synthetic bristles.',
                            'category':
                                'Beauty Tools and Accessories',
                            'images': [],
                            'price': '1899',
                            'sale_price': '1499',
                            'stock_quantity': 22,
                            'status': 'Approved',
                            'rating': 4.9,
                          },
                          {
                            'id': '8',
                            'name': 'Vitamin C Face Cream',
                            'description':
                                'Anti-aging face cream enriched with vitamin C and retinol.',
                            'category': 'Skin Care',
                            'images': [],
                            'price': '1499',
                            'sale_price': '1199',
                            'stock_quantity': 8,
                            'status': 'Pending',
                            'rating': 4.6,
                          },
                          {
                            'id': '9',
                            'name': 'Exfoliating Body Scrub',
                            'description':
                                'Coffee and sea salt body scrub for smooth, radiant skin.',
                            'category': 'Body Care',
                            'images': [],
                            'price': '699',
                            'sale_price': '549',
                            'stock_quantity': 0,
                            'status': 'Approved',
                            'rating': 4.2,
                          },
                          {
                            'id': '10',
                            'name': 'Keratin Hair Treatment',
                            'description':
                                'Salon-quality keratin treatment for frizz-free, silky hair.',
                            'category': 'Hair Care',
                            'images': [],
                            'price': '2999',
                            'sale_price': '2499',
                            'stock_quantity': 18,
                            'status': 'Approved',
                            'rating': 4.8,
                          },
                        ];
                        _navigateTo(
                          context,
                          SuppProducts(products: productsList),
                        );
                      },
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.question_answer_outlined,
                      title: 'Product Questions',
                      isSelected:
                          currentPage == 'Product Questions',
                      onTap: () => _navigateTo(
                        context,
                        const SuppProductQuestionsPage(),
                      ),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Reviews',
                      isSelected: currentPage == 'Reviews',
                      onTap: () =>
                          _navigateTo(context, const SuppReviewsPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Orders',
                      isSelected: currentPage == 'Orders',
                      onTap: () =>
                          _navigateTo(context, const SuppOrdersPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Sales',
                      isSelected: currentPage == 'Sales',
                      onTap: () =>
                          _navigateTo(context, const SuppSalesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Invoice Management',
                      isSelected: currentPage == 'Invoice Management',
                      onTap: () =>
                          _navigateTo(context, const SuppInvoiceManagementPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Shipping',
                      isSelected: currentPage == 'Shipping',
                      onTap: () =>
                          _navigateTo(context, const SuppShippingPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Expenses',
                      isSelected: currentPage == 'Shipping',
                      onTap: () =>
                          _navigateTo(context, const SuppExpensesPage()),
                      scale: scale,
                      baseFontScale: baseFontScale,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_outlined,
                      title: 'Settlement',
                      isSelected: currentPage == 'Settlement',
                      onTap: () =>
                          _navigateTo(context, const SuppSettlementsPage()),
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
        leading: Container(
          width: 36 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 17 * baseFontScale,
            color: isSelected
                ? const Color(0xFF457BFF)
                : Colors.black87,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16 * baseFontScale,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF457BFF)
                : Colors.black87,
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
    print('Navigating to page: ${page.runtimeType}');
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
