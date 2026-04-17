import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'supp_drawer.dart';
import '../services/api_service.dart';
import '../widgets/subscription_wrapper.dart';

class SuppOffersCouponsPage extends StatefulWidget {
  const SuppOffersCouponsPage({super.key});

  @override
  State<SuppOffersCouponsPage> createState() => _SuppOffersCouponsPageState();
}

class _SuppOffersCouponsPageState extends State<SuppOffersCouponsPage> {
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  bool _isLoading = true;
  List<Map<String, dynamic>> coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  bool _robustBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final List<OfferModel> apiOffers = await ApiService.getOffers();

      setState(() {
        coupons = apiOffers.map((o) {
          return {
            'id': o.id,
            'code': o.code ?? 'N/A',
            'discountType':
                o.type == 'percentage' ? 'Percentage' : 'Fixed Amount',
            'discountValue': o.value ?? 0,
            'status': o.status ?? 'Inactive',
            'startsOn': o.startDate ?? DateTime.now(),
            'expiresOn': o.expires ?? DateTime.now(),
            'image': o.offerImage,
            'redeemed': o.redeemed ?? 0,
            'isCustomCode': _robustBool(o.isCustomCode ?? false),
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
      if (c['discountType'] == 'Fixed Amount') {
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
          onSubmit: _addCoupon,
        );
      },
    );
  }

  // Add new coupon to the list
  Future<void> _addCoupon(Map<String, dynamic> couponData) async {
    setState(() => _isLoading = true);
    try {
      String? imageBase64;
      final images = couponData['image'] as List?;
      if (images != null && images.isNotEmpty) {
        final filePath = images[0] as String;
        if (filePath.startsWith('/') || filePath.contains('data/user')) {
          // Local file, convert to base64
          final bytes = await File(filePath).readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = filePath.split('.').last.toLowerCase();
          final mimeType = (extension == 'png') ? 'png' : 'jpeg';
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
        "minOrderAmount": couponData['minOrderAmount'] ?? 0,
        "offerImage": imageBase64,
        "isCustomCode": couponData['isCustomCode'] ?? false,
        if (couponData['code'] != null &&
            (couponData['code'] as String).isNotEmpty)
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
        "id": id,
        "type": (updatedCoupon['discountType'] == 'Fixed Amount')
            ? 'fixed'
            : (updatedCoupon['discountType'] as String).toLowerCase(),
        "value": updatedCoupon['discountValue'],
        "startDate":
            (updatedCoupon['startsOn'] as DateTime).toUtc().toIso8601String(),
        "expires":
            (updatedCoupon['expiresOn'] as DateTime).toUtc().toIso8601String(),
        "minOrderAmount": updatedCoupon['minOrderAmount'] ?? 0,
        "offerImage": imageBase64,
        "isCustomCode": updatedCoupon['isCustomCode'] ?? false,
        if (updatedCoupon['code'] != null &&
            (updatedCoupon['code'] as String).isNotEmpty)
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
                  _detailRow('Min Order Amount', '₹${c['minOrderAmount']}'),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Offers and Coupons'),
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
      body: SubscriptionWrapper(
        child: SafeArea(
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
                          childAspectRatio: isMobile ? 1.8 : 1.6,
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
                      'Min Order: ₹${c['minOrderAmount']}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                      ),
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
  final Map<String, dynamic>? initialCoupon;
  final Function(Map<String, dynamic>) onSubmit;

  const CouponDialog({
    super.key,
    required this.mode,
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
  late final TextEditingController _minOrderController;

  late bool _useCustomCode;
  late String _discountType;
  late DateTime _startDate;
  late DateTime _endDate;
  List<String>? _selectedImages = [];

  final List<String> _discountTypes = ['Percentage', 'Fixed Amount'];

  bool get _isEdit => widget.mode == CouponDialogMode.edit;

  bool _robustBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    final c = widget.initialCoupon;

    _couponCodeController =
        TextEditingController(text: c != null ? c['code'] as String : '');
    _discountValueController = TextEditingController(
      text: c != null ? (c['discountValue'] as num).toString() : '',
    );
    _minOrderController = TextEditingController(
      text: c != null ? (c['minOrderAmount'] as num).toString() : '',
    );

    _useCustomCode = c != null ? _robustBool(c['isCustomCode']) : false;
    _discountType = c != null ? c['discountType'] as String : 'Percentage';
    _startDate = c != null ? c['startsOn'] as DateTime : DateTime.now();
    _endDate = c != null
        ? c['expiresOn'] as DateTime
        : DateTime.now().add(const Duration(days: 30));

    // Handle image initialization
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
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    super.dispose();
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
        'redeemed': _isEdit ? (base['redeemed'] ?? 0) : 0,
        // Only include code if it's custom
        if (_useCustomCode) 'code': _couponCodeController.text.trim(),
        'discountType': _discountType,
        'discountValue':
            double.tryParse(_discountValueController.text.trim()) ?? 0.0,
        'minOrderAmount':
            double.tryParse(_minOrderController.text.trim()) ?? 0.0,
        'status': _startDate.isAfter(DateTime.now()) ? 'Scheduled' : 'Active',
        'startsOn': _startDate,
        'expiresOn': _endDate,
        'image': _selectedImages,
        'isCustomCode': _useCustomCode,
      };
      widget.onSubmit(couponData);
      Navigator.of(context).pop();
    }
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
              maxWidth: 500,
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
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
                  Flexible(
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
                                decoration: _inputDecoration('Enter code here'),
                                style: GoogleFonts.poppins(fontSize: 11),
                                validator: (value) {
                                  if (_useCustomCode &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter a coupon code';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        size: 14, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Coupon code will be automatically generated.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                            _sectionLabel('Minimum Order Amount'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _minOrderController,
                              decoration: _inputDecoration('0').copyWith(
                                prefixText: '₹ ',
                                prefixStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151)),
                              ),
                              style: GoogleFonts.poppins(fontSize: 11),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter minimum order amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel('Offer Image (Optional)'),
                            const SizedBox(height: 8),
                            _imageUploadSection(),
                            const SizedBox(height: 16),
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

  Widget _imageUploadSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
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
                  child: _buildDialogImage(_selectedImages![0]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _dialogErrorImage());
    } else if (path.startsWith('data:image')) {
      try {
        final base64Data = path.split(',').last;
        return Image.memory(base64Decode(base64Data),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _dialogErrorImage());
      } catch (e) {
        return _dialogErrorImage();
      }
    } else {
      return Image.file(File(path),
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _dialogErrorImage());
    }
  }

  Widget _dialogErrorImage() {
    return Container(
      color: Colors.grey.shade100,
      child:
          const Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
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
