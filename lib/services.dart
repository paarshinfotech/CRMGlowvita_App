import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_services.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'add_ons.dart';
import 'vendor_model.dart';
import 'my_Profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/subscription_wrapper.dart';
import 'Notification.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class Services extends StatefulWidget {
  const Services({super.key});
  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  List<Service> services = [];
  bool isLoading = true;
  String? errorMessage;
  VendorProfile? _profile;
  Map<String, String> categoryIdToName = {};

  String? selectedCategory;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Set<String> get dynamicCategories {
    final cats = services.map((s) => s.category).whereType<String>().toSet();
    cats.add('All');
    return cats;
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = 'All';
    _fetchCategories().then((_) => _fetchServices());
    _fetchProfile();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoryData = await ApiService.getServiceCategories();
      final map = <String, String>{};
      for (var cat in categoryData) {
        if (cat['_id'] != null && cat['name'] != null) {
          map[cat['_id']] = cat['name'];
        }
      }
      if (mounted) setState(() => categoryIdToName = map);
    } catch (e) {
      debugPrint('fetchCategories error: $e');
    }
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

  // ══════════════════════════════════════════════════
  // ▼▼▼  ORIGINAL BACKEND CODE — NOT MODIFIED  ▼▼▼
  // ══════════════════════════════════════════════════

  Future<void> _fetchServices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedServices = await ApiService.getServices();

      // Ensure category names are resolved if they are IDs
      for (var s in fetchedServices) {
        if (s.categoryId != null &&
            categoryIdToName.containsKey(s.categoryId)) {
          s.category = categoryIdToName[s.categoryId];
        } else if (s.category != null &&
            categoryIdToName.containsKey(s.category)) {
          // If category field itself holds an ID
          s.category = categoryIdToName[s.category];
        }
      }

      setState(() => services = fetchedServices);
    } catch (e) {
      setState(
          () => errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddServicePage()),
    );
    if (result != null) _fetchServices();
  }

  void _editService(int index) async {
    final service = filteredServices[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServicePage(serviceData: service.toJson()),
      ),
    );
    if (result != null) _fetchServices();
  }

  void _deleteService(int index) {
    final service = filteredServices[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Service',
            style: GoogleFonts.poppins(
                fontSize: 7.5.sp, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${service.name}"?',
            style: GoogleFonts.poppins(fontSize: 7.5.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade700, fontSize: 7.5.sp)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final success = await ApiService.deleteService(service.id!);
                if (success) {
                  _fetchServices();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Service deleted successfully',
                            style: GoogleFonts.poppins(fontSize: 7.5.sp)),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Failed to delete: ${e.toString().replaceFirst('Exception: ', '')}',
                          style: GoogleFonts.poppins(fontSize: 7.5.sp)),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.red.shade600, fontSize: 7.5.sp)),
          ),
        ],
      ),
    );
  }

  void _showServiceDetails(Service service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: service.image?.isNotEmpty == true
                ? NetworkImage(service.image!)
                : null,
            backgroundColor: Colors.grey.shade100,
            child: service.image?.isNotEmpty != true
                ? Icon(Icons.spa, size: 20, color: Colors.grey.shade600)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(service.name ?? 'Service Details',
                style: GoogleFonts.poppins(
                    fontSize: 7.5.sp, fontWeight: FontWeight.w600)),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (service.image?.isNotEmpty == true)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(service.image!,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image,
                                size: 40, color: Colors.grey.shade400))),
                  ),
                ),
              const SizedBox(height: 12),
              _detailRow('Service Name', service.name ?? 'N/A'),
              _detailRow('Category', service.category ?? 'N/A'),
              _detailRow('Price', '₹${service.price ?? 0}'),
              if (service.discountedPrice != null &&
                  service.discountedPrice! < (service.price ?? 0))
                _detailRow('Disc. Price', '₹${service.discountedPrice}',
                    color: Theme.of(context).primaryColor),
              _detailRow('Duration',
                  service.duration != null ? '${service.duration} min' : 'N/A'),
              _detailRow('Gender', service.gender ?? 'unisex'),
              _detailRow('Online Booking',
                  service.onlineBooking == true ? 'Enabled' : 'Disabled'),
              _detailRow('Status', service.status ?? 'N/A'),
              _detailRow('Home Service',
                  service.homeService == true ? 'Available' : 'Not Available'),
              const SizedBox(height: 10),
              Text('Description',
                  style: GoogleFonts.poppins(
                      fontSize: 7.5.sp, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                service.description?.isNotEmpty == true
                    ? service.description!
                    : 'No description provided.',
                style: GoogleFonts.poppins(
                    fontSize: 8.5.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(
                    fontSize: 7.5.sp, color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 8.5.sp,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 8.5.sp, color: color ?? Colors.black87)),
        ),
      ]),
    );
  }

  List<Service> get filteredServices {
    return services.where((service) {
      final matchesSearch = (service.name ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (service.category ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All' ||
          (service.category ?? '').toLowerCase() ==
              selectedCategory!.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get totalServices => services.length;
  int get totalCategories =>
      services.map((s) => s.category).whereType<String>().toSet().length;
  double get averageServicePrice {
    if (services.isEmpty) return 0.0;
    return services.fold(
            0.0, (sum, s) => sum + (s.discountedPrice ?? s.price ?? 0)) /
        services.length;
  }

  String get mostPopularService =>
      services.isEmpty ? 'N/A' : (services.first.name ?? 'N/A');

  // ══════════════════════════════════════════════════
  // ▲▲▲  END OF ORIGINAL BACKEND CODE  ▲▲▲
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
      buffer.writeln('Name\tCategory\tPrice\tDisc. Price\tDuration\tGender\tStatus\tOnline Booking');
      for (var s in filteredServices) {
        buffer.writeln('${s.name ?? ''}\t${s.category ?? ''}\t₹${s.price ?? 0}\t₹${s.discountedPrice ?? s.price ?? 0}\t${s.duration ?? 0} min\t${s.gender ?? 'unisex'}\t${s.status ?? ''}\t${s.onlineBooking == true ? 'Yes' : 'No'}');
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${filteredServices.length} services copied to clipboard!', style: GoogleFonts.poppins(fontSize: 10.sp)),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint('Error copying: $e');
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(['Name', 'Category', 'Price', 'Discount Price', 'Duration', 'Gender', 'Status', 'Online Booking']);
      for (var s in filteredServices) {
        rows.add([s.name ?? '', s.category ?? '', s.price ?? 0, s.discountedPrice ?? s.price ?? 0, s.duration ?? 0, s.gender ?? 'unisex', s.status ?? '', s.onlineBooking == true ? 'Yes' : 'No']);
      }
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/services_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CSV exported successfully!', style: GoogleFonts.poppins(fontSize: 10.sp)),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'OPEN', textColor: Colors.white, onPressed: () => OpenFile.open(file.path)),
        ));
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Services'];
      var headers = ['Name', 'Category', 'Price', 'Discount Price', 'Duration', 'Gender', 'Status', 'Online Booking'];
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
      }
      for (int i = 0; i < filteredServices.length; i++) {
        var s = filteredServices[i];
        int rowIndex = i + 1;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(s.name ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(s.category ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue((s.price ?? 0).toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue((s.discountedPrice ?? s.price ?? 0).toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue((s.duration ?? 0).toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(s.gender ?? 'unisex');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(s.status ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(s.onlineBooking == true ? 'Yes' : 'No');
      }
      var directory = await getApplicationDocumentsDirectory();
      var filePath = '${directory.path}/services_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)..createSync(recursive: true)..writeAsBytesSync(fileBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Excel exported successfully!', style: GoogleFonts.poppins(fontSize: 10.sp)),
            backgroundColor: Colors.green,
            action: SnackBarAction(label: 'OPEN', textColor: Colors.white, onPressed: () => OpenFile.open(filePath)),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error exporting Excel: $e');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Services Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}')),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Category', 'Price', 'Duration', 'Status'],
            data: filteredServices.map((s) => [s.name ?? '', s.category ?? '', '₹${s.price ?? 0}', '${s.duration ?? 0}m', s.status ?? '']).toList(),
          ),
        ],
      ));
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/services_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF exported successfully!', style: GoogleFonts.poppins(fontSize: 10.sp)),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'OPEN', textColor: Colors.white, onPressed: () => OpenFile.open(file.path)),
        ));
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
    }
  }

  Future<void> _exportToPrint() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Services Report')),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Category', 'Price', 'Duration', 'Status'],
            data: filteredServices.map((s) => [s.name ?? '', s.category ?? '', '₹${s.price ?? 0}', '${s.duration ?? 0}m', s.status ?? '']).toList(),
          ),
        ],
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      debugPrint('Error printing: $e');
    }
  }

  // ── Status chip ───────────────────────────────────
  Widget _statusChip(String? status) {
    Color bg, text, border;
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        border = const Color(0xFF81C784);
        break;
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        border = const Color(0xFFFFB74D);
        break;
      case 'reject':
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        border = const Color(0xFFE57373);
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        border = Colors.grey.shade300;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status ?? 'Pending',
        style: GoogleFonts.poppins(
            fontSize: 7.sp, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  // ── Stat card ─────────────────────────────────────
  Widget _statCard(String label, String value, String emoji) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        SizedBox(width: 10.w),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 7.5.sp, color: Colors.grey.shade500)),
          SizedBox(height: 2.h),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ]),
      ]),
    );
  }

  // ── Service card (matches screenshot exactly) ─────
  Widget _serviceCard(Service service, int index) {
    final isOnlineBooking = service.onlineBooking ?? false;
    final origPrice = (service.price ?? 0).toDouble();
    final discPrice = (service.discountedPrice ?? origPrice).toDouble();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top: avatar + name/email + status + toggle ──
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 8.w, 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: service.image?.isNotEmpty == true
                    ? NetworkImage(service.image!)
                    : null,
                child: service.image?.isNotEmpty != true
                    ? Icon(Icons.spa, size: 20.sp, color: Colors.grey.shade500)
                    : null,
              ),
              SizedBox(width: 10.w),

              // Name + contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name ?? 'Unnamed Service',
                        style: GoogleFonts.poppins(
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Row(children: [
                      if (service.category != null) ...[
                        Text(service.category!,
                            style: GoogleFonts.poppins(
                                fontSize: 7.sp, color: Colors.grey.shade500)),
                        Text(' • ',
                            style: GoogleFonts.poppins(
                                fontSize: 7.sp, color: Colors.grey.shade400)),
                      ],
                      if (service.duration != null)
                        Text('${service.duration} min',
                            style: GoogleFonts.poppins(
                                fontSize: 7.sp, color: Colors.grey.shade500)),
                    ]),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Status chip
              _statusChip(service.status),
              SizedBox(width: 4.w),

              // Online booking toggle
              // Online booking toggle
              Transform.scale(
                scale: 0.72,
                child: Switch(
                  value: isOnlineBooking,
                  onChanged: (val) async {
                    // Step 1: Update UI immediately (optimistic update)
                    final originalIndex =
                        services.indexOf(filteredServices[index]);
                    if (originalIndex == -1) return;

                    setState(() {
                      services[originalIndex].onlineBooking = val;
                    });

                    // Step 2: Build minimal payload with all required fields
                    final service = services[originalIndex];
                    try {
                      final serviceId = service.id;
                      if (serviceId == null) return;

                      final payload = service.toJson();
                      payload['onlineBooking'] = val;
                      payload['category_id'] =
                          service.categoryId ?? payload['categoryId'];

                      final success =
                          await ApiService.updateService(serviceId, payload);

                      if (!success) {
                        //  Step 3: Revert if API failed
                        if (mounted) {
                          setState(() {
                            services[originalIndex].onlineBooking = !val;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update online booking status',
                                style: GoogleFonts.poppins(fontSize: 7.5.sp),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      //  Step 4: Revert on error
                      if (mounted) {
                        setState(() {
                          services[originalIndex].onlineBooking = !val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                              style: GoogleFonts.poppins(fontSize: 7.5.sp),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  activeColor: Colors.green.shade600,
                  thumbColor: WidgetStateProperty.all(Colors.white),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Thin divider
        Divider(height: 1, color: Colors.grey.shade100),

        // ── Price section ────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price',
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 2.h),
                  Text('₹ ${origPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discount Price',
                      style: GoogleFonts.poppins(
                          fontSize: 7.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 2.h),
                  Text('₹ ${discPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ],
              ),
            ),
          ]),
        ),

        // ── Action icons row ─────────────────────────
        Padding(
          padding: EdgeInsets.only(right: 10.w, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // View
              _actionIcon(Icons.visibility_outlined, Colors.grey.shade600,
                  () => _showServiceDetails(service)),
              SizedBox(width: 6.w),
              // Edit
              _actionIcon(Icons.edit_outlined, Colors.grey.shade600,
                  () => _editService(index)),
              SizedBox(width: 6.w),
              // Add Add-on
              _actionIcon(Icons.add, Colors.grey.shade600, () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      AddEditAddOnDialog(initialServiceId: service.id),
                );
              }),
              SizedBox(width: 6.w),
              // Delete
              _actionIcon(Icons.delete_outline, Colors.red.shade400,
                  () => _deleteService(index)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Icon(icon, size: 17.sp, color: color),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Stats derived from services
    final approvedCount =
        services.where((s) => s.status?.toLowerCase() == 'approved').length;
    final pendingCount =
        services.where((s) => s.status?.toLowerCase() == 'pending').length;
    final disapprovedCount = services
        .where((s) =>
            s.status?.toLowerCase() == 'reject' ||
            s.status?.toLowerCase() == 'rejected')
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(currentPage: 'Services'),
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
          'Services',
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
      body: SubscriptionWrapper(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor))
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Failed to load services',
                              style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 7.5.sp,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _fetchServices,
                            child: Text('Retry',
                                style: GoogleFonts.poppins(fontSize: 7.5.sp)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Search bar ───────────────────────
                          Container(
                            height: 38.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => searchQuery = v),
                              style: GoogleFonts.poppins(fontSize: 8.5.sp),
                              decoration: InputDecoration(
                                hintText: 'Search services......',
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 8.5.sp,
                                    color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.search,
                                    size: 15.sp, color: Colors.grey.shade400),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear,
                                            size: 14.sp,
                                            color: Colors.grey.shade400),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.h),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // ── Category filter + Export ─────────
                          Row(children: [
                            Expanded(
                              child: Container(
                                height: 34.h,
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCategory,
                                    isDense: true,
                                    icon: Icon(Icons.keyboard_arrow_down,
                                        size: 14.sp, color: Colors.grey),
                                    style: GoogleFonts.poppins(
                                        fontSize: 8.5.sp,
                                        color: Colors.black87),
                                    items: dynamicCategories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 8.5.sp)),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => selectedCategory = v),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            PopupMenuButton<String>(
                              onSelected: _handleExport,
                              itemBuilder: (context) => [
                                _buildExportItem('copy', Icons.copy, 'Copy', Colors.grey[700]!),
                                _buildExportItem('csv', Icons.table_chart, 'CSV', Colors.grey[700]!),
                                _buildExportItem('excel', Icons.grid_on, 'Excel', Colors.green[700]!),
                                _buildExportItem('pdf', Icons.picture_as_pdf, 'PDF', Colors.red[700]!),
                                _buildExportItem('print', Icons.print, 'Print', Colors.grey[700]!),
                              ],
                              child: Container(
                                height: 34.h,
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.file_download_outlined, size: 14.sp, color: Colors.blue[700]),
                                    SizedBox(width: 4.w),
                                    Text('Export',
                                        style: GoogleFonts.poppins(
                                            fontSize: 8.5.sp,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                          SizedBox(height: 10.h),

                          // ── 2×2 Stat cards ───────────────────
                          Row(children: [
                            Expanded(
                                child: _statCard('Total Services\nOffered',
                                    '$totalServices', '🎨')),
                            SizedBox(width: 8.w),
                            Expanded(
                                child: _statCard('Approved Services',
                                    '$approvedCount', '✅')),
                          ]),
                          SizedBox(height: 8.h),
                          Row(children: [
                            Expanded(
                                child: _statCard(
                                    'Pending Approval', '$pendingCount', '🕐')),
                            SizedBox(width: 8.w),
                            Expanded(
                                child: _statCard(
                                    'Disapproved', '$disapprovedCount', '❌')),
                          ]),
                          SizedBox(height: 12.h),

                          // ── Add Service header row ────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('All Services',
                                  style: GoogleFonts.poppins(
                                      fontSize: 7.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87)),
                              GestureDetector(
                                onTap: _navigateToAddService,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 5.h),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add,
                                            size: 12.sp, color: Colors.white),
                                        SizedBox(width: 4.w),
                                        Text('Add Service',
                                            style: GoogleFonts.poppins(
                                                fontSize: 7.5.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600)),
                                      ]),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          // ── Service list ─────────────────────
                          filteredServices.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(children: [
                                      Icon(Icons.spa_outlined,
                                          size: 50,
                                          color: Colors.grey.shade400),
                                      SizedBox(height: 10.h),
                                      Text('No services found',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12.sp,
                                              color: Colors.grey.shade600)),
                                    ]),
                                  ),
                                )
                              : Column(
                                  children: filteredServices
                                      .asMap()
                                      .entries
                                      .map((e) => _serviceCard(e.value, e.key))
                                      .toList(),
                                ),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
  PopupMenuItem<String> _buildExportItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Text(label, style: GoogleFonts.poppins(fontSize: 9.sp)),
        ],
      ),
    );
  }
}
