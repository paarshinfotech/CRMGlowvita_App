import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './supp_drawer.dart';
import '../customer_model.dart';
import '../add_customer.dart';
import 'dart:async';

class SuppSalesPage extends StatefulWidget {
  const SuppSalesPage({super.key});

  @override
  State<SuppSalesPage> createState() => _SuppSalesPageState();
}

class _SuppSalesPageState extends State<SuppSalesPage> {
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _text = Color(0xFF0F172A);
  // Removed static _primary blue constant
  static const Color _success = Color(0xFF10B981);

  // Supplier-focused products data (removed services)
  List<Map<String, dynamic>> products = [
    {'name': 'Hydrating Face Serum', 'category': 'Skin Care', 'price': 999.0},
    {'name': 'Vitamin C Face Cream', 'category': 'Skin Care', 'price': 1199.0},
    {'name': 'Argan Oil Hair Mask', 'category': 'Hair Care', 'price': 1299.0},
    {'name': 'Luxury Body Butter', 'category': 'Body Care', 'price': 749.0},
    {'name': 'Matte Lipstick Set', 'category': 'Makeup', 'price': 1999.0},
    {'name': 'Beard Growth Oil', 'category': 'Males Grooming', 'price': 649.0},
    {'name': 'Gel Nail Polish Kit', 'category': 'Nails Care', 'price': 2799.0},
    {
      'name': 'Professional Makeup Brush Set',
      'category': 'Beauty Tools',
      'price': 1499.0
    },
  ];

  // Sample customers data (updated dates around Dec 2025)
  List<Customer> customers = [
    Customer(
      id: '1',
      fullName: 'Priya Sharma',
      mobile: '+91 9876543210',
      email: 'priya.sharma@email.com',
      dateOfBirth: '15/03/1990',
      gender: 'Female',
      country: 'India',
      occupation: 'Marketing Manager',
      address: '123 Main St, Mumbai, MH 400001',
      note: 'Regular buyer of skin care products',
      lastVisit: '15/12/2025',
      totalBookings: 8,
      totalSpent: 4560.50,
      status: 'Active',
      createdAt: DateTime(2025, 10, 15),
      isOnline: true,
    ),
    Customer(
      id: '2',
      fullName: 'Rahul Mehta',
      mobile: '+91 8765432109',
      email: 'rahul.mehta@email.com',
      dateOfBirth: '22/07/1988',
      gender: 'Male',
      country: 'India',
      occupation: 'Business Owner',
      address: '456 Oak Ave, Delhi, DL 110001',
      note: 'Prefers bulk orders',
      lastVisit: '10/12/2025',
      totalBookings: 5,
      totalSpent: 3450.00,
      status: 'Active',
      createdAt: DateTime(2025, 9, 10),
      isOnline: false,
    ),
    Customer(
      id: '3',
      fullName: 'Anjali Patel',
      mobile: '+91 7654321098',
      email: 'anjali.patel@email.com',
      dateOfBirth: '10/11/1992',
      gender: 'Female',
      country: 'India',
      occupation: 'Teacher',
      address: '789 Pine Rd, Bangalore, KA 560001',
      lastVisit: '05/12/2025',
      totalBookings: 3,
      totalSpent: 1899.75,
      status: 'Active',
      createdAt: DateTime(2025, 11, 1),
      isOnline: true,
    ),
    Customer(
      id: '4',
      fullName: 'Vikram Singh',
      mobile: '+91 6543210987',
      email: 'vikram.singh@email.com',
      dateOfBirth: '05/01/1985',
      gender: 'Male',
      country: 'India',
      occupation: 'Doctor',
      address: '321 Elm St, Chennai, TN 600001',
      note: 'VIP wholesaler',
      lastVisit: '20/12/2025',
      totalBookings: 15,
      totalSpent: 12500.00,
      status: 'Active',
      createdAt: DateTime(2025, 8, 20),
      isOnline: false,
    ),
    Customer(
      id: '5',
      fullName: 'Sneha Reddy',
      mobile: '+91 5432109876',
      dateOfBirth: '18/09/1995',
      gender: 'Female',
      country: 'India',
      occupation: 'Software Engineer',
      address: '555 Beach Rd, Hyderabad, TS 500001',
      totalBookings: 2,
      totalSpent: 1498.00,
      status: 'Active',
      createdAt: DateTime(2025, 10, 25),
      isOnline: true,
    ),
    Customer(
      id: '6',
      fullName: 'Amit Kumar',
      mobile: '+91 4321098765',
      email: 'amit.kumar@email.com',
      dateOfBirth: '30/04/1982',
      gender: 'Male',
      country: 'India',
      occupation: 'Nurse',
      address: '987 Maple Dr, Kolkata, WB 700001',
      note: 'New retailer partner',
      totalBookings: 1,
      totalSpent: 2799.00,
      status: 'Active',
      createdAt: DateTime(2025, 12, 17),
      isOnline: false,
    ),
  ];

  // Selected items for invoice
  List<Map<String, dynamic>> selectedItems = [];

  // Selected customer
  Customer? selectedCustomer;

  // Search controllers
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();

  // Category filter
  String? selectedProductCategory;

  // Search queries
  String productSearchQuery = '';
  String customerSearchQuery = '';

  // Timer for debouncing customer search
  Timer? _customerSearchTimer;

  @override
  void initState() {
    super.initState();
    selectedProductCategory = 'All';
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _customerSearchController.dispose();
    _customerSearchTimer?.cancel();
    super.dispose();
  }

  // Filter products based on search and category
  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final q = productSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          product['name'].toString().toLowerCase().contains(q) ||
          product['category'].toString().toLowerCase().contains(q);

      final matchesCategory = selectedProductCategory == 'All' ||
          product['category'].toString() == selectedProductCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Filter customers based on search
  List<Customer> get filteredCustomers {
    return customers.where((customer) {
      final query = customerSearchQuery.toLowerCase();
      return query.isEmpty ||
          customer.fullName.toLowerCase().contains(query) ||
          (customer.email?.toLowerCase().contains(query) ?? false) ||
          customer.mobile.toLowerCase().contains(query);
    }).toList();
  }

  // Get unique categories for products
  List<String> get productCategories {
    final categories = <String>{'All'};
    for (var product in products) {
      if (product['category'] is String) categories.add(product['category']);
    }
    return categories.toList()..sort();
  }

  // Add product to invoice
  void _addItemToInvoice(Map<String, dynamic> item) {
    setState(() {
      selectedItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': item['name'],
        'category': item['category'],
        'price': item['price'],
        'quantity': 1,
      });
    });
  }

  void _removeItemFromInvoice(int id) {
    setState(() {
      selectedItems.removeWhere((item) => item['id'] == id);
    });
  }

  void _updateItemQuantity(int id, int quantity) {
    if (quantity <= 0) return;
    setState(() {
      final index = selectedItems.indexWhere((item) => item['id'] == id);
      if (index != -1) selectedItems[index]['quantity'] = quantity;
    });
  }

  double get subtotal {
    return selectedItems.fold(
        0.0,
        (sum, item) =>
            sum + (item['price'] as double) * (item['quantity'] as int));
  }

  double get tax => subtotal * 0.18; // Assuming 18% GST for India
  double get total => subtotal + tax;

  void _clearInvoice() {
    setState(() {
      selectedItems.clear();
      selectedCustomer = null;
    });
  }

  void _navigateToAddCustomer() async {
    final newCustomer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomer()),
    );

    if (newCustomer != null) {
      setState(() {
        customers.add(newCustomer);
        selectedCustomer = newCustomer;
      });
    }
  }

  // UI helpers
  TextStyle get _h1 => GoogleFonts.poppins(
      fontSize: 20, fontWeight: FontWeight.w700, color: _text);
  TextStyle get _h2 => GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w700, color: _text);
  TextStyle get _sub => GoogleFonts.poppins(
      fontSize: 11.5, fontWeight: FontWeight.w500, color: _muted);
  TextStyle get _th => GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w700, color: _muted);
  TextStyle get _td => GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: _text);

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    bool showClear = false,
    VoidCallback? onClear,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: showClear
          ? IconButton(
              icon: const Icon(Icons.close, size: 16), onPressed: onClear)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      isDense: true,
    );
  }

  Widget _chip(String text, {Color? bg, Color? fg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg ?? _muted),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg ?? _muted)),
        ],
      ),
    );
  }

  bool _isItemSelected(String name, double price) {
    return selectedItems
        .any((x) => x['name'] == name && (x['price'] as double) == price);
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 1300) return 4;
    if (width >= 980) return 3;
    return 2;
  }

  Widget _buildInvoicePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create Invoice', style: _h1),
        const SizedBox(height: 12),
        Text('Selected Customer:', style: _sub),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => _buildCustomerSelector(),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.person,
                    color: selectedCustomer == null
                        ? _muted
                        : Theme.of(context).primaryColor,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  selectedCustomer?.fullName ?? 'Select Customer',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selectedCustomer == null
                        ? _muted
                        : Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: _muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (selectedItems.isNotEmpty) ...[
          Text('Selected Products:', style: _sub),
          const SizedBox(height: 8),
          ...selectedItems.map((item) => _buildSelectedItemRow(item)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _billingLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
          _billingLine('GST (18%)', '₹${tax.toStringAsFixed(2)}'),
          const Divider(),
          _billingLine('Total', '₹${total.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearInvoice,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child:
                      Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      total > 0 ? () {} : null, // Implement invoice generation
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text('Generate Invoice',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ] else
          Center(
            child: Text(
              'No products selected',
              style: GoogleFonts.poppins(fontSize: 12, color: _muted),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedItemRow(Map<String, dynamic> item) {
    final quantity = item['quantity'] as int;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item['name'],
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _qtyButton(
                icon: Icons.remove,
                onTap: () =>
                    _updateItemQuantity(item['id'] as int, quantity - 1),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text('$quantity',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              _qtyButton(
                icon: Icons.add,
                onTap: () =>
                    _updateItemQuantity(item['id'] as int, quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            '₹${((item['price'] as double) * quantity).toStringAsFixed(0)}',
            style:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _removeItemFromInvoice(item['id'] as int),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customerSearchController,
                      onChanged: (v) {
                        _customerSearchTimer?.cancel();
                        _customerSearchTimer =
                            Timer(const Duration(milliseconds: 300), () {
                          setState(() => customerSearchQuery = v);
                        });
                      },
                      decoration: _fieldDecoration(
                        hint: 'Search by name, mobile, or email…',
                        icon: Icons.search,
                        showClear: customerSearchQuery.isNotEmpty,
                        onClear: () {
                          _customerSearchController.clear();
                          setState(() => customerSearchQuery = '');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddCustomer,
                    icon: const Icon(Icons.add, size: 18),
                    label:
                        Text('Add', style: GoogleFonts.poppins(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Text(
                        'No customers found',
                        style: GoogleFonts.poppins(fontSize: 14, color: _muted),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected = selectedCustomer?.id == customer.id;

                        return ListTile(
                          onTap: () {
                            setState(() => selectedCustomer = customer);
                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text(
                              customer.fullName[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          title: Text(
                            customer.fullName,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            customer.mobile,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _muted),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF10B981))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    // Products catalog
    final productsCatalog = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Catalog', style: _h1),
        const SizedBox(height: 12),
        TextField(
          controller: _productSearchController,
          onChanged: (v) => setState(() => productSearchQuery = v),
          decoration: _fieldDecoration(
            hint: 'Search products by name or category…',
            icon: Icons.search,
            showClear: productSearchQuery.isNotEmpty,
            onClear: () {
              _productSearchController.clear();
              setState(() => productSearchQuery = '');
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border, width: 0.8),
          ),
          child: DropdownButton<String>(
            value: selectedProductCategory,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.expand_more, size: 20),
            items: productCategories
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _text,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => selectedProductCategory = v),
            dropdownColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        filteredProducts.isEmpty
            ? Center(
                child: Text(
                  'No products found',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _muted),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCrossAxisCount(width),
                  childAspectRatio: 0.92,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final selected = _isItemSelected(
                      product['name'], product['price'] as double);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? Theme.of(context).primaryColor.withOpacity(0.45)
                              : _border,
                          width: selected ? 1.1 : 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _text),
                                ),
                              ),
                              if (selected)
                                _chip('Added',
                                    bg: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    fg: Theme.of(context).primaryColor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _chip(product['category']),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                '₹${(product['price'] as double).toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).primaryColor),
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 28,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addItemToInvoice(product),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: Text('Add',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );

    final invoicePanel = Container(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: _buildInvoicePanel(),
        ),
      ),
    );

    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Sales'),
      appBar: AppBar(
        title: Text(
          "Product Sales",
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
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: productsCatalog),
                      const SizedBox(width: 12),
                      Expanded(flex: 4, child: invoicePanel),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        productsCatalog,
                        const SizedBox(height: 10),
                        invoicePanel,
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 30,
      height: 30,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border, width: 0.8),
          ),
          child: Icon(icon, size: 16, color: _text),
        ),
      ),
    );
  }

  Widget _billingLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w800, color: _text)),
        ],
      ),
    );
  }
}
