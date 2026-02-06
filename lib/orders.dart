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

class _OrdersPageState extends State<OrdersPage> {
  final List<Map<String, dynamic>> orders = [
    {
      'orderId': '#ONLINE-12345',
      'customer': 'Online Customer',
      'items': 'Demo Product',
      'count': 1,
      'totalAmount': 357.12,
      'status': 'Delivered',
      'date': '2025-07-23',
    },
    {
      'orderId': '#ONLINE-12346',
      'customer': 'Rahul Sharma',
      'items': 'Face Wash, Serum',
      'count': 2,
      'totalAmount': 850.00,
      'status': 'Shipped',
      'date': '2025-07-24',
    },
    {
      'orderId': '#ONLINE-12347',
      'customer': 'Priya Patel',
      'items': 'Hair Oil',
      'count': 1,
      'totalAmount': 420.50,
      'status': 'Pending',
      'date': '2025-07-25',
    },
    {
      'orderId': '#ONLINE-12348',
      'customer': 'Amit Singh',
      'items': 'Massage Oil, Cream',
      'count': 2,
      'totalAmount': 1200.00,
      'status': 'Cancelled',
      'date': '2025-07-26',
    },
  ];

  String _searchQuery = '';
  String _selectedStatus = 'All Statuses';
  String _activeView = 'Orders';

  @override
  void initState() {
    super.initState();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Shipped':
        return Colors.blue;
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
      case 'Pending':
        return Colors.orange.shade100;
      case 'Cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order['orderId'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['customer'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == 'All Statuses' ||
          order['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Orders'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Orders",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Text(
                'Orders Management',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track and manage all your orders in one place.',
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
                children: [
                  _buildSummaryCard(
                    'Total Orders',
                    '${orders.length}',
                    'All orders',
                    Icons.inventory_2_outlined,
                    const Color(0xFFF3F4F6),
                    const Color(0xFF4B5563),
                  ),
                  _buildSummaryCard(
                    'Pending',
                    '${orders.where((o) => o['status'] == 'Pending').length}',
                    'Awaiting processing',
                    Icons.shopping_cart_outlined,
                    const Color(0xFFF3F4F6),
                    const Color(0xFF4B5563),
                  ),
                  _buildSummaryCard(
                    'Shipped',
                    '${orders.where((o) => o['status'] == 'Shipped').length}',
                    'In transit',
                    Icons.local_shipping_outlined,
                    const Color(0xFFF3F4F6),
                    const Color(0xFF4B5563),
                  ),
                  _buildSummaryCard(
                    'Delivered',
                    '${orders.where((o) => o['status'] == 'Delivered').length}',
                    'Successfully delivered',
                    Icons.check_circle_outline,
                    const Color(0xFFF3F4F6),
                    const Color(0xFF4B5563),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Control Row
              _buildControlRow(),
              const SizedBox(height: 20),

              // Order List (Cards)
              _buildOrdersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, String subtext,
      IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            subtext,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Bar
          
          SizedBox(
            width: isMobile ? double.infinity : 300.w,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search orders, products...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ),
          ),

          // Tabs / Toggles
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Orders', Icons.shopping_cart),
                _buildToggleButton('My Purchases', Icons.shopping_bag_outlined),
              ],
            ),
          ),

          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                items: [
                  'All Statuses',
                  'Pending',
                  'Shipped',
                  'Delivered',
                  'Cancelled'
                ]
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child:
                              Text(s, style: GoogleFonts.poppins(fontSize: 12)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
            ),
          ),

          // Export Button
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: Text('Export',
                style: GoogleFonts.poppins(
                    fontSize: 13.sp, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 48),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildToggleButton(String label, IconData icon) {
    bool isActive = _activeView == label;
    return GestureDetector(
      onTap: () => setState(() => _activeView = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final filtered = filteredOrders;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.shopping_basket_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No orders found',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => _showOrderDetailDialog(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['orderId'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order['customer'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['items'],
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  ' x${order['count']}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      order['date'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${order['totalAmount']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: 800.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Order ID: ${order['orderId']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Order Progress
                        _buildProgressTracker(order['status']),
                        const SizedBox(height: 24),

                        LayoutBuilder(builder: (context, constraints) {
                          bool isNarrow = constraints.maxWidth < 600;
                          return isNarrow
                              ? Column(
                                  children: [
                                    _buildSectionTitle('Items Ordered (1)',
                                        Icons.shopping_cart_outlined),
                                    const SizedBox(height: 12),
                                    _buildOrderItem(order),
                                    const SizedBox(height: 24),
                                    _buildTotalAmountSection(
                                        order['totalAmount']),
                                    const SizedBox(height: 32),
                                    _buildSideInfoCard(
                                        'Customer Details',
                                        Icons.person_outline,
                                        order['customer']),
                                    _buildSideInfoCard(
                                        'Shipping Address',
                                        Icons.location_on_outlined,
                                        'Nashik, Maharashtra'),
                                    _buildTrackingCard(),
                                    _buildTimelineCard(order['date']),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Main content (Left)
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionTitle(
                                              'Items Ordered (1)',
                                              Icons.shopping_cart_outlined),
                                          const SizedBox(height: 12),
                                          _buildOrderItem(order),
                                          const SizedBox(height: 24),
                                          _buildTotalAmountSection(
                                              order['totalAmount']),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Sidebar content (Right)
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          _buildSideInfoCard(
                                              'Customer Details',
                                              Icons.person_outline,
                                              order['customer']),
                                          _buildSideInfoCard(
                                              'Shipping Address',
                                              Icons.location_on_outlined,
                                              'Nashik, Maharashtra'),
                                          _buildTrackingCard(),
                                          _buildTimelineCard(order['date']),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTracker(String currentStatus) {
    final statuses = [
      'Pending',
      'Processing',
      'Packed',
      'Shipped',
      'Delivered'
    ];
    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex == -1 && currentStatus == 'Cancelled') currentIndex = -1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: Color(0xFF1F2937)),
              const SizedBox(width: 8),
              Text(
                'Order Progress',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(statuses.length, (index) {
              bool isDone = index <= currentIndex;
              bool isActive = index == currentIndex;

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            isDone
                                ? Icons.check
                                : _getStatusIcon(statuses[index]),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          statuses[index],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight:
                                isDone ? FontWeight.w600 : FontWeight.w500,
                            color: isDone
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (index != statuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: index < currentIndex
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Processing':
        return Icons.sync;
      case 'Packed':
        return Icons.inventory_2;
      case 'Shipped':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.home;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['items'],
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Qty: ${order['count']}  ₹${(order['totalAmount'] / (order['count'] == 0 ? 1 : order['count'])).toStringAsFixed(2)} each',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '₹${order['totalAmount']}',
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountSection(double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            '₹$amount',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideInfoCard(String title, IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('Tracking Details',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTrackingRow(
              Icons.account_balance_outlined, 'Courier', 'Not specified'),
          const SizedBox(height: 8),
          _buildTrackingRow(
              Icons.qr_code_scanner_outlined, 'Tracking Number', '12345'),
        ],
      ),
    );
  }

  Widget _buildTrackingRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 9, color: Colors.grey.shade600)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('Order Timeline',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Placed',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.grey.shade600)),
                    Text(date,
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w600)),
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
