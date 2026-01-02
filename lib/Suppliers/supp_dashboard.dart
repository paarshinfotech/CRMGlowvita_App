import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/animation.dart';
import './supp_drawer.dart';
import '../products.dart';
import 'supp_profile.dart';


class Supp_DashboardPage extends StatefulWidget {
  const Supp_DashboardPage({super.key});

  @override
  State<Supp_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<Supp_DashboardPage> with TickerProviderStateMixin {
  late AnimationController _kpiAnimationController;
  late Animation<double> _kpiFadeAnimation;

  @override
  void initState() {
    super.initState();
    print('Initializing Supplier Dashboard Page');

    _kpiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _kpiFadeAnimation = CurvedAnimation(
      parent: _kpiAnimationController,
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _kpiAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _kpiAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building Supplier Dashboard Page');
    final mediaQuery = MediaQuery.of(context);
    final String today = DateFormat('dd MMM yyyy').format(DateTime.now());
    ScreenUtil.init(context, designSize: const Size(375, 812));

    final double baseFontScale = (mediaQuery.size.width / 375).clamp(0.8, 0.95);

    // Demo product data
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
    ];

    // Calculate product summary statistics
    final int totalProducts = productsList.length;
    final int approvedProducts = productsList.where((p) => p['status'] == 'Approved').length;
    final int pendingProducts = productsList.where((p) => p['status'] == 'Pending').length;
    final int disapprovedProducts = productsList.where((p) => p['status'] == 'Disapproved').length;
    final int outOfStockProducts = productsList.where((p) => p['stock_quantity'] == 0).length;
    final int lowStockProducts = productsList.where((p) => p['stock_quantity'] > 0 && p['stock_quantity'] <= 10).length;
    
    // Category distribution
    final Map<String, int> categoryDistribution = {};
    for (var product in productsList) {
      final category = product['category'];
      categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
    }

    const double bottomSheetInitialPadding = 120;

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ).apply(fontSizeFactor: baseFontScale),
        ),
        child: Scaffold(
          drawer: const SupplierDrawer(currentPage: 'Dashboard'),
          backgroundColor: const Color(0xFFF7F7F8),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    expandedHeight: 150.h,
                    leading: Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () {
                          print('Opening supplier drawer menu');
                          Scaffold.of(ctx).openDrawer();
                        },
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.black),
                        onPressed: () {
                          print('Opening notifications page');
                         /* Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationPage()),
                          );*/
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          print('Opening profile page');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SuppProfilePage()),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1.w),
                            ),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundImage: AssetImage('assets/images/profile.jpeg'),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(16.w, 70.h, 16.w, 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                _MiniChip(text: today, icon: Icons.calendar_month_outlined),
                                SizedBox(width: 8.w),
                              ],
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(10.h),
                      child: Container(
                        height: 10.h,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F7F8),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                      ),
                    ),
                  ),

                  // ---- OVERVIEW ----
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overview', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                          Text('Swipe', style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120.h,
                      child: FadeTransition(
                        opacity: _kpiFadeAnimation,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (_, __) => SizedBox(width: 12.w),
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return _KpiCard(
                                title: "Total Products",
                                value: '$totalProducts',
                                subtitle: 'In catalog',
                                icon: Icons.inventory_2_outlined,
                                accent: const Color(0xFF111827),
                              );
                            }
                            if (i == 1) {
                              return _KpiCard(
                                title: 'Approved',
                                value: '$approvedProducts',
                                subtitle: 'Products',
                                icon: Icons.check_circle_outline,
                                accent: const Color(0xFF2563EB),
                              );
                            }
                            if (i == 2) {
                              return _KpiCard(
                                title: 'Pending Review',
                                value: '$pendingProducts',
                                subtitle: 'Products',
                                icon: Icons.pending_outlined,
                                accent: const Color(0xFFF97316),
                              );
                            }

                            // Disapproved products
                            return _KpiCard(
                              title: 'Disapproved',
                              value: '$disapprovedProducts',
                              subtitle: 'Products',
                              icon: Icons.cancel_outlined,
                              accent: const Color(0xFFEF4444),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // ---- PRODUCT SUMMARY ----
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Product Summary', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () {
                              print('Navigating to Products page from Dashboard');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Products(products: productsList),
                                ),
                              );
                            },
                            child: Text('View All', style: TextStyle(fontSize: 11.sp, color: Colors.blue)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Stock Status Summary
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stock Status',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  _StockStatusIndicator(
                                    title: 'In Stock',
                                    value: '${totalProducts - outOfStockProducts - lowStockProducts}',
                                    color: Colors.green,
                                    percentage: ((totalProducts - outOfStockProducts - lowStockProducts) / totalProducts * 100).round(),
                                  ),
                                  SizedBox(width: 12.w),
                                  _StockStatusIndicator(
                                    title: 'Low Stock',
                                    value: '$lowStockProducts',
                                    color: Colors.orange,
                                    percentage: (lowStockProducts / totalProducts * 100).round(),
                                  ),
                                  SizedBox(width: 12.w),
                                  _StockStatusIndicator(
                                    title: 'Out of Stock',
                                    value: '$outOfStockProducts',
                                    color: Colors.red,
                                    percentage: (outOfStockProducts / totalProducts * 100).round(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                  
                  // Category Distribution
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category Distribution',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              SizedBox(
                                height: 100.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categoryDistribution.length,
                                  itemBuilder: (context, index) {
                                    final category = categoryDistribution.keys.elementAt(index);
                                    final count = categoryDistribution[category]!;
                                    final percentage = (count / totalProducts * 100).round();
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(right: 16.w),
                                      child: Column(
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            '$count',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF457BFF),
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Container(
                                            width: 60.w,
                                            height: 60.w,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF457BFF).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF457BFF),
                                                width: 2.w,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$percentage%',
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF457BFF),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: bottomSheetInitialPadding.h)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockStatusIndicator extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final int percentage;
  
  const _StockStatusIndicator({
    required this.title,
    required this.value,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (60 * (percentage / 100)).h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- UI Widgets (unchanged from your file) -----------------

class _MiniChip extends StatefulWidget {
  final String text;
  final IconData icon;

  const _MiniChip({required this.text, required this.icon});

  @override
  State<_MiniChip> createState() => _MiniChipState();
}

class _MiniChipState extends State<_MiniChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: Colors.black87),
              SizedBox(width: 4.w),
              Text(widget.text, style: TextStyle(fontSize: 10.sp, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? child;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.child,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 200.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 14, color: widget.accent),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(widget.value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 2.h),
              Text(widget.subtitle, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
              if (widget.child != null) ...[
                SizedBox(height: 6.h),
                Expanded(child: widget.child!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}