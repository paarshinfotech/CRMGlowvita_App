import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  // Sample reviews data
  final List<Map<String, dynamic>> reviews = [
    {
      'id': '1',
      'customerName': 'Priya Sharma',
      'serviceName': 'Facial Treatment',
      'productName': null,
      'salonName': null,
      'type': 'service',
      'rating': 5,
      'date': '2025-11-15',
      'review':
          'Amazing service! The facial was very relaxing and my skin felt great afterwards. Will definitely come back.',
      'status': 'Approved',
    },
    {
      'id': '2',
      'customerName': 'Rahul Mehta',
      'serviceName': null,
      'productName': 'Hydrating Face Serum',
      'salonName': null,
      'type': 'product',
      'rating': 4,
      'date': '2025-11-10',
      'review':
          'Good service overall. The color turned out well, but the waiting time was a bit long.',
      'status': 'Approved',
    },
    {
      'id': '3',
      'customerName': 'Anjali Patel',
      'serviceName': 'Manicure',
      'productName': null,
      'salonName': null,
      'type': 'service',
      'rating': 3,
      'date': '2025-11-05',
      'review':
          'Average experience. The nail art was nice but the polish chipped off quickly.',
      'status': 'Pending',
    },
    {
      'id': '4',
      'customerName': 'Vikram Singh',
      'serviceName': null,
      'productName': null,
      'salonName': 'GlowVita Salon',
      'type': 'salon',
      'rating': 5,
      'date': '2025-10-28',
      'review':
          'Outstanding service! The full spa package was very relaxing and rejuvenating. Highly recommended!',
      'status': 'Approved',
    },
    {
      'id': '5',
      'customerName': 'Sneha Reddy',
      'serviceName': 'Basic Haircut',
      'productName': null,
      'salonName': null,
      'type': 'service',
      'rating': 2,
      'date': '2025-10-20',
      'review':
          'Not satisfied with the haircut. It was uneven and not what I asked for.',
      'status': 'Disapproved',
    },
  ];

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  // Filter options
  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Approved',
    'Disapproved'
  ];
  final List<String> _categoryFilters = [
    'All',
    'Services',
    'Products',
    'Salons'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtered reviews getter
  List<Map<String, dynamic>> get _filteredReviews {
    return reviews.where((review) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          review['customerName']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (review['serviceName']
                  ?.toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (review['productName']
                  ?.toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (review['salonName']
                  ?.toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          review['review']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesStatus =
          _selectedStatus == 'All' || review['status'] == _selectedStatus;

      // Category filter
      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'Services' && review['type'] == 'service') ||
          (_selectedCategory == 'Products' && review['type'] == 'product') ||
          (_selectedCategory == 'Salons' && review['type'] == 'salon');

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Reviews'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Reviews',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search reviews...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey, size: 20),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            // Filter row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Status filter dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        underline: const SizedBox(),
                        items: _statusFilters
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
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category filter dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        underline: const SizedBox(),
                        items: _categoryFilters
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Header stats (approved and pending counts)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Approved',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getApprovedCount()}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pending_outlined,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pending',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getPendingCount()}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
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
            // Count card (similar to products page) - moved to second line
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.rate_review,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reviews',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Text('${_filteredReviews.length} reviews in total',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_filteredReviews.length}',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Reviews list header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Filter dropdown could go here
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Reviews list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredReviews.length,
                itemBuilder: (context, index) {
                  final review = _filteredReviews[index];
                  return _buildReviewCard(review);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getApprovedCount() {
    return reviews.where((review) => review['status'] == 'Approved').length;
  }

  int _getPendingCount() {
    return reviews.where((review) => review['status'] == 'Pending').length;
  }

  double _calculateAverageRating() {
    if (reviews.isEmpty) return 0.0;
    double total = 0;
    for (final review in reviews) {
      total += review['rating'] as int;
    }
    return total / reviews.length;
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final status = review['status'] as String;
    final type = review['type'] as String;

    Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Disapproved':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Different display based on review type
          if (type == 'service') ...[
            // Service review
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['serviceName'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Service',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rating stars
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: i < rating ? Colors.amber : Colors.grey,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer name
            Text(
              'by ${review['customerName']}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            // Review text
            Text(
              review['review'] as String,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            // Date
            Text(
              review['date'] as String,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ] else if (type == 'product') ...[
            // Product review
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['productName'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Product',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rating stars
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: i < rating ? Colors.amber : Colors.grey,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer name
            Text(
              'by ${review['customerName']}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            // Review text
            Text(
              review['review'] as String,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            // Date
            Text(
              review['date'] as String,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ] else ...[
            // Salon review
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customerName'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rating stars
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: i < rating ? Colors.amber : Colors.grey,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Review text
                      Text(
                        review['review'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date
                      Text(
                        review['date'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action buttons for salon reviews
                    Row(
                      children: [
                        if (status !=
                            'Approved') // Show reject button only if not approved
                          TextButton(
                            onPressed: () {
                              // Reject logic would go here
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Reject',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            // Delete logic would go here
                            setState(() {
                              reviews
                                  .removeWhere((r) => r['id'] == review['id']);
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
