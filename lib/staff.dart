import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'add_staff.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'dart:io' show HttpClient, X509Certificate;
import 'widgets/custom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Sort state (0=Name, 1=Contact, 2=Position, 3=Status)
  int? _sortColumn;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; 

      debugPrint('========== STAFF API DEBUG ==========');
      debugPrint('Token: $token');
      debugPrint('Token length: ${token.length}');
      debugPrint('---------------------------------------');

      if (token.isEmpty) {
        throw Exception('Auth token missing. Please login again.');
      }

      // Create an HTTP client that automatically handles cookies
      final ioClient = HttpClient();
      ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final cookieClient = http_io.IOClient(ioClient);
      
      final response = await cookieClient.get(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Cookie": "crm_access_token=$token",
        },
      );
      
      cookieClient.close(); // Close the client after use 

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        setState(() {
          staffList = data.map<Map<String, dynamic>>((item) {
            final fullName = item['fullName'] ?? '';
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
              'image': item['photo'],
              'raw': item,
            };
          }).toList();

          isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('STAFF API ERROR: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }


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
      if (editIndex != null) {
        await _updateStaff(result['id'], result);
      } else {
        await _createStaff(result);
      }
    }
  }
  
  Future<void> _createStaff(Map<String, dynamic> staffData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('Auth token missing. Please login again.');
      }
      
      // Create an HTTP client that automatically handles cookies
      final ioClient = HttpClient();
      ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final cookieClient = http_io.IOClient(ioClient);
      
      final response = await cookieClient.post(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(staffData),
      );
      
      cookieClient.close(); // Close the client after use
      
      if (response.statusCode == 201) {
        final newStaff = json.decode(response.body);
        
        // Process the new staff data similar to fetchStaff
        final fullName = newStaff['fullName'] ?? '';
        final parts = fullName.split(' ');
        
        final formattedStaff = {
          'id': newStaff['_id'],
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.last : '',
          'fullName': fullName,
          'email': newStaff['emailAddress'] ?? '',
          'mobile': newStaff['mobileNo'] ?? '',
          'position': newStaff['position'] ?? '',
          'status': newStaff['status'] ?? 'Active',
          'image': newStaff['photo'],
          'raw': newStaff,
        };
        
        setState(() {
          staffList.add(formattedStaff);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Staff member created successfully', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to create staff: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('CREATE STAFF ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error creating staff: $e', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _updateStaff(String staffId, Map<String, dynamic> staffData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('Auth token missing. Please login again.');
      }
      
      // Create an HTTP client that automatically handles cookies
      final ioClient = HttpClient();
      ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final cookieClient = http_io.IOClient(ioClient);
      
      final response = await cookieClient.put(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff/update/$staffId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Cookie": "crm_access_token=$token",
        },
        body: jsonEncode(staffData),
      );
      
      cookieClient.close(); // Close the client after use
      
      if (response.statusCode == 200) {
        final updatedStaff = json.decode(response.body);
        
        // Process the updated staff data similar to fetchStaff
        final fullName = updatedStaff['fullName'] ?? '';
        final parts = fullName.split(' ');
        
        final formattedStaff = {
          'id': updatedStaff['_id'],
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.last : '',
          'fullName': fullName,
          'email': updatedStaff['emailAddress'] ?? '',
          'mobile': updatedStaff['mobileNo'] ?? '',
          'position': updatedStaff['position'] ?? '',
          'status': updatedStaff['status'] ?? 'Active',
          'image': updatedStaff['photo'],
          'raw': updatedStaff,
        };
        
        setState(() {
          staffList[staffList.indexWhere((s) => s['id'] == staffId)] = formattedStaff;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Staff member updated successfully', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update staff: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('UPDATE STAFF ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error updating staff: $e', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteStaff(int index) async {
    final staffId = staffList[index]['id'];
    
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(dialogBackgroundColor: Colors.white),
        child: AlertDialog(
          title: Text('Delete staff', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to delete ${staffList[index]['fullName']}?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12))),
            TextButton(
              onPressed: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token') ?? '';
                  
                  if (token.isEmpty) {
                    throw Exception('Auth token missing. Please login again.');
                  }
                  
                  // Create an HTTP client that automatically handles cookies
                  final ioClient = HttpClient();
                  ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
                  final cookieClient = http_io.IOClient(ioClient);
                  
                  final response = await cookieClient.delete(
                    Uri.parse('https://partners.v2winonline.com/api/crm/staff/delete/$staffId'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                  );
                  
                  cookieClient.close(); // Close the client after use
                  
                  if (response.statusCode == 200 || response.statusCode == 204) {
                    setState(() {
                      staffList.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Staff member deleted successfully', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    final errorData = json.decode(response.body);
                    final errorMessage = errorData['message'] ?? 'Failed to delete staff: ${response.statusCode}';
                    throw Exception(errorMessage);
                  }
                } catch (e) {
                  debugPrint('DELETE STAFF ERROR: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Error deleting staff: $e', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (token.isEmpty) {
        throw Exception('Auth token missing. Please login again.');
      }
      
      // Create an HTTP client that automatically handles cookies
      final ioClient = HttpClient();
      ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final cookieClient = http_io.IOClient(ioClient);
      
      final response = await cookieClient.get(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff/export'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      cookieClient.close(); // Close the client after use
      
      if (response.statusCode == 200) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Staff exported successfully', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to export staff: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('EXPORT STAFF ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error exporting staff: $e', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchStaff,
              tooltip: 'Refresh',
            ),
          ],
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

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(errorMessage!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: fetchStaff,
                                  child: Text('Retry', style: GoogleFonts.poppins(fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        : rows.isEmpty
                            ? Center(
                                child: Text(
                                  'No staff found.',
                                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return Scrollbar(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: 730,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Header
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
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
                                                  SizedBox(
                                                    width: 120,
                                                    child: Text('Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11)),
                                                  ),
                                                  const SizedBox(width: 10),
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
                                                      mainAxisSize: MainAxisSize.min,
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
                                                                        s['firstName'].toString().isNotEmpty
                                                                            ? s['firstName'][0].toUpperCase()
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
                                                        SizedBox(
                                                          width: 120,
                                                          child: Text(
                                                            s['mobile'],
                                                            style: GoogleFonts.poppins(fontSize: 10),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        SizedBox(
                                                          width: 140,
                                                          child: Text(
                                                            s['position'],
                                                            style: GoogleFonts.poppins(fontSize: 10),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
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
                                                              IconButton(
                                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                                iconSize: 16,
                                                                padding: EdgeInsets.zero,
                                                                constraints: const BoxConstraints.tightFor(),
                                                                onPressed: () => _deleteStaff(actualIndex),
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