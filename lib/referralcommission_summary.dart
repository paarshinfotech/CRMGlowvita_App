import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class ReferralCommissionSummary extends StatefulWidget {
  @override
  State<ReferralCommissionSummary> createState() =>
      _ReferralCommissionSummaryState();
}

class _ReferralCommissionSummaryState
    extends State<ReferralCommissionSummary> {
  DateTimeRange? _selectedDateRange;
  String _searchText = '';

  final List<Map<String, dynamic>> _allCommissions = [
    {
      'from': 'referral@example.com',
      'name': 'Alice Johnson',
      'date': DateTime(2025, 7, 20),
      'rate': 10.0,
      'amount': 500.0,
    },
    {
      'from': 'promo@salon.com',
      'name': 'Bob Smith',
      'date': DateTime(2025, 7, 21),
      'rate': 12.5,
      'amount': 750.0,
    },
    {
      'from': 'campaign@beauty.com',
      'name': 'Carol Lee',
      'date': DateTime(2025, 7, 22),
      'rate': 8.0,
      'amount': 320.0,
    },
  ];

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_allCommissions);
  }

  void _filterData() {
    setState(() {
      _filtered = _allCommissions.where((row) {
        final matchesSearch = row['name']
            .toString()
            .toLowerCase()
            .contains(_searchText.toLowerCase());
        final matchesDate = _selectedDateRange == null ||
            (row['date']
                .isAfter(_selectedDateRange!.start.subtract(Duration(days: 1))) &&
                row['date']
                    .isBefore(_selectedDateRange!.end.add(Duration(days: 1))));
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

  String _currency(num v) => '₹${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    final totalAmount = _filtered.fold<double>(
      0,
          (sum, row) => sum + (row['amount'] as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
        IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        toolbarHeight: 50.h,
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Referral Commission',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage())),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // subtitle
            Text(
              "View referral commissions earned",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            SizedBox(height: 24),

            // Search
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search salon/customer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                _searchText = v;
                _filterData();
              },
            ),
            SizedBox(height: 16),

            // Range & Export
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: Icon(Icons.date_range, size: 20),
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
                      icon:
                      Icon(Icons.file_download_outlined, color: Colors.black),
                      items: [
                        'CSV',
                        'PDF',
                        'Copy',
                        'Excel',
                        'Print'
                      ]
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      hint: Text("Export"),
                      onChanged: (v) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Selected: $v"))),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Table
            Expanded(
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith(
                              (_) => Colors.grey.shade200),
                      columnSpacing: 24,
                      dataRowHeight: 56,
                      headingTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      columns: const [
                        DataColumn(label: Text("Commission From")),
                        DataColumn(label: Text("Salon / Customer")),
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Rate (%)")),
                        DataColumn(label: Text("Amount")),
                      ],
                      rows: [
                        // data
                        for (var row in _filtered)
                          DataRow(cells: [
                            DataCell(Text(row['from'])),
                            DataCell(Text(row['name'])),
                            DataCell(Text(DateFormat('dd MMM yyyy').format(row['date']))),
                            DataCell(Text("${row['rate'].toStringAsFixed(2)}%")),
                            DataCell(Text(_currency(row['amount']))),
                          ]),

                        // total
                        DataRow(
                          color: MaterialStateColor.resolveWith(
                                  (_) => Colors.yellow.shade50),
                          cells: [
                            const DataCell(Text("Total",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataCell(Text("")),
                            const DataCell(Text("")),
                            const DataCell(Text("")),
                            DataCell(Text(_currency(totalAmount),
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
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