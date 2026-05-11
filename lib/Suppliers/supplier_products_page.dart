import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/marketplace_models.dart';
import '../cart_manager.dart';
import '../services/api_service.dart';
import '../marketplace.dart';

class SupplierProductsPage extends StatefulWidget {
  final MarketplaceSupplier supplier;
  final List<MarketplaceProduct> products;

  const SupplierProductsPage({
    super.key,
    required this.supplier,
    required this.products,
  });

  @override
  State<SupplierProductsPage> createState() => _SupplierProductsPageState();
}

class _SupplierProductsPageState extends State<SupplierProductsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showProductDetails(MarketplaceProduct product) {
    showDialog(
      context: context,
      builder: (_) => MarketProductDetailsDialog(
        product: product,
        scaffoldKey: _scaffoldKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierProducts = widget.products
        .where((p) => p.vendorId == widget.supplier.id || p.supplierEmail == widget.supplier.email)
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kMarketBg,
      endDrawer: const MarketCartSidebar(),
      appBar: AppBar(
        title: Text(
          widget.supplier.name,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Cart Icon (Matching Marketplace Style)
          ListenableBuilder(
            listenable: cartManager,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  if (cartManager.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: kMarketPrimary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${cartManager.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: supplierProducts.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              itemCount: supplierProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, supplierProducts[index]);
              },
            ),
    );
  }

  Widget _buildProductCard(BuildContext context, MarketplaceProduct product) {
    final inStock = product.stock > 0;
    
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kMarketBg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: product.productImages.isNotEmpty
                          ? Image.network(
                              product.productImages[0],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const MarketNoImage(),
                            )
                          : const MarketNoImage(),
                    ),
                  ),
                  if (!inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.6),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kMarketDanger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
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
                  Text(
                    product.category.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: kMarketPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.productName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${product.salePrice}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          if (product.price > product.salePrice)
                            Text(
                              '₹${product.price}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: kMarketMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: inStock ? () async {
                          await cartManager.addToCart(product);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.productName} added to cart'), duration: const Duration(seconds: 1)),
                            );
                          }
                        } : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kMarketPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 16,
                            color: inStock ? kMarketPrimary : kMarketMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Buy Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: inStock ? () {
                        _showProductDetails(product);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMarketPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'BUY NOW',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
