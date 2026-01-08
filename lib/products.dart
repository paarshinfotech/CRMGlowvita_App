import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'add_product.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<Products> {
  static const double _radius = 12;
  static const double _gap = 12;

  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All Status';
  bool isGridView = true;
  String searchQuery = '';
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

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
  }

  Future<void> _loadProducts() async {
    try {
      final apiProducts = await ApiService.getProducts();
      setState(() {
        products = apiProducts.map((product) => {
          '_id': product.id,
          'name': product.productName,
          'category': product.category,
          'description': product.description,
          'price': product.price,
          'sale_price': product.salePrice,
          'stock_quantity': product.stock,
          'images': product.productImages,
          'status': product.status?.toLowerCase() == 'approved' ? 'Approved' : 
                   product.status?.toLowerCase() == 'disapproved' ? 'Disapproved' : 'Pending',
          'rating': 4.4, // default rating since not provided in API
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editProduct(int index) async {
    // For now, we'll pass the product data to AddProductPage
    // In a real implementation, you'd want to call an API to update the product
    final editedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          existingProduct: products[index],
        ),
      ),
    );
    if (editedProduct != null && editedProduct is Map<String, dynamic>) {
      setState(() => products[index] = editedProduct);
    }
  }

  void _deleteProduct(int index) async {
    final productId = products[index]['_id'];
    final productName = products[index]['name'];
    
    // Confirm deletion with user
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete '$productName'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 12),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
                SizedBox(width: 12),
                Text("Deleting product..."),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );

        // Call the API to delete the product
        bool success = await ApiService.deleteProduct(productId);
        
        if (success) {
          // Remove from local list
          setState(() {
            products.removeAt(index);
          });
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Product deleted successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to delete product"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting product: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() => products.add(result));
    }
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

  int get productCount => filteredProducts.length;

  static Widget _buildImageWidget(dynamic image) {
    try {
      // Handle URL strings
      if (image is String) {
        if (image.startsWith('http')) {
          // It's a URL, load from network
          return Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default asset image if network fails
              return Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              );
            },
          );
        } else if (image.startsWith('assets/')) {
          // It's an asset path
          return Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default asset image if asset doesn't exist
              return Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              );
            },
          );
        } else {
          // Regular file path
          return Image.file(
            File(image),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default asset image if file doesn't exist
              return Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              );
            },
          );
        }
      }
      
      // Handle XFile objects
      if (image is XFile) {
        return Image.file(
          File(image.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to default asset image if file doesn't exist
            return Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            );
          },
        );
      }
      
      // Fallback for any other format
      return Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      );
    } catch (e) {
      // Fallback to default assets if the image loading fails
      return Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep your original palette
    const scaffoldBg = Color(0xFFF5F5F5);
    const cardBg = Colors.white;
    const accent = Color(0xFF457BFF);
    const approved = Color(0xFF4ECDC4);
    const disapproved = Colors.red;
    const pending = Colors.orange;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Products'),  
      appBar: AppBar(
        title: Text(
          "Product Catalog", 
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
      backgroundColor: scaffoldBg,
      body: Padding(
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
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    underline: const SizedBox(),
                    items: statusFilters
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: GoogleFonts.poppins(fontSize: 12),
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
                const SizedBox(width: 8),

                // Grid/List Segmented toggle (explicit colors)
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
                    foregroundColor:
                        WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? Colors.blue
                          : Colors.grey;
                    }),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Add (kept blue)
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
                    backgroundColor: Colors.blue,
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

            // Count card (unchanged colors)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.inventory_2, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Products',
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$productCount',
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

            // Content
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
                                          products.indexOf(product)),
                                      onDelete: () => _deleteProduct(
                                          products.indexOf(product)),
                                      onPreview: (images, i) => Navigator.push(
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
                                          products.indexOf(product)),
                                      onDelete: () => _deleteProduct(
                                          products.indexOf(product)),
                                      onPreview: (images, i) => Navigator.push(
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
          Text("No products found",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text("Add your first product to get started",
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
  final void Function(List images, int index) onPreview;

  const _GridCard({
    required this.product,
    required this.accent,
    required this.approved,
    required this.disapproved,
    required this.pending,
    required this.onEdit,
    required this.onDelete,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final images = (product['images'] as List?) ?? [];
    final status = (product['status'] ?? 'Pending') as String;
    final stock = (product['stock_quantity'] ?? 0) as int;
    final isInStock = stock > 0;
    final rating = (product['rating'] ?? 4.4).toString();

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
        onTap: images.isNotEmpty ? () => onPreview(images, 0) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with tags overlayed
            AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  images.isNotEmpty
                      ? _ProductsPageState._buildImageWidget(images[0])
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 30),
                        ),
                  // Status badge (top left)
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
                            status == 'Approved'
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
                  // Stock badge (top right)
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      product['category'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Name
                    Text(
                      product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11, // Reduced from 13
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    
                    // Description
                    Text(
                      product['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price and rating
                    Row(
                      children: [
                        Text(
                          "₹${product['sale_price']}",
                          style: GoogleFonts.poppins(
                            fontSize: 14, // Reduced from 16
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
                    const Spacer(), // Push buttons to bottom
                    const SizedBox(height: 8),
                    
                    // Edit and Delete buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete, size: 16),
                          label: Text(
                            ' ',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
  final void Function(List images, int index) onPreview;

  const _ListTileCard({
    required this.product,
    required this.accent,
    required this.approved,
    required this.disapproved,
    required this.pending,
    required this.onEdit,
    required this.onDelete,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final images = (product['images'] as List?) ?? [];
    final status = (product['status'] ?? 'Pending') as String;
    final stock = (product['stock_quantity'] ?? 0) as int;
    final isInStock = stock > 0;
    final rating = (product['rating'] ?? 4.4).toString();

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
                width: 75,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    images.isNotEmpty
                        ? _ProductsPageState._buildImageWidget(images[0])
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 30),
                          ),
                    // Status badge (top left)
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
                              status == 'Approved'
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
                    // Stock badge (top right)
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
                  // Category
                  Text(
                    product['category'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.blue, // kept blue in list style
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Name
                  Text(
                    product['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12, // Reduced from 13
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Description
                  Text(
                    product['description'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price and rating
                  Row(
                    children: [
                      Text(
                        "₹${product['sale_price']}",
                        style: GoogleFonts.poppins(
                          fontSize: 13, // Reduced from 14
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
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
                  // Edit and Delete buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 14),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.poppins(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 14),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.edit, color: Colors.blue, size: 18),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete, color: Colors.red, size: 18),
                  ),
                ),
              ],
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
                  child: _ProductsPageState._buildImageWidget(img),
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