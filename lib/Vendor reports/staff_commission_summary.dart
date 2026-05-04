import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/export_helper.dart';
import '../widgets/report_filter_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class _StaffCommission {
  final String staffId;
  final String staffName;
  final String commissionRate;
  final num totalCommissionEarned;
  final num totalPaidOut;
  final num netCommissionBalance;
  final int commissionCount;
  final String lastTransactionDate;
  final List<_Transaction> transactions;

  _StaffCommission({
    required this.staffId,
    required this.staffName,
    required this.commissionRate,
    required this.totalCommissionEarned,
    required this.totalPaidOut,
    required this.netCommissionBalance,
    required this.commissionCount,
    required this.lastTransactionDate,
    required this.transactions,
  });

  factory _StaffCommission.fromJson(Map<String, dynamic> j) {
    final txList = (j['transactions'] as List? ?? [])
        .map((t) => _Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    return _StaffCommission(
      staffId: j['staffId']?.toString() ?? '',
      staffName: j['staffName'] ?? '—',
      commissionRate: j['commissionRate'] ?? '0%',
      totalCommissionEarned: (j['totalCommissionEarned'] as num?) ?? 0,
      totalPaidOut: (j['totalPaidOut'] as num?) ?? 0,
      netCommissionBalance: (j['netCommissionBalance'] as num?) ?? 0,
      commissionCount: (j['commissionCount'] as num?)?.toInt() ?? 0,
      lastTransactionDate: j['lastTransactionDate'] ?? 'N/A',
      transactions: txList,
    );
  }
}

class _Transaction {
  final String transactionId;
  final String transactionDate;
  final String appointmentId;
  final String client;
  final String serviceName;
  final num appointmentAmount;
  final num commissionRate;
  final num commissionEarned;
  final String type;
  final String notes;

  _Transaction({
    required this.transactionId,
    required this.transactionDate,
    required this.appointmentId,
    required this.client,
    required this.serviceName,
    required this.appointmentAmount,
    required this.commissionRate,
    required this.commissionEarned,
    required this.type,
    required this.notes,
  });

  factory _Transaction.fromJson(Map<String, dynamic> j) {
    return _Transaction(
      transactionId: j['transactionId']?.toString() ?? '',
      transactionDate: j['transactionDate'] ?? '',
      appointmentId: j['appointmentId']?.toString() ?? '-',
      client: j['client'] ?? '-',
      serviceName: j['serviceName'] ?? '—',
      appointmentAmount: (j['appointmentAmount'] as num?) ?? 0,
      commissionRate: (j['commissionRate'] as num?) ?? 0,
      commissionEarned: (j['commissionEarned'] as num?) ?? 0,
      type: j['type'] ?? '',
      notes: j['notes'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class StaffCommissionSummary extends StatefulWidget {
  const StaffCommissionSummary({super.key});

  @override
  State<StaffCommissionSummary> createState() => _StaffCommissionSummaryState();
}

class _StaffCommissionSummaryState extends State<StaffCommissionSummary> {
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<_StaffCommission> _all = [];
  List<_StaffCommission> _filtered = [];

  String _searchText = '';
  Map<String, dynamic> _filters = {
    'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30))),
    'endDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'staff': 'All',
  };

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
      final raw = await ApiService.getStaffCommissionReport(
        startDate: _filters['startDate'],
        endDate: _filters['endDate'],
        staffId: _filters['staff'] == 'All' ? null : _filters['staff'],
      );
      _all = raw.map((e) => _StaffCommission.fromJson(e as Map<String, dynamic>)).toList();
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
      _filtered = _all.where((s) => s.staffName.toLowerCase().contains(q)).toList();
    });
  }


  List<_StaffCommission> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  String _fmt(num v) => '₹${NumberFormat('#,##0').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
                            label: 'Filter',
                            isActive: true,
                            onTap: _showFilterSheet,
                          ),
                          SizedBox(width: 8.w),
                          PopupMenuButton<String>(
                            position: PopupMenuPosition.under,
                            offset: Offset(0, 10.h),
                             child: _toolbarBtn(
                               icon: Icons.upload_rounded,
                               label: 'Export',
                               onTap: null,
                             ),
                            onSelected: (value) => _handleExport(value),
                            itemBuilder: (context) => [
                              _buildExportItem('copy', Icons.copy_rounded, 'Copy'),
                              _buildExportItem('excel', Icons.grid_on_rounded, 'Excel'),
                              _buildExportItem('csv', Icons.description_rounded, 'CSV'),
                              _buildExportItem('pdf', Icons.picture_as_pdf_rounded, 'PDF'),
                              _buildExportItem('print', Icons.print_rounded, 'Print'),
                            ],
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
            child: Text('Staff Commission Summary',
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
            DataColumn(label: Text('Staff Name')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Total Earned')),
            DataColumn(label: Text('Paid Out')),
            DataColumn(label: Text('Balance')),
            DataColumn(label: Text('Last Tx')),
            DataColumn(label: Text('Action')),
          ],
          rows: _pageItems.map((s) => DataRow(cells: [
            DataCell(Text(s.staffName)),
            DataCell(Text(s.commissionRate)),
            DataCell(Text(_fmt(s.totalCommissionEarned))),
            DataCell(Text(_fmt(s.totalPaidOut))),
            DataCell(Text(_fmt(s.netCommissionBalance), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            DataCell(Text(s.lastTransactionDate)),
            DataCell(InkWell(
              onTap: () => _showDetailSheet(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('View', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            )),
          ])).toList(),
        ),
      ),
    );
  }

  void _showDetailSheet(_StaffCommission s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.staffName, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Text('Commission Detail', style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                    ]),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: s.transactions.isEmpty
                  ? Center(child: Text('No transactions found', style: GoogleFonts.poppins(color: Colors.grey)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowHeight: 40,
                          dataRowHeight: 45,
                          columnSpacing: 15.w,
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Client')),
                            DataColumn(label: Text('Service')),
                            DataColumn(label: Text('Earned')),
                            DataColumn(label: Text('Type')),
                          ],
                          rows: s.transactions.map((tx) => DataRow(cells: [
                            DataCell(Text(tx.transactionDate, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(tx.client, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(tx.serviceName, style: const TextStyle(fontSize: 10))),
                            DataCell(Text('₹${tx.commissionEarned}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            DataCell(Text(tx.type, style: TextStyle(fontSize: 10, color: tx.type == 'CREDIT' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                          ])).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded, size: 40.sp, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No commission records found', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
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

  Widget _toolbarBtn({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool isIconOnly = false,
  }) {
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
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportFilterSheet(
        initialFilters: _filters,
        fields: [
          FilterField(label: 'Filter by Staff', key: 'staff', options: ['All', ..._getUniqueValues('staffName')]),
        ],
        onApply: (newFilters) {
          setState(() => _filters = newFilters);
          _fetchData();
        },
        onClear: () {
          setState(() {
            _filters = {
              'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30))),
              'endDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              'staff': 'All',
            };
          });
          _fetchData();
        },
      ),
    );
  }

  List<String> _getUniqueValues(String key) {
    return _all.map((e) => e.staffName).where((e) => e != '—').toSet().toList()..sort();
  }

  PopupMenuItem<String> _buildExportItem(String val, IconData icon, String label) {
    return PopupMenuItem(
      value: val,
      height: 35.h,
      child: Row(children: [Icon(icon, size: 16.sp, color: Colors.grey), SizedBox(width: 10.w), Text(label, style: GoogleFonts.poppins(fontSize: 11.sp))]),
    );
  }

  void _handleExport(String type) async {
    if (_filtered.isEmpty) return;
    
    final headers = ['Staff Name', 'Rate', 'Total Earned', 'Paid Out', 'Balance', 'Last Tx'];
    final rows = _filtered.map((s) => [
      s.staffName,
      s.commissionRate,
      s.totalCommissionEarned,
      s.totalPaidOut,
      s.netCommissionBalance,
      s.lastTransactionDate,
    ]).toList();

    try {
      await ExportHelper.executeExport(
        type,
        fileName: 'Staff_Commission_Report',
        title: 'Staff Commission Summary',
        headers: headers,
        rows: rows,
      );
      if (type == 'copy') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }
}
