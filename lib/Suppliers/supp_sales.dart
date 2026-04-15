import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  static const Color _primary = Color(0xFF5D121B); // GlowVita Wine
  static const Color _primaryDark = Color(0xFF3F2B3E);
  static const Color _success = Color(0xFF10B981);

  // Dynamic Data
  List<Product> products = [];
  List<Customer> clients = [];
  bool isLoading = true;
  String? supplierId;
  double profileTaxRate = 18.0;
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

  // ── Filters ──
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

  // ── Actions ──
  void _addItemToBilling(Product p) {
    if (selectedItems.any((i) => i['sourceId'] == p.id)) return;
    if (p.stock == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This product is out of stock'),
        backgroundColor: Colors.red,
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

  void _removeItemFromBilling(int id) {
    setState(() => selectedItems.removeWhere((item) => item['id'] == id));
  }

  void _updateItemQuantity(int id, int quantity) {
    if (quantity <= 0) return;
    setState(() {
      final index = selectedItems.indexWhere((item) => item['id'] == id);
      if (index != -1) selectedItems[index]['quantity'] = quantity;
    });
  }

  double get subtotal => selectedItems.fold(0.0, (sum, item) {
        return sum + (item['price'] as double) * (item['quantity'] as int);
      });

  double get tax => subtotal * (profileTaxRate / 100);
  double get total => subtotal + tax;

  bool _isItemSelected(String? id) =>
      selectedItems.any((x) => x['sourceId'] == id);

  void _clearBilling() {
    setState(() {
      selectedItems.clear();
      selectedClient = null;
    });
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
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
              onPressed: _fetchData, icon: const Icon(Icons.refresh, size: 20)),
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
          Expanded(flex: 4, child: _buildBillingPart()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildCatalogPart(),
          const SizedBox(height: 12),
          _buildBillingPart(),
        ],
      ),
    );
  }

  // ── Catalog Part ─────────────────────────────────────────────────────────────
  Widget _buildCatalogPart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
          ],
        ),
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
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _muted)),
                      ])),
              Expanded(
                  flex: 2,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${price.toStringAsFixed(0)}.00',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    regularPrice != null ? _primary : _text)),
                        if (regularPrice != null)
                          Text('₹${regularPrice.toStringAsFixed(0)}.00',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _muted,
                                  decoration: TextDecoration.lineThrough)),
                      ])),
              const Spacer(flex: 2),
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

  // ── Billing Part ─────────────────────────────────────────────────────────────
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Text('Billing',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Icon(Icons.person_outline, size: 17, color: Colors.blue.shade400),
              const SizedBox(width: 6),
              Text('Client Selection',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
            ]),
          ),
          const SizedBox(height: 10),
          _buildClientSearch(),
          const SizedBox(height: 10),
          if (selectedClient != null) _buildSelectedClientCard(),
          const SizedBox(height: 10),
          if (selectedItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text('Products',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark)),
            ),
            ...selectedItems.map((item) => _billingItemCard(item)).toList(),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                _billingLine('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                _billingLine(
                    'GST ($profileTaxRate%)', '₹${tax.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _text)),
                      Text('₹${total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _primary)),
                    ]),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _clearBilling,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Clear'))),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                        onPressed: (selectedClient != null)
                            ? _showPaymentDialog
                            : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Proceed'))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────
  Widget _searchField(
      {required TextEditingController controller,
      required String hint,
      required ValueChanged<String> onChanged,
      required VoidCallback onClear,
      required bool showClear}) {
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
                icon: const Icon(Icons.close, size: 16), onPressed: onClear)
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
          items: productCategories
              .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat, style: GoogleFonts.poppins(fontSize: 13))))
              .toList(),
          onChanged: (v) => setState(() => selectedProductCategory = v!),
        ),
      ),
    );
  }

  Widget _addCircleButton(
      {required bool isOutOfStock,
      required bool isSelected,
      VoidCallback? onTap}) {
    if (isOutOfStock)
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6)),
          child: Text('Out of\nStock',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 9, color: _muted)));
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
                size: 17, color: isSelected ? Colors.white : _text)));
  }

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
            hintText: 'Search clients...',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF7C3AED), width: 2)),
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
                    _showClientDropdown = false;
                    _clientSearchFocusNode.unfocus();
                  }),
                  leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(c.fullName.isNotEmpty ? c.fullName[0] : '?',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.bold))),
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
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: Colors.white))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(selectedClient!.fullName,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(selectedClient!.mobile,
                    style: GoogleFonts.poppins(fontSize: 11))
              ])),
          IconButton(
              onPressed: () => setState(() => selectedClient = null),
              icon: const Icon(Icons.close, size: 18, color: Colors.red)),
        ]),
      ),
    );
  }

  Widget _billingItemCard(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'],
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Text(item['category'],
              style: GoogleFonts.poppins(fontSize: 11, color: _muted))
        ])),
        Row(children: [
          _miniQtyBtn(Icons.remove,
              () => _updateItemQuantity(item['id'], item['quantity'] - 1)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${item['quantity']}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.bold))),
          _miniQtyBtn(Icons.add,
              () => _updateItemQuantity(item['id'], item['quantity'] + 1)),
        ]),
        const SizedBox(width: 12),
        Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
        IconButton(
            onPressed: () => _removeItemFromBilling(item['id']),
            icon:
                const Icon(Icons.delete_outline, size: 18, color: Colors.red)),
      ]),
    );
  }

  Widget _miniQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _border)),
            child: Icon(icon, size: 14)));
  }

  Widget _billingLine(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600))
        ]));
  }

  void _showPaymentDialog() {
    String method = 'Cash';
    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setS) => AlertDialog(
                  title: Text('Payment Method',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    _payOption('Cash', Icons.money, method,
                        (v) => setS(() => method = v)),
                    _payOption('UPI', Icons.qr_code, method,
                        (v) => setS(() => method = v)),
                    _payOption('Bank', Icons.account_balance, method,
                        (v) => setS(() => method = v)),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () {
                          _processSale(method);
                          Navigator.pop(context);
                        },
                        child: const Text('Confirm'))
                  ],
                )));
  }

  Widget _payOption(String label, IconData icon, String current,
      ValueChanged<String> onSelect) {
    bool selected = label == current;
    return ListTile(
        leading: Icon(icon, color: selected ? _primary : _muted),
        title: Text(label),
        trailing: selected ? Icon(Icons.check_circle, color: _primary) : null,
        onTap: () => onSelect(label));
  }

  Future<void> _processSale(String method) async {
    try {
      final payload = {
        "clientId": selectedClient!.id,
        "paymentMethod": method,
        "subtotal": subtotal,
        "taxRate": profileTaxRate,
        "taxAmount": tax,
        "totalAmount": total,
        "items": selectedItems
            .map((i) => {
                  "itemId": i['sourceId'],
                  "itemType": "Product",
                  "name": i['name'],
                  "price": i['price'],
                  "quantity": i['quantity'],
                  "totalPrice": i['price'] * i['quantity']
                })
            .toList(),
        "status": "Paid",
        "billingDate": DateTime.now().toIso8601String(),
      };
      final res = await ApiService.createBilling(payload);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sale Recorded!'), backgroundColor: _success));
        _clearBilling();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
