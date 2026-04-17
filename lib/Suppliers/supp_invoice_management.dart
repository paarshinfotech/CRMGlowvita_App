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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Invoice Management",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 12.sp,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SubscriptionWrapper(
        child: Padding(
          padding: const EdgeInsets.all(_gap),
          child: Column(
            children: [
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
                ),
              ),

              const SizedBox(height: 10),

              /// 🔹 FILTER ROW (EXACT SAME)
              SizedBox(
                height: 44,
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
                        itemBuilder: (_, i) => InvoiceCard(
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
          items: items
              .map<DropdownMenuItem<String>>(
                (String e) =>
                    DropdownMenuItem<String>(value: e, child: Text(e)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateChip(DateTime? date, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(date == null ? hint : '${date.day}/${date.month}/${date.year}'),
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
