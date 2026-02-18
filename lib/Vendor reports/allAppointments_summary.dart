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
      return matchesSearch && matchesDate;
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  String _fmt(num amount) => '₹${NumberFormat('#,##0.00').format(amount)}';
  String _fmtInt(num amount) => '₹${NumberFormat('#,##0').format(amount)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + subtitle
            Text(
              'All Appointments',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
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
                            onChanged: (v) => setState(() => searchText = v),
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
                  onTap: _selectDateRange,
                  filled: true,
                ),
                SizedBox(width: 6.w),
                _exportDropdown(),
              ],
            ),
            SizedBox(height: 14.h),

            // Stat cards
            Row(
              children: [
                _statCard(
                    'Total Bookings', filteredAppointments.length.toString()),
                SizedBox(width: 10.w),
                _statCard('Online Bookings', onlineCount.toString()),
                SizedBox(width: 10.w),
                _statCard('Offline Bookings', offlineCount.toString()),
                SizedBox(width: 10.w),
                _statCard('Total Revenue', _fmtInt(totalFinal)),
                SizedBox(width: 10.w),
                _statCard('Total Business', _fmtInt(totalBaseAmount)),
              ],
            ),
            SizedBox(height: 14.h),

            // Total count note
            Text(
              'Total appointments: ${filteredAppointments.length}',
              style: GoogleFonts.poppins(
                  fontSize: 10.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Text(
              '* Multi-service appointments are shown individually for each service. Status with * indicates multi-service appointment.',
              style: GoogleFonts.poppins(
                  fontSize: 9.sp, color: const Color(0xFF94A3B8)),
            ),
            SizedBox(height: 10.h),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTable(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Pagination
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    const headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Color(0xFF475569),
    );
    final cellStyle =
        GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF1E293B));

    return DataTable(
      headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
      headingRowHeight: 36.h,
      dataRowHeight: 44.h,
      columnSpacing: 20.w,
      dividerThickness: 0.6,
      border: TableBorder(
        horizontalInside:
            BorderSide(color: const Color(0xFFE2E8F0), width: 0.6),
        bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 0.6),
        top: BorderSide(color: const Color(0xFFE2E8F0), width: 0.6),
      ),
      columns: const [
        DataColumn(label: Text('Client', style: headerStyle)),
        DataColumn(label: Text('Service', style: headerStyle)),
        DataColumn(label: Text('Staff', style: headerStyle)),
        DataColumn(label: Text('Scheduled On', style: headerStyle)),
        DataColumn(label: Text('Created On', style: headerStyle)),
        DataColumn(label: Text('Time', style: headerStyle)),
        DataColumn(label: Text('Duration', style: headerStyle)),
        DataColumn(label: Text('Base Amount', style: headerStyle)),
        DataColumn(label: Text('Platform Fee', style: headerStyle)),
        DataColumn(label: Text('Service Tax', style: headerStyle)),
        DataColumn(label: Text('Final Amount', style: headerStyle)),
        DataColumn(label: Text('Status', style: headerStyle)),
      ],
      rows: [
        ...pagedAppointments.map((a) {
          return DataRow(cells: [
            DataCell(Text(a['client'], style: cellStyle)),
            DataCell(Text(a['services'], style: cellStyle)),
            DataCell(Text(a['staffName'], style: cellStyle)),
            DataCell(Text(DateFormat('dd MMM yyyy').format(a['scheduledOn']),
                style: cellStyle)),
            DataCell(Text(DateFormat('dd MMM yyyy').format(a['createdOn']),
                style: cellStyle)),
            DataCell(Text(
              '${DateFormat('HH:mm').format(a['scheduledOn'])} - ${DateFormat('HH:mm').format(a['scheduledEnd'])}',
              style: cellStyle,
            )),
            DataCell(Text(a['duration'], style: cellStyle)),
            DataCell(Text(_fmt(a['baseAmount']), style: cellStyle)),
            DataCell(Text(_fmt(a['platformFee']), style: cellStyle)),
            DataCell(Text(_fmt(a['serviceTax']), style: cellStyle)),
            DataCell(Text(_fmt(a['price']), style: cellStyle)),
            DataCell(_statusBadge(a['status'])),
          ]);
        }),

        // Total row
        DataRow(
          color: MaterialStateProperty.all(const Color(0xFFFFFBEB)),
          cells: [
            DataCell(Text('Total',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, fontWeight: FontWeight.w700))),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            DataCell(Text(_fmt(totalBaseAmount),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, fontWeight: FontWeight.w700))),
            DataCell(Text(_fmt(totalPlatformFee),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, fontWeight: FontWeight.w700))),
            DataCell(Text(_fmt(totalServiceTax),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, fontWeight: FontWeight.w700))),
            DataCell(Text(_fmt(totalFinal),
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, fontWeight: FontWeight.w700))),
            const DataCell(Text('')),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
            fontSize: 9.sp, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildPagination() {
    final start = _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage)
        .clamp(0, filteredAppointments.length);
    final total = filteredAppointments.length;

    return Row(
      children: [
        Text(
          'Showing $start to $end of $total results',
          style: GoogleFonts.poppins(
              fontSize: 10.sp, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text('Rows per page',
            style: GoogleFonts.poppins(
                fontSize: 10.sp, color: const Color(0xFF64748B))),
        SizedBox(width: 6.w),
        Container(
          height: 28.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(4.r),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              style: GoogleFonts.poppins(
                  fontSize: 10.sp, color: const Color(0xFF1E293B)),
              items: [5, 10, 20, 50]
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e.toString())))
                  .toList(),
              onChanged: (v) => setState(() {
                _rowsPerPage = v!;
                _currentPage = 0;
              }),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          'Page ${_currentPage + 1} of $totalPages',
          style: GoogleFonts.poppins(
              fontSize: 10.sp, color: const Color(0xFF1E293B)),
        ),
        SizedBox(width: 6.w),
        _pageBtn(Icons.chevron_left, _currentPage > 0,
            () => setState(() => _currentPage--)),
        SizedBox(width: 4.w),
        _pageBtn(Icons.chevron_right, _currentPage < totalPages - 1,
            () => setState(() => _currentPage++)),
      ],
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
        child: Icon(
          icon,
          size: 14.sp,
          color: enabled ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
        ),
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
          children: [
            Icon(icon,
                size: 12.sp,
                color: filled ? Colors.white : const Color(0xFF1E293B)),
            SizedBox(width: 5.w),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : const Color(0xFF1E293B),
                )),
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
            child: Text(
              'Appointment Summary',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 18),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: CircleAvatar(
                radius: 14.r,
                backgroundImage: const AssetImage('assets/images/profile.jpeg'),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
