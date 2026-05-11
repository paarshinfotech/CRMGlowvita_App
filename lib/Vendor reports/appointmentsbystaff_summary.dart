import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _StaffSummary {
  final String staffName;
  final int totalAppointments;
  final int totalMinutes; 
  final double totalSale;

  _StaffSummary({
    required this.staffName,
    required this.totalAppointments,
    required this.totalMinutes,
    required this.totalSale,
  });

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
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<_StaffSummary> _all = [];
  List<_StaffSummary> _filtered = [];

  String _searchText = '';
  DateTimeRange? _dateRange;

  int _rowsPerPage = 10;
  int _currentPage = 0;

  final _searchCtrl = TextEditingController();

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

      final allAppointments = response['data']?['allAppointments'] as Map<String, dynamic>?;
      final List<dynamic> appointments = (allAppointments?['appointments'] as List?) ?? [];

      _all = _aggregate(appointments);
      _applyFilter();
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_StaffSummary> _aggregate(List<dynamic> appointments) {
    final Map<String, Map<String, dynamic>> map = {};

    for (final raw in appointments) {
      if (raw is! Map<String, dynamic>) continue;

      final String staffName = (raw['staffName'] as String?)?.trim().isNotEmpty == true
              ? (raw['staffName'] as String).trim()
              : 'Unassigned';

      final int minutes = (raw['duration'] as num?)?.toInt() ?? 0;
      final double amount = ((raw['totalAmount'] ?? raw['amount']) as num?)?.toDouble() ?? 0.0;

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
      _filtered = _all.where((s) => s.staffName.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange ??
          DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _purple, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateRange = picked;
      _fetchData();
    }
  }

  List<_StaffSummary> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  String _fmtCurrency(num v) => '₹${NumberFormat('#,##0').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34.h,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) { _searchText = v; _applyFilter(); },
                                style: GoogleFonts.poppins(fontSize: 11.sp),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 16.sp),
                                  hintText: 'Search staff...',
                                  hintStyle: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F6FA),
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _toolbarBtn(
                            icon: Icons.filter_list_rounded,
                            label: _dateRange != null ? 'Filtered' : 'Filter',
                            isActive: _dateRange != null,
                            onTap: _pickDateRange,
                          ),
                          SizedBox(width: 8.w),
                          _toolbarBtn(
                            icon: Icons.upload_rounded,
                            label: 'Export',
                            onTap: () {},
                          ),
                          SizedBox(width: 8.w),
                          _toolbarBtn(
                            icon: Icons.refresh_rounded,
                            label: '',
                            onTap: _fetchData,
                            isIconOnly: true,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),
                    Expanded(child: _buildTable()),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 50.h,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Appointments by Staff',
              style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9FB)),
          headingTextStyle: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          dataTextStyle: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black87),
          horizontalMargin: 12.w,
          columnSpacing: 20.w,
          columns: const [
            DataColumn(label: Text('Staff Name')),
            DataColumn(label: Text('Total Appointments')),
            DataColumn(label: Text('Total Duration')),
            DataColumn(label: Text('Total Sale')),
          ],
          rows: _pageItems.map((s) => DataRow(cells: [
            DataCell(Text(s.staffName)),
            DataCell(Text('${s.totalAppointments}')),
            DataCell(Text(s.durationLabel)),
            DataCell(Text(_fmtCurrency(s.totalSale))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded, size: 40.sp, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No records found', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 40.sp, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text('Failed to load data', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.sp)),
          Text(_errorMsg!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchData, style: ElevatedButton.styleFrom(backgroundColor: _purple), child: const Text('Retry', style: TextStyle(color: Colors.white))),
        ]),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final start = _filtered.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Text('Showing $start–$end of ${_filtered.length}',
              style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey.shade500)),
          const Spacer(),
          _pageBtn(Icons.chevron_left_rounded, _currentPage > 0, () => setState(() => _currentPage--)),
          SizedBox(width: 6.w),
          _pageBtn(Icons.chevron_right_rounded, _currentPage < _totalPages - 1, () => setState(() => _currentPage++)),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4), color: enabled ? Colors.white : const Color(0xFFF5F6FA)),
        child: Icon(icon, size: 16.sp, color: enabled ? Colors.black54 : Colors.grey.shade200),
      ),
    );
  }

  Widget _toolbarBtn({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false, bool isIconOnly = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 8 : 10),
        decoration: BoxDecoration(
          color: isActive ? _purple.withOpacity(0.08) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? _purple : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? _purple : Colors.grey.shade600),
            if (!isIconOnly) ...[const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: isActive ? _purple : Colors.grey.shade600, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))],
          ],
        ),
      ),
    );
  }
}
