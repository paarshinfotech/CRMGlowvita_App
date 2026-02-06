// staff.dart (UPDATED - minimal changes)
// Fixes:
// 1) After create/update, refresh list so you see saved non-personal fields.
// 2) Keeps your existing API + cookie token behavior.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

import 'add_staff.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/staff_earnings_dialog.dart';

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

  Future<void> fetchStaff() async {
    debugPrint('=== Fetch Staff Process Started ===');

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<StaffMember> members = await ApiService.getStaff();
      debugPrint('Activities: Received ${members.length} staff members');

      setState(() {
        staffList = members.map<Map<String, dynamic>>((item) {
          final fullName = (item.fullName ?? '').toString();
          final parts = fullName.split(' ');
          return {
            'id': item.id,
            'firstName': parts.isNotEmpty ? parts.first : '',
            'lastName': parts.length > 1 ? parts.last : '',
            'fullName': fullName,
            'email': item.emailAddress ?? '',
            'mobile': item.mobileNo ?? '',
            'position': item.position ?? '',
            'status': item.status ?? 'Active',
            'image': item.photo, // used by UI avatar
            'raw': item.toJson(),
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR fetching staff: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load staff members: $e';
      });
    }
    debugPrint('=== Fetch Staff Process Completed ===');
  }

  Future<void> _openAddStaff(
      {Map<String, dynamic>? existing, int? editIndex}) async {
    final result = await showDialog<Map?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme)
              .apply(fontSizeFactor: 0.9),
        ),
        child: AddStaffDialog(existing: existing?['raw']),
      ),
    );

    if (result != null && result is Map) {
      if (editIndex != null) {
        await _updateStaff(
            result['id'].toString(), Map<String, dynamic>.from(result));
      } else {
        await _createStaff(Map<String, dynamic>.from(result));
      }

      // IMPORTANT: refresh after save so all saved data reflects
      await fetchStaff();
    }
  }

  Future<void> _createStaff(Map<String, dynamic> staffData) async {
    debugPrint('=== Staff Creation Process Started ===');
    debugPrint('Status: Preparing to create staff');
    debugPrint('Activities: Staff data keys: ${staffData.keys}');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('Authentication token missing.');
      debugPrint('Activities: Auth token retrieved successfully');

      final vendorId = prefs.getString('user_id') ?? '';
      if (vendorId.isEmpty)
        throw Exception('Vendor ID not found. Please login again.');
      debugPrint('Activities: Vendor ID retrieved: $vendorId');

      staffData['vendorId'] = vendorId;

      // Ensure permissions are included in the staff data
      if (!staffData.containsKey('permissions')) {
        staffData['permissions'] = staffData['permission'] ?? [];
      }
      debugPrint('Activities: Permissions: ${staffData['permissions']}');

      // Process availability data to match backend format
      if (staffData.containsKey('availability')) {
        final availability = staffData['availability'] as Map<String, dynamic>?;
        if (availability != null) {
          // Convert availability object to individual day fields
          for (final day in [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday'
          ]) {
            if (availability.containsKey(day)) {
              final dayData = availability[day] as Map<String, dynamic>?;
              if (dayData != null) {
                final available = dayData['available'] == true;
                final slots = (dayData['slots'] as List?) ?? [];

                staffData['${day}Available'] = available;
                staffData['${day}Slots'] = slots;

                debugPrint(
                    'Activities: Processed $day - Available: $available, Slots: $slots');
              } else {
                // Set default values if dayData is null
                staffData['${day}Available'] = false;
                staffData['${day}Slots'] = [];
              }
            } else {
              // Set default values if day is not in availability
              staffData['${day}Available'] = false;
              staffData['${day}Slots'] = [];
            }
          }
        }
        // Remove the original availability object since we've converted it
        staffData.remove('availability');
      }

      // Remove photo from data if it's a local file path (not URL)
      // The backend likely handles photo upload separately
      if (staffData.containsKey('photo') && staffData['photo'] != null) {
        if (!staffData['photo'].toString().startsWith('http')) {
          debugPrint(
              'Activities: Removing local photo path from request: ${staffData['photo']}');
          staffData.remove('photo');
        } else {
          debugPrint(
              'Activities: Keeping photo URL in request: ${staffData['photo']}');
        }
      }

      debugPrint('Status: Sending staff creation request to API');

      final response = await ApiService.createStaff(staffData);

      debugPrint('Activities: API Response status: ${response.statusCode}');
      debugPrint('Activities: API Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        debugPrint('Status: Staff created successfully');
        debugPrint('Activities: Server response: ${responseJson['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseJson['message'] ?? 'Staff created successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = json.decode(response.body);
        debugPrint(
            'Exception: API returned error status ${response.statusCode}');
        throw Exception(error['message'] ?? 'Failed to create staff');
      }
    } catch (e) {
      debugPrint('Exception: Error creating staff: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    debugPrint('=== Staff Creation Process Completed ===');
  }

  Future<void> _updateStaff(
      String staffId, Map<String, dynamic> staffData) async {
    try {
      debugPrint('UPDATE STAFF PAYLOAD: ${jsonEncode(staffData)}');

      final response = await ApiService.updateStaff(staffId, staffData);

      debugPrint('UPDATE STATUS: ${response.statusCode}');
      debugPrint('UPDATE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updatedStaff = json.decode(response.body);

        final fullName = updatedStaff['fullName'] ?? '';
        final parts = fullName.split(' ');

        final formattedStaff = {
          'id': updatedStaff['_id'],
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'fullName': fullName,
          'email': updatedStaff['emailAddress'] ?? '',
          'mobile': updatedStaff['mobileNo'] ?? '',
          'position': updatedStaff['position'] ?? '',
          'status': updatedStaff['status'] ?? 'Active',
          'image': updatedStaff['photo'],
          'raw': updatedStaff,
        };

        setState(() {
          final index = staffList.indexWhere((s) => s['id'] == staffId);
          if (index != -1) {
            staffList[index] = formattedStaff;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Staff member updated successfully',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ??
            'Failed to update staff: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('UPDATE STAFF ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error updating staff: $e',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteStaff(String staffId, String staffName) async {
    // Show confirmation dialog before deletion
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirm Delete',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Text(
                  'Are you sure you want to delete staff member "$staffName"? This action cannot be undone.',
                  style: GoogleFonts.poppins(fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete',
                      style: GoogleFonts.poppins(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmDelete) return; // If user cancels, do nothing

    try {
      final response = await ApiService.deleteStaff(staffId);

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseJson['message'] ?? 'Staff member deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh the staff list after successful deletion
        await fetchStaff();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ??
            'Failed to delete staff: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting staff: $e'),
          backgroundColor: Colors.red,
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
          return cmp(a['fullName'].toString().toLowerCase(),
              b['fullName'].toString().toLowerCase());
        case 1:
          return cmp((a['mobile'] ?? '').toString().toLowerCase(),
              (b['mobile'] ?? '').toString().toLowerCase());
        case 2:
          return cmp((a['position'] ?? '').toString().toLowerCase(),
              (b['position'] ?? '').toString().toLowerCase());
        case 3:
          return cmp((a['status'] ?? 'Active').toString().toLowerCase(),
              (b['status'] ?? 'Active').toString().toLowerCase());
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
        cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(fontSizeFactor: 0.8),
      ),
      child: Scaffold(
        drawer: const CustomDrawer(currentPage: 'Staff'),
        appBar: AppBar(
          title: Text(
            'Staff Management',
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          surfaceTintColor: Colors.white,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: fetchStaff,
                tooltip: 'Refresh'),
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
                        _InfoCard(
                            title: 'Total',
                            value: '$total',
                            subtitle: 'team members'),
                        const SizedBox(height: 8),
                        _InfoCard(
                            title: 'Active',
                            value: '$activeCount',
                            subtitle: 'active members'),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                          child: _InfoCard(
                              title: 'Total',
                              value: '$total',
                              subtitle: 'team members')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _InfoCard(
                              title: 'Active',
                              value: '$activeCount',
                              subtitle: 'active members')),
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
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
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
                      label: Text('Add Staff',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
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
                                Text(errorMessage!,
                                    style: GoogleFonts.poppins(
                                        color: Colors.red, fontSize: 12)),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                    onPressed: fetchStaff,
                                    child: Text('Retry',
                                        style:
                                            GoogleFonts.poppins(fontSize: 12))),
                              ],
                            ),
                          )
                        : rows.isEmpty
                            ? Center(
                                child: Text('No staff found.',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey[600], fontSize: 11)))
                            : Scrollbar(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 760,
                                    child: Column(
                                      children: [
                                        // header row
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 6),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            border: Border(
                                                bottom: BorderSide(
                                                    color: Color(0xFFEAEAEA),
                                                    width: 1)),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 200,
                                                child: InkWell(
                                                  onTap: () => _sortBy(0),
                                                  child: Row(
                                                    children: [
                                                      Text('Name',
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      11)),
                                                      const SizedBox(width: 4),
                                                      if (_sortColumn == 0)
                                                        Icon(
                                                            _sortAsc
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward,
                                                            size: 12,
                                                            color:
                                                                Colors.black54),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              SizedBox(
                                                  width: 120,
                                                  child: Text('Contact',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 11))),
                                              const SizedBox(width: 10),
                                              SizedBox(
                                                width: 140,
                                                child: InkWell(
                                                  onTap: () => _sortBy(2),
                                                  child: Row(
                                                    children: [
                                                      Text('Position',
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      11)),
                                                      const SizedBox(width: 4),
                                                      if (_sortColumn == 2)
                                                        Icon(
                                                            _sortAsc
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward,
                                                            size: 12,
                                                            color:
                                                                Colors.black54),
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
                                                      Text('Status',
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      11)),
                                                      const SizedBox(width: 4),
                                                      if (_sortColumn == 3)
                                                        Icon(
                                                            _sortAsc
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward,
                                                            size: 12,
                                                            color:
                                                                Colors.black54),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              SizedBox(
                                                  width: 100,
                                                  child: Text('Actions',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 11))),
                                            ],
                                          ),
                                        ),

                                        // data rows
                                        Flexible(
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: rows.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                                    height: 1,
                                                    color: Color(0xFFEFEFEF)),
                                            itemBuilder: (context, idx) {
                                              final s = rows[idx];
                                              final actualIndex =
                                                  staffList.indexOf(s);

                                              return Container(
                                                color: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 6),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 200,
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 14,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            child: (s['image'] !=
                                                                        null &&
                                                                    s['image']
                                                                        .toString()
                                                                        .isNotEmpty)
                                                                ? (s['image']
                                                                        .toString()
                                                                        .startsWith(
                                                                            'http')
                                                                    ? ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(14),
                                                                        child: Image
                                                                            .network(
                                                                          s['image'],
                                                                          width:
                                                                              28,
                                                                          height:
                                                                              28,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          errorBuilder: (context,
                                                                              error,
                                                                              stackTrace) {
                                                                            // If network image fails, show initial
                                                                            return Container(
                                                                              color: Colors.grey[300],
                                                                              child: Center(
                                                                                child: Text(
                                                                                  s['firstName'].toString().isNotEmpty ? s['firstName'][0].toUpperCase() : '',
                                                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.grey[300],
                                                                          borderRadius:
                                                                              BorderRadius.circular(14),
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            s['firstName'].toString().isNotEmpty
                                                                                ? s['firstName'][0].toUpperCase()
                                                                                : '',
                                                                            style:
                                                                                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10),
                                                                          ),
                                                                        ),
                                                                      ))
                                                                : Center(
                                                                    child: Text(
                                                                      s['firstName']
                                                                              .toString()
                                                                              .isNotEmpty
                                                                          ? s['firstName'][0]
                                                                              .toUpperCase()
                                                                          : '',
                                                                      style: GoogleFonts.poppins(
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontSize:
                                                                              10),
                                                                    ),
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Builder(
                                                                  builder:
                                                                      (context) {
                                                                    // Adding debug print for staff ID and name
                                                                    // This will be executed when the widget is built
                                                                    debugPrint(
                                                                        'Staff ID: ${s['id']}, Staff Name: ${s['fullName']}');
                                                                    return Text(
                                                                      s['fullName'],
                                                                      style: GoogleFonts.poppins(
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontSize:
                                                                              11),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    );
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    height: 1),
                                                                Text(
                                                                  s['email'],
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          10,
                                                                      color: Colors
                                                                              .grey[
                                                                          700]),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                        width: 120,
                                                        child: Text(s['mobile'],
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontSize:
                                                                        10),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                        width: 140,
                                                        child: Text(
                                                            s['position'],
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontSize:
                                                                        10),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                      width: 90,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: (s['status'] !=
                                                                    'Active')
                                                                ? Colors
                                                                    .grey[200]
                                                                : Colors
                                                                    .green[50],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        14),
                                                          ),
                                                          child: Text(
                                                            s['status'],
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: (s['status'] !=
                                                                      'Active')
                                                                  ? Colors
                                                                      .grey[800]
                                                                  : Colors.green[
                                                                      800],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                      width: 100,
                                                      child: Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons
                                                                .edit_outlined),
                                                            iconSize: 16,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints
                                                                    .tightFor(),
                                                            onPressed: () =>
                                                                _openAddStaff(
                                                                    existing: s,
                                                                    editIndex:
                                                                        actualIndex),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons
                                                                .visibility_outlined),
                                                            iconSize: 16,
                                                            color: const Color(
                                                                0xFF4A2C40),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints
                                                                    .tightFor(),
                                                            onPressed: () =>
                                                                _showEarningsDialog(
                                                                    s),
                                                            tooltip:
                                                                'View Earnings',
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons
                                                                .delete_outline),
                                                            iconSize: 16,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints
                                                                    .tightFor(),
                                                            onPressed: () =>
                                                                _deleteStaff(
                                                                    s['id'],
                                                                    s['fullName']),
                                                            color: Colors.red,
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

  void _showEarningsDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StaffEarningsDialog(staff: staff),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard(
      {required this.title,
      required this.value,
      required this.subtitle,
      Key? key})
      : super(key: key);

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
            Text(title,
                style:
                    GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
