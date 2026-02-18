import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffPerformance extends StatefulWidget {
  @override
  State<StaffPerformance> createState() => _StaffPerformanceState();
}

class _StaffPerformanceState extends State<StaffPerformance> {
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
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterData();
      });
    }
  }

  final List<Map<String, dynamic>> staffPerformanceList = [
    {
      'staffName': 'Juili Ware',
      'appointments': 33,
      'avg_service_duration': '23.03 Hours',
      'netRevenue': '0.00',
      'discount': '0.00',
      'tax': 0.00,
      'totalSale': '6080.00',
    },
    {
      'staffName': 'Juili Ware',
      'appointments': 33,
      'avg_service_duration': '23.03 Hours',
      'netRevenue': '0.00',
      'discount': '0.00',
      'tax': 0.00,
      'totalSale': '6080.00',
    }
  ];

  List<Map<String, dynamic>> filteredServices = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    filteredServices = List.from(staffPerformanceList);
  }

  void _filterData() {
    setState(() {
      filteredServices = staffPerformanceList.where((service) {
        final matchesSearch = service['staffName']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());

        // Date filter disabled due to missing 'date' field
        return matchesSearch;
      }).toList();
    });
  }

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }
  double _totalServiceDuration() {
    return filteredServices.fold<double>(0, (sum, item) {
      final durationStr = item['avg_service_duration']?.toString() ?? '0';
      final match = RegExp(r'\d+(\.\d+)?').firstMatch(durationStr);
      final value = match != null ? double.parse(match.group(0)!) : 0;
      return sum + value;
    });
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
                'Staff Performance',
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
            Text(
              "View Reports by Staff Performance",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search here",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              onChanged: (value) {
                searchText = value;
                _filterData();
              },
            ),
            const SizedBox(height: 16),
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
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade200),
                      columnSpacing: 24,
                      dataRowHeight: 60,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      columns: const [
                        DataColumn(label: Text("Staff Name")),
                        DataColumn(label: Text("Appointments")),
                        DataColumn(label: Text("Avg. Service Duration")),
                        DataColumn(label: Text("Net Revenue")),
                        DataColumn(label: Text("Discount")),
                        DataColumn(label: Text("Tax")),
                        DataColumn(label: Text("Total Sale")),
                      ],
                      rows: [
                        ...List.generate(filteredServices.length, (index) {
                          final service = filteredServices[index];
                          final isEven = index % 2 == 0;
                          return DataRow(
                            color: MaterialStateColor.resolveWith(
                                    (states) => isEven ? Colors.grey.shade50 : Colors.white),
                            cells: [
                              DataCell(Text(service['staffName'] ?? '')),
                              DataCell(Text(service['appointments'].toString())),
                              DataCell(Text(service['avg_service_duration'] ?? '')),
                              DataCell(Text(_currencyFormat(num.tryParse(service['netRevenue']) ?? 0))),
                              DataCell(Text(_currencyFormat(num.tryParse(service['discount']) ?? 0))),
                              DataCell(Text(_currencyFormat(service['tax']))),
                              DataCell(Text(_currencyFormat(num.tryParse(service['totalSale']) ?? 0))),
                            ],
                          );
                        }),

                        // Total Row
                        DataRow(
                          color: MaterialStateColor.resolveWith((states) => Colors.yellow.shade50),
                          cells: [
                            const DataCell(Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              filteredServices.fold<int>(
                                0,
                                    (sum, item) => sum + (item['appointments'] as int? ?? 0),
                              ).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),

                            DataCell(Text(
                              '${_totalServiceDuration().toStringAsFixed(2)} Hours',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(filteredServices.fold<num>(0, (sum, item) =>
                              sum + (num.tryParse(item['netRevenue'].toString()) ?? 0))),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(filteredServices.fold<num>(0, (sum, item) =>
                              sum + (num.tryParse(item['discount'].toString()) ?? 0))),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(filteredServices.fold<num>(0, (sum, item) =>
                              sum + (item['tax'] ?? 0))),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(filteredServices.fold<num>(0, (sum, item) =>
                              sum + (num.tryParse(item['totalSale'].toString()) ?? 0))),
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


