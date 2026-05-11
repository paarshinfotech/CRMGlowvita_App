import 'package:flutter/material.dart';
import 'package:glowvita/vendor_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/custom_drawer.dart';
import 'customer_model.dart';
import 'add_customer.dart';
import 'services/api_service.dart';
import 'addon_model.dart';
import 'dart:async';
import 'Notification.dart';
import 'my_Profile.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Exact colors from screenshot ──
  static const Color _bg = Colors.white;
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _text = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF5D121B);
  static const Color _primaryDark = Color(0xFF3F2B3E);

  List<Service> services = [];
  List<Product> products = [];
  List<AddOn> allAddOns = [];
  String? vendorId;
  bool isLoading = true;

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

  VendorProfile? vendorProfile;
  List<StaffMember> staffList = [];
  List<Map<String, dynamic>> selectedItems = [];
  Customer? selectedClient;
  StaffMember? selectedStaff;
  bool applyTax = false;
  double profileTaxRate = 0.0;
  String paymentMethod = 'Cash';

  final TextEditingController _serviceProductSearchController =
      TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();

  String? selectedServiceCategory;
  String? selectedProductCategory;
  String serviceProductSearchQuery = '';
  String clientSearchQuery = '';

  final FocusNode _clientSearchFocusNode = FocusNode();
  bool _showClientDropdown = false;
  Timer? _clientSearchTimer;

  Widget _buildInitialAvatar() {
    return Text(
      (vendorProfile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedServiceCategory = 'All';
    selectedProductCategory = 'All';
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _clientSearchFocusNode.addListener(() {
      if (!_clientSearchFocusNode.hasFocus)
        setState(() => _showClientDropdown = false);
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final fetchedServices = await ApiService.getServices();
      final fetchedProducts = await ApiService.getProducts();
      final fetchedClients = await ApiService.getClients();
      final fetchedAddOns = await ApiService.getAddOns();
      final fetchedVendor = await ApiService.getVendorProfile();
      setState(() {
        services = fetchedServices;
        products = fetchedProducts;
        clients = fetchedClients;
        allAddOns = fetchedAddOns;
        vendorProfile = fetchedVendor;
        vendorId = fetchedVendor.id;
        profileTaxRate = (fetchedVendor.taxes?.taxValue ?? 0).toDouble();
        ApiService.getStaff().then((list) {
          if (mounted)
            setState(() {
              staffList = list;
              if (staffList.isNotEmpty && selectedStaff == null)
                selectedStaff = staffList.first;
            });
        });
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceProductSearchController.dispose();
    _clientSearchController.dispose();
    _clientSearchFocusNode.dispose();
    _clientSearchTimer?.cancel();
    super.dispose();
  }

  List<Service> get filteredServices => services.where((s) {
    final q = serviceProductSearchQuery.toLowerCase();
    return (q.isEmpty ||
            (s.name?.toLowerCase().contains(q) ?? false) ||
            (s.category?.toLowerCase().contains(q) ?? false)) &&
        (selectedServiceCategory == 'All' ||
            s.category == selectedServiceCategory);
  }).toList();

  List<Product> get filteredProducts => products.where((p) {
    final q = serviceProductSearchQuery.toLowerCase();
    return (q.isEmpty ||
            (p.productName?.toLowerCase().contains(q) ?? false) ||
            (p.category?.toLowerCase().contains(q) ?? false)) &&
        (selectedProductCategory == 'All' ||
            p.category == selectedProductCategory);
  }).toList();

  List<Customer> get filteredClients => clients.where((c) {
    final q = clientSearchQuery.toLowerCase();
    return q.isEmpty ||
        c.fullName.toLowerCase().contains(q) ||
        (c.email?.toLowerCase().contains(q) ?? false) ||
        c.mobile.toLowerCase().contains(q);
  }).toList();

  List<String> get serviceCategories {
    final cats = <String>{'All'};
    for (var s in services) {
      if (s.category != null) cats.add(s.category!);
    }
    return cats.toList()..sort();
  }

  List<String> get productCategories {
    final cats = <String>{'All'};
    for (var p in products) {
      if (p.category != null) cats.add(p.category!);
    }
    return cats.toList()..sort();
  }

  void _addItemToBilling(
    dynamic item, {
    bool isService = false,
    List<AddOn>? selectedAddOns,
  }) {
    // Check for mixed billing (services vs products)
    if (isService && selectedItems.any((i) => i['isService'] == false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot add service to a product bill. Please clear products first.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!isService && selectedItems.any((i) => i['isService'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot add product to a service bill. Please clear services first.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String itemId = isService
        ? (item as Service).id ?? ''
        : (item as Product).id ?? '';
    if (selectedItems.any((i) => i['sourceId'] == itemId)) return;

    if (!isService && (item as Product).stock == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (isService && selectedAddOns == null) {
      final serviceId = (item as Service).id;
      final relevantAddOns = allAddOns
          .where((a) => a.mappedServices?.contains(serviceId) ?? false)
          .toList();
      if (relevantAddOns.isNotEmpty) {
        _showAddOnsDialog(item, relevantAddOns);
        return;
      }
    }
    setState(() {
      final String name;
      final String category;
      final double price;
      final String? duration;
      if (isService) {
        final s = item as Service;
        name = s.name ?? '';
        category = s.category ?? 'Uncategorized';
        price =
            ((s.discountedPrice != null && s.discountedPrice! > 0)
                    ? s.discountedPrice!
                    : (s.price ?? 0))
                .toDouble();
        duration = '${s.duration} min';
      } else {
        final p = item as Product;
        name = p.productName ?? '';
        category = p.category ?? 'Uncategorized';
        price =
            ((p.salePrice != null && p.salePrice! > 0)
                    ? p.salePrice!
                    : (p.price ?? 0))
                .toDouble();
        duration = null;
      }
      selectedItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'sourceId': isService ? (item as Service).id : (item as Product).id,
        'name': name,
        'category': category,
        'price': price,
        'duration': duration,
        'quantity': 1,
        'isService': isService,
        'staffIds': isService ? (item as Service).staff : null,
        'addons':
            selectedAddOns
                ?.map(
                  (a) => {
                    'id': a.id,
                    'name': a.name,
                    'price': a.price,
                    'duration': a.duration,
                  },
                )
                .toList() ??
            [],
      });
    });
  }

  void _showAddOnsDialog(Service service, List<AddOn> relevantAddOns) {
    List<AddOn> selected = [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Add-Ons',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _text,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      'Select add-ons for ${service.name}',
                      style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: relevantAddOns.map((addon) {
                            final isSelected = selected.contains(addon);
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                addon.name ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _text,
                                ),
                              ),
                              subtitle: Text(
                                'Time: ${addon.duration} min • Price: ₹${addon.price}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (val) => setDialogState(() {
                                if (val == true)
                                  selected.add(addon);
                                else
                                  selected.remove(addon);
                              }),
                              activeColor: _primaryDark,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _addItemToBilling(
                                service,
                                isService: true,
                                selectedAddOns: [],
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _addItemToBilling(
                                service,
                                isService: true,
                                selectedAddOns: selected,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Add to Cart',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
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
        );
      },
    );
  }

  void _removeItemFromBilling(int id) =>
      setState(() => selectedItems.removeWhere((item) => item['id'] == id));

  void _updateItemQuantity(int id, int quantity) {
    if (quantity <= 0) return;
    setState(() {
      final index = selectedItems.indexWhere((item) => item['id'] == id);
      if (index != -1) selectedItems[index]['quantity'] = quantity;
    });
  }

  double get subtotal {
    final bool showingServices = _tabController.index == 0;
    return selectedItems
        .where((item) => item['isService'] == showingServices)
        .fold(0.0, (sum, item) {
          final double price = item['price'] as double;
          final int qty = item['quantity'] as int;
          final List addons = item['addons'] as List? ?? [];
          double addonsPrice = addons.fold(
            0.0,
            (s, a) => s + ((a['price'] as num?)?.toDouble() ?? 0.0),
          );
          return sum + (price + addonsPrice) * qty;
        });
  }

  double get tax => applyTax ? (subtotal * (profileTaxRate / 100)) : 0.0;
  double get total => subtotal + tax;

  void _clearBilling() => setState(() {
    final bool showingServices = _tabController.index == 0;
    selectedItems.removeWhere((item) => item['isService'] == showingServices);
    // Only clear client if no items are left in either category,
    // or keep it shared? Usually client is shared. Let's keep it shared.
    if (selectedItems.isEmpty) selectedClient = null;
  });

  void _showPaymentOptionsDialog() {
    String? selectedMethod;
    bool isProcessing = false;
    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Options',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _text,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Amount: ₹${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF635B63),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedClient == null) return;
                          setDialogState(() => isProcessing = true);
                          try {
                            final payload = {
                              "clientId": selectedClient!.id,
                              "clientInfo": {
                                "fullName": selectedClient!.fullName,
                                "phone": selectedClient!.mobile,
                              },
                              "paymentMethod": selectedMethod ?? paymentMethod,
                              "subtotal": subtotal,
                              "taxRate": applyTax ? profileTaxRate : 0.0,
                              "taxAmount": tax,
                              "platformFee": 0,
                              "totalAmount": total,
                              "items": selectedItems
                                  .where(
                                    (item) =>
                                        item['isService'] ==
                                        (_tabController.index == 0),
                                  )
                                  .map(
                                    (item) => {
                                      "itemId": item['sourceId'],
                                      "itemType": (item['isService'] ?? true)
                                          ? "Service"
                                          : "Product",
                                      "name": item['name'],
                                      "price": item['price'],
                                      "quantity": item['quantity'],
                                      "totalPrice":
                                          (item['price'] as num) *
                                          (item['quantity'] as num),
                                      "staffMember": {
                                        "id": selectedStaff?.id ?? "",
                                        "name":
                                            selectedStaff?.fullName ??
                                            "No Staff",
                                      },
                                      "addOns": (item['addons'] as List)
                                          .map(
                                            (a) => {
                                              "id": a['id'],
                                              "name": a['name'],
                                              "price": a['price'],
                                            },
                                          )
                                          .toList(),
                                    },
                                  )
                                  .toList(),
                              "status": "Paid",
                              "billingDate": DateTime.now().toIso8601String(),
                            };
                            final result = await ApiService.createBilling(
                              payload,
                            );
                            if (result['success'] == true && context.mounted) {
                              Navigator.pop(context);
                              _showInvoiceSummaryDialog(
                                context,
                                result['data'],
                              );
                              _clearBilling();
                            }
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error saving order: $e'),
                                ),
                              );
                          } finally {
                            if (context.mounted)
                              setDialogState(() => isProcessing = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Save Order',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'PAYMENT METHODS',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C8BA1),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _paymentMethodButton(
                          'Cash',
                          Icons.money,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m,
                        ),
                        _paymentMethodButton(
                          'QR Code',
                          Icons.qr_code,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m,
                        ),
                        _paymentMethodButton(
                          'Debit Card',
                          Icons.credit_card,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m,
                        ),
                        _paymentMethodButton(
                          'Credit Card',
                          Icons.credit_card,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m,
                        ),
                        _paymentMethodButton(
                          'Net Banking',
                          Icons.account_balance,
                          setDialogState,
                          selectedMethod,
                          (m) {
                            selectedMethod = m;
                            setState(() => paymentMethod = m);
                          },
                        ),
                      ],
                    ),
                    if (isProcessing) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _paymentMethodButton(
    String label,
    IconData icon,
    Function setState,
    String? selected,
    Function(String) onSelect,
  ) {
    bool isSelected = selected == label;
    return InkWell(
      onTap: () {
        onSelect(label);
        setState(() {});
        _processDirectSale(label);
      },
      child: Container(
        width: 125,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryDark : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processDirectSale(String method) async {
    if (selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client first')),
      );
      return;
    }
    if (vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor details not loaded yet')),
      );
      return;
    }
    try {
      final currentTabItems = selectedItems
          .where((i) => i['isService'] == (_tabController.index == 0))
          .toList();

      if (currentTabItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items in the current billing tab')),
        );
        return;
      }

      final firstItem = currentTabItems.firstWhere(
        (i) => i['isService'] == true,
        orElse: () => currentTabItems[0],
      );
      final defaultStaff = staffList.isNotEmpty ? staffList[0] : null;
      final Map<String, dynamic> appointmentData = {
        "client": selectedClient!.id,
        "clientName": selectedClient!.fullName,
        "vendorId": vendorId,
        "service": firstItem['sourceId'],
        "serviceName": firstItem['name'],
        "staff": defaultStaff?.id ?? vendorId ?? "",
        "staffName": defaultStaff?.fullName ?? "Staff Member",
        "date": DateTime.now().toIso8601String().split('T')[0],
        "startTime": DateTime.now()
            .toIso8601String()
            .split('T')[1]
            .substring(0, 5),
        "endTime": DateTime.now()
            .add(const Duration(minutes: 30))
            .toIso8601String()
            .split('T')[1]
            .substring(0, 5),
        "duration": 30,
        "amount": total,
        "totalAmount": total,
        "status": "Paid",
        "services": currentTabItems
            .where((i) => i['isService'] == true)
            .map(
              (i) => {
                "serviceId": i['sourceId'],
                "price": i['price'],
                "addons": (i['addons'] as List? ?? [])
                    .map((a) => a['id'])
                    .toList(),
              },
            )
            .toList(),
        "products": currentTabItems
            .where((i) => i['isService'] == false)
            .map(
              (i) => {
                "productId": i['sourceId'],
                "price": i['price'],
                "quantity": i['quantity'],
              },
            )
            .toList(),
      };
      final response = await ApiService.createAppointment(appointmentData);
      if (response['success'] == true || response['data'] != null) {
        final appointmentId = response['data'] != null
            ? response['data']['_id']
            : response['_id'];
        await ApiService.collectPayment({
          "appointmentId": appointmentId,
          "amount": total,
          "paymentMethod": method.toLowerCase().replaceAll(' ', ''),
          "paymentDate": DateTime.now().toUtc().toIso8601String(),
          "notes": "Direct Sale from POS",
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale processed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _clearBilling();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing sale: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  bool _isItemSelected(String sourceId) =>
      selectedItems.any((x) => x['sourceId'] == sourceId);

  // ─── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final items = _tabController.index == 0
        ? filteredServices
        : filteredProducts;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Sales'),
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
          'Sales',
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
                  child:
                      (vendorProfile != null &&
                          vendorProfile!.profileImage.isNotEmpty)
                      ? Image.network(
                          vendorProfile!.profileImage,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;

            // ── LEFT: Catalog ────────────────────────────────────────────────────
            final catalogWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab bar — white bg, maroon underline indicator
                Container(
                  color: _surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: _primary,
                    unselectedLabelColor: _muted,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    indicator: UnderlineTabIndicator(
                      borderSide: const BorderSide(color: _primary, width: 2.5),
                      insets: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    dividerColor: _border,
                    tabs: const [
                      Tab(text: 'Services'),
                      Tab(text: 'Products'),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading
                        Text(
                          _tabController.index == 0
                              ? 'Service Catalog'
                              : 'Product Catalog',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Search
                        _searchField(
                          controller: _serviceProductSearchController,
                          hint: _tabController.index == 0
                              ? 'Search services...'
                              : 'Search products...',
                          onChanged: (v) =>
                              setState(() => serviceProductSearchQuery = v),
                          onClear: () {
                            _serviceProductSearchController.clear();
                            setState(() => serviceProductSearchQuery = '');
                          },
                          showClear: serviceProductSearchQuery.isNotEmpty,
                        ),
                        const SizedBox(height: 8),

                        // Category dropdown
                        _categoryDropdown(),
                        const SizedBox(height: 10),

                        // Items
                        isLoading
                            ? const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Text(
                                    'No items found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                              )
                            : _catalogList(items),
                      ],
                    ),
                  ),
                ),
              ],
            );

            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: catalogWidget),
                      Container(
                        width: 380,
                        decoration: const BoxDecoration(
                          color: _surface,
                          border: Border(left: BorderSide(color: _border)),
                        ),
                        child: _buildBillingPanel(),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        bottom:
                            80, // Space for the collapsed bottom sheet handle area
                        child: catalogWidget,
                      ),
                      DraggableScrollableSheet(
                        initialChildSize: 0.12,
                        minChildSize: 0.12,
                        maxChildSize: 0.9,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Handle
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Summary bar when collapsed
                                if (selectedItems.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${selectedItems.length} Items Selected',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _primary,
                                          ),
                                        ),
                                        Text(
                                          'Total: ₹${total.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: _buildBillingPanel(
                                    scrollController: scrollController,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  // ─── Catalog helpers ─────────────────────────────────────────────────────────

  Widget _searchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    required bool showClear,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 13, color: _text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF94A3B8),
          size: 19,
        ),
        suffixIcon: showClear
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        isDense: true,
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tabController.index == 0
              ? selectedServiceCategory
              : selectedProductCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _muted),
          style: GoogleFonts.poppins(fontSize: 13, color: _text),
          items:
              (_tabController.index == 0
                      ? serviceCategories
                      : productCategories)
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        style: GoogleFonts.poppins(fontSize: 13, color: _text),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (v) => setState(() {
            if (_tabController.index == 0)
              selectedServiceCategory = v;
            else
              selectedProductCategory = v;
          }),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _catalogList(List items) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final item = items[index];
          final isService = _tabController.index == 0;
          final String name;
          final String category;
          final double price;
          final double? regularPrice;
          final String? duration;

          if (isService) {
            final s = item as Service;
            name = s.name ?? '';
            category = s.category ?? 'Uncategorized';
            price =
                ((s.discountedPrice != null && s.discountedPrice! > 0)
                        ? s.discountedPrice!
                        : (s.price ?? 0))
                    .toDouble();
            regularPrice = (s.discountedPrice != null && s.discountedPrice! > 0)
                ? (s.price ?? 0).toDouble()
                : null;
            duration = '${s.duration} min';
          } else {
            final p = item as Product;
            name = p.productName ?? '';
            category = p.category ?? 'Uncategorized';
            price =
                ((p.salePrice != null && p.salePrice! > 0)
                        ? p.salePrice!
                        : (p.price ?? 0))
                    .toDouble();
            regularPrice = (p.salePrice != null && p.salePrice! > 0)
                ? (p.price ?? 0).toDouble()
                : null;
            duration = null;
          }

          final bool isOutOfStock = !isService && (item as Product).stock == 0;
          final bool isSelected = _isItemSelected(
            isService ? (item as Service).id ?? '' : (item as Product).id ?? '',
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // Name + category
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                      Text(
                        category,
                        style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                ),

                // Price column
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}.00',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: regularPrice != null ? _primary : _text,
                        ),
                      ),
                      if (regularPrice != null)
                        Text(
                          '₹${regularPrice.toStringAsFixed(0)}.00',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),

                // Duration (services) or spacer (products)
                if (isService)
                  Expanded(
                    flex: 2,
                    child: Text(
                      duration ?? '',
                      style: GoogleFonts.poppins(fontSize: 12, color: _text),
                    ),
                  )
                else
                  const Spacer(flex: 2),

                // Add / selected button — circle style matching screenshot
                _addCircleButton(
                  isOutOfStock: isOutOfStock,
                  isSelected: isSelected,
                  onTap: isOutOfStock
                      ? null
                      : () => _addItemToBilling(item, isService: isService),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _addCircleButton({
    required bool isOutOfStock,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Out of\nStock',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 9, color: _muted),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected ? _primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _primaryDark : _border,
            width: 1.5,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check : Icons.add,
          size: 17,
          color: isSelected ? Colors.white : _text,
        ),
      ),
    );
  }

  // ─── Billing Panel ────────────────────────────────────────────────────────────
  Widget _buildBillingPanel({ScrollController? scrollController}) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Text(
              'Billing',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Client Selection label ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 17,
                  color: Colors.blue.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Client Selection',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Client search (purple border) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _clientSearchController,
              focusNode: _clientSearchFocusNode,
              onTap: () => setState(() => _showClientDropdown = true),
              onChanged: (v) {
                _clientSearchTimer?.cancel();
                _clientSearchTimer = Timer(
                  const Duration(milliseconds: 300),
                  () {
                    setState(() {
                      clientSearchQuery = v;
                      _showClientDropdown = true;
                    });
                  },
                );
              },
              style: GoogleFonts.poppins(fontSize: 13, color: _text),
              decoration: InputDecoration(
                hintText: 'Search clients by name, email or phone...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
                suffixIcon: clientSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _clientSearchController.clear();
                          setState(() => clientSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5CF6),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 2,
                  ),
                ),
                isDense: true,
              ),
            ),
          ),

          // Client dropdown results
          if (_showClientDropdown &&
              selectedClient == null &&
              filteredClients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredClients.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final c = filteredClients[i];
                    return InkWell(
                      onTap: () => setState(() {
                        selectedClient = c;
                        clientSearchQuery = '';
                        _clientSearchController.clear();
                        _showClientDropdown = false;
                        _clientSearchFocusNode.unfocus();
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: Text(
                                c.fullName.isNotEmpty
                                    ? c.fullName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.fullName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _text,
                                  ),
                                ),
                                Text(
                                  c.mobile,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: _muted,
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
            ),

          const SizedBox(height: 10),

          // ── Selected client card ──
          if (selectedClient != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFD4B8C0),
                      child: Text(
                        selectedClient!.fullName.isNotEmpty
                            ? selectedClient!.fullName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedClient!.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                          Text(
                            selectedClient!.mobile,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => selectedClient = null),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Billing Items (Separated) ──
          // ── Billing Items (Separated) ──
          if (_tabController.index == 0 &&
              selectedItems.any((i) => i['isService'] == true)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 15, 14, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 14,
                      color: _primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Services',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border.withOpacity(0.5)),
              ),
              child: Column(
                children: selectedItems
                    .where((i) => i['isService'] == true)
                    .map((item) => _billingItemCard(item))
                    .toList(),
              ),
            ),
          ],
          if (_tabController.index == 1 &&
              selectedItems.any((i) => i['isService'] == false)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 15, 14, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: _primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Products',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border.withOpacity(0.5)),
              ),
              child: Column(
                children: selectedItems
                    .where((i) => i['isService'] == false)
                    .map((item) => _billingItemCard(item))
                    .toList(),
              ),
            ),
          ],

          // ── Add New Client button ── (shown when no client selected)
          if (selectedClient == null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCustomer()),
                    ).then((v) {
                      if (v == true) _fetchData();
                    }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 16, color: _text),
                      const SizedBox(width: 6),
                      Text(
                        'Add New Client',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Totals ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              children: [
                // Tax checkbox row
                if (_tabController.index == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: applyTax,
                            activeColor: _primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) =>
                                setState(() => applyTax = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Apply Taxes (${profileTaxRate.toStringAsFixed(0)}%)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _text,
                            ),
                          ),
                        ),
                        Text(
                          'Configured in profile',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Subtotal row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                    ),
                    Text(
                      '₹ ${subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                  ],
                ),

                if (applyTax) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax (${profileTaxRate.toStringAsFixed(1)}%)',
                        style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                      ),
                      Text(
                        '₹ ${tax.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: _border),
                const SizedBox(height: 10),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    Text(
                      '₹ ${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: _clearBilling,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed:
                              (selectedItems.isEmpty || selectedClient == null)
                              ? null
                              : _showPaymentOptionsDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryDark,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFCBD5E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Proceed to Payment',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingItemCard(Map<String, dynamic> item) {
    final qty = item['quantity'] as int;
    final priceEach = item['price'] as double;
    final List addons = item['addons'] as List? ?? [];
    final double addonsTotal = addons.fold(
      0.0,
      (s, a) => s + ((a['price'] as num?)?.toDouble() ?? 0.0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + addon chips + trash icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _text,
                        ),
                      ),
                      ...addons.map(
                        (a) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 10, color: _muted),
                              const SizedBox(width: 2),
                              Text(
                                a['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeItemFromBilling(item['id']),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Row 2: clock + duration
            if (item['duration'] != null)
              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 13,
                    color: _muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ([
                      item['duration'] as String?,
                      ...addons.map<String?>(
                        (a) => a['duration'] != null
                            ? '${a['duration']} min'
                            : null,
                      ),
                    ].whereType<String>()).join(' + '),
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Row 3: Assign Staff (left) + Quantity stepper (right)
            if (_tabController.index == 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Staff dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Staff',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: _border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<StaffMember?>(
                              value: item['staff'],
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: _muted,
                              ),
                              hint: Text(
                                'Select',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _muted,
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _text,
                              ),
                              items: staffList
                                  .where((s) {
                                    final ids = item['staffIds'] as List?;
                                    if (ids == null || ids.isEmpty) return true;
                                    return ids.contains(s.id);
                                  })
                                  .map(
                                    (s) => DropdownMenuItem<StaffMember?>(
                                      value: s,
                                      child: Text(
                                        s.fullName ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: _text,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => item['staff'] = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _qtyBtn(
                            icon: Icons.remove,
                            onTap: () =>
                                _updateItemQuantity(item['id'], qty - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$qty',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _text,
                              ),
                            ),
                          ),
                          _qtyBtn(
                            icon: Icons.add,
                            onTap: () =>
                                _updateItemQuantity(item['id'], qty + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Row 4: price display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${priceEach.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    if (addonsTotal > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 12, color: _muted),
                    ],
                  ],
                ),
                Text(
                  '₹${priceEach.toStringAsFixed(2)}${addonsTotal > 0 ? ' + ₹${addonsTotal.toStringAsFixed(2)}' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ],
            ),

            // Total line (if qty > 1)
            if (qty > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total ₹${((priceEach + addonsTotal) * qty).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 14, color: _text),
      ),
    );
  }

  // ─── Invoice Summary Dialog ──────────────────────────────────────────────────
  void _showInvoiceSummaryDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final createdAt =
        DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
    final clientInfo = data['clientInfo'] ?? {};
    final items = data['items'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Invoice Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: _muted, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade100, height: 12.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E5BFF), Color(0xFF1B3BBE)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['invoiceNumber'] ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    data['status'] ?? 'Paid',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${dateFormat.format(createdAt)} by ${clientInfo['fullName'] ?? 'Guest'}',
                              style: GoogleFonts.poppins(
                                fontSize: 9.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildSummarySection(
                        title: 'Quick Actions',
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43303F),
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Rebook Client',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                _summaryActionBtn(
                                  Icons.email_outlined,
                                  'Email',
                                ),
                                SizedBox(width: 6.w),
                                _summaryActionBtn(
                                  Icons.print_outlined,
                                  'Download',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildSummarySection(
                        title: 'Client Information',
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: _muted,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientInfo['fullName'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: _text,
                                    ),
                                  ),
                                  Text(
                                    '${clientInfo['phone'] ?? 'N/A'} • ${clientInfo['email'] ?? 'N/A'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: _muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildSummarySection(
                        title: 'Invoice Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _infoCard(
                                  'Payment',
                                  data['paymentMethod'] ?? 'Cash',
                                ),
                                SizedBox(width: 8.w),
                                _infoCard(
                                  'Status',
                                  data['status'] ?? 'Paid',
                                  isStatus: true,
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Services',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                            ),
                            Divider(color: Colors.grey.shade100, height: 8.h),
                            ...items.map(
                              (item) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['name'] ?? 'N/A',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      '₹${(item['price'] ?? 0).toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  _priceLine(
                                    'Subtotal',
                                    '₹${(data['subtotal'] ?? 0).toStringAsFixed(2)}',
                                  ),
                                  if ((data['discountAmount'] ?? 0) > 0)
                                    _priceLine(
                                      'Discount',
                                      '-₹${(data['discountAmount'] ?? 0).toStringAsFixed(2)}',
                                      color: const Color(0xFF22C55E),
                                    ),
                                  if ((data['taxAmount'] ?? 0) > 0)
                                    _priceLine(
                                      'Tax (${data['taxRate'] ?? 0}%)',
                                      '₹${(data['taxAmount'] ?? 0).toStringAsFixed(2)}',
                                    ),
                                  if ((data['platformFee'] ?? 0) > 0)
                                    _priceLine(
                                      'Platform Fee',
                                      '₹${(data['platformFee'] ?? 0).toStringAsFixed(2)}',
                                    ),
                                  Divider(
                                    height: 12.h,
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                  _priceLine(
                                    'Total',
                                    '₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                    isBold: true,
                                  ),
                                  if ((data['balance'] ?? 0) > 0)
                                    _priceLine(
                                      'Balance',
                                      '₹${(data['balance'] ?? 0).toStringAsFixed(2)}',
                                      isBold: true,
                                      color: const Color(0xFFEF4444),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43303F),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          SizedBox(height: 4.h),
          Divider(color: Colors.grey.shade100),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _summaryActionBtn(IconData icon, String label) => Expanded(
    child: OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: _text),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 9.sp, color: _text),
          ),
        ],
      ),
    ),
  );

  Widget _infoCard(String label, String value, {bool isStatus = false}) =>
      Expanded(
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              isStatus
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: _text,
                      ),
                    ),
            ],
          ),
        ),
      );

  Widget _priceLine(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: 2.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 11.sp : 10.sp,
            color: color ?? (isBold ? _text : _muted),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 12.sp : 10.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? _text,
          ),
        ),
      ],
    ),
  );
}
