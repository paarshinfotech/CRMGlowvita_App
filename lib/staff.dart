import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';

import 'services/api_service.dart';
import 'add_staff.dart';
import 'widgets/custom_drawer.dart';
import 'vendor_model.dart';
import 'my_Profile.dart';
import 'widgets/staff_earnings_dialog.dart';
import 'widgets/subscription_wrapper.dart';

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
  String _selectedPosition = 'All Positions';
  String _selectedCommission = 'All Commission';

  int? _sortColumn;
  bool _sortAsc = true;
  VendorProfile? _profile;

  @override
  void initState() {
    super.initState();
    fetchStaff();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
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

      List<Map<String, dynamic>> tempStaffList = [];

      for (var item in members) {
        final fullName = (item.fullName ?? '').toString();
        final parts = fullName.split(' ');

        double balance = 0.0;
        double commission = item.commissionPercentage ?? 0.0;

        try {
          final earnings = await ApiService.getStaffEarnings(item.id ?? '');
          if (earnings['summary'] != null) {
            balance = (earnings['summary']['balance'] ?? 0.0).toDouble();
          }
          if (commission == 0.0) {
            if (earnings['commissionDetails'] != null) {
              commission =
                  (earnings['commissionDetails']['rate'] ?? 0.0).toDouble();
            } else if (earnings['summary'] != null &&
                earnings['summary']['commissionRate'] != null) {
              commission =
                  (earnings['summary']['commissionRate'] ?? 0.0).toDouble();
            }
          }
        } catch (e) {
          debugPrint('Failed to load earnings for ${item.id}: $e');
        }

        tempStaffList.add({
          'id': item.id,
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.last : '',
          'fullName': fullName,
          'email': item.emailAddress ?? '',
          'mobile': item.mobileNo ?? '',
          'position': item.position ?? '',
          'status': item.status ?? 'Active',
          'image': item.photo,
          'raw': item.toJson(),
          'balance': balance,
          'isCommissionEnabled': item.commission == true,
          'commissionRate': commission,
        });
      }

      setState(() {
        staffList = tempStaffList;
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
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(ctx).textTheme)
              .apply(fontSizeFactor: 0.9),
        ),
        child: AddStaffDialog(existing: existing?['raw']),
      ),
    );

    if (result != null) {
      if (editIndex != null) {
        await _updateStaff(
            result['id'].toString(), Map<String, dynamic>.from(result));
      } else {
        await _createStaff(Map<String, dynamic>.from(result));
      }
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

      if (!staffData.containsKey('permissions')) {
        staffData['permissions'] = staffData['permission'] ?? [];
      }
      debugPrint('Activities: Permissions: ${staffData['permissions']}');

      if (staffData.containsKey('availability')) {
        final availability = staffData['availability'] as Map<String, dynamic>?;
        if (availability != null) {
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
                staffData['${day}Available'] = false;
                staffData['${day}Slots'] = [];
              }
            } else {
              staffData['${day}Available'] = false;
              staffData['${day}Slots'] = [];
            }
          }
        }
        staffData.remove('availability');
      }

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
      if (staffData.containsKey('availability')) {
        final availability = staffData['availability'] as Map<String, dynamic>?;
        if (availability != null) {
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
              } else {
                staffData['${day}Available'] = false;
                staffData['${day}Slots'] = [];
              }
            } else {
              staffData['${day}Available'] = false;
              staffData['${day}Slots'] = [];
            }
          }
        }
        staffData.remove('availability');
      }

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
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
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
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteStaff(String staffId, String staffName) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirm Delete',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Text(
                  'Are you sure you want to delete staff member "$staffName"? This action cannot be undone.',
                  style: GoogleFonts.poppins(fontSize: 10)),
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

    if (!confirmDelete) return;

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
    List<Map<String, dynamic>> result = List.from(staffList);

    // Apply search filter
    if (q.isNotEmpty) {
      result = result.where((s) {
        final name = s['fullName'].toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final phone = (s['mobile'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }

    // Apply position filter
    if (_selectedPosition != 'All Positions') {
      result = result.where((s) => s['position'] == _selectedPosition).toList();
    }

    // Apply commission filter
    if (_selectedCommission == 'Commission Enabled') {
      result = result.where((s) => s['isCommissionEnabled'] == true).toList();
    } else if (_selectedCommission == 'Commission Disabled') {
      result = result.where((s) => s['isCommissionEnabled'] != true).toList();
    }

    return result;
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
    final commissionActiveCount =
        staffList.where((s) => s['isCommissionEnabled'] == true).length;

    double pendingPayoutsSum = 0;
    for (var s in staffList) {
      pendingPayoutsSum += (s['balance'] ?? 0.0);
    }

    final rows = _applySort(_filteredStaff);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardColor: Colors.white,
        cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            margin: EdgeInsets.zero),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(fontSizeFactor: 0.75),
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
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
          surfaceTintColor: Colors.white,
          actions: [
            IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () {},
                tooltip: 'Search'),
            IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: fetchStaff,
                tooltip: 'Refresh'),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => My_Profile())),
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: CircleAvatar(
                  radius: 14.r,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage:
                      (_profile != null && _profile!.profileImage.isNotEmpty)
                          ? NetworkImage(_profile!.profileImage)
                          : null,
                  child: (_profile == null || _profile!.profileImage.isEmpty)
                      ? Text(
                          (_profile?.businessName ?? 'H')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        body: SubscriptionWrapper(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search bar and filters
                Column(
                  children: [
                    // Search bar - Full width
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search,
                              size: 18, color: Colors.grey[400]),
                          hintText: 'Search by name or email....',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                        style: GoogleFonts.poppins(fontSize: 11),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filters row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPosition,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: Colors.grey[600]),
                              underline: const SizedBox(),
                              isExpanded: true,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.black87),
                              items: [
                                'All Positions',
                                'Senior Stylist',
                                'Junior Barber',
                                'Manager'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPosition =
                                      newValue ?? 'All Positions';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCommission,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: Colors.grey[600]),
                              underline: const SizedBox(),
                              isExpanded: true,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.black87),
                              items: [
                                'All Commission',
                                'Commission Enabled',
                                'Commission Disabled'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCommission =
                                      newValue ?? 'All Commission';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleExport(value),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy,
                                      size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 8),
                                  Text('Copy',
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'csv',
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart,
                                      size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 8),
                                  Text('CSV',
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'excel',
                              child: Row(
                                children: [
                                  Icon(Icons.grid_on,
                                      size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Text('Excel',
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf,
                                      size: 16, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Text('PDF',
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'print',
                              child: Row(
                                children: [
                                  Icon(Icons.print,
                                      size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 8),
                                  Text('Print',
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(
                                'Export',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats Cards - 2x2 Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.group_outlined,
                        iconColor: Colors.blue,
                        iconBg: Colors.blue[50]!,
                        title: 'Total Team Members',
                        value: '$total',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.person_outline,
                        iconColor: Colors.purple,
                        iconBg: Colors.purple[50]!,
                        title: 'Currently Active Members',
                        value: '$activeCount',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up,
                        iconColor: Colors.green,
                        iconBg: Colors.green[50]!,
                        title: 'Staff Earning Commission',
                        value: '$commissionActiveCount',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.orange,
                        iconBg: Colors.orange[50]!,
                        title: 'Total Balance Due',
                        value: '₹ ${pendingPayoutsSum.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Staff List
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
                                          color: Colors.red, fontSize: 9)),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                      onPressed: fetchStaff,
                                      child: Text('Retry',
                                          style: GoogleFonts.poppins(
                                              fontSize: 9))),
                                ],
                              ),
                            )
                          : rows.isEmpty
                              ? Center(
                                  child: Text('No staff found.',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 9)))
                              : ListView.separated(
                                  itemCount: rows.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final s = rows[idx];
                                    final actualIndex = staffList.indexOf(s);

                                    return _StaffCard(
                                      staff: s,
                                      onEdit: () => _openAddStaff(
                                          existing: s, editIndex: actualIndex),
                                      onDelete: () =>
                                          _deleteStaff(s['id'], s['fullName']),
                                      onViewEarnings: () =>
                                          _showEarningsDialog(s),
                                      onSendCredentials: () =>
                                          _sendCredentials(s),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddStaff(),
          backgroundColor: Theme.of(context).primaryColor,
          label: Text(
            'Add Staff',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
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

  Future<void> _sendCredentials(Map<String, dynamic> staff) async {
    final staffId = staff['id']?.toString() ?? '';
    if (staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff ID not found.',
              style: GoogleFonts.poppins(fontSize: 10)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('Sending credentials...',
                  style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await ApiService.sendStaffCredentials(staffId);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Credentials sent to ${staff['email'] ?? staff['fullName']}!'
                  : 'Failed to send credentials.',
              style: GoogleFonts.poppins(fontSize: 10),
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: $e', style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleExport(String type) {
    switch (type) {
      case 'copy':
        _exportToCopy();
        break;
      case 'csv':
        _exportToCSV();
        break;
      case 'excel':
        _exportToExcel();
        break;
      case 'pdf':
        _exportToPDF();
        break;
      case 'print':
        _exportToPrint();
        break;
    }
  }

  Future<void> _exportToCopy() async {
    try {
      StringBuffer buffer = StringBuffer();
      buffer.writeln(
          'Name\tEmail\tMobile\tPosition\tStatus\tCommission Rate\tBalance');

      for (var staff in _filteredStaff) {
        buffer.writeln(
            '${staff['fullName']}\t${staff['email']}\t${staff['mobile']}\t${staff['position']}\t${staff['status']}\t${staff['commissionRate']?.toStringAsFixed(1) ?? '0'}%\t₹${staff['balance']?.toStringAsFixed(2) ?? '0.00'}');
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_filteredStaff.length} staff members copied to clipboard!',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Name',
        'Email',
        'Mobile',
        'Position',
        'Status',
        'Commission Rate (%)',
        'Balance (₹)'
      ]);

      // Data rows
      for (var staff in _filteredStaff) {
        rows.add([
          staff['fullName'] ?? '',
          staff['email'] ?? '',
          staff['mobile'] ?? '',
          staff['position'] ?? '',
          staff['status'] ?? 'Active',
          staff['commissionRate']?.toStringAsFixed(1) ?? '0',
          staff['balance']?.toStringAsFixed(2) ?? '0.00',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/staff_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);

      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully!',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Automatically open the file
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Staff'];

      // Set column widths
      sheetObject.setColumnWidth(0, 20); // Name
      sheetObject.setColumnWidth(1, 30); // Email
      sheetObject.setColumnWidth(2, 15); // Mobile
      sheetObject.setColumnWidth(3, 20); // Position
      sheetObject.setColumnWidth(4, 12); // Status
      sheetObject.setColumnWidth(5, 15); // Commission
      sheetObject.setColumnWidth(6, 12); // Balance

      // Header style
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#4A90E2'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // Add headers
      var headers = [
        'Name',
        'Email',
        'Mobile',
        'Position',
        'Status',
        'Commission Rate (%)',
        'Balance (₹)'
      ];
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      for (int i = 0; i < _filteredStaff.length; i++) {
        var staff = _filteredStaff[i];
        int rowIndex = i + 1;

        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(staff['fullName'] ?? '');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(staff['email'] ?? '');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(staff['mobile'] ?? '');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(staff['position'] ?? '');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(staff['status'] ?? 'Active');
        sheetObject
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 5, rowIndex: rowIndex))
                .value =
            TextCellValue(staff['commissionRate']?.toStringAsFixed(1) ?? '0');
        sheetObject
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 6, rowIndex: rowIndex))
                .value =
            TextCellValue(staff['balance']?.toStringAsFixed(2) ?? '0.00');
      }

      // Save file
      var directory = await getApplicationDocumentsDirectory();
      var filePath =
          '${directory.path}/staff_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel exported successfully!',
                  style: GoogleFonts.poppins(fontSize: 10)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () => OpenFile.open(filePath),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Automatically open the file
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Excel: $e',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Staff Members Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Summary info
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                'Total Staff: ${_filteredStaff.length}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
                headers: [
                  'Name',
                  'Email',
                  'Mobile',
                  'Position',
                  'Status',
                  'Commission %',
                  'Balance'
                ],
                data: _filteredStaff.map((staff) {
                  return [
                    staff['fullName'] ?? '',
                    staff['email'] ?? '',
                    staff['mobile'] ?? '',
                    staff['position'] ?? '',
                    staff['status'] ?? 'Active',
                    '${staff['commissionRate']?.toStringAsFixed(1) ?? '0'}%',
                    '₹${staff['balance']?.toStringAsFixed(2) ?? '0.00'}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/staff_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully!',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(filePath),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Automatically open the file
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportToPrint() async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();

          pdf.addPage(
            pw.MultiPage(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) {
                return [
                  // Title
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'Staff Members Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Summary
                  pw.Text(
                    'Generated on: ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Total Staff: ${_filteredStaff.length}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 20),

                  // Table
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.blue700,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellHeight: 30,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                      3: pw.Alignment.centerLeft,
                      4: pw.Alignment.center,
                      5: pw.Alignment.centerRight,
                      6: pw.Alignment.centerRight,
                    },
                    headers: [
                      'Name',
                      'Email',
                      'Mobile',
                      'Position',
                      'Status',
                      'Commission %',
                      'Balance'
                    ],
                    data: _filteredStaff.map((staff) {
                      return [
                        staff['fullName'] ?? '',
                        staff['email'] ?? '',
                        staff['mobile'] ?? '',
                        staff['position'] ?? '',
                        staff['status'] ?? 'Active',
                        '${staff['commissionRate']?.toStringAsFixed(1) ?? '0'}%',
                        '₹${staff['balance']?.toStringAsFixed(2) ?? '0.00'}',
                      ];
                    }).toList(),
                  ),
                ];
              },
            ),
          );

          return pdf.save();
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print dialog opened',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: $e',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// New Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// New Staff Card Widget
class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewEarnings;
  final VoidCallback onSendCredentials;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
    required this.onViewEarnings,
    required this.onSendCredentials,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = staff['status'] ?? 'Active';
    final isActive = status == 'Active';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Profile, Name/Email, Status
          Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[200],
                backgroundImage: (staff['image'] != null &&
                        staff['image'].toString().isNotEmpty &&
                        staff['image'].toString().startsWith('http'))
                    ? NetworkImage(staff['image'])
                    : null,
                child: (staff['image'] == null ||
                        staff['image'].toString().isEmpty ||
                        !staff['image'].toString().startsWith('http'))
                    ? Text(
                        staff['firstName'].toString().isNotEmpty
                            ? staff['firstName'][0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name, Email, Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['fullName'] ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${staff['email'] ?? ''} • ${staff['mobile'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Position and Action Icons
          Row(
            children: [
              // Position with icon
              Row(
                children: [
                  Icon(Icons.work_outline, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    staff['position'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Action Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onViewEarnings,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.currency_rupee,
                          size: 16, color: Colors.green[700]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onSendCredentials,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.blue[50],
                      ),
                      child: Icon(Icons.email_outlined,
                          size: 16, color: Colors.blue[700]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
