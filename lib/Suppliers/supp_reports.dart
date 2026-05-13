import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'supp_drawer.dart';
import 'Supplier reports/sales_by_product_report.dart';
import 'Supplier reports/all_products_report.dart';
import 'Supplier reports/inventory_stock_report.dart';
import 'Supplier reports/category_wise_product_report.dart';
import '../services/api_service.dart';
import '../utils/export_helper.dart';
import 'supp_profile.dart';
import 'supp_notifications.dart';
import '../supplier_model.dart';

class SuppReportsPage extends StatefulWidget {
  const SuppReportsPage({super.key});

  @override
  State<SuppReportsPage> createState() => _SuppReportsPageState();
}

class _SuppReportsPageState extends State<SuppReportsPage> {
  static const Color _muted = Color(0xFF64748B);

  bool _isDownloading = false;
  SupplierProfile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getSupplierProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.shopName ?? 'S').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _downloadReport(String type) async {
    setState(() => _isDownloading = true);
    try {
      if (type == 'sales') {
        final res = await ApiService.getSalesByProductReport();
        final data =
            (res['data']?['salesByProduct'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        if (data.isEmpty) throw 'No data available';
        await ExportHelper.executeExport(
          'excel',
          fileName: 'Sales_Report',
          title: 'Sales by Product Report',
          headers: [
            'Product',
            'Brand',
            'Category',
            'Quantity Sold',
            'Gross',
            'Net',
            'Tax',
            'Total',
          ],
          rows: data
              .map(
                (r) => [
                  r['productName'] ?? '—',
                  r['brand'] ?? '—',
                  r['category'] ?? '—',
                  r['quantitySold'] ?? 0,
                  r['grossSale'] ?? 0,
                  r['netSale'] ?? 0,
                  r['tax'] ?? 0,
                  r['totalSales'] ?? 0,
                ],
              )
              .toList(),
        );
      } else if (type == 'products') {
        final res = await ApiService.getProductSummaryReport();
        final data =
            (res['data']?['products'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
        if (data.isEmpty) throw 'No data available';
        await ExportHelper.executeExport(
          'excel',
          fileName: 'All_Products_Report',
          title: 'All Products Report',
          headers: [
            'Product',
            'Brand',
            'Category',
            'Price',
            'Sale Price',
            'Stock',
            'Status',
          ],
          rows: data
              .map(
                (r) => [
                  r['productName'] ?? '—',
                  r['brand'] ?? '—',
                  r['category'] ?? '—',
                  r['price'] ?? 0,
                  r['salePrice'] ?? 0,
                  r['stock'] ?? 0,
                  r['status'] ?? '—',
                ],
              )
              .toList(),
        );
      } else if (type == 'inventory') {
        final res = await ApiService.getInventoryStockReport();
        final data =
            (res['data']?['products'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
        if (data.isEmpty) throw 'No data available';
        await ExportHelper.executeExport(
          'excel',
          fileName: 'Inventory_Report',
          title: 'Inventory / Stock Report',
          headers: ['Product', 'Stock', 'Status'],
          rows: data
              .map(
                (r) => [
                  r['productName'] ?? '—',
                  r['stockAvailable'] ?? 0,
                  r['stockStatus'] ?? '—',
                ],
              )
              .toList(),
        );
      } else if (type == 'category') {
        final res = await ApiService.getCategoryWiseProductReport();
        final data =
            (res['data']?['categories'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        if (data.isEmpty) throw 'No data available';
        await ExportHelper.executeExport(
          'excel',
          fileName: 'Category_Report',
          title: 'Category-wise Product Report',
          headers: [
            'Category',
            'Products',
            'Active',
            'Avg Price',
            'Avg Sale Price',
          ],
          rows: data
              .map(
                (r) => [
                  r['categoryName'] ?? '—',
                  r['numberOfProducts'] ?? 0,
                  r['activeProducts'] ?? 0,
                  r['averagePrice'] ?? 0,
                  r['averageSalePrice'] ?? 0,
                ],
              )
              .toList(),
        );
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report downloaded successfully')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Stack(
      children: [
        Scaffold(
          drawer: const SupplierDrawer(currentPage: 'Reports'),
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              'Reports',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuppNotificationsPage(),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SuppProfilePage()),
                ),
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: ClipOval(
                      child:
                          (_profile != null &&
                              _profile!.profileImage.isNotEmpty)
                          ? Image.network(
                              _profile!.profileImage,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) =>
                                  _buildInitialAvatar(),
                              loadingBuilder: (ctx, child, progress) =>
                                  progress == null
                                  ? child
                                  : const CircularProgressIndicator(),
                            )
                          : _buildInitialAvatar(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Generate and download detailed reports for your supply business.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Sales Summary
                _buildSectionHeader('Sales Summary'),
                SizedBox(height: 16.h),
                _buildTwoColumnGrid(context, [
                  _ReportCard(
                    title: 'Sales by Product',
                    icon: Icons.shopping_bag_outlined,
                    iconColor: Colors.pink,
                    description:
                        'Detailed report showing revenue generated by each product, specifically for delivered products only.',
                    details: [
                      'Product Name, Brand, Category, Quantity Sold',
                      'Gross Sales, Discount, Net Sales',
                      'Tax Amount, Total Sales, Average Price',
                      'COGS, Gross Profit, Margin %',
                    ],
                    onView: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesByProductReport(),
                      ),
                    ),
                    onDownload: () => _downloadReport('sales'),
                  ),
                ]),

                SizedBox(height: 32.h),

                // Products Summary
                _buildSectionHeader('Products Summary'),
                SizedBox(height: 16.h),
                _buildTwoColumnGrid(context, [
                  _ReportCard(
                    title: 'All Products Report',
                    icon: Icons.inventory_2_outlined,
                    iconColor: Colors.blueGrey,
                    description:
                        'A complete record of all products currently in the system with detailed identifying information.',
                    details: [
                      'Product Name, Category, Brand',
                      'Price, Sale Price',
                      'Stock Quantity, Status',
                      'Created Date, Active Status',
                    ],
                    onView: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllProductsReport(),
                      ),
                    ),
                    onDownload: () => _downloadReport('products'),
                  ),
                  _ReportCard(
                    title: 'Inventory / Stock Report',
                    icon: Icons.warehouse_outlined,
                    iconColor: Colors.brown,
                    description:
                        'A detailed analysis of current product inventory levels and stock health.',
                    details: [
                      'Product Name, Category, Brand',
                      'Current Stock, Low Stock Alert',
                      'Stock Value, Reorder Level',
                      'Last Updated Date',
                    ],
                    onView: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryStockReport(),
                      ),
                    ),
                    onDownload: () => _downloadReport('inventory'),
                  ),
                  _ReportCard(
                    title: 'Category-wise Product Report',
                    icon: Icons.category_outlined,
                    iconColor: Colors.orange,
                    description:
                        'An aggregated view that provides insights into product counts and sales performance categorized by group.',
                    details: [
                      'Category Name, Total Products',
                      'Average Price, Total Stock Value',
                      'Total Stock Quantity',
                      'Sales Performance Metrics',
                    ],
                    onView: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryWiseProductReport(),
                      ),
                    ),
                    onDownload: () => _downloadReport('category'),
                  ),
                ]),
              ],
            ),
          ),
        ),
        if (_isDownloading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildTwoColumnGrid(BuildContext context, List<Widget> children) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, __) => SizedBox(height: 7.h),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> details;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final IconData icon;
  final Color iconColor;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.details,
    required this.onView,
    required this.onDownload,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 14.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 8.sp,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          SizedBox(height: 10.h),
          ...details.map(
            (d) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 5.h, right: 8.w, left: 10.w),
                    child: Container(
                      width: 2.5.w,
                      height: 2.5.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      d,
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B2D3D),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View',
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
