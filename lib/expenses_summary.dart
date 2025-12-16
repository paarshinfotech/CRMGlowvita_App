import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExpensesSummary extends StatefulWidget {
  const ExpensesSummary({super.key});

  @override
  State<ExpensesSummary> createState() => _ExpensesSummaryState();
}

class _ExpensesSummaryState extends State<ExpensesSummary> {
  String _searchText = '';
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> allData = [
    {
      'date': DateTime(2025, 7, 12),
      'expenseType': 'Travel',
      'amount': 2500.0,
      'paymentMode': 'Cash',
      'description': 'Client meeting travel expenses'
    },
    {
      'date': DateTime(2025, 7, 14),
      'expenseType': 'Supplies',
      'amount': 1300.0,
      'paymentMode': 'Card',
      'description': 'Office stationery'
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
        final matchesSearch = item['description']
            .toLowerCase()
            .contains(_searchText.toLowerCase());
        final matchesDate = _selectedDateRange == null ||
            (item['date'].isAfter(
                _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                item['date'].isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1))));
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
    num totalAmount =
    filteredData.fold(0, (sum, item) => sum + (item['amount'] as num));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Expense Summary",
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Track all business expenses by type, date, and payment mode.",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            // Search Bar Row (separate line)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                        _filterData();
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search Description",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

// Range + Export Buttons Row
            Row(
              children: [
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
               // const SizedBox(width: 100),
Spacer(),
                // Export Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.download, color: Colors.black),
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
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Expense Type")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Payment Mode")),
                    DataColumn(label: Text("Description")),
                  ],
                  rows: [
                    ...filteredData.map((item) {
                      return DataRow(cells: [
                        DataCell(
                            Text(DateFormat('dd MMM yyyy').format(item['date']))),
                        DataCell(Text(item['expenseType'])),
                        DataCell(Text(_currencyFormat(item['amount']))),
                        DataCell(Text(item['paymentMode'])),
                        DataCell(Text(item['description'])),
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
                        DataCell(Text(
                          _currencyFormat(totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
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
}
