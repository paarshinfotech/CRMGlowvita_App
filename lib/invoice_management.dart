import 'package:flutter/material.dart';
import 'package:glowvita/widgets/invoice_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'billing_invoice_model.dart';
import 'appointment_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'my_Profile.dart';
import 'Notification.dart';
import 'vendor_model.dart';

class InvoiceManagementPage extends StatefulWidget {
  const InvoiceManagementPage({super.key});

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const double _radius = 12;
  static const double _gap = 12;

  List<BillingInvoice> invoices = [];
  List<AppointmentModel> appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  VendorProfile? _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchInvoices();
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

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedInvoices = await ApiService.getInvoices();
      // Fetch appointments that are paid or have an invoice number
      final apptResult = await ApiService.getAppointments(limit: 100);
      final List<AppointmentModel> allAppts = apptResult['data'] ?? [];

      setState(() {
        invoices = fetchedInvoices;
        appointments = allAppts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<BillingInvoice> _generateAppointmentInvoices() {
    return appointments
        .where((appt) {
          bool isPaid = appt.paymentStatus == 'completed';
          bool hasInvoice =
              appt.invoiceNumber != null && appt.invoiceNumber!.isNotEmpty;
          return isPaid || hasInvoice;
        })
        .map((appt) {
          // Determine correct status based on payment rule
          String finalStatus = appt.status ?? 'N/A';
          if (appt.status == 'completed' &&
              (appt.paymentStatus == 'completed' ||
                  appt.paymentStatus == 'Paid')) {
            finalStatus = 'Paid';
          } else if (appt.paymentStatus == 'completed' ||
              appt.paymentStatus == 'Paid') {
            finalStatus = 'Paid';
          } else if (appt.status == 'completed' &&
              appt.paymentStatus != 'completed' &&
              appt.paymentStatus != 'Paid') {
            finalStatus = 'Completed Without Payment';
          }

          return BillingInvoice(
            id: appt.id ?? '',
            invoiceNumber: appt.invoiceNumber ?? 'N/A',
            clientInfo: ClientInfo(
              fullName: appt.clientName ?? 'N/A',
              email: appt.client?.email ?? '',
              phone: appt.client?.phone ?? '',
              profilePicture: '',
              address: appt.venueAddress ?? '',
            ),
            vendorId: appt.vendorId ?? '',
            clientId: appt.client?.id ?? '',
            items: (appt.serviceItems ?? [])
                .map(
                  (si) => BillingItem(
                    itemId: si.service ?? '',
                    itemType: 'Service',
                    name: si.serviceName ?? appt.serviceName ?? 'Service',
                    description: '',
                    price: si.amount ?? appt.amount ?? 0.0,
                    quantity: 1,
                    totalPrice: si.amount ?? appt.amount ?? 0.0,
                    duration: si.duration ?? appt.duration ?? 0,
                    addOns: (si.addOns ?? [])
                        .map(
                          (ao) => AddOnItem(
                            id: ao.id ?? '',
                            name: ao.name ?? '',
                            price: (ao.price ?? 0).toDouble(),
                            duration: ao.duration ?? 0,
                          ),
                        )
                        .toList(),
                    discount: 0,
                    discountType: 'flat',
                  ),
                )
                .toList(),
            subtotal: appt.amount ?? 0.0,
            taxRate: 0,
            taxAmount: appt.serviceTax ?? 0.0,
            platformFee: appt.platformFee ?? 0.0,
            totalAmount: appt.totalAmount ?? appt.finalAmount ?? 0.0,
            balance: appt.amountRemaining ?? 0.0,
            paymentMethod: appt.paymentMethod ?? 'N/A',
            paymentStatus: finalStatus,
            billingType: 'Appointment',
            createdAt: appt.date ?? DateTime.now(),
            updatedAt: appt.date ?? DateTime.now(),
          );
        })
        .toList();
  }

  String _searchQuery = '';
  String _selectedPaymentMethod = 'All Payment Methods';
  String _selectedItemType = 'All Item Types';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  List<BillingInvoice> get _allBaseInvoices => [
    ...invoices.where((i) => i.billingType != 'Appointment'),
    ..._generateAppointmentInvoices(),
  ];

  int get totalBills => _allBaseInvoices.length;
  double get totalRevenue =>
      _allBaseInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);
  int get totalServicesSold => _allBaseInvoices.fold(
    0,
    (sum, i) =>
        sum + i.items.where((item) => item.itemType == 'Service').length,
  );
  int get totalProductsSold => _allBaseInvoices.fold(
    0,
    (sum, i) =>
        sum +
        i.items
            .where(
              (item) => item.itemType == 'Product' || item.itemType == 'Item',
            )
            .length,
  );

  List<BillingInvoice> get filteredInvoices {
    List<BillingInvoice> sourceInvoices = [];
    if (_tabController.index == 0) {
      sourceInvoices = invoices
          .where((i) => i.billingType != 'Appointment')
          .toList();
    } else {
      sourceInvoices = _generateAppointmentInvoices();
    }

    return sourceInvoices.where((invoice) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.clientInfo.fullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.clientInfo.email.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesPaymentMethod =
          _selectedPaymentMethod == 'All Payment Methods' ||
          invoice.paymentMethod == _selectedPaymentMethod;

      final hasServices = invoice.items.any(
        (item) => item.itemType == 'Service',
      );
      final hasProducts = invoice.items.any(
        (item) => item.itemType == 'Product' || item.itemType == 'Item',
      );

      final matchesItemType =
          _selectedItemType == 'All Item Types' ||
          (_selectedItemType == 'Services' && hasServices) ||
          (_selectedItemType == 'Products' && hasProducts);

      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        final invoiceDate = invoice.createdAt;
        if (_startDate != null && invoiceDate.isBefore(_startDate!)) {
          matchesDateRange = false;
        }
        if (_endDate != null &&
            invoiceDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          matchesDateRange = false;
        }
      }
      return matchesSearch &&
          matchesPaymentMethod &&
          matchesItemType &&
          matchesDateRange;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showInvoiceDialog(BillingInvoice invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InvoiceDetailsDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Invoice Management'),
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
          'Invoice Management',
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
      body: Padding(
        padding: const EdgeInsets.all(_gap),
        child: Column(
          children: [
            /// 🔹 SEARCH
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search Invoices...',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_radius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 10),

            // TabBar in body
            Container(
              margin: EdgeInsets.symmetric(vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: Theme.of(context).primaryColor,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blueGrey,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Counter Billing'),
                  Tab(text: 'Appointments'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1.1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPaymentMethod,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF1E293B),
                            size: 20,
                          ),
                          dropdownColor: Colors.white,
                          onChanged: (value) =>
                              setState(() => _selectedPaymentMethod = value!),
                          items: [
                            DropdownMenuItem(
                              value: 'All Payment Methods',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.payment,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'All Payment Methods',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Cash',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cash',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Net Banking',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance,
                                      size: 16,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Net Banking',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1.1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedItemType,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF1E293B),
                            size: 20,
                          ),
                          dropdownColor: Colors.white,
                          onChanged: (value) =>
                              setState(() => _selectedItemType = value!),
                          items: [
                            DropdownMenuItem(
                              value: 'All Item Types',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'All Item Types',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Services',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cut,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Services',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Products',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Products',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Date filter row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _startDate == null
                                  ? 'Start Date'
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_startDate!),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _startDate == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _endDate == null
                                  ? 'End Date'
                                  : DateFormat('dd/MM/yyyy').format(_endDate!),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _endDate == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top stats row
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Total Revenue',
                    value: '₹${totalRevenue.toStringAsFixed(0)}',
                    subtitle: 'From all transactions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title: 'Services Sold',
                    value: '$totalServicesSold',
                    subtitle: 'Service transactions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title: 'Products Sold',
                    value: '$totalProductsSold',
                    subtitle: 'Product transactions',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 12),
            // --- invoice card list ---
            Expanded(
              child: filteredInvoices.isEmpty
                  ? Center(
                      child: Text(
                        'No invoices found',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12, top: 2),
                      itemCount: filteredInvoices.length,
                      itemBuilder: (ctx, idx) => InvoiceCard(
                        invoice: filteredInvoices[idx],
                        onView: () => _showInvoiceDialog(filteredInvoices[idx]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// DIALOG WIDGET
class InvoiceDetailsDialog extends StatelessWidget {
  final BillingInvoice invoice;

  const InvoiceDetailsDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 3 : 12,
        vertical: isMobile ? 5 : 20,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: isMobile ? double.infinity : 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        child: InvoiceView(invoice: invoice),
      ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final BillingInvoice invoice;
  final VoidCallback? onView;

  const InvoiceCard({super.key, required this.invoice, this.onView});

  @override
  Widget build(BuildContext context) {
    final firstItem = invoice.items.isNotEmpty ? invoice.items.first : null;
    final hasServices = invoice.items.any((i) => i.itemType == 'Service');
    final hasProducts = invoice.items.any(
      (i) => i.itemType == 'Product' || i.itemType == 'Item',
    );

    final itemType = hasServices
        ? "Services"
        : (hasProducts ? "Products" : "Items");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID and Date
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 4, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(invoice.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Name Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person, size: 13, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  invoice.clientInfo.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade400),

          // Content Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Phone
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            invoice.clientInfo.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Services
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$itemType : ${firstItem?.name ?? '-'} (x${firstItem?.quantity ?? 1})',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Amount
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${invoice.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Paid By
                    Expanded(
                      child: Text(
                        'Paid By : ${invoice.paymentMethod}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Billing Type and Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Billing Type : ${invoice.billingType}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 20,
                            color: Color(0xFF374151),
                          ),
                          onPressed: onView,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
