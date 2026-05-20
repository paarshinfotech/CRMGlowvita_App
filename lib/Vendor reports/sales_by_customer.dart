import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../widgets/report_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class SalesByCustomer extends StatefulWidget {
  const SalesByCustomer({super.key});

  @override
  State<SalesByCustomer> createState() => _SalesByCustomerState();
}

class _SalesByCustomerState extends State<SalesByCustomer> {
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

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
      final result = await ApiService.getSalesByCustomerReport(
        startDate: _dateRange != null ? DateFormat('yyyy-MM-dd').format(_dateRange!.start) : null,
        endDate: _dateRange != null ? DateFormat('yyyy-MM-dd').format(_dateRange!.end) : null,
      );
      final raw = (result['data']?['salesByCustomer'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _all = raw;
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
      _filtered = _all.where((row) {
        return (row['customer'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
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

  List<Map<String, dynamic>> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  double _n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  String _fmt(num v) => '₹${NumberFormat('#,##0').format(v)}';

  @override
  Widget build(BuildContext context) {
    int totalSold = _filtered.fold(0, (sum, r) => sum + ((r['serviceSold'] as num?)?.toInt() ?? 0));
    double totalGross = _filtered.fold(0.0, (sum, r) => sum + _n(r['grossSale']));
    double totalNet = _filtered.fold(0.0, (sum, r) => sum + _n(r['netSale']));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ReportAppBar(
        title: 'Sales by Customer',
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
              hintText: 'Search customer...',
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
                  label: 'Total Customers',
                  value: _filtered.length.toString().padLeft(2, '0'),
                  icon: Icons.people_outline_rounded,
                  iconColor: const Color(0xFF7C5CFC),
                  circleBgColor: const Color(0xFFF3F0FF),
                ),
                ReportStatCard(
                  label: 'Total Sold',
                  value: totalSold.toString().padLeft(2, '0'),
                  icon: Icons.shopping_bag_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  circleBgColor: const Color(0xFFEFF6FF),
                ),
                ReportStatCard(
                  label: 'Gross Sales',
                  value: _fmt(totalGross),
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  circleBgColor: const Color(0xFFFEF3C7),
                ),
                ReportStatCard(
                  label: 'Net Sales',
                  value: _fmt(totalNet),
                  icon: Icons.price_check_rounded,
                  iconColor: const Color(0xFF10B981),
                  circleBgColor: const Color(0xFFECFDF5),
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
            child: Text('Sales by Customer',
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
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Sold')),
            DataColumn(label: Text('Gross')),
            DataColumn(label: Text('Net')),
            DataColumn(label: Text('Tax')),
            DataColumn(label: Text('Total')),
          ],
          rows: [
            ..._pageItems.map((r) => DataRow(cells: [
              DataCell(Text(r['customer']?.toString() ?? '—')),
              DataCell(Text(r['serviceSold']?.toString() ?? '0')),
              DataCell(Text(_fmt(_n(r['grossSale'])))),
              DataCell(Text(_fmt(_n(r['netSale'])))),
              DataCell(Text(_fmt(_n(r['tax'])))),
              DataCell(Text(_fmt(_n(r['totalSales'])), style: const TextStyle(fontWeight: FontWeight.bold))),
            ])),
            _buildTotalsRow(),
          ],
        ),
      ),
    );
  }

  DataRow _buildTotalsRow() {
    int tSold = 0;
    double tGross = 0;
    double tNet = 0;
    double tTax = 0;
    double tTotal = 0;

    for (var r in _filtered) {
      tSold += (r['serviceSold'] as num?)?.toInt() ?? 0;
      tGross += _n(r['grossSale']);
      tNet += _n(r['netSale']);
      tTax += _n(r['tax']);
      tTotal += _n(r['totalSales']);
    }

    return DataRow(
      color: MaterialStateProperty.all(const Color(0xFFF9F9FB)),
      cells: [
        DataCell(Text('TOTAL', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 9.sp))),
        DataCell(Text('$tSold', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(_fmt(tGross), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(_fmt(tNet), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(_fmt(tTax), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(_fmt(tTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: _purple))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_search_rounded, size: 40.sp, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No customer records found', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
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
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 8 : 10),
        decoration: BoxDecoration(
          color: isActive ? _purple.withOpacity(0.08) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? _purple : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? _purple : Colors.grey.shade600),
            if (!isIconOnly) ...[const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 9.sp, color: isActive ? _purple : Colors.grey.shade600, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))],
          ],
        ),
      ),
    );
  }
}
