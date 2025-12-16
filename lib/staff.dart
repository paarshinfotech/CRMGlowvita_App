import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'add_staff.dart';
import 'dart:io';
import 'widgets/custom_drawer.dart';

class Staff extends StatefulWidget {
  const Staff({Key? key}) : super(key: key);

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  final List<Map<String, dynamic>> staffList = [];

  String _searchQuery = '';

  // Sort state (0=Name, 1=Contact, 2=Position, 3=Status)
  int? _sortColumn;
  bool _sortAsc = true;

  Future<void> _openAddStaff({Map<String, dynamic>? existing, int? editIndex}) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme).apply(fontSizeFactor: 0.9),
        ),
        child: AddStaffDialog(existing: existing),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (editIndex != null) {
          staffList[editIndex] = result;
        } else {
          staffList.add(result);
        }
      });
    }
  }

  void _deleteStaff(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(dialogBackgroundColor: Colors.white),
        child: AlertDialog(
          title: Text('Delete staff', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to delete ${staffList[index]['firstName']} ${staffList[index]['lastName']}?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12))),
            TextButton(
              onPressed: () {
                setState(() => staffList.removeAt(index));
                Navigator.pop(ctx);
              },
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportStaff() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        content: Text('Exporting ${staffList.length} staff (demo).', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredStaff {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(staffList);
    return staffList.where((s) {
      final name = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      final phone = (s['mobile'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  void _sortBy(int columnIndex) {
    setState(() {
      _sortAsc = (_sortColumn == columnIndex) ? !_sortAsc : true;
      _sortColumn = columnIndex;
    });
  }

  List<Map<String, dynamic>> _applySort(List<Map<String, dynamic>> input) {
    if (_sortColumn == null) return input;
    final list = List<Map<String, dynamic>>.from(input);
    int cmp(String x, String y) => _sortAsc ? x.compareTo(y) : y.compareTo(x);
    list.sort((a, b) {
      switch (_sortColumn) {
        case 0:
          final ax = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.toLowerCase();
          final bx = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'.toLowerCase();
          return cmp(ax, bx);
        case 1:
          return cmp((a['mobile'] ?? '').toString().toLowerCase(), (b['mobile'] ?? '').toString().toLowerCase());
        case 2:
          return cmp((a['position'] ?? '').toString().toLowerCase(), (b['position'] ?? '').toString().toLowerCase());
        case 3:
          return cmp((a['status'] ?? 'Active').toString().toLowerCase(), (b['status'] ?? 'Active').toString().toLowerCase());
        default:
          return 0;
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final total = staffList.length;
    final activeCount = staffList.where((s) => s['status'] == 'Active' || s['status'] == null).length;

    final rows = _applySort(_filteredStaff);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(fontSizeFactor: 0.8),
      ),
      child: Scaffold(
        drawer: const CustomDrawer(currentPage: 'Staff'),
        appBar: AppBar(
          title: Text(
            'Staff Management',
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          surfaceTintColor: Colors.white,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    return Column(
                      children: [
                        _InfoCard(title: 'Total', value: '$total', subtitle: 'team members'),
                        const SizedBox(height: 8),
                        _InfoCard(title: 'Active', value: '$activeCount', subtitle: 'active members'),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: _InfoCard(title: 'Total', value: '$total', subtitle: 'team members')),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoCard(title: 'Active', value: '$activeCount', subtitle: 'active members')),
                        const Spacer(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 15),

              // Search + actions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 16),
                          hintText: 'Search staff...',
                          hintStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        style: GoogleFonts.poppins(fontSize: 11),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _exportStaff,
                      icon: const Icon(Icons.upload_file_outlined, size: 16),
                      label: Text('Export', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openAddStaff(),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('Add Staff', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Combined scrollable header and data rows
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          'No staff yet. Click "Add Staff" to create one.',
                          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 730, // Adjusted width to remove extra space
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header row with sorting
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min, // Use min to reduce extra space
                                        children: [
                                          // Name
                                          SizedBox(
                                            width: 200,
                                            child: InkWell(
                                              onTap: () => _sortBy(0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11)),
                                                  const SizedBox(width: 4),
                                                  if (_sortColumn == 0)
                                                    Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: Colors.black54),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Contact
                                          SizedBox(
                                            width: 120,
                                            child: Text('Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11)),
                                          ),
                                          const SizedBox(width: 10),
                                          // Position
                                          SizedBox(
                                            width: 140,
                                            child: InkWell(
                                              onTap: () => _sortBy(2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Position', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11)),
                                                  const SizedBox(width: 4),
                                                  if (_sortColumn == 2)
                                                    Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: Colors.black54),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Status
                                          SizedBox(
                                            width: 90,
                                            child: InkWell(
                                              onTap: () => _sortBy(3),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11)),
                                                  const SizedBox(width: 4),
                                                  if (_sortColumn == 3)
                                                    Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: Colors.black54),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Actions
                                          SizedBox(
                                            width: 70,
                                            child: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Data rows
                                    Flexible(
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: rows.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFEFEF)),
                                        itemBuilder: (context, idx) {
                                          final s = rows[idx];
                                          final actualIndex = staffList.indexOf(s);
                                          return Container(
                                            color: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min, // Use min to reduce extra space
                                              children: [
                                                // Name + email
                                                SizedBox(
                                                  width: 200,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 14,
                                                        backgroundImage: (s['image'] != null && s['image'].toString().isNotEmpty)
                                                            ? FileImage(File(s['image']))
                                                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                                        child: (s['image'] == null || s['image'].toString().isEmpty)
                                                            ? Text(
                                                                (s['firstName'] ?? '').toString().isNotEmpty
                                                                    ? (s['firstName'][0] ?? '')
                                                                    : '',
                                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              softWrap: false,
                                                            ),
                                                            const SizedBox(height: 1),
                                                            Text(
                                                              s['email'] ?? '',
                                                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              softWrap: false,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                // Contact
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    s['mobile'] ?? '',
                                                    style: GoogleFonts.poppins(fontSize: 10),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                // Position
                                                SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    s['position'] ?? '',
                                                    style: GoogleFonts.poppins(fontSize: 10),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                // Status
                                                SizedBox(
                                                  width: 90,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: (s['status'] == 'Inactive') ? Colors.grey[200] : Colors.green[50],
                                                        borderRadius: BorderRadius.circular(14),
                                                      ),
                                                      child: Text(
                                                        (s['status'] == 'Inactive') ? 'Inactive' : 'Active',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w600,
                                                          color: (s['status'] == 'Inactive') ? Colors.grey[800] : Colors.green[800],
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        softWrap: false,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                // Actions
                                                SizedBox(
                                                  width: 70,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined),
                                                        iconSize: 16,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints.tightFor(),
                                                        onPressed: () => _openAddStaff(existing: s, editIndex: actualIndex),
                                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                        iconSize: 16,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints.tightFor(),
                                                        onPressed: () => _deleteStaff(actualIndex),
                                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({required this.title, required this.value, required this.subtitle, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
        ]),
      ),
    );
  }
}
