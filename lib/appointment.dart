import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glowvita/my_Profile.dart';
import 'package:glowvita/widgets/create_appointment_form.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'Notification.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'appointment_model.dart';
import 'widgets/collect_payment_dialog.dart';
import 'widgets/appointment_detail_dialog.dart';
import 'vendor_model.dart';
import 'widgets/subscription_wrapper.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

enum QuickDateRange {
  today,
  tomorrow,
  yesterday,
  next7Days,
  last7Days,
  next30Days,
  last30Days,
  last90Days,
  lastMonth,
  lastYear,
  allTime,
}

class Appointment extends StatefulWidget {
  const Appointment({super.key});

  @override
  State<Appointment> createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? _selectedDateRange;
  String? _selectedClient, _selectedService, _selectedStaff;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  // ── Backend data — NOT MODIFIED ─────────────────────
  List<AppointmentModel> _apiAppointments = [];
  bool _isLoading = true;
  Set<String> _uniqueClients = {};
  Set<String> _uniqueServices = {};
  Set<String> _uniqueStaff = {};

  // Pagination
  int _currentPage = 1;
  int _limit = 10;
  int _totalCount = 0;
  final List<int> _limitOptions = [5, 10, 15, 20, 25, 50];
  VendorProfile? _profile;

  final ScrollController _scrollController = ScrollController();

  final List<String> statuses = [
    'All',
    'scheduled',
    'confirmed',
    'in_progress',
    'completed',
    'completed_without_payment',
    'cancelled',
  ];

  // Derived pagination flags
  bool get _hasPrev => _currentPage > 1;
  bool get _hasNext => (_currentPage * _limit) < _totalCount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAppointments();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      print(
          '📥 Fetching appointments (Page: $_currentPage, Limit: $_limit)...');
      final result =
          await ApiService.getAppointments(page: _currentPage, limit: _limit);

      final List<AppointmentModel> appointments = result['data'] ?? [];
      final int total = result['total'] ?? 0;

      setState(() {
        _apiAppointments = appointments;
        _totalCount = total;
        _isLoading = false;
        _uniqueClients = appointments
            .map((a) => a.clientName ?? 'Unknown')
            .where((name) => name.isNotEmpty)
            .toSet();
        _uniqueServices = appointments
            .map((a) => a.serviceName ?? 'Unknown')
            .where((name) => name.isNotEmpty)
            .toSet();
        _uniqueStaff = appointments
            .map((a) => a.staffName ?? 'Unassigned')
            .where((name) => name.isNotEmpty)
            .toSet();
      });
      print('✅ Loaded ${appointments.length} appointments. Total: $total');
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red));
      }
    }
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
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  List<AppointmentModel> get _filteredAppointments {
    return _apiAppointments.where((appt) {
      final scheduled = appt.date;
      final inRange = _selectedDateRange == null ||
          scheduled == null ||
          (scheduled.isAfter(_selectedDateRange!.start
                  .subtract(const Duration(days: 1))) &&
              scheduled.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1))));

      final searchMatch = _searchQuery.isEmpty ||
          (appt.clientName
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (appt.serviceName
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (appt.staffName?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final clientMatch =
          _selectedClient == null || appt.clientName == _selectedClient;
      final serviceMatch =
          _selectedService == null || appt.serviceName == _selectedService;
      final staffMatch =
          _selectedStaff == null || appt.staffName == _selectedStaff;
      final statusMatch = _selectedStatus == 'All' ||
          (appt.status?.toLowerCase() == _selectedStatus.toLowerCase());

      return inRange &&
          searchMatch &&
          clientMatch &&
          serviceMatch &&
          staffMatch &&
          statusMatch;
    }).toList();
  }

  void _editAppointment(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (context) => CreateAppointmentForm(existingAppointment: appt),
    ).then((_) => _fetchAppointments());
  }

  void _confirmDelete(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Appointment',
            style: GoogleFonts.poppins(
                fontSize: 12.sp, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this appointment?',
            style: GoogleFonts.poppins(fontSize: 10.sp)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: GoogleFonts.poppins(fontSize: 10.sp))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (appt.id != null) _deleteAppointment(appt.id!);
              },
              child: Text('Delete',
                  style:
                      GoogleFonts.poppins(fontSize: 10.sp, color: Colors.red))),
        ],
      ),
    );
  }

  void _showCollectPaymentDialog(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (context) => CollectPaymentDialog(appointment: appt),
    ).then((result) {
      if (result != null) {
        print('Payment Collected: $result');
        _fetchAppointments();
      }
    });
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      print('🗑️ Deleting: $id');
      await ApiService.deleteAppointment(id);
      await _fetchAppointments();
      print('✅ Deleted');
    } catch (e) {
      print('❌ Failed: $e');
    }
  }

  void _goToPage(int page) {
    if (page < 1) return;
    setState(() {
      _currentPage = page;
      _isLoading = true;
    });
    _fetchAppointments();
    // Scroll to top of list
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  // ══════════════════════════════════════════════════
  // EXPORT FUNCTIONS
  // ══════════════════════════════════════════════════

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
          'Date\tTime\tClient\tService\tStaff\tStatus\tAmount Paid\tTotal Amount\tPayment Status');

      for (var appt in _filteredAppointments) {
        final dateStr = appt.date != null
            ? DateFormat('MMM d, yyyy').format(appt.date!)
            : '-';
        final timeStr = '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';
        final paid = appt.amountPaid ?? 0;
        final total = appt.totalAmount ?? appt.amount ?? 0;
        final paymentStatus = paid >= total && total > 0
            ? 'Paid'
            : paid > 0
                ? 'Partial'
                : 'Unpaid';

        buffer.writeln(
            '$dateStr\t$timeStr\t${appt.clientName ?? 'Unknown'}\t${appt.serviceName ?? '-'}\t${appt.staffName ?? '-'}\t${appt.status ?? 'Schedule'}\t₹${paid.toStringAsFixed(2)}\t₹${total.toStringAsFixed(2)}\t$paymentStatus');
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_filteredAppointments.length} appointments copied to clipboard!',
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
        'Date',
        'Time',
        'Client',
        'Service',
        'Staff',
        'Status',
        'Amount Paid (₹)',
        'Total Amount (₹)',
        'Payment Status'
      ]);

      // Data rows
      for (var appt in _filteredAppointments) {
        final dateStr = appt.date != null
            ? DateFormat('MMM d, yyyy').format(appt.date!)
            : '-';
        final timeStr = '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';
        final paid = appt.amountPaid ?? 0;
        final total = appt.totalAmount ?? appt.amount ?? 0;
        final paymentStatus = paid >= total && total > 0
            ? 'Paid'
            : paid > 0
                ? 'Partial'
                : 'Unpaid';

        rows.add([
          dateStr,
          timeStr,
          appt.clientName ?? 'Unknown',
          appt.serviceName ?? '-',
          appt.staffName ?? '-',
          appt.status ?? 'Schedule',
          paid.toStringAsFixed(2),
          total.toStringAsFixed(2),
          paymentStatus,
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/appointments_export_${DateTime.now().millisecondsSinceEpoch}.csv';
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
      Sheet sheetObject = excel['Appointments'];

      // Set column widths
      sheetObject.setColumnWidth(0, 15); // Date
      sheetObject.setColumnWidth(1, 20); // Time
      sheetObject.setColumnWidth(2, 25); // Client
      sheetObject.setColumnWidth(3, 30); // Service
      sheetObject.setColumnWidth(4, 20); // Staff
      sheetObject.setColumnWidth(5, 15); // Status
      sheetObject.setColumnWidth(6, 15); // Amount Paid
      sheetObject.setColumnWidth(7, 15); // Total Amount
      sheetObject.setColumnWidth(8, 15); // Payment Status

      // Header style
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#4A90E2'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // Add headers
      var headers = [
        'Date',
        'Time',
        'Client',
        'Service',
        'Staff',
        'Status',
        'Amount Paid (₹)',
        'Total Amount (₹)',
        'Payment Status'
      ];
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      for (int i = 0; i < _filteredAppointments.length; i++) {
        var appt = _filteredAppointments[i];
        int rowIndex = i + 1;

        final dateStr = appt.date != null
            ? DateFormat('MMM d, yyyy').format(appt.date!)
            : '-';
        final timeStr = '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';
        final paid = appt.amountPaid ?? 0;
        final total = appt.totalAmount ?? appt.amount ?? 0;
        final paymentStatus = paid >= total && total > 0
            ? 'Paid'
            : paid > 0
                ? 'Partial'
                : 'Unpaid';

        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(dateStr);
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(timeStr);
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(appt.clientName ?? 'Unknown');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(appt.serviceName ?? '-');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(appt.staffName ?? '-');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(appt.status ?? 'Schedule');
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(paid.toStringAsFixed(2));
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = TextCellValue(total.toStringAsFixed(2));
        sheetObject
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
            .value = TextCellValue(paymentStatus);
      }

      // Save file
      var directory = await getApplicationDocumentsDirectory();
      var filePath =
          '${directory.path}/appointments_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Appointments Report',
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
                'Total Appointments: ${_filteredAppointments.length}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),

              // Table
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
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.centerRight,
                  8: pw.Alignment.center,
                },
                headers: [
                  'Date',
                  'Time',
                  'Client',
                  'Service',
                  'Staff',
                  'Status',
                  'Paid',
                  'Total',
                  'Payment'
                ],
                data: _filteredAppointments.map((appt) {
                  final dateStr = appt.date != null
                      ? DateFormat('MMM d, yyyy').format(appt.date!)
                      : '-';
                  final timeStr =
                      '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';
                  final paid = appt.amountPaid ?? 0;
                  final total = appt.totalAmount ?? appt.amount ?? 0;
                  final paymentStatus = paid >= total && total > 0
                      ? 'Paid'
                      : paid > 0
                          ? 'Partial'
                          : 'Unpaid';

                  return [
                    dateStr,
                    timeStr,
                    appt.clientName ?? 'Unknown',
                    appt.serviceName ?? '-',
                    appt.staffName ?? '-',
                    appt.status ?? 'Schedule',
                    '₹${paid.toStringAsFixed(2)}',
                    '₹${total.toStringAsFixed(2)}',
                    paymentStatus,
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
          '${directory.path}/appointments_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
                      'Appointments Report',
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
                    'Total Appointments: ${_filteredAppointments.length}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 20),

                  // Table
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
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                      3: pw.Alignment.centerLeft,
                      4: pw.Alignment.centerLeft,
                      5: pw.Alignment.center,
                      6: pw.Alignment.centerRight,
                      7: pw.Alignment.centerRight,
                      8: pw.Alignment.center,
                    },
                    headers: [
                      'Date',
                      'Time',
                      'Client',
                      'Service',
                      'Staff',
                      'Status',
                      'Paid',
                      'Total',
                      'Payment'
                    ],
                    data: _filteredAppointments.map((appt) {
                      final dateStr = appt.date != null
                          ? DateFormat('MMM d, yyyy').format(appt.date!)
                          : '-';
                      final timeStr =
                          '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';
                      final paid = appt.amountPaid ?? 0;
                      final total = appt.totalAmount ?? appt.amount ?? 0;
                      final paymentStatus = paid >= total && total > 0
                          ? 'Paid'
                          : paid > 0
                              ? 'Partial'
                              : 'Unpaid';

                      return [
                        dateStr,
                        timeStr,
                        appt.clientName ?? 'Unknown',
                        appt.serviceName ?? '-',
                        appt.staffName ?? '-',
                        appt.status ?? 'Schedule',
                        '₹${paid.toStringAsFixed(2)}',
                        '₹${total.toStringAsFixed(2)}',
                        paymentStatus,
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

  // ── Color helpers ─────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'schedule':
        return const Color(0xFFE65100);
      case 'confirmed':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'completed_without_payment':
        return Colors.brown;
      case 'cancelled':
        return const Color(0xFFC62828);
      case 'in_progress':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF616161);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'schedule':
        return const Color(0xFFFFF3E0);
      case 'confirmed':
        return const Color(0xFFE3F2FD);
      case 'completed_without_payment':
        return const Color(0xFFFFF3E0);
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      case 'in_progress':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  // ── Micro widgets ─────────────────────────────────
  Widget _statusChip(String status) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: _statusBg(status),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(status.capitalize(),
            style: GoogleFonts.poppins(
                fontSize: 7.sp,
                fontWeight: FontWeight.w700,
                color: _statusColor(status))),
      );

  Widget _paymentChip(AppointmentModel appt) {
    final paid = appt.amountPaid ?? 0;
    final total = appt.totalAmount ?? appt.amount ?? 0;
    String label;
    Color bg, text;
    if (paid >= total && total > 0) {
      label = 'Paid';
      bg = const Color(0xFFE8F5E9);
      text = const Color(0xFF2E7D32);
    } else if (paid > 0) {
      label = 'Partial';
      bg = const Color(0xFFFFF3E0);
      text = const Color(0xFFE65100);
    } else {
      label = 'Unpaid';
      bg = const Color(0xFFFFEBEE);
      text = const Color(0xFFC62828);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 7.sp, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _statCard({
    required String label,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) =>
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(children: [
            Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(6.r)),
              child: Icon(icon, size: 12.sp, color: iconColor),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(count,
                      style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.black)),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 6.5.sp, color: Colors.grey.shade500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _serviceRow(String service, String staff) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: Row(children: [
          Expanded(
              child: Text(service,
                  style: GoogleFonts.poppins(
                      fontSize: 9.sp, color: Colors.black87),
                  overflow: TextOverflow.ellipsis)),
          SizedBox(width: 4.w),
          Icon(Icons.person_outline,
              size: 8.sp,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.6)),
          SizedBox(width: 2.w),
          Text(staff,
              style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _actionBtn(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 3.w),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 8.sp, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _buildDropdown<T>({
    required String hint,
    required List<T> items,
    T? selectedValue,
    required ValueChanged<T?> onChanged,
    double? width,
  }) {
    return Container(
      width: width,
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selectedValue,
          hint: Text(hint,
              style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.grey)),
          isExpanded: false,
          icon:
              Icon(Icons.keyboard_arrow_down, size: 12.sp, color: Colors.grey),
          style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString().capitalize(),
                        style: GoogleFonts.poppins(fontSize: 8.sp)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() => Row(children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(7.r),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<QuickDateRange>(
              underline: const SizedBox(),
              hint: Text('Quick Range',
                  style: GoogleFonts.poppins(fontSize: 9.sp)),
              onChanged: (range) {
                if (range == null) return;
                final now = DateTime.now();
                DateTime start, end;
                switch (range) {
                  case QuickDateRange.today:
                    start = end = now;
                    break;
                  case QuickDateRange.tomorrow:
                    start = end = now.add(const Duration(days: 1));
                    break;
                  case QuickDateRange.yesterday:
                    start = end = now.subtract(const Duration(days: 1));
                    break;
                  case QuickDateRange.next7Days:
                    start = now;
                    end = now.add(const Duration(days: 7));
                    break;
                  case QuickDateRange.last7Days:
                    start = now.subtract(const Duration(days: 7));
                    end = now;
                    break;
                  case QuickDateRange.next30Days:
                    start = now;
                    end = now.add(const Duration(days: 30));
                    break;
                  case QuickDateRange.last30Days:
                    start = now.subtract(const Duration(days: 30));
                    end = now;
                    break;
                  case QuickDateRange.last90Days:
                    start = now.subtract(const Duration(days: 90));
                    end = now;
                    break;
                  case QuickDateRange.lastMonth:
                    start = DateTime(now.year, now.month - 1, 1);
                    end = DateTime(now.year, now.month, 0);
                    break;
                  case QuickDateRange.lastYear:
                    start = DateTime(now.year - 1, 1, 1);
                    end = DateTime(now.year - 1, 12, 31);
                    break;
                  case QuickDateRange.allTime:
                    start = DateTime(2000);
                    end = DateTime(2100);
                    break;
                }
                setState(() =>
                    _selectedDateRange = DateTimeRange(start: start, end: end));
              },
              items: QuickDateRange.values.map((e) {
                final label = e.name
                    .replaceAllMapped(
                        RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
                    .capitalize();
                return DropdownMenuItem(
                  value: e,
                  child:
                      Text(label, style: GoogleFonts.poppins(fontSize: 9.sp)),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).primaryColor, width: 1),
                borderRadius: BorderRadius.circular(7.r),
                color: Colors.white,
              ),
              child: Row(children: [
                Icon(Icons.date_range,
                    size: 10.sp, color: Theme.of(context).primaryColor),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}'
                        : 'Pick Range',
                    style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ),
              ]),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: () => setState(() => _selectedDateRange = null),
          child: Icon(Icons.clear, color: Colors.grey.shade400, size: 13.sp),
        ),
      ]);

  // ── Appointment card ──────────────────────────────
  Widget _buildAppointmentCard(AppointmentModel appt) {
    final dateStr =
        appt.date != null ? DateFormat('MMM d, yyyy').format(appt.date!) : '-';
    final timeStr = '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';
    final items = appt.serviceItems ?? [];
    final initials = (appt.clientName ?? 'U').substring(0, 1).toUpperCase();

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AppointmentDetailDialog(appointmentId: appt.id!),
      ).then((_) => _fetchAppointments()),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 5.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  child: Text(initials,
                      style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor)),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt.clientName ?? 'Unknown',
                            style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        SizedBox(height: 1.h),
                        Row(children: [
                          Icon(Icons.access_time,
                              size: 8.sp, color: Colors.grey.shade400),
                          SizedBox(width: 2.w),
                          Flexible(
                            child: Text('$dateStr • $timeStr',
                                style: GoogleFonts.poppins(
                                    fontSize: 7.5.sp,
                                    color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        if (appt.isWeddingService == true) ...[
                          SizedBox(height: 3.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: Colors.pink.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                  color: Colors.pink.withValues(alpha: 0.25)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.auto_awesome,
                                  size: 7.sp, color: Colors.pink),
                              SizedBox(width: 2.w),
                              Text('Wedding',
                                  style: GoogleFonts.poppins(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.pink)),
                            ]),
                          ),
                        ],
                      ]),
                ),
                Builder(builder: (context) {
                  String displayStatus = appt.status ?? 'Schedule';
                  if (displayStatus.toLowerCase() == 'completed' && appt.paymentStatus != 'completed') {
                    displayStatus = 'completed_without_payment';
                  }
                  return _statusChip(displayStatus);
                }),
              ],
            ),
          ),

          // Services
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            color: const Color(0xFFF8F9FA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Services & Staff',
                    style: GoogleFonts.poppins(
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.4)),
                SizedBox(height: 3.h),
                if (appt.isWeddingService == true &&
                    appt.weddingPackageDetails != null)
                  _serviceRow(
                      appt.weddingPackageDetails?.packageName ??
                          'Wedding Package',
                      'Wedding Team')
                else
                  ...items.isEmpty
                      ? [
                          _serviceRow(
                              appt.serviceName ?? '—', appt.staffName ?? '—')
                        ]
                      : items
                          .map((item) => _serviceRow(
                              '${item.serviceName} (${item.duration} min)',
                              item.staffName ?? '—'))
                          .toList(),
                if (appt.addOns != null && appt.addOns!.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text('Add-ons',
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.4)),
                  SizedBox(height: 2.h),
                  ...appt.addOns!.map((addon) => Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('+ ${addon.name ?? 'Add-on'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87)),
                              Text('₹${addon.price?.toStringAsFixed(0) ?? '0'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      color: Colors.grey.shade600)),
                            ]),
                      )),
                ],
              ],
            ),
          ),

          // Payment footer
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 5.h, 10.w, 3.h),
            child: Row(children: [
              _paymentChip(appt),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: 'Paid: ',
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp, color: Colors.grey.shade400)),
                  TextSpan(
                      text: '₹${appt.amountPaid?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.poppins(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32))),
                ])),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: 'Total: ',
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp, color: Colors.grey.shade400)),
                  TextSpan(
                      text:
                          '₹${(appt.totalAmount ?? appt.amount ?? 0).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ])),
                if (appt.paymentMethod != null)
                  Text(appt.paymentMethod!,
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp, color: Colors.grey.shade400)),
              ]),
            ]),
          ),

          // Actions
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100))),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            child: Builder(builder: (context) {
              bool isCancelled = appt.status?.toLowerCase().contains('cancelled') ?? false;
              bool isPaymentPending = appt.paymentStatus == 'pending';
              bool isCompletedWithoutPayment = appt.status == 'completed_without_payment';
              bool isAmountRemaining = (appt.amountPaid ?? 0) < (appt.totalAmount ?? appt.amount ?? 0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if ((isPaymentPending || isCompletedWithoutPayment || isAmountRemaining) && !isCancelled)
                    _actionBtn(
                        Icons.payments_outlined,
                        'Pay',
                        const Color(0xFF2E7D32),
                        () => _showCollectPaymentDialog(appt)),
                  _actionBtn(
                      Icons.edit_outlined,
                      'Edit',
                      Theme.of(context).primaryColor,
                      () => _editAppointment(appt)),
                  _actionBtn(Icons.delete_outline, 'Delete',
                      const Color(0xFFC62828), () => _confirmDelete(appt)),
                ],
              );
            }),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final scheduledCount = _apiAppointments
        .where((a) => a.status?.toLowerCase() == 'scheduled')
        .length;
    final confirmedCount = _apiAppointments
        .where((a) => a.status?.toLowerCase() == 'confirmed')
        .length;
    final completedCount = _apiAppointments
        .where((a) => a.status?.toLowerCase() == 'completed')
        .length;
    final cancelledCount = _apiAppointments
        .where((a) => a.status?.toLowerCase() == 'cancelled')
        .length;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Appointments'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 42.h,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black87, size: 18.sp),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text('Appointments',
            style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                size: 16.sp, color: Colors.black54),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const My_Profile())),
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: CircleAvatar(
                radius: 13.r,
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
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SubscriptionWrapper(
        child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),

              // ── Search & Filter Section ────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  children: [
                    // Row 1: Search
                    Container(
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.poppins(fontSize: 9.sp),
                        decoration: InputDecoration(
                          hintText: 'Search Client or Service...',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 8.sp, color: Colors.grey),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey, size: 13.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 6.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Row 2: Date Selector
                    _buildDateRangeSelector(),
                    SizedBox(height: 6.h),

                    // Row 3: Horizontal Scrollable Dropdowns
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _buildDropdown<String>(
                          hint: 'Status',
                          selectedValue:
                              _selectedStatus == 'All' ? null : _selectedStatus,
                          items: statuses.where((s) => s != 'All').toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStatus = v ?? 'All'),
                        ),
                        if (_selectedStatus != 'All')
                          IconButton(
                            icon: Icon(Icons.clear, size: 12.sp),
                            onPressed: () =>
                                setState(() => _selectedStatus = 'All'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        SizedBox(width: 5.w),
                        _buildDropdown<String>(
                          hint: 'Client',
                          selectedValue: _selectedClient,
                          items: _uniqueClients.toList(),
                          onChanged: (v) => setState(() => _selectedClient = v),
                        ),
                        if (_selectedClient != null)
                          IconButton(
                            icon: Icon(Icons.clear, size: 12.sp),
                            onPressed: () =>
                                setState(() => _selectedClient = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        SizedBox(width: 5.w),
                        _buildDropdown<String>(
                          hint: 'Service',
                          selectedValue: _selectedService,
                          items: _uniqueServices.toList(),
                          onChanged: (v) =>
                              setState(() => _selectedService = v),
                        ),
                        if (_selectedService != null)
                          IconButton(
                            icon: Icon(Icons.clear, size: 12.sp),
                            onPressed: () =>
                                setState(() => _selectedService = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        SizedBox(width: 5.w),
                        _buildDropdown<String>(
                          hint: 'Staff',
                          selectedValue: _selectedStaff,
                          items: _uniqueStaff.toList(),
                          onChanged: (v) => setState(() => _selectedStaff = v),
                        ),
                        if (_selectedStaff != null)
                          IconButton(
                            icon: Icon(Icons.clear, size: 12.sp),
                            onPressed: () =>
                                setState(() => _selectedStaff = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              // ── 2×2 Stat Cards ───────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(children: [
                  Row(children: [
                    _statCard(
                      label: 'All Scheduled\nAppointments',
                      count: '$scheduledCount',
                      icon: Icons.event_note_outlined,
                      iconColor: const Color(0xFF1565C0),
                      iconBg: const Color(0xFFE3F2FD),
                    ),
                    SizedBox(width: 6.w),
                    _statCard(
                      label: 'Upcoming Confirmed\nBookings',
                      count: '$confirmedCount',
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF2E7D32),
                      iconBg: const Color(0xFFE8F5E9),
                    ),
                  ]),
                  SizedBox(height: 6.h),
                  Row(children: [
                    _statCard(
                      label: 'Successfully\nCompleted',
                      count: '$completedCount',
                      icon: Icons.done_all,
                      iconColor: const Color(0xFF00796B),
                      iconBg: const Color(0xFFE0F2F1),
                    ),
                    SizedBox(width: 6.w),
                    _statCard(
                      label: 'Cancelled by Client\nor Staff',
                      count: '$cancelledCount',
                      icon: Icons.cancel_outlined,
                      iconColor: const Color(0xFFC62828),
                      iconBg: const Color(0xFFFFEBEE),
                    ),
                  ]),
                ]),
              ),

              SizedBox(height: 8.h),

              // Export Button Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleExport(value),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_download_outlined,
                                size: 14.sp, color: Colors.blue[700]),
                            SizedBox(width: 4.w),
                            Text('Export',
                                style: GoogleFonts.poppins(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700])),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy,
                                  size: 14.sp, color: Colors.grey[700]),
                              SizedBox(width: 8.w),
                              Text('Copy',
                                  style: GoogleFonts.poppins(fontSize: 10.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'csv',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart,
                                  size: 14.sp, color: Colors.grey[700]),
                              SizedBox(width: 8.w),
                              Text('CSV',
                                  style: GoogleFonts.poppins(fontSize: 10.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.grid_on,
                                  size: 14.sp, color: Colors.green[700]),
                              SizedBox(width: 8.w),
                              Text('Excel',
                                  style: GoogleFonts.poppins(fontSize: 10.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf,
                                  size: 14.sp, color: Colors.red[700]),
                              SizedBox(width: 8.w),
                              Text('PDF',
                                  style: GoogleFonts.poppins(fontSize: 10.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print,
                                  size: 14.sp, color: Colors.grey[700]),
                              SizedBox(width: 8.w),
                              Text('Print',
                                  style: GoogleFonts.poppins(fontSize: 10.sp)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),
              // List header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Appointments List',
                        style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text('$_totalCount',
                          style: GoogleFonts.poppins(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 6.h),

              // Appointment cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _filteredAppointments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text('No appointments found.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.sp, color: Colors.grey)),
                            ),
                          )
                        : Column(
                            children: _filteredAppointments
                                .map(_buildAppointmentCard)
                                .toList(),
                          ),
              ),

              // ── Pagination ───────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show N per page
                    Row(children: [
                      Text('Show',
                          style: GoogleFonts.poppins(
                              fontSize: 8.sp, color: Colors.grey.shade500)),
                      SizedBox(width: 5.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(5.r),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _limit,
                            isDense: true,
                            items: _limitOptions
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.toString(),
                                          style: GoogleFonts.poppins(
                                              fontSize: 8.sp)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _limit = v;
                                  _currentPage = 1;
                                  _isLoading = true;
                                });
                                _fetchAppointments();
                              }
                            },
                            icon: Icon(Icons.arrow_drop_down, size: 13.sp),
                          ),
                        ),
                      ),
                    ]),

                    // Prev · Page N · Next
                    Row(children: [
                      GestureDetector(
                        onTap:
                            _hasPrev ? () => _goToPage(_currentPage - 1) : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _hasPrev
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(
                                color: _hasPrev
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.3)
                                    : Colors.grey.shade200),
                          ),
                          child: Icon(Icons.chevron_left,
                              size: 14.sp,
                              color: _hasPrev
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text('Page $_currentPage',
                          style: GoogleFonts.poppins(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap:
                            _hasNext ? () => _goToPage(_currentPage + 1) : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _hasNext
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(
                                color: _hasNext
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.3)
                                    : Colors.grey.shade200),
                          ),
                          child: Icon(Icons.chevron_right,
                              size: 14.sp,
                              color: _hasNext
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),

              SizedBox(height: 70.h),
            ],
          ),
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const CreateAppointmentForm(),
        ).then((_) => _fetchAppointments()),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, size: 20, color: Colors.white),
        tooltip: 'Add Appointment',
      ),
    );
  }
}
