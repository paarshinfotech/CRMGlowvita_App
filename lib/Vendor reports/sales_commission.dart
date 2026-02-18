import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesCommission extends StatefulWidget {
  @override
  State<SalesCommission> createState() => _SalesCommissionState();
}

class _SalesCommissionState extends State<SalesCommission> {
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> salesCommission = [
    {
      'invoice': '#00001265',
      'mode': 'OFFLINE',
      'status': 'PENDING',
      'date': DateTime(2025, 7, 26, 12, 52),
      'customer': 'Siddhi Shinde',
      'qty': 2,
      'grossSale': 410,
      'discount': 0,
      'netSale': 410,
      'tax': 0,
      'totalSales': 410,
      'commissionRate': '2.00%',
      'commissionamount': '6.20',
      'settlementAmount': '409.00',
      'payoutAmount': '0.00',
    },
    {
      'invoice': '#00001264',
      'mode': 'ONLINE',
      'status': 'PENDING',
      'date': DateTime(2025, 7, 26, 12, 48),
      'customer': 'Siddhi Shinde',
      'qty': 1,
      'grossSale': 310,
      'discount': 0,
      'netSale': 310,
      'tax': 0,
      'totalSales': 310,
      'commissionRate': '2.00%',
      'commissionamount': '6.20',
      'settlementAmount': '308.00',
      'payoutAmount': '0.00',
    },
    {
      'invoice': '#00001263',
      'mode': 'OFFLINE',
      'status': 'PAID',
      'date': DateTime(2025, 7, 26, 12, 48),
      'customer': 'Siddhi Shinde',
      'qty': 1,
      'grossSale': 310,
      'discount': 10,
      'netSale': 300,
      'tax': 10,
      'totalSales': 310,
      'commissionRate': '2.00%',
      'commissionamount': '6.00',
      'settlementAmount': '304.00',
      'payoutAmount': '6.00',
    },
    {
      'invoice': '#00001262',
      'mode': 'ONLINE',
      'status': 'CANCELLED',
      'date': DateTime(2025, 7, 26, 12, 25),
      'customer': 'Siddhi Shinde',
      'qty': 1,
      'grossSale': 310,
      'discount': 0,
      'netSale': 310,
      'tax': 0,
      'totalSales': 310,
      'commissionRate': '0.00%',
      'commissionamount': '0.00',
      'settlementAmount': '0.00',
      'payoutAmount': '0.00',
    },
  ];

  List<Map<String, dynamic>> filteredServices = [];
  String searchText = '';

  int totalQty = 0;
  double totalGrossSale = 0;
  double totalDiscount = 0;
  double totalNetSale = 0;
  double totalTax = 0;
  double totalSales = 0;
  double totalCommissionAmt = 0;
  double totalSettlementAmt = 0;
  double totalPayoutAmt = 0;

  @override
  void initState() {
    super.initState();
    filteredServices = List.from(salesCommission);
    _calculateTotals();
  }

  void _calculateTotals() {
    totalQty = 0;
    totalGrossSale = 0;
    totalDiscount = 0;
    totalNetSale = 0;
    totalTax = 0;
    totalSales = 0;
    totalCommissionAmt = 0;
    totalSettlementAmt = 0;
    totalPayoutAmt = 0;

    for (var service in filteredServices) {
      totalQty += (service['qty'] ?? 0) as int;
      totalGrossSale += service['grossSale'] ?? 0.0;
      totalDiscount += service['discount'] ?? 0.0;
      totalNetSale += service['netSale'] ?? 0.0;
      totalTax += service['tax'] ?? 0.0;
      totalSales += service['totalSales'] ?? 0.0;

      totalCommissionAmt +=
          double.tryParse(service['commissionamount'] ?? '0.0') ?? 0.0;
      totalSettlementAmt +=
          double.tryParse(service['settlementAmount'] ?? '0.0') ?? 0.0;
      totalPayoutAmt +=
          double.tryParse(service['payoutAmount'] ?? '0.0') ?? 0.0;
    }
  }

  void _filterData() {
    setState(() {
      filteredServices = salesCommission.where((service) {
        final matchesSearch = service['customer']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());

        final matchesDate = _selectedDateRange == null ||
            (service['date'].isAfter(_selectedDateRange!.start
                    .subtract(const Duration(days: 1))) &&
                service['date'].isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1))));

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

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
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
            const Text("View Admin Commission Reports by Each Sale",
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

            // Date picker
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),

                // Payout Button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payments_outlined,
                      size: 20, color: Colors.white),
                  label: Text(
                    "Payout: ${_currencyFormat(totalPayoutAmt)}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),

                //Export Button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.file_download_outlined,
                          color: Colors.black),
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
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade200),
                        columnSpacing: 24,
                        dataRowHeight: 60,
                        headingTextStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        border:
                            TableBorder.all(color: Colors.black26, width: 0.6),
                        columns: const [
                          DataColumn(label: Text("Invoice")),
                          DataColumn(label: Text("Mode")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Customer")),
                          DataColumn(label: Text("QTY")),
                          DataColumn(label: Text("Gross Sale")),
                          DataColumn(label: Text("Discount")),
                          DataColumn(label: Text("Net Sale")),
                          DataColumn(label: Text("Taxes")),
                          DataColumn(label: Text("Total Sale")),
                          DataColumn(label: Text("Commission %")),
                          DataColumn(label: Text("Commission Amt")),
                          DataColumn(label: Text("Settlement Amt")),
                          DataColumn(label: Text("Payout Amt")),
                        ],
                        rows: [
                          ...filteredServices.map((service) {
                            return DataRow(
                              cells: [
                                DataCell(Text(service['invoice'] ?? '')),
                                DataCell(Text(service['mode'] ?? '')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(service['status']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      service['status'] ?? '',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataCell(Text(DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(service['date']))),
                                DataCell(Text(service['customer'] ?? '')),
                                DataCell(Text(service['qty'].toString())),
                                DataCell(Text(
                                    _currencyFormat(service['grossSale']))),
                                DataCell(
                                    Text(_currencyFormat(service['discount']))),
                                DataCell(
                                    Text(_currencyFormat(service['netSale']))),
                                DataCell(Text(_currencyFormat(service['tax']))),
                                DataCell(Text(
                                    _currencyFormat(service['totalSales']))),
                                DataCell(
                                    Text(service['commissionRate'] ?? '0.00%')),
                                DataCell(Text(_currencyFormat(double.tryParse(
                                        service['commissionamount']) ??
                                    0.0))),
                                DataCell(Text(_currencyFormat(double.tryParse(
                                        service['settlementAmount']) ??
                                    0.0))),
                                DataCell(Text(_currencyFormat(
                                    double.tryParse(service['payoutAmount']) ??
                                        0.0))),
                              ],
                            );
                          }).toList(),

                          // Total Row
                          DataRow(
                            color: MaterialStateColor.resolveWith(
                                (states) => Colors.yellow.shade50),
                            cells: [
                              const DataCell(Text("Total",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              DataCell(Text(
                                totalQty.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalGrossSale),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalDiscount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalNetSale),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalTax),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalSales),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              const DataCell(
                                  Text("")), // Commission % not summed
                              DataCell(Text(
                                _currencyFormat(totalCommissionAmt),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalSettlementAmt),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                _currencyFormat(totalPayoutAmt),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
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
              'Sales Commission',
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
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Theme.of(context).primaryColor;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'unpaid':
        return Theme.of(context).primaryColor;
      default:
        return Colors.grey;
    }
  }
}
