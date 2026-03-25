import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

const Color _primary = Color(0xFF372935);
const Color _bg = Color(0xFFF8FAFC);

class CategoryWiseProductReport extends StatefulWidget {
  const CategoryWiseProductReport({super.key});

  @override
  State<CategoryWiseProductReport> createState() => _CategoryWiseProductReportState();
}

class _CategoryWiseProductReportState extends State<CategoryWiseProductReport> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _categories = [];
  String _search = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getCategoryWiseProductReport();
      final categoriesList = (result['data']['categories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      setState(() {
        _categories = categoriesList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    if (_search.isEmpty) return _categories;
    final q = _search.toLowerCase();
    return _categories.where((c) {
      final name = (c['categoryName'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  String _fmt(num v) => '₹${NumberFormat('#,##0.00').format(v)}';

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
    final filtered = _filteredCategories;
    final totalResults = filtered.length;
    final totalPages = (totalResults / _rowsPerPage).ceil() == 0 ? 1 : (totalResults / _rowsPerPage).ceil();
    final startIdx = (_currentPage - 1) * _rowsPerPage;
    final endIdx = (startIdx + _rowsPerPage) > totalResults ? totalResults : (startIdx + _rowsPerPage);
    final displayedData = filtered.sublist(startIdx, endIdx);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category-wise Product Report',
                        style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B))),
                    SizedBox(height: 2.h),
                    Text(
                      'Aggregated view showing product counts and sales by category.',
                      style: GoogleFonts.poppins(
                          fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18.sp, color: const Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Search + Export
            Row(
              children: [
                Expanded(child: _searchBar()),
                SizedBox(width: 8.w),
                _filterBtn(),
                SizedBox(width: 8.w),
                _exportBtn(),
              ],
            ),
            SizedBox(height: 16.h),

            // Table
            _buildProductsTable(displayedData),
            SizedBox(height: 16.h),

            // Pagination
            _buildPagination(totalResults, startIdx, endIdx, totalPages),
            SizedBox(height: 16.h),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF1E293B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r)),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text('Close',
                    style: GoogleFonts.poppins(
                        fontSize: 11.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(List<Map<String, dynamic>> displayedData) {
    return _wrapperTable(
      DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
        headingTextStyle: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B)),
        dataTextStyle: GoogleFonts.poppins(
            fontSize: 10.sp,
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
          DataColumn(label: Text('Category Name')),
          DataColumn(label: Text('Number of Products')),
          DataColumn(label: Text('Active Products')),
          DataColumn(label: Text('Average Price')),
          DataColumn(label: Text('Average Sale Price')),
        ],
        rows: displayedData.map((c) {
          final cName = c['categoryName'] ?? '—';
          final numProducts = c['numberOfProducts']?.toString() ?? '0';
          final numActive = c['activeProducts']?.toString() ?? '0';
          final avgPrice = c['averagePrice'] != null ? _fmt(c['averagePrice']) : '—';
          final avgSalePrice = c['averageSalePrice'] != null ? _fmt(c['averageSalePrice']) : '—';

          return DataRow(
            color: MaterialStateProperty.all(Colors.white),
            cells: [
              DataCell(Text(cName)),
              DataCell(Text(numProducts)),
              DataCell(Text(numActive)),
              DataCell(Text(avgPrice)),
              DataCell(Text(avgSalePrice)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination(int totalResults, int startIdx, int endIdx, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${totalResults == 0 ? 0 : startIdx + 1} to $endIdx of $totalResults results',
          style: GoogleFonts.poppins(
              fontSize: 10.sp, color: const Color(0xFF64748B)),
        ),
        Row(
          children: [
            Text('Rows per page  ',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, color: const Color(0xFF64748B))),
            Container(
              height: 28.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  icon: Icon(Icons.keyboard_arrow_down, size: 14.sp),
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp, color: const Color(0xFF1E293B)),
                  items: [10, 25, 50]
                      .map((val) => DropdownMenuItem(value: val, child: Text(val.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _rowsPerPage = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
            SizedBox(width: 12.w),
            IconButton(
              icon: Icon(Icons.chevron_left, size: 18.sp),
              onPressed: _currentPage > 1
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
              color: _currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: 4.w),
            Text('Page $_currentPage of $totalPages',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, color: const Color(0xFF64748B))),
            SizedBox(width: 4.w),
            IconButton(
              icon: Icon(Icons.chevron_right, size: 18.sp),
              onPressed: _currentPage < totalPages
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
              color: _currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 48.sp),
          SizedBox(height: 12.h),
          Text(_error ?? 'Error', style: GoogleFonts.poppins(fontSize: 11.sp)),
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
                onChanged: (v) {
                  setState(() {
                    _search = v;
                    _currentPage = 1;
                  });
                },
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

  Widget _filterBtn() => InkWell(
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
              Icon(Icons.filter_alt_outlined, color: Colors.white, size: 13.sp),
              SizedBox(width: 6.w),
              Text('Filters',
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ],
          ),
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
              Icon(Icons.file_download_outlined, color: Colors.white, size: 13.sp),
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
              child: Text('Category-wise Product Report',
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
