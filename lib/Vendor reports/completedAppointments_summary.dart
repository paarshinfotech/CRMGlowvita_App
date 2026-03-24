import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

const Color _primary = Color(0xFF372935);

class CompletedAppointmentsSummary extends StatefulWidget {
  @override
  State<CompletedAppointmentsSummary> createState() =>
      _CompletedAppointmentsSummaryState();
}

class _CompletedAppointmentsSummaryState
    extends State<CompletedAppointmentsSummary> {
  // ── API state ────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _appointments = [];
  int _totalDuration = 0;

  // ── Pagination ───────────────────────────────────────────────────────────────
  int _rowsPerPage = 10;
  int _currentPage = 0;

  // ── Filters ──────────────────────────────────────────────────────────────────
  String _searchText = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterBookingType;
  String? _filterClient;
  String? _filterService;
  String? _filterStaff;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getCompletedAppointmentsReport(
        startDate: _filterStartDate?.toIso8601String(),
        endDate: _filterEndDate?.toIso8601String(),
        bookingType: _filterBookingType?.toLowerCase(),
        client: _filterClient,
        service: _filterService,
        staff: _filterStaff,
      );

      final block = result['data']['complete'] as Map<String, dynamic>;
      final raw =
          (block['appointments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        _appointments = raw;
        _totalDuration = (block['totalDuration'] as num?)?.toInt() ?? 0;
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

  // ── Client-side search ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    if (_searchText.isEmpty) return _appointments;
    final q = _searchText.toLowerCase();
    return _appointments.where((a) {
      return (a['clientName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['serviceName'] ?? '').toString().toLowerCase().contains(q) ||
          (a['staffName'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _paged {
    final all = _filtered;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ── Computed stats ────────────────────────────────────────────────────────────
  int get _onlineCount => _filtered.where((a) => a['mode'] == 'online').length;
  int get _offlineCount =>
      _filtered.where((a) => a['mode'] == 'offline').length;
  double get _filteredRevenue =>
      _filtered.fold(0, (s, a) => s + _n(a['finalAmount']));
  double get _filteredBase => _filtered.fold(0, (s, a) => s + _n(a['amount']));
  double get _filteredPlatformFee =>
      _filtered.fold(0, (s, a) => s + _n(a['platformFee']));
  double get _filteredServiceTax =>
      _filtered.fold(0, (s, a) => s + _n(a['serviceTax']));

  double _n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  String _fmt(num v) => '₹${NumberFormat('#,##0.00').format(v)}';
  String _fmtInt(num v) => '₹${NumberFormat('#,##0').format(v)}';

  // ── Filter sheet ──────────────────────────────────────────────────────────────
  Future<void> _openFilters() async {
    final clients = _appointments
        .map((a) => a['clientName'] as String? ?? '')
        .toSet()
        .toList()
      ..sort();
    final services = _appointments
        .map((a) => a['serviceName'] as String? ?? '')
        .toSet()
        .toList()
      ..sort();
    final staff = _appointments
        .map((a) => a['staffName'] as String? ?? '')
        .toSet()
        .toList()
      ..sort();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14.r))),
      builder: (_) => _FilterSheet(
        initialStartDate: _filterStartDate,
        initialEndDate: _filterEndDate,
        initialBookingType: _filterBookingType,
        initialClient: _filterClient,
        initialService: _filterService,
        initialStaff: _filterStaff,
        clients: clients,
        services: services,
        staff: staff,
        onApply: (sd, ed, bt, cl, sv, st) {
          setState(() {
            _filterStartDate = sd;
            _filterEndDate = ed;
            _filterBookingType = bt;
            _filterClient = cl;
            _filterService = sv;
            _filterStaff = st;
            _currentPage = 0;
          });
          _fetchReport();
        },
      ),
    );
  }

  bool get _hasFilters =>
      _filterStartDate != null ||
      _filterEndDate != null ||
      _filterBookingType != null ||
      _filterClient != null ||
      _filterService != null ||
      _filterStaff != null;

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
                      Text('Completed Appointments',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B))),
                      SizedBox(height: 2.h),
                      Text(
                        'Detailed record of all completed appointments.',
                        style: GoogleFonts.poppins(
                            fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                      ),
                      SizedBox(height: 14.h),

                      // Search + Filters + Refresh + Export
                      Row(
                        children: [
                          Expanded(child: _searchBar()),
                          SizedBox(width: 8.w),
                          _topBtn(
                              icon: Icons.tune,
                              label: 'Filters',
                              onTap: _openFilters,
                              filled: true),
                          SizedBox(width: 6.w),
                          _refreshBtn(),
                          SizedBox(width: 6.w),
                          _exportDropdown(),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Active filter chips
                      if (_hasFilters) ...[
                        _filterChips(),
                        SizedBox(height: 10.h),
                      ],

                      // Stats row 1
                      Row(
                        children: [
                          _statCard(
                              'Total Completed', _filtered.length.toString()),
                          SizedBox(width: 10.w),
                          _statCard('Online', _onlineCount.toString()),
                          SizedBox(width: 10.w),
                          _statCard('Offline', _offlineCount.toString()),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      // Stats row 2
                      Row(
                        children: [
                          _statCard('Total Revenue', _fmtInt(_filteredRevenue)),
                          SizedBox(width: 10.w),
                          _statCard('Total Duration', '${_totalDuration} min'),
                          SizedBox(width: 10.w),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      SizedBox(height: 14.h),

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

  // ── Error ─────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48.sp),
            SizedBox(height: 12.h),
            Text('Failed to load report',
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
                backgroundColor: _primary,
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

  // ── Filter chips ──────────────────────────────────────────────────────────────
  Widget _filterChips() {
    final chips = <Widget>[];
    void add(String label, VoidCallback onRemove) {
      chips.add(Padding(
        padding: EdgeInsets.only(right: 6.w),
        child: Chip(
          label: Text(label,
              style: GoogleFonts.poppins(fontSize: 9.sp, color: Colors.white)),
          backgroundColor: _primary,
          deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white),
          onDeleted: onRemove,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ));
    }

    if (_filterStartDate != null)
      add('From: ${DateFormat('dd MMM yy').format(_filterStartDate!)}',
          () => setState(() => _filterStartDate = null));
    if (_filterEndDate != null)
      add('To: ${DateFormat('dd MMM yy').format(_filterEndDate!)}',
          () => setState(() => _filterEndDate = null));
    if (_filterBookingType != null)
      add(_filterBookingType!, () => setState(() => _filterBookingType = null));
    if (_filterClient != null)
      add(_filterClient!, () => setState(() => _filterClient = null));
    if (_filterService != null)
      add(_filterService!, () => setState(() => _filterService = null));
    if (_filterStaff != null)
      add(_filterStaff!, () => setState(() => _filterStaff = null));

    return Wrap(children: chips);
  }

  // ── Table ─────────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    final rows = _paged;

    if (rows.isEmpty) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Center(
            child: Text('No completed appointments found.',
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
        _col('Payment'),
      ],
      rows: [
        ...List.generate(rows.length, (i) {
          final a = rows[i];
          final isEven = i % 2 == 0;
          final scheduledDate =
              a['date'] != null ? DateTime.tryParse(a['date']) : null;
          final createdAt =
              a['createdAt'] != null ? DateTime.tryParse(a['createdAt']) : null;

          return DataRow(
            color: MaterialStateProperty.resolveWith(
                (_) => isEven ? Colors.white : const Color(0xFFFAFAFB)),
            cells: [
              DataCell(Text(a['clientName'] ?? '—',
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B)))),
              DataCell(Text(a['serviceName'] ?? '—', style: _cellStyle())),
              DataCell(Text(a['staffName'] ?? '—', style: _cellStyle())),
              DataCell(Text(
                  scheduledDate != null
                      ? DateFormat('dd MMM yy').format(scheduledDate)
                      : '—',
                  style: _cellStyle())),
              DataCell(Text(
                  createdAt != null
                      ? DateFormat('dd MMM yy').format(createdAt)
                      : '—',
                  style: _cellStyle())),
              DataCell(Text('${a['startTime'] ?? '—'}–${a['endTime'] ?? '—'}',
                  style: _cellStyle())),
              DataCell(Text(a['duration'] != null ? '${a['duration']}m' : '—',
                  style: _cellStyle())),
              DataCell(_modeBadge(a['mode'] ?? '')),
              DataCell(Text(_fmt(_n(a['amount'])), style: _cellStyle())),
              DataCell(Text(_fmt(_n(a['platformFee'])), style: _cellStyle())),
              DataCell(Text(_fmt(_n(a['serviceTax'])), style: _cellStyle())),
              DataCell(Text(_fmt(_n(a['finalAmount'])),
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: _primary))),
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
            DataCell(Text(_fmt(_filteredBase), style: _totalStyle())),
            DataCell(Text(_fmt(_filteredPlatformFee), style: _totalStyle())),
            DataCell(Text(_fmt(_filteredServiceTax), style: _totalStyle())),
            DataCell(Text(_fmt(_filteredRevenue),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _primary))),
            const DataCell(Text('')),
          ],
        ),
      ],
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    final start = _filtered.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);
    final total = _filtered.length;

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
              Text('Showing $start–$end of $total results',
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp, color: const Color(0xFF64748B))),
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
              Text('Page ${_currentPage + 1} of $_totalPages',
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp, color: const Color(0xFF1E293B))),
              SizedBox(width: 10.w),
              _pageBtn(Icons.chevron_left, _currentPage > 0,
                  () => setState(() => _currentPage--)),
              SizedBox(width: 4.w),
              _pageBtn(Icons.chevron_right, _currentPage < _totalPages - 1,
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

  Widget _modeBadge(String mode) {
    final isOnline = mode.toLowerCase() == 'online';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isOnline ? 'Online' : 'Offline',
        style: GoogleFonts.poppins(
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
            color:
                isOnline ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(status,
          style: GoogleFonts.poppins(
              fontSize: 8.sp, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
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

  Widget _statCard(String label, String value) => Expanded(
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

  Widget _searchBar() => Container(
        height: 36.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          children: [
            Icon(Icons.search, size: 14.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 6.w),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() {
                  _searchText = v;
                  _currentPage = 0;
                }),
                decoration: InputDecoration(
                  hintText: 'Search client, service…',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: GoogleFonts.poppins(fontSize: 10.sp),
              ),
            ),
          ],
        ),
      );

  Widget _topBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: filled ? _primary : Colors.white,
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

  Widget _refreshBtn() => InkWell(
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
          child:
              Icon(Icons.refresh, size: 14.sp, color: const Color(0xFF1E293B)),
        ),
      );

  Widget _exportDropdown() => Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: _primary,
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
                    child:
                        Text(e, style: GoogleFonts.poppins(fontSize: 10.sp))))
                .toList(),
            onChanged: (v) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Selected: $v'))),
          ),
        ),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
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
              child: Text('Completed Appointments Report',
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

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialBookingType;
  final String? initialClient;
  final String? initialService;
  final String? initialStaff;
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
  ) onApply;

  const _FilterSheet({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialBookingType,
    required this.initialClient,
    required this.initialService,
    required this.initialStaff,
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

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _bookingType = widget.initialBookingType;
    _client = widget.initialClient;
    _service = widget.initialService;
    _staff = widget.initialStaff;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters',
                    style: GoogleFonts.poppins(
                        fontSize: 14.sp, fontWeight: FontWeight.w700)),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9), shape: BoxShape.circle),
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
                controller: ctrl,
                padding: EdgeInsets.zero,
                children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('Start Date'),
                          SizedBox(height: 6.h),
                          _dateField(_startDate, () => _pickDate(true)),
                        ])),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _lbl('End Date'),
                          SizedBox(height: 6.h),
                          _dateField(_endDate, () => _pickDate(false)),
                        ])),
                  ]),
                  SizedBox(height: 14.h),
                  _lbl('Booking Type'),
                  SizedBox(height: 6.h),
                  _drop(_bookingType, ['Online', 'Offline'], 'All types',
                      (v) => setState(() => _bookingType = v)),
                  SizedBox(height: 14.h),
                  _lbl('Client'),
                  SizedBox(height: 6.h),
                  _drop(_client, widget.clients, 'All clients',
                      (v) => setState(() => _client = v)),
                  SizedBox(height: 14.h),
                  _lbl('Service'),
                  SizedBox(height: 6.h),
                  _drop(_service, widget.services, 'All services',
                      (v) => setState(() => _service = v)),
                  SizedBox(height: 14.h),
                  _lbl('Staff'),
                  SizedBox(height: 6.h),
                  _drop(_staff, widget.staff, 'All staff',
                      (v) => setState(() => _staff = v)),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onApply(null, null, null, null, null, null);
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
                            _client, _service, _staff);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
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

  Widget _lbl(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B)));

  Widget _dateField(DateTime? date, VoidCallback onTap) {
    final has = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
              color: has ? _primary : const Color(0xFFE2E8F0),
              width: has ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(has ? DateFormat('dd MMM yyyy').format(date!) : 'Select',
                style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: has
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8))),
            Icon(Icons.calendar_today_outlined,
                size: 13.sp, color: const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _drop(String? value, List<String> items, String hint,
      void Function(String?) onChange) {
    final safe = items.contains(value) ? value : null;
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
            color: safe != null ? _primary : const Color(0xFFE2E8F0),
            width: safe != null ? 1.5 : 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safe,
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
                child:
                    Text('All', style: GoogleFonts.poppins(fontSize: 11.sp))),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: onChange,
        ),
      ),
    );
  }
}
