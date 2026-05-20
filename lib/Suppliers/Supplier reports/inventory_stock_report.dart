import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../utils/export_helper.dart';
import '../../widgets/report_filter_sheet.dart';
import '../../widgets/report_widgets.dart';

class InventoryStockReport extends StatefulWidget {
  const InventoryStockReport({super.key});

  @override
  State<InventoryStockReport> createState() => _InventoryStockReportState();
}

class _InventoryStockReportState extends State<InventoryStockReport> {
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  String _searchText = '';
  Map<String, dynamic> _filters = {
    'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 90))),
    'endDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'product': 'All',
    'category': 'All',
    'brand': 'All',
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
      final response = await ApiService.getInventoryStockReport(
        startDate: _filters['startDate'],
        endDate: _filters['endDate'],
        product: _filters['product'] == 'All' ? null : _filters['product'],
        category: _filters['category'] == 'All' ? null : _filters['category'],
        brand: _filters['brand'] == 'All' ? null : _filters['brand'],
      );
      final List<dynamic> raw = (response['data']?['products'] as List?) ?? [];
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
        final name = (row['productName'] ?? '').toString().toLowerCase();
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

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  int _getStock(dynamic p) => ((p['stockAvailable'] ?? p['stock'] ?? p['currentStock'] ?? 0) as num).toInt();

  @override
  Widget build(BuildContext context) {
    int inStockCount = _filtered.where((p) => _getStock(p) > 10).length;
    int lowStockCount = _filtered.where((p) { final s = _getStock(p); return s > 0 && s <= 10; }).length;
    int outOfStockCount = _filtered.where((p) => _getStock(p) <= 0).length;
    int totalQty = _filtered.fold(0, (sum, p) => sum + _getStock(p));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ReportAppBar(
        title: 'Inventory / Stock Report',
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
              hintText: 'Search inventory...',
              onChanged: (v) {
                _searchText = v;
                _applyFilter();
              },
              onFilterTap: _showFilterSheet,
              exportMenu: PopupMenuButton<String>(
                position: PopupMenuPosition.under,
                offset: Offset(0, 8.h),
                child: const ReportPlumButton(
                  label: 'Export',
                  suffixIcon: Icons.download_rounded,
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
            ),
            SizedBox(height: 20.h),

            // Stats grid in 2 columns
            ReportStatsGrid(
              children: [
                ReportStatCard(
                  label: 'In Stock Items',
                  value: inStockCount.toString().padLeft(2, '0'),
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  circleBgColor: const Color(0xFFECFDF5),
                ),
                ReportStatCard(
                  label: 'Low Stock Items',
                  value: lowStockCount.toString().padLeft(2, '0'),
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  circleBgColor: const Color(0xFFFEF3C7),
                ),
                ReportStatCard(
                  label: 'Out of Stock',
                  value: outOfStockCount.toString().padLeft(2, '0'),
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFC62828),
                  circleBgColor: const Color(0xFFFFEBEE),
                ),
                ReportStatCard(
                  label: 'Total Available Quantity',
                  value: totalQty.toString().padLeft(2, '0'),
                  icon: Icons.unarchive_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  circleBgColor: const Color(0xFFEFF6FF),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Inventory / Stock Report',
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
          headingRowColor: MaterialStateProperty.all(Colors.white),
          headingTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF71717A),
          ),
          dataTextStyle: GoogleFonts.poppins(
            fontSize: 9.sp,
            color: Colors.black87,
          ),
          dividerThickness: 0,
          horizontalMargin: 8.w,
          columnSpacing: 16.w,
          columns: const [
            DataColumn(label: Text('Product Name')),
            DataColumn(label: Text('Stock Available')),
            DataColumn(label: Text('Stock Status')),
          ],
          rows: [
            ..._pageItems.map((r) {
              final stock = r['stockAvailable'] ?? r['stock'] ?? r['currentStock'] ?? 0;
              final status = r['stockStatus'] ?? r['status'] ?? '—';
              return DataRow(
                cells: [
                  DataCell(Text(r['productName']?.toString() ?? '—')),
                  DataCell(Text('$stock units')),
                  DataCell(_buildStatusBadge(status.toString(), stock)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, dynamic stock) {
    Color color = Colors.green;
    String label = status.toUpperCase();
    final s = stock as num? ?? 0;

    if (s <= 0) {
      color = Colors.red;
      label = 'OUT OF STOCK';
    } else if (s <= 10) {
      color = Colors.orange;
      label = 'LOW STOCK';
    } else {
      color = Colors.green;
      label = 'IN STOCK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 8.sp,
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
            Icons.inventory_2_outlined,
            size: 40.sp,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No inventory data found',
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
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
          FilterField(label: 'Filter by product', key: 'product', options: ['All', ..._getUniqueValues('productName')]),
          FilterField(label: 'Filter by category', key: 'category', options: ['All', ..._getUniqueValues('category')]),
          FilterField(label: 'Filter by brand', key: 'brand', options: ['All', ..._getUniqueValues('brand')]),
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
              'product': 'All',
              'category': 'All',
              'brand': 'All',
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

  PopupMenuItem<String> _buildExportItem(String val, IconData icon, String label) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [Icon(icon, size: 16), SizedBox(width: 8), Text(label)]),
    );
  }

  void _handleExport(String type) async {
    if (_filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    final headers = ['Product Name', 'Stock Available', 'Status'];
    final rows = _filtered.map((r) {
      final stock = r['stockAvailable'] ?? r['stock'] ?? r['currentStock'] ?? 0;
      final status = r['stockStatus'] ?? r['status'] ?? '—';
      return [
        r['productName'] ?? '—',
        stock,
        status.toString().toUpperCase(),
      ];
    }).toList();

    try {
      await ExportHelper.executeExport(
        type,
        fileName: 'Inventory_Report',
        title: 'Inventory / Stock Report',
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
