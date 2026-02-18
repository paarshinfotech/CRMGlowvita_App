import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OutstandingSaleSummary extends StatefulWidget {
  const OutstandingSaleSummary({super.key});

  @override
  State<OutstandingSaleSummary> createState() => _OutstandingSaleSummaryState();
}

class _OutstandingSaleSummaryState extends State<OutstandingSaleSummary> {
  String _searchText = '';
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> allData = [
    {
      'invoice': 'INV001',
      'status': 'Pending',
      'date': DateTime(2025, 7, 10),
      'customer': 'John Doe',
      'qty': 3,
      'grossSale': 1500.0,
      'discount': 100.0,
      'netSale': 1400.0,
      'taxes': 126.0,
      'totalSale': 1526.0,
    },
    {
      'invoice': 'INV002',
      'status': 'Completed',
      'date': DateTime(2025, 7, 15),
      'customer': 'Jane Smith',
      'qty': 2,
      'grossSale': 1000.0,
      'discount': 50.0,
      'netSale': 950.0,
      'taxes': 85.5,
      'totalSale': 1035.5,
    },
  ];

  List<Map<String, dynamic>> filteredData = [];

  @override
  void initState() {
    super.initState();
    filteredData = List.from(allData);
  }

  void _filterData() {
    setState(() {
      filteredData = allData.where((item) {
        final matchesSearch = item['customer']
            .toLowerCase()
            .contains(_searchText.toLowerCase());
        final matchesDate = _selectedDateRange == null ||
            (item['date'].isAfter(
                _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                item['date']
                    .isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterData();
      });
    }
  }

  String _currencyFormat(num value) {
    return '₹${NumberFormat('#,##0.00').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    num totalQty =
    filteredData.fold(0, (sum, item) => sum + (item['qty'] as num));
    num totalGross =
    filteredData.fold(0, (sum, item) => sum + (item['grossSale'] as num));
    num totalDiscount =
    filteredData.fold(0, (sum, item) => sum + (item['discount'] as num));
    num totalNet =
    filteredData.fold(0, (sum, item) => sum + (item['netSale'] as num));
    num totalTax =
    filteredData.fold(0, (sum, item) => sum + (item['taxes'] as num));
    num totalSale =
    filteredData.fold(0, (sum, item) => sum + (item['totalSale'] as num));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Outstanding Sales", style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Track all outstanding sales with customer-wise details",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            // Controls: Search, Range, Export
            Row(
              children: [
                // Search
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      _searchText = value;
                      _filterData();
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search Customer",
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Range Button
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_month, size: 18),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),

                // Export
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      icon:
                      const Icon(Icons.download, color: Colors.black),
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
                            SnackBar(content: Text("Selected: $value")));
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                  MaterialStateProperty.all(Colors.grey.shade200),
                  columns: const [
                    DataColumn(label: Text("Invoice")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Customer")),
                    DataColumn(label: Text("QTY")),
                    DataColumn(label: Text("Gross")),
                    DataColumn(label: Text("Discount")),
                    DataColumn(label: Text("Net")),
                    DataColumn(label: Text("Tax")),
                    DataColumn(label: Text("Total")),
                  ],
                  rows: [
                    // Normal Data Rows
                    ...filteredData.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['invoice'])),
                        DataCell(_buildStatusTag(item['status'])),
                        DataCell(Text(DateFormat('dd MMM yyyy').format(item['date']))),
                        DataCell(Text(item['customer'])),
                        DataCell(Text(item['qty'].toString())),
                        DataCell(Text(_currencyFormat(item['grossSale']))),
                        DataCell(Text(_currencyFormat(item['discount']))),
                        DataCell(Text(_currencyFormat(item['netSale']))),
                        DataCell(Text(_currencyFormat(item['taxes']))),
                        DataCell(Text(_currencyFormat(item['totalSale']))),
                      ]);
                    }).toList(),

                    // Total Row
                    DataRow(
                      color: MaterialStateProperty.all(Colors.yellow.shade100),
                      cells: [
                        const DataCell(Text(
                          "Total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        DataCell(Text(
                          totalQty.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _currencyFormat(totalGross),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _currencyFormat(totalDiscount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _currencyFormat(totalNet),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _currencyFormat(totalTax),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _currencyFormat(totalSale),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                      ],
                    )
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color bgColor = status == 'Completed'
        ? Colors.green.shade100
        : status == 'Pending'
        ? Colors.orange.shade100
        : Colors.grey.shade300;
    Color textColor = status == 'Completed'
        ? Colors.green
        : status == 'Pending'
        ? Colors.orange
        : Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(fontSize: 12.sp, color: textColor),
      ),
    );
  }

  Widget _buildTotalTile(String title, num value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
            GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w500)),
        Text(_currencyFormat(value),
            style: GoogleFonts.poppins(fontSize: 14.sp)),
      ],
    );
  }
}
