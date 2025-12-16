import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PayoutSummary extends StatefulWidget {
  @override
  _PayoutSummaryState createState() => _PayoutSummaryState();
}

class _PayoutSummaryState extends State<PayoutSummary> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];
  double totalQty = 0;
  double totalGrossSale = 0;
  double totalDiscount = 0;
  double totalNetSale = 0;
  double totalTaxes = 0;
  double totalTotalSale = 0;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }
  DateTimeRange? _selectedDateRange;
  void _loadDummyData() {
    allData = [
      {
        "invoice": "INV001",
        "status": "Paid",
        "date": DateTime.now(),
        "customer": "John Doe",
        "qty": 2,
        "grossSale": 1000.0,
        "discount": 100.0,
        "netSale": 900.0,
        "taxes": 90.0,
        "totalSale": 990.0,
      },
      {
        "invoice": "INV002",
        "status": "Pending",
        "date": DateTime.now().subtract(Duration(days: 1)),
        "customer": "Jane Smith",
        "qty": 1,
        "grossSale": 500.0,
        "discount": 50.0,
        "netSale": 450.0,
        "taxes": 45.0,
        "totalSale": 495.0,
      },
    ];
    _applyFilter('');
  }

  void _applyFilter(String query) {
    setState(() {
      filteredData = allData.where((data) {
        return data['invoice'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
      _calculateTotals();
    });
  }
  void _filterData() {
    setState(() {
      filteredData = allData.where((data) {
        return data['settlementId']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());
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
              end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterData();
      });
    }
  }
  void _calculateTotals() {
    totalQty = totalGrossSale = totalDiscount = totalNetSale = totalTaxes = totalTotalSale = 0;
    for (var data in filteredData) {
      totalQty += data['qty'];
      totalGrossSale += data['grossSale'];
      totalDiscount += data['discount'];
      totalNetSale += data['netSale'];
      totalTaxes += data['taxes'];
      totalTotalSale += data['totalSale'];
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _currencyFormat(double value) {
    final format = NumberFormat.currency(symbol: "₹", decimalDigits: 2);
    return format.format(value);
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
        title: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Payout Summary',
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
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => NotificationPage())),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfilePage())),
              child: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/images/profile.jpeg'),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Subtitle & divider
            Text(
              "View settlement reports by each sale",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            TextField(
              decoration: InputDecoration(
                hintText: "Search Settlement ID...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                searchText = val;
                _filterData();
              },
            ),
            SizedBox(height: 12),
            Row(
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
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payments_outlined, size: 20, color: Colors.white),
                  label: Text(
                    "Payout: ",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                SizedBox(width: 10),
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
            SizedBox(height: 20),

            // Data Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                  columns: const [
                    DataColumn(label: Text("Invoice")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Customer")),
                    DataColumn(label: Text("Qty")),
                    DataColumn(label: Text("Gross Sale")),
                    DataColumn(label: Text("Discount")),
                    DataColumn(label: Text("Net Sale")),
                    DataColumn(label: Text("Taxes")),
                    DataColumn(label: Text("Total Sale")),
                  ],
                  rows: [
                    ...filteredData.map((data) {
                      return DataRow(cells: [
                        DataCell(Text(data['invoice'] ?? '')),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status']).withOpacity(0.1),
                            border: Border.all(color: _getStatusColor(data['status'])),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['status'],
                            style: TextStyle(
                              color: _getStatusColor(data['status']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                        DataCell(Text(DateFormat('dd MMM yyyy').format(data['date']))),
                        DataCell(Text(data['customer'] ?? '')),
                        DataCell(Text('${data['qty']}')),
                        DataCell(Text(_currencyFormat(data['grossSale']))),
                        DataCell(Text(_currencyFormat(data['discount']))),
                        DataCell(Text(_currencyFormat(data['netSale']))),
                        DataCell(Text(_currencyFormat(data['taxes']))),
                        DataCell(Text(_currencyFormat(data['totalSale']))),
                      ]);
                    }).toList(),

                    // Totals Row
                    DataRow(
                      color: MaterialStateProperty.all(Colors.yellow.shade100),
                      cells: [
                        const DataCell(Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        DataCell(Text(totalQty.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(_currencyFormat(totalGrossSale), style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(_currencyFormat(totalDiscount), style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(_currencyFormat(totalNetSale), style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(_currencyFormat(totalTaxes), style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(_currencyFormat(totalTotalSale), style: TextStyle(fontWeight: FontWeight.bold))),
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
