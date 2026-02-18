import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/custom_drawer.dart';

class SettlementsPage extends StatefulWidget {
  const SettlementsPage({super.key});

  @override
  State<SettlementsPage> createState() => _SettlementsPageState();
}

class _SettlementsPageState extends State<SettlementsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  String _selectedStatus = 'All Status';
  String _selectedTime = 'All Time';

  final List<Map<String, dynamic>> _settlements = [
    {
      'id': 'SETTLEMENT_5...',
      'vendor': 'GlowVita Salon & Spa',
      'email': 'N/A',
      'phone': 'N/A',
      'totalAmount': 5658.00,
      'direction': 'Vendor -> Admin',
      'amount': 1102.00,
      'status': 'Partially Paid',
    },
    // Add more mock data if needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const CustomDrawer(currentPage: 'Settlements'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Settlements',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor Settlements',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Track settlements for Pay Online and Pay at Salon appointments',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16.h),

                // Summary Cards
                LayoutBuilder(builder: (context, constraints) {
                  return Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    children: [
                      _buildSummaryCard(
                        title: 'Total Amount',
                        value: '₹5658.00',
                        subtitle: '1 settlements',
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 48.w) / 4
                            : (constraints.maxWidth - 16.w) / 2,
                      ),
                      _buildSummaryCard(
                        title: 'Admin Owes Vendors',
                        value: '₹0.00',
                        subtitle: 'Pay Online service amounts',
                        valueColor: Colors.red[700],
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 48.w) / 4
                            : (constraints.maxWidth - 16.w) / 2,
                      ),
                      _buildSummaryCard(
                        title: 'Vendors Owe Admin',
                        value: '₹1102.00',
                        subtitle: 'Pay at Salon fees',
                        valueColor: Colors.green[700],
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 48.w) / 4
                            : (constraints.maxWidth - 16.w) / 2,
                      ),
                      _buildSummaryCard(
                        title: 'Net Settlement',
                        value: '+ ₹1102.00',
                        subtitle: 'Vendors owe admin',
                        valueColor: Colors.green[700],
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 48.w) / 4
                            : (constraints.maxWidth - 16.w) / 2,
                      ),
                    ],
                  );
                }),

                SizedBox(height: 24.h),

                // Filter Bar
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search by vendor or owner name...',
                            hintStyle: GoogleFonts.poppins(fontSize: 10.sp),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      _buildDropdown(
                        value: _selectedTime,
                        items: ['All Time', 'This Month', 'Last Month'],
                        onChanged: (v) => setState(() => _selectedTime = v!),
                      ),
                      SizedBox(width: 8.w),
                      _buildDropdown(
                        value: _selectedStatus,
                        items: [
                          'All Status',
                          'Paid',
                          'Pending',
                          'Partially Paid'
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Table Header
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell('ID', 100.w),
                      _buildHeaderCell('Vendor Details', 250.w),
                      _buildHeaderCell('Total Amount', 150.w),
                      _buildHeaderCell('Settlement Direction', 180.w),
                      _buildHeaderCell('Amount', 120.w),
                      _buildHeaderCell('Status', 120.w),
                      _buildHeaderCell('Actions', 200.w),
                    ],
                  ),
                ),

                // Table Body
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _settlements.length,
                  itemBuilder: (context, index) {
                    final s = _settlements[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[100]!)),
                      ),
                      child: Row(
                        children: [
                          _buildBodyCell(s['id'], 100.w),
                          SizedBox(
                            width: 250.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['vendor'],
                                    style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600)),
                                Text(s['email'],
                                    style: GoogleFonts.poppins(
                                        fontSize: 9.sp,
                                        color: Colors.grey[500])),
                                Text(s['phone'],
                                    style: GoogleFonts.poppins(
                                        fontSize: 9.sp,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          _buildBodyCell('₹${s['totalAmount']}', 150.w),
                          SizedBox(
                            width: 180.w,
                            child: Text(
                              s['direction'],
                              style: GoogleFonts.poppins(
                                  fontSize: 9.sp, color: Colors.green[700]),
                            ),
                          ),
                          _buildBodyCell('₹${s['amount']}', 120.w,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold),
                          SizedBox(
                            width: 120.w,
                            child: _buildStatusPill(s['status']),
                          ),
                          SizedBox(
                            width: 200.w,
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _showDetailsDialog(context, s),
                                  child: Text('View Details',
                                      style: GoogleFonts.poppins(
                                          fontSize: 9.sp,
                                          color: Colors.grey[700])),
                                ),
                                SizedBox(width: 8.w),
                                ElevatedButton(
                                  onPressed: () =>
                                      _showRecordPaymentDialog(context, s),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF372935),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 8.h),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.r)),
                                  ),
                                  child: Text('Collect Payment',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required double width,
    Color? valueColor,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  GoogleFonts.poppins(fontSize: 9.sp, color: Colors.grey[600])),
          SizedBox(height: 8.h),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF111827),
              )),
          SizedBox(height: 4.h),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 10.sp, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.poppins(fontSize: 9.sp))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildBodyCell(String label, double width,
      {Color? color, FontWeight? fontWeight}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          color: color ?? const Color(0xFF374151),
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = Colors.grey[100]!;
    Color text = Colors.grey[700]!;

    if (status == 'Partially Paid') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    } else if (status == 'Paid') {
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF059669);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
            fontSize: 10.sp, fontWeight: FontWeight.w600, color: text),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Send Payment to Admin',
                    style: GoogleFonts.poppins(
                        fontSize: 16.sp, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text('Record payment received from ${s['vendor']}',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, color: Colors.grey[600])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Amount'),
            TextFormField(
              initialValue: '502',
              decoration: _inputDecoration(),
            ),
            SizedBox(height: 4.h),
            Text('Pending: ₹502.00',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp, color: Colors.grey[500])),
            SizedBox(height: 16.h),
            _buildFieldLabel('Payment Method'),
            DropdownButtonFormField<String>(
              value: 'Bank Transfer',
              items: ['Bank Transfer', 'Cash', 'UPI']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {},
              decoration: _inputDecoration(),
            ),
            SizedBox(height: 16.h),
            _buildFieldLabel('Transaction ID (Optional)'),
            TextFormField(
              decoration: _inputDecoration(hintText: 'Enter transaction ID'),
            ),
            SizedBox(height: 16.h),
            _buildFieldLabel('Notes (Optional)'),
            TextFormField(
              maxLines: 3,
              decoration: _inputDecoration(hintText: 'Add any notes...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF372935),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text('Record Payment',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Container(
          width: 700.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settlement Details',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      Text('Detailed breakdown of vendor settlement',
                          style: GoogleFonts.poppins(
                              fontSize: 10.sp, color: Colors.grey[600])),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('Vendor Name', s['vendor'], flex: 2),
                  _buildDetailItem('Owner Name', 'N/A', flex: 2),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('Contact', 'N/A', flex: 2),
                  _buildDetailItem('Settlement ID',
                      'SETTLEMENT_696a30e6a8e33e1bf1a2d787_1577836800000',
                      flex: 2),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Wrap(
                  spacing: 40.w,
                  runSpacing: 20.h,
                  children: [
                    _buildMetric('Total Amount', '₹5658.00', Colors.black),
                    _buildMetric(
                        'Platform Fee', '₹499.00', Colors.orange[800]!),
                    _buildMetric('Service Tax', '₹603.00', Colors.orange[800]!),
                    _buildMetric(
                        'Admin Receivable', '₹1102.00', Colors.green[700]!),
                    _buildMetric('Vendor Amount', '₹0.00', Colors.blue[700]!),
                    _buildMetric('Pending Amount', '₹502.00', Colors.red[700]!),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text('Included Appointments (9)',
                  style: GoogleFonts.poppins(
                      fontSize: 14.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              Container(
                constraints: BoxConstraints(maxHeight: 300.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20.w,
                    headingRowHeight: 40.h,
                    dataRowHeight: 45.h,
                    columns: [
                      _buildDataColumn('Date'),
                      _buildDataColumn('Client'),
                      _buildDataColumn('Service'),
                      _buildDataColumn('Amount'),
                      _buildDataColumn('Platform Fee'),
                      _buildDataColumn('Tax'),
                    ],
                    rows: List.generate(
                        5,
                        (index) => DataRow(cells: [
                              DataCell(Text('3/9/2026',
                                  style: TextStyle(fontSize: 9.sp))),
                              DataCell(Text('Pratiksha Aher',
                                  style: TextStyle(fontSize: 9.sp))),
                              DataCell(Text('Moonlight Silver Colored Lashes',
                                  style: TextStyle(fontSize: 9.sp))),
                              DataCell(Text('₹597.00',
                                  style: TextStyle(fontSize: 9.sp))),
                              DataCell(Text('₹67.00',
                                  style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.orange[800]))),
                              DataCell(Text('₹81.00',
                                  style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.orange[800]))),
                            ])),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10.sp, fontWeight: FontWeight.w500)),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!)),
    );
  }

  Widget _buildDetailItem(String label, String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 9.sp, color: Colors.grey[500])),
          SizedBox(height: 2.h),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return SizedBox(
      width: 130.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10.sp, color: Colors.grey[500])),
          SizedBox(height: 4.h),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
        label: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600])));
  }
}
