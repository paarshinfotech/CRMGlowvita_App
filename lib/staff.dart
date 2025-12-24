// staff.dart (UPDATED - minimal changes)
// Fixes:
// 1) After create/update, refresh list so you see saved non-personal fields.
// 2) Keeps your existing API + cookie token behavior.

import 'dart:convert';
import 'dart:io' show HttpClient, X509Certificate;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:shared_preferences/shared_preferences.dart';

import 'add_staff.dart';
import 'widgets/custom_drawer.dart';

class Staff extends StatefulWidget {
  const Staff({Key? key}) : super(key: key);

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  List<Map<String, dynamic>> staffList = [];
  bool isLoading = true;
  String? errorMessage;
  String _searchQuery = '';

  int? _sortColumn;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  http_io.IOClient _cookieClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return http_io.IOClient(ioClient);
  }

  Future<void> fetchStaff() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('Auth token missing. Please login again.');

      final client = _cookieClient();
      final response = await client.get(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Cookie": "crm_access_token=$token",
        },
      );
      client.close();

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          staffList = data.map<Map<String, dynamic>>((item) {
            final fullName = (item['fullName'] ?? '').toString();
            final parts = fullName.split(' ');
            return {
              'id': item['_id'],
              'firstName': parts.isNotEmpty ? parts.first : '',
              'lastName': parts.length > 1 ? parts.last : '',
              'fullName': fullName,
              'email': item['emailAddress'] ?? '',
              'mobile': item['mobileNo'] ?? '',
              'position': item['position'] ?? '',
              'status': item['status'] ?? 'Active',
              'image': item['photo'], // used by UI avatar
              'raw': item,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _openAddStaff({Map<String, dynamic>? existing, int? editIndex}) async {
    final result = await showDialog<Map?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme).apply(fontSizeFactor: 0.9),
        ),
        child: AddStaffDialog(existing: existing?['raw']),
      ),
    );

    if (result != null && result is Map) {
      if (editIndex != null) {
        await _updateStaff(result['id'].toString(), Map<String, dynamic>.from(result));
      } else {
        await _createStaff(Map<String, dynamic>.from(result));
      }

      // IMPORTANT: refresh after save so all saved data reflects
      await fetchStaff();
    }
  }

  Future<void> _createStaff(Map<String, dynamic> staffData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; 
      if (token.isEmpty) throw Exception('Authentication token missing.');

      final vendorId = prefs.getString('user_id') ?? '';
      if (vendorId.isEmpty) throw Exception('Vendor ID not found. Please login again.');

      staffData['vendorId'] = vendorId;

      final response = await http.post(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Cookie": "crm_access_token=$token",
        },
        body: jsonEncode(staffData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseJson['message'] ?? 'Staff created successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create staff');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateStaff(String staffId, Map<String, dynamic> staffData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('Auth token missing. Please login again.');

      final client = _cookieClient();
      final response = await client.put(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff/update/$staffId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Cookie": "crm_access_token=$token",
        },
        body: jsonEncode(staffData),
      );
      client.close();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Staff member updated successfully', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update staff: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error updating staff: $e', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredStaff {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List.from(staffList);
    return staffList.where((s) {
      final name = s['fullName'].toString().toLowerCase();
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
          return cmp(a['fullName'].toString().toLowerCase(), b['fullName'].toString().toLowerCase());
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
    final activeCount = staffList.where((s) => s['status'] == 'Active').length;
    final rows = _applySort(_filteredStaff);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        cardTheme: const CardThemeData(color: Colors.white, surfaceTintColor: Colors.white, elevation: 0, margin: EdgeInsets.zero),
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
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: fetchStaff, tooltip: 'Refresh'),
          ],
        ),
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
                  }
                  return Row(
                    children: [
                      Expanded(child: _InfoCard(title: 'Total', value: '$total', subtitle: 'team members')),
                      const SizedBox(width: 10),
                      Expanded(child: _InfoCard(title: 'Active', value: '$activeCount', subtitle: 'active members')),
                      const Spacer(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 15),
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
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (errorMessage != null)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(errorMessage!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                                const SizedBox(height: 10),
                                ElevatedButton(onPressed: fetchStaff, child: Text('Retry', style: GoogleFonts.poppins(fontSize: 12))),
                              ],
                            ),
                          )
                        : rows.isEmpty
                            ? Center(child: Text('No staff found.', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11)))
                            : Scrollbar(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 730,
                                    child: Column(
                                      children: [
                                        // header row
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1)),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 200,
                                                child: InkWell(
                                                  onTap: () => _sortBy(0),
                                                  child: Row(
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
                                              SizedBox(width: 120, child: Text('Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11))),
                                              const SizedBox(width: 10),
                                              SizedBox(
                                                width: 140,
                                                child: InkWell(
                                                  onTap: () => _sortBy(2),
                                                  child: Row(
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
                                              SizedBox(
                                                width: 90,
                                                child: InkWell(
                                                  onTap: () => _sortBy(3),
                                                  child: Row(
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
                                              SizedBox(width: 70, child: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11))),
                                            ],
                                          ),
                                        ),

                                        // data rows
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
                                                  children: [
                                                    SizedBox(
                                                      width: 200,
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 14,
                                                            backgroundImage: (s['image'] != null && s['image'].toString().isNotEmpty)
                                                                ? NetworkImage(s['image'])
                                                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                                            child: (s['image'] == null || s['image'].toString().isEmpty)
                                                                ? Text(
                                                                    s['firstName'].toString().isNotEmpty ? s['firstName'][0].toUpperCase() : '',
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
                                                                  s['fullName'],
                                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 1),
                                                                Text(
                                                                  s['email'],
                                                                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    SizedBox(width: 120, child: Text(s['mobile'], style: GoogleFonts.poppins(fontSize: 10), overflow: TextOverflow.ellipsis)),
                                                    const SizedBox(width: 10),
                                                    SizedBox(width: 140, child: Text(s['position'], style: GoogleFonts.poppins(fontSize: 10), overflow: TextOverflow.ellipsis)),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                      width: 90,
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: (s['status'] != 'Active') ? Colors.grey[200] : Colors.green[50],
                                                            borderRadius: BorderRadius.circular(14),
                                                          ),
                                                          child: Text(
                                                            s['status'],
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w600,
                                                              color: (s['status'] != 'Active') ? Colors.grey[800] : Colors.green[800],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                      width: 70,
                                                      child: Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit_outlined),
                                                            iconSize: 16,
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints.tightFor(),
                                                            onPressed: () => _openAddStaff(existing: s, editIndex: actualIndex),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
