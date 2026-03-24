import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../my_Profile.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

const Color _primaryDark = Color(0xFF372935);

class AllAppointmentsSummary extends StatefulWidget {
  @override
  State<AllAppointmentsSummary> createState() => _AllAppointmentsSummaryState();
}

class _AllAppointmentsSummaryState extends State<AllAppointmentsSummary> {
  // ── API state ────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> allAppointment = [];
  int _totalFromApi = 0;

  // ── UI state ─────────────────────────────────────────────────────────────────
  String searchText = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  // ── Active filters ───────────────────────────────────────────────────────────
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterBookingType; // 'online' | 'offline'
  String? _filterClient;
  String? _filterService;
  String? _filterStaff;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  // ── Fetch from API ────────────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAllAppointmentsReport(
        startDate: _filterStartDate?.toIso8601String(),
        endDate: _filterEndDate?.toIso8601String(),
        bookingType:
            _filterBookingType != null ? _filterBookingType!.toLowerCase() : null,
        client: _filterClient,
        service: _filterService,
        staff: _filterStaff,
        status: _filterStatus?.toLowerCase(),
      );

      final allData = result['data']['allAppointments'];
      final List<dynamic> raw = allData['appointments'] ?? [];

      setState(() {
        _totalFromApi = (allData['total'] as num?)?.toInt() ?? raw.length;
        allAppointment = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Client-side search (on top of server-filtered data) ───────────────────────
  List<Map<String, dynamic>> get filteredAppointments {
    if (searchText.isEmpty) return allAppointment;
    final q = searchText.toLowerCase();
    return allAppointment.where((a) {
      return (a['clientName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['serviceName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['staffName'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get pagedAppointments {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredAppointments.length);
    return filteredAppointments.sublist(start, end);
  }

  int get totalPages =>
      (filteredAppointments.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ── Totals (over all filtered data, not just the current page) ─────────────
  double get totalBaseAmount =>
      filteredAppointments.fold(0, (s, a) => s + _toDouble(a['amount']));
  double get totalPlatformFee =>
      filteredAppointments.fold(0, (s, a) => s + _toDouble(a['platformFee']));
  double get totalServiceTax =>
      filteredAppointments.fold(0, (s, a) => s + _toDouble(a['serviceTax']));
  double get totalFinal =>
      filteredAppointments.fold(0, (s, a) => s + _toDouble(a['finalAmount']));

  int get onlineCount =>
      filteredAppointments.where((a) => a['mode'] == 'online').length;
  int get offlineCount =>
      filteredAppointments.where((a) => a['mode'] == 'offline').length;

  double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  // ── Filter sheet ──────────────────────────────────────────────────────────────
  Future<void> _openFilters() async {
    final clients =
        allAppointment.map((a) => a['clientName'] as String? ?? '').toSet().toList()
          ..sort();
    final services =
        allAppointment.map((a) => a['serviceName'] as String? ?? '').toSet().toList()
          ..sort();
    final staff =
        allAppointment.map((a) => a['staffName'] as String? ?? '').toSet().toList()
          ..sort();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      builder: (ctx) => _FilterSheet(
        initialStartDate: _filterStartDate,
        initialEndDate: _filterEndDate,
        initialBookingType: _filterBookingType,
        initialClient: _filterClient,
        initialService: _filterService,
        initialStaff: _filterStaff,
        initialStatus: _filterStatus,
        clients: clients,
        services: services,
        staff: staff,
        onApply: (startDate, endDate, bookingType, client, service, staffName,
            status) {
          setState(() {
            _filterStartDate = startDate;
            _filterEndDate = endDate;
            _filterBookingType = bookingType;
            _filterClient = client;
            _filterService = service;
            _filterStaff = staffName;
            _filterStatus = status;
            _currentPage = 0;
          });
          _fetchReport();
        },
      ),
    );
  }

  String _fmt(num amount) => '₹${NumberFormat('#,##0.00').format(amount)}';
  String _fmtInt(num amount) => '₹${NumberFormat('#,##0').format(amount)}';

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text('All Appointments',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B))),
                      SizedBox(height: 2.h),
                      Text(
                        'Complete record of all appointments with detailed information.',
                        style: GoogleFonts.poppins(
                            fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                      ),
                      SizedBox(height: 14.h),

                      // Search + Filters + Export
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              padding:
                                  EdgeInsets.symmetric(horizontal: 10.w),
                              child: Row(
                                children: [
                                  Icon(Icons.search,
                                      size: 14.sp,
                                      color: const Color(0xFF94A3B8)),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (v) => setState(() {
                                        searchText = v;
                                        _currentPage = 0;
                                      }),
                                      decoration: InputDecoration(
                                        hintText: 'Search client, service…',
                                        hintStyle: GoogleFonts.poppins(
                                            fontSize: 10.sp,
                                            color:
                                                const Color(0xFF94A3B8)),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      style:
                                          GoogleFonts.poppins(fontSize: 10.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _topButton(
                              icon: Icons.tune,
                              label: 'Filters',
                              onTap: _openFilters,
                              filled: true),
                          SizedBox(width: 6.w),
                          _refreshButton(),
                          SizedBox(width: 6.w),
                          _exportDropdown(),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Active filter chips
                      if (_hasActiveFilters()) ...[
                        _buildFilterChips(),
                        SizedBox(height: 10.h),
                      ],

                      // Stats row 1
                      Row(
                        children: [
                          _statCard('Total Bookings',
                              filteredAppointments.length.toString()),
                          SizedBox(width: 10.w),
                          _statCard('Online', onlineCount.toString()),
                          SizedBox(width: 10.w),
                          _statCard('Offline', offlineCount.toString()),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      // Stats row 2
                      Row(
                        children: [
                          _statCard('Total Revenue', _fmtInt(totalFinal)),
                          SizedBox(width: 10.w),
                          _statCard('Base Amount', _fmtInt(totalBaseAmount)),
                          SizedBox(width: 10.w),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      Text(
                        '* Multi-service appointments are shown individually per service.',
                        style: GoogleFonts.poppins(
                            fontSize: 9.sp, color: const Color(0xFF94A3B8)),
                      ),
                      SizedBox(height: 10.h),

                      // Table
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTable(),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Pagination
                      _buildPagination(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
    );
  }

  // ── Error widget ──────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48.sp),
            SizedBox(height: 12.h),
            Text('Failed to load appointments',
                style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B))),
            SizedBox(height: 6.h),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11.sp, color: const Color(0xFF64748B))),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Retry', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active filter chips ───────────────────────────────────────────────────────
  bool _hasActiveFilters() =>
      _filterStartDate != null ||
      _filterEndDate != null ||
      _filterBookingType != null ||
      _filterClient != null ||
      _filterService != null ||
      _filterStaff != null ||
      _filterStatus != null;

  Widget _buildFilterChips() {
    final chips = <Widget>[];

    void addChip(String label, VoidCallback onRemove) {
      chips.add(Padding(
        padding: EdgeInsets.only(right: 6.w),
        child: Chip(
          label: Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 9.sp, color: Colors.white)),
          backgroundColor: _primaryDark,
          deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white),
          onDeleted: onRemove,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ));
    }

    if (_filterStartDate != null) {
      addChip(
          'From: ${DateFormat('dd MMM yy').format(_filterStartDate!)}',
          () => setState(() => _filterStartDate = null));
    }
    if (_filterEndDate != null) {
      addChip(
          'To: ${DateFormat('dd MMM yy').format(_filterEndDate!)}',
          () => setState(() => _filterEndDate = null));
    }
    if (_filterBookingType != null) {
      addChip(_filterBookingType!,
          () => setState(() => _filterBookingType = null));
    }
    if (_filterClient != null) {
      addChip(_filterClient!, () => setState(() => _filterClient = null));
    }
    if (_filterService != null) {
      addChip(_filterService!, () => setState(() => _filterService = null));
    }
    if (_filterStaff != null) {
      addChip(_filterStaff!, () => setState(() => _filterStaff = null));
    }
    if (_filterStatus != null) {
      addChip(_filterStatus!, () => setState(() => _filterStatus = null));
    }

    return Wrap(children: chips);
  }

  // ── Table ─────────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    final rows = pagedAppointments;

    if (rows.isEmpty) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Center(
            child: Text('No appointments found.',
                style: GoogleFonts.poppins(
                    fontSize: 12.sp, color: const Color(0xFF94A3B8))),
          ),
        ),
      );
    }

    return DataTable(
      headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
      headingRowHeight: 40.h,
      dataRowMinHeight: 48.h,
      dataRowMaxHeight: 56.h,
      columnSpacing: 18.w,
      horizontalMargin: 14.w,
      dividerThickness: 0,
      border: TableBorder(
        top: const BorderSide(color: Color(0xFFE2E8F0)),
        bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        left: const BorderSide(color: Color(0xFFE2E8F0)),
        right: const BorderSide(color: Color(0xFFE2E8F0)),
        horizontalInside: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      columns: [
        _col('Client'),
        _col('Service'),
        _col('Staff'),
        _col('Scheduled On'),
        _col('Created On'),
        _col('Time'),
        _col('Duration'),
        _col('Mode'),
        _col('Base Amt', numeric: true),
        _col('Platform Fee', numeric: true),
        _col('Service Tax', numeric: true),
        _col('Final Amt', numeric: true),
        _col('Status'),
        _col('Payment'),
      ],
      rows: [
        ...List.generate(rows.length, (index) {
          final a = rows[index];
          final isEven = index % 2 == 0;

          final scheduledDate = a['date'] != null
              ? DateTime.tryParse(a['date'])
              : null;
          final createdAt = a['createdAt'] != null
              ? DateTime.tryParse(a['createdAt'])
              : null;

          return DataRow(
            color: MaterialStateProperty.resolveWith(
              (_) => isEven ? Colors.white : const Color(0xFFFAFAFB),
            ),
            cells: [
              // Client
              DataCell(Text(a['clientName'] ?? '—',
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B)))),
              DataCell(Text(a['serviceName'] ?? '—', style: _cellStyle())),
              DataCell(Text(a['staffName'] ?? '—', style: _cellStyle())),
              // Scheduled date
              DataCell(Text(
                  scheduledDate != null
                      ? DateFormat('dd MMM yy').format(scheduledDate)
                      : '—',
                  style: _cellStyle())),
              // Created at
              DataCell(Text(
                  createdAt != null
                      ? DateFormat('dd MMM yy').format(createdAt)
                      : '—',
                  style: _cellStyle())),
              // Time range
              DataCell(Text(
                '${a['startTime'] ?? '—'}–${a['endTime'] ?? '—'}',
                style: _cellStyle(),
              )),
              // Duration (minutes)
              DataCell(Text(
                  a['duration'] != null ? '${a['duration']}m' : '—',
                  style: _cellStyle())),
              // Mode badge
              DataCell(_modeBadge(a['mode'] ?? '')),
              // Amounts
              DataCell(Text(_fmt(_toDouble(a['amount'])), style: _cellStyle())),
              DataCell(
                  Text(_fmt(_toDouble(a['platformFee'])), style: _cellStyle())),
              DataCell(
                  Text(_fmt(_toDouble(a['serviceTax'])), style: _cellStyle())),
              DataCell(Text(_fmt(_toDouble(a['finalAmount'])),
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: _primaryDark))),
              // Status
              DataCell(_statusBadge(a['status'] ?? '')),
              // Payment status
              DataCell(_paymentBadge(a['paymentStatus'] ?? '')),
            ],
          );
        }),

        // Totals row
        DataRow(
          color: MaterialStateProperty.all(const Color(0xFFFFF9EC)),
          cells: [
            DataCell(Text('Total',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B)))),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            DataCell(Text(_fmt(totalBaseAmount), style: _totalStyle())),
            DataCell(Text(_fmt(totalPlatformFee), style: _totalStyle())),
            DataCell(Text(_fmt(totalServiceTax), style: _totalStyle())),
            DataCell(Text(_fmt(totalFinal),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark))),
            const DataCell(Text('')),
            const DataCell(Text('')),
          ],
        ),
      ],
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    final start =
        filteredAppointments.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage)
        .clamp(0, filteredAppointments.length);
    final total = filteredAppointments.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Showing $start–$end of $total results',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, color: const Color(0xFF64748B)),
              ),
              const Spacer(),
              Text('Per page:',
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp, color: const Color(0xFF64748B))),
              SizedBox(width: 6.w),
              Container(
                height: 28.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4.r),
                  color: const Color(0xFFF8FAFC),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    isDense: true,
                    style: GoogleFonts.poppins(
                        fontSize: 10.sp, color: const Color(0xFF1E293B)),
                    items: [5, 10, 20, 50]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.toString())))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _rowsPerPage = v!;
                      _currentPage = 0;
                    }),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, color: const Color(0xFF1E293B)),
              ),
              SizedBox(width: 10.w),
              _pageBtn(Icons.chevron_left, _currentPage > 0,
                  () => setState(() => _currentPage--)),
              SizedBox(width: 4.w),
              _pageBtn(Icons.chevron_right, _currentPage < totalPages - 1,
                  () => setState(() => _currentPage++)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  DataColumn _col(String label, {bool numeric = false}) => DataColumn(
        numeric: numeric,
        label: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B))),
      );

  TextStyle _cellStyle() =>
      GoogleFonts.poppins(fontSize: 8.sp, color: const Color(0xFF475569));

  TextStyle _totalStyle() => GoogleFonts.poppins(
      fontSize: 8.sp,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1E293B));

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'scheduled':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case 'cancelled':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case 'temp-locked':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(status,
          style: GoogleFonts.poppins(
              fontSize: 8.sp, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _paymentBadge(String status) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'pending':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(status,
          style: GoogleFonts.poppins(
              fontSize: 8.sp, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _modeBadge(String mode) {
    final isOnline = mode.toLowerCase() == 'online';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isOnline ? 'Online' : 'Offline',
        style: GoogleFonts.poppins(
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
            color: isOnline
                ? const Color(0xFF2563EB)
                : const Color(0xFF64748B)),
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: 26.w,
        height: 26.h,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4.r),
          color: Colors.white,
        ),
        child: Icon(icon,
            size: 14.sp,
            color:
                enabled ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9.sp, color: const Color(0xFF64748B))),
            SizedBox(height: 4.h),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: filled ? _primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
              color: filled ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12.sp,
                color: filled ? Colors.white : const Color(0xFF1E293B)),
            SizedBox(width: 5.w),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return InkWell(
      onTap: _fetchReport,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        height: 36.h,
        width: 36.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(Icons.refresh,
            size: 14.sp, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _exportDropdown() {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          icon: Icon(Icons.file_download_outlined,
              color: Colors.white, size: 13.sp),
          hint: Text('Export',
              style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          dropdownColor: Colors.white,
          items: ['CSV', 'PDF', 'Copy', 'Excel', 'Print']
              .map((e) => DropdownMenuItem(
                  value: e.toLowerCase(),
                  child: Text(e, style: GoogleFonts.poppins(fontSize: 10.sp))))
              .toList(),
          onChanged: (v) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Selected: $v'))),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      toolbarHeight: 46.h,
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(width: 4.w),
          Expanded(
            child: Text('Appointment Summary',
                style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialBookingType;
  final String? initialClient;
  final String? initialService;
  final String? initialStaff;
  final String? initialStatus;
  final List<String> clients;
  final List<String> services;
  final List<String> staff;
  final void Function(
    DateTime? startDate,
    DateTime? endDate,
    String? bookingType,
    String? client,
    String? service,
    String? staff,
    String? status,
  ) onApply;

  const _FilterSheet({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialBookingType,
    required this.initialClient,
    required this.initialService,
    required this.initialStaff,
    required this.initialStatus,
    required this.clients,
    required this.services,
    required this.staff,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _bookingType;
  String? _client;
  String? _service;
  String? _staff;
  String? _status;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _bookingType = widget.initialBookingType;
    _client = widget.initialClient;
    _service = widget.initialService;
    _staff = widget.initialStaff;
    _status = widget.initialStatus;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filters',
                        style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B))),
                    SizedBox(height: 2.h),
                    Text('Refine your report data.',
                        style: GoogleFonts.poppins(
                            fontSize: 10.sp, color: const Color(0xFF94A3B8))),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 14.sp, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            SizedBox(height: 14.h),

            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Start Date'),
                            SizedBox(height: 6.h),
                            _dateField(_startDate, () => _pickDate(true)),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('End Date'),
                            SizedBox(height: 6.h),
                            _dateField(_endDate, () => _pickDate(false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  _label('Booking Type'),
                  SizedBox(height: 6.h),
                  _dropdown(
                    value: _bookingType,
                    items: ['Online', 'Offline'],
                    hint: 'All types',
                    onChanged: (v) => setState(() => _bookingType = v),
                  ),
                  SizedBox(height: 14.h),

                  _label('Client'),
                  SizedBox(height: 6.h),
                  _dropdown(
                    value: _client,
                    items: widget.clients,
                    hint: 'All clients',
                    onChanged: (v) => setState(() => _client = v),
                  ),
                  SizedBox(height: 14.h),

                  _label('Service'),
                  SizedBox(height: 6.h),
                  _dropdown(
                    value: _service,
                    items: widget.services,
                    hint: 'All services',
                    onChanged: (v) => setState(() => _service = v),
                  ),
                  SizedBox(height: 14.h),

                  _label('Staff'),
                  SizedBox(height: 6.h),
                  _dropdown(
                    value: _staff,
                    items: widget.staff,
                    hint: 'All staff',
                    onChanged: (v) => setState(() => _staff = v),
                  ),
                  SizedBox(height: 14.h),

                  _label('Status'),
                  SizedBox(height: 6.h),
                  _dropdown(
                    value: _status,
                    items: [
                      'completed',
                      'scheduled',
                      'cancelled',
                      'temp-locked'
                    ],
                    hint: 'All statuses',
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onApply(
                            null, null, null, null, null, null, null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r)),
                      ),
                      child: Text('Clear All',
                          style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B))),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_startDate, _endDate, _bookingType,
                            _client, _service, _staff, _status);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDark,
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r)),
                      ),
                      child: Text('Apply Filters',
                          style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B)));

  Widget _dateField(DateTime? date, VoidCallback onTap) {
    final hasValue = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: hasValue ? _primaryDark : const Color(0xFFE2E8F0),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasValue ? DateFormat('dd MMM yyyy').format(date!) : 'Select',
              style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: hasValue
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8)),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 13.sp, color: const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    // Guard: if current value is not in items, reset to null
    final safeValue = items.contains(value) ? value : null;
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color:
              safeValue != null ? _primaryDark : const Color(0xFFE2E8F0),
          width: safeValue != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: Text(hint,
              style: GoogleFonts.poppins(
                  fontSize: 11.sp, color: const Color(0xFF94A3B8))),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16.sp, color: const Color(0xFF94A3B8)),
          style: GoogleFonts.poppins(
              fontSize: 11.sp, color: const Color(0xFF1E293B)),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All', style: GoogleFonts.poppins(fontSize: 11.sp)),
            ),
            ...items
                .map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
