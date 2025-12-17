import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'customer_model.dart';
import 'add_customer.dart';
import 'dart:async';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _text = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _success = Color(0xFF10B981);

  // Sample services data
  List<Map<String, dynamic>> services = [
    {'name': 'Basic Haircut', 'category': 'Hair', 'duration': '30 min', 'price': 250.0},
    {'name': 'Manicure', 'category': 'Nails', 'duration': '45 min', 'price': 350.0},
    {'name': 'Hair Coloring', 'category': 'Hair', 'duration': '2 hours', 'price': 1200.0},
    {'name': 'Facial Treatment', 'category': 'Skin', 'duration': '1 hour', 'price': 800.0},
    {'name': 'Pedicure', 'category': 'Nails', 'duration': '1 hour', 'price': 400.0},
    {'name': 'Back Massage', 'category': 'Massage', 'duration': '45 min', 'price': 500.0},
    {'name': 'Waxing Full Legs', 'category': 'Waxing', 'duration': '1 hour', 'price': 600.0},
  ];

  // Sample products data
  List<Map<String, dynamic>> products = [
    {'name': 'Shampoo', 'category': 'Hair Care', 'price': 200.0},
    {'name': 'Conditioner', 'category': 'Hair Care', 'price': 180.0},
    {'name': 'Face Cream', 'category': 'Skin Care', 'price': 550.0},
    {'name': 'Nail Polish', 'category': 'Nails', 'price': 150.0},
    {'name': 'Hair Serum', 'category': 'Hair Care', 'price': 750.0},
    {'name': 'Body Lotion', 'category': 'Body Care', 'price': 300.0},
    {'name': 'Lip Balm', 'category': 'Lips Care', 'price': 120.0},
  ];

  // Sample clients data - expanded to match clients page
  List<Customer> clients = [
    Customer(
      id: '1',
      fullName: 'John Smith',
      mobile: '+1 234-567-8901',
      email: 'john.smith@email.com',
      dateOfBirth: '15/03/1985',
      gender: 'Male',
      country: 'United States',
      occupation: 'Software Engineer',
      address: '123 Main St, New York, NY 10001',
      note: 'Prefers morning appointments',
      lastVisit: '10/12/2025',
      totalBookings: 12,
      totalSpent: 1250.50,
      status: 'Active',
      createdAt: DateTime(2024, 8, 15),
      isOnline: true,
    ),
    Customer(
      id: '2',
      fullName: 'Sarah Johnson',
      mobile: '+1 234-567-8902',
      email: 'sarah.j@email.com',
      dateOfBirth: '22/07/1990',
      gender: 'Female',
      country: 'Canada',
      occupation: 'Marketing Manager',
      address: '456 Oak Ave, Toronto, ON M5H 2N2',
      note: 'Allergic to certain products',
      lastVisit: '05/12/2025',
      totalBookings: 8,
      totalSpent: 890.00,
      status: 'Active',
      createdAt: DateTime(2024, 9, 10),
      isOnline: false,
    ),
    Customer(
      id: '3',
      fullName: 'Michael Brown',
      mobile: '+1 234-567-8903',
      email: 'mbrown@email.com',
      dateOfBirth: '10/11/1988',
      gender: 'Male',
      country: 'United States',
      occupation: 'Doctor',
      address: '789 Pine Rd, Los Angeles, CA 90001',
      lastVisit: '15/11/2025',
      totalBookings: 5,
      totalSpent: 625.75,
      status: 'Active',
      createdAt: DateTime(2024, 10, 1),
      isOnline: true,
    ),
    Customer(
      id: '4',
      fullName: 'Emily Davis',
      mobile: '+1 234-567-8904',
      email: 'emily.davis@email.com',
      dateOfBirth: '05/01/1995',
      gender: 'Female',
      country: 'United Kingdom',
      occupation: 'Teacher',
      address: '321 Elm St, London, SW1A 1AA',
      note: 'VIP customer',
      lastVisit: '18/12/2025',
      totalBookings: 20,
      totalSpent: 2150.00,
      status: 'Active',
      createdAt: DateTime(2024, 7, 20),
      isOnline: false,
    ),
    Customer(
      id: '5',
      fullName: 'David Wilson',
      mobile: '+1 234-567-8905',
      dateOfBirth: '18/09/1982',
      gender: 'Male',
      country: 'Australia',
      occupation: 'Business Owner',
      address: '555 Beach Rd, Sydney, NSW 2000',
      totalBookings: 3,
      totalSpent: 345.00,
      status: 'Active',
      createdAt: DateTime(2024, 10, 25),
      isOnline: true,
    ),
    Customer(
      id: '6',
      fullName: 'Lisa Anderson',
      mobile: '+1 234-567-8906',
      email: 'lisa.anderson@email.com',
      dateOfBirth: '30/04/1992',
      gender: 'Female',
      country: 'United States',
      occupation: 'Nurse',
      address: '987 Maple Dr, Chicago, IL 60601',
      note: 'Referred by Emily Davis',
      totalBookings: 0,
      totalSpent: 0.00,
      status: 'Active',
      createdAt: DateTime(2024, 12, 17),
      isOnline: false,
    ),
  ];

  // Selected items for billing
  List<Map<String, dynamic>> selectedItems = [];

  // Selected client
  Customer? selectedClient;

  // Search controllers
  final TextEditingController _serviceProductSearchController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();

  // Category filters
  String? selectedServiceCategory;
  String? selectedProductCategory;

  // Search queries
  String serviceProductSearchQuery = '';
  String clientSearchQuery = '';

  // Timer for debouncing client search
  Timer? _clientSearchTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedServiceCategory = 'All';
    selectedProductCategory = 'All';

    // Important: rebuild when tab changes so list switches Service/Product instantly.
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceProductSearchController.dispose();
    _clientSearchController.dispose();
    _clientSearchTimer?.cancel();
    super.dispose();
  }

  // Filter services based on search and category
  List<Map<String, dynamic>> get filteredServices {
    return services.where((service) {
      final q = serviceProductSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          service['name'].toString().toLowerCase().contains(q) ||
          service['category'].toString().toLowerCase().contains(q);

      final matchesCategory = selectedServiceCategory == 'All' || service['category'].toString() == selectedServiceCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Filter products based on search and category
  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final q = serviceProductSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          product['name'].toString().toLowerCase().contains(q) ||
          product['category'].toString().toLowerCase().contains(q);

      final matchesCategory = selectedProductCategory == 'All' || product['category'].toString() == selectedProductCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Filter clients based on search
  List<Customer> get filteredClients {
    return clients.where((client) {
      final query = clientSearchQuery.toLowerCase();
      return query.isEmpty ||
          client.fullName.toLowerCase().contains(query) ||
          (client.email?.toLowerCase().contains(query) ?? false) ||
          client.mobile.toLowerCase().contains(query);
    }).toList();
  }

  // Get unique categories for services
  List<String> get serviceCategories {
    final categories = <String>{'All'};
    for (var service in services) {
      if (service['category'] is String) categories.add(service['category']);
    }
    return categories.toList()..sort();
  }

  // Get unique categories for products
  List<String> get productCategories {
    final categories = <String>{'All'};
    for (var product in products) {
      if (product['category'] is String) categories.add(product['category']);
    }
    return categories.toList()..sort();
  }

  // Add item to billing
  void _addItemToBilling(Map<String, dynamic> item, {bool isService = false}) {
    setState(() {
      selectedItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': item['name'],
        'category': item['category'],
        'price': item['price'],
        'duration': isService ? item['duration'] : null,
        'quantity': 1,
        'isService': isService,
      });
    });
  }

  void _removeItemFromBilling(int id) {
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
    return selectedItems.fold(0.0, (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int));
  }

  double get tax => 0.0;
  double get total => subtotal + tax;

  void _clearBilling() {
    setState(() {
      selectedItems.clear();
      selectedClient = null;
    });
  }

  void _navigateToAddClient() async {
    final newClient = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomer()),
    );

    if (newClient != null) {
      setState(() {
        clients.add(newClient);
        selectedClient = newClient;
      });
    }
  }

  // ---------------- UI helpers ----------------
  TextStyle get _h1 => GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _text);
  TextStyle get _h2 => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _text);
  TextStyle get _sub => GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500, color: _muted);
  TextStyle get _th => GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _muted);
  TextStyle get _td => GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _text);

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    bool showClear = false,
    VoidCallback? onClear,
  })
  
  {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: showClear ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onClear) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
          Text(text, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: fg ?? _muted)),
        ],
      ),
    );
  }

  bool _isItemSelected(String name, double price) {
    return selectedItems.any((x) => x['name'] == name && (x['price'] as double) == price);
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 1300) return 4;
    if (width >= 980) return 3;
    return 2;
  }

  Widget _tableHeader(List<Widget> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(children: cells),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _border);

  Widget _buildBillingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Billing', style: _h2),
        const SizedBox(height: 1),
        Text('Review items and process payment', style: _sub),
        const SizedBox(height: 10),

        // Client Selection title like screenshot
        Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: _muted),
            const SizedBox(width: 6),
            Text('Client Selection', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
          ],
        ),
        const SizedBox(height: 8),

        Stack(
          children: [
            TextField(
              controller: _clientSearchController,
              onChanged: (v) {
                // Debounce the search to improve performance
                _clientSearchTimer?.cancel();
                _clientSearchTimer = Timer(const Duration(milliseconds: 300), () {
                  setState(() => clientSearchQuery = v);
                });
              },
              decoration: _fieldDecoration(
                hint: 'Search clients by name, email, or phone...',
                icon: Icons.search,
                showClear: clientSearchQuery.isNotEmpty,
                onClear: () {
                  _clientSearchController.clear();
                  setState(() => clientSearchQuery = '');
                },
              ),
            ),
            if (clientSearchQuery.isNotEmpty && filteredClients.isNotEmpty)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: filteredClients.take(5).length,
                    separatorBuilder: (_, __) => _divider(),
                    itemBuilder: (_, i) {
                      final cst = filteredClients[i];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(cst.fullName, style: _td),
                        subtitle: Text(cst.mobile, style: _sub),
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: _primary.withValues(alpha: 0.1),
                          child: Text(
                            cst.fullName.isNotEmpty ? cst.fullName[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _primary),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedClient = cst;
                            clientSearchQuery = '';
                            _clientSearchController.clear();
                          });
                          // Close the dropdown by removing focus
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _navigateToAddClient,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add New Client', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _text,
              side: const BorderSide(color: _border, width: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (selectedClient != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border, width: 0.8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _primary.withValues(alpha: 0.12),
                  child: Text(
                    selectedClient!.fullName.isNotEmpty ? selectedClient!.fullName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedClient!.fullName, style: _td),
                      Text(selectedClient!.mobile, style: _sub),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => selectedClient = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Items table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border, width: 0.8),
          ),
          child: Column(
            children: [
              _tableHeader([
                Expanded(flex: 4, child: Text('Item', style: _th)),
                Expanded(flex: 2, child: Text('Price', style: _th)),
                Expanded(flex: 3, child: Center(child: Text('Qty', style: _th))),
                Expanded(flex: 2, child: Text('Total', style: _th)),
                const SizedBox(width: 36), // actions space
              ]),
              SizedBox(
                height: 200, // keeps POS feel + ensures totals always visible
                child: selectedItems.isEmpty
                    ? Center(child: Text('No items added yet', style: GoogleFonts.poppins(color: _muted, fontWeight: FontWeight.w600)))
                    : ListView.separated(
                        itemCount: selectedItems.length,
                        separatorBuilder: (_, __) => _divider(),
                        itemBuilder: (_, index) {
                          final item = selectedItems[index];
                          final qty = item['quantity'] as int;
                          final priceEach = item['price'] as double;
                          final lineTotal = priceEach * qty;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: _td),
                                      if (item['duration'] != null) Text(item['duration'], style: _sub),
                                    ],
                                  ),
                                ),
                                Expanded(flex: 2, child: Text('₹${priceEach.toStringAsFixed(2)}', style: _td)),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _qtyButton(
                                        icon: Icons.remove,
                                        onTap: () => _updateItemQuantity(item['id'], qty - 1),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('$qty', style: _td),
                                      const SizedBox(width: 10),
                                      _qtyButton(
                                        icon: Icons.add,
                                        onTap: () => _updateItemQuantity(item['id'], qty + 1),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(flex: 2, child: Text('₹${lineTotal.toStringAsFixed(2)}', style: _td)),
                                SizedBox(
                                  width: 36,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () => _removeItemFromBilling(item['id']),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Totals
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Column(
            children: [
              _billingLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
              _billingLine('Tax (0%)', '₹${tax.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _text)),
                  Text('₹${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: _text)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Footer actions
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _clearBilling,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Clear', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    side: const BorderSide(color: _border, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment processed successfully!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Proceed to Payment', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _tabController.index == 0 ? filteredServices : filteredProducts;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Sales'),
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Sales', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        elevation: 0.4,
        iconTheme: const IconThemeData(color: _text),
        toolbarHeight: 48,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;

            final left = SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: Text('Sales Overview', style: _h1)),
                      _chip(
                        _tabController.index == 0 ? 'Services' : 'Products',
                        bg: const Color(0xFFEFF6FF),
                        fg: _primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Filters card (tabs + search + category)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: _muted,
                            labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                            tabs: const [Tab(text: 'Service'), Tab(text: 'Product')],
                            onTap: (_) => setState(() {}),
                            dividerHeight: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _serviceProductSearchController,
                          onChanged: (v) => setState(() => serviceProductSearchQuery = v),
                          decoration: _fieldDecoration(
                            hint: 'Search by name or category…',
                            icon: Icons.search,
                            showClear: serviceProductSearchQuery.isNotEmpty,
                            onClear: () {
                              _serviceProductSearchController.clear();
                              setState(() => serviceProductSearchQuery = '');
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
                            value: _tabController.index == 0 ? selectedServiceCategory : selectedProductCategory,
                            underline: const SizedBox(),
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more, size: 20),
                            items: (_tabController.index == 0 ? serviceCategories : productCategories)
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat, style: GoogleFonts.poppins(fontSize: 12, color: _text, fontWeight: FontWeight.w600)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              if (_tabController.index == 0) {
                                selectedServiceCategory = v;
                              } else {
                                selectedProductCategory = v;
                              }
                            }),
                            dropdownColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Catalog grid
                  SizedBox(
                    height: 400, // Fixed height to prevent overflow
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'No items found',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _muted),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _gridCrossAxisCount(constraints.maxWidth),
                              childAspectRatio: 0.92,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isService = _tabController.index == 0;
                              final selected = _isItemSelected(item['name'], item['price'] as double);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: selected ? _primary.withValues(alpha: 0.45) : _border, width: selected ? 1.1 : 0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
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
                                              item['name'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: _text),
                                            ),
                                          ),
                                          if (selected) _chip('Added', bg: const Color(0xFFEFF6FF), fg: _primary),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 5,
                                        runSpacing: 5,
                                        children: [
                                          _chip(item['category']),
                                          if (isService)
                                            _chip(
                                              item['duration'],
                                              bg: const Color(0xFFEFF6FF),
                                              fg: _primary,
                                              icon: Icons.schedule,
                                            ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${(item['price'] as double).toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _primary),
                                          ),
                                          const Spacer(),
                                          SizedBox(
                                            height: 28,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _addItemToBilling(item, isService: isService),
                                              icon: const Icon(Icons.add, size: 14),
                                              label: Text('Add', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  ),
                ],
              ),
            );

            final billingPanel = Container(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: _buildBillingPanel(),
                ),
              ),
            );

            return Padding(
              padding: const EdgeInsets.all(12),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: left),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: billingPanel),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(width: double.infinity, child: left),
                          const SizedBox(height: 10),
                          billingPanel,
                        ],
                      ),
                    ),
            );
          },
        ),
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
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: _text)),
        ],
      ),
    );
  }
}
