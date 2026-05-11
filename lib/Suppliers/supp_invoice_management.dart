import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../invoice_management.dart';
import 'supp_drawer.dart';
import '../services/api_service.dart';
import '../billing_invoice_model.dart';
import '../widgets/invoice_view.dart';
import '../widgets/subscription_wrapper.dart';
import 'supp_profile.dart';
import 'supp_notifications.dart';
import '../supplier_model.dart';

class SuppInvoiceManagementPage extends StatefulWidget {
  const SuppInvoiceManagementPage({super.key});

  @override
  State<SuppInvoiceManagementPage> createState() =>
      _SuppInvoiceManagementPageState();
}

class _SuppInvoiceManagementPageState extends State<SuppInvoiceManagementPage> {
  static const double _radius = 12;
  static const double _gap = 12;

  List<BillingInvoice> invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  SupplierProfile? _profile;

  String _searchQuery = '';
  String _selectedPaymentMethod = 'All Payment Methods';
  String _selectedItemType = 'All Item Types';
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
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

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.shopName ?? 'S').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _fetchInvoices() async {
    try {
      final fetchedInvoices = await ApiService.getInvoices();

      setState(() {
        invoices = fetchedInvoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// ✅ ONLY COUNTER BILLING + PRODUCT FILTER
  List<BillingInvoice> get filteredInvoices {
    return invoices.where((invoice) {
      if (invoice.billingType == 'Appointment') return false;

      final hasProducts = invoice.items.any(
        (item) => item.itemType == 'Product' || item.itemType == 'Item',
      );

      if (!hasProducts) return false;

      final matchesSearch =
          _searchQuery.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.clientInfo.fullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesPaymentMethod =
          _selectedPaymentMethod == 'All Payment Methods' ||
          invoice.paymentMethod == _selectedPaymentMethod;

      final matchesItemType =
          _selectedItemType == 'All Item Types' ||
          (_selectedItemType == 'Products' && hasProducts);

      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        final d = invoice.createdAt;
        if (_startDate != null && d.isBefore(_startDate!)) {
          matchesDateRange = false;
        }
        if (_endDate != null &&
            d.isAfter(_endDate!.add(const Duration(days: 1)))) {
          matchesDateRange = false;
        }
      }

      return matchesSearch &&
          matchesPaymentMethod &&
          matchesItemType &&
          matchesDateRange;
    }).toList();
  }

  int get totalBills => filteredInvoices.length;

  double get totalRevenue =>
      filteredInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);

  int get totalProductsSold => filteredInvoices.fold(
    0,
    (sum, i) =>
        sum +
        i.items
            .where(
              (item) => item.itemType == 'Product' || item.itemType == 'Item',
            )
            .length,
  );

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        isStartDate ? _startDate = picked : _endDate = picked;
      });
    }
  }

  void _showInvoiceDialog(BillingInvoice invoice) {
    showDialog(
      context: context,
      builder: (_) => InvoiceDetailsDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Invoice Management'),
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
              MaterialPageRoute(builder: (_) => const SuppNotificationsPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuppProfilePage()),
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
        child: Padding(
          padding: const EdgeInsets.all(_gap),
          child: Column(
            children: [
              /// 🔹 SEARCH (MATCHED)
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search Invoices...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
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

              /// 🔹 STATS (EXACT MATCH)
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Total Revenue',
                      value: '₹${totalRevenue.toStringAsFixed(0)}',
                      subtitle: 'From product sales',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Invoices',
                      value: '$totalBills',
                      subtitle: 'Total invoices',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 COUNT CARD (EXACT COPY)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Invoices',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$totalBills invoices in system',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const SizedBox(height: 10),

              /// 🔹 FILTER ROW (EXACT SAME)
              SizedBox(
                height: 38,
                child: Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        _selectedPaymentMethod,
                        ['All Payment Methods', 'Cash', 'Net Banking'],
                        (v) => setState(() => _selectedPaymentMethod = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropdown(
                        _selectedItemType,
                        ['All Item Types', 'Products'],
                        (v) => setState(() => _selectedItemType = v!),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// 🔹 DATE FILTER (MATCHED)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: _dateChip(_startDate, 'Start Date'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: _dateChip(_endDate, 'End Date'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// 🔹 LIST (SAME CARD)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : filteredInvoices.isEmpty
                    ? Center(
                        child: Text(
                          'No invoices found',
                          style: GoogleFonts.poppins(),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredInvoices.length,
                        itemBuilder: (_, i) => SuppInvoiceCard(
                          invoice: filteredInvoices[i],
                          onView: () => _showInvoiceDialog(filteredInvoices[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black),
          items: items
              .map<DropdownMenuItem<String>>(
                (String e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: GoogleFonts.poppins(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateChip(DateTime? date, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            date == null ? hint : DateFormat('dd/MM/yyyy').format(date),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: date == null ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class SuppInvoiceCard extends StatelessWidget {
  final BillingInvoice invoice;
  final VoidCallback onView;

  const SuppInvoiceCard({
    super.key,
    required this.invoice,
    required this.onView,
  });

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
                // Billing Type and Icon
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
  });

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
