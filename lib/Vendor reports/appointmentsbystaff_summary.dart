import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AppointmentsbyStaffSummary extends StatefulWidget {
  @override
  State<AppointmentsbyStaffSummary> createState() => _AppointmentsbyStaffSummaryState();
}

class _AppointmentsbyStaffSummaryState extends State<AppointmentsbyStaffSummary> {
  DateTimeRange? _selectedDateRange;
  String _sortColumn = 'staffName';
  bool _sortAscending = true;

  final List<Map<String, dynamic>> AppointmentsbyStaff = [
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

  List<Map<String, dynamic>> filteredStaffSummary = [];
  String searchText = '';

  // Totals
  int totalAppointments = 0;
  String totalDuration = '';
  double totalSales = 0;

  @override
  void initState() {
    super.initState();
    _calculateStaffSummary();
  }

  String _calculateTotalDuration(List<Map<String, dynamic>> appointments) {
    int totalMinutes = 0;
    for (var appointment in appointments) {
      String duration = appointment['duration'] ?? '0h';
      RegExp regex = RegExp(r'(\d+)h\s*(\d*)m?');
      var match = regex.firstMatch(duration);
      if (match != null) {
        int hours = int.parse(match.group(1) ?? '0');
        int minutes = match.group(2)!.isEmpty ? 0 : int.parse(match.group(2)!);
        totalMinutes += hours * 60 + minutes;
      }
    }
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  void _calculateStaffSummary() {
    Map<String, List<Map<String, dynamic>>> staffAppointments = {};
    List<Map<String, dynamic>> filteredAppointments = AppointmentsbyStaff.where((appointment) {
      final matchesDate = _selectedDateRange == null ||
          (appointment['scheduledOn'].isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              appointment['scheduledOn'].isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      return matchesDate;
    }).toList();

    for (var appointment in filteredAppointments) {
      String staffName = appointment['staffName'];
      if (!staffAppointments.containsKey(staffName)) {
        staffAppointments[staffName] = [];
      }
      staffAppointments[staffName]!.add(appointment);
    }

    filteredStaffSummary = staffAppointments.entries.map((entry) {
      String staffName = entry.key;
      List<Map<String, dynamic>> appointments = entry.value;
      int appointmentCount = appointments.length;
      String totalDuration = _calculateTotalDuration(appointments);
      double totalSale = appointments.fold(0, (sum, app) => sum + (double.tryParse(app['price'].toString()) ?? 0));

      return {
        'staffName': staffName,
        'totalAppointments': appointmentCount,
        'totalDuration': totalDuration,
        'totalSale': totalSale,
      };
    }).toList();

    // Apply search filter
    filteredStaffSummary = filteredStaffSummary.where((staff) {
      return staff['staffName'].toString().toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    // Sort the summary
    filteredStaffSummary.sort((a, b) {
      var aValue = a[_sortColumn];
      var bValue = b[_sortColumn];
      if (_sortColumn == 'staffName') {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (_sortColumn == 'totalAppointments' || _sortColumn == 'totalSale') {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else {
        int aMinutes = _durationToMinutes(aValue);
        int bMinutes = _durationToMinutes(bValue);
        return _sortAscending ? aMinutes.compareTo(bMinutes) : bMinutes.compareTo(aMinutes);
      }
    });

    _calculateTotals(filteredAppointments);
  }

  int _durationToMinutes(String duration) {
    RegExp regex = RegExp(r'(\d+)h\s*(\d*)m?');
    var match = regex.firstMatch(duration);
    if (match != null) {
      int hours = int.parse(match.group(1) ?? '0');
      int minutes = match.group(2)!.isEmpty ? 0 : int.parse(match.group(2)!);
      return hours * 60 + minutes;
    }
    return 0;
  }

  void _calculateTotals(List<Map<String, dynamic>> filteredAppointments) {
    totalAppointments = filteredStaffSummary.fold(0, (sum, staff) => sum + (staff['totalAppointments'] as int));
    totalSales = filteredStaffSummary.fold(0, (sum, staff) => sum + (staff['totalSale'] as double));
    totalDuration = _calculateTotalDuration(filteredAppointments);
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
        _calculateStaffSummary();
      });
    }
  }

  String _currencyFormat(num amount) {
    return '₹${NumberFormat('#,##0').format(amount)}';
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [
      ['Staff Name', 'Total Appointments', 'Total Duration', 'Total Sale'],
      ...filteredStaffSummary.map((staff) => [
        staff['staffName'],
        staff['totalAppointments'],
        staff['totalDuration'],
        _currencyFormat(staff['totalSale']),
      ]),
      ['Total', totalAppointments, totalDuration, _currencyFormat(totalSales)],
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/staff_summary.csv';
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
      _calculateStaffSummary();
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
                "Appointments by Staff Summary",
                style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.black),
              ),
              SizedBox(height: 4.h),
              Container(height: 2.h, width: 200.w, color: Colors.black),
              SizedBox(height: 24.h),

              // Search
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search Staff...",
                  hintStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                style: GoogleFonts.poppins(),
                onChanged: (value) {
                  searchText = value;
                  _calculateStaffSummary();
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
                          columnSpacing: 24.w,
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
                                onTap: () => _sort('totalAppointments'),
                                child: Row(
                                  children: [
                                    Text("Total Appointments"),
                                    if (_sortColumn == 'totalAppointments')
                                      Icon(
                                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16.sp,
                                      ),
                                  ],
                                ),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: GestureDetector(
                                onTap: () => _sort('totalDuration'),
                                child: Row(
                                  children: [
                                    Text("Total Duration"),
                                    if (_sortColumn == 'totalDuration')
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
                                onTap: () => _sort('totalSale'),
                                child: Row(
                                  children: [
                                    Text("Total Sale"),
                                    if (_sortColumn == 'totalSale')
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
                          rows: [
                            ...List.generate(filteredStaffSummary.length, (index) {
                              final staff = filteredStaffSummary[index];
                              final isEven = index % 2 == 0;
                              return DataRow(
                                color: MaterialStateColor.resolveWith(
                                      (states) => isEven ? Colors.grey.shade50 : Colors.white,
                                ),
                                cells: [
                                  DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                      child: Text(staff['staffName']),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                      child: Text(staff['totalAppointments'].toString()),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                      child: Text(staff['totalDuration']),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                      child: Text(_currencyFormat(staff['totalSale'])),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            // Total Row
                            DataRow(
                              color: MaterialStateColor.resolveWith((states) => Colors.yellow.shade100),
                              cells: [
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(
                                      "Total",
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(
                                      totalAppointments.toString(),
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(
                                      totalDuration,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Text(
                                      _currencyFormat(totalSales),
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
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
              'Appointments by Staff Summary',
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
