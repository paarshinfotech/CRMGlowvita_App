import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'widgets/custom_drawer.dart';

class OffersCouponsPage extends StatefulWidget {
  const OffersCouponsPage({super.key});

  @override
  State<OffersCouponsPage> createState() => _OffersCouponsPageState();
}

class _OffersCouponsPageState extends State<OffersCouponsPage> {
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  // Sample coupons data
  final List<Map<String, dynamic>> coupons = [
    {
      'code': 'WELCOME50',
      'discountType': 'Percentage',
      'discountValue': 50,
      'status': 'Active',
      'startsOn': DateTime(2025, 8, 1),
      'expiresOn': DateTime(2025, 8, 31),
      'services': 'All Services',
      'categories': 'All',
      'genders': 'All',
      'image': null,
      'redeemed': 12,
    },
    {
      'code': 'FESTIVE200',
      'discountType': 'Flat',
      'discountValue': 200,
      'status': 'Scheduled',
      'startsOn': DateTime(2025, 11, 1),
      'expiresOn': DateTime(2025, 11, 7),
      'services': 'Hair, Facial',
      'categories': 'Festive',
      'genders': 'Women',
      'image': null,
      'redeemed': 0,
    },
    {
      'code': 'LOYALTY20',
      'discountType': 'Percentage',
      'discountValue': 20,
      'status': 'Expired',
      'startsOn': DateTime(2025, 5, 1),
      'expiresOn': DateTime(2025, 5, 31),
      'services': 'Spa',
      'categories': 'Loyalty',
      'genders': 'All',
      'image': null,
      'redeemed': 37,
    },
  ];

  // Sample services data (in a real app, this would come from the services page)
  final List<Map<String, dynamic>> services = [
    {
      'name': 'Basic Haircut',
      'category': 'Hair',
      'duration': '30 min',
      'price': 250.0,
      'discounted_price': 200.0,
      'is_active': true,
      'home_service': true,
      'event_service': false,
    },
    {
      'name': 'Manicure',
      'category': 'Nails',
      'duration': '45 min',
      'price': 350.0,
      'discounted_price': 300.0,
      'is_active': false,
      'home_service': true,
      'event_service': true,
    },
    {
      'name': 'Hair Coloring',
      'category': 'Hair',
      'duration': '2 hours',
      'price': 1200.0,
      'discounted_price': 1000.0,
      'is_active': true,
      'home_service': true,
      'event_service': true,
    },
    {
      'name': 'Facial',
      'category': 'Skin',
      'duration': '1 hour',
      'price': 800.0,
      'discounted_price': 600.0,
      'is_active': true,
      'home_service': true,
      'event_service': false,
    },
    {
      'name': 'Makeup',
      'category': 'Makeup',
      'duration': '1.5 hours',
      'price': 1500.0,
      'discounted_price': 1200.0,
      'is_active': true,
      'home_service': false,
      'event_service': true,
    },
  ];

  int get totalCoupons => coupons.length;
  int get activeCoupons =>
      coupons.where((c) => c['status'] == 'Active').length;
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
          onSubmit: _addCoupon,
        );
      },
    );
  }

  // Add new coupon to the list
  void _addCoupon(Map<String, dynamic> coupon) {
    setState(() {
      coupons.add(coupon);
    });
  }

  void _editCoupon(int index) {
    final couponToEdit = coupons[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CouponDialog(
          mode: CouponDialogMode.edit,
          services: services,
          initialCoupon: couponToEdit,
          onSubmit: (updatedCoupon) => _updateCoupon(index, updatedCoupon),
        );
      },
    );
  }

  void _updateCoupon(int index, Map<String, dynamic> updatedCoupon) {
    setState(() {
      coupons[index] = updatedCoupon;
    });
  }

  void _deleteCoupon(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Coupon'),
          content: const Text(
            'Are you sure you want to delete this coupon? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  coupons.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showImages(Map<String, dynamic> c) {
    List<String> images = [];
    
    // Handle different types of image data
    final imageData = c['image'];
    if (imageData is String) {
      images = [imageData];
    } else if (imageData is List) {
      images = List<String>.from(imageData);
    }
    
    if (images.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Coupon Images'),
            backgroundColor: Colors.white,
            content: SizedBox(
              width: 500,
              height: images.length * 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imagePath = images[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: _buildImageWidget(imagePath),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
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
        child: Column(
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_offer,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      backgroundColor: const Color(0xFF2563EB),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              _HeaderCell('Code', flex: 2),
                              _HeaderCell('Discount'),
                              _HeaderCell('Status'),
                              _HeaderCell('Starts On'),
                              _HeaderCell('Expires On'),
                              _HeaderCell('Services', flex: 2),
                              _HeaderCell('Service Categories', flex: 2),
                              _HeaderCell('Genders'),
                              _HeaderCell('Image'),
                              _HeaderCell('Redeemed'),
                              _HeaderCell('Actions', alignRight: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: coupons
                              .map(
                                (c) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: _couponRow(c),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _couponRow(Map<String, dynamic> c) {
    final index = coupons.indexOf(c);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              c['code'] as String,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              c['discountType'] == 'Flat'
                  ? '₹${c['discountValue']}'
                  : '${c['discountValue']}%',
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusChip(c['status'] as String),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('d MMM yyyy').format(c['startsOn'] as DateTime),
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('d MMM yyyy').format(c['expiresOn'] as DateTime),
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: _wrapTextContent(c['services'] as String),
          ),
          Expanded(
            flex: 2,
            child: _wrapTextContent(c['categories'] as String),
          ),
          Expanded(
            child: Text(
              c['genders'] as String,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => _showImages(c),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade200,
                  child: _getImageIcon(c),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              (c['redeemed'] as int).toString(),
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _editCoupon(index),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteCoupon(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapTextContent(String content) {
    // Split the content by comma to get individual items
    final items = content.split(', ').where((item) => item.isNotEmpty).toList();
    
    // If 1 or fewer items, display normally
    if (items.length == 1) { 
      return Text(
        content,
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // If more than 1 items, wrap them in a column
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First 3 items
        Text(
          items.take(1).join(', '),
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.left,
        ),
        // Remaining items
        Text(
          items.skip(1).join(', '),
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Widget _getImageIcon(Map<String, dynamic> c) {
    final image = c['image'];
    if (image != null) {
      // Check if we have images
      if (image is String && image.isNotEmpty) {
        return const Icon(
          Icons.image,
          size: 16,
          color: Color(0xFF6B7280),
        );
      } else if (image is List && image.isNotEmpty) {
        return const Icon(
          Icons.image,
          size: 16,
          color: Color(0xFF6B7280),
        );
      }
    }
    
    return const Icon(
      Icons.image_outlined,
      size: 16,
      color: Color(0xFF6B7280),
    );
  }

  Widget _statusChip(String status) {
    Color fg;
    switch (status) {
      case 'Active':
        fg = const Color(0xFF065F46);
        break;
      case 'Scheduled':
        fg = const Color(0xFF1D4ED8);
        break;
      case 'Expired':
        fg = const Color(0xFFB91C1C);
        break;
      default:
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ---------- add/edit coupon dialog ----------

enum CouponDialogMode { create, edit }

class CouponDialog extends StatefulWidget {
  final CouponDialogMode mode;
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? initialCoupon;
  final Function(Map<String, dynamic>) onSubmit;

  const CouponDialog({
    super.key,
    required this.mode,
    required this.services,
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

  late bool _useCustomCode;
  late String _discountType;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _selectedServices;
  late List<String> _selectedCategories;
  late String _selectedGender;
  List<String>? _selectedImages = [];

  final List<String> _discountTypes = ['Percentage', 'Flat'];
  final List<String> _genders = ['All', 'Men', 'Women', 'Unisex'];

  bool get _isEdit => widget.mode == CouponDialogMode.edit;

  @override
  void initState() {
    super.initState();

    final c = widget.initialCoupon;

    _couponCodeController =
        TextEditingController(text: c != null ? c['code'] as String : '');
    _discountValueController = TextEditingController(
      text: c != null
          ? (c['discountValue'] as num).toString()
          : '',
    );

    _useCustomCode = true;
    _discountType =
        c != null ? c['discountType'] as String : 'Percentage';
    _startDate = c != null ? c['startsOn'] as DateTime : DateTime.now();
    _endDate = c != null
        ? c['expiresOn'] as DateTime
        : DateTime.now().add(const Duration(days: 30));
    _selectedGender = c != null ? c['genders'] as String : 'All';
    
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

    // Services
    if (c != null) {
      final servicesString = c['services'] as String;
      if (servicesString == 'All Services') {
        _selectedServices =
            widget.services.map((s) => s['name'] as String).toList();
      } else {
        _selectedServices =
            (servicesString.split(', ')..removeWhere((s) => s.isEmpty))
                .toList();
      }
    } else {
      _selectedServices =
          widget.services.map((s) => s['name'] as String).toList();
    }

    // Categories
    if (c != null) {
      final categoriesString = c['categories'] as String;
      if (categoriesString == 'All') {
        final categories = <String>{};
        for (var service in widget.services) {
          if (service['category'] is String) {
            categories.add(service['category'] as String);
          }
        }
        _selectedCategories = categories.toList();
      } else {
        _selectedCategories =
            (categoriesString.split(', ')..removeWhere((s) => s.isEmpty))
                .toList();
      }
    } else {
      final categories = <String>{};
      for (var service in widget.services) {
        if (service['category'] is String) {
          categories.add(service['category'] as String);
        }
      }
      _selectedCategories = categories.toList();
    }
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  List<String> get _availableCategories {
    final categories = <String>{};
    for (var service in widget.services) {
      if (service['category'] is String) {
        categories.add(service['category'] as String);
      }
    }
    return categories.toList();
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

  void _toggleServiceSelection(String serviceName) {
    setState(() {
      if (_selectedServices.contains(serviceName)) {
        _selectedServices.remove(serviceName);
      } else {
        _selectedServices.add(serviceName);
      }
      _updateCategoriesBasedOnServices();
    });
  }

  void _toggleCategorySelection(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _updateCategoriesBasedOnServices() {
    final categories = <String>{};
    for (var service in widget.services) {
      if (_selectedServices.contains(service['name'])) {
        if (service['category'] is String) {
          categories.add(service['category'] as String);
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
        'services': _selectedServices.isEmpty
            ? 'All Services'
            : _selectedServices.join(', '),
        'categories': _selectedCategories.isEmpty
            ? 'All'
            : _selectedCategories.join(', '),
        'genders': _selectedGender,
        'image': _selectedImages, // Changed from _selectedImage to _selectedImages
      };

      widget.onSubmit(couponData);
      Navigator.of(context).pop();
    }
  }

  String _generateUniqueCode() {
    final now = DateTime.now();
    return 'COUPON${now.millisecondsSinceEpoch.toString().substring(6)}';
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
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.3),
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
          final maxHeight = MediaQuery.of(context).size.height * 0.8;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: maxHeight,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _useCustomCode,
                                  onChanged: (value) {
                                    setState(() {
                                      _useCustomCode = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  'Use custom coupon code',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (_useCustomCode)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 10),
                                child: TextFormField(
                                  controller: _couponCodeController,
                                  decoration:
                                      _underlineInput('Coupon Code'),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                  validator: (value) {
                                    if (_useCustomCode &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Please enter a coupon code';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            const SizedBox(height: 6),
                            _sectionLabel('Discount Type'),
                            const SizedBox(height: 4),
                            _chipDropdown<String>(
                              value: _discountType,
                              items: _discountTypes,
                              onChanged: (value) {
                                setState(() {
                                  _discountType = value ?? 'Percentage';
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            _sectionLabel('Discount Value'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _discountValueController,
                              decoration: _underlineInput(
                                _discountType == 'Percentage'
                                    ? 'Percentage'
                                    : 'Flat Amount',
                              ),
                              style: GoogleFonts.poppins(fontSize: 12),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a discount value';
                                }
                                final numValue =
                                    double.tryParse(value.trim());
                                if (numValue == null || numValue <= 0) {
                                  return 'Please enter a valid discount value';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _sectionLabel('Starts On / Expires On'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: _selectStartDate,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateFormat.format(_startDate),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'to',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: _selectEndDate,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateFormat.format(_endDate),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _sectionLabel('Applicable Services'),
                            const SizedBox(height: 3),
                            _helperText(
                              'Select specific services or leave empty for all',
                            ),
                            const SizedBox(height: 6),
                            if (widget.services.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: _helperText('No services available'),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _selectedServices.length ==
                                              widget.services.length,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedServices = widget
                                                    .services
                                                    .map((s) =>
                                                        s['name'] as String)
                                                    .toList();
                                              } else {
                                                _selectedServices.clear();
                                              }
                                              _updateCategoriesBasedOnServices();
                                            });
                                          },
                                        ),
                                        Text(
                                          'Select all services',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 14),
                                    SizedBox(
                                      height: 90,
                                      child: GridView.count(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                        childAspectRatio: 3.2,
                                        children: widget.services
                                            .map((service) {
                                          final serviceName =
                                              service['name'] as String;
                                          final category =
                                              service['category']
                                                      as String? ??
                                                  '';
                                          final price =
                                              service['price'] as num?;
                                          final display =
                                              price != null
                                                  ? '₹$price'
                                                  : '';

                                          final selected =
                                              _selectedServices
                                                  .contains(serviceName);

                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: selected
                                                  ? Colors.blue
                                                      .shade50
                                                  : Colors.white,
                                              border: Border.all(
                                                color: selected
                                                    ? const Color(
                                                        0xFF2563EB)
                                                    : const Color(
                                                        0xFFE5E7EB),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  _toggleServiceSelection(
                                                      serviceName),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(
                                                        4),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Text(
                                                      serviceName,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style:
                                                          GoogleFonts
                                                              .poppins(
                                                        fontSize: 9,
                                                        fontWeight: selected
                                                            ? FontWeight
                                                                .w600
                                                            : FontWeight
                                                                .w400,
                                                        color: selected
                                                            ? const Color(
                                                                0xFF2563EB)
                                                            : const Color(
                                                                0xFF111827),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 1),
                                                    if (display
                                                        .isNotEmpty)
                                                      Text(
                                                        display,
                                                        textAlign:
                                                            TextAlign
                                                                .center,
                                                        style: GoogleFonts
                                                            .poppins(
                                                          fontSize: 8,
                                                          color: selected
                                                              ? const Color(
                                                                  0xFF2563EB)
                                                              : const Color(
                                                                  0xFF6B7280),
                                                        ),
                                                      ),
                                                    if (category
                                                        .isNotEmpty)
                                                      Text(
                                                        category,
                                                        textAlign:
                                                            TextAlign
                                                                .center,
                                                        style: GoogleFonts
                                                            .poppins(
                                                          fontSize: 7.5,
                                                          color: selected
                                                              ? const Color(
                                                                  0xFF2563EB)
                                                              : const Color(
                                                                  0xFF9CA3AF),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            _sectionLabel('Applicable Service Categories'),
                            const SizedBox(height: 3),
                            _helperText(
                              'Auto-selected based on services + manual selection',
                            ),
                            const SizedBox(height: 6),
                            if (_availableCategories.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child:
                                    _helperText('No categories available'),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _selectedCategories.length ==
                                              _availableCategories.length,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedCategories =
                                                    List.from(
                                                        _availableCategories);
                                              } else {
                                                _selectedCategories
                                                    .clear();
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          'Select all categories',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 14),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _availableCategories
                                          .map((category) {
                                        final selected =
                                            _selectedCategories
                                                .contains(category);
                                        return FilterChip(
                                          label: Text(
                                            category,
                                            style:
                                                GoogleFonts.poppins(
                                              fontSize: 9,
                                            ),
                                          ),
                                          selected: selected,
                                          onSelected: (_) {
                                            _toggleCategorySelection(
                                                category);
                                          },
                                          selectedColor:
                                              const Color(0xFFDDEAFE),
                                          backgroundColor:
                                              const Color(0xFFE5E7EB),
                                          checkmarkColor:
                                              const Color(0xFF2563EB),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F0FF),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _infoBullet(
                                    'When you select specific services, their categories are automatically selected.',
                                  ),
                                  _infoBullet(
                                    'Auto-selected categories cannot be manually deselected.',
                                  ),
                                  _infoBullet(
                                    'You can manually select additional categories beyond those auto-selected.',
                                  ),
                                  _infoBullet(
                                    'If you select both services and additional categories, the offer applies to all of them.',
                                  ),
                                  _infoBullet(
                                    'If you select neither services nor categories, the offer applies to all your services.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _sectionLabel('Applicable Genders'),
                            const SizedBox(height: 4),
                            _chipDropdown<String>(
                              value: _selectedGender,
                              items: _genders,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value ?? 'All';
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            _sectionLabel('Offer Image (Optional)'),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: const [
                                            BoxShadow(
                                              color:
                                                  Color(0x14000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.image_outlined,
                                          size: 20,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _selectedImages == null || _selectedImages!.isEmpty
                                            ? 'Upload images'
                                            : '${_selectedImages!.length} image(s) selected',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              const Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'JPG, PNG, GIF, WebP • up to 5MB',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          color:
                                              const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          primaryLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
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
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool alignRight;

  const _HeaderCell(
    this.label, {
    this.flex = 1,
    this.alignRight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
