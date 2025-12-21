import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import './supp_drawer.dart';

class SuppOrdersPage extends StatefulWidget {
  const SuppOrdersPage({super.key});
  @override
  State<SuppOrdersPage> createState() => _SuppOrdersPageState();
}

class _SuppOrdersPageState extends State<SuppOrdersPage> with SingleTickerProviderStateMixin {
  // Supplier-focused sample orders (orders received for their products)
  final List<Map<String, dynamic>> orders = [
    {
      'orderId': '#ORD501',
      'customerName': 'Priya Sharma',
      'numProducts': 2,
      'totalAmount': 1898,
      'paymentMode': 'Online (UPI)',
      'orderDate': '2025-12-20',
      'status': 'Delivered',
      'products': ['Hydrating Face Serum', 'Vitamin C Face Cream'],
    },
    {
      'orderId': '#ORD502',
      'customerName': 'Rahul Mehta',
      'numProducts': 1,
      'totalAmount': 1299,
      'paymentMode': 'Card',
      'orderDate': '2025-12-19',
      'status': 'Shipped',
      'products': ['Argan Oil Hair Mask'],
    },
    {
      'orderId': '#ORD503',
      'customerName': 'Anjali Patel',
      'numProducts': 3,
      'totalAmount': 2747,
      'paymentMode': 'Online',
      'orderDate': '2025-12-18',
      'status': 'Pending',
      'products': ['Luxury Body Butter', 'Matte Lipstick Set', 'Beard Growth Oil'],
    },
    {
      'orderId': '#ORD504',
      'customerName': 'Vikram Singh',
      'numProducts': 1,
      'totalAmount': 799,
      'paymentMode': 'Cash on Delivery',
      'orderDate': '2025-12-17',
      'status': 'Processing',
      'products': ['Gel Nail Polish Kit'],
    },
    {
      'orderId': '#ORD505',
      'customerName': 'Sneha Reddy',
      'numProducts': 2,
      'totalAmount': 2198,
      'paymentMode': 'UPI',
      'orderDate': '2025-12-15',
      'status': 'Cancelled',
      'products': ['Professional Makeup Brush Set', 'Hydrating Face Serum'],
    },
    {
      'orderId': '#ORD506',
      'customerName': 'Amit Kumar',
      'numProducts': 1,
      'totalAmount': 649,
      'paymentMode': 'Online',
      'orderDate': '2025-12-14',
      'status': 'Delivered',
      'products': ['Beard Growth Oil'],
    },
  ];

  late TabController _tabController;
  String _searchQuery = '';
  String _selectedStatus = 'All Statuses';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Only one tab for supplier
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
      case 'Shipped':
        return Colors.blue;
      case 'Processing':
        return Colors.purple;
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
      case 'Shipped':
        return Colors.blue.shade100;
      case 'Processing':
        return Colors.purple.shade100;
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
    return DateFormat('dd MMM yyyy').format(date);
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order['orderId'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['customerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order['products'] as List).any((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesStatus = _selectedStatus == 'All Statuses' || order['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get deliveredCount => orders.where((o) => o['status'] == 'Delivered').length;
  int get pendingCount => orders.where((o) => o['status'] == 'Pending' || o['status'] == 'Processing').length;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Orders'),
      appBar: AppBar(
        title: Text(
          "Orders",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Header + Stats
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Incoming Orders',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage orders placed for your products',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          deliveredCount.toString(),
                          'Delivered',
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          pendingCount.toString(),
                          'Processing',
                          Icons.timelapse_outlined,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          orders.length.toString(),
                          'Total',
                          Icons.shopping_bag_outlined,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search + Filter
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10.w : 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by order ID, customer, or product...',
                          hintStyle: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 18.sp),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        ),
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: Icon(Icons.expand_more, size: 14.sp, color: Colors.grey.shade700),
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 10.sp),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                        items: <String>[
                          'All Statuses',
                          'Pending',
                          'Processing',
                          'Shipped',
                          'Delivered',
                          'Cancelled',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: GoogleFonts.poppins(fontSize: 10.sp)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.shopping_bag_outlined, size: 48.sp, color: Colors.grey.shade400),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No orders found',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Try adjusting your search or filter',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(height: 6.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['orderId'],
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _formatDate(order['orderDate']),
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(order['status']),
                    borderRadius: BorderRadius.circular(18),
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
              ],
            ),
          ),
          
          // Order details
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          order['customerName'][0],
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customerName'],
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${order['numProducts']} product${order['numProducts'] > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 14.h),
                
                // Products list
                Text(
                  'Products:',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 6.h),
                ...List.generate(
                  (order['products'] as List).length,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 5.sp, color: Colors.grey.shade400),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            (order['products'] as List)[i],
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 14.h),
                
                // Payment info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          order['paymentMode'],
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '₹${order['totalAmount']}',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}