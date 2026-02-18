import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';

class DiscountSummary extends StatefulWidget {
  const DiscountSummary({super.key});

  @override
  State<DiscountSummary> createState() => _DiscountSummaryState();
}

class _DiscountSummaryState extends State<DiscountSummary> {
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> discountSummary = [
    {
      'itemsDiscounted': 10,
      'itemsValue': 5000.0,
      'discountAmount': 750.0,
      'date': DateTime(2025, 7, 24),
    },
    {
      'itemsDiscounted': 5,
      'itemsValue': 3000.0,
      'discountAmount': 450.0,
      'date': DateTime(2025, 7, 20),
    },
    {
      'itemsDiscounted': 8,
      'itemsValue': 4000.0,
      'discountAmount': 600.0,
      'date': DateTime(2025, 7, 22),
    },
  ];

  List<Map<String, dynamic>> filteredData = [];

  @override
  void initState() {
    super.initState();
    filteredData = List.from(discountSummary);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterData();
      });
    }
  }

  void _filterData() {
    setState(() {
      filteredData = discountSummary.where((item) {
        final matchesDate = _selectedDateRange == null ||
            (item['date'].isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                item['date'].isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        return matchesDate;
      }).toList();
    });
  }

  String _currencyFormat(num value) {
    return '₹${NumberFormat('#,##0.00').format(value)}';
  }

  @override
  Widget build(BuildContext context) {

    double totalValue = filteredData.fold(0.0, (sum, item) => sum + (item['itemsValue'] as double));
    double totalDiscount = filteredData.fold(0.0, (sum, item) => sum + (item['discountAmount'] as double));
    int totalItems = filteredData.fold(0, (sum, item) => sum + (item['itemsDiscounted'] as int));


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 50.h,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Discount Summary',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
              child: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.w),
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/profile.jpeg'),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "View Summary of Tax Breakdown",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 20),
                  label: Text(
                    _selectedDateRange != null
                        ? "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}"
                        : "Pick Range",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black54),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.file_download_outlined, color: Colors.black),
                      items: const [
                        DropdownMenuItem(value: 'csv', child: Text('CSV')),
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                        DropdownMenuItem(value: 'copy', child: Text('Copy')),
                        DropdownMenuItem(value: 'excel', child: Text('Excel')),
                        DropdownMenuItem(value: 'print', child: Text('Print')),
                      ],
                      hint: const Text("Export"),
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Selected: $value")),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Table
// Table
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(3),
                      },
                      children: [
                        // Header Row
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade200),
                          children: [
                            _buildTableHeaderCell("Items Discounted"),
                            _buildTableHeaderCell("Items Value"),
                            _buildTableHeaderCell("Discount Amount"),
                          ],
                        ),
                        // Data Rows
                        ...filteredData.map((item) {
                          return TableRow(
                            decoration: const BoxDecoration(color: Colors.white),
                            children: [
                              _buildTableDataCell(item['itemsDiscounted'].toString()),
                              _buildTableDataCell(_currencyFormat(item['itemsValue'])),
                              _buildTableDataCell(_currencyFormat(item['discountAmount'])),
                            ],
                          );
                        }).toList(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Vertical Total Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      color: Colors.yellow.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTotalRow("Total Items Discounted", totalItems.toString()),
                            const SizedBox(height: 8),
                            _buildTotalRow("Total Items Value", _currencyFormat(totalValue)),
                            const SizedBox(height: 8),
                            _buildTotalRow("Total Discount Amount", _currencyFormat(totalDiscount)),
                          ],
                        ),
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
}
Widget _buildTableHeaderCell(String text) {
  return Padding(
    padding: EdgeInsets.all(12.w),
    child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12.sp)),
  );
}

Widget _buildTableDataCell(String text) {
  return Padding(
    padding: EdgeInsets.all(12.w),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 12.sp)),
  );
}

Widget _buildTableTotalCell(String text) {
  return Padding(
    padding: EdgeInsets.all(12.w),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
  );
}
Widget _buildTotalRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13.sp)),
      Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.sp)),
    ],
  );
}
