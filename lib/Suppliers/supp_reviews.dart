import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './supp_drawer.dart';

class SuppReviewsPage extends StatefulWidget {
  const SuppReviewsPage({super.key});

  @override
  State<SuppReviewsPage> createState() => _SuppReviewsPageState();
}

class _SuppReviewsPageState extends State<SuppReviewsPage> {
  // Sample product reviews data (Supplier-focused)
  List<Map<String, dynamic>> reviews = [
    {
      'id': '1',
      'customerName': 'Priya Sharma',
      'productName': 'Hydrating Face Serum',
      'rating': 5,
      'date': '2025-12-18',
      'review':
          'Excellent serum! Absorbs quickly and leaves my skin glowing. Highly recommend.',
      'status': 'Approved',
    },
    {
      'id': '2',
      'customerName': 'Rahul Mehta',
      'productName': 'Vitamin C Face Cream',
      'rating': 4,
      'date': '2025-12-15',
      'review':
          'Good cream, brightens skin well. A bit thick for daytime use though.',
      'status': 'Approved',
    },
    {
      'id': '3',
      'customerName': 'Anjali Patel',
      'productName': 'Argan Oil Hair Mask',
      'rating': 3,
      'date': '2025-12-10',
      'review':
          'Average results. Hair felt soft but not much difference after a few uses.',
      'status': 'Pending',
    },
    {
      'id': '4',
      'customerName': 'Vikram Singh',
      'productName': 'Luxury Body Butter',
      'rating': 5,
      'date': '2025-12-05',
      'review':
          'Best body butter I\'ve used! Smells amazing and keeps skin moisturized all day.',
      'status': 'Approved',
    },
    {
      'id': '5',
      'customerName': 'Sneha Reddy',
      'productName': 'Matte Lipstick Set',
      'rating': 2,
      'date': '2025-11-28',
      'review':
          'Disappointed. Colors are nice but very drying and doesn\'t last long.',
      'status': 'Pending',
    },
    {
      'id': '6',
      'customerName': 'Amit Kumar',
      'productName': 'Beard Growth Oil',
      'rating': 4,
      'date': '2025-11-20',
      'review':
          'Seeing good growth after 3 weeks. Pleasant scent and non-greasy.',
      'status': 'Approved',
    },
  ];

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Approved',
    'Disapproved'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReviews {
    return reviews.where((review) {
      final matchesSearch = _searchQuery.isEmpty ||
          review['customerName']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          review['productName']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          review['review']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatus == 'All' || review['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int _getApprovedCount() =>
      reviews.where((r) => r['status'] == 'Approved').length;
  int _getPendingCount() =>
      reviews.where((r) => r['status'] == 'Pending').length;

  void _approveReview(String id) {
    setState(() {
      final review = reviews.firstWhere((r) => r['id'] == id);
      review['status'] = 'Approved';
    });
  }

  void _rejectReview(String id) {
    setState(() {
      final review = reviews.firstWhere((r) => r['id'] == id);
      review['status'] = 'Disapproved';
    });
  }

  void _deleteReview(String id) {
    setState(() {
      reviews.removeWhere((r) => r['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:
          const SupplierDrawer(currentPage: 'Reviews'), // Updated for supplier
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text(
          'Product Reviews',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search reviews...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Status filter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _statusFilters
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                        'Approved', _getApprovedCount(), Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                        'Pending', _getPendingCount(), Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total reviews card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.rate_review,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Reviews',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${_filteredReviews.length} reviews',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${_filteredReviews.length}',
                        style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reviews list
            Expanded(
              child: _filteredReviews.isEmpty
                  ? Center(
                      child: Text(
                        'No reviews found',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredReviews.length,
                      itemBuilder: (context, index) {
                        final review = _filteredReviews[index];
                        return _buildProductReviewCard(review);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildProductReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final status = review['status'] as String;

    Color statusColor = status == 'Approved'
        ? Colors.green
        : status == 'Pending'
            ? Colors.orange
            : Colors.red;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['productName'],
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review['review'],
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${review['customerName']} • ${review['date']}',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (status == 'Pending') ...[
                    ElevatedButton(
                      onPressed: () => _approveReview(review['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(80, 32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Approve',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => _rejectReview(review['id']),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(80, 32),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Reject',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.red)),
                    ),
                  ],
                  if (status != 'Pending')
                    TextButton(
                      onPressed: () => _deleteReview(review['id']),
                      child: Text('Delete',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.grey.shade700)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
