import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Notification.dart';
import 'Profile.dart';

class TotalPage extends StatelessWidget {
  const TotalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('dd MMM yyyy').format(DateTime.now());
    ScreenUtil.init(context, designSize: Size(375, 812));

    // Sort appointments by time
    appointments.sort((a, b) {
      final timeA = TimeOfDay(
        hour: int.parse(a['time'].split(' ')[1].split(':')[0]) +
            (a['time'].contains('PM') && !a['time'].contains('12') ? 12 : 0),
        minute: int.parse(a['time'].split(':')[1].substring(0, 2)),
      );
      final timeB = TimeOfDay(
        hour: int.parse(b['time'].split(' ')[1].split(':')[0]) +
            (b['time'].contains('PM') && !b['time'].contains('12') ? 12 : 0),
        minute: int.parse(b['time'].split(':')[1].substring(0, 2)),
      );
      return timeA.hour.compareTo(timeB.hour) != 0
          ? timeA.hour.compareTo(timeB.hour)
          : timeA.minute.compareTo(timeB.minute);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50.h,
        titleSpacing: 0,
        automaticallyImplyLeading: true,
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
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
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
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()),
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
                    border: Border.all(
                      color: Colors.black,
                      width: 1.w,
                    ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 22,
              childAspectRatio: 0.9,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // disables internal scroll
              children: [
                // Total Earnings
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Earnings",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "All Time",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 13),
                              ),
                              const Divider(),
                              const SizedBox(height: 12),
                              const Text("₹ 0",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 8),
                              const Text("Completed Appointment : 0",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              const Text("Total Earnings : ₹ 0",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Appointments
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("All Appointments",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                              SizedBox(height: 2),
                              Text("Past, Current & Future",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 13)),
                              Divider(),
                              SizedBox(height: 12),
                              Text("0 Appointments",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              SizedBox(height: 8),
                              Text("New : 0",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              Text("Confirmed : 0",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              Text("Completed : 0",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              Text("Cancelled : 0",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Booked Hours
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Booked Hours",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                              const Text(
                                "All Time",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Divider(),
                              SizedBox(height: 12),
                              Text("0h",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              SizedBox(height: 8),
                              Text("Total Hours Booked",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Top Selling Services
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Top Selling Services",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                      const Text(
                        "All Time",
                        style: TextStyle(color: Colors.black, fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: TopSellingServices(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // All Appointments
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "All Appointments",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      appointments.isEmpty
                          ? Center(
                              child: Text(
                                "No Upcoming Appointments",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            )
                          : SizedBox(
                              height: 300,
                              child: ListView.separated(
                                itemCount: appointments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final appointment = appointments[index];
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Date Box
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              appointment['date'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              appointment['month'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Appointment Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appointment['time'],
                                              style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              appointment['service'],
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${appointment['client']}, ${appointment['duration']} with ${appointment['staff']}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Price + Status
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.lock_clock,
                                                  color: Colors.orange,
                                                  size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                "New",
                                                style: TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "₹ ${appointment['price']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),

                // Staff Commission Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Staff Commission",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "All Time",
                        style: TextStyle(color: Colors.black, fontSize: 13),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      staffList.isEmpty
                          ? const Center(
                              child: Text(
                                "No staff added yet.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                    Color(0xFFF5F5F5)),
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text("Staff Member")),
                                  DataColumn(label: Text("Appointments")),
                                  DataColumn(label: Text("Sales")),
                                  DataColumn(label: Text("Commission")),
                                ],
                                rows: [
                                  ...staffList.map((staff) {
                                    return DataRow(cells: [
                                      DataCell(Text(staff['name'] ?? '')),
                                      DataCell(
                                          Text("${staff['appointments']}")),
                                      DataCell(Text("₹ ${staff['sales']}")),
                                      DataCell(
                                          Text("₹ ${staff['commission']}")),
                                    ]);
                                  }).toList(),
                                  // Totals Row
                                  DataRow(
                                    color: MaterialStateProperty.all(
                                        Colors.grey.shade100),
                                    cells: [
                                      const DataCell(Text(
                                        "Total",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        "${getTotal('appointments')}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        "₹ ${getTotal('sales')}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        "₹ ${getTotal('commission')}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Staff List
final List<Map<String, dynamic>> staffList = [
  {
    'name': 'Juilli Ware',
    'appointments': 3,
    'sales': 1200,
    'commission': 120, // 10%
  },
  {
    'name': 'Riya Mehta',
    'appointments': 2,
    'sales': 800,
    'commission': 80,
  },
];

bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

// Appointment List
final List<Map<String, dynamic>> appointments = [
  {
    'date': '23',
    'month': 'JUL',
    'time': 'Wed 01:15PM',
    'service': 'Spa',
    'client': 'Siddhi Shinde',
    'duration': '25min',
    'staff': 'Juilli Ware',
    'price': 300,
  },
  {
    'date': '28',
    'month': 'JUL',
    'time': 'Wed 11:15AM',
    'service': 'Facial',
    'client': 'Aarohi Patil',
    'duration': '30min',
    'staff': 'Ananya Mehra',
    'price': 400,
  },
  {
    'date': '27',
    'month': 'JUL',
    'time': 'Thu 10:00AM',
    'service': 'Haircut',
    'client': 'Rutuja More',
    'duration': '45min',
    'staff': 'Pooja Nair',
    'price': 550,
  },
  {
    'date': '23',
    'month': 'JUL',
    'time': 'Fri 02:30PM',
    'service': 'Nail Art',
    'client': 'Sneha Sawant',
    'duration': '35min',
    'staff': 'Neha Joshi',
    'price': 250,
  },
  {
    'date': '25',
    'month': 'JUL',
    'time': 'Sat 12:00PM',
    'service': 'Massage',
    'client': 'Nikita Kale',
    'duration': '60min',
    'staff': 'Rashmi Desai',
    'price': 650,
  },
  {
    'date': '24',
    'month': 'JUL',
    'time': 'Sun 03:45PM',
    'service': 'Cleanup',
    'client': 'Tanvi Patankar',
    'duration': '40min',
    'staff': 'Simran Kaur',
    'price': 700,
  },
];

String getTotal(String key) {
  double total = 0.0;
  for (var staff in staffList) {
    total += double.tryParse(staff[key].toString()) ?? 0.0;
  }
  return total.toStringAsFixed(2);
}

class TopSellingServices extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {'service': 'Spa', 'sold': 2},
    {'service': 'Facial', 'sold': 5},
    {'service': 'Haircut', 'sold': 3},
    {'service': 'Manicure', 'sold': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Service',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Sold',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Divider(),
        ...services.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['service']),
                Text(item['sold'].toString()),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
