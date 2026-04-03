import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/animation.dart';
import './supp_drawer.dart';
import 'supp_profile.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// BRAND COLORS
// ─────────────────────────────────────────────
const Color kPrimary = Color(0xFF3D1A47);
const Color kPrimaryLight = Color(0xFF6B3FA0);
const Color kBg = Color(0xFFF7F7F8);
const Color kCard = Colors.white;
const Color kBorder = Color(0xFFE5E7EB);

class Supp_DashboardPage extends StatefulWidget {
  const Supp_DashboardPage({super.key});

  @override
  State<Supp_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<Supp_DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _kpiCtrl;
  late Animation<double> _kpiFade;
  bool _isLoading = false;

  // Filter state
  String _filterType = 'Preset';
  String _presetPeriod = 'All Time';

  // Stats
  double _totalRevenue = 542500.0;
  int _totalOrders = 1250;
  int _totalProducts = 45;
  int _pendingOrders = 12;
  int _shippedOrders = 45;
  int _deliveredOrders = 1180;
  int _cancelledOrders = 13;
  double _avgOrderValue = 434.0;

  @override
  void initState() {
    super.initState();
    _kpiCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _kpiFade = CurvedAnimation(parent: _kpiCtrl, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _kpiCtrl.forward();
    });
  }

  @override
  void dispose() {
    _kpiCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return MediaQuery(
      data: mq.copyWith(
          textScaler:
              mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.0)),
      child: Theme(
        data: Theme.of(context).copyWith(
          primaryColor: kPrimary,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        child: Scaffold(
          drawer: const SupplierDrawer(currentPage: 'Dashboard'),
          backgroundColor: kBg,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: kCard,
                      elevation: 0,
                      pinned: true,
                      leading: Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      title: Text('Supplier Dashboard',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.black),
                          onPressed: () {},
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SuppProfilePage())),
                          child: Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: kPrimary,
                              child: const ClipOval(
                                child: Icon(Icons.person,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Filter Row
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        color: kCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text('Filter Type',
                                    style: TextStyle(
                                        fontSize: 9.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500)),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text('Period',
                                    style: TextStyle(
                                        fontSize: 9.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500)),
                              ),
                              SizedBox(width: 10.w),
                              const SizedBox(width: 68),
                            ]),
                            SizedBox(height: 4.h),
                            Row(children: [
                              Expanded(
                                child: _buildDropdown(
                                  value: _filterType,
                                  items: ['Preset', 'Custom'],
                                  onChanged: (v) =>
                                      setState(() => _filterType = v!),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildDropdown(
                                  value: _presetPeriod,
                                  items: [
                                    'Today',
                                    'Yesterday',
                                    'Last 7 Days',
                                    'Last 30 Days',
                                    'This Month',
                                    'All Time'
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _presetPeriod = v!),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              GestureDetector(
                                onTap: _applyFilter,
                                child: Container(
                                  height: 38.h,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 18.w),
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('Apply',
                                      style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // KPI Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: FadeTransition(
                          opacity: _kpiFade,
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Total Revenue',
                                      value:
                                          '₹ ${NumberFormat('#,##,###').format(_totalRevenue)}',
                                      icon: '💰',
                                      color: const Color(0xFFFFF3E0))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Total Orders',
                                      value: '$_totalOrders',
                                      icon: '📦',
                                      color: const Color(0xFFE3F2FD))),
                            ]),
                            SizedBox(height: 8.h),
                            Row(children: [
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Total Products',
                                      value: '$_totalProducts',
                                      icon: '🛍️',
                                      color: const Color(0xFFE8F5E9))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Pending Orders',
                                      value: '$_pendingOrders',
                                      icon: '⏳',
                                      color: const Color(0xFFFFF8E1))),
                            ]),
                            SizedBox(height: 8.h),
                            Row(children: [
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Shipped Orders',
                                      value: '$_shippedOrders',
                                      icon: '🚚',
                                      color: const Color(0xFFF3E5F5))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Delivered Orders',
                                      value: '$_deliveredOrders',
                                      icon: '✅',
                                      color: const Color(0xFFE8F5E9))),
                            ]),
                            SizedBox(height: 8.h),
                            Row(children: [
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Cancelled Orders',
                                      value: '$_cancelledOrders',
                                      icon: '❌',
                                      color: const Color(0xFFFFEBEE))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: _KpiCard(
                                      title: 'Avg. Order Value',
                                      value: '₹ $_avgOrderValue',
                                      icon: '📊',
                                      color: const Color(0xFFFCE4EC))),
                            ]),
                          ]),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                    // Top Selling Products Section
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Top Selling Products',
                        child: Column(
                          children: [
                            _TopProductRow(
                                name: 'Hydrating Face Serum',
                                sales: '450',
                                revenue: '₹ 4,49,550'),
                            _TopProductRow(
                                name: 'Luxury Body Butter',
                                sales: '280',
                                revenue: '₹ 2,09,720'),
                            _TopProductRow(
                                name: 'Argan Oil Hair Mask',
                                sales: '150',
                                revenue: '₹ 1,94,850'),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // Sales Overview Section
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Sales Overview',
                        child: Container(
                          height: 150.h,
                          child: _SimpleBarChart(),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // Feedback Ratings
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Client Feedback Ratings',
                        child: Column(
                          children: [
                            _RatingRow(label: 'Total Reviews', value: '4.8/5', count: '128 reviews'),
                            SizedBox(height: 12.h),
                            _RatingRow(label: 'Product Quality', value: '4.9/5', progress: 0.98),
                            _RatingRow(label: 'Shipping Speed', value: '4.7/5', progress: 0.94),
                            _RatingRow(label: 'Service Response', value: '4.8/5', progress: 0.96),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      {required String value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16.sp, color: Colors.grey),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: TextStyle(
                          fontSize: 10.sp, fontWeight: FontWeight.w500))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color color;

  const _KpiCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(icon, style: TextStyle(fontSize: 16.sp)),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(value,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final String name;
  final String sales;
  final String revenue;

  const _TopProductRow(
      {required this.name, required this.sales, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
                color: kBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.image_outlined, color: Colors.grey[400]),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w600)),
                Text('$sales sales',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(revenue,
              style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: kPrimary)),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final String value;
  final String? count;
  final double? progress;

  const _RatingRow(
      {required this.label, required this.value, this.count, this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  if (count != null)
                    Text(count!,
                        style:
                            TextStyle(fontSize: 9.sp, color: Colors.grey[500])),
                  if (count != null) SizedBox(width: 4.w),
                  Text(value,
                      style: TextStyle(
                          fontSize: 10.sp, fontWeight: FontWeight.w700)),
                  Icon(Icons.star, color: Colors.orange, size: 12.sp),
                ],
              ),
            ],
          ),
          if (progress != null) SizedBox(height: 4.h),
          if (progress != null)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: kBg,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryLight),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final values = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.85];
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 25.w,
              height: 100.h * values[i],
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [kPrimary, kPrimaryLight.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            SizedBox(height: 8.h),
            Text(labels[i],
                style: TextStyle(fontSize: 9.sp, color: Colors.grey[600])),
          ],
        );
      }),
    );
  }
}

