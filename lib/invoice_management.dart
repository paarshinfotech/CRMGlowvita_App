import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';

class InvoiceManagementPage extends StatefulWidget {
  const InvoiceManagementPage({super.key});

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage> {
  static const double _radius = 12;
  static const double _gap = 12;

  final List<Map<String, dynamic>> invoices = [
    {
      'id': 'INV-001',
      'customer': 'Rahul Sharma',
      'email': 'rahul.sharma@example.com',
      'amount': 150,
      'date': '2025-11-22',
      'status': 'Paid',
      'dueDate': '2025-12-22',
      'services': [
        {'name': 'Soldier Cut', 'quantity': 1, 'price': 150.0, 'tax': 0.0},
      ],
      'products': [],
      'paymentMethod': 'Debit Card',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-002',
      'customer': 'Priya Patel',
      'email': 'priya.patel@example.com',
      'amount': 250,
      'date': '2025-11-20',
      'status': 'Pending',
      'dueDate': '2025-12-20',
      'services': [
        {'name': 'Hair Spa', 'quantity': 1, 'price': 180.0, 'tax': 0.0},
        {'name': 'Face Massage', 'quantity': 1, 'price': 70.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Hair Oil', 'quantity': 1, 'price': 50.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Cash',
      'discount': 50.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-003',
      'customer': 'Amit Kumar',
      'email': 'amit.kumar@example.com',
      'amount': 180,
      'date': '2025-11-18',
      'status': 'Overdue',
      'dueDate': '2025-11-18',
      'services': [],
      'products': [
        {'name': 'Shampoo', 'quantity': 2, 'price': 40.0, 'tax': 0.0},
        {'name': 'Conditioner', 'quantity': 1, 'price': 50.0, 'tax': 0.0},
        {'name': 'Hair Serum', 'quantity': 1, 'price': 90.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Net Banking',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-004',
      'customer': 'Sneha Reddy',
      'email': 'sneha.reddy@example.com',
      'amount': 320,
      'date': '2025-11-15',
      'status': 'Paid',
      'dueDate': '2025-12-15',
      'services': [
        {'name': 'Full Body Massage', 'quantity': 1, 'price': 250.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Body Lotion', 'quantity': 1, 'price': 40.0, 'tax': 0.0},
        {'name': 'Face Wash', 'quantity': 2, 'price': 15.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Debit Card',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-005',
      'customer': 'Vikram Singh',
      'email': 'vikram.singh@example.com',
      'amount': 95,
      'date': '2025-11-12',
      'status': 'Paid',
      'dueDate': '2025-12-12',
      'services': [
        {'name': 'Beard Trim', 'quantity': 1, 'price': 95.0, 'tax': 0.0},
      ],
      'products': [],
      'paymentMethod': 'Cash',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-006',
      'customer': 'Anjali Mehta',
      'email': 'anjali.mehta@example.com',
      'amount': 420,
      'date': '2025-11-10',
      'status': 'Pending',
      'dueDate': '2025-12-10',
      'services': [
        {'name': 'Hair Coloring', 'quantity': 1, 'price': 250.0, 'tax': 0.0},
        {'name': 'Hair Treatment', 'quantity': 1, 'price': 120.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Hair Color Kit', 'quantity': 1, 'price': 30.0, 'tax': 0.0},
        {'name': 'Hair Mask', 'quantity': 2, 'price': 10.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Net Banking',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-007',
      'customer': 'Rajesh Gupta',
      'email': 'rajesh.gupta@example.com',
      'amount': 175,
      'date': '2025-11-08',
      'status': 'Paid',
      'dueDate': '2025-12-08',
      'services': [],
      'products': [
        {'name': 'Shampoo', 'quantity': 1, 'price': 40.0, 'tax': 0.0},
        {'name': 'Conditioner', 'quantity': 1, 'price': 50.0, 'tax': 0.0},
        {'name': 'Hair Gel', 'quantity': 2, 'price': 42.5, 'tax': 0.0},
      ],
      'paymentMethod': 'Debit Card',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-008',
      'customer': 'Kavita Desai',
      'email': 'kavita.desai@example.com',
      'amount': 280,
      'date': '2025-11-05',
      'status': 'Overdue',
      'dueDate': '2025-11-05',
      'services': [
        {'name': 'Manicure', 'quantity': 1, 'price': 120.0, 'tax': 0.0},
        {'name': 'Pedicure', 'quantity': 1, 'price': 160.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Nail Polish', 'quantity': 3, 'price': 0.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Cash',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-009',
      'customer': 'Arjun Verma',
      'email': 'arjun.verma@example.com',
      'amount': 350,
      'date': '2025-11-03',
      'status': 'Paid',
      'dueDate': '2025-12-03',
      'services': [
        {'name': 'Hair Spa', 'quantity': 1, 'price': 180.0, 'tax': 0.0},
        {'name': 'Facial', 'quantity': 1, 'price': 120.0, 'tax': 0.0},
        {'name': 'Head Massage', 'quantity': 1, 'price': 50.0, 'tax': 0.0},
      ],
      'products': [],
      'paymentMethod': 'Debit Card',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-010',
      'customer': 'Neha Kapoor',
      'email': 'neha.kapoor@example.com',
      'amount': 195,
      'date': '2025-11-01',
      'status': 'Pending',
      'dueDate': '2025-12-01',
      'services': [
        {'name': 'Hair Cut', 'quantity': 1, 'price': 150.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Hair Serum', 'quantity': 1, 'price': 45.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Net Banking',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-011',
      'customer': 'Deepak Nair',
      'email': 'deepak.nair@example.com',
      'amount': 220,
      'date': '2025-10-28',
      'status': 'Paid',
      'dueDate': '2025-11-28',
      'services': [
        {'name': 'Beard Styling', 'quantity': 1, 'price': 80.0, 'tax': 0.0},
        {'name': 'Face Massage', 'quantity': 1, 'price': 70.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Face Wash', 'quantity': 2, 'price': 15.0, 'tax': 0.0},
        {'name': 'Moisturizer', 'quantity': 1, 'price': 40.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Cash',
      'discount': 0.0,
      'platformFee': 0.0,
    },
    {
      'id': 'INV-012',
      'customer': 'Pooja Iyer',
      'email': 'pooja.iyer@example.com',
      'amount': 480,
      'date': '2025-10-25',
      'status': 'Overdue',
      'dueDate': '2025-10-25',
      'services': [
        {'name': 'Full Body Massage', 'quantity': 1, 'price': 250.0, 'tax': 0.0},
        {'name': 'Spa Treatment', 'quantity': 1, 'price': 180.0, 'tax': 0.0},
      ],
      'products': [
        {'name': 'Body Lotion', 'quantity': 1, 'price': 40.0, 'tax': 0.0},
        {'name': 'Essential Oil', 'quantity': 1, 'price': 10.0, 'tax': 0.0},
      ],
      'paymentMethod': 'Debit Card',
      'discount': 0.0,
      'platformFee': 0.0,
    },
  ];

  String _searchQuery = '';
  String _selectedPaymentMethod = 'All Payment Methods';
  String _selectedItemType = 'All Item Types';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  int get totalBills => invoices.length;
  double get totalRevenue => invoices.fold(0.0, (sum, i) => sum + (i['amount'] as num).toDouble());
  int get totalServicesSold =>
      invoices.fold(0, (sum, i) => sum + (i['services'] as List).length);
  int get totalProductsSold =>
      invoices.fold(0, (sum, i) => sum + (i['products'] as List).length);

  List<Map<String, dynamic>> get filteredInvoices {
    return invoices.where((invoice) {
      final matchesSearch = _searchQuery.isEmpty ||
          invoice['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          invoice['customer'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          invoice['email'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPaymentMethod =
          _selectedPaymentMethod == 'All Payment Methods' ||
              invoice['paymentMethod'] == _selectedPaymentMethod;
      final hasServices = (invoice['services'] as List).isNotEmpty;
      final hasProducts = (invoice['products'] as List).isNotEmpty;
      final matchesItemType =
          _selectedItemType == 'All Item Types' ||
              (_selectedItemType == 'Services' && hasServices) ||
              (_selectedItemType == 'Products' && hasProducts);
      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        final invoiceDate = DateTime.parse(invoice['date']);
        if (_startDate != null && invoiceDate.isBefore(_startDate!)) {
          matchesDateRange = false;
        }
        if (_endDate != null && invoiceDate.isAfter(_endDate!)) {
          matchesDateRange = false;
        }
      }
      return matchesSearch && matchesPaymentMethod && matchesItemType && matchesDateRange;
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

  void _deleteInvoice(String invoiceId) {
    setState(() {
      invoices.removeWhere((invoice) => invoice['id'] == invoiceId);
    });
  }

  void _confirmDeleteInvoice(String invoiceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Are you sure you want to delete this invoice?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _deleteInvoice(invoiceId);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showInvoiceDialog(Map<String, dynamic> invoice) {
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt, color: Colors.blue, size: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$totalBills',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
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
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPaymentMethod,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E293B), size: 20),
                          dropdownColor: Colors.white,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                          items: [
                            DropdownMenuItem(
                              value: 'All Payment Methods',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.payment, size: 16, color: Colors.grey),
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
                              value: 'Debit Card',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.credit_card, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Debit Card',
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Cash',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, size: 16, color: Colors.green),
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
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance, size: 16, color: Colors.purple),
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
                        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedItemType,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E293B), size: 20),
                          dropdownColor: Colors.white,
                          onChanged: (value) => setState(() => _selectedItemType = value!),
                          items: [
                            DropdownMenuItem(
                              value: 'All Item Types',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.category, size: 16, color: Colors.grey),
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
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cut, size: 16, color: Colors.blue),
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
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shopping_cart, size: 16, color: Colors.green),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate == null ? 'Start Date' : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                  style: GoogleFonts.poppins(fontSize: 12, color: _startDate == null ? Colors.grey : Colors.black),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _endDate == null ? 'End Date' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                  style: GoogleFonts.poppins(fontSize: 12, color: _endDate == null ? Colors.grey : Colors.black),
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
                  ? Center(child: Text('No invoices found', style: GoogleFonts.poppins(fontSize: 13)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12, top: 2),
                      itemCount: filteredInvoices.length,
                      itemBuilder: (ctx, idx) => InvoiceCard(
                        invoice: filteredInvoices[idx],
                        onView: () => _showInvoiceDialog(filteredInvoices[idx]),
                        onDelete: () => _confirmDeleteInvoice(filteredInvoices[idx]['id']),
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
  final Map<String, dynamic> invoice;

  const InvoiceDetailsDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final List services = invoice['services'] as List? ?? [];
    final List products = invoice['products'] as List? ?? [];
    final List<Map<String, dynamic>> items = [
      ...services.map((e) => {
            'name': e['name'],
            'qty': e['quantity'],
            'price': e['price'] ?? 0.0,
            'tax': e['tax'] ?? 0.0
          }),
      ...products.map((e) => {
            'name': e['name'],
            'qty': e['quantity'],
            'price': e['price'] ?? 0.0,
            'tax': e['tax'] ?? 0.0
          }),
    ];

    final double subtotal = items.fold(0.0, (a, b) => a + ((b['price'] as num) * (b['qty'] as num)));
    final double discount = invoice['discount'] ?? 0.0;
    final double tax = items.fold(0.0, (a, b) => a + ((b['tax'] as num) * (b['qty'] as num)));
    final double platformFee = invoice['platformFee'] ?? 0.0;
    final double total = subtotal - discount + tax + platformFee;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 12, vertical: isMobile ? 5 : 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: isMobile ? double.infinity : 400,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 6 : 12),
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
                            "HarshalSpa",
                            style: TextStyle(
                              fontFamily: "Georgia",
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 11 : 13,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text("Nashik, Maharashtra, India",
                              style: GoogleFonts.poppins(fontSize: 10)),
                          Text("Phone: 9996281728",
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
              Container(height: 2, color: Colors.black54, margin: const EdgeInsets.symmetric(vertical: 7)),
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
                            text: _invoiceFormatDate(invoice['date']),
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
                              text: "#${invoice['id']}",
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.blue[700],
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
              Container(height: 2, color: Colors.black54, margin: const EdgeInsets.symmetric(vertical: 7)),
              // Invoice to
              Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Invoice To: ",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 10
                          ),
                        ),
                        TextSpan(
                          text: invoice['customer'],
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
                        _cellTxt("ITEM DESCRIPTION", weight: FontWeight.w600, isHeader: true),
                        _cellTxt("₹ PRICE", weight: FontWeight.w600, isHeader: true),
                        _cellTxt("QTY", weight: FontWeight.w600, isHeader: true),
                        _cellTxt("₹ TAX", weight: FontWeight.w600, isHeader: true),
                        _cellTxt("₹ AMOUNT", weight: FontWeight.w600, isHeader: true),
                      ],
                    ),
                    ...items.map((e) => TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[600]!, width: 1),
                            ),
                          ),
                          children: [
                            _cellTxt(e['name'], weight: FontWeight.w500),
                            _cellTxt("₹${(e['price'] as num).toStringAsFixed(2)}"),
                            _cellTxt("${e['qty']}"),
                            _cellTxt('₹${(e['tax'] as num).toStringAsFixed(2)}'),
                            _cellTxt(
                              "₹${((e['qty'] as num) * (e['price'] as num) + (e['qty'] as num) * (e['tax'] as num)).toStringAsFixed(2)}",
                              align: TextAlign.right),
                          ],
                        )),
                    // empty row for look
                    ...List.generate(1, (_) => TableRow(
                          children: List.generate(5, (_) => const SizedBox(height: 18)),
                        )),
                    // summary bolds rightmost two columns and label aligns right
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Subtotal:", align: TextAlign.right, weight: FontWeight.w600),
                        _cellTxt("₹${subtotal.toStringAsFixed(2)}", align: TextAlign.right),
                      ],
                    ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Discount:", align: TextAlign.right, weight: FontWeight.w600, color: Colors.green[800]),
                        _cellTxt("-₹${discount.toStringAsFixed(2)}", color: Colors.green[800], align: TextAlign.right, weight: FontWeight.w500),
                      ],
                    ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Tax (0%):", align: TextAlign.right, weight: FontWeight.w600),
                        _cellTxt("₹${tax.toStringAsFixed(2)}", align: TextAlign.right),
                      ],
                    ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        const SizedBox(),
                        _cellTxt("Platform Fee:", align: TextAlign.right, weight: FontWeight.w600),
                        _cellTxt("₹${platformFee.toStringAsFixed(2)}", align: TextAlign.right),
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
                        _cellTxt("Total:", align: TextAlign.right, weight: FontWeight.bold),
                        _cellTxt("₹${total.toStringAsFixed(2)}", align: TextAlign.right, weight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Section line: strong & full
              Container(height: 2, color: Colors.black87, margin: const EdgeInsets.symmetric(vertical: 3)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Payment Of ₹${total.toStringAsFixed(2)} Received By ${invoice['paymentMethod']}",
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
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download"),
                    onPressed: () {}, // download logic
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    child: const Text("Close"),
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
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
        padding: EdgeInsets.symmetric(
            vertical: isHeader ? 4 : 2, horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(
              fontSize: isHeader ? 9 : 10, fontWeight: weight, color: color ?? Colors.black87),
        ),
      );

  String _invoiceFormatDate(String date) {
    final dt = DateTime.parse(date);
    return "${_weekday(dt.weekday)}, ${_month(dt.month)} ${dt.day}, ${dt.year}";
  }

  String _weekday(int weekday) {
    const week = [
      "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    ];
    return week[(weekday - 1) % 7];
  }

  String _month(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[(month - 1) % 12];
  }
}

class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onView,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final services = (invoice['services'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final products = (invoice['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final firstItem = services.isNotEmpty ? services.first : (products.isNotEmpty ? products.first : null);
    final itemType = services.isNotEmpty ? "Service" : (products.isNotEmpty ? "Product" : "Item");
    final itemIcon = services.isNotEmpty ? Icons.cut : (products.isNotEmpty ? Icons.shopping_cart : Icons.category);
    final itemColor = services.isNotEmpty ? const Color(0xFF2563EB) : (products.isNotEmpty ? Colors.green : Colors.grey);

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
                        "#${invoice['id']}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoice['date'],
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
                      invoice['status'] == 'Paid' ? 'Completed' : invoice['status'],
                      style: GoogleFonts.poppins(
                        color: Colors.green,
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
              invoice['customer'],
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              invoice['email'],
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
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[800]),
                ),
                const SizedBox(width: 4),
                Icon(itemIcon, size: 13, color: itemColor),
                const SizedBox(width: 2),
                Text(
                  itemType,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: itemColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  " : ${firstItem?['name'] ?? '-'} ",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
                ),
                Text(
                  "(x${firstItem?['quantity'] ?? '1'})",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.black),
                ),
                const Spacer(),
                Text(
                  "1",
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Payment status
            Row(
              children: [
                Text(
                  "Payment Status:",
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[800]),
                ),
                const SizedBox(width: 5),
                Text(
                  invoice['status'] == 'Paid' ? 'Completed' : invoice['status'],
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: invoice['status'] == 'Paid' ? Colors.green : Colors.orange,
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
                    text: '₹${invoice['amount']}',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF2563EB),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        side: BorderSide(color: Colors.grey.shade200),
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.visibility, size: 15, color: Color(0xFF2563EB)),
                      label: Text("View",
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF2563EB))),
                      onPressed: onView,
                    ),
                    const SizedBox(width: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        side: BorderSide(color: Colors.grey.shade200),
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFDC2626)),
                      label: Text("Delete",
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFDC2626))),
                      onPressed: onDelete,
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

  const _InfoCard({required this.title, required this.value, required this.subtitle, Key? key})
      : super(key: key);

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
