import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../utils/export_helper.dart';
import '../../widgets/report_filter_sheet.dart';

class CategoryWiseProductReport extends StatefulWidget {
  const CategoryWiseProductReport({super.key});

  @override
  State<CategoryWiseProductReport> createState() =>
      _CategoryWiseProductReportState();
}

class _CategoryWiseProductReportState extends State<CategoryWiseProductReport> {
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  String _searchText = '';
  Map<String, dynamic> _filters = {
    'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 90))),
    'endDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'category': 'All',
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
      final response = await ApiService.getCategoryWiseProductReport(
        startDate: _filters['startDate'],
        endDate: _filters['endDate'],
        category: _filters['category'] == 'All' ? null : _filters['category'],
      );
      final List<dynamic> raw =
          (response['data']?['categories'] as List?) ?? [];
      _all = raw.cast<Map<String, dynamic>>();
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
        final name = (row['categoryName'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  List<Map<String, dynamic>> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  double _n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  String _fmt(num v) => '₹${NumberFormat('#,##0.00').format(v)}';

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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34.h,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) {
                                  _searchText = v;
                                  _applyFilter();
                                },
                                style: GoogleFonts.poppins(fontSize: 11.sp),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.grey.shade400,
                                    size: 16.sp,
                                  ),
                                  hintText: 'Search category...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F6FA),
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Category-wise Product Report',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_errorMsg != null) return _buildErrorState();
    if (_filtered.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9FB)),
          headingTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
          dataTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            color: Colors.black87,
          ),
          horizontalMargin: 12.w,
          columnSpacing: 30.w,
          columns: const [
            DataColumn(label: Text('Category Name')),
            DataColumn(label: Text('Number of Products')),
            DataColumn(label: Text('Active Products')),
            DataColumn(label: Text('Average Price')),
            DataColumn(label: Text('Average Sales Price')),
          ],
          rows: [
            ..._pageItems.map(
              (r) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      r['categoryName']?.toString() ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      (r['numberOfProducts'] ?? r['totalProducts'] ?? '0')
                          .toString(),
                    ),
                  ),
                  DataCell(Text(r['activeProducts']?.toString() ?? '0')),
                  DataCell(Text(_fmt(_n(r['averagePrice'])))),
                  DataCell(
                    Text(
                      _fmt(_n(r['averageSalePrice'] ?? r['averageSalesPrice'])),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 40.sp,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No category data found',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40.sp,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load data',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
          Text(
            'Showing $start–$end of ${_filtered.length}',
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.grey.shade500,
            ),
          ),
          const Spacer(),
          _pageBtn(
            Icons.chevron_left_rounded,
            _currentPage > 0,
            () => setState(() => _currentPage--),
          ),
          SizedBox(width: 6.w),
          _pageBtn(
            Icons.chevron_right_rounded,
            _currentPage < _totalPages - 1,
            () => setState(() => _currentPage++),
          ),
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
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
          color: enabled ? Colors.white : const Color(0xFFF5F6FA),
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: enabled ? Colors.black54 : Colors.grey.shade200,
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
          FilterField(label: 'Filter by category', key: 'category', options: ['All', ..._getUniqueValues('categoryName')]),
        ],
        onApply: (newFilters) {
          setState(() => _filters = newFilters);
          _fetchData();
        },
        onClear: () {
          setState(() {
            _filters = {
              'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 90))),
              'endDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              'category': 'All',
            };
          });
          _fetchData();
        },
      ),
    );
  }

  List<String> _getUniqueValues(String key) {
    return _all.map((e) => e[key]?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
  }

  PopupMenuItem<String> _buildExportItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 35.h,
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 10.w),
          Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  void _handleExport(String type) async {
    if (_filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final headers = ['Category Name', 'Number of Products', 'Active Products', 'Average Price', 'Average Sales Price'];
    final rows = _filtered.map((r) => [
      r['categoryName'] ?? '—',
      r['numberOfProducts'] ?? r['totalProducts'] ?? 0,
      r['activeProducts'] ?? 0,
      _n(r['averagePrice']),
      _n(r['averageSalePrice'] ?? r['averageSalesPrice']),
    ]).toList();

    try {
      await ExportHelper.executeExport(
        type,
        fileName: 'Category_Report',
        title: 'Category-wise Product Report',
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
            Icon(
              icon,
              size: 14,
              color: isActive ? _purple : Colors.grey.shade600,
            ),
            if (!isIconOnly) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  color: isActive ? _purple : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
