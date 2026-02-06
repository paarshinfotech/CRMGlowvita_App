import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';

class OffersCouponsPage extends StatefulWidget {
  const OffersCouponsPage({super.key});

  @override
  State<OffersCouponsPage> createState() => _OffersCouponsPageState();
}

class _OffersCouponsPageState extends State<OffersCouponsPage> {
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  bool _isLoading = true;
  List<Map<String, dynamic>> coupons = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getOffers(),
        ApiService.getServices(),
        ApiService.getCategories(),
      ]);

      final List<OfferModel> apiOffers = results[0] as List<OfferModel>;
      final List<Service> apiServices = results[1] as List<Service>;
      final List<Map<String, dynamic>> apiCategories =
          results[2] as List<Map<String, dynamic>>;

      setState(() {
        categories = apiCategories;
        services = apiServices
            .where((s) => s.status == 'approved')
            .map((s) => {
                  'id': s.id,
                  'name': s.name ?? 'Unnamed Service',
                  'category': s.category ?? 'Uncategorized',
                  'categoryId': s.categoryId,
                  'price': (s.price ?? 0).toDouble(),
                  'discounted_price': (s.discountedPrice ?? 0).toDouble(),
                  'is_active': s.status == 'approved',
                  'home_service': s.homeService ?? false,
                  'event_service': s.eventService ?? false,
                })
            .toList();

        coupons = apiOffers.map((o) {
          // Map service IDs to names for display
          String servicesDisplay = 'All Services';
          if (o.applicableServices != null &&
              o.applicableServices!.isNotEmpty) {
            final names = o.applicableServices!.map((id) {
              final svc = apiServices.firstWhere((s) => s.id == id,
                  orElse: () => Service(id: id));
              return svc.name ?? id;
            }).toList();
            servicesDisplay = names.join(', ');
          }

          return {
            'id': o.id,
            'code': o.code ?? 'N/A',
            'discountType':
                o.type == 'percentage' ? 'Percentage' : 'Fixed Amount',
            'discountValue': o.value ?? 0,
            'status': o.status ?? 'Inactive',
            'startsOn': o.startDate ?? DateTime.now(),
            'expiresOn': o.expires ?? DateTime.now(),
            'services': servicesDisplay,
            'categories': (o.applicableServiceCategories != null &&
                    o.applicableServiceCategories!.isNotEmpty)
                ? o.applicableServiceCategories!
                    .join(', ') // These are IDs but displayed as is for now
                : 'All',
            'genders': (o.applicableCategories != null &&
                    o.applicableCategories!.isNotEmpty)
                ? o.applicableCategories!.join(', ')
                : 'All',
            'image': o.offerImage,
            'redeemed': o.redeemed ?? 0,
            'isCustomCode': o.isCustomCode ?? false,
            'minOrderAmount': o.minOrderAmount ?? 0,
            'api_data': o.toJson(), // Store original data for edit/view
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  int get totalCoupons => coupons.length;
  int get activeCoupons => coupons.where((c) => c['status'] == 'Active').length;
  int get totalRedeemed =>
      coupons.fold<int>(0, (sum, c) => sum + (c['redeemed'] as int));

  double get totalDiscountValue {
    double total = 0;
    for (final c in coupons) {
      final redeemed = c['redeemed'] as int;
      final val = (c['discountValue'] as num).toDouble();
      if (c['discountType'] == 'Flat') {
        total += val * redeemed;
      } else {
        total += 500 * (val / 100) * redeemed; // assume avg bill 500
      }
    }
    return total;
  }

  // Show popup form to create coupon
  void _showCreateCouponForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CouponDialog(
          mode: CouponDialogMode.create,
          services: services,
          categories: categories,
          onSubmit: _addCoupon,
        );
      },
    );
  }

  // Add new coupon to the list
  Future<void> _addCoupon(Map<String, dynamic> couponData) async {
    setState(() => _isLoading = true);
    try {
      // Prepare payload for API
      final Map<String, dynamic> apiData =
          couponData['api_data'] as Map<String, dynamic>? ?? {};

      String? imageBase64;
      final images = couponData['image'] as List?;
      if (images != null && images.isNotEmpty) {
        final filePath = images[0] as String;
        if (filePath.startsWith('/')) {
          // Local file, convert to base64
          final bytes = await File(filePath).readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = filePath.split('.').last.toLowerCase();
          final mimeType = extension == 'png' ? 'png' : 'jpeg';
          imageBase64 = 'data:image/$mimeType;base64,$base64String';
        } else {
          // Already base64 or URL
          imageBase64 = filePath;
        }
      }

      final payload = {
        "type": (couponData['discountType'] == 'Fixed Amount')
            ? 'fixed'
            : (couponData['discountType'] as String).toLowerCase(),
        "value": couponData['discountValue'],
        "startDate":
            (couponData['startsOn'] as DateTime).toUtc().toIso8601String(),
        "expires":
            (couponData['expiresOn'] as DateTime).toUtc().toIso8601String(),
        "applicableServices": apiData['applicableServices'] ?? [],
        "applicableServiceCategories":
            apiData['applicableServiceCategories'] ?? [],
        "applicableCategories": apiData['applicableCategories'] ?? [],
        "minOrderAmount": couponData['minOrderAmount'] ?? 0,
        "offerImage": imageBase64,
        "status": couponData['status'],
        "isCustomCode": couponData['isCustomCode'] ?? false,
        "code": couponData['code'],
      };

      final response = await ApiService.createOffer(payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - Refresh Data
        await _fetchData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer created successfully')),
        );
      } else {
        throw Exception('Failed to create offer: ${response.body}');
      }
    } catch (e) {
      print('Error adding coupon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding coupon: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editCoupon(int index) {
    final couponToEdit = coupons[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CouponDialog(
          mode: CouponDialogMode.edit,
          services: services,
          categories: categories,
          initialCoupon: couponToEdit,
          onSubmit: (updated) => _updateCoupon(index, updated),
        );
      },
    );
  }

  Future<void> _updateCoupon(
      int index, Map<String, dynamic> updatedCoupon) async {
    final String? id = coupons[index]['id'];
    if (id == null) return;

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> apiData =
          updatedCoupon['api_data'] as Map<String, dynamic>? ?? {};

      String? imageBase64;
      final images = updatedCoupon['image'] as List?;
      if (images != null && images.isNotEmpty) {
        final filePath = images[0] as String;
        if (filePath.startsWith('/') || filePath.contains('data/user')) {
          final bytes = await File(filePath).readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = filePath.split('.').last.toLowerCase();
          final mimeType =
              (extension == 'png' || extension == 'jpg' || extension == 'jpeg')
                  ? extension
                  : 'jpeg';
          imageBase64 = 'data:image/$mimeType;base64,$base64String';
        } else {
          imageBase64 = filePath;
        }
      }

      final payload = {
        "type": (updatedCoupon['discountType'] == 'Fixed Amount')
            ? 'fixed'
            : (updatedCoupon['discountType'] as String).toLowerCase(),
        "value": updatedCoupon['discountValue'],
        "startDate":
            (updatedCoupon['startsOn'] as DateTime).toUtc().toIso8601String(),
        "expires":
            (updatedCoupon['expiresOn'] as DateTime).toUtc().toIso8601String(),
        "applicableServices": apiData['applicableServices'] ?? [],
        "applicableServiceCategories":
            apiData['applicableServiceCategories'] ?? [],
        "applicableCategories": apiData['applicableCategories'] ?? [],
        "minOrderAmount": updatedCoupon['minOrderAmount'] ?? 0,
        "offerImage": imageBase64,
        "status": updatedCoupon['status'],
        "isCustomCode": updatedCoupon['isCustomCode'] ?? false,
        "code": updatedCoupon['code'],
      };

      final response = await ApiService.updateOffer(id, payload);

      if (response.statusCode == 200) {
        await _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer updated successfully')),
        );
      } else {
        throw Exception('Failed to update offer: ${response.body}');
      }
    } catch (e) {
      print('Error updating coupon: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating coupon: $e')),
      );
    }
  }

  Map<String, dynamic> _mapApiOfferToUi(Map<String, dynamic> raw) {
    final apiData = raw['api_data'] as Map<String, dynamic>? ?? {};

    // Services Display
    String servicesDisplay = 'All Services';
    final appServices = apiData['applicableServices'] as List?;
    if (appServices != null && appServices.isNotEmpty) {
      final names = appServices.map((id) {
        final svc = services.firstWhere((s) => s['id'] == id,
            orElse: () => {'name': id});
        return svc['name'] ?? id;
      }).toList();
      servicesDisplay = names.join(', ');
    }

    // Categories Display
    String categoriesDisplay = 'All';
    final appCategories = apiData['applicableServiceCategories'] as List?;
    if (appCategories != null && appCategories.isNotEmpty) {
      final names = appCategories.map((id) {
        // Find category name from services
        final svc =
            services.firstWhere((s) => s['categoryId'] == id, orElse: () => {});
        return svc['category'] ?? id;
      }).toList();
      categoriesDisplay = names.join(', ');
    }

    return {
      ...raw,
      'services': servicesDisplay,
      'categories': categoriesDisplay,
      'image': raw['image'] ?? raw['offerImage'], // Map offerImage to image
      'discountType': raw['discountType'] ??
          (raw['type'] == 'percentage' ? 'Percentage' : 'Fixed Amount'),
      'discountValue': raw['discountValue'] ?? raw['value'] ?? 0,
      'startsOn': raw['startsOn'] ??
          (raw['startDate'] != null
              ? DateTime.parse(raw['startDate'])
              : DateTime.now()),
      'expiresOn': raw['expiresOn'] ??
          (raw['expires'] != null
              ? DateTime.parse(raw['expires'])
              : DateTime.now()),
      'isCustomCode': raw['isCustomCode'] ?? false,
      'minOrderAmount': raw['minOrderAmount'] ?? 0,
    };
  }

  Widget _buildImageWidgetFromData(dynamic imageData) {
    if (imageData == null || (imageData is String && imageData.isEmpty)) {
      return Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
      );
    }

    if (imageData is String) {
      if (imageData.startsWith('data:image')) {
        // Base64 image
        try {
          final base64Data = imageData.split(',').last;
          return Image.memory(
            base64Decode(base64Data),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _errorImage(),
          );
        } catch (e) {
          return _errorImage();
        }
      } else if (imageData.startsWith('http')) {
        // URL image
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorImage(),
        );
      } else if (imageData.startsWith('/')) {
        // Local file path
        return Image.file(
          File(imageData),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorImage(),
        );
      }
    }

    return _errorImage();
  }

  Widget _errorImage() {
    return Container(
      color: Colors.grey.shade100,
      child:
          const Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
    );
  }

  void _showCouponDetails(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coupon Details',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Viewing details for this coupon.',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.cancel_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailRow('Code', c['code'] as String),
                  _detailRow(
                      'Code Type',
                      c['isCustomCode'] == true
                          ? '● Custom Code'
                          : '● Auto-gen Code'),
                  _detailRow(
                      'Discount',
                      c['discountType'] == 'Fixed Amount'
                          ? '₹${c['discountValue']} Off'
                          : '${c['discountValue']}% Off'),
                  _detailRow('Status', c['status'] as String),
                  _detailRow(
                      'Starts',
                      DateFormat('yyyy-MM-dd')
                          .format(c['startsOn'] as DateTime)),
                  _detailRow(
                      'Expires',
                      DateFormat('yyyy-MM-dd')
                          .format(c['expiresOn'] as DateTime)),
                  _detailRow('Services', c['services'] as String),
                  _detailRow('Service Categories', c['categories'] as String),
                  _detailRow('Applicable Genders', c['genders'] as String),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Image',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: _buildImageWidgetFromData(c['image']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Redeemed', (c['redeemed'] as int).toString()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteCoupon(int index) {
    final coupon = coupons[index];
    final String? id = coupon['id'];

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Coupon ID is missing')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text('Delete Coupon', style: GoogleFonts.poppins(fontSize: 14)),
          content: Text(
            'Are you sure you want to delete this coupon? This action cannot be undone.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final success = await ApiService.deleteOffer(id);
                  if (success) {
                    await _fetchData();
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Coupon deleted successfully')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete coupon: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(fontSize: 12),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageWidget(String imagePath) {
    // Check if it's a local file path (starts with file:// or is a direct path)
    if (imagePath.startsWith('file://') ||
        imagePath.startsWith('/') ||
        imagePath.contains('data/user')) {
      // It's a local file, use Image.file
      try {
        return Image.file(
          File(imagePath),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // If there's an error loading the file, fall back to a placeholder
        return Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 50,
          ),
        );
      }
    } else {
      // It's a network URL, use Image.network
      return Image.network(
        imagePath,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 50,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Offers & Coupons'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Offers & Coupons',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat cards
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.local_offer,
                                    color: Theme.of(context).primaryColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Coupons',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$totalCoupons',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Coupons',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$activeCoupons',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.redeem,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Redeemed',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$totalRedeemed',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.discount,
                                    color: Colors.purple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Discount',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currency.format(totalDiscountValue),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Coupons',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create, edit, and manage your promotional coupons.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showCreateCouponForm,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Create New Coupon',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 1.6 : 1.5,
                        ),
                        itemCount: coupons.length,
                        itemBuilder: (context, index) {
                          return _buildCouponCard(coupons[index], index);
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> c, int index) {
    Color statusColor;
    switch (c['status']) {
      case 'Active':
        statusColor = const Color(0xFF059669);
        break;
      case 'Scheduled':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'Expired':
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusColor = Colors.grey.shade600;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showCouponDetails(c),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section with Image and Status
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildImageWidgetFromData(c['image']),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        c['status'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Section with Details
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c['code'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          c['discountType'] == 'Fixed Amount'
                              ? '₹${c['discountValue']}'
                              : '${c['discountValue']}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c['services'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Redeemed: ${c['redeemed']}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            Text(
                              'Expires: ${DateFormat('dd MMM yyyy').format(c['expiresOn'] as DateTime)}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _actionIcon(
                              Icons.edit_outlined,
                              const Color(0xFF6B7280),
                              () => _editCoupon(index),
                            ),
                            const SizedBox(width: 8),
                            _actionIcon(
                              Icons.delete_outline,
                              const Color(0xFFEF4444),
                              () => _deleteCoupon(index),
                            ),
                          ],
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

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ---------- add/edit coupon dialog ----------

enum CouponDialogMode { create, edit }

class CouponDialog extends StatefulWidget {
  final CouponDialogMode mode;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? initialCoupon;
  final Function(Map<String, dynamic>) onSubmit;

  const CouponDialog({
    super.key,
    required this.mode,
    required this.services,
    required this.categories,
    required this.onSubmit,
    this.initialCoupon,
  });

  @override
  State<CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<CouponDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _couponCodeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _minOrderAmountController;

  late bool _useCustomCode;
  late String _discountType;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _selectedServices;
  late List<String> _selectedCategories;
  late String _selectedGender;
  List<String>? _selectedImages = [];

  final List<String> _discountTypes = ['Percentage', 'Fixed Amount'];
  final List<String> _genders = ['Men', 'Women', 'Unisex'];

  bool get _isEdit => widget.mode == CouponDialogMode.edit;

  @override
  void initState() {
    super.initState();

    final c = widget.initialCoupon;

    _couponCodeController =
        TextEditingController(text: c != null ? c['code'] as String : '');
    _discountValueController = TextEditingController(
      text: c != null ? (c['discountValue'] as num).toString() : '',
    );
    _minOrderAmountController = TextEditingController(
      text: c != null && c['minOrderAmount'] != null
          ? (c['minOrderAmount'] as num).toString()
          : '',
    );

    _useCustomCode = true;
    _discountType = c != null ? c['discountType'] as String : 'Percentage';
    _startDate = c != null ? c['startsOn'] as DateTime : DateTime.now();
    _endDate = c != null
        ? c['expiresOn'] as DateTime
        : DateTime.now().add(const Duration(days: 30));
    _selectedGender = c != null ? c['genders'] as String : 'Unisex';

    // Handle image initialization for multiple images
    if (c != null && c['image'] != null) {
      final imageValue = c['image'];
      if (imageValue is String) {
        _selectedImages = [imageValue];
      } else if (imageValue is List) {
        _selectedImages = List<String>.from(imageValue);
      } else {
        _selectedImages = [];
      }
    } else {
      _selectedImages = [];
    }

    // Services & Categories Selection
    if (c != null && c['api_data'] != null) {
      final apiData = c['api_data'] as Map<String, dynamic>;

      // Services
      final appServices = apiData['applicableServices'] as List?;
      if (appServices != null && appServices.isNotEmpty) {
        _selectedServices = List<String>.from(appServices);
      } else {
        _selectedServices = [];
      }

      // Categories
      final appCategories = apiData['applicableServiceCategories'] as List?;
      if (appCategories != null && appCategories.isNotEmpty) {
        _selectedCategories = List<String>.from(appCategories);
      } else {
        _selectedCategories = [];
      }
    } else {
      _selectedServices = [];
      _selectedCategories = [];
    }
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    _discountValueController.dispose();
    _minOrderAmountController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _availableCategories {
    return widget.categories.map((cat) {
      return {
        'id': (cat['_id'] ?? cat['id'] ?? '').toString(),
        'name': (cat['name'] ?? 'Unknown').toString(),
      };
    }).toList();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleServiceSelection(String serviceId) {
    setState(() {
      if (_selectedServices.contains(serviceId)) {
        _selectedServices.remove(serviceId);
      } else {
        _selectedServices.add(serviceId);
      }
      _updateCategoriesBasedOnServices();
    });
  }

  void _toggleCategorySelection(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  void _updateCategoriesBasedOnServices() {
    final categories = <String>{};
    for (var service in widget.services) {
      if (_selectedServices.contains(service['id'])) {
        final catId = service['categoryId'] as String?;
        if (catId != null) {
          categories.add(catId);
        }
      }
    }
    _selectedCategories = categories.toList();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => image.path).toList();
      });
    }
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final base = widget.initialCoupon ?? {};

      final couponData = {
        // preserve redeemed on edit
        'redeemed': _isEdit ? (base['redeemed'] ?? 0) : 0,
        'code': _useCustomCode
            ? _couponCodeController.text.trim()
            : _generateUniqueCode(),
        'discountType': _discountType,
        'discountValue':
            double.tryParse(_discountValueController.text.trim()) ?? 0.0,
        'status': _startDate.isAfter(DateTime.now()) ? 'Scheduled' : 'Active',
        'startsOn': _startDate,
        'expiresOn': _endDate,
        'genders': _selectedGender,
        'image': _selectedImages,
        'isCustomCode': _useCustomCode,
        'minOrderAmount':
            double.tryParse(_minOrderAmountController.text.trim()) ?? 0.0,
        'api_data': {
          'applicableServices': _selectedServices,
          'applicableServiceCategories': _selectedCategories,
          'applicableCategories': _selectedGender == 'Unisex'
              ? ['Men', 'Women', 'Unisex']
              : [_selectedGender],
        }
      };

      widget.onSubmit(couponData);
      Navigator.of(context).pop();
    }
  }

  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  InputDecoration _underlineInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF9CA3AF),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 1.3),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _helperText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _chipDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF111827),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<T>(
                value: e,
                child: Text(e.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _infoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 9),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final title = _isEdit ? 'Edit Coupon' : 'Create New Coupon';
    final subtitle = _isEdit
        ? 'Update the details for this coupon.'
        : 'Enter the details for the new coupon.';
    final primaryLabel = _isEdit ? 'Save Changes' : 'Create Coupon';

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = MediaQuery.of(context).size.height * 0.9;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: maxHeight,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _useCustomCode,
                                    onChanged: (value) {
                                      setState(() {
                                        _useCustomCode = value ?? false;
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Use custom coupon code',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                            if (_useCustomCode) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _couponCodeController,
                                decoration: _inputDecoration(''),
                                style: GoogleFonts.poppins(fontSize: 11),
                                validator: (value) {
                                  if (_useCustomCode &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter a coupon code';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            _sectionLabel('Discount Type'),
                            const SizedBox(height: 6),
                            _customDropdown<String>(
                              value: _discountType,
                              items: _discountTypes,
                              onChanged: (value) {
                                setState(() {
                                  _discountType = value ?? 'Percentage';
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel('Discount Value'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _discountValueController,
                              decoration: _inputDecoration('0').copyWith(
                                prefixText: _discountType == 'Fixed Amount'
                                    ? '₹ '
                                    : null,
                                suffixText:
                                    _discountType == 'Percentage' ? ' %' : null,
                                prefixStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151)),
                                suffixStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151)),
                              ),
                              style: GoogleFonts.poppins(fontSize: 11),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a discount value';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel('Min Order Amount'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _minOrderAmountController,
                              decoration: _inputDecoration('0').copyWith(
                                prefixText: '₹ ',
                                prefixStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151)),
                              ),
                              style: GoogleFonts.poppins(fontSize: 11),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionLabel('Starts On'),
                                      const SizedBox(height: 6),
                                      _datePickerField(
                                          dateFormat.format(_startDate),
                                          _selectStartDate),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionLabel('Expires On'),
                                      const SizedBox(height: 6),
                                      _datePickerField(
                                          dateFormat.format(_endDate),
                                          _selectEndDate),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel(
                                'Applicable Services (Select specific services or leave empty for all)'),
                            const SizedBox(height: 6),
                            _multiSelectContainer(
                              height: 150,
                              children: widget.services.map((service) {
                                final id = service['id'] as String;
                                final name = service['name'] as String;
                                final price = service['price'] as num;
                                final cat = service['category'] as String? ??
                                    'Uncategorized';
                                return _selectionItem(
                                  '$name - ₹$price ($cat)',
                                  _selectedServices.contains(id),
                                  () => _toggleServiceSelection(id),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel(
                                'Applicable Service Categories (Auto-selected based on services + manual selection)'),
                            const SizedBox(height: 6),
                            _multiSelectContainer(
                              height: 100,
                              grid: true,
                              children: _availableCategories.map((cat) {
                                final id = cat['id']!;
                                final name = cat['name']!;
                                return _selectionItem(
                                  name,
                                  _selectedCategories.contains(id),
                                  () => _toggleCategorySelection(id),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            _howItWorksBox(),
                            const SizedBox(height: 12),
                            _legacySettings(),
                            const SizedBox(height: 16),
                            _sectionLabel('Offer Image (Optional)'),
                            const SizedBox(height: 8),
                            _imageUploadSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          primaryLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _datePickerField(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFF374151))),
            const Icon(Icons.calendar_today,
                size: 14, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _multiSelectContainer(
      {required double height,
      required List<Widget> children,
      bool grid = false}) {
    final scrollController = ScrollController();
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: grid
            ? GridView.count(
                controller: scrollController,
                crossAxisCount: 2,
                childAspectRatio: 4,
                padding: const EdgeInsets.all(8),
                children: children,
              )
            : ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                children: children,
              ),
      ),
    );
  }

  Widget _selectionItem(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howItWorksBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works:',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 4),
          _infoBullet(
              'When you select specific services, their categories are automatically selected'),
          _infoBullet(
              'Auto-selected categories (marked with "Auto") cannot be manually deselected'),
          _infoBullet(
              'You can manually select additional categories beyond those auto-selected'),
          _infoBullet(
              'If you select both services and additional categories, the offer applies to:'),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                _infoBullet('All selected services'),
                _infoBullet('All services in auto-selected categories'),
                _infoBullet('All services in manually selected categories'),
              ],
            ),
          ),
          _infoBullet(
              'If you select neither services nor categories, the offer applies to all your services'),
        ],
      ),
    );
  }

  Widget _legacySettings() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpansionTile(
        title: Text(
          'Legacy Compatibility Settings',
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _sectionLabel('Applicable Genders'),
          const SizedBox(height: 6),
          _customDropdown<String>(
            value: _selectedGender,
            items: _genders,
            onChanged: (value) {
              setState(() {
                _selectedGender = value ?? 'Unisex';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _imageUploadSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color(0xFFE5E7EB), style: BorderStyle.none),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_outlined,
                        size: 24, color: Color(0xFF6B7280)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload Image',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImages != null && _selectedImages!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImages![0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _customDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        style:
            GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF374151)),
        items: items
            .map(
                (e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
