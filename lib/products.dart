import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'add_product.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';
import 'my_Profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/subscription_wrapper.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<Products> {
  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All Status';
  bool isGridView = false;
  String searchQuery = '';
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  VendorProfile? _profile;

  final List<String> statusFilters = [
    'All Status',
    'Pending',
    'Approved',
    'Disapproved'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final apiProducts = await ApiService.getProducts();
      setState(() {
        products = apiProducts
            .map((product) => {
                  '_id': product.id,
                  'name': product.productName,
                  'category': product.category,
                  'description': product.description,
                  'price': product.price,
                  'sale_price': product.salePrice,
                  'stock_quantity': product.stock,
                  'images': product.productImages,
                  'status': product.status?.toLowerCase() == 'approved'
                      ? 'Approved'
                      : product.status?.toLowerCase() == 'disapproved'
                          ? 'Disapproved'
                          : 'Pending',
                  'rating': 4.4,
                  'size': product.size ?? '',
                  'sizeMetric': product.sizeMetric ?? '',
                  'brand': product.brand ?? '',
                  'productForm': product.productForm ?? '',
                  'forBodyPart': product.forBodyPart ?? '',
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editProduct(int index) async {
    final editedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              AddProductPage(existingProduct: products[index])),
    );
    if (editedProduct != null && editedProduct is Map<String, dynamic>) {
      setState(() => products[index] = editedProduct);
    }
  }

  void _deleteProduct(int index) async {
    final productId = products[index]['_id'];
    final productName = products[index]['name'];
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text("Are you sure you want to delete '$productName'?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Delete")),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [
            SizedBox(width: 12),
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
            SizedBox(width: 12),
            Text("Deleting product..."),
          ]),
          duration: Duration(seconds: 10),
        ));
        bool success = await ApiService.deleteProduct(productId);
        if (success) {
          setState(() => products.removeAt(index));
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Product deleted successfully"),
                backgroundColor: Colors.green));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Failed to delete product"),
                backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error deleting product: $e"),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const AddProductPage()));
    if (result == true) _loadProducts();
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final matchesSearch = product['name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final matchesStatus =
          selectedStatus == 'All Status' || product['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ── Computed stats ──────────────────────────────────────────────────────
  int get _totalProducts => products.length;
  int get _pendingProducts =>
      products.where((p) => p['status'] == 'Pending').length;
  int get _categoryCount => products.map((p) => p['category']).toSet().length;
  double get _inventoryValue => products.fold(0.0, (sum, p) {
        try {
          final price =
              double.parse((p['sale_price'] ?? p['price'] ?? 0).toString());
          final stock = int.parse((p['stock_quantity'] ?? 0).toString());
          return sum + (price * stock);
        } catch (_) {
          return sum;
        }
      });

  String _formatCurrency(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  static Widget _buildImageWidget(dynamic image) {
    if (image == null) {
      return Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center);
    }
    try {
      if (image is String) {
        if (image.isEmpty)
          return Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center);
        if (image.startsWith('http'))
          return Image.network(image,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center));
        if (image.startsWith('data:image')) {
          try {
            return Image.memory(base64Decode(image.split(',').last),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) =>
                    Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center));
          } catch (_) {
            return Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center);
          }
        }
        if (image.startsWith('assets/'))
          return Image.asset(image,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center));
        if (image.contains('/')) {
          final fullUrl =
              'https://partners.glowvitasalon.com/${image.startsWith('/') ? image.substring(1) : image}';
          return Image.network(fullUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center));
        }
        if (File(image).existsSync())
          return Image.file(File(image),
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center));
      }
      if (image is XFile)
        return Image.file(File(image.path),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center));
    } catch (_) {}
    return Image.asset('assets/images/logo.png', fit: BoxFit.contain, alignment: Alignment.center);
  }

  int _discountPercent(dynamic price, dynamic salePrice) {
    try {
      final orig = double.parse(price.toString());
      final sale = double.parse(salePrice.toString());
      if (orig > 0 && sale < orig)
        return (((orig - sale) / orig) * 100).round();
    } catch (_) {}
    return 0;
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => _ProductDetailsDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFFF5F5F5);
    final accent = Theme.of(context).primaryColor;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Products'),
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Products",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 12.sp)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.black54, size: 20),
              onPressed: () => showSearch(
                  context: context,
                  delegate: _ProductSearchDelegate(
                      products: products,
                      onNavigateToAdd: _navigateToAddProduct))),
          IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: Colors.black54, size: 20),
              onPressed: () {}),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => My_Profile())),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 14.r,
                backgroundColor: accent.withOpacity(0.12),
                backgroundImage:
                    (_profile != null && _profile!.profileImage.isNotEmpty)
                        ? NetworkImage(_profile!.profileImage)
                        : null,
                child: (_profile == null || _profile!.profileImage.isEmpty)
                    ? Text(
                        (_profile?.businessName ?? 'H')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                            color: accent,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600))
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SubscriptionWrapper(
        child: Column(
          children: [
            // ── Stats Row ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatCard(
                        icon: Icons.apps_outlined,
                        label: 'Total Products',
                        value: isLoading ? '—' : '$_totalProducts',
                        subtitle: 'In your catalog'),
                    const SizedBox(width: 10),
                    _StatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Pending Products',
                        value: isLoading ? '—' : '$_pendingProducts',
                        subtitle: 'Awaiting approval'),
                    const SizedBox(width: 10),
                    _StatCard(
                        icon: Icons.label_outline,
                        label: 'Categories',
                        value: isLoading ? '—' : '$_categoryCount',
                        subtitle: 'Product categories'),
                    const SizedBox(width: 10),
                    _StatCard(
                        icon: Icons.attach_money,
                        label: 'Inventory Value',
                        value: isLoading
                            ? '—'
                            : '₹${_formatCurrency(_inventoryValue)}',
                        subtitle: 'Total stock value',
                        compactValue: true),
                  ],
                ),
              ),
            ),

            // ── Filters + Toggle ─────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        underline: const SizedBox(),
                        isExpanded: true,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.black87),
                        items: statusFilters
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: Colors.black87))))
                            .toList(),
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        _ToggleBtn(
                            icon: Icons.grid_view,
                            selected: isGridView,
                            accent: accent,
                            onTap: () => setState(() => isGridView = true)),
                        _ToggleBtn(
                            icon: Icons.view_list,
                            selected: !isGridView,
                            accent: accent,
                            onTap: () => setState(() => isGridView = false)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Add New Product ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddProduct,
                  icon: const Icon(Icons.add, color: Colors.white, size: 15),
                  label: Text("Add New Product",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            // ── Product List / Grid ──────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? _EmptyState(onAdd: _navigateToAddProduct)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isGridView
                              ? GridView.builder(
                                  key: const ValueKey('grid'),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.60,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return _GridCard(
                                      product: product,
                                      accent: accent,
                                      discountPercent: _discountPercent(
                                          product['price'],
                                          product['sale_price']),
                                      onEdit: () => _editProduct(
                                          products.indexOf(product)),
                                      onDelete: () => _deleteProduct(
                                          products.indexOf(product)),
                                      onPreview: (images, i) => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ImagePreviewPage(
                                                  images: images,
                                                  initialIndex: i))),
                                      onViewDetails: () =>
                                          _showProductDetails(context, product),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  key: const ValueKey('list'),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 8, 12, 16),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return _ListCard(
                                      product: product,
                                      accent: accent,
                                      discountPercent: _discountPercent(
                                          product['price'],
                                          product['sale_price']),
                                      onEdit: () => _editProduct(
                                          products.indexOf(product)),
                                      onDelete: () => _deleteProduct(
                                          products.indexOf(product)),
                                      onPreview: (images, i) => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ImagePreviewPage(
                                                  images: images,
                                                  initialIndex: i))),
                                      onViewDetails: () =>
                                          _showProductDetails(context, product),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Details Dialog  — matches screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _ProductDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductDetailsDialog({required this.product});

  int get _discountPct {
    try {
      final orig = double.parse((product['price'] ?? 0).toString());
      final sale = double.parse((product['sale_price'] ?? 0).toString());
      if (orig > 0 && sale < orig)
        return (((orig - sale) / orig) * 100).round();
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final images = (product['images'] as List?) ?? [];
    final name = product['name'] ?? '';
    final category = product['category'] ?? '';
    final description = product['description'] ?? '';
    final price = product['price'];
    final salePrice = product['sale_price'];
    final stock = product['stock_quantity'] ?? 0;
    final brand = (product['brand'] ?? '').toString();
    final productForm = (product['productForm'] ?? '').toString();
    final size = (product['size'] ?? '').toString();
    final sizeMetric = (product['sizeMetric'] ?? '').toString();
    final forBodyPart = (product['forBodyPart'] ?? '').toString();
    final status = product['status'] ?? 'Pending';

    final sizeDisplay = (size.isNotEmpty && sizeMetric.isNotEmpty)
        ? '$size $sizeMetric'
        : size.isNotEmpty
            ? size
            : 'N/A';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────────────
              Row(
                children: [
                  Text('Product Details',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Two-column body ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: image + status + vendor
                  SizedBox(
                    width: 155,
                    child: Column(
                      children: [
                        // Product image with discount badge
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                images.isNotEmpty
                                    ? _ProductsPageState._buildImageWidget(
                                        images[0])
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: Text('600 × 600',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ),
                                      ),
                                if (_discountPct > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF2E1F3A),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text('$_discountPct% OFF',
                                          style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Status & Visibility
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('STATUS & VISIBILITY',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _StatusPill(
                                      label: status,
                                      color: status == 'Approved'
                                          ? const Color(0xFF2DB885)
                                          : status == 'Disapproved'
                                              ? Colors.red
                                              : Colors.orange,
                                      withDot: true),
                                  _StatusPill(
                                      label: 'Active in Store',
                                      color: const Color(0xFF2DB885),
                                      withDot: false),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Vendor
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('VENDOR',
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right column: details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        Text(category.toUpperCase(),
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        // Name
                        Text(name,
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                            softWrap: true),
                        const SizedBox(height: 6),
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('₹${salePrice ?? '—'}.00',
                                style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87)),
                            if (price != null &&
                                salePrice != null &&
                                price != salePrice) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('₹$price.00',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        decoration:
                                            TextDecoration.lineThrough)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text('DESCRIPTION',
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 3),
                        Text(description.isNotEmpty ? description : 'N/A',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.black87),
                            softWrap: true),
                        const SizedBox(height: 14),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 10),

                        // Stock | Brand | Product Form
                        Row(
                          children: [
                            Expanded(
                                child: _DetailField(
                                    label: 'STOCK',
                                    value: '$stock Units',
                                    withDot: true,
                                    dotColor: const Color(0xFF2DB885))),
                            Expanded(
                                child: _DetailField(
                                    label: 'BRAND',
                                    value: brand.isNotEmpty ? brand : 'N/A')),
                            Expanded(
                                child: _DetailField(
                                    label: 'PRODUCT FORM',
                                    value: productForm.isNotEmpty
                                        ? productForm
                                        : 'N/A')),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Size | For Body Part
                        Row(
                          children: [
                            Expanded(
                                child: _DetailField(
                                    label: 'SIZE', value: sizeDisplay)),
                            Expanded(
                                child: _DetailField(
                                    label: 'FOR BODY PART',
                                    value: forBodyPart.isNotEmpty
                                        ? forBodyPart
                                        : 'N/A')),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade200),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Field
// ─────────────────────────────────────────────────────────────────────────────
class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final bool withDot;
  final Color dotColor;

  const _DetailField({
    required this.label,
    required this.value,
    this.withDot = false,
    this.dotColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (withDot) ...[
              Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Pill
// ─────────────────────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool withDot;
  const _StatusPill(
      {required this.label, required this.color, required this.withDot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final bool compactValue;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.compactValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8E8))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: compactValue ? 15 : 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.1)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle Button
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.icon,
      required this.selected,
      required this.accent,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon,
            size: 16, color: selected ? Colors.white : Colors.grey.shade500),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text("No products found",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("Add your first product to get started",
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Add product")),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List Card
// ─────────────────────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color accent;
  final int discountPercent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(List images, int index) onPreview;
  final VoidCallback onViewDetails;

  const _ListCard({
    required this.product,
    required this.accent,
    required this.discountPercent,
    required this.onEdit,
    required this.onDelete,
    required this.onPreview,
    required this.onViewDetails,
  });

  static const Color _approvedColor = Color(0xFF2DB885);
  static const Color _disapprovedColor = Colors.red;
  static const Color _pendingColor = Colors.orange;
  static const Color _discountBg = Color(0xFF2E1F3A);

  Color get _statusColor {
    switch ((product['status'] ?? 'Pending') as String) {
      case 'Approved':
        return _approvedColor;
      case 'Disapproved':
        return _disapprovedColor;
      default:
        return _pendingColor;
    }
  }

  String get _sizeLabel {
    final s = (product['size'] ?? '').toString();
    final m = (product['sizeMetric'] ?? '').toString();
    if (s.isNotEmpty && m.isNotEmpty) return 'Size : $s$m';
    if (s.isNotEmpty) return 'Size : $s';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final images = (product['images'] as List?) ?? [];
    final status = (product['status'] ?? 'Pending') as String;
    final category = product['category'] ?? '';
    final name = product['name'] ?? '';
    final price = product['price'];
    final salePrice = product['sale_price'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 2.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? GestureDetector(
                          onTap: () => onPreview(images, 0),
                          child:
                              _ProductsPageState._buildImageWidget(images[0]))
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image,
                              size: 36, color: Colors.grey)),
                  // Status badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(5)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: _statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(status,
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Discount badge
                  if (discountPercent > 0)
                    Positioned(
                      top: 0,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 5),
                        decoration: const BoxDecoration(
                            color: _discountBg,
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(6),
                                bottomRight: Radius.circular(6))),
                        child: Text('$discountPercent%\nOFF',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Category + actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(category,
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: accent,
                          fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                _ActionIcon(
                    icon: Icons.remove_red_eye_outlined,
                    color: Colors.grey.shade500,
                    onTap: onViewDetails),
                const SizedBox(width: 5),
                _ActionIcon(
                    icon: Icons.edit_outlined, color: accent, onTap: onEdit),
                const SizedBox(width: 5),
                _ActionIcon(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    onTap: onDelete),
              ],
            ),
          ),

          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(name,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),

          // Size line
          if (_sizeLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Text(_sizeLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 9.5, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),

          // Price
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 11),
            child: Row(
              children: [
                Text('₹${salePrice ?? '—'}/-',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(width: 8),
                if (price != null && salePrice != null && price != salePrice)
                  Text('₹$price',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid Card
// ─────────────────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color accent;
  final int discountPercent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(List images, int index) onPreview;
  final VoidCallback onViewDetails;

  const _GridCard({
    required this.product,
    required this.accent,
    required this.discountPercent,
    required this.onEdit,
    required this.onDelete,
    required this.onPreview,
    required this.onViewDetails,
  });

  static const Color _approvedColor = Color(0xFF2DB885);
  static const Color _disapprovedColor = Colors.red;
  static const Color _pendingColor = Colors.orange;
  static const Color _discountBg = Color(0xFF2E1F3A);

  Color get _statusColor {
    switch ((product['status'] ?? 'Pending') as String) {
      case 'Approved':
        return _approvedColor;
      case 'Disapproved':
        return _disapprovedColor;
      default:
        return _pendingColor;
    }
  }

  String get _sizeLabel {
    final s = (product['size'] ?? '').toString();
    final m = (product['sizeMetric'] ?? '').toString();
    if (s.isNotEmpty && m.isNotEmpty) return '$s $m';
    if (s.isNotEmpty) return s;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final images = (product['images'] as List?) ?? [];
    final status = (product['status'] ?? 'Pending') as String;
    final name = product['name'] ?? '';
    final category = product['category'] ?? '';
    final price = product['price'];
    final salePrice = product['sale_price'];
    final rating = (product['rating'] ?? 4.4).toString();

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              fit: StackFit.expand,
              children: [
                images.isNotEmpty
                    ? GestureDetector(
                        onTap: () => onPreview(images, 0),
                        child: _ProductsPageState._buildImageWidget(images[0]))
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 30)),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(5)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: _statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 3),
                        Text(status,
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 0,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                      decoration: const BoxDecoration(
                          color: _discountBg,
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5))),
                      child: Text('$discountPercent%\nOFF',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2)),
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.more_vert,
                          color: Colors.black54, size: 16),
                    ),
                    onSelected: (v) {
                      if (v == 'view') onViewDetails();
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'view',
                          child: Row(children: [
                            Icon(Icons.remove_red_eye_outlined, size: 14),
                            SizedBox(width: 6),
                            Text('View')
                          ])),
                      const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, size: 14),
                            SizedBox(width: 6),
                            Text('Edit')
                          ])),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete, size: 14),
                            SizedBox(width: 6),
                            Text('Delete')
                          ])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: accent,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 1),
                  Text(_sizeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 8, color: Colors.grey.shade500)),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${salePrice ?? '—'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87)),
                            if (price != null &&
                                salePrice != null &&
                                price != salePrice)
                              Text('₹$price',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const SizedBox(width: 2),
                      Text(rating,
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Icon Button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(5)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Delegate
// ─────────────────────────────────────────────────────────────────────────────
class _ProductSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> products;
  final VoidCallback onNavigateToAdd;
  _ProductSearchDelegate(
      {required this.products, required this.onNavigateToAdd});

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = products
        .where((p) =>
            p['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (results.isEmpty)
      return Center(
          child: Text('No products found',
              style: GoogleFonts.poppins(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: (p['images'] as List?)?.isNotEmpty == true
                  ? _ProductsPageState._buildImageWidget(p['images'][0])
                  : const Icon(Icons.image),
            ),
          ),
          title: Text(p['name'] ?? '',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text('₹${p['sale_price']}',
              style: GoogleFonts.poppins(fontSize: 12)),
          onTap: () => close(context, p),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Preview Page
// ─────────────────────────────────────────────────────────────────────────────
class ImagePreviewPage extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  const ImagePreviewPage(
      {super.key, required this.images, required this.initialIndex});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  void _previousImage() {
    if (_currentIndex > 0)
      _controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1)
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.images.length,
            itemBuilder: (context, index) => Center(
              child: InteractiveViewer(
                  child: _ProductsPageState._buildImageWidget(
                      widget.images[index])),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context)),
            ),
          ),
          if (_currentIndex > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 28),
                  onPressed: _previousImage),
            ),
          if (_currentIndex < widget.images.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 28),
                  onPressed: _nextImage),
            ),
        ],
      ),
    );
  }
}
