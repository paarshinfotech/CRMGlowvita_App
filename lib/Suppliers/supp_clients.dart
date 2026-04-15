import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glowvita/supplier_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import '../customer_model.dart';
import '../appointment_model.dart';
import '../import_customers.dart';
import 'add_supp_clients.dart';
import '../Notification.dart';
import '../my_Profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'supp_drawer.dart';
import '../services/api_service.dart';
import '../widgets/customer_detail_popup.dart';
import '../widgets/subscription_wrapper.dart';
import 'supp_profile.dart';

class SuppClient extends StatefulWidget {
  const SuppClient({super.key});

  @override
  State<SuppClient> createState() => _SuppClientState();
}

class _SuppClientState extends State<SuppClient>
    with SingleTickerProviderStateMixin {
  List<Customer> customers = [];
  String _searchQuery = '';

  late TabController _tabController;
  int _currentTabIndex = 0;

  bool _isLoading = false;
  String? _errorMessage;
  SupplierProfile? _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        if (_currentTabIndex == 1) {
          _loadOnlineCustomers();
        } else {
          _loadCustomers();
        }
      }
    });

    _loadCustomers();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getSupplierProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Future<void> _fetchAndCalculateStats(List<Customer> currentCustomers) async {
    try {
      // Fetch appointments (using a reasonably large limit to get most relevant history)
      final appointmentResult = await ApiService.getAppointments(limit: 1000);
      final List<dynamic> allAppointments = appointmentResult['data'] ?? [];

      final List<Customer> updatedCustomers = [];

      for (var customer in currentCustomers) {
        // Filter appointments for this specific customer
        // We match by ID first, then fallback to mobile or email for robustness
        final clientAppointments = allAppointments.where((app) {
          if (app is! AppointmentModel) return false;

          final appCid = app.client?.id;
          if (appCid != null && customer.id != null && appCid == customer.id) {
            return true;
          }

          // Fallback matching
          if (app.client?.phone == customer.mobile) return true;
          if (customer.email != null && app.client?.email == customer.email)
            return true;

          return false;
        }).toList();

        int totalBookings = clientAppointments.length;
        double totalSpent = clientAppointments.fold<double>(0.0, (sum, app) {
          // Use finalAmount or totalAmount if available, fallback to amount
          if (app is AppointmentModel) {
            return sum +
                (app.finalAmount ?? app.totalAmount ?? app.amount ?? 0.0);
          }
          return sum;
        });

        updatedCustomers.add(customer.copyWith(
          totalBookings: totalBookings,
          totalSpent: totalSpent,
        ));
      }

      setState(() {
        customers = updatedCustomers;
      });
    } catch (e) {
      debugPrint('Error calculating client stats: $e');
      // If stats fetch fails, we still have the original customer list
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final loadedCustomers = await ApiService.getSupplierClients();
      setState(() {
        customers = loadedCustomers;
      });
      // After loading customers, fetch appointments to calculate stats
      await _fetchAndCalculateStats(loadedCustomers);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading customers: ${e.toString()}');
    }
  }

  Future<void> _loadOnlineCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final loadedCustomers = await ApiService.getOnlineSupplierClients();
      setState(() {
        customers = loadedCustomers;
      });
      // After loading online customers, fetch appointments to calculate stats
      await _fetchAndCalculateStats(loadedCustomers);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading online customers: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateAndAddSuppCustomer(BuildContext context) async {
    final newCustomer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (context) => const AddSuppCustomer()),
    );
    if (newCustomer != null) {
      try {
        final addedCustomer = await ApiService.addSupplierClient(newCustomer);
        setState(() => customers.add(addedCustomer));
      } catch (e) {
        debugPrint('Error adding customer: ${e.toString()}');
      }
    }
  }

  void _editCustomer(Customer customer) async {
    final editedCustomer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
          builder: (context) => AddSuppCustomer(existing: customer)),
    );
    if (editedCustomer != null) {
      try {
        final updatedCustomer =
            await ApiService.updateSupplierClient(editedCustomer);
        setState(() {
          final index = customers.indexWhere((c) => c.id == updatedCustomer.id);
          if (index != -1) customers[index] = updatedCustomer;
        });
      } catch (e) {
        debugPrint('Error updating customer: ${e.toString()}');
      }
    }
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete customer',
            style:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete ${customer.fullName}?',
          style: GoogleFonts.poppins(fontSize: 10),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 10))),
          TextButton(
            onPressed: () async {
              try {
                final success =
                    await ApiService.deleteSupplierClient(customer.id!);
                if (success) {
                  setState(() => customers.remove(customer));
                  Navigator.pop(ctx);
                }
              } catch (e) {
                Navigator.pop(ctx);
                debugPrint('Error deleting customer: ${e.toString()}');
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  List<Customer> get _filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    List<Customer> filtered = List<Customer>.from(customers);
    if (_currentTabIndex == 0) {
      filtered = filtered.where((c) => !c.isOnline).toList();
    } else {
      filtered = filtered.where((c) => c.isOnline).toList();
    }
    if (q.isEmpty) return filtered;
    return filtered.where((c) {
      final name = c.fullName.toLowerCase();
      final mobile = c.mobile.toLowerCase();
      final email = (c.email ?? '').toLowerCase();
      return name.contains(q) || mobile.contains(q) || email.contains(q);
    }).toList();
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) =>
          CustomerDetailPopup(customer: customer),
    );
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
          'Name\tEmail\tMobile\tBirth Day\tLast Visit\tTotal Bookings\tTotal Spent\tStatus');
      for (var customer in _filteredCustomers) {
        buffer.writeln(
            '${customer.fullName}\t${customer.email ?? ''}\t${customer.mobile}\t${customer.dateOfBirth ?? ''}\t${customer.lastVisit ?? 'Never'}\t${customer.totalBookings}\t${customer.totalSpent.toStringAsFixed(2)}\t${customer.status}');
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${_filteredCustomers.length} customers copied to clipboard!',
              style: GoogleFonts.poppins(fontSize: 10)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add([
        'Name',
        'Email',
        'Mobile',
        'Birth Day',
        'Last Visit',
        'Total Bookings',
        'Total Spent (₹)',
        'Status'
      ]);
      for (var customer in _filteredCustomers) {
        rows.add([
          customer.fullName,
          customer.email ?? '',
          customer.mobile,
          customer.dateOfBirth ?? '',
          customer.lastVisit ?? 'Never',
          customer.totalBookings.toString(),
          customer.totalSpent.toStringAsFixed(2),
          customer.status,
        ]);
      }
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/customers_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CSV exported successfully!',
              style: GoogleFonts.poppins(fontSize: 10)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path)),
          duration: const Duration(seconds: 5),
        ));
      }
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Customers'];
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#4A90E2'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
      var headers = [
        'Name',
        'Email',
        'Mobile',
        'Birth Day',
        'Last Visit',
        'Total Bookings',
        'Total Spent (₹)',
        'Status'
      ];
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      for (int i = 0; i < _filteredCustomers.length; i++) {
        var customer = _filteredCustomers[i];
        int rowIndex = i + 1;
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(customer.fullName);
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(customer.email ?? '');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(customer.mobile);
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(customer.dateOfBirth ?? '');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(customer.lastVisit ?? 'Never');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(customer.totalBookings.toString());
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(customer.totalSpent.toStringAsFixed(2));
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = TextCellValue(customer.status);
      }
      var directory = await getApplicationDocumentsDirectory();
      var filePath =
          '${directory.path}/customers_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Excel exported successfully!',
                style: GoogleFonts.poppins(fontSize: 10)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () => OpenFile.open(filePath)),
            duration: const Duration(seconds: 5),
          ));
        }
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text('Customers Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Text('Generated on: ${DateTime.now().toString().split('.')[0]}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('Total Customers: ${_filteredCustomers.length}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 25,
            headers: [
              'Name',
              'Email',
              'Mobile',
              'Birth Day',
              'Last Visit',
              'Bookings',
              'Spent',
              'Status'
            ],
            data: _filteredCustomers
                .map((customer) => [
                      customer.fullName,
                      customer.email ?? '',
                      customer.mobile,
                      customer.birthDay ?? '',
                      customer.lastVisit ?? 'Never',
                      customer.totalBookings.toString(),
                      '${customer.totalSpent.toStringAsFixed(2)}',
                      customer.status,
                    ])
                .toList(),
          ),
        ],
      ));
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/customers_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF exported successfully!',
              style: GoogleFonts.poppins(fontSize: 10)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(filePath)),
          duration: const Duration(seconds: 5),
        ));
      }
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
    }
  }

  Future<void> _exportToPrint() async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          pdf.addPage(pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) => [
              pw.Header(
                  level: 0,
                  child: pw.Text('Customers Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Generated on: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
              pw.Text('Total Customers: ${_filteredCustomers.length}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue700),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellHeight: 25,
                headers: [
                  'Name',
                  'Email',
                  'Mobile',
                  'Birth Day',
                  'Last Visit',
                  'Bookings',
                  'Spent',
                  'Status'
                ],
                data: _filteredCustomers
                    .map((customer) => [
                          customer.fullName,
                          customer.email ?? '',
                          customer.mobile,
                          customer.birthDay ?? '',
                          customer.lastVisit ?? 'Never',
                          customer.totalBookings.toString(),
                          '${customer.totalSpent.toStringAsFixed(2)}',
                          customer.status,
                        ])
                    .toList(),
              ),
            ],
          ));
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint('Error printing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = customers.length;
    final activeClients = customers.where((c) => c.status == 'Active').length;
    final totalBookings =
        customers.fold<int>(0, (sum, c) => sum + c.totalBookings);
    final totalRevenue =
        customers.fold<double>(0.0, (sum, c) => sum + c.totalSpent);
    final rows = _filteredCustomers;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(fontSizeFactor: 0.75),
      ),
      child: Scaffold(
        drawer: const SupplierDrawer(currentPage: 'Clients'),
        // No FAB button is inline now
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          titleSpacing: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.black, size: 20.sp),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'Client Management',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon:
                  Icon(Icons.notifications, size: 20.sp, color: Colors.black54),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationPage())),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const My_Profile())),
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
                          ((_profile?.shopName ?? '').isNotEmpty
                                  ? _profile!.shopName[0]
                                  : ' ')
                              .toUpperCase(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
            ),
          ],
        ),
        body: SubscriptionWrapper(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search,
                          size: 16.sp, color: Colors.grey[400]),
                      hintText: 'Search by name, email or phone...',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 10.sp, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 12.w),
                    ),
                    style: GoogleFonts.poppins(fontSize: 10.sp),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                SizedBox(height: 10.h),

                Row(children: [
                  Expanded(
                    child: Container(
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          tabBarTheme: const TabBarThemeData(
                            dividerColor: Colors.transparent,
                            dividerHeight: 0,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black54,
                          labelStyle: GoogleFonts.poppins(
                              fontSize: 10.sp, fontWeight: FontWeight.w600),
                          unselectedLabelStyle:
                              GoogleFonts.poppins(fontSize: 10.sp),
                          tabs: const [
                            Tab(text: 'Offline Client'),
                            Tab(text: 'Online Client'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
                SizedBox(height: 10.h),

                Row(children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.group_outlined,
                      iconColor: Colors.purple,
                      iconBg: Colors.purple[50]!,
                      title: 'Total Clients',
                      value: '$total',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person_outline,
                      iconColor: Colors.blue,
                      iconBg: Colors.blue[50]!,
                      title: 'Currently Active Clients',
                      value: '$activeClients',
                    ),
                  ),
                ]),
                SizedBox(height: 8.h),
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.pink,
                      iconBg: Colors.pink[50]!,
                      title: 'Total Bookings',
                      value: '$totalBookings',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.orange,
                      iconBg: Colors.orange[50]!,
                      title: 'Total Revenue',
                      value: '₹ ${totalRevenue.toStringAsFixed(2)}',
                    ),
                  ),
                ]),
                SizedBox(height: 8.h),

                // Export + Add Customer (right-aligned, after stats)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: _handleExport,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(children: [
                            Icon(Icons.copy,
                                size: 13.sp, color: Colors.grey[700]),
                            SizedBox(width: 8.w),
                            Text('Copy',
                                style: GoogleFonts.poppins(fontSize: 10.sp)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'csv',
                          child: Row(children: [
                            Icon(Icons.table_chart,
                                size: 13.sp, color: Colors.grey[700]),
                            SizedBox(width: 8.w),
                            Text('CSV',
                                style: GoogleFonts.poppins(fontSize: 10.sp)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(children: [
                            Icon(Icons.grid_on,
                                size: 13.sp, color: Colors.green[700]),
                            SizedBox(width: 8.w),
                            Text('Excel',
                                style: GoogleFonts.poppins(fontSize: 10.sp)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(children: [
                            Icon(Icons.picture_as_pdf,
                                size: 13.sp, color: Colors.red[700]),
                            SizedBox(width: 8.w),
                            Text('PDF',
                                style: GoogleFonts.poppins(fontSize: 10.sp)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: Row(children: [
                            Icon(Icons.print,
                                size: 13.sp, color: Colors.grey[700]),
                            SizedBox(width: 8.w),
                            Text('Print',
                                style: GoogleFonts.poppins(fontSize: 10.sp)),
                          ]),
                        ),
                      ],
                      child: Container(
                        height: 33.h,
                        padding: EdgeInsets.symmetric(horizontal: 11.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.upload_outlined,
                              size: 13.sp, color: Colors.black54),
                          SizedBox(width: 5.w),
                          Text('Export',
                              style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(width: 3.w),
                          Icon(Icons.keyboard_arrow_down,
                              size: 13.sp, color: Colors.black38),
                        ]),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (_currentTabIndex == 0)
                      GestureDetector(
                        onTap: () => _navigateAndAddSuppCustomer(context),
                        child: Container(
                          height: 33.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(7.r),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add, size: 14.sp, color: Colors.white),
                            SizedBox(width: 5.w),
                            Text('Add Customer',
                                style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Customer List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : rows.isEmpty
                          ? Center(
                              child: Text('No customers found.',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 10.sp)))
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, idx) {
                                final c = rows[idx];
                                return _CustomerCard(
                                  customer: c,
                                  onEdit: () => _editCustomer(c),
                                  onDelete: () => _deleteCustomer(c),
                                  onView: () =>
                                      _showCustomerDetails(context, c),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Stat Card
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
              blurRadius: 3),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ],
          ),
        ),
      ]),
    );
  }
}

// Customer Card
class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = customer.status == 'Active';
    final isNew = customer.status == 'New';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name/contact + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              customer.imagePath != null && customer.imagePath!.isNotEmpty
                  ? CircleAvatar(
                      radius: 26,
                      backgroundImage: customer.imagePath!.startsWith('http')
                          ? NetworkImage(customer.imagePath!) as ImageProvider
                          : FileImage(File(customer.imagePath!)),
                    )
                  : CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        customer.fullName.isNotEmpty
                            ? customer.fullName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[700]),
                      ),
                    ),
              const SizedBox(width: 12),

              // Name + contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (customer.email != null &&
                          customer.email!.isNotEmpty) ...[
                        Text(customer.email!,
                            style: GoogleFonts.poppins(
                                fontSize: 9, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis),
                        Text(' • ',
                            style: GoogleFonts.poppins(
                                fontSize: 9, color: Colors.grey[400])),
                      ],
                      Flexible(
                        child: Text(customer.mobile,
                            style: GoogleFonts.poppins(
                                fontSize: 9, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status badge green outlined pill like the screenshot
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green[50]
                      : isNew
                          ? Colors.pink[50]
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.green[400]!
                        : isNew
                            ? Colors.pink[300]!
                            : Colors.grey[300]!,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  customer.status,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.green[700]
                          : isNew
                              ? Colors.pink[700]
                              : Colors.grey[600]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 12),

          // Info grid: 2×2
          Row(children: [
            Expanded(
                child:
                    _infoCell('Birth Day', customer.dateOfBirth ?? 'Not set')),
            Expanded(
                child: _infoCell(
                    'Last Visit', customer.lastVisit ?? 'Not Visited')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _infoCell('Bookings', '${customer.totalBookings}')),
            Expanded(
                child: _infoCell('Total Spent',
                    '₹ ${customer.totalSpent.toStringAsFixed(2)}')),
          ]),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _iconBtn(Icons.visibility_outlined, Colors.grey[700]!, onView),
              const SizedBox(width: 8),
              _iconBtn(Icons.edit_outlined, Colors.blue[700]!, onEdit,
                  borderColor: Colors.blue.withValues(alpha: 0.25)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete_outline, Colors.red[700]!, onDelete,
                  borderColor: Colors.red.withValues(alpha: 0.25)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap,
          {Color? borderColor}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor ?? Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
