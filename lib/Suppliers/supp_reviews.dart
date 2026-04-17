import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './supp_drawer.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/subscription_wrapper.dart';

class SuppReviewsPage extends StatefulWidget {
  const SuppReviewsPage({super.key});

  @override
  State<SuppReviewsPage> createState() => _SuppReviewsPageState();
}

class _SuppReviewsPageState extends State<SuppReviewsPage> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  // Filter options
  final List<String> _statusFilters = ['All', 'Pending', 'Approved'];
  final List<String> _categoryFilters = [
    'All',
    'Services',
    'Products',
    'Salons'
  ];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final fetchedReviews = await ApiService.getReviews();
      print('DEBUG: Fetched ${fetchedReviews.length} reviews');
      if (mounted) {
        setState(() {
          _reviews = fetchedReviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching reviews: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String reviewId, bool isApproved) async {
    try {
      final success = await ApiService.updateReviewStatus(reviewId, isApproved);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  isApproved ? 'Review Approved' : 'Review set to Pending'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchReviews();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Review',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
            'Are you sure you want to permanently delete this review?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ApiService.deleteReview(reviewId);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review deleted successfully')),
            );
          }
          _fetchReviews();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReviews {
    return _reviews.where((review) {
      final userName =
          (review['userName'] ?? review['user']?['name'] ?? 'Anonymous')
              .toString()
              .toLowerCase();
      final comment = (review['comment'] ?? '').toString().toLowerCase();

      final entity = review['entityDetails'] ?? {};
      final entityName = (entity['productName'] ??
              entity['salonName'] ??
              entity['serviceName'] ??
              '')
          .toString()
          .toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          userName.contains(_searchQuery.toLowerCase()) ||
          comment.contains(_searchQuery.toLowerCase()) ||
          entityName.contains(_searchQuery.toLowerCase());

      final isApproved = review['isApproved'] == true;
      String status = isApproved ? 'Approved' : 'Pending';

      final matchesStatus =
          _selectedStatus == 'All' || status == _selectedStatus;

      final type = (review['entityType'] ?? '').toString().toLowerCase();
      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'Services' && type == 'service') ||
          (_selectedCategory == 'Products' &&
              (type == 'product' || type == 'products')) ||
          (_selectedCategory == 'Salons' && type == 'salon');

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Reviews'),
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Manage Reviews',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 14.sp),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _fetchReviews,
          ),
        ],
      ),
      body: SubscriptionWrapper(
        child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            _buildSearchBar(),

            // Filter row
            _buildFilterRow(),

            const SizedBox(height: 16),

            // Stats Header
            _buildStatsHeader(),

            const SizedBox(height: 16),

            // Reviews list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_filteredReviews.length} Results',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Reviews list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchReviews,
                color: Theme.of(context).primaryColor,
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredReviews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _filteredReviews.length,
                            itemBuilder: (context, index) {
                              return _buildReviewCard(_filteredReviews[index]);
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by user, product or comment...',
          hintStyle:
              GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedStatus,
              items: _statusFilters,
              onChanged: (v) => setState(() => _selectedStatus = v!),
              icon: Icons.filter_list_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              value: _selectedCategory,
              items: _categoryFilters,
              onChanged: (v) => setState(() => _selectedCategory = v!),
              icon: Icons.category_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: Colors.grey.shade600),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(icon, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(s,
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final approved = _reviews.where((r) => r['isApproved'] == true).length;
    final pending = _reviews.where((r) => r['isApproved'] != true).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem('Approved', approved, Colors.green),
          const SizedBox(width: 12),
          _buildStatItem('Pending', pending, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              strokeWidth: 2, color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            'Fetching reviews...',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No reviews found',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600),
              ),
              Text(
                'Change your filters or search query',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num? ?? 0).toInt();
    final isApproved = review['isApproved'] == true;
    final type = (review['entityType'] ?? 'product').toString().toLowerCase();
    final String reviewId = review['_id'] ?? '';

    final entity = review['entityDetails'] ?? {};
    final String entityName = entity['productName'] ??
        entity['salonName'] ??
        entity['serviceName'] ??
        'General Item';

    final String customerName =
        review['userName'] ?? review['user']?['name'] ?? 'Anonymous';
    final String comment = review['comment'] ?? 'No comment provided.';

    String dateStr = 'Unknown date';
    if (review['createdAt'] != null) {
      try {
        final dt = DateTime.parse(review['createdAt']);
        dateStr = DateFormat('MMM dd, yyyy').format(dt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      dateStr,
                      style:
                          GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                              i < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < rating
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                              size: 16,
                            )),
                  ),
                  const SizedBox(height: 4),
                  _buildTypeBadge(type),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'About: $entityName',
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isApproved ? 'Approved' : 'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isApproved ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: isApproved,
                      activeColor: Colors.green,
                      splashRadius: 0,
                      onChanged: (v) => _updateStatus(reviewId, v),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _deleteReview(reviewId),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    switch (type) {
      case 'service':
        color = Colors.blue;
        break;
      case 'product':
      case 'products':
        color = Colors.purple;
        break;
      case 'salon':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.poppins(
            fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
