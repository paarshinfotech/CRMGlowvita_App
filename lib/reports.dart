import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'my_Profile.dart';
import 'Notification.dart';
import 'vendor_model.dart';
import 'services/api_service.dart';
import 'Vendor reports/sales_by_service.dart';
import 'Vendor reports/sales_by_customer.dart';
import 'Vendor reports/sales_by_product.dart';
import 'Vendor reports/staff_commission_summary.dart';
import 'Vendor reports/settlement_summary.dart';
import 'Vendor reports/allAppointments_summary.dart';
import 'Vendor reports/appointmentsbystaff_summary.dart';
import 'Vendor reports/appointmentsbyservice_summary.dart';
import 'Vendor reports/appointmentsCancellation_summary.dart';
import 'Vendor reports/completedAppointments_summary.dart';
import 'Vendor reports/all_products_report.dart';
import 'Vendor reports/inventory_stock_report.dart';
import 'Vendor reports/category_wise_product_report.dart';

const Color _primaryDark = Color(0xFF372935);

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  VendorProfile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Reports'),
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
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const My_Profile()),
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: ClipOval(
                  child: (_profile != null && _profile!.profileImage.isNotEmpty)
                      ? Image.network(
                          _profile!.profileImage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => _buildInitialAvatar(),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Row(
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
                            'Generate and download detailed reports for various components of the platform.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWide) ...[
                      SizedBox(width: 32.w),
                      SizedBox(width: 240.w, child: _buildSearchBar()),
                    ],
                  ],
                );
              },
            ),
            if (MediaQuery.of(context).size.width <= 800) ...[
              SizedBox(height: 12.h),
              _buildSearchBar(),
            ],
            SizedBox(height: 32.h),

            // Appointment Summary Section
            _buildSectionHeader('Appointment Summary'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'All Appointments Report',
                icon: Icons.assignment_outlined,
                iconColor: Colors.blue,
                description:
                    'Complete record of all appointments with detailed information.',
                details: [
                  'Client Name, Service Type, Staff Member',
                  'Date & Time, Duration, Amount',
                  'Status, Payment Status',
                  'Booking Type, Notes',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllAppointmentsSummary(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Appointment Summary by Service',
                icon: Icons.settings_outlined,
                iconColor: Colors.purple,
                description:
                    'Aggregated view showing appointment counts, revenue, and popularity by service type.',
                details: [
                  'Service Name, Total Appointments',
                  'Revenue Generated, Average Duration',
                  'Distribution %, Completion Rate',
                  'Staff Performance Metrics',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentsbyServicesSummary(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Completed Appointments Report',
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                description:
                    'Detailed listing of all successfully completed appointments.',
                details: [
                  'Client Name, Service, Staff Member',
                  'Completion Date & Time, Duration',
                  'Amount Charged, Payment Method',
                  'Rating/Review, Booking Type',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompletedAppointmentsSummary(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Cancelled Appointments Report',
                icon: Icons.cancel_outlined,
                iconColor: Colors.red,
                description:
                    'Comprehensive analysis of cancelled appointments with reasons and impact.',
                details: [
                  'Client Name, Service, Staff Member',
                  'Cancellation Date & Time, Reason',
                  'Refund Status, Revenue Impact',
                  'Status, Booking Type',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentsCancellationSummary(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'All Appointments by Staff',
                icon: Icons.people_outline,
                iconColor: Colors.teal,
                description:
                    'Detailed report showing appointment statistics aggregated by staff member.',
                details: [
                  'Staff Name, Total Appointments',
                  'Total Duration, Average Duration',
                  'Total Sales, Average Sale',
                  'Performance Metrics',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentsbyStaffSummary(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Staff Commission Summary',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.indigo,
                description: 'Overview of commissions earned by staff members.',
                details: [
                  'Staff Name',
                  'Total Sales',
                  'Commission Rate',
                  'Earned Amount',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffCommissionSummary(),
                  ),
                ),
                onDownload: () {},
              ),
            ]),

            SizedBox(height: 32.h),

            // Settlement Summary Section
            _buildSectionHeader('Settlement Summary'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'Settlement Summary Report',
                icon: Icons.account_balance_outlined,
                iconColor: Colors.deepPurple,
                description:
                    'Overview of fund settlements between vendors and the platform.',
                details: [
                  'Settlement ID',
                  'Vendor Name',
                  'Transfer Amount',
                  'Status',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettlementSummary()),
                ),
                onDownload: () {},
              ),
            ]),

            SizedBox(height: 32.h),

            // Sales Summary
            _buildSectionHeader('Sales Summary'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'Sales by Service',
                icon: Icons.bar_chart_outlined,
                iconColor: Colors.blueAccent,
                description:
                    'Detailed revenue breakdown generated by each service offering.',
                details: [
                  'Service Category',
                  'Gross Revenue',
                  'Net Sales',
                  'Volume',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesByService()),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Sales by Customer',
                icon: Icons.person_search_outlined,
                iconColor: Colors.cyan,
                description:
                    'Revenue breakdown by customer to identify high-value clients.',
                details: [
                  'Customer Name',
                  'Total Spend',
                  'Visit Frequency',
                  'Last Visit',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesByCustomer()),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Sales by Product',
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.pink,
                description:
                    'Detailed record of revenue generated by individual products.',
                details: [
                  'Product Name',
                  'Quantity Sold',
                  'Net Revenue',
                  'Stock Remaining',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesByProduct(),
                  ),
                ),
                onDownload: () {},
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
                    'Complete record of all products with detailed information.',
                details: [
                  'Product Name, Brand, Category',
                  'Price, Sale Price, Stock',
                  'Status, Is Active, Created Date',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllProductsReport(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Inventory / Stock Report',
                icon: Icons.warehouse_outlined,
                iconColor: Colors.brown,
                description:
                    'Detailed analysis of product inventory and stock levels.',
                details: ['Product Name', 'Stock Available', 'Stock Status'],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryStockReport(),
                  ),
                ),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Category-wise Product Report',
                icon: Icons.category_outlined,
                iconColor: Colors.orange,
                description:
                    'Aggregated view showing product counts and sales by category.',
                details: [
                  'Category Name',
                  'Number of Products, Active Products',
                  'Average Price, Average Sale Price',
                ],
                onView: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryWiseProductReport(),
                  ),
                ),
                onDownload: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: _border),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          Icon(Icons.search, color: _muted, size: 15),
          SizedBox(width: 6.w),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search reports...',
                hintStyle: GoogleFonts.poppins(fontSize: 11.sp, color: _muted),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.poppins(fontSize: 11.sp),
            ),
          ),
        ],
      ),
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

  /// 1 card per row — list layout
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
