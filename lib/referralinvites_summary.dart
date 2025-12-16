import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class ReferralInvitesSummary extends StatefulWidget {
  @override
  State<ReferralInvitesSummary> createState() => _ReferralInvitesSummaryState();
}

class _ReferralInvitesSummaryState extends State<ReferralInvitesSummary> {
  DateTimeRange? _selectedDateRange;
  String _searchText = '';

  final List<Map<String, dynamic>> _allInvites = [
    {
      'inviteTo': 'alice@example.com',
      'name': 'Alice Johnson',
      'date': DateTime(2025, 7, 20),
    },
    {
      'inviteTo': 'bob@example.com',
      'name': 'Bob Smith',
      'date': DateTime(2025, 7, 21),
    },
    {
      'inviteTo': 'carol@example.com',
      'name': 'Carol Lee',
      'date': DateTime(2025, 7, 22),
    },
  ];

  List<Map<String, dynamic>> _filteredInvites = [];

  @override
  void initState() {
    super.initState();
    _filteredInvites = List.from(_allInvites);
  }

  void _filterData() {
    setState(() {
      _filteredInvites = _allInvites.where((invite) {
        final matchesSearch = invite['name']
            .toString()
            .toLowerCase()
            .contains(_searchText.toLowerCase());
        final matchesDate = _selectedDateRange == null ||
            (invite['date'].isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                invite['date'].isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
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

  @override
  Widget build(BuildContext context) {
    final totalInvites = _filteredInvites.length;

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
                'Referrals / Invites',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Subtitle & divider
            Text(
              "View all referral invites sent",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 200, color: Colors.black),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search salon/customer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _searchText = value;
                _filterData();
              },
            ),
            const SizedBox(height: 16),

            // Range picker & export
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const Icon(Icons.file_download_outlined, color: Colors.black),
                      items: const [
                        DropdownMenuItem(value: 'csv', child: Text('CSV')),
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                        DropdownMenuItem(value: 'copy', child: Text('Copy')),
                        DropdownMenuItem(value: 'excel', child: Text('Excel')),
                        DropdownMenuItem(value: 'print', child: Text('Print')),
                      ],
                      hint: const Text("Export"),
                      onChanged: (value) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Selected: $value")),
                      ),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 8,
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
                          fontWeight: FontWeight.bold, color: Colors.black87),
                      columns: const [
                        DataColumn(label: Text("Invite To")),
                        DataColumn(label: Text("Salon / Customer")),
                        DataColumn(label: Text("Date")),
                      ],
                      rows: [
                        // Data rows
                        for (var invite in _filteredInvites)
                          DataRow(
                            cells: [
                              DataCell(Text(invite['inviteTo'])),
                              DataCell(Text(invite['name'])),
                              DataCell(
                                Text(DateFormat('dd MMM yyyy')
                                    .format(invite['date'])),
                              ),
                            ],
                          ),

                        // Total row
                        DataRow(
                          color: MaterialStateColor.resolveWith(
                                  (_) => Colors.yellow.shade50),
                          cells: [
                            const DataCell(Text("Total",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text("$totalInvites invites",
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
                            const DataCell(Text("")),
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
