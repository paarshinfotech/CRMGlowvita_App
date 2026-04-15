import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import './supp_drawer.dart';
import '../services/api_service.dart';

class SuppInventoryPage extends StatefulWidget {
  const SuppInventoryPage({super.key});

  @override
  State<SuppInventoryPage> createState() => _SuppInventoryPageState();
}

class _SuppInventoryPageState extends State<SuppInventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Product> _products = [];
  List<InventoryTransaction> _transactions = [];
  String _errorMessage = '';

  final Color kPrimary = const Color(0xFF3D1A47);
  final Color kPrimaryLight = const Color(0xFF6B3FA0);
  final Color kBg = const Color(0xFFF4F4F6);
  final Color kBorder = const Color(0xFFECECEC);
  final Color kBorderMid = const Color(0xFFDCDCDC);
  final Color kCardBg = Colors.white;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final products = await ApiService.getProducts();
      final transactions = await ApiService.getSupplierInventoryTransactions();
      if (mounted) {
        setState(() {
          _products = products;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Data is now fetched dynamically

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: kPrimary,
        textTheme: GoogleFonts.dmSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: kBg,
        drawer: const SupplierDrawer(currentPage: 'Inventory'),
        appBar: _buildAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(),
            SizedBox(height: 12.h),
            _buildTabBar(),
            SizedBox(height: 12.h),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    )
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStockManagement(),
                            _buildTransactionHistory(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: kBorder),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'Inventory Management',
        style: TextStyle(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.black, size: 20.sp),
          onPressed: _fetchData,
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Retry', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final lowStockCount = _products.where((p) => (p.stock ?? 0) < 10).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Products',
              value: '${_products.length}',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF4F46E5),
              iconBg: const Color(0xFFEEF2FF),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildStatCard(
              title: 'Low Stock Alerts',
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEA580C),
              iconBg: const Color(0xFFFFF7ED),
              valueColor: const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17.sp),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8EA),
          borderRadius: BorderRadius.circular(9),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorPadding: const EdgeInsets.all(3),
          // Force black on both selected and unselected
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Stock Management'),
            Tab(text: 'Transaction History'),
          ],
        ),
      ),
    );
  }

  // ─── Stock Management ─────────────────────────────────────────────────────

  Widget _buildStockManagement() {
    final filtered = _products
        .where((p) =>
            (p.productName ?? '').toLowerCase().contains(_searchQuery) ||
            (p.category ?? '').toLowerCase().contains(_searchQuery))
        .toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Stock (${filtered.length})',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              _buildSearchField(),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoData('No products found matching "$_searchQuery"')
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildProductStockCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildProductStockCard(Product p) {
    final String image =
        (p.productImages != null && p.productImages!.isNotEmpty)
            ? p.productImages!.first
            : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Product Image
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Icon(Icons.image,
                          size: 24.sp, color: Colors.grey[300]),
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Icon(Icons.image, size: 24.sp, color: Colors.grey[300]),
            ),
            SizedBox(width: 12.w),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.productName ?? 'N/A',
                    style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.category ?? 'Uncategorized',
                    style: TextStyle(fontSize: 9.5.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Text(
                        '₹${p.salePrice ?? p.price ?? 0}',
                        style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: kPrimary),
                      ),
                      const Spacer(),
                      _buildStockBadge(p.stock ?? 0),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            VerticalDivider(
                width: 1, indent: 5.h, endIndent: 5.h, color: kBorder),
            SizedBox(width: 8.w),
            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Adjust',
                  color: kPrimary,
                  onTap: () => _showAdjustStockDialog(
                      p.productName ?? 'N/A', p.stock ?? 0),
                ),
                SizedBox(height: 8.h),
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Details',
                  color: Colors.grey[700]!,
                  onTap: () => _showProductDetailsDialog(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    final bool isLow = stock < 10;
    final bool isOut = stock <= 0;
    Color bg = const Color(0xFFEEF2FF);
    Color fg = const Color(0xFF3730A3);
    String label = 'In Stock: $stock';

    if (isOut) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      label = 'Out of Stock';
    } else if (isLow) {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFEA580C);
      label = 'Low Stock: $stock';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 140.w,
      height: 32.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 10.sp, color: Colors.black),
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search stock...',
          hintStyle: TextStyle(fontSize: 10.sp, color: const Color(0xFFAAAAAA)),
          prefixIcon:
              Icon(Icons.search, size: 13.sp, color: const Color(0xFFAAAAAA)),
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Transaction History ──────────────────────────────────────────────────

  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) {
      return _buildNoData('No transaction history found');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(14.w),
      child: Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
              child: Text(
                'Audit Logs',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16.w,
                headingRowHeight: 38.h,
                dataRowMinHeight: 44.h,
                dataRowMaxHeight: 52.h,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFFAFAFA)),
                dividerThickness: 0.5,
                columns: [
                  _buildDataColumn('Date'),
                  _buildDataColumn('Product'),
                  _buildDataColumn('Type'),
                  _buildDataColumn('Qty'),
                  _buildDataColumn('New'),
                  _buildDataColumn('Reason'),
                  _buildDataColumn('Reference'),
                ],
                rows: _transactions.map((h) => _buildHistoryRow(h)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 32.sp, color: Colors.grey[300]),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  DataRow _buildHistoryRow(InventoryTransaction h) {
    final bool isOut = h.type.toUpperCase() == 'OUT';
    final Color typeFg =
        isOut ? const Color(0xFFB91C1C) : const Color(0xFF15803D);

    final String formattedDate = DateFormat('MMM dd, hh:mm a').format(h.date);

    return DataRow(cells: [
      DataCell(Text(formattedDate,
          style: TextStyle(fontSize: 8.5.sp, color: const Color(0xFF666666)))),
      DataCell(Text(h.productId.productName,
          style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black))),
      DataCell(
        Text(
          h.type,
          style: TextStyle(
              fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: typeFg),
        ),
      ),
      DataCell(Text(
        '${isOut ? "-" : "+"}${h.quantity}',
        style: TextStyle(
            fontSize: 9.sp, fontWeight: FontWeight.w800, color: typeFg),
      )),
      DataCell(Text('${h.newStock}',
          style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black))),
      DataCell(SizedBox(
        width: 100.w,
        child: Text(
          h.reason,
          style: TextStyle(fontSize: 8.5.sp, color: const Color(0xFF666666)),
          overflow: TextOverflow.ellipsis,
        ),
      )),
      DataCell(Text(h.reference ?? '-',
          style: TextStyle(fontSize: 8.5.sp, color: const Color(0xFF444444)))),
    ]);
  }

  void _showAdjustStockDialog(String productName, int currentStock) {
    showDialog(
      context: context,
      builder: (ctx) => _AdjustStockDialog(
        productName: productName,
        currentStock: currentStock,
        onSuccess: _fetchData,
      ),
    );
  }

  void _showProductDetailsDialog(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductDetailsDialog(product: p),
    );
  }
}

// ─── Minimal Action Button for Card ──────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 18.sp, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Details Dialog ──────────────────────────────────────────────────

class _ProductDetailsDialog extends StatelessWidget {
  final Product product;
  const _ProductDetailsDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    final image =
        (product.productImages != null && product.productImages!.isNotEmpty)
            ? product.productImages!.first
            : '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320.w,
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Product Details',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                clipBehavior: Clip.antiAlias,
                child: image.isNotEmpty
                    ? Image.network(image, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
            SizedBox(height: 16.h),
            _infoRow('Product Name', product.productName ?? 'N/A'),
            _infoRow('Category', product.category ?? 'Uncategorized'),
            _infoRow('Price', '₹${product.price ?? 0}'),
            _infoRow(
                'Sale Price', '₹${product.salePrice ?? product.price ?? 0}'),
            _infoRow('Available Stock', '${product.stock ?? 0} units'),
            _infoRow(
                'Size', '${product.size ?? "N/A"} ${product.sizeMetric ?? ""}'),
            _infoRow('Brand', product.brand ?? 'N/A'),
            SizedBox(height: 12.h),
            Text('Description',
                style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700])),
            SizedBox(height: 4.h),
            Text(product.description ?? 'No description available',
                style: TextStyle(
                    fontSize: 10.sp, color: Colors.grey[600], height: 1.4)),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Back to Inventory'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90.w,
              child: Text(label,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87))),
        ],
      ),
    );
  }
}

// ─── Adjust Stock Dialog Widget ──────────────────────────────────────────────

class _AdjustStockDialog extends StatefulWidget {
  final String productName;
  final int currentStock;
  final VoidCallback? onSuccess;

  const _AdjustStockDialog({
    required this.productName,
    required this.currentStock,
    this.onSuccess,
  });

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  String _selectedAction = 'Add Stock (+)';
  String _selectedReason = 'Select Reason';
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _refController = TextEditingController();

  final Color kBorder = const Color(0xFFE0E0E0);

  @override
  void dispose() {
    _qtyController.dispose();
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 22.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust Stock - ${widget.productName}',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Current Stock: ${widget.currentStock}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 16.sp, color: const Color(0xFF555555)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Action dropdown
              _buildLabel('Action'),
              _buildDropdown(
                value: _selectedAction,
                items: [
                  'Add Stock (+)',
                  'Remove Stock (-)',
                ],
                onChanged: (v) => setState(() => _selectedAction = v!),
              ),
              SizedBox(height: 13.h),

              // Quantity
              _buildLabel('Quantity'),
              _buildTextField(
                controller: _qtyController,
                hint: '1',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 13.h),

              // Reason dropdown
              _buildLabel('Reason'),
              _buildDropdown(
                value: _selectedReason,
                items: [
                  'Select Reason',
                  'New Purchase / Restock',
                  'Customer Return',
                  'Stock Correction (Audit Found)',
                  'Other'
                ],
                onChanged: (v) => setState(() => _selectedReason = v!),
              ),
              SizedBox(height: 13.h),

              // Reference
              _buildLabel('Reference (Optional)'),
              _buildTextField(
                controller: _refController,
                hint: 'Invoice #, Order ID, etc.',
              ),
              SizedBox(height: 18.h),

              // Buttons
              Row(
                children: [
                  Expanded(child: _buildCancelButton()),
                  SizedBox(width: 10.w),
                  Expanded(child: _buildSaveButton()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon:
              Icon(Icons.keyboard_arrow_down, size: 18.sp, color: Colors.black),
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.black,
            fontFamily: 'DM Sans',
          ),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: TextStyle(fontSize: 11.sp, color: Colors.black)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 11.sp, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11.sp, color: const Color(0xFFAAAAAA)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: const Color(0xFFDCDCDC)),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        backgroundColor: Colors.white,
      ),
      child: Text(
        'Cancel',
        style: TextStyle(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        // Mock adjustment logic (until we have an API endpoint)
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock level updated successfully!')),
        );
        if (widget.onSuccess != null) widget.onSuccess!();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D2E3B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        'Save Adjustment',
        style: TextStyle(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Adjust Button with hover state ───────────────────────────────────────────

class _AdjustButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AdjustButton({required this.onTap});

  @override
  State<_AdjustButton> createState() => _AdjustButtonState();
}

class _AdjustButtonState extends State<_AdjustButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF3F4F6) : Colors.white,
            border: Border.all(
              color:
                  _hovered ? const Color(0xFFBEBEBE) : const Color(0xFFDCDCDC),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            'Adjust Stock',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
