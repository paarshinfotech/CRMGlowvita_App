// Import Statements
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesHistory extends StatefulWidget {
  @override
  State<SalesHistory> createState() => _SalesHistoryState();
}

class _SalesHistoryState extends State<SalesHistory> {
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> selesHistory = [
    {
      'invoice': '#00001265',
      'status': 'PENDING',
      'date': DateTime(2025, 7, 26, 12, 52),
      'customer': 'Siddhi Shinde',
      'qty': 2,
      'grossSale': 410,
      'discount': 0,
      'netSale': 410,
      'tax': 0,
      'totalSales': 410,
    },
    {
      'invoice': '#00001264',
      'status': 'PENDING',
      'date': DateTime(2025, 7, 26, 12, 48),
      'customer': 'Siddhi Shinde',
      'qty': 1,
      'grossSale': 310,
      'discount': 0,
      'netSale': 310,
      'tax': 0,
      'totalSales': 310,
    },
    {
      'invoice': '#00001263',
      'status': 'PAID',
      'date': DateTime(2025, 7, 26, 12, 48),
      'customer': 'Siddhi Shinde',
      'qty': 1,
      'grossSale': 310,
      'discount': 10,
      'netSale': 300,
      'tax': 10,
      'totalSales': 310,
    },
    {
      'invoice': '#00001262',
      'status': 'CANCELLED',
      'date': DateTime(2025, 7, 26, 12, 25),
      'customer': 'Siddhi Shinde',
      'qty': 1,
      'grossSale': 310,
      'discount': 0,
      'netSale': 310,
      'tax': 0,
      'totalSales': 310,
    },
  ];

  List<Map<String, dynamic>> filteredServices = [];
  String searchText = '';

  // Totals
  int totalQty = 0;
  double totalGrossSale = 0;
  double totalDiscount = 0;
  double totalNetSale = 0;
  double totalTax = 0;
  double totalSales = 0;

  @override
  void initState() {
    super.initState();
    filteredServices = List.from(selesHistory);
    _calculateTotals();
  }

  void _calculateTotals() {
    totalQty = 0;
    totalGrossSale = 0;
    totalDiscount = 0;
    totalNetSale = 0;
    totalTax = 0;
    totalSales = 0;

    for (var service in filteredServices) {
      totalQty += int.tryParse(service['qty'].toString()) ?? 0;
      totalGrossSale += double.tryParse(service['grossSale'].toString()) ?? 0;
      totalDiscount += double.tryParse(service['discount'].toString()) ?? 0;
      totalNetSale += double.tryParse(service['netSale'].toString()) ?? 0;
      totalTax += double.tryParse(service['tax'].toString()) ?? 0;
      totalSales += double.tryParse(service['totalSales'].toString()) ?? 0;
    }
  }

  void _filterData() {
    setState(() {
      filteredServices = selesHistory.where((service) {
        final matchesSearch = service['customer']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());

        final matchesDate = _selectedDateRange == null ||
            (service['date'].isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                service['date'].isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesDate;
      }).toList();

      _calculateTotals();
    });
  }

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
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterData();
      });
    }
  }

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("View Reports by each Service and Customer",
                style: TextStyle(fontSize: 16, color: Colors.black)),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            // Search
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search Here..",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                searchText = value;
                _filterData();
              },
            ),
            const SizedBox(height: 16),

            // Date picker + Export
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
                    border: Border.all(color: Colors.black),
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
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade200),
                        columnSpacing: 24,
                        dataRowHeight: 60,
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                        border: TableBorder.all(color: Colors.black26, width: 0.6),
                        columns: const [
                          DataColumn(label: Text("Invoice")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Customer")),
                          DataColumn(label: Text("QTY")),
                          DataColumn(label: Text("Gross Sale")),
                          DataColumn(label: Text("Discount")),
                          DataColumn(label: Text("Net Sale")),
                          DataColumn(label: Text("Taxes")),
                          DataColumn(label: Text("Total Sale")),
                        ],
                        rows: [
                          ...List.generate(filteredServices.length, (index) {
                            final service = filteredServices[index];
                            final isEven = index % 2 == 0;
                            return DataRow(
                              color: MaterialStateColor.resolveWith(
                                    (states) => isEven ? Colors.grey.shade50 : Colors.white,
                              ),
                              cells: [
                                DataCell(Text(service['invoice'])),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(service['status']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      service['status'],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataCell(Text(DateFormat('dd MMM yyyy, hh:mm a').format(service['date']))),
                                DataCell(Text(service['customer'])),
                                DataCell(Text(service['qty'].toString())),
                                DataCell(Text(_currencyFormat(service['grossSale']))),
                                DataCell(Text(_currencyFormat(service['discount']))),
                                DataCell(Text(_currencyFormat(service['netSale']))),
                                DataCell(Text(_currencyFormat(service['tax']))),
                                DataCell(Text(
                                  _currencyFormat(service['totalSales']),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
                              ],
                            );
                          }),

                          // TOTAL ROW
                          DataRow(
                            color: MaterialStateColor.resolveWith((states) => Colors.yellow.shade50),
                            cells: [
                              const DataCell(Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              DataCell(Text(totalQty.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(_currencyFormat(totalGrossSale), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(_currencyFormat(totalDiscount), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(_currencyFormat(totalNetSale), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(_currencyFormat(totalTax), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(_currencyFormat(totalSales), style: const TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      toolbarHeight: 50.h,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              'Sales History',
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'unpaid':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
