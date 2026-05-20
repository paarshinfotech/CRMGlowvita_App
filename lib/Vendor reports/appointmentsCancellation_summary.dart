import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/report_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _CancelledAppointment {
  final String id;
  final String clientName;
  final String serviceName;
  final String staffName;
  final String date;
  final String createdAt;
  final String startTime;
  final String endTime;
  final int duration;
  final double amount;
  final double totalAmount;
  final double platformFee;
  final double serviceTax;
  final double finalAmount;
  final String status;
  final String cancelledBy;
  final String cancelledDate;
  final String mode;

  _CancelledAppointment({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
    required this.date,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.amount,
    required this.totalAmount,
    required this.platformFee,
    required this.serviceTax,
    required this.finalAmount,
    required this.status,
    required this.cancelledBy,
    required this.cancelledDate,
    required this.mode,
  });

  factory _CancelledAppointment.fromJson(Map<String, dynamic> j) {
    return _CancelledAppointment(
      id: j['id'] ?? '',
      clientName: j['clientName'] ?? '—',
      serviceName: j['serviceName'] ?? '—',
      staffName: j['staffName'] ?? '—',
      date: j['scheduledDate'] ?? j['date'] ?? '',
      createdAt: j['createdAt'] ?? '',
      startTime: j['startTime'] ?? '—',
      endTime: j['endTime'] ?? '—',
      duration: (j['duration'] as num?)?.toInt() ?? 0,
      amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0.0,
      serviceTax: (j['serviceTax'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (j['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: j['status'] ?? 'cancelled',
      cancelledBy: j['cancelledBy'] ?? '—',
      cancelledDate: j['cancelledDate'] ?? '',
      mode: j['mode'] ?? 'offline',
    );
  }

  String _fmtDate(String d) {
    if (d.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String get formattedDate => _fmtDate(date);
  String get formattedCreatedAt => _fmtDate(createdAt);
  String get formattedCancelledDate => _fmtDate(cancelledDate);
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AppointmentsCancellationSummary extends StatefulWidget {
  const AppointmentsCancellationSummary({super.key});

  @override
  State<AppointmentsCancellationSummary> createState() =>
      _AppointmentsCancellationSummaryState();
}

class _AppointmentsCancellationSummaryState
    extends State<AppointmentsCancellationSummary> {
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<_CancelledAppointment> _all = [];
  List<_CancelledAppointment> _filtered = [];

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
      final response = await ApiService.getCancelledAppointmentsReport(
        startDate: _dateRange != null ? DateFormat('yyyy-MM-dd').format(_dateRange!.start) : null,
        endDate: _dateRange != null ? DateFormat('yyyy-MM-dd').format(_dateRange!.end) : null,
      );

      final block = response['data']?['cancellations'];
      final List<dynamic> raw = (block?['cancellations'] as List?) ?? [];

      _all = raw.map((j) => _CancelledAppointment.fromJson(j)).toList();
      _applyFilter();
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _searchText.toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = _all.where((a) {
        return a.clientName.toLowerCase().contains(q) ||
               a.serviceName.toLowerCase().contains(q) ||
               a.staffName.toLowerCase().contains(q);
      }).toList();
    });
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  double get _totalRevenueLoss => _filtered.fold(0, (sum, a) => sum + a.finalAmount);
  int get _onlineCount => _filtered.where((a) => a.mode.toLowerCase() == 'online').length;
  int get _offlineCount => _filtered.where((a) => a.mode.toLowerCase() == 'offline').length;

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

  List<_CancelledAppointment> get _pageItems {
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
      appBar: ReportAppBar(
        title: 'Cancelled Appointments',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and plum buttons row matching Figma exactly
            ReportSearchBarAndButtons(
              controller: _searchCtrl,
              hintText: 'Search cancelled...',
              onChanged: (v) {
                _searchText = v;
                _applyFilter();
              },
              onFilterTap: _pickDateRange,
              exportMenu: const ReportPlumButton(
                label: 'Export',
                suffixIcon: Icons.download_rounded,
              ),
            ),
            SizedBox(height: 20.h),

            // Stats grid in 2 columns
            ReportStatsGrid(
              children: [
                ReportStatCard(
                  label: 'Total Cancelled',
                  value: '${_filtered.length}',
                  icon: Icons.cancel_outlined,
                  iconColor: const Color(0xFFC62828),
                  circleBgColor: const Color(0xFFFFEBEE),
                ),
                ReportStatCard(
                  label: 'Revenue Loss',
                  value: _fmtCurrency(_totalRevenueLoss),
                  icon: Icons.trending_down_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  circleBgColor: const Color(0xFFFEF3C7),
                ),
                ReportStatCard(
                  label: 'Online Bookings',
                  value: _onlineCount.toString().padLeft(2, '0'),
                  icon: Icons.desktop_mac_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  circleBgColor: const Color(0xFFEFF6FF),
                ),
                ReportStatCard(
                  label: 'Offline Bookings',
                  value: _offlineCount.toString().padLeft(2, '0'),
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFF64748B),
                  circleBgColor: const Color(0xFFF1F5F9),
                ),
              ],
            ),
            SizedBox(height: 24.h),



            // Premium table container without borders
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Theme(
                data: getReportTableTheme(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTable(),
                    Divider(height: 1, color: Colors.grey.shade50),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      child: ReportPagination(
                        currentPage: _currentPage,
                        totalPages: _totalPages,
                        rowsPerPage: _rowsPerPage,
                        totalItems: _filtered.length,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        onRowsPerPageChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _rowsPerPage = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
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
            child: Text('Cancelled Appointments',
                style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
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
          headingRowColor: MaterialStateProperty.all(Colors.white),
          headingTextStyle: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w500, color: const Color(0xFF71717A)),
          dataTextStyle: GoogleFonts.poppins(fontSize: 9.sp, color: Colors.black87),
          dividerThickness: 0,
          horizontalMargin: 8.w,
          columnSpacing: 16.w,
          columns: const [
            DataColumn(label: Text('Client')),
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Staff')),
            DataColumn(label: Text('Scheduled')),
            DataColumn(label: Text('Cancelled By')),
            DataColumn(label: Text('Cancelled On')),
            DataColumn(label: Text('Loss')),
          ],
          rows: _pageItems.map((a) => DataRow(cells: [
            DataCell(Text(a.clientName)),
            DataCell(Text(a.serviceName)),
            DataCell(Text(a.staffName)),
            DataCell(Text(a.formattedDate)),
            DataCell(Text(a.cancelledBy)),
            DataCell(Text(a.formattedCancelledDate)),
            DataCell(Text(_fmtCurrency(a.finalAmount), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_busy_rounded, size: 40.sp, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No cancelled records found', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 14, color: color)),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  Text(label, style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
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
