import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import './supp_drawer.dart';
import '../customer_model.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';
import 'dart:async';

class SuppSalesPage extends StatefulWidget {
  const SuppSalesPage({super.key});

  @override
  State<SuppSalesPage> createState() => _SuppSalesPageState();
}

class _SuppSalesPageState extends State<SuppSalesPage> {
  // ── Colors matching main sales.dart ──
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _text = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF5D121B);
  static const Color _primaryDark = Color(0xFF3F2B3E);
  static const Color _success = Color(0xFF10B981);

  // Dynamic Data
  List<Product> products = [];
  List<Customer> clients = [];
  bool isLoading = true;
  String? supplierId;
  double profileTaxRate = 0.0;
  SupplierProfile? supplierProfile;

  // Selected items for billing
  List<Map<String, dynamic>> selectedItems = [];
  Customer? selectedClient;

  // Search and Filters
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  final FocusNode _clientSearchFocusNode = FocusNode();

  String selectedProductCategory = 'All';
  String productSearchQuery = '';
  String clientSearchQuery = '';

  bool _showClientDropdown = false;
  Timer? _clientSearchTimer;

  @override
  void initState() {
    super.initState();
    _clientSearchFocusNode.addListener(() {
      if (mounted && !_clientSearchFocusNode.hasFocus) {
        setState(() => _showClientDropdown = false);
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final fetchedProducts = await ApiService.getProducts();
      final fetchedClients = await ApiService.getSupplierClients();
      final fetchedProfile = await ApiService.getSupplierProfile();

      setState(() {
        products = fetchedProducts;
        clients = fetchedClients;
        supplierProfile = fetchedProfile;
        supplierId = fetchedProfile.id;
        profileTaxRate = (fetchedProfile.taxes?.taxValue ?? 0).toDouble();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _clientSearchController.dispose();
    _clientSearchFocusNode.dispose();
    _clientSearchTimer?.cancel();
    super.dispose();
  }

  // ── Filters ──────────────────────────────────────────────────────────────────
  List<Product> get filteredProducts {
    return products.where((p) {
      final q = productSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (p.productName?.toLowerCase().contains(q) ?? false) ||
          (p.category?.toLowerCase().contains(q) ?? false);
      final matchesCategory = selectedProductCategory == 'All' ||
          p.category == selectedProductCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Customer> get filteredClients {
    return clients.where((c) {
      final q = clientSearchQuery.toLowerCase();
      return q.isEmpty ||
          c.fullName.toLowerCase().contains(q) ||
          (c.email?.toLowerCase().contains(q) ?? false) ||
          c.mobile.toLowerCase().contains(q);
    }).toList();
  }

  List<String> get productCategories {
    final cats = <String>{'All'};
    for (var p in products) {
      if (p.category != null) cats.add(p.category!);
    }
    return cats.toList()..sort();
  }

  // ── Billing Helpers ───────────────────────────────────────────────────────────
  double get subtotal => selectedItems.fold(
      0.0,
      (sum, item) =>
          sum + (item['price'] as double) * (item['quantity'] as int));

  double get tax => subtotal * (profileTaxRate / 100);
  double get total => subtotal + tax;

  bool _isItemSelected(String? id) =>
      selectedItems.any((x) => x['sourceId'] == id);

  // ── Actions ───────────────────────────────────────────────────────────────────
  void _addItemToBilling(Product p) {
    if (selectedItems.any((i) => i['sourceId'] == p.id)) return;
    if (p.stock == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This product is out of stock'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ));
      return;
    }

    setState(() {
      final price = ((p.salePrice != null && p.salePrice! > 0)
              ? p.salePrice!
              : (p.price ?? 0))
          .toDouble();

      selectedItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'sourceId': p.id,
        'name': p.productName ?? 'Unnamed Product',
        'category': p.category ?? 'Uncategorized',
        'price': price,
        'quantity': 1,
        'isService': false,
      });
    });
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

  void _clearBilling() {
    setState(() {
      selectedItems.clear();
      selectedClient = null;
      _clientSearchController.clear();
      clientSearchQuery = '';
    });
  }

  // ── Payment Options Dialog ────────────────────────────────────────────────────
  void _showPaymentOptionsDialog() {
    String? selectedMethod;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 450,
            padding: EdgeInsets.all(24.w),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
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
                    onPressed:
                        isProcessing ? null : () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: 8.h),
              Text('Total Amount: ₹${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF635B63))),
              SizedBox(height: 24.h),

              // Save Order button (processes via createBilling API)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          if (selectedClient == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please select a client first')));
                            return;
                          }
                          setDialogState(() => isProcessing = true);
                          await _processSale(
                              selectedMethod ?? 'Cash',
                              context,
                              setDialogState,
                              () => setDialogState(() => isProcessing = false));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Save Order',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),

              SizedBox(height: 24.h),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text('PAYMENT METHODS',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C8BA1),
                          letterSpacing: 0.5)),
                ),
                const Expanded(child: Divider()),
              ]),
              SizedBox(height: 24.h),

              // Payment method buttons — tap selects AND submits
              Wrap(spacing: 12, runSpacing: 12, children: [
                _paymentMethodButton(
                    'Cash', Icons.money, setDialogState, selectedMethod, (m) {
                  selectedMethod = m;
                  setDialogState(() {});
                  _processSale(m, context, setDialogState,
                      () => setDialogState(() => isProcessing = false));
                }),
                _paymentMethodButton(
                    'QR Code', Icons.qr_code, setDialogState, selectedMethod,
                    (m) {
                  selectedMethod = m;
                  setDialogState(() {});
                  _processSale(m, context, setDialogState,
                      () => setDialogState(() => isProcessing = false));
                }),
                _paymentMethodButton('Debit Card', Icons.credit_card,
                    setDialogState, selectedMethod, (m) {
                  selectedMethod = m;
                  setDialogState(() {});
                  _processSale(m, context, setDialogState,
                      () => setDialogState(() => isProcessing = false));
                }),
                _paymentMethodButton('Credit Card', Icons.credit_card,
                    setDialogState, selectedMethod, (m) {
                  selectedMethod = m;
                  setDialogState(() {});
                  _processSale(m, context, setDialogState,
                      () => setDialogState(() => isProcessing = false));
                }),
                _paymentMethodButton('Net Banking', Icons.account_balance,
                    setDialogState, selectedMethod, (m) {
                  selectedMethod = m;
                  setDialogState(() {});
                  _processSale(m, context, setDialogState,
                      () => setDialogState(() => isProcessing = false));
                }),
              ]),

              if (isProcessing) ...[
                SizedBox(height: 20.h),
                const CircularProgressIndicator(color: _primary),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodButton(
    String label,
    IconData icon,
    Function setS,
    String? selected,
    Function(String) onSelect,
  ) {
    final bool isSelected = selected == label;
    return InkWell(
      onTap: () => onSelect(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 125,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F0F3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryDark : _border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isSelected ? _primaryDark : _muted),
            SizedBox(height: 6.h),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _primaryDark : _text)),
          ],
        ),
      ),
    );
  }

  // ── Process Sale (calls createBilling API) ────────────────────────────────────
  Future<void> _processSale(
    String method,
    BuildContext dialogContext,
    Function setDialogState,
    VoidCallback onFinally,
  ) async {
    if (selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client first')));
      return;
    }

    setDialogState(() {});

    try {
      final payload = {
        "clientId": selectedClient!.id,
        "clientInfo": {
          "fullName": selectedClient!.fullName,
          "phone": selectedClient!.mobile,
          "email": selectedClient!.email ?? '',
        },
        "paymentMethod": method,
        "subtotal": subtotal,
        "taxRate": profileTaxRate,
        "taxAmount": tax,
        "platformFee": 0,
        "totalAmount": total,
        "items": selectedItems
            .map((item) => {
                  "itemId": item['sourceId'],
                  "itemType": "Product",
                  "name": item['name'],
                  "price": item['price'],
                  "quantity": item['quantity'],
                  "totalPrice":
                      (item['price'] as num) * (item['quantity'] as num),
                })
            .toList(),
        "status": "Paid",
        "billingDate": DateTime.now().toIso8601String(),
      };

      final result = await ApiService.createBilling(payload);

      if (result['success'] == true && dialogContext.mounted) {
        Navigator.pop(dialogContext); // close payment dialog
        _showInvoiceSummaryDialog(context, result['data']);
        _clearBilling();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving order: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      onFinally();
    }
  }

  // ── Invoice Summary Dialog ────────────────────────────────────────────────────
  void _showInvoiceSummaryDialog(
      BuildContext context, Map<String, dynamic> data) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final createdAt =
        DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
    final clientInfo = data['clientInfo'] ?? {};
    final items = data['items'] as List? ?? [];
    final vendorName = supplierProfile?.shopName ?? 'Store';

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
              // Title row
              Row(children: [
                Text('Invoice Summary',
                    style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: _text)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: _muted, size: 16.sp),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
              Divider(color: Colors.grey.shade100, height: 12.h),

              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Blue header card ──────────────────────────────
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFF2E5BFF),
                            Color(0xFF1B3BBE),
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data['invoiceNumber'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(data['status'] ?? 'Paid',
                                      style: GoogleFonts.poppins(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Saved on ${dateFormat.format(createdAt)} at $vendorName',
                              style: GoogleFonts.poppins(
                                  fontSize: 9.sp,
                                  color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // ── Quick Actions ─────────────────────────────────
                      _buildSummarySection(
                        title: 'Quick Actions',
                        child: Column(children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43303F),
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6))),
                              icon: const Icon(Icons.calendar_today,
                                  size: 12, color: Colors.white),
                              label: Text('Rebook Client',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 11.sp)),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(children: [
                            _summaryActionBtn(Icons.email_outlined, 'Email'),
                            SizedBox(width: 6.w),
                            _summaryActionBtn(Icons.print_outlined, 'Print'),
                            SizedBox(width: 6.w),
                            _summaryActionBtn(
                                Icons.download_outlined, 'Download'),
                          ]),
                        ]),
                      ),

                      SizedBox(height: 12.h),

                      // ── Client Information ────────────────────────────
                      _buildSummarySection(
                        title: 'Client Information',
                        child: Row(children: [
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
                                    clientInfo['fullName'] ??
                                        selectedClient?.fullName ??
                                        'N/A',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: _text)),
                                Text(
                                    '${clientInfo['phone'] ?? selectedClient?.mobile ?? 'N/A'}'
                                    '${(clientInfo['email'] ?? selectedClient?.email ?? '').isNotEmpty ? ' • ${clientInfo['email'] ?? selectedClient?.email}' : ''}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10.sp, color: _muted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ]),
                      ),

                      SizedBox(height: 12.h),

                      // ── Invoice Details ───────────────────────────────
                      _buildSummarySection(
                        title: 'Invoice Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Invoice number + Date row
                            Row(children: [
                              _infoCard('Invoice Number',
                                  data['invoiceNumber'] ?? 'N/A'),
                              SizedBox(width: 8.w),
                              _infoCard('Date', dateFormat.format(createdAt)),
                            ]),
                            SizedBox(height: 8.h),
                            Row(children: [
                              _infoCard('Payment Method',
                                  data['paymentMethod'] ?? 'Cash'),
                              SizedBox(width: 8.w),
                              _infoCard('Status', data['status'] ?? 'Completed',
                                  isStatus: true),
                            ]),

                            SizedBox(height: 12.h),
                            Text('Products',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp)),
                            Divider(color: Colors.grey.shade100, height: 8.h),

                            // Item rows
                            ...items.map((item) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 3.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name'] ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E293B)),
                                        ),
                                      ),
                                      Text(
                                        '₹${(item['totalPrice'] ?? item['price'] ?? 0).toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )),

                            SizedBox(height: 12.h),

                            // Price summary box
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(children: [
                                _priceLine('Subtotal',
                                    '₹${(data['subtotal'] ?? 0).toStringAsFixed(2)}'),
                                if ((data['discountAmount'] ?? 0) > 0)
                                  _priceLine('Discount',
                                      '-₹${(data['discountAmount'] ?? 0).toStringAsFixed(2)}',
                                      color: const Color(0xFF22C55E)),
                                if ((data['taxAmount'] ?? 0) > 0)
                                  _priceLine(
                                      'Tax (${(data['taxRate'] ?? 0).toStringAsFixed(1)}%)',
                                      '₹${(data['taxAmount'] ?? 0).toStringAsFixed(2)}'),
                                if ((data['platformFee'] ?? 0) > 0)
                                  _priceLine('Platform Fee',
                                      '₹${(data['platformFee'] ?? 0).toStringAsFixed(2)}'),
                                Divider(
                                    height: 12.h,
                                    color: Colors.grey.withOpacity(0.2)),
                                _priceLine('Total',
                                    '₹${(data['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                    isBold: true),
                                if ((data['balance'] ?? 0) > 0)
                                  _priceLine('Balance',
                                      '₹${(data['balance'] ?? 0).toStringAsFixed(2)}',
                                      isBold: true,
                                      color: const Color(0xFFEF4444)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43303F),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6))),
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

  // ── Invoice Summary Helpers ───────────────────────────────────────────────────
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

  Widget _summaryActionBtn(IconData icon, String label) => Expanded(
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Column(children: [
            Icon(icon, size: 18, color: _text),
            SizedBox(height: 4.h),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 9.sp, color: _text)),
          ]),
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
                              color: const Color(0xFF166534))))
                  : Text(value,
                      style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: _text)),
            ],
          ),
        ),
      );

  Widget _priceLine(String label, String value,
          {bool isBold = false, Color? color}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
        ]),
      );

  // ── BUILD ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 950;

    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Sales'),
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Sales Overview',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: _text, fontSize: 12.sp)),
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        actions: [
          IconButton(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh, size: 20, color: _muted)),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : isWide
              ? _buildWideLayout(width)
              : _buildMobileLayout(),
    );
  }

  Widget _buildWideLayout(double width) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildCatalogPart()),
          const SizedBox(width: 16),
          SizedBox(width: 380, child: _buildBillingPart()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Positioned.fill(
          bottom: 80,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildCatalogPart(),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.12,
          minChildSize: 0.12,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
              ),
              if (selectedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${selectedItems.length} Item(s)',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primary)),
                      Text('Total: ₹${total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _text)),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildBillingPart(),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Catalog Part ──────────────────────────────────────────────────────────────
  Widget _buildCatalogPart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: _searchField(
            controller: _productSearchController,
            hint: 'Search products...',
            onChanged: (v) => setState(() => productSearchQuery = v),
            onClear: () => setState(() {
              _productSearchController.clear();
              productSearchQuery = '';
            }),
            showClear: productSearchQuery.isNotEmpty,
          )),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: _categoryDropdown()),
        ]),
        const SizedBox(height: 15),
        _buildCatalogList(),
      ],
    );
  }

  Widget _buildCatalogList() {
    final items = filteredProducts;
    if (items.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No products found',
            style: GoogleFonts.poppins(color: _muted, fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final p = items[index];
          final price = ((p.salePrice != null && p.salePrice! > 0)
                  ? p.salePrice!
                  : (p.price ?? 0))
              .toDouble();
          final regularPrice = (p.salePrice != null && p.salePrice! > 0)
              ? (p.price ?? 0).toDouble()
              : null;
          final bool isOutOfStock = p.stock == 0;
          final bool isSelected = _isItemSelected(p.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              // Name + category
              Expanded(
                flex: 3,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.productName ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _text)),
                      Text(p.category ?? 'Uncategorized',
                          style:
                              GoogleFonts.poppins(fontSize: 11, color: _muted)),
                    ]),
              ),

              // Price column
              Expanded(
                flex: 2,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${price.toStringAsFixed(0)}.00',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: regularPrice != null ? _primary : _text)),
                      if (regularPrice != null)
                        Text('₹${regularPrice.toStringAsFixed(0)}.00',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _muted,
                                decoration: TextDecoration.lineThrough)),
                    ]),
              ),

              const Spacer(flex: 2),

              // Add button
              _addCircleButton(
                  isOutOfStock: isOutOfStock,
                  isSelected: isSelected,
                  onTap: isOutOfStock ? null : () => _addItemToBilling(p)),
            ]),
          );
        },
      ),
    );
  }

  // ── Billing Part ──────────────────────────────────────────────────────────────
  Widget _buildBillingPart() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Billing',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                Text('Review items and process payment',
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Client Selection label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Icon(Icons.person_outlined,
                  size: 17, color: Colors.blue.shade400),
              const SizedBox(width: 6),
              Text('Client Selection',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
            ]),
          ),
          const SizedBox(height: 10),

          // Client search / selected card
          _buildClientSearch(),
          const SizedBox(height: 10),
          if (selectedClient != null) _buildSelectedClientCard(),
          const SizedBox(height: 10),

          // Items table header
          if (selectedItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Text('Item',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 2,
                    child: Text('Price',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Text('Qty',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _muted)),
                const SizedBox(width: 32),
                Text('Total',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _muted)),
                const SizedBox(width: 36),
                Text('Actions',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _muted)),
              ]),
            ),
            const Divider(height: 1),

            // Item rows
            ...selectedItems.map((item) => _billingItemCard(item)).toList(),

            const Divider(height: 1),
            const SizedBox(height: 12),

            // Order Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  _billingLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                  if (profileTaxRate > 0)
                    _billingLine('GST (${profileTaxRate.toStringAsFixed(1)}%)',
                        '₹${tax.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: _border),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                        Text('₹${total.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                      ]),
                ]),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _clearBilling,
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Colors.red),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    label: Text('Clear Cart',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: (selectedItems.isEmpty || selectedClient == null)
                        ? null
                        : _showPaymentOptionsDialog,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0),
                    label: Text('Process Payment',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _billingItemCard(Map<String, dynamic> item) {
    final qty = item['quantity'] as int;
    final priceEach = item['price'] as double;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        // Name + category
        Expanded(
          flex: 3,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'],
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary)),
            Text(item['category'],
                style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
          ]),
        ),

        // Price (with strikethrough style matching screenshot)
        Expanded(
          flex: 2,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('₹${(priceEach * 1.05).toStringAsFixed(0)}.00',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _muted,
                    decoration: TextDecoration.lineThrough)),
            Text('₹${priceEach.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary)),
          ]),
        ),

        // Qty stepper
        Row(children: [
          _qtyBtn(
              icon: Icons.remove,
              onTap: () => _updateItemQuantity(item['id'], qty - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$qty',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          _qtyBtn(
              icon: Icons.add,
              onTap: () => _updateItemQuantity(item['id'], qty + 1)),
        ]),

        // Total
        SizedBox(
          width: 72,
          child: Text(
            '₹${(priceEach * qty).toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.bold, color: _text),
          ),
        ),

        // Delete
        IconButton(
          onPressed: () => _removeItemFromBilling(item['id']),
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          padding: const EdgeInsets.only(left: 4),
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border)),
        child: Icon(icon, size: 14, color: _text),
      ),
    );
  }

  Widget _billingLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
        Text(value,
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Client Search Widgets ─────────────────────────────────────────────────────
  Widget _buildClientSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(children: [
        TextField(
          controller: _clientSearchController,
          focusNode: _clientSearchFocusNode,
          onTap: () => setState(() => _showClientDropdown = true),
          onChanged: (v) {
            _clientSearchTimer?.cancel();
            _clientSearchTimer = Timer(const Duration(milliseconds: 300), () {
              setState(() {
                clientSearchQuery = v;
                _showClientDropdown = true;
              });
            });
          },
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search clients by name, email, or phone...',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
          ),
        ),
        if (_showClientDropdown &&
            selectedClient == null &&
            filteredClients.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 8)
                ]),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filteredClients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = filteredClients[i];
                return ListTile(
                  onTap: () => setState(() {
                    selectedClient = c;
                    _clientSearchController.text = c.fullName;
                    _showClientDropdown = false;
                    _clientSearchFocusNode.unfocus();
                  }),
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFD4B8C0),
                    child: Text(c.fullName.isNotEmpty ? c.fullName[0] : '?',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  title: Text(c.fullName,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle:
                      Text(c.mobile, style: GoogleFonts.poppins(fontSize: 11)),
                );
              },
            ),
          ),
      ]),
    );
  }

  Widget _buildSelectedClientCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border)),
        child: Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFD4B8C0),
            child: Text(
                selectedClient!.fullName.isNotEmpty
                    ? selectedClient!.fullName[0]
                    : '?',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(selectedClient!.fullName,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(selectedClient!.mobile,
                  style: GoogleFonts.poppins(fontSize: 11)),
            ]),
          ),
          IconButton(
            onPressed: () => setState(() {
              selectedClient = null;
              _clientSearchController.clear();
              clientSearchQuery = '';
            }),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ]),
      ),
    );
  }

  // ── Common Widgets ────────────────────────────────────────────────────────────
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
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
        prefixIcon:
            const Icon(Icons.search, color: Color(0xFF94A3B8), size: 19),
        suffixIcon: showClear
            ? IconButton(
                icon:
                    const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                onPressed: onClear)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
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
          border: Border.all(color: _border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedProductCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _muted),
          style: GoogleFonts.poppins(fontSize: 13, color: _text),
          items: productCategories
              .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat,
                      style: GoogleFonts.poppins(fontSize: 13, color: _text))))
              .toList(),
          onChanged: (v) =>
              setState(() => selectedProductCategory = v ?? 'All'),
          dropdownColor: Colors.white,
        ),
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
              borderRadius: BorderRadius.circular(6)),
          child: Text('Out of\nStock',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 9, color: _muted)));
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
                color: isSelected ? _primaryDark : _border, width: 1.5)),
        child: Icon(isSelected ? Icons.check : Icons.add,
            size: 17, color: isSelected ? Colors.white : _text),
      ),
    );
  }
}
