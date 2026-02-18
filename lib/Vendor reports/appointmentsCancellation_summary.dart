import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AppointmentsCancellationSummary extends StatefulWidget {
  @override
  State<AppointmentsCancellationSummary> createState() => _AppointmentsCancellationSummaryState();
}

class _AppointmentsCancellationSummaryState extends State<AppointmentsCancellationSummary> {
  DateTimeRange? _selectedDateRange;
  String _sortColumn = 'ref';
  bool _sortAscending = true;

  final List<Map<String, dynamic>> appointments = [
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
      'cancelledOn': null,
      'cancelledBy': null,
      'reason': null,
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
      'cancelledOn': null,
      'cancelledBy': null,
      'reason': null,
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
      'cancelledOn': null,
      'cancelledBy': null,
      'reason': null,
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
      'cancelledOn': DateTime(2025, 7, 26, 10, 30),
      'cancelledBy': 'User',
      'reason': 'Schedule conflict',
    },
  ];

  List<Map<String, dynamic>> filteredServiceDetails = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _calculateServiceDetails();
  }

  void _calculateServiceDetails() {
    List<Map<String, dynamic>> filteredAppointments = appointments.where((appointment) {
      final matchesDate = _selectedDateRange == null ||
          (appointment['scheduledOn'].isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              appointment['scheduledOn'].isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      return matchesDate;
    }).toList();

    List<Map<String, dynamic>> detailedAppointments = [];
    for (var appointment in filteredAppointments) {
      List<String> serviceList;
      if (appointment['services'] is String) {
        serviceList = (appointment['services'] as String).split(',').map((s) => s.trim()).toList();
      } else if (appointment['services'] is List) {
        serviceList = (appointment['services'] as List).map((s) => s.toString().trim()).toList();
      } else {
        serviceList = []; // Fallback for unexpected types
      }

      for (var service in serviceList) {
        double price = (double.tryParse(appointment['price'].toString()) ?? 0) / (serviceList.isEmpty ? 1 : serviceList.length);
        detailedAppointments.add({
          'ref': appointment['ref'],
          'client': appointment['client'],
          'service': service,
          'staffName': appointment['staffName'],
          'scheduledOn': appointment['scheduledOn'],
          'cancelledOn': appointment['cancelledOn'],
          'cancelledBy': appointment['cancelledBy'],
          'reason': appointment['reason'],
          'price': price,
        });
      }
    }

    filteredServiceDetails = detailedAppointments.where((appointment) {
      return appointment['ref'].toString().toLowerCase().contains(searchText.toLowerCase()) ||
          appointment['client'].toString().toLowerCase().contains(searchText.toLowerCase()) ||
          appointment['service'].toString().toLowerCase().contains(searchText.toLowerCase()) ||
          appointment['staffName'].toString().toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    // Sort the details
    filteredServiceDetails.sort((a, b) {
      var aValue = a[_sortColumn];
      var bValue = b[_sortColumn];
      if (_sortColumn == 'scheduledOn' || _sortColumn == 'cancelledOn') {
        aValue = aValue ?? DateTime(1970);
        bValue = bValue ?? DateTime(1970);
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (_sortColumn == 'price') {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else {
        return _sortAscending
            ? aValue.toString().compareTo(bValue.toString())
            : bValue.toString().compareTo(aValue.toString());
      }
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
        _calculateServiceDetails();
      });
    }
  }

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0').format(amount)}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [
      ['Ref.', 'Client', 'Service', 'Staff Name', 'Schedule On', 'Cancelled On', 'Cancelled By', 'Reason', 'Price'],
      ...filteredServiceDetails.map((appointment) => [
        appointment['ref'],
        appointment['client'],
        appointment['service'],
        appointment['staffName'],
        _formatDateTime(appointment['scheduledOn']),
        _formatDateTime(appointment['cancelledOn']),
        appointment['cancelledBy'] ?? 'N/A',
        appointment['reason'] ?? 'N/A',
        _currencyFormat(appointment['price']),
      ]),
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/service_details.csv';
    final file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to $path')),
    );
  }

  void _sort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _calculateServiceDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Text(
                "Appointments by Service Details",
                style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.black),
              ),
              SizedBox(height: 4.h),
              Container(height: 2.h, width: 200.w, color: Colors.black),
              SizedBox(height: 24.h),

              // Search
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search Ref., Client, Service, or Staff...",
                  hintStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                style: GoogleFonts.poppins(),
                onChanged: (value) {
                  searchText = value;
                  _calculateServiceDetails();
                },
              ),
              SizedBox(height: 16.h),

              // Date picker + Export
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectDateRange,
                    icon: Icon(Icons.date_range, size: 20.sp),
                    label: Text(
                      _selectedDateRange != null
                          ? "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}"
                          : "Pick Range",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.black54),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      elevation: 0,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        icon: Icon(Icons.file_download_outlined, color: Colors.black, size: 20.sp),
                        items: const [
                          DropdownMenuItem(value: 'csv', child: Text('CSV')),
                          DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                          DropdownMenuItem(value: 'copy', child: Text('Copy')),
                          DropdownMenuItem(value: 'excel', child: Text('Excel')),
                          DropdownMenuItem(value: 'print', child: Text('Print')),
                        ],
                        hint: Text("Export", style: GoogleFonts.poppins()),
                        onChanged: (value) {
                          if (value == 'csv') {
                            _exportToCsv();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Selected: $value")),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Data Table
              Expanded(
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade200),
                          columnSpacing: 16.w,
                          dataRowHeight: 60.h,
                          headingTextStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 10.sp,
                          ),
                          dataTextStyle: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: Colors.black87,
                          ),
                          border: TableBorder.all(color: Colors.black26, width: 0.5),
                          columns: [
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('ref'),
                                child: Row(
                                  children: [
                                    Text("Ref."),
                                    if (_sortColumn == 'ref')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('client'),
                                child: Row(
                                  children: [
                                    Text("Client"),
                                    if (_sortColumn == 'client')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('service'),
                                child: Row(
                                  children: [
                                    Text("Service"),
                                    if (_sortColumn == 'service')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('staffName'),
                                child: Row(
                                  children: [
                                    Text("Staff Name"),
                                    if (_sortColumn == 'staffName')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('scheduledOn'),
                                child: Row(
                                  children: [
                                    Text("Schedule On"),
                                    if (_sortColumn == 'scheduledOn')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('cancelledOn'),
                                child: Row(
                                  children: [
                                    Text("Cancelled On"),
                                    if (_sortColumn == 'cancelledOn')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('cancelledBy'),
                                child: Row(
                                  children: [
                                    Text("Cancelled By"),
                                    if (_sortColumn == 'cancelledBy')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('reason'),
                                child: Row(
                                  children: [
                                    Text("Reason"),
                                    if (_sortColumn == 'reason')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('price'),
                                child: Row(
                                  children: [
                                    Text("Price"),
                                    if (_sortColumn == 'price')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                              numeric: true,
                            ),
                          ],
                          rows: List.generate(filteredServiceDetails.length, (index) {
                            final appointment = filteredServiceDetails[index];
                            final isEven = index % 2 == 0;
                            return DataRow(
                              color: MaterialStateColor.resolveWith(
                                    (states) => isEven ? Colors.grey.shade50 : Colors.white,
                              ),
                              cells: [
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(appointment['ref']?.toString() ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(appointment['client']?.toString() ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(appointment['service']?.toString() ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(appointment['staffName']?.toString() ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(_formatDateTime(appointment['scheduledOn'])),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(_formatDateTime(appointment['cancelledOn'])),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(appointment['cancelledBy']?.toString() ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(appointment['reason']?.toString() ?? 'N/A'),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(_currencyFormat(appointment['price'])),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          SizedBox(width: 20.w),
          Expanded(
            child: Text(
              'Appointments by Service Details',
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
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
}
