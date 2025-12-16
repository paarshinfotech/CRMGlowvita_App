import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';

class SettlementSummary extends StatefulWidget {
  @override
  State<SettlementSummary> createState() => _SettlementSummaryState();
}

class _SettlementSummaryState extends State<SettlementSummary> {
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> settlementData = [
    {
      'settlementId': 'SETT001',
      'invoice': '#INV0001',
      'status': 'PAID',
      'orderType': 'ONLINE',
      'settlementType': 'Order',
      'transactionType': 'Deduction',
      'date': DateTime(2025, 7, 26, 11, 00),
      'settlementDate': DateTime(2025, 7, 27),
      'orderDate': DateTime(2025, 7, 25),
      'orderTotal': '100',
      'commissionRate': '2.00%',
      'payoutAmount': '300.00',
    },
    {
      'settlementId': 'SETT002',
      'invoice': '#INV0002',
      'status': 'PENDING',
      'orderType': 'OFFLINE',
      'settlementType': 'Order',
      'transactionType': 'Deduction',
      'date': DateTime(2025, 7, 26, 13, 20),
      'settlementDate': DateTime(2025, 7, 28),
      'orderDate': DateTime(2025, 7, 26),
      'orderTotal': '50',
      'commissionRate': '1.50%',
      'payoutAmount': '150.00',
    },
  ];

  List<Map<String, dynamic>> filteredData = [];
  double totalPayout = 0.0;
  double totalOrder = 0.0;
  double totalCommission = 0.0;
  double totalCommissionRate = 0.0;
  int commissionCount = 0;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    filteredData = List.from(settlementData);
    _calculateTotals();
  }

  void _calculateTotals() {
    totalPayout = 0.0;
    totalOrder = 0.0;
    totalCommission = 0.0;
    totalCommissionRate = 0.0;
    commissionCount = 0;

    for (var data in filteredData) {
      totalOrder += double.tryParse(data['orderTotal'] ?? '0') ?? 0.0;
      totalPayout += double.tryParse(data['payoutAmount'] ?? '0') ?? 0.0;

      String? rateStr = data['commissionRate'];
      if (rateStr != null && rateStr.contains('%')) {
        double? rate = double.tryParse(rateStr.replaceAll('%', ''));
        if (rate != null) {
          totalCommissionRate += rate;
          commissionCount++;
        }
      }
    }

    totalCommission = commissionCount == 0 ? 0 : totalCommissionRate / commissionCount;
  }

  void _filterData() {
    setState(() {
      filteredData = settlementData.where((data) {
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

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Settlements'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50.h,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Settlement Summary',
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                    "Payout: ${_currencyFormat(totalPayout)}",
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                  columns: const [
                    DataColumn(label: Text("Settlement ID")),
                    DataColumn(label: Text("Invoice")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Order Type")),
                    DataColumn(label: Text("Settlement Type")),
                    DataColumn(label: Text("Transaction Type")),
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Settlement Date")),
                    DataColumn(label: Text("Order Date")),
                    DataColumn(label: Text("Order Total")),
                    DataColumn(label: Text("Commission %")),
                    DataColumn(label: Text("Payout Amount")),
                  ],
                  rows: [
                    ...filteredData.map((data) {
                      return DataRow(cells: [
                        DataCell(Text(data['settlementId'] ?? '')),
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
                        DataCell(Text(data['orderType'] ?? '')),
                        DataCell(Text(data['settlementType'] ?? '')),
                        DataCell(Text(data['transactionType'] ?? '')),
                        DataCell(Text(DateFormat('dd MMM yyyy').format(data['date']))),
                        DataCell(Text(DateFormat('dd MMM').format(data['settlementDate']))),
                        DataCell(Text(DateFormat('dd MMM').format(data['orderDate']))),
                        DataCell(Text(_currencyFormat(double.tryParse(data['orderTotal']) ?? 0.0))),
                        DataCell(Text(data['commissionRate'] ?? '')),
                        DataCell(Text(_currencyFormat(double.tryParse(data['payoutAmount']) ?? 0.0))),
                      ]);
                    }),
                    // Total Row
                    DataRow(
                      color: MaterialStateProperty.all(Colors.yellow.shade100),
                      cells: [
                        const DataCell(Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                        for (int i = 0; i < 6; i++) const DataCell(Text("")),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        DataCell(Text(
                          _currencyFormat(totalOrder),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          "${totalCommission.toStringAsFixed(2)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          _currencyFormat(totalPayout),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
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
            'Settlement Summary',
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
  switch (status.toUpperCase()) {
    case 'PAID':
      return Colors.green;
    case 'PENDING':
      return Colors.orange;
    case 'FAILED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
