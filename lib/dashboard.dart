import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:glowvita/my_Profile.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;

import 'Notification.dart';
import 'appointment.dart';
import 'widgets/custom_drawer.dart';
import 'shared_data.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';
import 'appointment_model.dart';
import 'billing_invoice_model.dart';

// ─────────────────────────────────────────────
// BRAND COLORS  (deep plum from the Apply button)
// ─────────────────────────────────────────────
const Color kPrimary = Color(0xFF3D1A47);
const Color kPrimaryLight = Color(0xFF6B3FA0);
const Color kBg = Color(0xFFF7F7F8);
const Color kCard = Colors.white;
const Color kBorder = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────
// FILTER ENUMS
// ─────────────────────────────────────────────
enum _FilterType { presetPeriod, dateRange }

enum _PresetPeriod { day, month, year, allTime }

// ═══════════════════════════════════════════════════════
//  DASHBOARD PAGE
// ═══════════════════════════════════════════════════════
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  VendorProfile? _profile;

  late AnimationController _kpiCtrl;
  late Animation<double> _kpiFade;
  late List<AnimationController> _apptCtrlList;
  late List<Animation<double>> _apptAnimList;

  // ── Filter state ──────────────────────────
  _FilterType _filterType = _FilterType.presetPeriod;
  _PresetPeriod _presetPeriod = _PresetPeriod.allTime;
  DateTime? _selDay;
  int _selMonth = DateTime.now().month;
  int _selYear = DateTime.now().year;

  // ── Dynamic Data ──────────────────────────
  List<AppointmentModel> _allAppointments = [];
  List<Service> _allServices = [];
  List<Product> _allProducts = [];
  List<Map<String, dynamic>> _allReviews = [];
  List<BillingInvoice> _allInvoices = [];
  List<Map<String, dynamic>> _allExpenses = [];
  bool _isLoading = true;

  // KPI Values
  double _totalRevenue = 0;
  int _totalBookings = 0;
  double _bookingHours = 0;
  double _serviceRevenue = 0;
  double _productRevenue = 0;
  int _cancelledAppts = 0;
  int _upcomingAppts = 0;
  double _totalBusiness = 0;
  int _completedAppts = 0;
  double _totalExpense = 0;
  double _counterSale = 0;

  // Chart Data
  List<_PieSegment> _servicePieSegments = [];
  List<Map<String, dynamic>> _topServicesLegend = [];
  List<double> _monthlySalesData = List.filled(12, 0.0);
  List<String> _topProductNames = [];
  List<double> _topProductValues = [];
  double _salonFeedback = 0, _productFeedback = 0, _serviceFeedback = 0;

  @override
  void initState() {
    super.initState();
    _kpiCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _kpiFade = CurvedAnimation(parent: _kpiCtrl, curve: Curves.easeInOut);

    _apptCtrlList = List.generate(
      appointments.length,
      (i) => AnimationController(
          duration: Duration(milliseconds: 300 + i * 100), vsync: this),
    );
    _apptAnimList = _apptCtrlList
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    _fetchProfile();
    _fetchAllData();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _kpiCtrl.forward();
      for (final c in _apptCtrlList) c.forward();
    });
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAppointments(),
        ApiService.getServices(),
        ApiService.getProducts(),
        ApiService.getReviews(),
        ApiService.getInvoices(),
        ApiService.getExpenses(),
      ]);

      if (mounted) {
        final appointmentData = results[0] as Map<String, dynamic>;
        setState(() {
          _allAppointments = appointmentData['data'] ?? [];
          _allServices = results[1] as List<Service>;
          _allProducts = results[2] as List<Product>;
          _allReviews = results[3] as List<Map<String, dynamic>>;
          _allInvoices = results[4] as List<BillingInvoice>;
          _allExpenses = results[5] as List<Map<String, dynamic>>;
          _calculateKpis();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchAllData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateKpis() {
    _totalRevenue = 0;
    _serviceRevenue = 0;
    _productRevenue = 0;
    _counterSale = 0;

    for (var invoice in _allInvoices) {
      final total = invoice.totalAmount;
      _totalRevenue += total;

      if (invoice.items.isNotEmpty) {
        for (var item in invoice.items) {
          final price = item.price;
          final qty = item.quantity;
          if (item.itemType == 'product') {
            _productRevenue += price * qty;
          } else {
            _serviceRevenue += price * qty;
          }
        }
      }

      // Counter sale if not online
      if (invoice.paymentStatus == 'paid') {
        _counterSale += total;
      }
    }

    _totalBookings = _allAppointments.length;
    _bookingHours = 0;
    _cancelledAppts = 0;
    _upcomingAppts = 0;
    _completedAppts = 0;

    final now = DateTime.now();
    for (var appt in _allAppointments) {
      // Calculate duration
      final duration = appt.duration ?? 0;
      _bookingHours += duration / 60.0;

      if (appt.status?.toLowerCase() == 'cancelled') {
        _cancelledAppts++;
      } else if (appt.status?.toLowerCase() == 'completed') {
        _completedAppts++;
      }

      // Check for upcoming
      if (appt.date != null && appt.date!.isAfter(now)) {
        if (appt.status?.toLowerCase() != 'cancelled') {
          _upcomingAppts++;
        }
      }
    }

    _totalBusiness = _totalRevenue;

    _totalExpense = 0;
    for (var expense in _allExpenses) {
      _totalExpense += (expense['amount'] as num?)?.toDouble() ?? 0;
    }

    _calculateCharts();
  }

  void _calculateCharts() {
    // Top Services
    Map<String, int> serviceCounts = {};
    for (var appt in _allAppointments) {
      if (appt.serviceName != null) {
        serviceCounts[appt.serviceName!] =
            (serviceCounts[appt.serviceName!] ?? 0) + 1;
      }
    }
    var sortedServices = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _servicePieSegments = [];
    _topServicesLegend = [];
    int totalTopBookings = 0;
    final top4Services = sortedServices.take(4).toList();
    for (var e in top4Services) totalTopBookings += e.value;

    final List<Color> pieColors = [
      const Color(0xFF26A69A),
      const Color(0xFF42A5F5),
      const Color(0xFFFF7043),
      const Color(0xFFEC407A)
    ];

    for (int i = 0; i < top4Services.length; i++) {
      final percent = totalTopBookings > 0
          ? (top4Services[i].value / totalTopBookings) * 100
          : 0.0;
      _servicePieSegments.add(_PieSegment(
          value: top4Services[i].value.toDouble(), color: pieColors[i]));
      _topServicesLegend.add({
        'label': top4Services[i].key,
        'percent': '${percent.toStringAsFixed(0)}%',
        'color': pieColors[i]
      });
    }

    // Sales Overview - Last 7 months
    _monthlySalesData = List.filled(7, 0.0);
    double maxMonthly = 0;
    DateTime now = DateTime.now();
    for (var invoice in _allInvoices) {
      if (invoice.createdAt != null) {
        // Calculate difference in months
        int monthsDiff = (now.year - invoice.createdAt.year) * 12 +
            (now.month - invoice.createdAt.month);
        if (monthsDiff >= 0 && monthsDiff < 7) {
          int index = 6 - monthsDiff; // 0 is 6 months ago, 6 is current month
          _monthlySalesData[index] += invoice.totalAmount;
          if (_monthlySalesData[index] > maxMonthly)
            maxMonthly = _monthlySalesData[index];
        }
      }
    }
    if (maxMonthly > 0) {
      for (int i = 0; i < 7; i++) _monthlySalesData[i] /= maxMonthly;
    }

    // Top Products
    Map<String, int> productSales = {};
    for (var invoice in _allInvoices) {
      for (var item in invoice.items) {
        if (item.itemType == 'product') {
          productSales[item.name] =
              (productSales[item.name] ?? 0) + item.quantity;
        }
      }
    }
    var sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _topProductNames = [];
    _topProductValues = [];
    final top5Products = sortedProducts.take(5).toList();
    int maxProd = top5Products.isNotEmpty ? top5Products[0].value : 1;
    for (var p in top5Products) {
      _topProductNames.add(p.key);
      _topProductValues.add(p.value / maxProd);
    }

    // Feedback
    // Assuming reviews have a 'category' or similar, else average all
    double totalSalon = 0, totalProd = 0, totalServ = 0;
    int cSalon = 0, cProd = 0, cServ = 0;
    for (var rev in _allReviews) {
      double rating = (rev['rating'] as num?)?.toDouble() ?? 0;
      String cat = (rev['category'] ?? '').toString().toLowerCase();
      if (cat.contains('salon')) {
        totalSalon += rating;
        cSalon++;
      } else if (cat.contains('product')) {
        totalProd += rating;
        cProd++;
      } else {
        totalServ += rating;
        cServ++;
      }
    }
    _salonFeedback = cSalon > 0 ? (totalSalon / cSalon) / 5.0 : 0.5;
    _productFeedback = cProd > 0 ? (totalProd / cProd) / 5.0 : 0.6;
    _serviceFeedback = cServ > 0 ? (totalServ / cServ) / 5.0 : 0.8;
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
          color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
    );
  }

  void _applyFilter() {
    setState(() {
      _calculateKpis();
    });
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
      'Dec'
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
    for (final c in _apptCtrlList) c.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
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
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: kPrimary, secondary: kPrimaryLight),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        child: Scaffold(
          drawer: CustomDrawer(
            currentPage: 'Dashboard',
            userName: _profile?.businessName ?? 'HarshalSpa',
            profileImageUrl: _profile?.profileImage ?? '',
          ),
          backgroundColor: kBg,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // ... existing code for AppBar and Filter Row ...
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
                      title: Text('Vendor Dashboard',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.black),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationPage())),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => My_Profile())),
                          child: Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: kPrimary,
                              child: ClipOval(
                                child: (_profile != null &&
                                        _profile!.profileImage.isNotEmpty)
                                    ? Image.network(
                                        _profile!.profileImage,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, _, __) =>
                                            _buildInitialAvatar(),
                                        loadingBuilder:
                                            (ctx, child, progress) =>
                                                progress == null
                                                    ? child
                                                    : _buildInitialAvatar(),
                                      )
                                    : _buildInitialAvatar(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Smart Filter Row ───────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        color: kCard,
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
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
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 18.w),
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('Apply',
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ),
                            ]),
                            if (_filterType == _FilterType.presetPeriod &&
                                _presetPeriod != _PresetPeriod.allTime) ...[
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: kPrimary.withOpacity(0.2))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.filter_alt_outlined,
                                        size: 11.sp, color: kPrimary),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _buildPeriodLabel(),
                                      style: TextStyle(
                                          fontSize: 10.sp,
                                          color: kPrimary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                    // ── KPI Grid ───────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: FadeTransition(
                          opacity: _kpiFade,
                          child: Column(children: [
                            _kpiRow([
                              _KpiGridCard(
                                  title: 'Total Revenue',
                                  value:
                                      '₹ ${_totalRevenue.toStringAsFixed(2)}',
                                  icon: '🛒',
                                  iconBg: const Color(0xFFFFF3E0)),
                              _KpiGridCard(
                                  title: 'Total Bookings',
                                  value: '$_totalBookings',
                                  icon: '📅',
                                  iconBg: const Color(0xFFE3F2FD)),
                              _KpiGridCard(
                                  title: 'Booking Hours',
                                  value: '${_bookingHours.toStringAsFixed(1)}h',
                                  icon: '❤️',
                                  iconBg: const Color(0xFFFCE4EC)),
                              _KpiGridCard(
                                  title: 'Selling Service Revenue',
                                  value:
                                      '₹ ${_serviceRevenue.toStringAsFixed(2)}',
                                  icon: '🏷️',
                                  iconBg: const Color(0xFFF3E5F5)),
                            ]),
                            SizedBox(height: 8.h),
                            _kpiRow([
                              _KpiGridCard(
                                  title: 'Selling Products Revenue',
                                  value:
                                      '₹ ${_productRevenue.toStringAsFixed(2)}',
                                  icon: '🧴',
                                  iconBg: const Color(0xFFE8F5E9)),
                              _KpiGridCard(
                                  title: 'Cancelled Appointments',
                                  value: '$_cancelledAppts',
                                  icon: '❌',
                                  iconBg: const Color(0xFFFFEBEE)),
                              _KpiGridCard(
                                  title: 'Upcoming Appointments',
                                  value: '$_upcomingAppts',
                                  icon: '📋',
                                  iconBg: const Color(0xFFFFF8E1)),
                              _KpiGridCard(
                                  title: 'Total Business',
                                  value:
                                      '₹ ${_totalBusiness.toStringAsFixed(2)}',
                                  icon: '💰',
                                  iconBg: const Color(0xFFFFF3E0)),
                            ]),
                            SizedBox(height: 8.h),
                            Row(children: [
                              Expanded(
                                  child: _KpiGridCard(
                                      title: 'Completed Appointments',
                                      value: '$_completedAppts',
                                      icon: '✅',
                                      iconBg: const Color(0xFFE8F5E9))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: _KpiGridCard(
                                      title: 'Total Expense',
                                      value:
                                          '₹ ${_totalExpense.toStringAsFixed(2)}',
                                      icon: '💸',
                                      iconBg: const Color(0xFFFCE4EC))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: _KpiGridCard(
                                      title: 'Total Counter Sale',
                                      value:
                                          '₹ ${_counterSale.toStringAsFixed(2)}',
                                      icon: '🖥️',
                                      iconBg: const Color(0xFFE3F2FD))),
                              SizedBox(width: 8.w),
                              const Expanded(child: SizedBox()),
                            ]),
                          ]),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // ── Upcoming Appointments ──────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Upcoming Appointments',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          'You have $_upcomingAppts upcoming appointments',
                                          style: TextStyle(
                                              fontSize: 9.sp,
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const Appointment())),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 5.h),
                                      decoration: BoxDecoration(
                                          border: Border.all(color: kBorder),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text('View All',
                                          style: TextStyle(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Client',
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Service',
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Date',
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500))),
                                  Expanded(
                                      flex: 1,
                                      child: Text('Time',
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.end)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ..._allAppointments
                                .where((a) =>
                                    a.date != null &&
                                    a.date!.isAfter(DateTime.now()) &&
                                    a.status?.toLowerCase() != 'cancelled')
                                .take(4)
                                .map((a) => Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 12.h),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Text(a.clientName ?? 'N/A',
                                                  style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w600))),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                  a.serviceName ?? 'N/A',
                                                  style: TextStyle(
                                                      fontSize: 10.sp,
                                                      color:
                                                          Colors.grey[700]))),
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                  a.date != null
                                                      ? DateFormat('MMM d, y')
                                                          .format(a.date!)
                                                      : '--',
                                                  style: TextStyle(
                                                      fontSize: 10.sp,
                                                      color:
                                                          Colors.grey[700]))),
                                          Expanded(
                                              flex: 1,
                                              child: Text(
                                                  a.startTime ?? '--:--',
                                                  style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                  textAlign: TextAlign.end)),
                                        ],
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // ── Top Services ───────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Top Services',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700)),
                            Text('Top services based on customer bookings',
                                style: TextStyle(
                                    fontSize: 9.sp, color: Colors.grey[500])),
                            SizedBox(height: 12.h),
                            Row(children: [
                              SizedBox(
                                width: 90.w,
                                height: 90.w,
                                child: _servicePieSegments.isEmpty
                                    ? Center(
                                        child: Text('No data',
                                            style: TextStyle(fontSize: 8.sp)))
                                    : CustomPaint(
                                        painter: _PieChartPainter(
                                            segments: _servicePieSegments),
                                      ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: _topServicesLegend.isEmpty
                                    ? Text('No services found',
                                        style: TextStyle(fontSize: 9.sp))
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _topServicesLegend
                                            .map((e) => Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 6.h),
                                                  child: _ServiceLegendRow(
                                                      color: e['color'],
                                                      label: e['label'],
                                                      percent: e['percent']),
                                                ))
                                            .toList(),
                                      ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // ── Sales Overview (scrollable Jan–Dec) ────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                        decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Sales Overview',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          'A detailed summary of your sales activity for the last 7 months.',
                                          style: TextStyle(
                                              fontSize: 9.sp,
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                // Year selector removed
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _SalesOverviewChart(data: _monthlySalesData),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // ── Top Selling Products ───────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                        decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Top Selling Products',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700)),
                            Text('Products with the highest sales volume',
                                style: TextStyle(
                                    fontSize: 9.sp, color: Colors.grey[500])),
                            SizedBox(height: 12.h),
                            _TopProductsChart(
                                products: _topProductNames,
                                values: _topProductValues),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // ── Client Feedback ────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Client Feedback',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700)),
                            Text('Straight from your clients hearts',
                                style: TextStyle(
                                    fontSize: 9.sp, color: Colors.grey[500])),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _GaugeWidget(
                                    label: '✂️ Salon',
                                    labelBg: const Color(0xFFFFF9C4),
                                    value: _salonFeedback),
                                _GaugeWidget(
                                    label: '🛍️ Product',
                                    labelBg: const Color(0xFFFFE0B2),
                                    value: _productFeedback),
                                _GaugeWidget(
                                    label: '💆 Services',
                                    labelBg: const Color(0xFFE8F5E9),
                                    value: _serviceFeedback),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendDot(
                                    color: const Color(0xFFB3E5FC),
                                    label: 'Low (0-2.5)'),
                                SizedBox(width: 10.w),
                                _LegendDot(
                                    color: const Color(0xFF42A5F5),
                                    label: 'Medium (2.5-4.0)'),
                                SizedBox(width: 10.w),
                                _LegendDot(
                                    color: const Color(0xFF1565C0),
                                    label: 'High (4.0-5.0)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                  ],
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
// FILTER BOTTOM SHEETS
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
// SALES OVERVIEW CHART – scrollable Jan to Dec
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
      child: Row(children: [
        // Y-axis labels
        SizedBox(
          width: yAxisW,
          height: chartH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _yLabels
                .map((l) => Text(l,
                    style: TextStyle(fontSize: 7.sp, color: Colors.grey[500])))
                .toList(),
          ),
        ),
        const SizedBox(width: 4),
        // Scrollable chart + x labels
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: slotW * _months.length,
              child: Column(children: [
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
                        .map((m) => SizedBox(
                              width: slotW,
                              child: Text(m,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 8.sp, color: Colors.grey[500])),
                            ))
                        .toList(),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
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
        (i) => Offset(
              slotW * i + slotW / 2,
              padTop + chartH * (1 - data[i]),
            ));

    // Fill under line
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
        ..shader = ui.Gradient.linear(
          Offset(0, padTop),
          Offset(0, size.height),
          [
            const Color(0xFF42A5F5).withOpacity(0.22),
            const Color(0xFF42A5F5).withOpacity(0.01)
          ],
        ),
    );

    // Grid lines (dashed)
    final gridP = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + chartH * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridP);
    }

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++)
      path.lineTo(points[i].dx, points[i].dy);
    canvas.drawPath(path, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = const Color(0xFF42A5F5));
      canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // Tooltip on peak
    final peakIdx = data.indexOf(data.reduce(math.max));
    final peak = points[peakIdx];
    const tw = 68.0, th = 20.0;
    final tx =
        peak.dx + tw / 2 + 6 > size.width ? peak.dx - tw - 4 : peak.dx + 4;
    final trect = Rect.fromLTWH(tx, peak.dy - th - 4, tw, th);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF42A5F5),
    );
    final tp = TextPainter(
      text: const TextSpan(
          text: '64,3664.77',
          style: TextStyle(
              color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: tw);
    tp.paint(canvas, Offset(tx + (tw - tp.width) / 2, peak.dy - th - 2));
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
// TOP SELLING PRODUCTS CHART – scrollable with x-axis
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
      child: Row(children: [
        // Y-axis
        SizedBox(
          width: yAxisW,
          height: chartH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _yLabels
                .map((l) => Text(l,
                    style: TextStyle(fontSize: 7.sp, color: Colors.grey[500])))
                .toList(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: slotW * products.length,
              child: Column(children: [
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
                        .map((p) => SizedBox(
                              width: slotW,
                              child: Text(p,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 7.5.sp,
                                      color: Colors.grey[600])),
                            ))
                        .toList(),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
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

    // Dashed grid
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
        Paint()..color = colors[i],
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
// SMALL SHARED WIDGETS
// ═══════════════════════════════════════════════════════

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
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_FilterType>(
          value: current,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black),
          items: const [
            DropdownMenuItem(
                value: _FilterType.presetPeriod, child: Text('Preset Period')),
            DropdownMenuItem(
                value: _FilterType.dateRange, child: Text('Date Range')),
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
                  colorScheme: const ColorScheme.light(primary: kPrimary)),
              child: child!,
            ),
          );
          if (picked != null) {
            // we could update fromDate/toDate here if we had them as state in the parent
          }
        },
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text('Select Range',
                    style: TextStyle(
                        fontSize: 10.sp, fontWeight: FontWeight.w500)),
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
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_PresetPeriod>(
          value: presetPeriod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black),
          items: const [
            DropdownMenuItem(
                value: _PresetPeriod.allTime, child: Text('All Time')),
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
                      colorScheme: const ColorScheme.light(primary: kPrimary)),
                  child: child!,
                ),
              );
              if (d != null) onDayChanged(d);
            } else if (p == _PresetPeriod.month) {
              // Show month+year picker dialog
              int tmpMonth = selectedMonth;
              int tmpYear = selectedYear;
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
                'Dec'
              ];
              final years =
                  List.generate(10, (i) => DateTime.now().year - 4 + i);
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setDlg) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      title: Text('Select Month & Year',
                          style: TextStyle(
                              fontSize: 13.sp, fontWeight: FontWeight.w700)),
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        // Year row
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 2.h),
                          decoration: BoxDecoration(
                              border: Border.all(color: kBorder),
                              borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: tmpYear,
                              isExpanded: true,
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.black),
                              items: years
                                  .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text('$y',
                                            style: TextStyle(fontSize: 12.sp)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setDlg(() => tmpYear = v);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Month grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          children: List.generate(12, (i) {
                            final sel = tmpMonth == i + 1;
                            return GestureDetector(
                              onTap: () => setDlg(() => tmpMonth = i + 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: sel ? kPrimary : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(months[i],
                                    style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? Colors.white
                                            : Colors.black87)),
                              ),
                            );
                          }),
                        ),
                      ]),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.grey[600])),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          onPressed: () {
                            onMonthChanged(tmpMonth);
                            onYearChanged(tmpYear);
                            Navigator.pop(ctx);
                          },
                          child: Text('Apply',
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else if (p == _PresetPeriod.year) {
              // Show year picker dialog
              int tmpYear = selectedYear;
              final years =
                  List.generate(10, (i) => DateTime.now().year - 4 + i);
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setDlg) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      title: Text('Select Year',
                          style: TextStyle(
                              fontSize: 13.sp, fontWeight: FontWeight.w700)),
                      content: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: years.map((y) {
                          final sel = tmpYear == y;
                          return GestureDetector(
                            onTap: () => setDlg(() => tmpYear = y),
                            child: Container(
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('$y',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          sel ? Colors.white : Colors.black87)),
                            ),
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.grey[600])),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          onPressed: () {
                            onYearChanged(tmpYear);
                            Navigator.pop(ctx);
                          },
                          child: Text('Apply',
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
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

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Center(
          child: Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(999)),
          ),
        ),
      );
}

class _SheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        title: Text(label,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? kPrimary : Colors.black87)),
        trailing: selected ? const Icon(Icons.check, color: kPrimary) : null,
      );
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
              color: selected ? kPrimary : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87)),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
      );
}

class _DatePickerInline extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;
  const _DatePickerInline({required this.initialDate, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: kPrimary, onPrimary: Colors.white)),
          child: CalendarDatePicker(
            initialDate: initialDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: onChanged,
          ),
        ),
      );
}

class _MonthYearPicker extends StatelessWidget {
  final int month, year;
  final void Function(int, int) onChanged;
  const _MonthYearPicker(
      {required this.month, required this.year, required this.onChanged});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(children: [
          Expanded(
            child: _PickerDropdown(
              label: _months[month - 1],
              items: List.generate(12, (i) => _months[i]),
              onSelect: (v) => onChanged(_months.indexOf(v) + 1, year),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _PickerDropdown(
              label: '$year',
              items: List.generate(10, (i) => '${DateTime.now().year - 4 + i}'),
              onSelect: (v) => onChanged(month, int.parse(v)),
            ),
          ),
        ]),
      );
}

class _YearPickerWidget extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;
  const _YearPickerWidget({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: _PickerDropdown(
          label: '$year',
          items: List.generate(10, (i) => '${DateTime.now().year - 4 + i}'),
          onSelect: (v) => onChanged(int.parse(v)),
        ),
      );
}

class _PickerDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueChanged<String> onSelect;
  const _PickerDropdown(
      {required this.label, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: label,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kBorder)),
        ),
        style: TextStyle(
            fontSize: 11.sp, color: Colors.black87, fontFamily: 'Poppins'),
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) {
          if (v != null) onSelect(v);
        },
      );
}

class _DateTile extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(8)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 9.sp, color: Colors.grey[500])),
            SizedBox(height: 4.h),
            Row(children: [
              const Icon(Icons.calendar_today, size: 13, color: kPrimary),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────
// KPI GRID CARD
// ─────────────────────────────────────────────
class _KpiGridCard extends StatelessWidget {
  final String title, value, icon;
  final Color iconBg;
  const _KpiGridCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.iconBg});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 14))),
            ),
            SizedBox(height: 6.h),
            Text(title,
                style: TextStyle(
                    fontSize: 7.5.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            Text(value,
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────
// UPCOMING APPOINTMENT ROW
// ─────────────────────────────────────────────
class _UpcomingAppointmentRow extends StatelessWidget {
  final Map<String, dynamic> appointment;
  const _UpcomingAppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: appointment['image'] != null
                ? AssetImage(appointment['image'] as String)
                : null,
            backgroundColor: Colors.grey[200],
            child: appointment['image'] == null
                ? Icon(Icons.person, size: 18, color: Colors.grey[400])
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appointment['name'] ?? '',
                  style:
                      TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600)),
              Text(appointment['service'] ?? '',
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey[500])),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(appointment['time'] ?? '',
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600)),
            Text(appointment['date'] ?? '',
                style: TextStyle(fontSize: 9.sp, color: Colors.grey[500])),
          ]),
        ]),
      );
}

// ─────────────────────────────────────────────
// SERVICE LEGEND ROW
// ─────────────────────────────────────────────
class _ServiceLegendRow extends StatelessWidget {
  final Color color;
  final String label, percent;
  const _ServiceLegendRow(
      {required this.color, required this.label, required this.percent});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
        ),
        Text(percent,
            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600)),
      ]);
}

// ─────────────────────────────────────────────
// GAUGE WIDGET
// ─────────────────────────────────────────────
class _GaugeWidget extends StatelessWidget {
  final String label;
  final Color labelBg;
  final double value;
  const _GaugeWidget(
      {required this.label, required this.labelBg, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          width: 70.w,
          height: 45.w,
          child: CustomPaint(painter: _GaugePainter(value: value)),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
              color: labelBg, borderRadius: BorderRadius.circular(6)),
          child: Text(label,
              style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w600)),
        ),
      ]);
}

// ─────────────────────────────────────────────
// LEGEND DOT
// ─────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(fontSize: 7.sp, color: Colors.grey[600])),
        ],
      );
}

// ─────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────
class _PieSegment {
  final double value;
  final Color color;
  const _PieSegment({required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  const _PieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (s, e) => s + e.value);
    double start = -math.pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.05,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _GaugePainter extends CustomPainter {
  final double value;
  const _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = Colors.grey[200]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round);

    final valueColor = value < 0.33
        ? const Color(0xFFB3E5FC)
        : value < 0.66
            ? const Color(0xFF42A5F5)
            : const Color(0xFF1565C0);

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * value,
        false,
        Paint()
          ..color = valueColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round);

    final angle = math.pi + math.pi * value;
    canvas.drawLine(
      center,
      Offset(center.dx + (radius - 4) * math.cos(angle),
          center.dy + (radius - 4) * math.sin(angle)),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 4, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────
// DEMO DATA
// ─────────────────────────────────────────────
final List<Map<String, dynamic>> upcomingAppointments = [
  {
    'name': 'Olivia Cameron',
    'service': 'Party MakeUp',
    'time': '11:00AM',
    'date': '21 Jan',
    'image': null
  },
  {
    'name': 'Vishakha Mishra',
    'service': 'Bridal MakeUp',
    'time': '01:00PM',
    'date': '21 Jan',
    'image': null
  },
  {
    'name': 'Nidhi Deshmukh',
    'service': 'Nail Extension',
    'time': '03:00PM',
    'date': '21 Jan',
    'image': null
  },
];

final List<Map<String, dynamic>> staffList =
    sharedDataService.getDashboardStaffList();

final List<Map<String, dynamic>> appointments =
    sharedDataService.getDashboardAppointments();

String getTotal(String key) {
  double total = 0;
  for (final s in staffList) total += double.tryParse(s[key].toString()) ?? 0;
  return total.toStringAsFixed(2);
}
