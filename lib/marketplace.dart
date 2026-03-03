import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'services/marketplace_models.dart';
import 'cart_manager.dart';
import 'dart:ui';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<MarketplaceProduct> _allProducts = [];
  List<MarketplaceProduct> _filteredProductsList = [];
  List<MarketplaceSupplier> _suppliers = [];
  bool _isLoading = true;
  String? _selectedSupplierId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    cartManager.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.getSupplierProducts();
      final suppliersMap = <String, MarketplaceSupplier>{};

      for (var p in products) {
        if (p.supplierName.isNotEmpty) {
          suppliersMap[p.supplierEmail] = MarketplaceSupplier(
            id: p.vendorId,
            name: p.supplierName,
            email: p.supplierEmail,
            city: p.supplierCity,
            state: p.supplierState,
            country: p.supplierCountry,
            businessRegistrationNo: '',
          );
        }
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _suppliers = suppliersMap.values.toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProductsList = _allProducts.where((product) {
        final matchesSearch = _searchQuery.isEmpty ||
            product.productName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.supplierName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesSupplier = _selectedSupplierId == null ||
            product.vendorId == _selectedSupplierId ||
            product.supplierEmail == _selectedSupplierId;

        return matchesSearch && matchesSupplier;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(currentPage: 'Marketplace'),
      endDrawer: const _CartSidebar(),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              if (cartManager.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartManager.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchProducts,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatsStrip()),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Discover and order premium products from verified suppliers worldwide.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _applyFilters();
                            });
                          },
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search products or suppliers...',
                            hintStyle: GoogleFonts.poppins(fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildSuppliersList()),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text(
                          _selectedSupplierId == null
                              ? '${_filteredProductsList.length} Products Found'
                              : 'Products from ${_suppliers.firstWhere((s) => s.id == _selectedSupplierId || s.email == _selectedSupplierId, orElse: () => _suppliers[0]).name}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildProductCard(
                                _filteredProductsList[index]);
                          },
                          childCount: _filteredProductsList.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsStrip() {
    // Fix: Correct correctly calculate market value using salePrice of all products
    final totalMarketValue =
        _allProducts.fold(0.0, (sum, p) => sum + p.salePrice);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
              'Products', '${_allProducts.length}', Icons.inventory_2_outlined),
          _buildStatItem(
              'Suppliers', '${_suppliers.length}', Icons.business_outlined),
          _buildStatItem(
              'Market Value',
              '₹${(totalMarketValue / 1000).toStringAsFixed(1)}k',
              Icons.account_balance_wallet_outlined),
          _buildStatItem('Rating', '4.5', Icons.star_outline),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSuppliersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Suppliers',
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _suppliers.length,
            itemBuilder: (context, index) {
              final supplier = _suppliers[index];
              return _buildSupplierItem(
                  supplier.email,
                  supplier.name,
                  _selectedSupplierId == supplier.id ||
                      _selectedSupplierId == supplier.email);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierItem(String? id, String name, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // If already selected, deselect it (since "All" is removed, deselect acts as All)
          _selectedSupplierId = isSelected ? null : id;
          _applyFilters();
        });
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade100,
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(MarketplaceProduct product) {
    bool inStock = product.stock > 0;
    int discount = product.salePrice < product.price
        ? (((product.price - product.salePrice) / product.price) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: product.productImages.isNotEmpty
                      ? Image.network(
                          product.productImages[0],
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: Colors.grey),
                        )
                      : const Icon(Icons.inventory_2_outlined,
                          size: 40, color: Colors.grey),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          inStock ? 'In Stock' : 'Out of Stock',
                          style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          '4.5',
                          style: GoogleFonts.poppins(
                              fontSize: 8, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.supplierName,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${product.salePrice}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      if (product.salePrice < product.price)
                        Text(
                          '₹${product.price}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            cartManager.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${product.productName} added to cart'),
                                duration: const Duration(seconds: 1),
                                action: SnackBarAction(
                                  label: 'VIEW',
                                  onPressed: () => _scaffoldKey.currentState
                                      ?.openEndDrawer(),
                                  textColor: Colors.white,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Add',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            cartManager.addToCart(product);
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Buy',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
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

  void _showProductDetails(MarketplaceProduct product) {
    showDialog(
      context: context,
      builder: (context) =>
          Center(child: _ProductDetailsDialog(product: product)),
    );
  }
}

class _ProductDetailsDialog extends StatefulWidget {
  final MarketplaceProduct product;
  const _ProductDetailsDialog({required this.product});

  @override
  State<_ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<_ProductDetailsDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: p.productImages.isNotEmpty
                        ? Image.network(p.productImages[0], fit: BoxFit.cover)
                        : const Icon(Icons.inventory_2_outlined,
                            size: 60, color: Colors.grey),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: Colors.black, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.productName,
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹${p.salePrice}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'by ${p.supplierName}',
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.description,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Quantity',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      _buildQtyBtn(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_quantity',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      _buildQtyBtn(
                          Icons.add, () => setState(() => _quantity++)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            cartManager.addToCart(p, quantity: _quantity);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('ADD TO CART'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            cartManager.addToCart(p, quantity: _quantity);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('BUY NOW'),
                        ),
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

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _CartSidebar extends StatelessWidget {
  const _CartSidebar();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: ListenableBuilder(
          listenable: cartManager,
          builder: (context, _) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              'Your Cart (${cartManager.itemCount} items)',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  const Divider(),
                  if (cartManager.items.isEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Your cart is empty',
                              style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    )
                  else ...[
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: cartManager.items.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = cartManager.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: item.product.productImages.isNotEmpty
                                      ? Image.network(
                                          item.product.productImages[0],
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.image),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.productName,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text('₹${item.product.salePrice}',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                        icon:
                                            const Icon(Icons.remove, size: 14),
                                        onPressed: () =>
                                            cartManager.updateQuantity(
                                                item.product.id,
                                                item.quantity - 1),
                                        constraints: const BoxConstraints(
                                            minWidth: 28, minHeight: 28),
                                        padding: EdgeInsets.zero),
                                    Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    IconButton(
                                        icon: const Icon(Icons.add, size: 14),
                                        onPressed: () =>
                                            cartManager.updateQuantity(
                                                item.product.id,
                                                item.quantity + 1),
                                        constraints: const BoxConstraints(
                                            minWidth: 28, minHeight: 28),
                                        padding: EdgeInsets.zero),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5))
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              Text('₹${cartManager.totalAmount}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showCheckoutDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('PROCEED TO CHECKOUT',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Center(child: _CheckoutDialog()),
    );
  }
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Finalize Order',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Shipping Address',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your full delivery address...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items Total'),
                Text('₹${cartManager.totalAmount}'),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shipping Fee'),
                Text('₹0 (FREE)'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Payable',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${cartManager.totalAmount}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter shipping address')));
                  return;
                }
                Navigator.pop(context);
                cartManager.clearCart();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Order Placed!'),
                    content: const Text(
                        'Your order has been successfully sent to the suppliers. You will be notified once it is confirmed.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('GREAT'))
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('PLACE ORDER',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
