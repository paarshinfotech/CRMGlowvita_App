import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

const Color _primary = Color(0xFF372935);
const Color _bg = Color(0xFFF8FAFC);

class SettlementSummary extends StatefulWidget {
  const SettlementSummary({Key? key}) : super(key: key);

  @override
  State<SettlementSummary> createState() => _SettlementSummaryState();
}

class _SettlementSummaryState extends State<SettlementSummary> {
  // ── API state ────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _transfers = [];
  Map<String, dynamic> _totals = {};

  // ── Search & Filter ──────────────────────────────────────────────────────────
  String _globalSearch = '';
  String _appointmentsSearch = '';

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
      final result = await ApiService.getSettlementSummaryReport();

      final block =
          result['data']['settlementSummary'] as Map<String, dynamic>;
      final rawAppointments = (block['appointments'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final rawTransfers = (block['transfers'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final rawTotals =
          (block['totals'] as Map<String, dynamic>?) ?? {};

      setState(() {
        _appointments = rawAppointments;
        _transfers = rawTransfers;
        _totals = rawTotals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Computed & Searched Data ─────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredTransfers {
    if (_globalSearch.isEmpty) return _transfers;
    final q = _globalSearch.toLowerCase();
    return _transfers.where((t) {
      final type = (t['type'] ?? '').toString().toLowerCase();
      final method = (t['paymentMethod'] ?? '').toString().toLowerCase();
      final ref = (t['transactionId'] ?? '').toString().toLowerCase();
      return type.contains(q) || method.contains(q) || ref.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_appointmentsSearch.isEmpty) return _appointments;
    final q = _appointmentsSearch.toLowerCase();
    return _appointments.where((a) {
      final client = (a['clientName'] ?? '').toString().toLowerCase();
      final service = (a['serviceName'] ?? '').toString().toLowerCase();
      return client.contains(q) || service.contains(q);
    }).toList();
  }

  // ── Formatters ────────────────────────────────────────────────────────────────
  String _fmt(num v) => '₹${NumberFormat('#,##0.00').format(v)}';
  double _n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text('Settlement Summary Report',
              style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B))),
          SizedBox(height: 2.h),
          Text(
            'Detailed report of all settlements, payouts, and financial transactions.',
            style: GoogleFonts.poppins(
                fontSize: 10.sp, color: const Color(0xFF94A3B8)),
          ),
          SizedBox(height: 14.h),

          // Search + Export
          Row(
            children: [
              Expanded(child: _searchBar()),
              SizedBox(width: 8.w),
              _exportBtn(),
            ],
          ),
          SizedBox(height: 16.h),

          // Stats Cards
          _buildStatsRow(),
          SizedBox(height: 24.h),

          // Transfers Table
          Text('Actual Money Transfers',
              style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B))),
          SizedBox(height: 10.h),
          _buildTransfersTable(),

          SizedBox(height: 32.h),

          // Appointments Table
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Detailed Appointment Settlements',
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B))),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12.r)),
                child: Text('${_filteredAppointments.length} records',
                    style: GoogleFonts.poppins(
                        fontSize: 8.sp, color: const Color(0xFF64748B))),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _appointmentsSearchBar(),
          SizedBox(height: 10.h),
          _buildAppointmentsTable(),

          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2E8F0),
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              ),
              child: Text('Close',
                  style: GoogleFonts.poppins(
                      fontSize: 11.sp, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final owedFromAdmin = _n(_totals['totalAdminOwesVendor']);
    final payableToAdmin = _n(_totals['totalVendorOwesAdmin']);
    final totalPlatformFee = _n(_totals['totalPlatformFee']);
    final totalTaxAmount = _n(_totals['totalTaxAmount']);
    final netTransfers = _n(_totals['totalTransferredToAdmin']);
    final finalBal = _n(_totals['finalBalance']);

    final isVendorOwes = finalBal < 0;

    return Row(
      children: [
        _statCard(
          title: 'Owed from Admin',
          amount: _fmt(owedFromAdmin),
          amountColor: const Color(0xFF1E293B),
          subtitle: 'From Online Bookings',
        ),
        SizedBox(width: 10.w),
        _statCard(
          title: 'Payable to Admin',
          amount: _fmt(payableToAdmin),
          amountColor: const Color(0xFF1E293B),
          subtitle: 'Fee: ₹${totalPlatformFee.toStringAsFixed(1)} Tax: ₹${totalTaxAmount.toStringAsFixed(1)}',
        ),
        SizedBox(width: 10.w),
        _statCard(
          title: 'Total Net Transfers',
          amount: _fmt(netTransfers),
          amountColor: const Color(0xFF1E293B),
          subtitle: 'Actual Money Moved',
        ),
        SizedBox(width: 10.w),
        _statCard(
          title: 'Net Outstanding Balance',
          amount: _fmt(finalBal.abs()),
          amountColor: isVendorOwes ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          subtitle: isVendorOwes ? 'Vendor owes Admin' : 'Admin owes Vendor',
          dotColor: isVendorOwes ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String amount,
    required Color amountColor,
    required String subtitle,
    Color? dotColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 9.sp, color: const Color(0xFF64748B))),
            SizedBox(height: 6.h),
            Text(amount,
                style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: amountColor)),
            SizedBox(height: 4.h),
            Row(
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 4.w,
                    height: 4.h,
                    decoration:
                        BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 4.w),
                ],
                Expanded(
                  child: Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 8.sp, color: const Color(0xFF94A3B8))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersTable() {
    return _wrapperTable(
      DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.white),
        headingTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B)),
        dataTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B)),
        dataRowMinHeight: 44.h,
        dataRowMaxHeight: 52.h,
        horizontalMargin: 16.w,
        dividerThickness: 1,
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFF1F5F9)),
        ),
        columns: const [
          DataColumn(label: Text('Execution Date')),
          DataColumn(label: Text('Transaction Type')),
          DataColumn(label: Text('Payment Method')),
          DataColumn(label: Text('Transaction Reference')),
          DataColumn(label: Text('Transfer Amount'), numeric: true),
        ],
        rows: _filteredTransfers.map((t) {
          final isOutToAdmin =
              (t['type'] as String? ?? '').toLowerCase() ==
                  'payment to admin';
          final badgeColor = isOutToAdmin
              ? const Color(0xFFFEE2E2)
              : const Color(0xFFDCFCE7);
          final badgeTextColor = isOutToAdmin
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A);
          final actType =
              isOutToAdmin ? 'OUT: TO ADMIN' : (t['type']?.toUpperCase() ?? 'IN');

          final dateStr = t['paymentDate'] != null
              ? DateFormat('M/d/yyyy').format(DateTime.parse(t['paymentDate']))
              : '—';
          final method = t['paymentMethod'] ?? '—';
          final ref = (t['transactionId'] == null ||
                  t['transactionId'].toString().isEmpty)
              ? '—'
              : t['transactionId'];
          final amt = _n(t['amount']);

          return DataRow(
            color: MaterialStateProperty.all(Colors.white),
            cells: [
              DataCell(Text(dateStr)),
              DataCell(Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(actType,
                    style: GoogleFonts.poppins(
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w600,
                        color: badgeTextColor)),
              )),
              DataCell(Text(method)),
              DataCell(Text(ref.toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp, color: const Color(0xFF94A3B8)))),
              DataCell(Text(_fmt(amt),
                  style: GoogleFonts.poppins(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: isOutToAdmin
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A)))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentsTable() {
    return _wrapperTable(
      DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.white),
        headingTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B)),
        dataRowMinHeight: 52.h,
        dataRowMaxHeight: 64.h,
        horizontalMargin: 16.w,
        dividerThickness: 1,
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFF1F5F9)),
        ),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Client & Service')),
          DataColumn(label: Text('Mode')),
          DataColumn(label: Text('Owed from Admin'), numeric: true),
          DataColumn(label: Text('Payable to Admin'), numeric: true),
        ],
        rows: _filteredAppointments.map((a) {
          final dateStr = a['date'] != null
              ? DateFormat('M/d/yyyy').format(DateTime.parse(a['date']))
              : '—';

          final owedAdminAmt = _n(a['adminOwesVendor']);
          final payableAdminAmt = _n(a['vendorOwesAdmin']);
          final fee = _n(a['platformFee']);
          final tax = _n(a['serviceTax']);
          final payMethod = a['paymentMethod'] ?? '—';

          return DataRow(
            color: MaterialStateProperty.all(Colors.white),
            cells: [
              DataCell(Text(dateStr,
                  style: GoogleFonts.poppins(
                      fontSize: 9.sp, color: const Color(0xFF1E293B)))),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['clientName'] ?? '—',
                      style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B))),
                  Text(a['serviceName'] ?? '—',
                      style: GoogleFonts.poppins(
                          fontSize: 8.sp, color: const Color(0xFF64748B))),
                ],
              )),
              DataCell(Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(payMethod,
                    style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B))),
              )),
              DataCell(Text(_fmt(owedAdminAmt),
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981)))),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(payableAdminAmt),
                      style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444))),
                  Text('(Fee: ${fee.toStringAsFixed(1)}, Tax: ${tax.toStringAsFixed(1)})',
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp, color: const Color(0xFF94A3B8))),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _wrapperTable(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }

  // ── Error / Helpers ───────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 48.sp),
          SizedBox(height: 12.h),
          Text(_error ?? 'Error',
              style: GoogleFonts.poppins(fontSize: 11.sp)),
          SizedBox(height: 20.h),
          ElevatedButton(onPressed: _fetchReport, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _searchBar() => Container(
        height: 38.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          children: [
            Icon(Icons.search, size: 14.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _globalSearch = v),
                decoration: InputDecoration(
                  hintText: 'Search...',
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

  Widget _appointmentsSearchBar() => Container(
        height: 38.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          children: [
            Icon(Icons.search, size: 14.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _appointmentsSearch = v),
                decoration: InputDecoration(
                  hintText: 'Filter by Client or Service...',
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

  Widget _exportBtn() => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(6.r),
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Icon(Icons.file_download_outlined,
                  color: Colors.white, size: 13.sp),
              SizedBox(width: 6.w),
              Text('Export',
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ],
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
              child: Text('Settlement Summary Report',
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
