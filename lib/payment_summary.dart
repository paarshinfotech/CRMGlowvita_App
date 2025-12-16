import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentSummary extends StatefulWidget {
  @override
  State<PaymentSummary> createState() => _PaymentSummaryState();
}

class _PaymentSummaryState extends State<PaymentSummary> {

  DateTimeRange? _selectedDateRange;
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

  }

  final List<Map<String, dynamic>> payments = [
    {
      'method': 'Cash',
      'transactions': 25,
      'gross': 4500,
      'net': 4450,
    },
    {
      'method': 'QR',
      'transactions': 30,
      'gross': 5200,
      'net': 5150,
    },
    {
      'method': 'Link',
      'transactions': 15,
      'gross': 2800,
      'net': 2750,
    },
  ];

  List<Map<String, dynamic>> filteredServices = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
  }

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
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
                'Payments Summary',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
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
            const SizedBox(height: 24),

            // Range Picker & Export Dropdown
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
                    side: BorderSide(color: Colors.black54),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

            // Data Table
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.grey.shade200),
                      columnSpacing: 24,
                      dataRowHeight: 60,
                      headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                      columns: const [
                        DataColumn(label: Text("Payment Method")),
                        DataColumn(label: Text("Transactions")),
                        DataColumn(label: Text("Gross Payments")),
                        DataColumn(label: Text("Net Payments")),
                      ],
                      rows: [
                        ...List.generate(payments.length, (index) {
                          final payment = payments[index];
                          final isEven = index % 2 == 0;
                          return DataRow(
                            color: MaterialStateColor.resolveWith(
                                  (states) => isEven ? Colors.grey.shade50 : Colors.white,
                            ),
                            cells: [
                              DataCell(Text(payment['method'])),
                              DataCell(Text(payment['transactions'].toString())),
                              DataCell(Text(_currencyFormat(payment['gross']))),
                              DataCell(Text(
                                _currencyFormat(payment['net']),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              )),
                            ],
                          );
                        }),

                        // Total row
                        DataRow(
                          color: MaterialStateColor.resolveWith((states) => Colors.yellow.shade50),
                          cells: [
                            const DataCell(Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              payments.fold<int>(0, (sum, item) => sum + item['transactions'] as int).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(
                                payments.fold<double>(0.0, (sum, item) => sum + (item['gross'] as num).toDouble()),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(
                                payments.fold<double>(0.0, (sum, item) => sum + (item['net'] as num).toDouble()),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
