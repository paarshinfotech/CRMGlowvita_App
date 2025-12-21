import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supp_drawer.dart';

class SuppInvoiceManagementPage extends StatefulWidget {
  const SuppInvoiceManagementPage({super.key});

  @override
  State<SuppInvoiceManagementPage> createState() => _SuppInvoiceManagementPageState();
}

class _SuppInvoiceManagementPageState extends State<SuppInvoiceManagementPage> {
  static const double _radius = 12;
  static const double _gap = 12;

  // Supplier-focused product invoices only
  final List<Map<String, dynamic>> invoices = [
    {
      'id': 'INV-101',
      'customer': 'Priya Sharma',
      'email': 'priya.sharma@example.com',
      'amount': 1898,
      'date': '2025-12-20',
      'status': 'Paid',
      'dueDate': '2026-01-20',
      'products': [
        {'name': 'Hydrating Face Serum', 'quantity': 1, 'price': 999.0},
        {'name': 'Vitamin C Face Cream', 'quantity': 1, 'price': 899.0},
      ],
      'paymentMethod': 'Online (UPI)',
    },
    {
      'id': 'INV-102',
      'customer': 'Rahul Mehta',
      'email': 'rahul.mehta@example.com',
      'amount': 1299,
      'date': '2025-12-18',
      'status': 'Paid',
      'dueDate': '2026-01-18',
      'products': [
        {'name': 'Argan Oil Hair Mask', 'quantity': 1, 'price': 1299.0},
      ],
      'paymentMethod': 'Debit Card',
    },
    {
      'id': 'INV-103',
      'customer': 'Anjali Patel',
      'email': 'anjali.patel@example.com',
      'amount': 2747,
      'date': '2025-12-15',
      'status': 'Pending',
      'dueDate': '2026-01-15',
      'products': [
        {'name': 'Luxury Body Butter', 'quantity': 2, 'price': 749.0},
        {'name': 'Matte Lipstick Set', 'quantity': 1, 'price': 1249.0},
      ],
      'paymentMethod': 'Net Banking',
    },
    {
      'id': 'INV-104',
      'customer': 'Vikram Singh',
      'email': 'vikram.singh@example.com',
      'amount': 2799,
      'date': '2025-12-12',
      'status': 'Paid',
      'dueDate': '2026-01-12',
      'products': [
        {'name': 'Gel Nail Polish Kit', 'quantity': 1, 'price': 2799.0},
      ],
      'paymentMethod': 'Cash on Delivery',
    },
    {
      'id': 'INV-105',
      'customer': 'Sneha Reddy',
      'email': 'sneha.reddy@example.com',
      'amount': 649,
      'date': '2025-12-10',
      'status': 'Overdue',
      'dueDate': '2025-12-10',
      'products': [
        {'name': 'Beard Growth Oil', 'quantity': 1, 'price': 649.0},
      ],
      'paymentMethod': 'UPI',
    },
    {
      'id': 'INV-106',
      'customer': 'Amit Kumar',
      'email': 'amit.kumar@example.com',
      'amount': 1499,
      'date': '2025-12-08',
      'status': 'Paid',
      'dueDate': '2026-01-08',
      'products': [
        {'name': 'Professional Makeup Brush Set', 'quantity': 1, 'price': 1499.0},
      ],
      'paymentMethod': 'Debit Card',
    },
    {
      'id': 'INV-107',
      'customer': 'Neha Gupta',
      'email': 'neha.gupta@example.com',
      'amount': 2198,
      'date': '2025-12-05',
      'status': 'Pending',
      'dueDate': '2026-01-05',
      'products': [
        {'name': 'Hydrating Face Serum', 'quantity': 2, 'price': 999.0},
        {'name': 'Vitamin C Face Cream', 'quantity': 1, 'price': 200.0},
      ],
      'paymentMethod': 'Online',
    },
  ];

  String _searchQuery = '';
  String _selectedPaymentMethod = 'All Payment Methods';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  int get totalBills => invoices.length;
  double get totalRevenue => invoices.fold(0.0, (sum, i) => sum + (i['amount'] as num).toDouble());
  int get totalProductsSold => invoices.fold(0, (sum, i) => sum + (i['products'] as List).fold(0, (s, p) => s + (p['quantity'] as int)));

  List<Map<String, dynamic>> get filteredInvoices {
    return invoices.where((invoice) {
      final matchesSearch = _searchQuery.isEmpty ||
          invoice['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          invoice['customer'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          invoice['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesPaymentMethod = _selectedPaymentMethod == 'All Payment Methods' ||
          invoice['paymentMethod'].toString().contains(_selectedPaymentMethod.replaceAll('All Payment Methods', ''));

      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        final invoiceDate = DateTime.parse(invoice['date']);
        if (_startDate != null && invoiceDate.isBefore(_startDate!)) matchesDateRange = false;
        if (_endDate != null && invoiceDate.isAfter(_endDate!)) matchesDateRange = false;
      }

      return matchesSearch && matchesPaymentMethod && matchesDateRange;
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
        if (isStartDate) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  void _deleteInvoice(String invoiceId) {
    setState(() {
      invoices.removeWhere((i) => i['id'] == invoiceId);
    });
  }

  void _confirmDeleteInvoice(String invoiceId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirm Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this invoice?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(
            onPressed: () {
              _deleteInvoice(invoiceId);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDialog(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuppInvoiceDetailsDialog(invoice: invoice),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Invoice Management'),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Invoice Management",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(_gap),
        child: Column(
          children: [
            // Stats
            Row(
              children: [
                Expanded(child: _InfoCard(title: 'Total Revenue', value: '₹${totalRevenue.toStringAsFixed(0)}', subtitle: 'From product sales')),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(title: 'Invoices', value: '$totalBills', subtitle: 'Total invoices')),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(title: 'Products Sold', value: '$totalProductsSold', subtitle: 'Total units')),
              ],
            ),
            const SizedBox(height: 16),

            // Count card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_radius), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt, color: Colors.blue, size: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('My Product Invoices', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('$totalBills invoices', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                    ]),
                  ),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)), child: Text('$totalBills', style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 11))),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isEmpty ? null : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Payment method filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedPaymentMethod,
                  items: ['All Payment Methods', 'Online (UPI)', 'Debit Card', 'Net Banking', 'Cash on Delivery']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.poppins(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Date range
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_radius), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date Range', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: InkWell(onTap: () => _selectDate(context, true), child: _dateChip(_startDate, 'Start Date'))),
                      const SizedBox(width: 8),
                      Expanded(child: InkWell(onTap: () => _selectDate(context, false), child: _dateChip(_endDate, 'End Date'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Invoice list
            Expanded(
              child: filteredInvoices.isEmpty
                  ? Center(child: Text('No product invoices found', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)))
                  : ListView.builder(
                      itemCount: filteredInvoices.length,
                      itemBuilder: (_, i) => SuppInvoiceCard(
                        invoice: filteredInvoices[i],
                        onView: () => _showInvoiceDialog(filteredInvoices[i]),
                        onDelete: () => _confirmDeleteInvoice(filteredInvoices[i]['id']),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(DateTime? date, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(date == null ? hint : '${date.day}/${date.month}/${date.year}', style: GoogleFonts.poppins(fontSize: 12, color: date == null ? Colors.grey : Colors.black)),
        ],
      ),
    );
  }
}

class SuppInvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  const SuppInvoiceCard({super.key, required this.invoice, this.onView, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final products = invoice['products'] as List;
    final firstProduct = products.isNotEmpty ? products.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("#${invoice['id']}", style: GoogleFonts.poppins(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(invoice['date'], style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
                    ],
                  ),
                ),
                Text(invoice['status'], style: GoogleFonts.poppins(color: invoice['status'] == 'Paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.w600, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(invoice['customer'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(invoice['email'], style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Products:', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[800])),
                const SizedBox(width: 4),
                const Icon(Icons.shopping_cart, size: 13, color: Colors.green),
                const SizedBox(width: 4),
                Text('${products.length} item${products.length > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                if (firstProduct != null) ...[
                  const SizedBox(width: 6),
                  Text(': ${firstProduct['name']} (x${firstProduct['quantity']})', style: GoogleFonts.poppins(fontSize: 10)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: '₹${invoice['amount']}',
                    style: GoogleFonts.poppins(color: const Color(0xFF2563EB), fontSize: 16, fontWeight: FontWeight.w600),
                    children: [TextSpan(text: '\nTotal Amount', style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[700]))],
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(icon: const Icon(Icons.visibility, size: 16, color: Color(0xFF2563EB)), label: Text('View', style: GoogleFonts.poppins(fontSize: 11, color: Color(0xFF2563EB))), onPressed: onView),
                    const SizedBox(width: 6),
                    TextButton.icon(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), label: Text('Delete', style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)), onPressed: onDelete),
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

class SuppInvoiceDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const SuppInvoiceDetailsDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final products = invoice['products'] as List;
    final subtotal = products.fold(0.0, (sum, p) => sum + (p['price'] as double) * (p['quantity'] as int));
    final total = subtotal; // No tax/discount in sample

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Invoice Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(),
            Text('Invoice #: ${invoice['id']}', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Date: ${invoice['date']}', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Customer: ${invoice['customer']}', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Email: ${invoice['email']}', style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 16),
            Text('Products:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ...products.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${p['name']} (x${p['quantity']})', style: GoogleFonts.poppins(fontSize: 12)),
                Text('₹${((p['price'] as double) * (p['quantity'] as int)).toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 12)),
              ]),
            )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            Text('Payment: ${invoice['paymentMethod']}', style: GoogleFonts.poppins(fontSize: 12)),
            Text('Status: ${invoice['status']}', style: GoogleFonts.poppins(fontSize: 12, color: invoice['status'] == 'Paid' ? Colors.green : Colors.orange)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(icon: const Icon(Icons.download), label: const Text('Download'), onPressed: () {}),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ]),
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

  const _InfoCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
        ]),
      ),
    );
  }
}