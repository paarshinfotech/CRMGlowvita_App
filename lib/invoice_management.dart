import 'package:flutter/material.dart';
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
    final List<Map<String, dynamic>> items = invoice.items
        .map((e) => {
              'name': e.name,
              'qty': e.quantity,
              'price': e.price,
              'tax':
                  0.0, // Tax is now part of BillingInvoice top level or item?
              // The model has taxRate/taxAmount at top level.
              // items have price and totalPrice.
            })
        .toList();

    final double subtotal = invoice.subtotal;
    final double discount =
        invoice.items.fold(0.0, (sum, item) => sum + item.discount);
    final double tax = invoice.taxAmount;
    final double platformFee = invoice.platformFee;
    final double total = invoice.totalAmount;

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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16, vertical: isMobile ? 6 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Invoice Details",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 10 : 12,
                        )),
                    const Spacer(),
                    InkWell(
                      child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(Icons.close, size: 20)),
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(18),
                    )
                  ],
                ),
              ),
              // Dark Header with Icon
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.layers,
                        color: Color(0xFF1F2937),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "GlowVita Salon",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Professional Salon Management Platform",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Company Info
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Company Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GlowVita Salon & Spa",
                            style: TextStyle(
                              fontFamily: "Georgia",
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 11 : 13,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text("Baner Road, Pune, Pune, Maharashtra, 411045",
                              style: GoogleFonts.poppins(fontSize: 10)),
                          Text("Phone: 9876543210",
                              style: GoogleFonts.poppins(fontSize: 10)),
                        ],
                      ),
                    ),
                    // Right: Invoice Label
                    Text(
                      "INVOICE",
                      style: TextStyle(
                        fontFamily: "Georgia",
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Section line
              Container(
                  height: 2,
                  color: Colors.black54,
                  margin: const EdgeInsets.symmetric(vertical: 7)),
              // Date/Invoice No row
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Date: ",
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: _invoiceFormatDate(invoice.createdAt),
                            style: GoogleFonts.poppins(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Invoice No: ",
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: "#${invoice.invoiceNumber}",
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                  height: 2,
                  color: Colors.black54,
                  margin: const EdgeInsets.symmetric(vertical: 7)),
              // Invoice to
              Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Invoice To: ",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                        TextSpan(
                          text: invoice.clientInfo.fullName,
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              // Main Table: Use boxed style to match the image
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.7),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1.2),
                    4: FlexColumnWidth(1.3),
                  },
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.grey[800]!, width: 1),
                    outside: BorderSide.none,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                      ),
                      children: [
                        _cellTxt("ITEM DESCRIPTION",
                            weight: FontWeight.w600, isHeader: true),
                        _cellTxt("₹ PRICE",
                            weight: FontWeight.w600, isHeader: true),
                        _cellTxt("QTY",
                            weight: FontWeight.w600, isHeader: true),
                        _cellTxt("₹ TAX",
                            weight: FontWeight.w600, isHeader: true),
                        _cellTxt("₹ AMOUNT",
                            weight: FontWeight.w600, isHeader: true),
                      ],
                    ),
                    ...invoice.items.map((item) {
                      return TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[600]!, width: 1),
                          ),
                        ),
                        children: [
                          // Item Description with Add-ons
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10),
                                ),
                                if (item.addOns.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  ...item.addOns.map((addon) => Padding(
                                        padding: const EdgeInsets.only(left: 0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "+ ${addon.name}",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  color: Colors.grey[700]),
                                            ),
                                            Text(
                                              "₹${addon.price.toStringAsFixed(0)}",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      )),
                                ]
                              ],
                            ),
                          ),
                          _cellTxt("₹${item.price.toStringAsFixed(2)}"),
                          _cellTxt("${item.quantity}"),
                          _cellTxt(
                              "₹${(item.totalPrice * invoice.taxRate / 100).toStringAsFixed(2)}"),
                          _cellTxt("₹${item.totalPrice.toStringAsFixed(2)}",
                              align: TextAlign.right),
                        ],
                      );
                    }),
                    // empty row for look
                    ...List.generate(
                        1,
                        (_) => TableRow(
                              children: List.generate(
                                  5, (_) => const SizedBox(height: 18)),
                            )),
                    // summary bolds rightmost two columns and label aligns right
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Subtotal:",
                            align: TextAlign.right, weight: FontWeight.w600),
                        _cellTxt("₹${subtotal.toStringAsFixed(2)}",
                            align: TextAlign.right),
                      ],
                    ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Discount:",
                            align: TextAlign.right,
                            weight: FontWeight.w600,
                            color: Colors.green[800]),
                        _cellTxt("-₹${discount.toStringAsFixed(2)}",
                            color: Colors.green[800],
                            align: TextAlign.right,
                            weight: FontWeight.w500),
                      ],
                    ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Tax (0%):",
                            align: TextAlign.right, weight: FontWeight.w600),
                        _cellTxt("₹${tax.toStringAsFixed(2)}",
                            align: TextAlign.right),
                      ],
                    ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Platform Fee:",
                            align: TextAlign.right, weight: FontWeight.w600),
                        _cellTxt("₹${platformFee.toStringAsFixed(2)}",
                            align: TextAlign.right),
                      ],
                    ),
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[800]!, width: 1),
                        ),
                      ),
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Total:",
                            align: TextAlign.right, weight: FontWeight.bold),
                        _cellTxt("₹${total.toStringAsFixed(2)}",
                            align: TextAlign.right, weight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Section line: strong & full
              Container(
                  height: 2,
                  color: Colors.black87,
                  margin: const EdgeInsets.symmetric(vertical: 3)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Payment Of ₹${total.toStringAsFixed(2)} Received By ${invoice.paymentMethod}",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 10),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  "NOTE: This is computer generated receipt and does not require physical signature.",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: 8,
                      color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text("Print"),
                    onPressed: () => _handlePrint(invoice, context),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download"),
                    onPressed: () => _handlePdfDownload(invoice, context),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    child: const Text("Close"),
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellTxt(String text,
          {FontWeight weight = FontWeight.normal,
          TextAlign align = TextAlign.left,
          bool isHeader = false,
          Color? color}) =>
      Padding(
        padding:
            EdgeInsets.symmetric(vertical: isHeader ? 4 : 2, horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(
              fontSize: isHeader ? 9 : 10,
              fontWeight: weight,
              color: color ?? Colors.black87),
        ),
      );

  String _invoiceFormatDate(DateTime dt) {
    return "${_weekday(dt.weekday)}, ${_month(dt.month)} ${dt.day}, ${dt.year}";
  }

  String _weekday(int weekday) {
    const week = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return week[(weekday - 1) % 7];
  }

  String _month(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[(month - 1) % 12];
  }

  Future<void> _handlePrint(
      BillingInvoice invoice, BuildContext context) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error printing PDF: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handlePdfDownload(
      BillingInvoice invoice, BuildContext context) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      final bytes = await pdf.save();

      // Get the downloads directory
      Directory? downloadsDir;

      if (Platform.isWindows) {
        // For Windows, use the Downloads folder in user's home directory
        final home =
            Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (home != null) {
          downloadsDir = Directory('$home\\Downloads');
        }
      } else if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        // For other platforms (iOS, macOS, Linux)
        downloadsDir = await getDownloadsDirectory();
      }

      // Fallback to app documents directory if downloads not available
      if (downloadsDir == null || !await downloadsDir.exists()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          "invoice_${invoice.invoiceNumber.replaceAll(RegExp(r'[^\w-]'), '_')}.pdf";
      final filePath = "${downloadsDir.path}${Platform.pathSeparator}$fileName";
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invoice saved to: $filePath"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "Open",
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving PDF: $e"),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdfDocument(BillingInvoice invoice) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final iconFont = await PdfGoogleFonts.materialIcons();

    final double subtotal = invoice.subtotal;
    final double discount =
        invoice.items.fold(0.0, (sum, item) => sum + item.discount);
    final double tax = invoice.taxAmount;
    final double platformFee = invoice.platformFee;
    final double total = invoice.totalAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with dark background and icon
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1F2937'),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // Icon
                    pw.Container(
                      width: 24,
                      height: 24,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Center(
                        child: pw.Icon(
                          pw.IconData(Icons.layers.codePoint),
                          color: PdfColor.fromHex('#1F2937'),
                          size: 16,
                          font: iconFont,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "GlowVita Salon",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "Professional Salon Management Platform",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            font: font,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Company Info & Invoice Label
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "GlowVita Salon & Spa",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          font: boldFont, // Use bold font
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Baner Road, Pune, Maharashtra, 411045",
                        style: pw.TextStyle(fontSize: 10, font: font),
                      ),
                      pw.Text(
                        "Phone: 9876543210",
                        style: pw.TextStyle(fontSize: 10, font: font),
                      ),
                    ],
                  ),
                  pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                      font: boldFont,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),

              // Date & Invoice Number
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Date: ",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                        pw.TextSpan(
                          text: DateFormat('EEEE, MMM dd, yyyy')
                              .format(invoice.createdAt),
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Invoice No: ",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                        pw.TextSpan(
                          text: invoice.invoiceNumber,
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // Invoice To
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: "Invoice To: ",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                    pw.TextSpan(
                      text: invoice.clientInfo.fullName,
                      style: pw.TextStyle(fontSize: 11, font: font),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _pdfCell('ITEM DESCRIPTION',
                          bold: true, font: font, boldFont: boldFont),
                      _pdfCell('₹ PRICE',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('QTY',
                          bold: true,
                          align: pw.TextAlign.center,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹ TAX',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹ AMOUNT',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  // Item rows
                  ...invoice.items.map((item) => pw.TableRow(
                        children: [
                          // Custom cell for name and add-ons
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.name,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    font:
                                        boldFont, // Use bold font for item name
                                  ),
                                ),
                                if (item.addOns.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  ...item.addOns.map((addon) => pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(
                                            "+ ${addon.name}",
                                            style: pw.TextStyle(
                                              fontSize: 9,
                                              color:
                                                  PdfColor.fromHex('#6B7280'),
                                              font: font,
                                            ),
                                          ),
                                          pw.Text(
                                            "₹${addon.price.toStringAsFixed(0)}",
                                            style: pw.TextStyle(
                                              fontSize: 9,
                                              color:
                                                  PdfColor.fromHex('#6B7280'),
                                              font: font,
                                            ),
                                          ),
                                        ],
                                      )),
                                ]
                              ],
                            ),
                          ),
                          _pdfCell('₹${item.price.toStringAsFixed(2)}',
                              align: pw.TextAlign.right,
                              font: font,
                              boldFont: boldFont),
                          _pdfCell('${item.quantity}',
                              align: pw.TextAlign.center,
                              font: font,
                              boldFont: boldFont),
                          _pdfCell(
                              '₹${(item.totalPrice * invoice.taxRate / 100).toStringAsFixed(2)}',
                              align: pw.TextAlign.right,
                              font: font,
                              boldFont: boldFont),
                          _pdfCell('₹${item.totalPrice.toStringAsFixed(2)}',
                              align: pw.TextAlign.right,
                              font: font,
                              boldFont: boldFont),
                        ],
                      )),
                  // Summary rows
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Subtotal:',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${subtotal.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Discount:',
                          bold: true,
                          align: pw.TextAlign.right,
                          color: PdfColor.fromHex('#15803D'),
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('-₹${discount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          color: PdfColor.fromHex('#15803D'),
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Tax (0%):',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${tax.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Platform Fee:',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${platformFee.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Total:',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${total.toStringAsFixed(2)}',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 2, color: PdfColors.black),
              pw.SizedBox(height: 12),

              // Payment Note
              pw.Center(
                child: pw.Text(
                  "Payment Of ₹${total.toStringAsFixed(2)} Received By ${invoice.paymentMethod}",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    font: boldFont,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "NOTE: THIS IS COMPUTER GENERATED RECEIPT AND DOES NOT REQUIRE PHYSICAL SIGNATURE.",
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('#6B7280'),
                    font: font,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Powered by GlowVita Salon",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                    pw.Text(
                      "Professional Salon Management Platform",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromHex('#6B7280'),
                        font: font,
                      ),
                    ),
                    pw.Text(
                      "www.glowvitasalon.com",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromHex('#9CA3AF'),
                        font: font,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  // Helper method for PDF table cells
  pw.Widget _pdfCell(String text,
      {bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
      PdfColor? color,
      required pw.Font font,
      required pw.Font boldFont}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
          font: bold ? boldFont : font,
        ),
        textAlign: align,
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
