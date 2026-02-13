import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/custom_drawer.dart';
import 'customer_model.dart';
import 'add_customer.dart';
import 'services/api_service.dart';
import 'addon_model.dart';
import 'dart:async';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _text = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF5D121B); // Brand Maroon
  static const Color _success = Color(0xFF10B981);
  static const Color _primaryDark = Color(0xFF3F2B3E);

  // Dynamic data
  List<Service> services = [];
  List<Product> products = [];
  List<AddOn> allAddOns = [];
  String? vendorId;
  bool isLoading = true;

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

  // List of staff for default assignment
  List<StaffMember> staffList = [];

  // Selected items for billing
  List<Map<String, dynamic>> selectedItems = [];

  // Selected client
  Customer? selectedClient;
  StaffMember? selectedStaff;
  bool applyTax = false;
  double profileTaxRate = 0.0;
  String paymentMethod = 'Cash';

  // Search controllers
  final TextEditingController _serviceProductSearchController =
      TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();

  // Category filters
  String? selectedServiceCategory;
  String? selectedProductCategory;

  // Search queries
  String serviceProductSearchQuery = '';
  String clientSearchQuery = '';

  // Focus node for client search
  final FocusNode _clientSearchFocusNode = FocusNode();
  bool _showClientDropdown = false;

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

    // Add listener to hide dropdown when focus is lost
    _clientSearchFocusNode.addListener(() {
      if (!_clientSearchFocusNode.hasFocus) {
        setState(() => _showClientDropdown = false);
      }
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
        vendorId = fetchedVendor.id;
        profileTaxRate = (fetchedVendor.taxes?.taxValue ?? 0).toDouble();
        // Also fetch staff to fix 400 error for direct sales
        ApiService.getStaff().then((list) {
          if (mounted) {
            setState(() {
              staffList = list;
              if (staffList.isNotEmpty && selectedStaff == null) {
                selectedStaff = staffList.first;
              }
            });
          }
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

  // Filter services based on search and category
  List<Service> get filteredServices {
    return services.where((service) {
      final q = serviceProductSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (service.name?.toLowerCase().contains(q) ?? false) ||
          (service.category?.toLowerCase().contains(q) ?? false);

      final matchesCategory = selectedServiceCategory == 'All' ||
          service.category == selectedServiceCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Filter products based on search and category
  List<Product> get filteredProducts {
    return products.where((product) {
      final q = serviceProductSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (product.productName?.toLowerCase().contains(q) ?? false) ||
          (product.category?.toLowerCase().contains(q) ?? false);

      final matchesCategory = selectedProductCategory == 'All' ||
          product.category == selectedProductCategory;
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
      if (service.category != null) categories.add(service.category!);
    }
    return categories.toList()..sort();
  }

  // Get unique categories for products
  List<String> get productCategories {
    final categories = <String>{'All'};
    for (var product in products) {
      if (product.category != null) categories.add(product.category!);
    }
    return categories.toList()..sort();
  }

  // Add item to billing
  void _addItemToBilling(dynamic item,
      {bool isService = false, List<AddOn>? selectedAddOns}) {
    // Prevent adding out of stock products
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
          .where((addon) => addon.mappedServices?.contains(serviceId) ?? false)
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
        price = ((s.discountedPrice != null && s.discountedPrice! > 0)
                ? s.discountedPrice!
                : (s.price ?? 0))
            .toDouble();
        duration = '${s.duration} min';
      } else {
        final p = item as Product;
        name = p.productName ?? '';
        category = p.category ?? 'Uncategorized';
        price = ((p.salePrice != null && p.salePrice! > 0)
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
        'addons': selectedAddOns
                ?.map((a) => {
                      'id': a.id,
                      'name': a.name,
                      'price': a.price,
                      'duration': a.duration,
                    })
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
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Text('Select Add-Ons',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _text)),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  Text('Select add-ons for ${service.name}',
                      style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
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
                            title: Text(addon.name ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _text)),
                            subtitle: Text(
                                'Time: ${addon.duration} min • Price: ₹${addon.price}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: _muted)),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selected.add(addon);
                                } else {
                                  selected.remove(addon);
                                }
                              });
                            },
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
                            _addItemToBilling(service,
                                isService: true, selectedAddOns: []);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _addItemToBilling(service,
                                isService: true, selectedAddOns: selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Add to Cart',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
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
    return selectedItems.fold(0.0, (sum, item) {
      final double price = item['price'] as double;
      final int qty = item['quantity'] as int;
      final List addons = item['addons'] as List? ?? [];
      double addonsPrice = addons.fold(
          0.0, (s, a) => s + ((a['price'] as num?)?.toDouble() ?? 0.0));
      return sum + (price + addonsPrice) * qty;
    });
  }

  double get tax => applyTax ? (subtotal * (profileTaxRate / 100)) : 0.0;
  double get total => subtotal + tax;

  void _clearBilling() {
    setState(() {
      selectedItems.clear();
      selectedClient = null;
    });
  }

  void _showPaymentOptionsDialog() {
    String? selectedMethod;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Options',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _text)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Total Amount: ₹${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF635B63))),
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
                            "items": selectedItems.map((item) {
                              return {
                                "itemId": item['sourceId'],
                                "itemType": (item['isService'] ?? true)
                                    ? "Service"
                                    : "Product",
                                "name": item['name'],
                                "price": item['price'],
                                "quantity": item['quantity'],
                                "totalPrice": (item['price'] as num) *
                                    (item['quantity'] as num),
                                "staffMember": {
                                  "id": selectedStaff?.id ?? "",
                                  "name": selectedStaff?.fullName ?? "No Staff"
                                },
                                "addOns": (item['addons'] as List)
                                    .map((a) => {
                                          "id": a['id'],
                                          "name": a['name'],
                                          "price": a['price']
                                        })
                                    .toList(),
                              };
                            }).toList(),
                            "status": "completed",
                            "billingDate": DateTime.now().toIso8601String(),
                          };

                          final result =
                              await ApiService.createBilling(payload);

                          if (result['success'] == true) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close checkout dialog

                              // Show Invoice Summary Dialog
                              _showInvoiceSummaryDialog(
                                  context, result['data']);

                              _clearBilling();
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving order: $e')),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isProcessing = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9F8F9F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Save Order',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('PAYMENT METHODS',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C8BA1),
                                letterSpacing: 0.5)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _paymentMethodButton('Cash', Icons.money, setDialogState,
                          selectedMethod, (m) => selectedMethod = m),
                      _paymentMethodButton(
                          'QR Code',
                          Icons.qr_code,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m),
                      _paymentMethodButton(
                          'Debit Card',
                          Icons.credit_card,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m),
                      _paymentMethodButton(
                          'Credit Card',
                          Icons.credit_card,
                          setDialogState,
                          selectedMethod,
                          (m) => selectedMethod = m),
                      _paymentMethodButton('Net Banking', Icons.account_balance,
                          setDialogState, selectedMethod, (m) {
                        selectedMethod = m;
                        setState(() => paymentMethod = m);
                      }),
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
        });
      },
    );
  }

  Widget _paymentMethodButton(String label, IconData icon, Function setState,
      String? selected, Function(String) onSelect) {
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
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
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
      // Get primary service info if any, otherwise first item
      final firstService = selectedItems.firstWhere(
          (i) => i['isService'] == true,
          orElse: () => selectedItems[0]);
      final defaultStaff = staffList.isNotEmpty ? staffList[0] : null;

      // 1. Create Appointment
      final Map<String, dynamic> appointmentData = {
        "client": selectedClient!.id,
        "clientName": selectedClient!.fullName,
        "vendorId": vendorId,
        "service": firstService['sourceId'],
        "serviceName": firstService['name'],
        "staff": defaultStaff?.id ??
            vendorId ??
            "", // Use vendorId as fallback staff
        "staffName": defaultStaff?.fullName ?? "Staff Member",
        "date": DateTime.now().toIso8601String().split('T')[0],
        "startTime":
            DateTime.now().toIso8601String().split('T')[1].substring(0, 5),
        "endTime": DateTime.now()
            .add(const Duration(minutes: 30))
            .toIso8601String()
            .split('T')[1]
            .substring(0, 5),
        "duration": 30, // Default duration
        "amount": total,
        "totalAmount": total,
        "status": "completed",
        "services": selectedItems
            .where((item) => item['isService'] == true)
            .map((item) => {
                  "serviceId": item['sourceId'],
                  "price": item['price'],
                  "addons": (item['addons'] as List? ?? [])
                      .map((a) => a['id'])
                      .toList()
                })
            .toList(),
        "products": selectedItems
            .where((item) => item['isService'] == false)
            .map((item) => {
                  "productId": item['sourceId'],
                  "price": item['price'],
                  "quantity": item['quantity']
                })
            .toList(),
      };

      final response = await ApiService.createAppointment(appointmentData);

      print('✅ Appointment created successfully: ${response.toString()}');

      if (response['success'] == true || response['data'] != null) {
        final appointmentId = response['data'] != null
            ? response['data']['_id']
            : response['_id'];

        print('📝 Appointment ID: $appointmentId');

        // 2. Collect Payment
        final paymentData = {
          "appointmentId": appointmentId,
          "amount": total,
          "paymentMethod": method.toLowerCase().replaceAll(' ', ''),
          "paymentDate": DateTime.now().toUtc().toIso8601String(),
          "notes": "Direct Sale from POS",
        };

        print(
            '💳 Attempting to collect payment with data: ${paymentData.toString()}');

        await ApiService.collectPayment(paymentData);

        print('✅ Payment collected successfully');

        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sale processed successfully!'),
                backgroundColor: Colors.green),
          );
          _clearBilling();
        }
      }
    } catch (e) {
      print('❌ Error in _processDirectSale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error processing sale: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ----------------- UI helpers -----------------
  TextStyle get _h1 => GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700, color: _text);
  TextStyle get _h2 => GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.bold, color: _text);
  TextStyle get _sub => GoogleFonts.poppins(
      fontSize: 10, fontWeight: FontWeight.w400, color: _muted);
  TextStyle get _th => GoogleFonts.poppins(
      fontSize: 10, fontWeight: FontWeight.w500, color: _muted);
  TextStyle get _td => GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w600, color: _text);

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

  InputDecoration _clientSearchDecoration({
    required String hint,
    bool showClear = false,
    VoidCallback? onClear,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
      suffixIcon: showClear
          ? IconButton(
              icon: const Icon(Icons.close, size: 16), onPressed: onClear)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
      ),
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
    return selectedItems.any((x) =>
        x['name'] == name && (x['price'] as double).toInt() == price.toInt());
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

  Widget _buildBillingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Billing', style: _h2),
        const SizedBox(height: 1),
        Text('Review items and process payment', style: _sub),
        const SizedBox(height: 10),

        // Client Selection header
        Row(
          children: [
            const Icon(Icons.person_add_alt_1_outlined,
                size: 20, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text('Client Selection',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar with Purple Border
        TextField(
          controller: _clientSearchController,
          focusNode: _clientSearchFocusNode,
          onTap: () {
            setState(() => _showClientDropdown = true);
          },
          onChanged: (v) {
            _clientSearchTimer?.cancel();
            _clientSearchTimer = Timer(const Duration(milliseconds: 300), () {
              setState(() {
                clientSearchQuery = v;
                _showClientDropdown = true;
              });
            });
          },
          decoration: _clientSearchDecoration(
            hint: 'Search clients by name, email, or phone...',
            showClear: clientSearchQuery.isNotEmpty,
            onClear: () {
              _clientSearchController.clear();
              setState(() => clientSearchQuery = '');
            },
          ),
        ),
        const SizedBox(height: 12),

        // Add New Client Button
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCustomer()),
            ).then((value) {
              if (value == true) _fetchData();
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF1E293B)),
                const SizedBox(width: 8),
                Text('Add New Client',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Client Results Cards (Shown as dropdown when search is focused)
        if (_showClientDropdown && selectedClient == null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredClients.length,
              itemBuilder: (context, index) {
                final cst = filteredClients[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedClient = cst;
                      clientSearchQuery = '';
                      _clientSearchController.clear();
                      _showClientDropdown = false;
                      _clientSearchFocusNode.unfocus();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: Text(
                            cst.fullName.isNotEmpty
                                ? cst.fullName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cst.fullName,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B))),
                            Text(cst.mobile,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                    selectedClient!.fullName.isNotEmpty
                        ? selectedClient!.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _primary),
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
          const SizedBox(height: 12),
          // Staff Selection Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text('Assign Staff Member',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _text)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border, width: 0.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StaffMember?>(
                    value: selectedStaff,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: _muted),
                    hint: Text('Select Staff',
                        style:
                            GoogleFonts.poppins(fontSize: 12, color: _muted)),
                    items: staffList.map((staff) {
                      return DropdownMenuItem<StaffMember?>(
                        value: staff,
                        child: Text(staff.fullName ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _text)),
                      );
                    }).toList(),
                    onChanged: (StaffMember? value) {
                      setState(() => selectedStaff = value);
                    },
                  ),
                ),
              ),
            ],
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
                Expanded(
                    flex: 3, child: Center(child: Text('Qty', style: _th))),
                Expanded(flex: 2, child: Text('Total', style: _th)),
                const SizedBox(width: 30), // actions space
              ]),
              SizedBox(
                height: 200, // keeps POS feel + ensures totals always visible
                child: selectedItems.isEmpty
                    ? Center(
                        child: Text('No items added yet',
                            style: GoogleFonts.poppins(
                                color: _muted, fontWeight: FontWeight.w600)))
                    : ListView.separated(
                        itemCount: selectedItems.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (_, index) {
                          final item = selectedItems[index];
                          final qty = item['quantity'] as int;
                          final priceEach = item['price'] as double;
                          final List addons = item['addons'] as List? ?? [];
                          final double addonsTotal = addons.fold(
                              0.0,
                              (sum, a) =>
                                  sum +
                                  ((a['price'] as num?)?.toDouble() ?? 0.0));
                          final lineTotal = (priceEach + addonsTotal) * qty;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'],
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _success)),
                                      if (item['duration'] != null)
                                        Text(item['duration'],
                                            style: GoogleFonts.poppins(
                                                fontSize: 11, color: _muted)),
                                      ...addons.map((a) => Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4, left: 2),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 12,
                                                  width: 1,
                                                  color:
                                                      const Color(0xFFCBD5E1),
                                                ),
                                                const SizedBox(width: 6),
                                                Text("+ ${a['name']}",
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color: _muted)),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('₹${priceEach.toStringAsFixed(2)}',
                                            style: _td),
                                        if (addonsTotal > 0)
                                          Text(
                                              '+ ₹${addonsTotal.toStringAsFixed(2)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11, color: _muted)),
                                      ],
                                    )),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _qtyButton(
                                        icon: Icons.remove,
                                        onTap: () {
                                          if (item['id'] != null) {
                                            _updateItemQuantity(
                                                item['id'], qty - 1);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text('$qty', style: _td),
                                      const SizedBox(width: 8),
                                      _qtyButton(
                                        icon: Icons.add,
                                        onTap: () {
                                          if (item['id'] != null) {
                                            _updateItemQuantity(
                                                item['id'], qty + 1);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        '₹${lineTotal.toStringAsFixed(2)}',
                                        style: _td)),
                                SizedBox(
                                  width: 30,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 16),
                                    onPressed: () {
                                      if (item['id'] != null) {
                                        _removeItemFromBilling(item['id']);
                                      }
                                    },
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _billingLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
              // Tax Toggle Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: applyTax,
                            activeColor: _primary,
                            onChanged: (val) {
                              setState(() => applyTax = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Apply Taxes (${profileTaxRate.toStringAsFixed(1)}%)',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _text)),
                            Text('Configured in Profile',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: _muted,
                                    fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ],
                    ),
                    Text('₹${tax.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _text)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _billingLine('Total', '₹${total.toStringAsFixed(2)}',
                  isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Footer actions
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _clearBilling,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFF64748B)),
                  label: Text('Clear',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: (selectedItems.isEmpty || selectedClient == null)
                      ? null
                      : _showPaymentOptionsDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Proceed to Payment',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
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
    final items =
        _tabController.index == 0 ? filteredServices : filteredProducts;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Sales'),
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Sales',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
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
                            labelStyle: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            unselectedLabelStyle: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            tabs: const [
                              Tab(text: 'Service'),
                              Tab(text: 'Product')
                            ],
                            onTap: (_) => setState(() {}),
                            dividerHeight: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _serviceProductSearchController,
                          onChanged: (v) =>
                              setState(() => serviceProductSearchQuery = v),
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
                            value: _tabController.index == 0
                                ? selectedServiceCategory
                                : selectedProductCategory,
                            underline: const SizedBox(),
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more, size: 20),
                            items: (_tabController.index == 0
                                    ? serviceCategories
                                    : productCategories)
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _text,
                                            fontWeight: FontWeight.w600)),
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
                    height: 500, // Increased height
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : items.isEmpty
                            ? Center(
                                child: Text(
                                  'No items found',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _muted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
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
                                    price = ((s.discountedPrice != null &&
                                                s.discountedPrice! > 0)
                                            ? s.discountedPrice!
                                            : (s.price ?? 0))
                                        .toDouble();
                                    regularPrice = (s.discountedPrice != null &&
                                            s.discountedPrice! > 0)
                                        ? (s.price ?? 0).toDouble()
                                        : null;
                                    duration = '${s.duration} min';
                                  } else {
                                    final p = item as Product;
                                    name = p.productName ?? '';
                                    category = p.category ?? 'Uncategorized';
                                    price = ((p.salePrice != null &&
                                                p.salePrice! > 0)
                                            ? p.salePrice!
                                            : (p.price ?? 0))
                                        .toDouble();
                                    regularPrice = (p.salePrice != null &&
                                            p.salePrice! > 0)
                                        ? (p.price ?? 0).toDouble()
                                        : null;
                                    duration = null;
                                  }

                                  final bool isOutOfStock = !isService &&
                                      (item as Product).stock == 0;
                                  final selected = _isItemSelected(name, price);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                category,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color:
                                                      const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '₹${price.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      const Color(0xFF1E293B),
                                                ),
                                              ),
                                              if (regularPrice != null)
                                                Text(
                                                  '₹${regularPrice.toStringAsFixed(2)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: _muted,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isService)
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              duration ?? '',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                          )
                                        else
                                          const Spacer(flex: 2),
                                        ElevatedButton(
                                          onPressed: isOutOfStock
                                              ? null
                                              : () => _addItemToBilling(item,
                                                  isService: isService),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isOutOfStock
                                                ? Colors.grey.shade300
                                                : const Color(0xFF3F2B3E),
                                            foregroundColor: isOutOfStock
                                                ? Colors.grey.shade600
                                                : Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!isOutOfStock) ...[
                                                const Icon(Icons.add, size: 16),
                                                const SizedBox(width: 4),
                                              ],
                                              Text(
                                                isOutOfStock
                                                    ? 'Out of Stock'
                                                    : 'Add',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ],
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
            );

            final billingPanel = SizedBox(
              width: isWide ? null : double.infinity,
              child: Container(
                constraints:
                    isWide ? const BoxConstraints(maxWidth: 380) : null,
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
      width: 28,
      height: 28,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.8),
          ),
          child: Icon(icon, size: 14, color: _text),
        ),
      ),
    );
  }

  Widget _billingLine(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: isTotal ? 14 : 12,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? _text : _muted)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: isTotal ? 15 : 12,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  color: _text)),
        ],
      ),
    );
  }

  void _showInvoiceSummaryDialog(
      BuildContext context, Map<String, dynamic> data) {
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
              // Header
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
                      // Banner Section
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
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Completed',
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

                      // Quick Actions
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
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: const Icon(Icons.calendar_today,
                                    size: 12, color: Colors.white),
                                label: Text('Rebook Client',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 11.sp)),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                _summaryActionBtn(
                                    Icons.email_outlined, 'Email'),
                                SizedBox(width: 6.w),
                                _summaryActionBtn(
                                    Icons.print_outlined, 'Download'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Client Information
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
                              child: Icon(Icons.person_outline,
                                  color: _muted, size: 18),
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
                                        fontSize: 10.sp, color: _muted),
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

                      // Invoice Details
                      _buildSummarySection(
                        title: 'Invoice Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _infoCard(
                                    'Payment', data['paymentMethod'] ?? 'Cash'),
                                SizedBox(width: 8.w),
                                _infoCard('Status', 'Paid', isStatus: true),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Text('Services',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp)),
                            Divider(color: Colors.grey.shade100, height: 8.h),
                            ...items.map((item) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item['name'] ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E293B))),
                                      Text(
                                          '₹${(item['price'] ?? 0).toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  _priceLine('Subtotal',
                                      '₹${(data['subtotal'] ?? 0).toStringAsFixed(2)}'),
                                  _priceLine('Discount',
                                      '-₹${(data['discountAmount'] ?? 0).toStringAsFixed(2)}',
                                      color: const Color(0xFF22C55E)),
                                  _priceLine('Tax (${data['taxRate'] ?? 0}%)',
                                      '₹${(data['taxAmount'] ?? 0).toStringAsFixed(2)}'),
                                  _priceLine('Platform Fee',
                                      '₹${(data['platformFee'] ?? 0).toStringAsFixed(2)}'),
                                  Divider(
                                      height: 12.h,
                                      color: Colors.grey.withOpacity(0.2)),
                                  _priceLine('Total',
                                      '₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                      isBold: true),
                                  _priceLine('Balance',
                                      '₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                      isBold: true,
                                      color: const Color(0xFFEF4444)),
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
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('Close',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
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
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 12.sp, fontWeight: FontWeight.bold, color: _text)),
          SizedBox(height: 4.h),
          Divider(color: Colors.grey.shade100),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _summaryActionBtn(IconData icon, String label) {
    return Expanded(
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
            Text(label,
                style: GoogleFonts.poppins(fontSize: 9.sp, color: _text)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, {bool isStatus = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    color: _muted,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 4.h),
            isStatus
                ? Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(value,
                        style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF166534))),
                  )
                : Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: _text)),
          ],
        ),
      ),
    );
  }

  Widget _priceLine(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: isBold ? 11.sp : 10.sp,
                  color: color ?? (isBold ? _text : _muted),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: isBold ? 12.sp : 10.sp,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? _text)),
        ],
      ),
    );
  }
}
