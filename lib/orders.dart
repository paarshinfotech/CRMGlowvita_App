import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'widgets/custom_drawer.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> orders = [
    {
      'orderId': '#ORD123',
      'customerId': '#CUST101',
      'numProducts': 3,
      'totalAmount': 1200,
      'paymentMode': 'Online',
      'orderDate': '2025-07-23',
      'status': 'Delivered',
    },
    {
      'orderId': '#ORD124',
      'customerId': '#CUST102',
      'numProducts': 2,
      'totalAmount': 700,
      'paymentMode': 'Cash',
      'orderDate': '2025-07-22',
      'status': 'Pending',
    },
    {
      'orderId': '#ORD125',
      'customerId': '#CUST103',
      'numProducts': 5,
      'totalAmount': 2500,
      'paymentMode': 'UPI',
      'orderDate': '2025-07-21',
      'status': 'Cancelled',
    },
    {
      'orderId': '#ORD126',
      'customerId': '#CUST104',
      'numProducts': 1,
      'totalAmount': 300,
      'paymentMode': 'Card',
      'orderDate': '2025-07-20',
      'status': 'Delivered',
    },
  ];

  late TabController _tabController;
  String _searchQuery = '';
  String _selectedStatus = 'All Statuses';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green.shade100;
      case 'Pending':
        return Colors.orange.shade100;
      case 'Cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd-MM-yyyy').format(date);
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order['orderId'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['customerId'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == 'All Statuses' ||
          order['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get deliveredCount => orders.where((o) => o['status'] == 'Delivered').length;
  int get pendingCount => orders.where((o) => o['status'] == 'Pending').length;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Orders'),
      appBar: AppBar(
        title: Text(
          "Orders", 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header + Stats
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders Management',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track and manage all your orders in one place',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusPill('✓ $deliveredCount Delivered', Colors.green),
                      _buildStatusPill('⏱ $pendingCount Pending', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade700,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('Customer Orders', style: TextStyle(fontSize: 11.sp)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('My Purchases', style: TextStyle(fontSize: 11.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search + Filter
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.w : 20.w, vertical: 12.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search orders, products...',
                            hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20.sp),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          ),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            icon: Icon(Icons.expand_more, size: 16.sp, color: Colors.grey.shade700),
                            iconSize: 16.sp,
                            elevation: 16,
                            style: TextStyle(color: Colors.black, fontSize: 11.sp),
                            underline: Container(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue!;
                              });
                            },
                            items: <String>[
                              'All Statuses',
                              'Pending',
                              'Processing',
                              'Packed',
                              'Shipped',
                              'Delivered',
                              'Cancelled',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: TextStyle(fontSize: 11.sp)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Customer Orders Tab
                  _buildOrdersList(isMobile),
                  // My Purchases Tab (empty for now)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 48.sp, color: Colors.grey.shade400),
                        SizedBox(height: 12.h),
                        Text(
                          'No purchases yet',
                          style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ],
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

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOrdersList(bool isMobile) {
    return filteredOrders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined, size: 36.sp, color: Colors.grey.shade400),
                ),
                SizedBox(height: 12.h),
                Text(
                  'No orders found',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Try adjusting your search or filter criteria.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Color(0xFFF5F5F5)),
              columnSpacing: 16,
              dataRowMinHeight: 48,
              headingRowHeight: 40,
              columns: const [
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Products')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
              ],
              rows: filteredOrders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(Text(order['orderId'], style: TextStyle(fontSize: 11.sp))),
                    DataCell(Text(order['customerId'], style: TextStyle(fontSize: 11.sp))),
                    DataCell(Text('${order['numProducts']} items', style: TextStyle(fontSize: 11.sp))),
                    DataCell(Text('₹${order['totalAmount']}', style: TextStyle(fontSize: 11.sp))),
                    DataCell(Text(order['paymentMode'], style: TextStyle(fontSize: 11.sp))),
                    DataCell(Text(_formatDate(order['orderDate']), style: TextStyle(fontSize: 11.sp))),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(order['status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order['status'],
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(order['status']),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
  }



}