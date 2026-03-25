import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _Appointment {
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
  final String paymentStatus;
  final String mode;
  final bool isMultiService;

  _Appointment({
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
    required this.paymentStatus,
    required this.mode,
    required this.isMultiService,
  });

  factory _Appointment.fromJson(Map<String, dynamic> j) {
    return _Appointment(
      id: j['id'] ?? '',
      clientName: j['clientName'] ?? '—',
      serviceName: j['serviceName'] ?? '—',
      staffName: j['staffName'] ?? '—',
      date: j['date'] ?? '',
      createdAt: j['createdAt'] ?? '',
      startTime: j['startTime'] ?? '—',
      endTime: j['endTime'] ?? '—',
      duration: (j['duration'] as num?)?.toInt() ?? 0,
      amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0.0,
      serviceTax: (j['serviceTax'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (j['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: j['status'] ?? 'pending',
      paymentStatus: j['paymentStatus'] ?? 'pending',
      mode: j['mode'] ?? 'offline',
      isMultiService: j['isMultiService'] ?? false,
    );
  }

  String get timeLabel => '$startTime – $endTime';
  
  String get formattedDate {
    if (date.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String get formattedCreatedAt {
    if (createdAt.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt));
    } catch (_) {
      return createdAt;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AllAppointmentsSummary extends StatefulWidget {
  const AllAppointmentsSummary({super.key});

  @override
  State<AllAppointmentsSummary> createState() => _AllAppointmentsSummaryState();
}

class _AllAppointmentsSummaryState extends State<AllAppointmentsSummary> {
  // ── constants ───────────────────────────────────────────────────────────────
  static const Color _purple = Color(0xFF6C3EB8);

  // ── state ───────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMsg;

  List<_Appointment> _all = [];
  List<_Appointment> _filtered = [];

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

      final allData = response['data']?['allAppointments'];
      final List<dynamic> rawList = (allData?['appointments'] as List?) ?? [];

      _all = rawList.map((j) => _Appointment.fromJson(j)).toList();
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
  double get _totalRevenue => _filtered.fold(0, (sum, a) => sum + a.finalAmount);
  double get _totalBusiness => _filtered.fold(0, (sum, a) => sum + a.totalAmount);
  int get _onlineCount => _filtered.where((a) => a.mode.toLowerCase() == 'online').length;
  int get _offlineCount => _filtered.where((a) => a.mode.toLowerCase() == 'offline').length;

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmtCompact(num v) => '₹${NumberFormat('#,##0').format(v)}';

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
  List<_Appointment> get _pageItems {
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
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            // Stats Row
            Row(
              children: [
                _statCard('Total Bookings', '${_filtered.length}', Icons.event_available_rounded, Colors.blue),
                SizedBox(width: 8.w),
                _statCard('Total Revenue', _fmtCompact(_totalRevenue), Icons.payments_rounded, Colors.green),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _statCard('Total Business', _fmtCompact(_totalBusiness), Icons.business_center_rounded, Colors.indigo),
                SizedBox(width: 8.w),
                _statCard('Online', '$_onlineCount', Icons.language_rounded, _purple),
                SizedBox(width: 8.w),
                _statCard('Offline', '$_offlineCount', Icons.storefront_rounded, Colors.orange),
              ],
            ),
            SizedBox(height: 12.h),

            // Report Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toolbar
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
                                  hintText: 'Search...',
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
                            icon: Icons.file_download_outlined,
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

                    // Table
                    Expanded(child: _buildTable()),

                    // Footer
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
            child: Text('All Appointments',
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
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9FB)),
          headingTextStyle: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          dataTextStyle: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black87),
          horizontalMargin: 12.w,
          columnSpacing: 20.w,
          columns: const [
            DataColumn(label: Text('Client')),
            DataColumn(label: Text('Services')),
            DataColumn(label: Text('Staff')),
            DataColumn(label: Text('Scheduled On')),
            DataColumn(label: Text('Created On')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Base Amt')),
            DataColumn(label: Text('Platform Fee')),
            DataColumn(label: Text('Service Tax')),
            DataColumn(label: Text('Final Amt')),
            DataColumn(label: Text('Status')),
          ],
          rows: _pageItems.map((a) => DataRow(cells: [
            DataCell(Text(a.clientName)),
            DataCell(Text(a.serviceName)),
            DataCell(Text(a.staffName)),
            DataCell(Text(a.formattedDate)),
            DataCell(Text(a.formattedCreatedAt)),
            DataCell(Text(a.startTime)),
            DataCell(Text('${a.duration} min')),
            DataCell(Text('₹${a.amount.toStringAsFixed(0)}')),
            DataCell(Text('₹${a.platformFee.toStringAsFixed(0)}')),
            DataCell(Text('₹${a.serviceTax.toStringAsFixed(0)}')),
            DataCell(Text('₹${a.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_statusBadge(a.status)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    status = status.toLowerCase();
    Color bg, fg;
    if (status == 'completed') { bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32); }
    else if (status == 'scheduled') { bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0); }
    else if (status == 'cancelled') { bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828); }
    else { bg = const Color(0xFFF5F5F5); fg = const Color(0xFF757575); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 8.sp, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_rounded, size: 40.sp, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No appointments found', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
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

