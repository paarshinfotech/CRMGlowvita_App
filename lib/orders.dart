import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'my_Profile.dart';
import 'Notification.dart';
import 'vendor_model.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<UIOrder> _allOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All Statuses';
  String _activeView = 'Orders';
  VendorProfile? _profile;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (_activeView == 'Orders') {
        final orders = await ApiService.getClientOrders();
        if (mounted) {
          setState(() {
            _allOrders = orders.map((o) => UIOrder.fromClient(o)).toList();
            _isLoading = false;
          });
        }
      } else {
        final orders = await ApiService.getOrders();
        if (mounted) {
          setState(() {
            _allOrders = orders.map((o) => UIOrder.fromB2B(o)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Export functions ──────────────────

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
      buffer.writeln('Order ID\tDate\tItems\tAmount\tAddress\tStatus');
      for (var order in filteredOrders) {
        final items = order.items.map((e) => e.name).join(', ');
        buffer.writeln(
          '${order.displayOrderId}\t${DateFormat('dd/MM/yyyy').format(order.createdAt)}\t$items\tRs.${order.totalAmount.toStringAsFixed(2)}\t${order.shippingAddress}\t${order.status}',
        );
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${filteredOrders.length} orders copied to clipboard!',
              style: GoogleFonts.poppins(fontSize: 10),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add([
        'Order ID',
        'Date',
        'Items',
        'Amount (₹)',
        'Address',
        'Status',
      ]);
      for (var order in filteredOrders) {
        final items = order.items.map((e) => e.name).join(', ');
        rows.add([
          order.displayOrderId,
          DateFormat('dd/MM/yyyy').format(order.createdAt),
          items,
          order.totalAmount.toStringAsFixed(2),
          order.shippingAddress,
          order.status,
        ]);
      }
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/orders_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV exported successfully!',
              style: GoogleFonts.poppins(fontSize: 10),
            ),
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
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Orders'];
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#4A90E2'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
      var headers = [
        'Order ID',
        'Date',
        'Items',
        'Amount (₹)',
        'Address',
        'Status',
      ];
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }
      for (int i = 0; i < filteredOrders.length; i++) {
        var order = filteredOrders[i];
        int rowIndex = i + 1;
        final items = order.items.map((e) => e.name).join(', ');
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          order.displayOrderId,
        );
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          DateFormat('dd/MM/yyyy').format(order.createdAt),
        );
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          items,
        );
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          order.totalAmount.toStringAsFixed(2),
        );
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          order.shippingAddress,
        );
        sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          order.status,
        );
      }
      var directory = await getApplicationDocumentsDirectory();
      var filePath =
          '${directory.path}/orders_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Excel exported successfully!',
                style: GoogleFonts.poppins(fontSize: 10),
              ),
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
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Orders Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on: ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Total Orders: ${filteredOrders.length}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 25,
              headers: ['Order ID', 'Date', 'Items', 'Amount', 'Status'],
              data: filteredOrders
                  .map(
                    (order) => [
                      order.displayOrderId,
                      DateFormat('dd/MM/yyyy').format(order.createdAt),
                      order.items.map((e) => e.name).join(', '),
                      'Rs.${order.totalAmount.toStringAsFixed(2)}',
                      order.status,
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF exported successfully!',
              style: GoogleFonts.poppins(fontSize: 10),
            ),
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
          pdf.addPage(
            pw.MultiPage(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Orders Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Total Orders: ${filteredOrders.length}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue700,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellHeight: 25,
                  headers: ['Order ID', 'Date', 'Items', 'Amount', 'Status'],
                  data: filteredOrders
                      .map(
                        (order) => [
                          order.displayOrderId,
                          DateFormat('dd/MM/yyyy').format(order.createdAt),
                          order.items.map((e) => e.name).join(', '),
                          'Rs.${order.totalAmount.toStringAsFixed(2)}',
                          order.status,
                        ],
                      )
                      .toList(),
                ),
              ],
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint('Error printing: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'packed':
        return Colors.purple;
      case 'processing':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  List<UIOrder> get filteredOrders {
    return _allOrders.where((order) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          order.displayOrderId.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          order.items.any(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      final matchesStatus =
          _selectedStatus == 'All Statuses' ||
          order.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Orders'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Orders Management',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const My_Profile()),
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: ClipOval(
                  child: (_profile != null && _profile!.profileImage.isNotEmpty)
                      ? Image.network(
                          _profile!.profileImage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => _buildInitialAvatar(),
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                              ? child
                              : const CircularProgressIndicator(),
                        )
                      : _buildInitialAvatar(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchOrders,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Track and manage all your orders in one place.',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Control Row (Search & Filters moved before stats)
                      _buildControlRow(),
                      const SizedBox(height: 24),

                      // Summary Cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.0,
                        children: [
                          _buildSummaryCard(
                            'Total Orders',
                            '${_allOrders.length}',
                            'All orders',
                            Icons.inventory_2_outlined,
                            const Color(0xFFF3F4F6),
                            const Color(0xFF4B5563),
                          ),
                          _buildSummaryCard(
                            'Pending',
                            '${_allOrders.where((o) => o.status.toLowerCase() == 'pending').length}',
                            'Awaiting processing',
                            Icons.shopping_cart_outlined,
                            const Color(0xFFF3F4F6),
                            const Color(0xFF4B5563),
                          ),
                          _buildSummaryCard(
                            'Shipped',
                            '${_allOrders.where((o) => o.status.toLowerCase() == 'shipped').length}',
                            'In transit',
                            Icons.local_shipping_outlined,
                            const Color(0xFFF3F4F6),
                            const Color(0xFF4B5563),
                          ),
                          _buildSummaryCard(
                            'Delivered',
                            '${_allOrders.where((o) => o.status.toLowerCase() == 'delivered').length}',
                            'Successfully delivered',
                            Icons.check_circle_outline,
                            const Color(0xFFF3F4F6),
                            const Color(0xFF4B5563),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Order List (Cards)
                      _buildOrdersList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    String subtext,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            subtext,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Search Bar (Full width)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search orders, products...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tabs / Toggles (Centered and wider)
            Center(
              child: Container(
                width: constraints.maxWidth * 0.8,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildToggleButton('Orders', Icons.shopping_cart)),
                    Expanded(
                      child: _buildToggleButton(
                        'My Purchases',
                        Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown and Export Button (Separate line)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        items: [
                          'All Statuses',
                          'Pending',
                          'Processing',
                          'Packed',
                          'Shipped',
                          'Delivered',
                          'Cancelled',
                        ].map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            )).toList(),
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  onSelected: _handleExport,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          const Icon(Icons.copy, size: 16, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text('Copy to Clipboard',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          const Icon(Icons.table_chart,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text('Export to CSV',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excel',
                      child: Row(
                        children: [
                          const Icon(Icons.grid_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text('Export to Excel',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text('Export to PDF',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'print',
                      child: Row(
                        children: [
                          const Icon(Icons.print, size: 16, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text('Print Report',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleButton(String label, IconData icon) {
    bool isActive = _activeView == label;
    return GestureDetector(
      onTap: () {
        if (_activeView != label) {
          setState(() {
            _activeView = label;
            _allOrders = [];
          });
          _fetchOrders();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final filtered = filteredOrders;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No orders found',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(UIOrder order) {
    final status = order.status;
    final statusColor = _getStatusColor(status);
    final itemsText = order.items.map((e) => e.name).join(', ');
    final itemsCount = order.items.length;

    return GestureDetector(
      onTap: () => _showOrderDetailDialog(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayOrderId,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order created on ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    itemsText,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  ' $itemsCount item(s)',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.shippingAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(
                          'Update Status',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        items:
                            [
                                  'Pending',
                                  'Processing',
                                  'Packed',
                                  'Shipped',
                                  'Delivered',
                                  'Cancelled',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _handleStatusUpdate(order, val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showOrderDetailDialog(order),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleStatusUpdate(UIOrder order, String newStatus) async {
    final TextEditingController trackingController = TextEditingController();
    final TextEditingController courierController = TextEditingController();

    if (newStatus == 'Shipped') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Shipping Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courierController,
                decoration: InputDecoration(
                  labelText: 'Courier Name *',
                  hintText: 'e.g. BlueDart',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
              TextField(
                controller: trackingController,
                decoration: InputDecoration(
                  labelText: 'Tracking Number *',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (courierController.text.isNotEmpty &&
                    trackingController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      setState(() => _isLoading = true);
      await ApiService.updateOrderStatus(
        orderId: order.displayOrderId,
        status: newStatus,
        trackingNumber: trackingController.text,
        courier: courierController.text,
        isClientOrder: order.isClientOrder,
      );
      _fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showOrderDetailDialog(UIOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Container(
            width: 800.w,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Order ID: ${order.displayOrderId}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Order Progress
                        _buildProgressTracker(order.status),
                        const SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isNarrow = constraints.maxWidth < 600;
                            return isNarrow
                                ? Column(
                                    children: [
                                      _buildSectionTitle(
                                        'Items Ordered (${order.items.length})',
                                        Icons.shopping_cart_outlined,
                                      ),
                                      const SizedBox(height: 12),
                                      ...order.items
                                          .map((item) => _buildOrderItem(item))
                                          .toList(),
                                      const SizedBox(height: 24),
                                      _buildTotalAmountSection(
                                        order.totalAmount,
                                      ),
                                      const SizedBox(height: 32),
                                      _buildSideInfoCard(
                                        'Shipping Address',
                                        Icons.location_on_outlined,
                                        order.shippingAddress,
                                      ),
                                      _buildShippingDetailsCard(order),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Main content (Left)
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildSectionTitle(
                                              'Items Ordered (${order.items.length})',
                                              Icons.shopping_cart_outlined,
                                            ),
                                            const SizedBox(height: 12),
                                            ...order.items
                                                .map(
                                                  (item) =>
                                                      _buildOrderItem(item),
                                                )
                                                .toList(),
                                            const SizedBox(height: 24),
                                            _buildTotalAmountSection(
                                              order.totalAmount,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // Sidebar content (Right)
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            _buildSideInfoCard(
                                              'Shipping Address',
                                              Icons.location_on_outlined,
                                              order.shippingAddress,
                                            ),
                                            _buildShippingDetailsCard(order),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShippingDetailsCard(UIOrder order) {
    final hasShipping = order.courier != null && order.courier!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Shipping Details',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasShipping) ...[
            _buildDetailItem('Courier', order.courier!),
            const SizedBox(height: 8),
            _buildDetailItem('Tracking #', order.trackingNumber ?? 'N/A'),
          ] else
            Text(
              'No shipping details available yet.',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String currentStatus) {
    final statuses = [
      'Pending',
      'Processing',
      'Packed',
      'Shipped',
      'Delivered',
    ];
    int currentIndex = statuses.indexWhere(
      (s) => s.toLowerCase() == currentStatus.toLowerCase(),
    );

    // If not found in primary flow, check for Cancelled
    if (currentIndex == -1 && currentStatus.toLowerCase() == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'Order Cancelled',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: Color(0xFF1F2937),
              ),
              const SizedBox(width: 8),
              Text(
                'Order Progress',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(statuses.length, (index) {
              bool isDone = index <= currentIndex;

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            isDone
                                ? Icons.check
                                : _getStatusIcon(statuses[index]),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          statuses[index],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: isDone
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isDone
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (index != statuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: index < currentIndex
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Processing':
        return Icons.sync;
      case 'Packed':
        return Icons.inventory_2;
      case 'Shipped':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.home;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(UIOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              image: item.image != null
                  ? DecorationImage(
                      image: NetworkImage(item.image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.image == null
                ? Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey.shade400,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Qty: ${item.quantity}  ₹${item.price.toStringAsFixed(2)} each',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountSection(double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideInfoCard(String title, IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UIOrder {
  final String id;
  final String displayOrderId;
  final String status;
  final double totalAmount;
  final String shippingAddress;
  final DateTime createdAt;
  final List<UIOrderItem> items;
  final String? courier;
  final String? trackingNumber;
  final bool isClientOrder;

  UIOrder({
    required this.id,
    required this.displayOrderId,
    required this.status,
    required this.totalAmount,
    required this.shippingAddress,
    required this.createdAt,
    required this.items,
    this.courier,
    this.trackingNumber,
    required this.isClientOrder,
  });

  factory UIOrder.fromB2B(B2BOrder order) => UIOrder(
    id: order.id,
    displayOrderId: order.orderId,
    status: order.status,
    totalAmount: order.totalAmount,
    shippingAddress: order.shippingAddress,
    createdAt: order.createdAt,
    items: order.items
        .map(
          (i) => UIOrderItem(
            name: i.productName,
            quantity: i.quantity,
            price: i.price,
          ),
        )
        .toList(),
    courier: order.courier,
    trackingNumber: order.trackingNumber,
    isClientOrder: false,
  );

  factory UIOrder.fromClient(ClientOrder order) => UIOrder(
    id: order.id,
    displayOrderId: order.id,
    status: order.status,
    totalAmount: order.totalAmount,
    shippingAddress: order.shippingAddress,
    createdAt: order.createdAt,
    items: order.items
        .map(
          (i) => UIOrderItem(
            name: i.name,
            quantity: i.quantity,
            price: i.price,
            image: i.image,
          ),
        )
        .toList(),
    courier: order.courier,
    trackingNumber: order.trackingNumber,
    isClientOrder: true,
  );
}

class UIOrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? image;
  UIOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
  });
}
