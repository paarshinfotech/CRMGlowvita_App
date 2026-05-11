import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';
import 'my_Profile.dart';
import 'Notification.dart';

class Settlements extends StatefulWidget {
  const Settlements({Key? key}) : super(key: key);

  @override
  State<Settlements> createState() => _SettlementsState();
}

class _SettlementsState extends State<Settlements> {
  bool _isLoading = true;
  String? _errorMessage;
  VendorProfile? _profile;
  String _searchQuery = '';
  String _selectedMonth = 'This Month';
  String _selectedStatus = 'All Status';

  // Settlement data
  List<Map<String, dynamic>> _settlements = [];
  double _totalAmount = 0.0;
  double _adminOwesVendors = 0.0;
  double _vendorsOweAdmin = 0.0;
  double _netSettlement = 0.0;

  final List<String> _months = [
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
  ];

  final List<String> _statuses = [
    'All Status',
    'Pending',
    'Partially Paid',
    'Settled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchSettlements();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _fetchSettlements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getSettlements();

      setState(() {
        _settlements = List<Map<String, dynamic>>.from(result['data'] ?? []);
        final summary = result['summary'] ?? {};
        _totalAmount = (summary['totalAmount'] ?? 0.0).toDouble();
        _adminOwesVendors = (summary['totalVendorAmount'] ?? 0.0).toDouble();
        _vendorsOweAdmin = (summary['totalAdminReceivable'] ?? 0.0).toDouble();
        _netSettlement = (summary['totalPending'] ?? 0.0).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error fetching settlements: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredSettlements {
    final q = _searchQuery.trim().toLowerCase();
    List<Map<String, dynamic>> filtered = List.from(_settlements);

    // Filter by search query
    if (q.isNotEmpty) {
      filtered = filtered.where((s) {
        final vendorName = (s['vendorName'] ?? '').toString().toLowerCase();
        final ownerName = (s['ownerName'] ?? '').toString().toLowerCase();
        return vendorName.contains(q) || ownerName.contains(q);
      }).toList();
    }

    /*
    // Filter by status
    if (_selectedStatus != 'All Status') {
      filtered = filtered.where((s) {
        final status = (s['status'] ?? '').toString();
        return status.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }
    */

    return filtered;
  }

  void _showSettlementDetails(Map<String, dynamic> settlement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettlementDetailsSheet(
        settlement: settlement,
        onPaymentRecorded: () {
          Navigator.pop(context);
          _fetchSettlements();
        },
        onPayAdmin: () => _showPayAdminDialog(settlement),
      ),
    );
  }

  void _showPayAdminDialog(Map<String, dynamic> settlement) {
    showDialog(
      context: context,
      builder: (context) => _PayAdminDialog(
        settlement: settlement,
        onPaymentRecorded: () {
          Navigator.pop(context);
          _fetchSettlements();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filteredSettlements;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(fontSizeFactor: 0.75),
      ),
      child: Scaffold(
        drawer: const CustomDrawer(currentPage: 'Settlements'),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'Vendor Settlements',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const My_Profile()),
              ),
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: ClipOval(
                    child:
                        (_profile != null && _profile!.profileImage.isNotEmpty)
                        ? Image.network(
                            _profile!.profileImage,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => _buildInitialAvatar(),
                            loadingBuilder: (ctx, child, progress) =>
                                progress == null
                                ? child
                                : const CircularProgressIndicator(),
                          )
                        : _buildInitialAvatar(),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchSettlements,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  'Track settlements for both Pay Online and Pay at Salon appointments',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Cards - 2x2 Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Amount',
                        value: '₹${_totalAmount.toStringAsFixed(2)}',
                        subtitle: '${_settlements.length} settlements',
                        valueColor: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Admin Owes Vendors',
                        value: '₹${_adminOwesVendors.toStringAsFixed(2)}',
                        subtitle: 'Pay Online service amounts',
                        valueColor: Colors.orange[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Vendors Owe Admin',
                        value: '₹${_vendorsOweAdmin.toStringAsFixed(2)}',
                        subtitle: 'Pay at Salon fees',
                        valueColor: Colors.green[700]!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Net Settlement',
                        value:
                            '${_netSettlement >= 0 ? '+' : ''} ₹${_netSettlement.toStringAsFixed(2)}',
                        subtitle: 'Vendors owe admin',
                        valueColor: _netSettlement >= 0
                            ? Colors.green[700]!
                            : Colors.orange[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                      hintText: 'Search by vendor or owner name...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 11),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(height: 10),

                /*
                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          icon: Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Colors.grey[600]),
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.black87),
                          items: _months.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMonth = newValue ?? 'This Month';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          icon: Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Colors.grey[600]),
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.black87),
                          items: _statuses.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStatus = newValue ?? 'All Status';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                */
                const SizedBox(height: 12),

                // Settlements List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _fetchSettlements,
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredData.isEmpty
                      ? Center(
                          child: Text(
                            'No settlements found.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final settlement = filteredData[idx];
                            return _SettlementCard(
                              settlement: settlement,
                              onViewDetails: () =>
                                  _showSettlementDetails(settlement),
                              onPayAdmin: () => _showPayAdminDialog(settlement),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 7, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Settlement Card Widget
class _SettlementCard extends StatelessWidget {
  final Map<String, dynamic> settlement;
  final VoidCallback onViewDetails;
  final VoidCallback onPayAdmin;

  const _SettlementCard({
    required this.settlement,
    required this.onViewDetails,
    required this.onPayAdmin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settlementId = settlement['id'] ?? 'N/A';
    final vendorName = settlement['vendorName'] ?? 'Unknown Vendor';
    final totalAmount = (settlement['totalAmount'] ?? 0.0).toDouble();
    final vendorOwesAdmin = (settlement['vendorOwesAdmin'] ?? 0.0).toDouble();
    final status = settlement['status'] ?? 'Pending';
    final vendorImage = settlement['vendorImage'] ?? '';

    final statusColor = status == 'Settled'
        ? const Color(0xFF166534)
        : status == 'Partially Paid'
        ? const Color(0xFF9A3412)
        : const Color(0xFFB91C1C);

    final statusBgColor = status == 'Settled'
        ? const Color(0xFFDCFCE7)
        : status == 'Partially Paid'
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: vendorImage.isNotEmpty
                          ? Image.network(
                              vendorImage,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendorName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID : $settlementId',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹ ${totalAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Due to Admin',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFF166534),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹ ${vendorOwesAdmin.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onViewDetails,
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onPayAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A2C3C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Pay Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey[200],
      child: const Icon(
        Icons.storefront_outlined,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
}

// Settlement Details Sheet
class _SettlementDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> settlement;
  final VoidCallback onPaymentRecorded;
  final VoidCallback onPayAdmin;

  const _SettlementDetailsSheet({
    required this.settlement,
    required this.onPaymentRecorded,
    required this.onPayAdmin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vendorName = settlement['vendorName'] ?? 'N/A';
    final ownerName = settlement['ownerName'] ?? 'N/A';
    final contactNo = settlement['contactNo'] ?? 'N/A';
    final settlementId = settlement['id'] ?? 'N/A';

    final totalAmount = (settlement['totalAmount'] ?? 0.0).toDouble();
    final adminOwesVendor = (settlement['adminOwesVendor'] ?? 0.0).toDouble();
    final vendorOwesAdmin = (settlement['vendorOwesAdmin'] ?? 0.0).toDouble();
    final netSettlement = (settlement['netSettlement'] ?? 0.0).toDouble();

    final platformFeeTotal = (settlement['platformFeeTotal'] ?? 0.0).toDouble();
    final serviceTaxTotal = (settlement['serviceTaxTotal'] ?? 0.0).toDouble();

    final amountPaid = (settlement['amountPaid'] ?? 0.0).toDouble();
    final status = settlement['status'] ?? 'Pending';

    final paymentHistory = settlement['paymentHistory'] as List? ?? [];
    final appointments = settlement['appointments'] as List? ?? [];
    final amountPending = (settlement['amountPending'] ?? 0.0).toDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settlement Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Detailed breakdown of vendor settlement',
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor Details - 2 Column Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vendor Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vendorName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Owner Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ownerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                contactNo,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settlement ID',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                settlementId.length > 25
                                    ? '${settlementId.substring(0, 22)}...'
                                    : settlementId,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _AmountCard(
                            title: 'Total Volume',
                            amount: totalAmount,
                            subtitle: '',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AmountCard(
                            title: 'From Online Bookings',
                            amount: adminOwesVendor,
                            subtitle: 'Service amount admin owes you',
                            color: Colors.green[700]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _AmountCard(
                            title: 'From Salon Bookings',
                            amount: vendorOwesAdmin,
                            subtitle: 'Fees you owe admin',
                            color: Colors.red[700]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AmountCard(
                            title: 'Net Pending',
                            amount: netSettlement.abs(),
                            subtitle: 'Payable to Admin',
                            color: Colors.blue[700]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Two Column Layout for Fees and Summary
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tax & Fees Breakdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TAX & FEES BREAKDOWN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange[900],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildFeeRow(
                                  'Platform Fees:',
                                  platformFeeTotal,
                                ),
                                const SizedBox(height: 4),
                                _buildFeeRow('Service Tax:', serviceTaxTotal),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Settlement Summary
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SETTLEMENT SUMMARY',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildFeeRow('Amount Settled:', amountPaid),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Current Status:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: status == 'Settled'
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment History
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.currency_rupee,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Payment History',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          if (paymentHistory.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No payments recorded yet for this period.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 35,
                                dataRowHeight: 35,
                                columnSpacing: 20,
                                headingTextStyle: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                dataTextStyle: GoogleFonts.poppins(fontSize: 9),
                                columns: const [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Method')),
                                  DataColumn(label: Text('Ref ID')),
                                  DataColumn(label: Text('Amount')),
                                ],
                                rows: paymentHistory.map<DataRow>((payment) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(payment['date'] ?? 'N/A')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            payment['type'] ?? 'N/A',
                                            style: GoogleFonts.poppins(
                                              fontSize: 8,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          payment['paymentMethod'] ??
                                              payment['method'] ??
                                              'N/A',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          payment['transactionId'] ??
                                              payment['refId'] ??
                                              '--',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '₹${(payment['amount'] ?? 0.0).toStringAsFixed(2)}',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUICK ACTIONS',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[900],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You have a pending settlement of ₹${amountPending.toStringAsFixed(2)} to pay to Admin for Salon bookings.',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: status == 'Settled' ? null : onPayAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 40),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: Text(
                              'Record Payment to Admin',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              '(For Cash, Agent, or Online payments)',
                              style: GoogleFonts.poppins(
                                fontSize: 7,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Included Appointments
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Included Appointments (${appointments.length})',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 35,
                              dataRowHeight: 35,
                              columnSpacing: 20,
                              headingTextStyle: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              dataTextStyle: GoogleFonts.poppins(fontSize: 9),
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Client')),
                                DataColumn(label: Text('Service')),
                                DataColumn(label: Text('Method')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Owner Owed')),
                              ],
                              rows: appointments.map<DataRow>((apt) {
                                final date = apt['date'] != null
                                    ? DateFormat(
                                        'd/M/yyyy',
                                      ).format(DateTime.parse(apt['date']))
                                    : 'N/A';
                                final amount = (apt['totalAmount'] ?? 0.0)
                                    .toDouble();
                                final platformFee = (apt['platformFee'] ?? 0.0)
                                    .toDouble();
                                final serviceTax = (apt['serviceTax'] ?? 0.0)
                                    .toDouble();
                                final ownerOwed = -(platformFee + serviceTax);

                                return DataRow(
                                  cells: [
                                    DataCell(Text(date)),
                                    DataCell(Text(apt['clientName'] ?? 'N/A')),
                                    DataCell(Text(apt['serviceName'] ?? 'N/A')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          apt['paymentMethod'] ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                            fontSize: 8,
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text('₹${amount.toStringAsFixed(2)}'),
                                    ),
                                    DataCell(
                                      Text(
                                        ownerOwed >= 0
                                            ? '₹${ownerOwed.toStringAsFixed(2)}'
                                            : '-₹${ownerOwed.abs().toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          color: ownerOwed < 0
                                              ? Colors.red[700]
                                              : Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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
    );
  }

  Widget _buildFeeRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[700]),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Amount Card Widget for Settlement Details
class _AmountCard extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;
  final Color color;

  const _AmountCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 7, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// Pay Admin Dialog
class _PayAdminDialog extends StatefulWidget {
  final Map<String, dynamic> settlement;
  final VoidCallback onPaymentRecorded;

  const _PayAdminDialog({
    required this.settlement,
    required this.onPaymentRecorded,
    Key? key,
  }) : super(key: key);

  @override
  State<_PayAdminDialog> createState() => _PayAdminDialogState();
}

class _PayAdminDialogState extends State<_PayAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'Bank Transfer';

  final List<String> _paymentMethods = [
    'Bank Transfer',
    'UPI',
    'Cash',
    'Cheque',
    'Online',
    'Agent',
  ];

  @override
  void initState() {
    super.initState();
    final pendingAmount =
        (widget.settlement['amountPending'] ??
                widget.settlement['netPending'] ??
                0.0)
            .toDouble();
    _amountController.text = pendingAmount.toStringAsFixed(2);
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ApiService.recordSettlementPayment({
        'vendorId': widget.settlement['vendorId'] ?? widget.settlement['id'],
        'amount': double.parse(_amountController.text),
        'type': 'Payment to Admin',
        'paymentMethod': _selectedMethod,
        'transactionId': _transactionIdController.text,
        'notes': _notesController.text,
      });

      widget.onPaymentRecorded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment recorded successfully',
            style: GoogleFonts.poppins(fontSize: 10),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to record payment',
            style: GoogleFonts.poppins(fontSize: 10),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAmount =
        (widget.settlement['amountPending'] ??
                widget.settlement['netPending'] ??
                0.0)
            .toDouble();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay Admin — Platform Fees',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Record your payment of platform fees owed to Admin for Pay at Salon appointments. Pending: ₹$pendingAmount',
                          style: GoogleFonts.poppins(
                            fontSize: 5.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                Text(
                  'Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: GoogleFonts.poppins(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 10),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Amount is required' : null,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending: ₹$pendingAmount',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Method
                Text(
                  'Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                  items: _paymentMethods.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMethod = newValue ?? 'Bank Transfer';
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Transaction ID
                Text(
                  'Transaction ID (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _transactionIdController,
                  decoration: InputDecoration(
                    hintText: 'Enter transaction ID',
                    hintStyle: GoogleFonts.poppins(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
                const SizedBox(height: 12),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any notes...',
                    hintStyle: GoogleFonts.poppins(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _recordPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red[900],
                        ),
                        child: Text(
                          'Record Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
