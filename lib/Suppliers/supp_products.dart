import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'add_supp_product.dart';
import './supp_drawer.dart';
import '../services/api_service.dart';
import '../widgets/subscription_wrapper.dart';

class SuppProducts extends StatefulWidget {
  const SuppProducts({super.key});

  @override
  State<SuppProducts> createState() => _SuppProductsPageState();
}

class _SuppProductsPageState extends State<SuppProducts> {
  static const double _radius = 12;
  static const double _gap = 12;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = false;
  String? _errorMessage;
  String selectedStatus = 'All Status';
  String? selectedCategoryId;
  String searchQuery = '';
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await ApiService.getCRMProductCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products.map((k) => k.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  final List<String> statusFilters = [
    'All Status',
    'Pending',
    'Approved',
    'Disapproved'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editProduct(int index) async {
    final product = _products[index];
    final editedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSuppProductPage(
          existingProduct: product,
        ),
      ),
    );
    if (editedProduct != null) {
      _fetchProducts(); // Refresh after edit
    }
  }

  void _deleteProduct(int index) async {
    final product = _products[index];
    final id = product['_id'] ?? product['id'];

    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteProduct(id.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        _fetchProducts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSuppProductPage()),
    );
    if (result != null) {
      _fetchProducts(); // Refresh after add
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    return _products.where((product) {
      // Search
      final name = (product['name'] ?? product['productName'] ?? '').toString();
      final matchesSearch =
          name.toLowerCase().contains(searchQuery.toLowerCase());

      // Status
      final status = (product['status'] ?? 'Pending').toString();
      final matchesStatus = selectedStatus == 'All Status' ||
          status.toLowerCase() == selectedStatus.toLowerCase();

      // Category
      final catId = product['category'] is Map
          ? product['category']['_id']?.toString()
          : product['category']?.toString();
      final matchesCategory = selectedCategoryId == null ||
          catId == selectedCategoryId ||
          (product['categoryName'] ?? product['category'] ?? '').toString() ==
              selectedCategoryId;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  int get productCount => filteredProducts.length;

  static Widget _buildImageWidget(dynamic image) {
    try {
      if (image is XFile) {
        return Image.file(
          File(image.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            );
          },
        );
      }

      if (image is String) {
        if (image.startsWith('assets/')) {
          return Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              );
            },
          );
        } else if (image.startsWith('http')) {
          return Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          );
        } else {
          return Image.file(
            File(image),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              );
            },
          );
        }
      }

      return Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductDetailsDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFFF5F5F5);
    const cardBg = Colors.white;
    final accent = Theme.of(context).primaryColor;
    const approved = Color(0xFF4ECDC4);
    const disapproved = Colors.red;
    const pending = Colors.orange;

    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'SuppProducts'),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Supplier Account",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontSize: 14.sp,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: scaffoldBg,
      body: SubscriptionWrapper(
        child: Padding(
          padding: const EdgeInsets.all(_gap),
        child: Column(
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => searchQuery = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search Products...',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
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

            // Filters + toggle + add
            Row(
              children: [
                // Status dropdown
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: statusFilters
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: GoogleFonts.poppins(fontSize: 10),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Category dropdown
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategoryId,
                        hint: Text(
                          _isLoadingCategories ? '...' : 'All Category',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Category',
                                style: GoogleFonts.poppins(fontSize: 10)),
                          ),
                          ..._categories.map((cat) => DropdownMenuItem(
                                value: cat['_id'].toString(),
                                child: Text(
                                  cat['name'] ?? '',
                                  style: GoogleFonts.poppins(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Grid/List toggle
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.grid_view, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.view_list, size: 16),
                    ),
                  ],
                  selected: {isGridView},
                  onSelectionChanged: (s) =>
                      setState(() => isGridView = s.first),
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                    side: WidgetStateProperty.all(
                      BorderSide(color: Colors.grey.shade300),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? Theme.of(context).primaryColor
                          : Colors.grey;
                    }),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Add Button
                ElevatedButton.icon(
                  onPressed: _navigateToAddProduct,
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: Text(
                    "Add",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Count card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
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
                    child: Icon(Icons.inventory_2,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Supplier Products',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Text('$productCount products in catalog',
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
                    child: Text('$productCount',
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                  onPressed: _fetchProducts,
                                  child: const Text('Retry')),
                            ],
                          ),
                        )
                      : filteredProducts.isEmpty
                          ? _EmptyState(onAdd: _navigateToAddProduct)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: isGridView
                                  ? GridView.builder(
                                      key: const ValueKey('grid'),
                                      padding: EdgeInsets.zero,
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
                                          approved: approved,
                                          disapproved: disapproved,
                                          pending: pending,
                                          onEdit: () => _editProduct(
                                              _products.indexOf(product)),
                                          onDelete: () => _deleteProduct(
                                              _products.indexOf(product)),
                                          onDetails: () =>
                                              _showProductDetails(product),
                                          onPreview: (images, i) =>
                                              Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ImagePreviewPage(
                                                images: images,
                                                initialIndex: i,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : ListView.separated(
                                      key: const ValueKey('list'),
                                      padding: EdgeInsets.zero,
                                      itemCount: filteredProducts.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final product = filteredProducts[index];
                                        return _ListTileCard(
                                          product: product,
                                          accent: accent,
                                          approved: approved,
                                          disapproved: disapproved,
                                          pending: pending,
                                          onEdit: () => _editProduct(
                                              _products.indexOf(product)),
                                          onDelete: () => _deleteProduct(
                                              _products.indexOf(product)),
                                          onDetails: () =>
                                              _showProductDetails(product),
                                          onPreview: (images, i) =>
                                              Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ImagePreviewPage(
                                                images: images,
                                                initialIndex: i,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

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
          Text("No supplier products found",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text("Add your first supplier product to get started",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Add product"),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color accent;
  final Color approved;
  final Color disapproved;
  final Color pending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetails;
  final void Function(List images, int index) onPreview;

  const _GridCard({
    required this.product,
    required this.accent,
    required this.approved,
    required this.disapproved,
    required this.pending,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final images = (product['productImages'] ??
        product['product_images'] ??
        product['images'] ??
        []) as List;
    final status = (product['status'] ?? 'Pending') as String;
    final stock = (product['stock'] ?? product['stock_quantity'] ?? 0);
    final isInStock =
        (stock is int ? stock : int.tryParse(stock.toString()) ?? 0) > 0;
    final rating = (product['rating'] ?? 4.4).toString();
    final brand = product['brand'] ?? '';

    Color statusBg;
    switch (status) {
      case 'Approved':
        statusBg = approved;
        break;
      case 'Disapproved':
        statusBg = disapproved;
        break;
      default:
        statusBg = pending;
    }

    return Card(
      color: Colors.white,
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with tags
            AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? _SuppProductsPageState._buildImageWidget(images[0])
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 30),
                        ),
                  // Status badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status.toLowerCase() == 'approved'
                                ? Icons.check_circle
                                : Icons.pending,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category Badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product['categoryName'] ?? product['category'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Stock badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        isInStock ? 'In Stock' : 'Out',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: isInStock ? Colors.black87 : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  if (brand.isNotEmpty)
                    Text(
                      brand,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Name
                  Text(
                    product['name'] ?? product['productName'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price and rating
                  Row(
                    children: [
                      Text(
                        "₹${product['salePrice'] ?? product['price'] ?? product['sale_price'] ?? 0}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action icon buttons
                  Row(
                    children: [
                      _ActionIcon(
                        icon: Icons.visibility_outlined,
                        color: accent,
                        onTap: onDetails,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        icon: Icons.edit_outlined,
                        color: Colors.blue.shade600,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        icon: Icons.delete_outline,
                        color: Colors.red.shade400,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color accent;
  final Color approved;
  final Color disapproved;
  final Color pending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetails;
  final void Function(List images, int index) onPreview;

  const _ListTileCard({
    required this.product,
    required this.accent,
    required this.approved,
    required this.disapproved,
    required this.pending,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final images = (product['productImages'] ??
        product['product_images'] ??
        product['images'] ??
        []) as List;
    final status = (product['status'] ?? 'Pending') as String;
    final stock = (product['stock'] ?? product['stock_quantity'] ?? 0);
    final isInStock =
        (stock is int ? stock : int.tryParse(stock.toString()) ?? 0) > 0;
    final rating = (product['rating'] ?? 4.4).toString();
    final brand = product['brand'] ?? '';

    Color statusBg;
    switch (status) {
      case 'Approved':
        statusBg = approved;
        break;
      case 'Disapproved':
        statusBg = disapproved;
        break;
      default:
        statusBg = pending;
    }

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    images.isNotEmpty
                        ? _SuppProductsPageState._buildImageWidget(images[0])
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 30),
                          ),
                    // Status badge
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status.toLowerCase() == 'approved'
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: Colors.white,
                              size: 9,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Stock badge
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isInStock ? 'In Stock' : 'Out',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: isInStock ? Colors.black87 : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand & Category
                  Row(
                    children: [
                      if (brand.isNotEmpty)
                        Text(
                          brand,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (product['categoryName'] ?? product['category'] ?? '')
                              .toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Name
                  Text(
                    product['productName'] ?? product['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price and rating
                  Row(
                    children: [
                      Text(
                        "₹${product['salePrice'] ?? product['sale_price'] ?? product['price'] ?? 0}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        rating,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Action icon buttons
                  Row(
                    children: [
                      _ActionIcon(
                        icon: Icons.visibility_outlined,
                        color: accent,
                        onTap: onDetails,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        icon: Icons.edit_outlined,
                        color: Colors.blue.shade600,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        icon: Icons.delete_outline,
                        color: Colors.red.shade400,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePreviewPage extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

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
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return Center(
                child: InteractiveViewer(
                  child: _SuppProductsPageState._buildImageWidget(img),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (_currentIndex > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 28),
                onPressed: _previousImage,
              ),
            ),
          if (_currentIndex < widget.images.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 28),
                onPressed: _nextImage,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductDetailsDialog({required this.product});

  int get _discountPct {
    try {
      final orig = double.parse((product['price'] ?? 0).toString());
      final sale = double.parse((product['salePrice'] ??
              product['sale_price'] ??
              product['price'] ??
              0)
          .toString());
      if (orig > 0 && sale < orig)
        return (((orig - sale) / orig) * 100).round();
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final images = (product['productImages'] ??
        product['product_images'] ??
        product['images'] ??
        []) as List;
    final name =
        (product['productName'] ?? product['name'] ?? 'N/A').toString();
    final category =
        (product['categoryName'] ?? product['category'] ?? 'Uncategorized')
            .toString();
    final description =
        (product['description'] ?? 'No description available').toString();
    final price = product['price'];
    final salePrice =
        product['salePrice'] ?? product['sale_price'] ?? product['price'];
    final stock = product['stock'] ?? product['stock_quantity'] ?? 0;
    final brand = (product['brand'] ?? 'N/A').toString();
    final size = (product['size'] ?? '').toString();
    final sizeMetric = (product['sizeMetric'] ?? '').toString();
    final status = (product['status'] ?? 'Pending').toString();

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
                  // Left column: image + status
                  SizedBox(
                    width: 140,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                images.isNotEmpty
                                    ? _SuppProductsPageState._buildImageWidget(
                                        images[0])
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image,
                                            size: 40, color: Colors.grey),
                                      ),
                                if (_discountPct > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF2E1F3A),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text('$_discountPct% OFF',
                                          style: GoogleFonts.poppins(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('STATUS',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              _StatusPill(
                                  label: status,
                                  color: status.toLowerCase() == 'approved'
                                      ? const Color(0xFF2DB885)
                                      : status.toLowerCase() == 'disapproved'
                                          ? Colors.red
                                          : Colors.orange,
                                  withDot: true),
                            ],
                          ),
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
                        Text(category.toUpperCase(),
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(name,
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                            softWrap: true),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('₹$salePrice',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87)),
                            if (price != null &&
                                salePrice != null &&
                                price.toString() != salePrice.toString()) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('₹$price',
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
                        Text('DESCRIPTION',
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 4),
                        Text(description,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black87,
                                height: 1.4),
                            softWrap: true),
                        const SizedBox(height: 14),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: _infoField('STOCK', '$stock Units')),
                            Expanded(child: _infoField('BRAND', brand)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _infoField('SIZE', sizeDisplay)),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text('Close',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}

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

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
