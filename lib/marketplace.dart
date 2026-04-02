import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'services/marketplace_models.dart';
import 'cart_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLOR CONSTANTS  (matches the purple-based design)
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF4A2C3C);
const _kPrimaryLight = Color(0xFFF6F0F2);
const _kPrimaryMid = Color(0xFF633D50);
const _kAccent = Color(0xFFD4AF37);
const _kBg = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFE8E8F0);
const _kSuccess = Color(0xFF10B981);
const _kDanger = Color(0xFFEF4444);
const _kMuted = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────
// MARKETPLACE PAGE
// ─────────────────────────────────────────────────────────────────────────────
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
    cartManager.refreshCart();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProductsList = _allProducts.where((p) {
        final q = _searchQuery.toLowerCase();
        final matchesSearch = q.isEmpty ||
            p.productName.toLowerCase().contains(q) ||
            p.supplierName.toLowerCase().contains(q);
        final matchesSupplier = _selectedSupplierId == null ||
            p.vendorId == _selectedSupplierId ||
            p.supplierEmail == _selectedSupplierId;
        return matchesSearch && matchesSupplier;
      }).toList();
    });
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  MarketplaceSupplier? get _selectedSupplier => _selectedSupplierId == null
      ? null
      : _suppliers.firstWhere(
          (s) => s.id == _selectedSupplierId || s.email == _selectedSupplierId,
          orElse: () => _suppliers.first,
        );

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(currentPage: 'Marketplace'),
      endDrawer: const _CartSidebar(),
      backgroundColor: _kBg,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text(
          'Marketplace',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 12.sp),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              if (cartManager.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${cartManager.itemCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
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
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _fetchProducts,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatsStrip()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(
                          'Discover and order premium products from verified suppliers worldwide.',
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: _kMuted),
                        ),
                      ),
                    ),
                    // ── Search ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kBorder),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1))
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) {
                              setState(() => _searchQuery = v);
                              _applyFilters();
                            },
                            textInputAction: TextInputAction.search,
                            style: GoogleFonts.dmSans(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search products or suppliers...',
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: _kMuted),
                              prefixIcon: const Icon(Icons.search,
                                  color: _kMuted, size: 20),
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        _applyFilters();
                                      },
                                    ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ── Suppliers ──
                    SliverToBoxAdapter(child: _buildSuppliersSection()),
                    // ── Products header ──
                    if (_selectedSupplierId != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Text(
                            'Products from ${_selectedSupplier?.name ?? ''}',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      // ── Products Grid ──
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.60,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) =>
                                _buildProductCard(_filteredProductsList[i]),
                            childCount: _filteredProductsList.length,
                          ),
                        ),
                      ),
                    ] else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.shopping_bag_outlined,
                                    size: 48, color: _kBorder),
                                const SizedBox(height: 16),
                                Text(
                                  'Select a supplier to view products',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: _kMuted,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Stats Strip ───────────────────────────────────────────────────────────
  Widget _buildStatsStrip() {
    final totalValue = _allProducts.fold(0.0, (s, p) => s + p.salePrice);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _statItem('Products', '${_allProducts.length}',
                  Icons.inventory_2_outlined),
              _statItem(
                  'Suppliers', '${_suppliers.length}', Icons.business_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem(
                  'Market Value',
                  '₹${(totalValue / 1000).toStringAsFixed(1)}k',
                  Icons.account_balance_wallet_outlined),
              _statItem('Rating', '4.5', Icons.star_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Icon(icon, size: 20, color: _kPrimary),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            Text(label,
                style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
          ],
        ),
      ),
    );
  }

  // ── Suppliers Section ─────────────────────────────────────────────────────
  Widget _buildSuppliersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text('Suppliers',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 110,
            ),
            itemCount: _suppliers.length,
            itemBuilder: (context, i) {
              final s = _suppliers[i];
              final isSelected =
                  _selectedSupplierId == s.id || _selectedSupplierId == s.email;
              return _buildSupplierCard(s, isSelected);
            },
          ),
        ),
      ],
    );
  }

  /// Horizontal card matching screenshot 1
  Widget _buildSupplierCard(MarketplaceSupplier supplier, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSupplierId = isSelected
              ? null
              : (supplier.id.isEmpty ? supplier.email : supplier.id);
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kPrimary : _kBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.07 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : const Color(0xFFEDE9F6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isSelected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    supplier.name,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: _kMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${supplier.city}, ${supplier.country}',
                          style:
                              GoogleFonts.dmSans(fontSize: 10, color: _kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 11, color: _kPrimary),
                      const SizedBox(width: 2),
                      Text(
                        '${_allProducts.where((p) => p.vendorId == supplier.id || p.supplierEmail == supplier.email).length} Products',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (supplier.businessRegistrationNo.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 10, color: _kMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            supplier.businessRegistrationNo,
                            style:
                                GoogleFonts.dmSans(fontSize: 9, color: _kMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? _kPrimary : _kBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: isSelected ? Colors.white : _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product Card ──────────────────────────────────────────────────────────
  Widget _buildProductCard(MarketplaceProduct product) {
    final inStock = product.stock > 0;
    final discount = product.salePrice < product.price
        ? (((product.price - product.salePrice) / product.price) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EEFA),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: product.productImages.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                          child: Image.network(product.productImages[0],
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: Color(0xFFC4B5F0))),
                        )
                      : const Center(
                          child: Icon(Icons.inventory_2_outlined,
                              size: 40, color: Color(0xFFC4B5F0))),
                ),
                // Stock badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(inStock ? 'In Stock' : 'Out of Stock',
                          inStock ? _kSuccess : _kDanger),
                      if (discount > 0) ...[
                        const SizedBox(height: 4),
                        _badge('$discount% OFF', _kAccent),
                      ],
                    ],
                  ),
                ),
                // Rating
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: _kAccent, size: 12),
                        const SizedBox(width: 2),
                        Text('4.5',
                            style: GoogleFonts.poppins(
                                fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(product.supplierName,
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('₹${product.salePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 5),
                      if (product.salePrice < product.price)
                        Text('₹${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _kMuted,
                              decoration: TextDecoration.lineThrough,
                            )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Add to cart
                      Expanded(
                        child: _cardButton(
                          label: inStock ? 'Add' : 'Sold Out',
                          filled: false,
                          enabled: inStock,
                          onPressed: () async {
                            try {
                              await cartManager.addToCart(product);
                              if (context.mounted) {
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
                              }
                            } catch (_) {}
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Buy now
                      Expanded(
                        child: _cardButton(
                          label: 'Buy',
                          filled: true,
                          enabled: inStock,
                          onPressed: () => _openQuickCheckout(product),
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

  void _openQuickCheckout(MarketplaceProduct product) async {
    try {
      await cartManager.addToCart(product, quantity: 1);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => _QuickCheckoutDialog(product: product, quantity: 1),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to proceed to checkout')),
        );
      }
    }
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600)),
      );

  Widget _cardButton({
    required String label,
    required bool filled,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: !enabled
              ? Colors.grey[200]
              : filled
                  ? _kPrimary
                  : Colors.white,
          foregroundColor: !enabled
              ? Colors.grey[500]
              : filled
                  ? Colors.white
                  : _kPrimary,
          side: enabled && !filled
              ? const BorderSide(color: _kPrimary, width: 1.5)
              : BorderSide.none,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label,
            style:
                GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Product Details ───────────────────────────────────────────────────────
  void _showProductDetails(MarketplaceProduct product) {
    showDialog(
      context: context,
      builder: (_) => _ProductDetailsDialog(
        product: product,
        scaffoldKey: _scaffoldKey,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DETAILS DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ProductDetailsDialog extends StatefulWidget {
  final MarketplaceProduct product;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _ProductDetailsDialog({
    required this.product,
    required this.scaffoldKey,
  });

  @override
  State<_ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<_ProductDetailsDialog> {
  int _qty = 1;

  @override
  void initState() {
    super.initState();
  }

  MarketplaceProduct get p => widget.product;
  bool get inStock => p.stock > 0;
  int get discount => p.salePrice < p.price
      ? (((p.price - p.salePrice) / p.price) * 100).round()
      : 0;
  int get total => p.salePrice * _qty;

  void _changeQty(int delta) {
    setState(() => _qty = (_qty + delta).clamp(1, p.stock));
  }

  Future<void> _addToCart() async {
    try {
      await cartManager.addToCart(p, quantity: _qty);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${p.productName} added to cart'),
            duration: const Duration(seconds: 1),
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () => widget.scaffoldKey.currentState?.openEndDrawer(),
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add to cart')),
        );
      }
    }
  }

  Future<void> _buyNow() async {
    try {
      await cartManager.addToCart(p, quantity: _qty);
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => _QuickCheckoutDialog(product: p, quantity: _qty),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to proceed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image Area ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: p.productImages.isNotEmpty
                        ? Image.network(p.productImages[0],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const _NoImage())
                        : const _NoImage(),
                  ),
                ),
                // Close
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.black87),
                    ),
                  ),
                ),
                // Stock badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: inStock ? _kSuccess : _kDanger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('${p.stock} in stock',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                // Save badge
                if (discount > 0)
                  Positioned(
                    top: 12,
                    right: 52,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          'Save ₹${(p.price - p.salePrice).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(p.productName,
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E))),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${p.salePrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          if (p.salePrice < p.price)
                            Text('₹${p.price.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _kMuted,
                                    decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${p.stock} units available',
                      style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
                  const SizedBox(height: 12),
                  // Supplier row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _kBorder),
                        top: BorderSide(color: _kBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_outlined,
                              size: 16, color: _kPrimary),
                        ),
                        const SizedBox(width: 10),
                        Text(p.supplierName,
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category + Rating
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: _kMuted)),
                            const SizedBox(height: 3),
                            Text(p.category.isNotEmpty ? p.category : '—',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rating',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: _kMuted)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => const Icon(Icons.star_rounded,
                                      color: _kAccent, size: 15),
                                ),
                                const SizedBox(width: 4),
                                Text('4.5',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Qty row
                  Row(
                    children: [
                      Text('Quantity',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      // Total
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: _kMuted)),
                          Text('₹${total.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _kBorder, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove, () => _changeQty(-1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('$_qty',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                            ),
                            _qtyBtn(Icons.add, () => _changeQty(1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: inStock ? _addToCart : null,
                          icon:
                              const Icon(Icons.shopping_bag_outlined, size: 16),
                          label: Text(inStock ? 'Add to Cart' : 'Out of Stock',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: inStock ? _kPrimary : _kMuted,
                            side: BorderSide(
                                color: inStock ? _kPrimary : _kMuted,
                                width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: inStock ? _buyNow : null,
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: Text('Buy Now',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                inStock ? _kPrimary : Colors.grey[300],
                            foregroundColor:
                                inStock ? Colors.white : Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) => InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 17, color: const Color(0xFF1A1A2E)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK CHECKOUT DIALOG  (matches screenshot 3)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickCheckoutDialog extends StatefulWidget {
  final MarketplaceProduct product;
  final int quantity;
  const _QuickCheckoutDialog({required this.product, required this.quantity});

  @override
  State<_QuickCheckoutDialog> createState() => _QuickCheckoutDialogState();
}

class _QuickCheckoutDialogState extends State<_QuickCheckoutDialog> {
  // Address controllers
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _flatCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  bool _defaultAddr = false;
  bool _addressSaved = false;
  bool _isSubmitting = false;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _qty = widget.quantity;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _mobileCtrl,
      _pinCtrl,
      _flatCtrl,
      _streetCtrl,
      _cityCtrl,
      _stateCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  MarketplaceProduct get p => widget.product;
  int get subtotal => p.salePrice * _qty;
  String get fullAddress =>
      '${_flatCtrl.text}, ${_streetCtrl.text}, ${_cityCtrl.text}, ${_stateCtrl.text} - ${_pinCtrl.text}';

  void _saveAddress() {
    if (_nameCtrl.text.trim().isEmpty ||
        _mobileCtrl.text.trim().isEmpty ||
        _pinCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in name, mobile, and 6-digit PIN')),
      );
      return;
    }
    setState(() => _addressSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Address saved!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _placeOrder() async {
    if (!_addressSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save your address first')),
      );
      return;
    }
    if (cartManager.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final items = cartManager.items
          .map((item) => {
                "productId": item.product.id,
                "productName": item.product.productName,
                "quantity": item.quantity,
                "price": item.product.salePrice,
              })
          .toList();

      final orderData = {
        "supplierId": cartManager.items.first.product.vendorId,
        "items": items,
        "totalAmount": cartManager.totalAmount,
        "shippingAddress": fullAddress,
      };

      final response = await ApiService.createOrder(orderData);

      if (mounted) {
        Navigator.pop(context);
        cartManager.clearCart();
        _showSuccess(context, response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to place order: $e'),
              backgroundColor: _kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccess(BuildContext ctx, dynamic response) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.check_circle_rounded, color: _kSuccess),
          const SizedBox(width: 10),
          Text('Order Placed!',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Order ID: ${(response['data']?['orderId'] ?? response['orderId']) ?? 'N/A'}',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
                'Your order has been sent to the supplier. You will be notified once confirmed.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('GREAT!',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Checkout',
                            style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        Text('Complete your purchase securely',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _kMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _kMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Content: side-by-side on wide, stacked on narrow ──
            isWide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildLeftPanel()),
                        Container(width: 1, color: _kBorder),
                        Expanded(child: _buildRightPanel()),
                      ],
                    ),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLeftPanel(),
                          Container(height: 1, color: _kBorder),
                          _buildRightPanel(),
                        ],
                      ),
                    ),
                  ),
            // ── Footer ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (_addressSaved && !_isSubmitting)
                          ? _placeOrder
                          : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: Text('Place Order',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _addressSaved ? _kPrimary : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Left: Shipping form ──────────────────────────────────────────────────
  Widget _buildLeftPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
              Icons.location_on_outlined, 'Shipping & Contact Details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Address',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field('FULL NAME', _nameCtrl, '')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field('MOBILE NO', _mobileCtrl, '',
                          type: TextInputType.phone)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _field('PINCODE', _pinCtrl, '6-digit PIN',
                          maxLen: 6, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('FLAT/HOUSE NO', _flatCtrl, '')),
                ]),
                const SizedBox(height: 10),
                _field('AREA/STREET', _streetCtrl, ''),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field('CITY', _cityCtrl, '')),
                  const SizedBox(width: 10),
                  Expanded(child: _field('STATE', _stateCtrl, '')),
                ]),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _defaultAddr = !_defaultAddr),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _defaultAddr,
                          onChanged: (v) =>
                              setState(() => _defaultAddr = v ?? false),
                          activeColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Default address',
                          style:
                              GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text('Save and Use This Address',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Right: Order summary ─────────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Product preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: p.productImages.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(p.productImages[0],
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFFC4B5F0))),
                        )
                      : const Icon(Icons.inventory_2_outlined,
                          color: Color(0xFFC4B5F0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.productName,
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(p.supplierName,
                          style:
                              GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${p.salePrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    if (p.salePrice < p.price)
                      Text('₹${p.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _kMuted,
                              decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Qty row
          Row(
            children: [
              Text('Quantity',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Subtotal',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
                  Text('₹${subtotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _miniQtyBtn(
                        Icons.remove,
                        () => setState(
                            () => _qty = (_qty - 1).clamp(1, p.stock))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_qty',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    _miniQtyBtn(
                        Icons.add,
                        () => setState(
                            () => _qty = (_qty + 1).clamp(1, p.stock))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: _kMuted),
              const SizedBox(width: 4),
              Text('${p.stock} items available',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
            ],
          ),
          const SizedBox(height: 12),
          // Delivery
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    color: _kPrimary, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fast & Reliable Delivery',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    Text('Estimated: 3-5 business days',
                        style:
                            GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Order summary box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 15, color: _kPrimary),
                    const SizedBox(width: 6),
                    Text('Order Summary',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                _summaryRow('Item ($_qty)', '₹${subtotal.toStringAsFixed(0)}',
                    muted: true),
                const SizedBox(height: 4),
                _summaryRow('Shipping Fee', 'FREE', green: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: _kBorder),
                ),
                _summaryRow('Total Amount', '₹${subtotal.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: _kPrimary),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    int? maxLen,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kMuted,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: type,
            maxLength: maxLen,
            style: GoogleFonts.dmSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[400]),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
        ],
      );

  Widget _summaryRow(String label, String value,
          {bool muted = false, bool green = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: muted ? _kMuted : const Color(0xFF1A1A2E),
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w800)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: muted ? 13 : 15,
                  color: green
                      ? _kSuccess
                      : muted
                          ? _kMuted
                          : const Color(0xFF1A1A2E),
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w800)),
        ],
      );

  Widget _miniQtyBtn(IconData icon, VoidCallback onPressed) => InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: const Color(0xFF1A1A2E)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CART SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _CartSidebar extends StatelessWidget {
  const _CartSidebar();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      child: ListenableBuilder(
        listenable: cartManager,
        builder: (context, _) {
          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: _kPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your Cart (${cartManager.itemCount} items)',
                          style: GoogleFonts.poppins(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                // Items
                if (cartManager.isLoading)
                  const Expanded(
                      child: Center(
                          child: CircularProgressIndicator(color: _kPrimary)))
                else if (cartManager.items.isEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 14),
                        Text('Your cart is empty',
                            style: GoogleFonts.dmSans(color: _kMuted)),
                      ],
                    ),
                  )
                else ...[
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: cartManager.items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: _kBorder),
                      itemBuilder: (context, i) {
                        final item = cartManager.items[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _kBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: item.product.productImages.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                            item.product.productImages[0],
                                            fit: BoxFit.cover))
                                    : const Icon(Icons.inventory_2_outlined,
                                        color: Color(0xFFC4B5F0)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.productName,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text(
                                        '₹${item.product.salePrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: _kPrimary,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              // Qty controls
                              Row(
                                children: [
                                  _cqBtn(Icons.remove, () async {
                                    try {
                                      await cartManager.updateQuantity(
                                          item.product.id, item.quantity - 1);
                                    } catch (_) {}
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${item.quantity}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13)),
                                  ),
                                  _cqBtn(
                                      Icons.add,
                                      item.product.stock > item.quantity
                                          ? () async {
                                              try {
                                                await cartManager
                                                    .updateQuantity(
                                                        item.product.id,
                                                        item.quantity + 1);
                                              } catch (_) {}
                                            }
                                          : () {}),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () async {
                                      try {
                                        await cartManager
                                            .removeFromCart(item.product.id);
                                      } catch (_) {}
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline_rounded,
                                          color: _kDanger, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, -4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount',
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(
                                '₹${cartManager.totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _kPrimary)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCheckout(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text('PROCEED TO CHECKOUT',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cqBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(6),
            color: _kBg,
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF1A1A2E)),
        ),
      );

  void _showCheckout(BuildContext context) {
    if (cartManager.items.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => _QuickCheckoutDialog(
        product: cartManager.items.first.product,
        quantity: cartManager.items.first.quantity,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _NoImage extends StatelessWidget {
  const _NoImage();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF0EEFA),
        child: const Center(
          child: Icon(Icons.inventory_2_outlined,
              size: 60, color: Color(0xFFC4B5F0)),
        ),
      );
}
