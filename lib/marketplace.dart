import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  // Sample product data with placeholder images
  final List<Map<String, dynamic>> products = [
    {
      'id': '1',
      'name': 'Professional Hair Dryer',
      'vendor': 'BeautyPro Supplies',
      'price': 8999,
      'originalPrice': 12000,
      'image': '',
      'rating': 4.5,
      'reviews': 128,
      'inStock': true,
      'discount': 25,
      'verified': true,
      'featured': true,
    },
    {
      'id': '2',
      'name': 'LED Facial Therapy Mask',
      'vendor': 'GlowTech Beauty',
      'price': 15999,
      'originalPrice': 19999,
      'image': '',
      'rating': 4.8,
      'reviews': 96,
      'inStock': true,
      'discount': 20,
      'verified': true,
      'featured': true,
    },
    {
      'id': '3',
      'name': 'Organic Argan Oil',
      'vendor': 'NatureEssence',
      'price': 2499,
      'originalPrice': 3499,
      'image': '',
      'rating': 4.3,
      'reviews': 215,
      'inStock': false,
      'discount': 28,
      'verified': false,
      'featured': false,
    },
    {
      'id': '4',
      'name': 'Wireless Bluetooth Speaker',
      'vendor': 'TechWorld',
      'price': 3999,
      'originalPrice': 5999,
      'image': '',
      'rating': 4.6,
      'reviews': 87,
      'inStock': true,
      'discount': 33,
      'verified': true,
      'featured': true,
    },
    {
      'id': '5',
      'name': 'Ceramic Hair Straightener',
      'vendor': 'StyleMaster',
      'price': 4599,
      'originalPrice': 6500,
      'image': '',
      'rating': 4.2,
      'reviews': 142,
      'inStock': true,
      'discount': 29,
      'verified': true,
      'featured': false,
    },
    {
      'id': '6',
      'name': 'Luxury Spa Robe',
      'vendor': 'ComfortWear',
      'price': 2999,
      'originalPrice': 3999,
      'image': '',
      'rating': 4.7,
      'reviews': 65,
      'inStock': false,
      'discount': 25,
      'verified': false,
      'featured': true,
    },
  ];

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showVerifiedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtered products getter
  List<Map<String, dynamic>> get _filteredProducts {
    return products.where((product) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product['vendor'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      // Verified filter
      final matchesVerified = !_showVerifiedOnly || product['verified'] == true;

      return matchesSearch && matchesVerified;
    }).toList();
  }

  // Featured products getter
  List<Map<String, dynamic>> get _featuredProducts {
    return products.where((product) => product['featured'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Marketplace'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header description
            Container(
              margin: const EdgeInsets.all(16),
              child: Text(
                'Discover and order premium products from verified suppliers worldwide.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter buttons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Verified only filter
                  FilterChip(
                    label: Text(
                      'Verified Only',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    selected: _showVerifiedOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showVerifiedOnly = selected;
                      });
                    },
                    selectedColor: const Color(0xFF457BFF),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    labelStyle: GoogleFonts.poppins(
                      color: _showVerifiedOnly ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // All categories filter
                  FilterChip(
                    label: Text(
                      'All Categories',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    selected: true,
                    onSelected: (selected) {},
                    selectedColor: const Color(0xFF457BFF),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Featured products section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_featuredProducts.length} Premium Products from Trusted Suppliers',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Products grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final inStock = product['inStock'] as bool;
    final discount = product['discount'] as int?;
    final rating = product['rating'] as double;
    final reviews = product['reviews'] as int;
    final isVerified = product['verified'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with tags
          Stack(
            children: [
              // Product image placeholder
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey.shade500,
                ),
              ),
              // Tags
              Positioned(
                top: 8,
                left: 8,
                child: Column(
                  children: [
                    // In stock/out of stock tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Discount tag
                    if (discount != null && discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Rating tag
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '$rating',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Product details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Vendor name
                Text(
                  product['vendor'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Row(
                  children: [
                    Text(
                      '₹${product['price']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (product['originalPrice'] != product['price'])
                      Text(
                        '₹${product['originalPrice']}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  children: [
                    // Add to cart button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Add to cart functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF457BFF),
                          side: BorderSide(color: const Color(0xFF457BFF), width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Buy now button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Buy now functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF457BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Buy',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}