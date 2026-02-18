import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../Notification.dart';
import '../Profile.dart';

class TaxesSummary extends StatefulWidget {
  const TaxesSummary({super.key});

  @override
  State<TaxesSummary> createState() => _TaxesSummaryState();
}

class _TaxesSummaryState extends State<TaxesSummary> {
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> taxesSummary = [
    {
      'tax': 'GST 18%',
      'itemsSold': 52,
      'rate': 18,
      'amount': 2700.0,
      'date': DateTime(2025, 7, 24),
    },
    {
      'tax': 'CGST 9%',
      'itemsSold': 30,
      'rate': 9,
      'amount': 900.0,
      'date': DateTime(2025, 7, 20),
    },
    {
      'tax': 'SGST 9%',
      'itemsSold': 30,
      'rate': 9,
      'amount': 900.0,
      'date': DateTime(2025, 7, 22),
    },
  ];

  List<Map<String, dynamic>> filteredTaxData = [];

  @override
  void initState() {
    super.initState();
    filteredTaxData = List.from(taxesSummary);
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
      filteredTaxData = taxesSummary.where((item) {
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
    double totalAmount = filteredTaxData.fold(
      0.0,
          (sum, item) => sum + (item['amount'] as num),
    );
    int totalItems = filteredTaxData.fold(
      0,
          (sum, item) => sum + (item['itemsSold'] as int),
    );

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
                'Tax Summary',
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

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    Table(
                      columnWidths: {
                        0: FlexColumnWidth(3), // Tax
                        1: FlexColumnWidth(2), // Item Sold
                        2: FlexColumnWidth(2), // Rate
                        3: FlexColumnWidth(3), // Amount
                      },
                      border: TableBorder.all(color: Colors.grey.shade300),
                      children: [
                        // Table Header
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade200),
                          children: [
                            _buildTableHeaderCell("Tax"),
                            _buildTableHeaderCell("Item Sold"),
                            _buildTableHeaderCell("Rate (%)"),
                            _buildTableHeaderCell("Amount"),
                          ],
                        ),

                        // Table Rows
                        ...filteredTaxData.map((item) {
                          return TableRow(
                            decoration: BoxDecoration(color: Colors.white),
                            children: [
                              _buildTableDataCell(item['tax']),
                              _buildTableDataCell(item['itemsSold'].toString()),
                              _buildTableDataCell(item['rate'].toString()),
                              _buildTableDataCell(_currencyFormat(item['amount'])),
                            ],
                          );
                        }).toList(),

                        // Total Summary Row
                        TableRow(
                          decoration: BoxDecoration(color: Colors.yellow.shade100),
                          children: [
                            _buildTableTotalCell("Total"),
                            _buildTableTotalCell(totalItems.toString()),
                            _buildTableTotalCell(""),
                            _buildTableTotalCell(_currencyFormat(totalAmount)),
                          ],
                        ),
                      ],
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
    child: Text(
      text,
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12.sp),
    ),
  );
}

Widget _buildTableDataCell(String text) {
  return Padding(
    padding: EdgeInsets.all(12.w),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 12.sp),
    ),
  );
}

Widget _buildTableTotalCell(String text) {
  return Padding(
    padding: EdgeInsets.all(12.w),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.sp),
    ),
  );
}
