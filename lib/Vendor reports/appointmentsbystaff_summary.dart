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

class _StaffSummary {
  final String staffName;
  final int totalAppointments;
  final int totalMinutes; // for sorting / display
  final double totalSale;

  _StaffSummary({
    required this.staffName,
    required this.totalAppointments,
    required this.totalMinutes,
    required this.totalSale,
  });

  /// e.g. "1 hr 30 min"
  String get durationLabel {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AppointmentsbyStaffSummary extends StatefulWidget {
  const AppointmentsbyStaffSummary({super.key});

  @override
  State<AppointmentsbyStaffSummary> createState() =>
      _AppointmentsbyStaffSummaryState();
}

class _AppointmentsbyStaffSummaryState
    extends State<AppointmentsbyStaffSummary> {
  // ── constants ───────────────────────────────────────────────────────────────
  static const Color _purple = Color(0xFF6C3EB8);

  // ── state ───────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMsg;

  List<_StaffSummary> _all = [];
  List<_StaffSummary> _filtered = [];

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

  // ── fetch & aggregate ──────────────────────────────────────────────────────
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

      // Response: { success, data: { allAppointments: { total, appointments: [...] } } }
      final allAppointments =
          response['data']?['allAppointments'] as Map<String, dynamic>?;
      final List<dynamic> appointments =
          (allAppointments?['appointments'] as List?) ?? [];

      _all = _aggregate(appointments);
      _applyFilter();
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Group raw appointment list by staff and compute totals.
  /// API fields used: staffName (String), duration (int, minutes), totalAmount (num).
  List<_StaffSummary> _aggregate(List<dynamic> appointments) {
    final Map<String, Map<String, dynamic>> map = {};

    for (final raw in appointments) {
      if (raw is! Map<String, dynamic>) continue;

      // ── staff name (plain string in this API) ─────────────────────────
      final String staffName =
          (raw['staffName'] as String?)?.trim().isNotEmpty == true
              ? (raw['staffName'] as String).trim()
              : 'Unassigned';

      // ── duration already in minutes (int) ────────────────────────────
      final int minutes = (raw['duration'] as num?)?.toInt() ?? 0;

      // ── use totalAmount as the sale figure ────────────────────────────
      final double amount =
          ((raw['totalAmount'] ?? raw['amount']) as num?)?.toDouble() ?? 0.0;

      // ── accumulate ───────────────────────────────────────────────────
      map.putIfAbsent(staffName, () => {'count': 0, 'minutes': 0, 'sale': 0.0});
      map[staffName]!['count'] = (map[staffName]!['count'] as int) + 1;
      map[staffName]!['minutes'] = (map[staffName]!['minutes'] as int) + minutes;
      map[staffName]!['sale'] = (map[staffName]!['sale'] as double) + amount;
    }

    return map.entries
        .map((e) => _StaffSummary(
              staffName: e.key,
              totalAppointments: e.value['count'] as int,
              totalMinutes: e.value['minutes'] as int,
              totalSale: e.value['sale'] as double,
            ))
        .toList()
      ..sort((a, b) => a.staffName.compareTo(b.staffName));
  }

  void _applyFilter() {
    final q = _searchText.toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = _all
          .where((s) => s.staffName.toLowerCase().contains(q))
          .toList();
    });
  }

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

  void _clearDateRange() {
    _dateRange = null;
    _fetchData();
  }

  // ── pagination ─────────────────────────────────────────────────────────────
  List<_StaffSummary> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ── helpers ────────────────────────────────────────────────────────────────
  String _fmtCurrency(num v) => '₹${NumberFormat('#,##0.00').format(v)}';

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Stats Row
            Row(
              children: [
                _statCard('Total Bookings', '${_filtered.fold(0, (sum, s) => sum + s.totalAppointments)}', Icons.event_available_rounded, Colors.blue),
                SizedBox(width: 10.w),
                _statCard('Total Revenue', _fmtCompact(_filtered.fold(0, (sum, s) => sum + s.totalSale)), Icons.payments_rounded, Colors.green),
              ],
            ),
            SizedBox(height: 16.h),

            // Table Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Appointments by Staff',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Detailed report showing appointment statistics aggregated by staff member.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),

                    // ── Toolbar ───────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          // search
                          Expanded(
                            child: SizedBox(
                              height: 40.h,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) {
                                  _searchText = v;
                                  _applyFilter();
                                },
                                style: GoogleFonts.poppins(fontSize: 13),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search_rounded,
                                      color: _purple.withOpacity(0.5), size: 20),
                                  hintText: 'Search staff…',
                                  hintStyle: GoogleFonts.poppins(
                                      fontSize: 12.5, color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F6FA),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: _purple, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),

                          // Filters (date range)
                          InkWell(
                            onTap: _pickDateRange,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 40.h,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: _dateRange != null
                                    ? _purple.withOpacity(0.08)
                                    : const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _dateRange != null
                                      ? _purple
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list_rounded,
                                      size: 16,
                                      color: _dateRange != null
                                          ? _purple
                                          : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    _dateRange != null
                                        ? '${DateFormat('dd MMM').format(_dateRange!.start)} – ${DateFormat('dd MMM yy').format(_dateRange!.end)}'
                                        : 'Filters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: _dateRange != null
                                          ? _purple
                                          : Colors.grey.shade600,
                                      fontWeight: _dateRange != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (_dateRange != null) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: _clearDateRange,
                                      child: const Icon(Icons.close_rounded,
                                          size: 14, color: _purple),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),

                          // Export
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export coming soon…')),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 40.h,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: _purple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.upload_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Export',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),

                    // ── Table ─────────────────────────────────────────────────
                    Expanded(child: _buildTable()),

                    // ── Pagination ────────────────────────────────────────────
                    Divider(height: 1, color: Colors.grey.shade100),
                    _buildPaginationFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60.h,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Appointments by Staff',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const My_Profile()),
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _purple, width: 1.5),
                ),
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

  // ── Table ──────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _purple));
    }
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Failed to load data',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMsg!,
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No records found',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── column headers ────────────────────────────────────────────────
        Container(
          color: const Color(0xFFF9F9FB),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              _hCell('Staff Name', flex: 4),
              _hCell('Total Appointments', flex: 3),
              _hCell('Total Duration', flex: 3),
              _hCell('Total Sale', flex: 3),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // ── data rows ─────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            itemCount: _pageItems.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) => _buildRow(_pageItems[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_StaffSummary s, int idx) {
    return Container(
      color: idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFF),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              s.staffName,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${s.totalAppointments}',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.durationLabel,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtCurrency(s.totalSale),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPaginationFooter() {
    final start = _filtered.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Text(
            'Showing $start to $end of ${_filtered.length} results',
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade500),
          ),
          const Spacer(),
          Text('Rows per page ',
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: Colors.grey.shade500)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
              items: [5, 10, 20, 50]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _rowsPerPage = v;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade600),
          ),
          SizedBox(width: 8.w),
          _pageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--),
          ),
          SizedBox(width: 4.w),
          _pageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages - 1,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(
      {required IconData icon,
      required bool enabled,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: enabled ? Colors.white : const Color(0xFFF5F6FA),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black54 : Colors.grey.shade300,
        ),
      ),
    );
  }

  // ── Components ──────────────────────────────────────────────────────────────
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 16, color: color),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtCompact(num v) => '₹${NumberFormat('#,##0').format(v)}';

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _hCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
