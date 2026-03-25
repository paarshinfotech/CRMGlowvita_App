import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../Notification.dart';
import '../my_Profile.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceSummary {
  final String serviceName;
  final int totalAppointments;
  final int totalDuration; // minutes
  final double totalSale;

  _ServiceSummary({
    required this.serviceName,
    required this.totalAppointments,
    required this.totalDuration,
    required this.totalSale,
  });

  String get durationLabel {
    final h = totalDuration ~/ 60;
    final m = totalDuration % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AppointmentsbyServicesSummary extends StatefulWidget {
  const AppointmentsbyServicesSummary({super.key});

  @override
  State<AppointmentsbyServicesSummary> createState() =>
      _AppointmentsbyServicesSummaryState();
}

class _AppointmentsbyServicesSummaryState
    extends State<AppointmentsbyServicesSummary> {
  // ── constants ───────────────────────────────────────────────────────────────
  static const Color _purple = Color(0xFF6C3EB8);

  // ── state ───────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMsg;

  List<_ServiceSummary> _all = [];
  List<_ServiceSummary> _filtered = [];

  String _searchText = '';
  DateTimeRange? _dateRange;

  // pagination
  int _rowsPerPage = 10;
  int _currentPage = 0;

  final _searchCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final response = await ApiService.getAllAppointmentsReport(
        startDate: _dateRange != null
            ? DateFormat('yyyy-MM-dd').format(_dateRange!.start)
            : null,
        endDate: _dateRange != null
            ? DateFormat('yyyy-MM-dd').format(_dateRange!.end)
            : null,
      );

      // JSON Structure: { success, data: { allAppointments: { total, appointments: [...] } } }
      final allData = response['data']?['allAppointments'];
      final List<dynamic> rawList = (allData?['appointments'] as List?) ?? [];

      _all = _aggregate(rawList);
      _applyFilter();
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<_ServiceSummary> _aggregate(List<dynamic> appointments) {
    final Map<String, Map<String, dynamic>> map = {};

    for (final raw in appointments) {
      if (raw is! Map<String, dynamic>) continue;

      final String srvName = (raw['serviceName'] as String?)?.trim().isNotEmpty == true
          ? (raw['serviceName'] as String).trim()
          : 'Unknown Service';

      final int minutes = (raw['duration'] as num?)?.toInt() ?? 0;
      final double amount = ((raw['totalAmount'] ?? raw['amount']) as num?)?.toDouble() ?? 0.0;

      map.putIfAbsent(srvName, () => {'count': 0, 'minutes': 0, 'sale': 0.0});
      map[srvName]!['count'] = (map[srvName]!['count'] as int) + 1;
      map[srvName]!['minutes'] = (map[srvName]!['minutes'] as int) + minutes;
      map[srvName]!['sale'] = (map[srvName]!['sale'] as double) + amount;
    }

    return map.entries
        .map((e) => _ServiceSummary(
              serviceName: e.key,
              totalAppointments: e.value['count'] as int,
              totalDuration: e.value['minutes'] as int,
              totalSale: e.value['sale'] as double,
            ))
        .toList()
      ..sort((a, b) => b.totalAppointments.compareTo(a.totalAppointments)); // Sort by popularity
  }

  void _applyFilter() {
    final q = _searchText.toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = _all.where((s) => s.serviceName.toLowerCase().contains(q)).toList();
    });
  }

  int get _totalCount => _filtered.fold(0, (sum, s) => sum + s.totalAppointments);

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmtCurrency(num v) => '₹${NumberFormat('#,##0').format(v)}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateRange = picked;
      _fetchData();
    }
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  List<_ServiceSummary> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appointments by Service',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    Text('Analyze popular services and their impact on revenue.',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),

              // Toolbar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38.h,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) { _searchText = v; _applyFilter(); },
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                            hintText: 'Search service...',
                            hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _toolbarBtn(
                      icon: Icons.filter_list_rounded,
                      label: _dateRange != null ? 'Filtered' : 'Date Range',
                      isActive: _dateRange != null,
                      onTap: _pickDateRange,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),

              // Table
              Expanded(child: _buildTable()),

              // Footer
              Divider(height: 1, color: Colors.grey.shade100),
              _buildPaginationFooter(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60.h,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
      ),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Appointments by Service',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const My_Profile())),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _purple, width: 1.5)),
                child: const CircleAvatar(
                  radius: 17,
                  backgroundImage: AssetImage('assets/images/profile.jpeg'),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _purple));
    if (_errorMsg != null) return _buildErrorState();
    if (_filtered.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        Container(
          color: const Color(0xFFF9F9FB),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              _hCell('Service Name', flex: 4),
              _hCell('Appts', flex: 2, center: true),
              _hCell('Duration', flex: 3),
              _hCell('Revenue', flex: 3, right: true),
              _hCell('Share', flex: 2, right: true),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: ListView.separated(
            itemCount: _pageItems.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) => _buildRow(_pageItems[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_ServiceSummary s, int idx) {
    double percentage = (_totalCount > 0) ? (s.totalAppointments / _totalCount) * 100 : 0;

    return Container(
      color: idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFF),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(s.serviceName,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('${s.totalAppointments}',
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.black87)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(s.durationLabel,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 3,
            child: Text(_fmtCurrency(s.totalSale),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _purple)),
          ),
          Expanded(
            flex: 2,
            child: Text('${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _hCell(String label, {int flex = 1, bool center = false, bool right = false}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: center ? TextAlign.center : (right ? TextAlign.right : TextAlign.left),
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.category_outlined, size: 50, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No services found', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 50, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text('Oops! Failed to load data', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        Padding(padding: const EdgeInsets.all(16), child: Text(_errorMsg!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))),
        ElevatedButton(onPressed: _fetchData, style: ElevatedButton.styleFrom(backgroundColor: _purple), child: const Text('Retry', style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  Widget _buildPaginationFooter() {
    final start = _filtered.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Text('Showing $start–$end of ${_filtered.length}',
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500)),
          const Spacer(),
          _pageBtn(Icons.chevron_left_rounded, _currentPage > 0, () => setState(() => _currentPage--)),
          SizedBox(width: 8.w),
          _pageBtn(Icons.chevron_right_rounded, _currentPage < _totalPages - 1, () => setState(() => _currentPage++)),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6), color: enabled ? Colors.white : const Color(0xFFF5F6FA)),
        child: Icon(icon, size: 18, color: enabled ? Colors.black54 : Colors.grey.shade200),
      ),
    );
  }

  Widget _toolbarBtn({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38.h,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _purple.withOpacity(0.08) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? _purple : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? _purple : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isActive ? _purple : Colors.grey.shade600, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
