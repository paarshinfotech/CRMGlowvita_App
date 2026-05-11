import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;
import './supp_drawer.dart';
import 'supp_profile.dart';
import 'supp_notifications.dart';
import 'supp_orders.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';
import '../widgets/subscription_wrapper.dart';

// ─────────────────────────────────────────────
// BRAND COLORS
// ─────────────────────────────────────────────
const Color kPrimary = Color(0xFF4A2C3C);
const Color kPrimaryLight = Color(0xFF6B3FA0);
const Color kBg = Colors.white;
const Color kCard = Colors.white;
const Color kBorder = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────
// FILTER ENUMS
// ─────────────────────────────────────────────
enum _FilterType { presetPeriod, dateRange }

enum _PresetPeriod { day, month, year, allTime }

// ═══════════════════════════════════════════════════════
//  SUPPLIER DASHBOARD PAGE
// ═══════════════════════════════════════════════════════
class Supp_DashboardPage extends StatefulWidget {
  const Supp_DashboardPage({super.key});
  @override
  State<Supp_DashboardPage> createState() => _SuppDashboardPageState();
}

class _SuppDashboardPageState extends State<Supp_DashboardPage>
    with TickerProviderStateMixin {
  SupplierProfile? _profile;

  late AnimationController _kpiCtrl;
  late Animation<double> _kpiFade;

  // ── Filter state ──────────────────────────
  _FilterType _filterType = _FilterType.presetPeriod;
  _PresetPeriod _presetPeriod = _PresetPeriod.allTime;
  DateTime? _selDay;
  int _selMonth = DateTime.now().month;
  int _selYear = DateTime.now().year;

  // ── Dynamic Data (Sample/Real placeholders) ──
  bool _isLoading = true;

  // KPI Values
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgOrderValue = 0;
  int _totalProducts = 0;
  int _pendingOrders = 0;
  int _shippedOrders = 0;
  int _deliveredOrders = 0;
  int _cancelledOrders = 0;

  // Chart Data
  List<double> _monthlySalesData = List.filled(7, 0.0);
  List<String> _topProductNames = [];
  List<double> _topProductValues = [];
  double _qualityFeedback = 0, _shippingFeedback = 0, _serviceFeedback = 0;

  @override
  void initState() {
    super.initState();
    _kpiCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _kpiFade = CurvedAnimation(parent: _kpiCtrl, curve: Curves.easeInOut);

    _fetchProfile();
    _loadDashboardData();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _kpiCtrl.forward();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getSupplierProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, you would fetch these from ApiService
      // final results = await Future.wait([ ... ]);

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          // Reset stats to 0 or fetch real data
          _totalRevenue = 0;
          _totalOrders = 0;
          _avgOrderValue = 0;
          _totalProducts = 0;
          _pendingOrders = 0;
          _shippedOrders = 0;
          _deliveredOrders = 0;
          _cancelledOrders = 0;

          _calculateCharts();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadDashboardData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateCharts() {
    // Sales Overview - Last 7 months (Sample data)
    _monthlySalesData = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.85];

    // Top Products (Sample data)
    _topProductNames = [
      'Face Serum',
      'Body Butter',
      'Hair Mask',
      'Day Cream',
      'Eye Roll',
    ];
    _topProductValues = [1.0, 0.8, 0.65, 0.45, 0.3];

    // Feedback
    _qualityFeedback = 0.95;
    _shippingFeedback = 0.88;
    _serviceFeedback = 0.92;
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.shopName ?? 'S').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _applyFilter() {
    setState(() => _isLoading = true);
    _loadDashboardData();
  }

  String _buildPeriodLabel() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    switch (_presetPeriod) {
      case _PresetPeriod.day:
        if (_selDay != null) {
          return '${_selDay!.day} ${months[_selDay!.month - 1]} ${_selDay!.year}';
        }
        return 'Today';
      case _PresetPeriod.month:
        return '${months[_selMonth - 1]} $_selYear';
      case _PresetPeriod.year:
        return '$_selYear';
      default:
        return 'All Time';
    }
  }

  @override
  void dispose() {
    _kpiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          primaryColor: kPrimary,
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: kPrimary, secondary: kPrimaryLight),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        child: Scaffold(
          drawer: SupplierDrawer(
            currentPage: 'Dashboard',
            userName: _profile?.shopName ?? 'Supplier',
          ),
          backgroundColor: kBg,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SubscriptionWrapper(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      // ── AppBar ─────────────────────────────────
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
                        title: Text(
                          'Supplier Dashboard',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SuppNotificationsPage(),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SuppProfilePage(),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(right: 10.w),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: kPrimary,
                                child: ClipOval(
                                  child:
                                      (_profile != null &&
                                          _profile!.profileImage.isNotEmpty)
                                      ? Image.network(
                                          _profile!.profileImage,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, _, __) =>
                                              _buildInitialAvatar(),
                                          loadingBuilder:
                                              (
                                                ctx,
                                                child,
                                                progress,
                                              ) => progress == null
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

                      // ── Filter Row (Sliver) ─────────────────────
                      SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          color: kCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Filter Type',
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      'Period',
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  const SizedBox(width: 68),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FilterTypeDropdown(
                                      current: _filterType,
                                      onChanged: (v) =>
                                          setState(() => _filterType = v!),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: _PeriodDropdown(
                                      filterType: _filterType,
                                      presetPeriod: _presetPeriod,
                                      onChanged: (p) =>
                                          setState(() => _presetPeriod = p!),
                                      selectedDay: _selDay,
                                      selectedMonth: _selMonth,
                                      selectedYear: _selYear,
                                      onDayChanged: (d) =>
                                          setState(() => _selDay = d),
                                      onMonthChanged: (m) =>
                                          setState(() => _selMonth = m!),
                                      onYearChanged: (y) =>
                                          setState(() => _selYear = y!),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  GestureDetector(
                                    onTap: _applyFilter,
                                    child: Container(
                                      height: 38.h,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Apply',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_filterType == _FilterType.presetPeriod &&
                                  _presetPeriod != _PresetPeriod.allTime) ...[
                                SizedBox(height: 6.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: kPrimary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.filter_alt_outlined,
                                        size: 11.sp,
                                        color: kPrimary,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        _buildPeriodLabel(),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: kPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                        // ── KPI Grid ───────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: FadeTransition(
                              opacity: _kpiFade,
                              child: Column(
                                children: [
                                  _kpiRow([
                                    _KpiGridCard(
                                      title: 'Total Revenue',
                                      value:
                                          '₹ ${NumberFormat('#,##,###').format(_totalRevenue)}',
                                      icon: '💰',
                                      iconBg: const Color(0xFFFFF3E0),
                                    ),
                                    _KpiGridCard(
                                      title: 'Total Orders',
                                      value: '$_totalOrders',
                                      icon: '📦',
                                      iconBg: const Color(0xFFE3F2FD),
                                    ),
                                    _KpiGridCard(
                                      title: 'Avg Order Value',
                                      value:
                                          '₹ ${_avgOrderValue.toStringAsFixed(0)}',
                                      icon: '📊',
                                      iconBg: const Color(0xFFFCE4EC),
                                    ),
                                    _KpiGridCard(
                                      title: 'Total Products',
                                      value: '$_totalProducts',
                                      icon: '🛍️',
                                      iconBg: const Color(0xFFF3E5F5),
                                    ),
                                  ]),
                                  SizedBox(height: 8.h),
                                  _kpiRow([
                                    _KpiGridCard(
                                      title: 'Pending Orders',
                                      value: '$_pendingOrders',
                                      icon: '⏳',
                                      iconBg: const Color(0xFFFFF8E1),
                                    ),
                                    _KpiGridCard(
                                      title: 'Shipped Orders',
                                      value: '$_shippedOrders',
                                      icon: '🚚',
                                      iconBg: const Color(0xFFE8F5E9),
                                    ),
                                    _KpiGridCard(
                                      title: 'Delivered Orders',
                                      value: '$_deliveredOrders',
                                      icon: '✅',
                                      iconBg: const Color(0xFFE3F2FD),
                                    ),
                                    _KpiGridCard(
                                      title: 'Cancelled Orders',
                                      value: '$_cancelledOrders',
                                      icon: '❌',
                                      iconBg: const Color(0xFFFFEBEE),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                        // ── Sales Overview (scrollable Jan–Dec) ────
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 12.w),
                            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sales Overview',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'A detailed summary of your sales activity for the last 7 months.',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _SalesOverviewChart(data: _monthlySalesData),
                              ],
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                        // ── Top Selling Products ───────────────────
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 12.w),
                            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Top Selling Products',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Products with the highest sales volume',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _TopProductsChart(
                                  products: _topProductNames,
                                  values: _topProductValues,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                        // ── Client Feedback ────────────────────────
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 12.w),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Client Feedback',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Performance metrics from your vendor clients',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _GaugeWidget(
                                      label: '🛡️ Quality',
                                      labelBg: const Color(0xFFFFF9C4),
                                      value: _qualityFeedback,
                                    ),
                                    _GaugeWidget(
                                      label: '🚚 Shipping',
                                      labelBg: const Color(0xFFFFE0B2),
                                      value: _shippingFeedback,
                                    ),
                                    _GaugeWidget(
                                      label: '💆 Service',
                                      labelBg: const Color(0xFFE8F5E9),
                                      value: _serviceFeedback,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _LegendDot(
                                      color: const Color(0xFFB3E5FC),
                                      label: 'Low (0-2.5)',
                                    ),
                                    SizedBox(width: 10.w),
                                    _LegendDot(
                                      color: const Color(0xFF42A5F5),
                                      label: 'Med (2.5-4)',
                                    ),
                                    SizedBox(width: 10.w),
                                    _LegendDot(
                                      color: const Color(0xFF1565C0),
                                      label: 'High (4-5)',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _kpiRow(List<Widget> cards) => Row(
    children: cards.expand((c) => [c, SizedBox(width: 8.w)]).toList()
      ..removeLast(),
  );
}

// ═══════════════════════════════════════════════════════
// KPI GRID CARD
// ═══════════════════════════════════════════════════════
class _KpiGridCard extends StatelessWidget {
  final String title, value, icon;
  final Color iconBg;
  const _KpiGridCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72.h,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(icon, style: TextStyle(fontSize: 10.sp)),
                ),
                const Spacer(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.5.sp,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SALES OVERVIEW CHART
// ═══════════════════════════════════════════════════════
class _SalesOverviewChart extends StatelessWidget {
  final List<double> data;
  const _SalesOverviewChart({required this.data});

  static List<String> get _months {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = DateTime(now.year, now.month - (6 - i), 1);
      return DateFormat('MMM').format(d);
    });
  }

  static const _yLabels = ['Max', '0.75', '0.5', '0.25', '0'];

  @override
  Widget build(BuildContext context) {
    const double chartH = 150;
    const double yAxisW = 30;
    const double xLabelH = 20;
    const double slotW = 44;

    return SizedBox(
      height: chartH + xLabelH,
      child: Row(
        children: [
          SizedBox(
            width: yAxisW,
            height: chartH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _yLabels
                  .map(
                    (l) => Text(
                      l,
                      style: TextStyle(fontSize: 7.sp, color: Colors.grey[500]),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: slotW * _months.length,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartH,
                      child: CustomPaint(
                        painter: _SalesLinePainter(data: data),
                        size: Size(slotW * _months.length, chartH),
                      ),
                    ),
                    SizedBox(
                      height: xLabelH,
                      child: Row(
                        children: _months
                            .map(
                              (m) => SizedBox(
                                width: slotW,
                                child: Text(
                                  m,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesLinePainter extends CustomPainter {
  final List<double> data;
  const _SalesLinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.length;
    final slotW = size.width / n;
    const padTop = 24.0;
    final chartH = size.height - padTop;

    final points = List.generate(
      n,
      (i) => Offset(slotW * i + slotW / 2, padTop + chartH * (1 - data[i])),
    );

    final fill = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++)
      fill.lineTo(points[i].dx, points[i].dy);
    fill
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader =
            ui.Gradient.linear(Offset(0, padTop), Offset(0, size.height), [
              const Color(0xFF42A5F5).withOpacity(0.22),
              const Color(0xFF42A5F5).withOpacity(0.01),
            ]),
    );

    final gridP = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + chartH * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridP);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++)
      path.lineTo(points[i].dx, points[i].dy);
    canvas.drawPath(path, linePaint);

    for (final p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = const Color(0xFF42A5F5));
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawDashedLine(Canvas c, Offset s, Offset e, Paint p) {
    const dash = 4.0, gap = 3.0;
    final dx = e.dx - s.dx, dy = e.dy - s.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len, uy = dy / len;
    double pos = 0;
    while (pos < len) {
      final end = math.min(pos + dash, len);
      c.drawLine(
        Offset(s.dx + ux * pos, s.dy + uy * pos),
        Offset(s.dx + ux * end, s.dy + uy * end),
        p,
      );
      pos += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SalesLinePainter o) => o.data != data;
}

// ═══════════════════════════════════════════════════════
// TOP PRODUCTS CHART
// ═══════════════════════════════════════════════════════
class _TopProductsChart extends StatelessWidget {
  final List<String> products;
  final List<double> values;
  const _TopProductsChart({required this.products, required this.values});

  static const _colors = [
    Color(0xFF42A5F5),
    Color(0xFF42A5F5),
    Color(0xFF388E3C),
    Color(0xFF42A5F5),
    Color(0xFF42A5F5),
  ];
  static const _yLabels = ['100%', '80%', '60%', '40%', '20%', '0'];

  @override
  Widget build(BuildContext context) {
    const double chartH = 150;
    const double yAxisW = 34;
    const double xLabelH = 24;
    const double slotW = 54;

    return SizedBox(
      height: chartH + xLabelH,
      child: Row(
        children: [
          SizedBox(
            width: yAxisW,
            height: chartH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _yLabels
                  .map(
                    (l) => Text(
                      l,
                      style: TextStyle(fontSize: 7.sp, color: Colors.grey[500]),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: slotW * products.length,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartH,
                      child: CustomPaint(
                        painter: _BarsPainter(values: values, colors: _colors),
                        size: Size(slotW * products.length, chartH),
                      ),
                    ),
                    SizedBox(
                      height: xLabelH,
                      child: Row(
                        children: products
                            .map(
                              (p) => SizedBox(
                                width: slotW,
                                child: Text(
                                  p,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 7.5.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  const _BarsPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final slotW = size.width / n;
    final barW = slotW * 0.5;

    final gridP = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridP);
    }

    for (int i = 0; i < n; i++) {
      final barH = values[i] * size.height;
      final left = slotW * i + (slotW - barW) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - barH, barW, barH),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = i < colors.length ? colors[i] : colors[0],
      );
    }
  }

  void _drawDashedLine(Canvas c, Offset s, Offset e, Paint p) {
    const dash = 4.0, gap = 3.0;
    double pos = 0;
    final len = e.dx - s.dx;
    while (pos < len) {
      final end = math.min(pos + dash, len);
      c.drawLine(Offset(s.dx + pos, s.dy), Offset(s.dx + end, s.dy), p);
      pos += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter o) => false;
}

// ═══════════════════════════════════════════════════════
// GAUGE WIDGET
// ═══════════════════════════════════════════════════════
class _GaugeWidget extends StatelessWidget {
  final String label;
  final Color labelBg;
  final double value; // 0 to 1
  const _GaugeWidget({
    required this.label,
    required this.labelBg,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final Color gaugeColor = value > 0.8
        ? const Color(0xFF1565C0)
        : value > 0.5
        ? const Color(0xFF42A5F5)
        : const Color(0xFFB3E5FC);

    return Column(
      children: [
        SizedBox(
          width: 64.w,
          height: 64.w,
          child: CustomPaint(
            painter: _GaugePainter(value: value, color: gaugeColor),
            child: Center(
              child: Text(
                '${(value * 5).toStringAsFixed(1)}',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: labelBg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgP = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgP,
    );

    final fgP = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * value,
      false,
      fgP,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) =>
      o.value != value || o.color != color;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 7.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// FILTER DROPDOWNS
// ═══════════════════════════════════════════════════════
class _FilterTypeDropdown extends StatelessWidget {
  final _FilterType current;
  final ValueChanged<_FilterType?> onChanged;
  const _FilterTypeDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_FilterType>(
          value: current,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          items: const [
            DropdownMenuItem(
              value: _FilterType.presetPeriod,
              child: Text('Preset Period'),
            ),
            DropdownMenuItem(
              value: _FilterType.dateRange,
              child: Text('Date Range'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  final _FilterType filterType;
  final _PresetPeriod presetPeriod;
  final ValueChanged<_PresetPeriod?> onChanged;
  final DateTime? selectedDay;
  final int selectedMonth, selectedYear;
  final ValueChanged<DateTime?> onDayChanged;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const _PeriodDropdown({
    required this.filterType,
    required this.presetPeriod,
    required this.onChanged,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (filterType == _FilterType.dateRange) {
      return GestureDetector(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(primary: kPrimary),
              ),
              child: child!,
            ),
          );
          if (picked != null) {}
        },
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Select Range',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_PresetPeriod>(
          value: presetPeriod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          items: const [
            DropdownMenuItem(
              value: _PresetPeriod.allTime,
              child: Text('All Time'),
            ),
            DropdownMenuItem(value: _PresetPeriod.day, child: Text('Day')),
            DropdownMenuItem(value: _PresetPeriod.month, child: Text('Month')),
            DropdownMenuItem(value: _PresetPeriod.year, child: Text('Year')),
          ],
          onChanged: (p) async {
            onChanged(p);
            if (p == _PresetPeriod.day) {
              final d = await showDatePicker(
                context: context,
                initialDate: selectedDay ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: kPrimary),
                  ),
                  child: child!,
                ),
              );
              if (d != null) onDayChanged(d);
            } else if (p == _PresetPeriod.month) {
              int tmpMonth = selectedMonth;
              int tmpYear = selectedYear;
              final years = List.generate(
                10,
                (i) => DateTime.now().year - 4 + i,
              );
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setDlg) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text(
                        'Select Month & Year',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            decoration: BoxDecoration(
                              border: Border.all(color: kBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: tmpYear,
                                isExpanded: true,
                                items: years
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text('$y'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setDlg(() => tmpYear = v);
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 4,
                            childAspectRatio: 2,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            children: List.generate(12, (i) {
                              final sel = tmpMonth == i + 1;
                              return GestureDetector(
                                onTap: () => setDlg(() => tmpMonth = i + 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: sel ? kPrimary : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: sel ? kPrimary : kBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun',
                                      'Jul',
                                      'Aug',
                                      'Sep',
                                      'Oct',
                                      'Nov',
                                      'Dec',
                                    ][i],
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onMonthChanged(tmpMonth);
                            onYearChanged(tmpYear);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                          ),
                          child: const Text(
                            'Select',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else if (p == _PresetPeriod.year) {
              int tmpYear = selectedYear;
              final years = List.generate(
                10,
                (i) => DateTime.now().year - 4 + i,
              );
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setDlg) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text('Select Year'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: years
                                .map(
                                  (y) => GestureDetector(
                                    onTap: () => setDlg(() => tmpYear = y),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tmpYear == y
                                            ? kPrimary
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: tmpYear == y
                                              ? kPrimary
                                              : kBorder,
                                        ),
                                      ),
                                      child: Text(
                                        '$y',
                                        style: TextStyle(
                                          color: tmpYear == y
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onYearChanged(tmpYear);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                          ),
                          child: const Text(
                            'Select',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
