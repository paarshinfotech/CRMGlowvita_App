import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesByService extends StatefulWidget {
  @override
  State<SalesByService> createState() => _SalesByServiceState();
}

class _SalesByServiceState extends State<SalesByService> {
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
    if (picked != null) setState(() {
      _selectedDateRange = picked;
      _filterData();
    });
  }

  final List<Map<String, dynamic>> services = [
    {
      'service': 'Haircut',
      'sold': 30,
      'grossSale': 3000,
      'discount': 200,
      'offers': 100,
      'netSale': 2700,
      'tax': 135,
      'totalSales': 2835,
    },
    {
      'service': 'Hair Styling',
      'sold': 18,
      'grossSale': 3600,
      'discount': 300,
      'offers': 200,
      'netSale': 3100,
      'tax': 155,
      'totalSales': 3255,
    },
    {
      'service': 'Nail Art',
      'sold': 12,
      'grossSale': 1800,
      'discount': 150,
      'offers': 50,
      'netSale': 1600,
      'tax': 80,
      'totalSales': 1680,
    },
  ];


  List<Map<String, dynamic>> filteredServices = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    filteredServices = List.from(services);
  }

  void _filterData() {
    setState(() {
      filteredServices = services.where((service) {
        final matchesSearch = service['customer']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());

        final matchesDate = _selectedDateRange == null ||
            (service['date'].isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                service['date'].isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesDate;
      }).toList();
    });
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
                'Sales by Services',
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
              "View Sales Reports by Each Service",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search Services",
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
                    borderRadius: BorderRadius.circular(12)),
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
                        DataColumn(label: Text("Service")),
                        DataColumn(label: Text("Sold")),
                        DataColumn(label: Text("Gross Sale")),
                        DataColumn(label: Text("Discounts")),
                        DataColumn(label: Text("Offers")),
                        DataColumn(label: Text("Net Sale")),
                        DataColumn(label: Text("Tax")),
                        DataColumn(label: Text("Total Sales")),
                      ],
                      rows: [
                        ...services.asMap().entries.map((entry) {
                          final index = entry.key;
                          final service = entry.value;
                          final isEven = index % 2 == 0;
                          return DataRow(
                            color: MaterialStateColor.resolveWith((states) =>
                            isEven ? Colors.grey.shade50 : Colors.white),
                            cells: [
                              DataCell(Text(service['service'])),
                              DataCell(Text(service['sold'].toString())),
                              DataCell(Text(_currencyFormat(service['grossSale']))),
                              DataCell(Text(_currencyFormat(service['discount']))),
                              DataCell(Text(_currencyFormat(service['offers']))),
                              DataCell(Text(_currencyFormat(service['netSale']))),
                              DataCell(Text(_currencyFormat(service['tax']))),
                              DataCell(Text(
                                _currencyFormat(service['totalSales']),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              )),
                            ],
                          );
                        }),

                        //  Totals Row
                        DataRow(
                          color: MaterialStateColor.resolveWith((states) => Colors.yellow.shade50),
                          cells: [
                            const DataCell(Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              services.fold<num>(0, (sum, item) => sum + item['sold']).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(services.fold<num>(0, (sum, item) => sum + item['grossSale'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(services.fold<num>(0, (sum, item) => sum + item['discount'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(services.fold<num>(0, (sum, item) => sum + item['offers'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(services.fold<num>(0, (sum, item) => sum + item['netSale'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(services.fold<num>(0, (sum, item) => sum + item['tax'])),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              _currencyFormat(services.fold<num>(0, (sum, item) => sum + item['totalSales'])),
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
