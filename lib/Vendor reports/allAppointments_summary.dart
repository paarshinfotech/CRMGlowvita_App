import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _primaryDark = Color(0xFF372935);

class AllAppointmentsSummary extends StatefulWidget {
  @override
  State<AllAppointmentsSummary> createState() => _AllAppointmentsSummaryState();
}

class _AllAppointmentsSummaryState extends State<AllAppointmentsSummary> {
  DateTimeRange? _selectedDateRange;
  String searchText = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  String? _filterBookingType;
  String? _filterClient;
  String? _filterService;
  String? _filterStaff;
  String? _filterStatus;

  final List<Map<String, dynamic>> allAppointment = [
    {
      'ref': '#00001265',
      'client': 'Siddhi Shinde',
      'services': 'Haircut, Styling',
      'staffName': 'Priya Sharma',
      'createdOn': DateTime(2025, 7, 26, 12, 52),
      'scheduledOn': DateTime(2025, 7, 27, 14, 00),
      'scheduledEnd': DateTime(2025, 7, 27, 15, 30),
      'duration': '1h 30m',
      'baseAmount': 400.0,
      'platformFee': 5.0,
      'serviceTax': 5.0,
      'price': 410.0,
      'bookingType': 'Online',
      'status': 'PENDING',
    },
    {
      'ref': '#00001264',
      'client': 'Anita Desai',
      'services': 'Manicure',
      'staffName': 'Riya Patel',
      'createdOn': DateTime(2025, 7, 26, 12, 48),
      'scheduledOn': DateTime(2025, 7, 27, 10, 30),
      'scheduledEnd': DateTime(2025, 7, 27, 11, 15),
      'duration': '45m',
      'baseAmount': 300.0,
      'platformFee': 5.0,
      'serviceTax': 5.0,
      'price': 310.0,
      'bookingType': 'Offline',
      'status': 'PENDING',
    },
    {
      'ref': '#00001263',
      'client': 'Neha Gupta',
      'services': 'Massage',
      'staffName': 'Sonia Verma',
      'createdOn': DateTime(2025, 7, 26, 12, 48),
      'scheduledOn': DateTime(2025, 7, 26, 15, 00),
      'scheduledEnd': DateTime(2025, 7, 26, 16, 00),
      'duration': '1h',
      'baseAmount': 300.0,
      'platformFee': 5.0,
      'serviceTax': 5.0,
      'price': 310.0,
      'bookingType': 'Online',
      'status': 'PAID',
    },
    {
      'ref': '#00001262',
      'client': 'Pooja Mehta',
      'services': 'Facial',
      'staffName': 'Kavita Singh',
      'createdOn': DateTime(2025, 7, 26, 12, 25),
      'scheduledOn': DateTime(2025, 7, 26, 11, 00),
      'scheduledEnd': DateTime(2025, 7, 26, 12, 00),
      'duration': '1h',
      'baseAmount': 300.0,
      'platformFee': 5.0,
      'serviceTax': 5.0,
      'price': 310.0,
      'bookingType': 'Offline',
      'status': 'CANCELLED',
    },
  ];

  List<Map<String, dynamic>> get filteredAppointments {
    return allAppointment.where((a) {
      final matchesSearch = a['client']
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());
      final matchesDate = _selectedDateRange == null ||
          (a['scheduledOn'].isAfter(_selectedDateRange!.start
                  .subtract(const Duration(days: 1))) &&
              a['scheduledOn'].isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1))));
      final matchesBooking =
          _filterBookingType == null || a['bookingType'] == _filterBookingType;
      final matchesClient =
          _filterClient == null || a['client'] == _filterClient;
      final matchesService =
          _filterService == null || a['services'] == _filterService;
      final matchesStaff =
          _filterStaff == null || a['staffName'] == _filterStaff;
      final matchesStatus =
          _filterStatus == null || a['status'] == _filterStatus;
      return matchesSearch &&
          matchesDate &&
          matchesBooking &&
          matchesClient &&
          matchesService &&
          matchesStaff &&
          matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> get pagedAppointments {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredAppointments.length);
    return filteredAppointments.sublist(start, end);
  }

  int get totalPages =>
      (filteredAppointments.length / _rowsPerPage).ceil().clamp(1, 9999);

  double get totalBaseAmount =>
      filteredAppointments.fold(0, (s, a) => s + (a['baseAmount'] as double));
  double get totalPlatformFee =>
      filteredAppointments.fold(0, (s, a) => s + (a['platformFee'] as double));
  double get totalServiceTax =>
      filteredAppointments.fold(0, (s, a) => s + (a['serviceTax'] as double));
  double get totalFinal =>
      filteredAppointments.fold(0, (s, a) => s + (a['price'] as double));

  int get onlineCount =>
      filteredAppointments.where((a) => a['bookingType'] == 'Online').length;
  int get offlineCount =>
      filteredAppointments.where((a) => a['bookingType'] == 'Offline').length;

  Future<void> _openFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      builder: (ctx) => _FilterSheet(
        initialDateRange: _selectedDateRange,
        initialBookingType: _filterBookingType,
        initialClient: _filterClient,
        initialService: _filterService,
        initialStaff: _filterStaff,
        initialStatus: _filterStatus,
        clients:
            allAppointment.map((a) => a['client'] as String).toSet().toList()
              ..sort(),
        services:
            allAppointment.map((a) => a['services'] as String).toSet().toList()
              ..sort(),
        staff:
            allAppointment.map((a) => a['staffName'] as String).toSet().toList()
              ..sort(),
        onApply: (range, bookingType, client, service, staffName, status) {
          setState(() {
            _selectedDateRange = range;
            _filterBookingType = bookingType;
            _filterClient = client;
            _filterService = service;
            _filterStaff = staffName;
            _filterStatus = status;
            _currentPage = 0;
          });
        },
      ),
    );
  }

  String _fmt(num amount) => '₹${NumberFormat('#,##0.00').format(amount)}';
  String _fmtInt(num amount) => '₹${NumberFormat('#,##0').format(amount)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      // ── Full page vertical scroll ─────────────────────────────────────────
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + subtitle
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
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            size: 14.sp, color: const Color(0xFF94A3B8)),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() {
                              searchText = v;
                              _currentPage = 0;
                            }),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: GoogleFonts.poppins(fontSize: 10.sp),
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
                _exportDropdown(),
              ],
            ),
            SizedBox(height: 14.h),

            // Stats row 1 — 3 cards
            Row(
              children: [
                _statCard(
                    'Total Bookings', filteredAppointments.length.toString()),
                SizedBox(width: 10.w),
                _statCard('Online Bookings', onlineCount.toString()),
                SizedBox(width: 10.w),
                _statCard('Offline Bookings', offlineCount.toString()),
              ],
            ),
            SizedBox(height: 10.h),
            // Stats row 2 — 2 cards + spacer
            Row(
              children: [
                _statCard('Total Revenue', _fmtInt(totalFinal)),
                SizedBox(width: 10.w),
                _statCard('Total Business', _fmtInt(totalBaseAmount)),
                SizedBox(width: 10.w),
                const Expanded(child: SizedBox()),
              ],
            ),
            SizedBox(height: 10.h),

            Text(
              '* Multi-service appointments are shown individually for each service.',
              style: GoogleFonts.poppins(
                  fontSize: 9.sp, color: const Color(0xFF94A3B8)),
            ),
            SizedBox(height: 10.h),

            // ── Table: only horizontal scroll ──────────────────────────────
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

            // ── Pagination ──────────────────────────────────────────────────
            _buildPagination(),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────
  Widget _buildTable() {
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
        _col('Base Amount', numeric: true),
        _col('Platform Fee', numeric: true),
        _col('Service Tax', numeric: true),
        _col('Final Amount', numeric: true),
        _col('Status'),
      ],
      rows: [
        ...List.generate(pagedAppointments.length, (index) {
          final a = pagedAppointments[index];
          final isEven = index % 2 == 0;
          return DataRow(
            color: MaterialStateProperty.resolveWith(
              (_) => isEven ? Colors.white : const Color(0xFFFAFAFB),
            ),
            cells: [
              // Client with avatar
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a['client'],
                      style: GoogleFonts.poppins(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B))),
                ],
              )),
              DataCell(Text(a['services'], style: _cellStyle())),
              DataCell(Text(a['staffName'], style: _cellStyle())),
              DataCell(Text(DateFormat('dd MMM yy').format(a['scheduledOn']),
                  style: _cellStyle())),
              DataCell(Text(DateFormat('dd MMM yy').format(a['createdOn']),
                  style: _cellStyle())),
              DataCell(Text(
                '${DateFormat('HH:mm').format(a['scheduledOn'])}-'
                '${DateFormat('HH:mm').format(a['scheduledEnd'])}',
                style: _cellStyle(),
              )),
              DataCell(Text(a['duration'], style: _cellStyle())),
              DataCell(Text(_fmt(a['baseAmount']), style: _cellStyle())),
              DataCell(Text(_fmt(a['platformFee']), style: _cellStyle())),
              DataCell(Text(_fmt(a['serviceTax']), style: _cellStyle())),
              DataCell(Text(_fmt(a['price']),
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: _primaryDark))),
              DataCell(_statusBadge(a['status'])),
            ],
          );
        }),

        // Total row
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
            DataCell(Text(_fmt(totalBaseAmount), style: _totalStyle())),
            DataCell(Text(_fmt(totalPlatformFee), style: _totalStyle())),
            DataCell(Text(_fmt(totalServiceTax), style: _totalStyle())),
            DataCell(Text(_fmt(totalFinal),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark))),
            const DataCell(Text('')),
          ],
        ),
      ],
    );
  }

  // ── Pagination (2 rows to avoid overflow) ─────────────────────────────────
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
          // Row 1: result count + rows per page
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
          // Row 2: page info + nav buttons
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

  // ── Helpers ────────────────────────────────────────────────────────────────
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

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      _primaryDark,
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'pending':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        break;
      case 'cancelled':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
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
              fontSize: 9.sp, fontWeight: FontWeight.w600, color: fg)),
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
            color: enabled ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
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
  final DateTimeRange? initialDateRange;
  final String? initialBookingType;
  final String? initialClient;
  final String? initialService;
  final String? initialStaff;
  final String? initialStatus;
  final List<String> clients;
  final List<String> services;
  final List<String> staff;
  final void Function(
    DateTimeRange? range,
    String? bookingType,
    String? client,
    String? service,
    String? staff,
    String? status,
  ) onApply;

  const _FilterSheet({
    required this.initialDateRange,
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
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
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

            // Scrollable fields
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  // Dates side by side
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
                    items: ['PENDING', 'PAID', 'CANCELLED'],
                    hint: 'All statuses',
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),

            // Action buttons — always visible at bottom
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _bookingType = null;
                          _client = null;
                          _service = null;
                          _staff = null;
                          _status = null;
                        });
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
                        final range = (_startDate != null && _endDate != null)
                            ? DateTimeRange(start: _startDate!, end: _endDate!)
                            : null;
                        widget.onApply(range, _bookingType, _client, _service,
                            _staff, _status);
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
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: value != null ? _primaryDark : const Color(0xFFE2E8F0),
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
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
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
