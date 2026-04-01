import 'package:flutter/material.dart';
import 'package:glowvita/widgets/invoice_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'billing_invoice_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class InvoiceManagementPage extends StatefulWidget {
  const InvoiceManagementPage({super.key});

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage> {
  static const double _radius = 12;
  static const double _gap = 12;

  List<BillingInvoice> invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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

  String _searchQuery = '';
  String _selectedPaymentMethod = 'All Payment Methods';
  String _selectedItemType = 'All Item Types';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  int get totalBills => invoices.length;
  double get totalRevenue =>
      invoices.fold(0.0, (sum, i) => sum + i.totalAmount);
  int get totalServicesSold => invoices.fold(
      0,
      (sum, i) =>
          sum + i.items.where((item) => item.itemType == 'Service').length);
  int get totalProductsSold => invoices.fold(
      0,
      (sum, i) =>
          sum +
          i.items
              .where((item) =>
                  item.itemType == 'Product' || item.itemType == 'Item')
              .length);

  List<BillingInvoice> get filteredInvoices {
    return invoices.where((invoice) {
      final matchesSearch = _searchQuery.isEmpty ||
          invoice.invoiceNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          invoice.clientInfo.fullName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          invoice.clientInfo.email
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesPaymentMethod =
          _selectedPaymentMethod == 'All Payment Methods' ||
              invoice.paymentMethod == _selectedPaymentMethod;

      final hasServices =
          invoice.items.any((item) => item.itemType == 'Service');
      final hasProducts = invoice.items
          .any((item) => item.itemType == 'Product' || item.itemType == 'Item');

      final matchesItemType = _selectedItemType == 'All Item Types' ||
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Invoice Management",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(_gap),
        child: Column(
          children: [
            // Top stats row (unchanged, see previous code)
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
            // Count card, search bar, filter bar (unchanged)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    child: Icon(Icons.receipt,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Invoices',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Text('$totalBills invoices in system',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$totalBills',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search Invoices...',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey, size: 20),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            color: const Color(0xFFD1D5DB), width: 1.1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPaymentMethod,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.black87),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E293B), size: 20),
                          dropdownColor: Colors.white,
                          onChanged: (value) =>
                              setState(() => _selectedPaymentMethod = value!),
                          items: [
                            DropdownMenuItem(
                              value: 'All Payment Methods',
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.payment,
                                        size: 16, color: Colors.grey),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet,
                                        size: 16, color: Colors.green),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance,
                                        size: 16, color: Colors.purple),
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
                            color: const Color(0xFFD1D5DB), width: 1.1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedItemType,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.black87),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E293B), size: 20),
                          dropdownColor: Colors.white,
                          onChanged: (value) =>
                              setState(() => _selectedItemType = value!),
                          items: [
                            DropdownMenuItem(
                              value: 'All Item Types',
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.category,
                                        size: 16, color: Colors.grey),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cut,
                                        size: 16, color: Colors.green),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shopping_cart,
                                        size: 16, color: Colors.green),
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
            // Date filter row (unchanged)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate == null
                                      ? 'Start Date'
                                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: _startDate == null
                                          ? Colors.grey
                                          : Colors.black),
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
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _endDate == null
                                      ? 'End Date'
                                      : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: _endDate == null
                                          ? Colors.grey
                                          : Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // --- invoice card list ---
            Expanded(
              child: filteredInvoices.isEmpty
                  ? Center(
                      child: Text('No invoices found',
                          style: GoogleFonts.poppins(fontSize: 13)))
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
          horizontal: isMobile ? 3 : 12, vertical: isMobile ? 5 : 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: isMobile ? double.infinity : 400,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.95),
        child: InvoiceView(invoice: invoice),
      ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final BillingInvoice invoice;
  final VoidCallback? onView;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = invoice.items.isNotEmpty ? invoice.items.first : null;
    final hasServices = invoice.items.any((i) => i.itemType == 'Service');
    final hasProducts = invoice.items
        .any((i) => i.itemType == 'Product' || i.itemType == 'Item');

    final itemType =
        hasServices ? "Service" : (hasProducts ? "Product" : "Item");
    final itemIcon = hasServices
        ? Icons.cut
        : (hasProducts ? Icons.shopping_cart : Icons.category);
    final itemColor = hasServices
        ? Theme.of(context).primaryColor
        : (hasProducts ? Colors.green : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top: code, date, status row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#${invoice.invoiceNumber}",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('yyyy-MM-dd').format(invoice.createdAt),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status at top right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      invoice.paymentStatus == 'Paid'
                          ? 'Completed'
                          : invoice.paymentStatus,
                      style: GoogleFonts.poppins(
                        color: invoice.paymentStatus == 'Paid'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 5),
            // name and email
            Text(
              invoice.clientInfo.fullName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              invoice.clientInfo.email,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 5),
            // items
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Items:",
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey[800]),
                ),
                const SizedBox(width: 4),
                Icon(itemIcon, size: 13, color: itemColor),
                const SizedBox(width: 2),
                Text(
                  itemType,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: itemColor,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  " : ${firstItem?.name ?? '-'} ",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
                ),
                Text(
                  "(x${firstItem?.quantity ?? '1'})",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
                ),
                const Spacer(),
                Text(
                  invoice.items.length.toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Payment status
            Row(
              children: [
                Text(
                  "Payment Status:",
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey[800]),
                ),
                const SizedBox(width: 5),
                Text(
                  invoice.paymentStatus == 'Paid'
                      ? 'Completed'
                      : invoice.paymentStatus,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: invoice.paymentStatus == 'Paid'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
            const SizedBox(height: 5),
            // Amount and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: '₹${invoice.totalAmount}',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: "\nTotal Amount",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                            fontSize: 9),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        side: BorderSide(color: Colors.grey.shade200),
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.visibility,
                          size: 15, color: Theme.of(context).primaryColor),
                      label: Text("View",
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor)),
                      onPressed: onView,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
        ]),
      ),
    );
  }
}
