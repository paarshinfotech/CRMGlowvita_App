import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class AllAppointmentsSummary extends StatefulWidget {
  @override
  State<AllAppointmentsSummary> createState() => _AllAppointmentsSummaryState();
}

class _AllAppointmentsSummaryState extends State<AllAppointmentsSummary> {
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> allAppointment = [
    {
      'ref': '#00001265',
      'client': 'Siddhi Shinde',
      'services': 'Haircut, Styling',
      'staffName': 'Priya Sharma',
      'createdOn': DateTime(2025, 7, 26, 12, 52),
      'scheduledOn': DateTime(2025, 7, 27, 14, 00),
      'duration': '1h 30m',
      'price': 410,
      'status': 'PENDING',
    },
    {
      'ref': '#00001264',
      'client': 'Anita Desai',
      'services': 'Manicure',
      'staffName': 'Riya Patel',
      'createdOn': DateTime(2025, 7, 26, 12, 48),
      'scheduledOn': DateTime(2025, 7, 27, 10, 30),
      'duration': '45m',
      'price': 310,
      'status': 'PENDING',
    },
    {
      'ref': '#00001263',
      'client': 'Neha Gupta',
      'services': 'Massage',
      'staffName': 'Sonia Verma',
      'createdOn': DateTime(2025, 7, 26, 12, 48),
      'scheduledOn': DateTime(2025, 7, 26, 15, 00),
      'duration': '1h',
      'price': 310,
      'status': 'PAID',
    },
    {
      'ref': '#00001262',
      'client': 'Pooja Mehta',
      'services': 'Facial',
      'staffName': 'Kavita Singh',
      'createdOn': DateTime(2025, 7, 26, 12, 25),
      'scheduledOn': DateTime(2025, 7, 26, 11, 00),
      'duration': '1h',
      'price': 310,
      'status': 'CANCELLED',
    },
  ];

  List<Map<String, dynamic>> filteredAppointments = [];
  String searchText = '';

  // Totals
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    filteredAppointments = List.from(allAppointment);
    _calculateTotals();
  }

  void _calculateTotals() {
    totalPrice = 0;

    for (var appointment in filteredAppointments) {
      totalPrice += double.tryParse(appointment['price'].toString()) ?? 0;
    }
  }

  void _filterData() {
    setState(() {
      filteredAppointments = allAppointment.where((appointment) {
        final matchesSearch = appointment['client']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());

        final matchesDate = _selectedDateRange == null ||
            (appointment['scheduledOn'].isAfter(_selectedDateRange!.start
                    .subtract(const Duration(days: 1))) &&
                appointment['scheduledOn'].isBefore(
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
            Text("View Appointment Summary",
                style: TextStyle(fontSize: 16, color: Colors.black)),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            // Search
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search Client..",
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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

            // Data Table
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
                          DataColumn(label: Text("Ref.")),
                          DataColumn(label: Text("Client")),
                          DataColumn(label: Text("Services")),
                          DataColumn(label: Text("Staff Name")),
                          DataColumn(label: Text("Created On")),
                          DataColumn(label: Text("Scheduled On")),
                          DataColumn(label: Text("Duration")),
                          DataColumn(label: Text("Price")),
                          DataColumn(label: Text("Status")),
                        ],
                        rows: [
                          ...List.generate(filteredAppointments.length,
                              (index) {
                            final appointment = filteredAppointments[index];
                            final isEven = index % 2 == 0;
                            return DataRow(
                              color: MaterialStateColor.resolveWith(
                                (states) =>
                                    isEven ? Colors.grey.shade50 : Colors.white,
                              ),
                              cells: [
                                DataCell(Text(appointment['ref'])),
                                DataCell(Text(appointment['client'])),
                                DataCell(Text(appointment['services'])),
                                DataCell(Text(appointment['staffName'])),
                                DataCell(Text(DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(appointment['createdOn']))),
                                DataCell(Text(DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(appointment['scheduledOn']))),
                                DataCell(Text(appointment['duration'])),
                                DataCell(Text(
                                    _currencyFormat(appointment['price']))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                          appointment['status']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      appointment['status'],
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),

                          // TOTAL ROW
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
                              const DataCell(Text("")),
                              const DataCell(Text("")),
                              DataCell(Text(_currencyFormat(totalPrice),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                              const DataCell(Text("")),
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
              'Appointment Summary',
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
