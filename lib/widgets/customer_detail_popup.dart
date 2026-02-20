import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../customer_model.dart';
import '../appointment_model.dart';
import '../billing_invoice_model.dart';
import '../services/api_service.dart';

class CustomerDetailPopup extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPopup({Key? key, required this.customer})
      : super(key: key);

  @override
  _CustomerDetailPopupState createState() => _CustomerDetailPopupState();
}

class _CustomerDetailPopupState extends State<CustomerDetailPopup>
    with SingleTickerProviderStateMixin {
  Customer? _updatedCustomer;
  late TabController _tabController;

  final List<String> _tabs = [
    'Overview',
    'Client Details',
    'Appointments',
    'Orders',
    'Reviews',
    'Payment History',
  ];

  bool _isLoading = true;
  List<AppointmentModel> _appointments = [];
  List<BillingInvoice> _invoices = [];

  int _completedCount = 0;
  int _cancelledCount = 0;
  int _visitsCount = 0;
  double _totalBookingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchClientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClientData() async {
    try {
      final clientId = widget.customer.id;
      final clientName = widget.customer.fullName.toLowerCase().trim();

      // 1. Fetch Latest Client Data (to make it dynamic)
      final allClients = await ApiService.getClients();
      final updatedClient = allClients.firstWhere(
        (c) =>
            c.id == clientId || c.fullName.toLowerCase().trim() == clientName,
        orElse: () => widget.customer,
      );

      // 2. Fetch Appointments
      final allAppts = await ApiService.getAppointments(limit: 1000);
      final clientAppts = allAppts.where((a) {
        final cId = a.client?.id;
        final cName = a.clientName?.toLowerCase().trim();
        return cId == clientId || (cName != null && cName == clientName);
      }).toList();

      // 3. Fetch Invoices
      final allInvoices = await ApiService.getInvoices();
      final clientInvoices = allInvoices.where((inv) {
        final cId = inv.clientId;
        final cName = inv.clientInfo.fullName.toLowerCase().trim();
        return cId == clientId || cName == clientName;
      }).toList();

      // 4. Calculate metrics
      final completed = clientAppts
          .where((a) => (a.status ?? '').toLowerCase().contains('completed'))
          .length;
      final cancelled = clientAppts
          .where((a) => (a.status ?? '').toLowerCase().contains('cancelled'))
          .length;
      final visits = clientAppts
          .where((a) =>
              (a.status ?? '').toLowerCase() != 'cancelled' &&
              (a.status ?? '').toLowerCase() != 'missed')
          .length;

      // Calculate Total Sale from PAID appointments (using amountPaid)
      final totalSale = clientAppts.fold<double>(
          0, (sum, appt) => sum + (appt.amountPaid ?? 0.0));

      if (mounted) {
        setState(() {
          _updatedCustomer = updatedClient;
          _appointments = clientAppts;
          _invoices = clientInvoices;
          _completedCount = completed;
          _cancelledCount = cancelled;
          _visitsCount = visits;
          _totalBookingAmount = totalSale;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching client details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: 580,
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _buildTabBar(),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _isLoading
                    ? const Expanded(
                        child: Center(child: CircularProgressIndicator()))
                    : _buildTabContent(),
              ],
            ),
            Positioned(
              right: 12.0,
              top: 12.0,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 18, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final c = _updatedCustomer ?? widget.customer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 48, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Text(
              c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : 'C',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.fullName,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              if (c.mobile.isNotEmpty)
                Text(
                  c.mobile,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 38,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF3B1F3A),
        unselectedLabelColor: Colors.black54,
        labelStyle:
            GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.normal),
        indicatorColor: const Color(0xFF3B1F3A),
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _tabs
            .map((tab) => Tab(
                  height: 38,
                  text: tab,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewContent(),
          _buildClientDetailsContent(),
          _buildAppointmentsContent(),
          _buildOrdersContent(),
          _buildReviewsContent(),
          _buildPaymentHistoryContent(),
        ],
      ),
    );
  }

  // ─── Overview ────────────────────────────────────────────────────────────────

  Widget _buildOverviewContent() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: const Color(0xFFFAFAFA),
      child: Wrap(
        spacing: 14.0,
        runSpacing: 14.0,
        children: [
          _buildMetricCard(
              '₹${_totalBookingAmount.toStringAsFixed(0)}', 'Total Sale',
              valueColor: Colors.black87),
          _buildMetricCard('$_visitsCount', 'Total Visits',
              valueColor: Colors.black87),
          _buildMetricCard('$_completedCount', 'Completed',
              valueColor: const Color(0xFF22A861)),
          _buildMetricCard('$_cancelledCount', 'Cancelled',
              valueColor: const Color(0xFFE03E3E)),
        ],
      ),
    );
  }

  // ─── Client Details ──────────────────────────────────────────────────────────

  Widget _buildClientDetailsContent() {
    final c = _updatedCustomer ?? widget.customer;
    return Container(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Info'),
            _buildDetailGrid([
              _buildDetailCell('Full Name', c.fullName),
              _buildDetailCell('Email ID', c.email ?? ''),
              _buildDetailCell('Mobile Number', c.mobile),
              _buildDetailCell('Gender', c.gender ?? ''),
              _buildDetailCell('Date of Birth', c.dateOfBirth ?? ''),
              _buildDetailCell('Source', c.source ?? 'Offline'),
              _buildDetailCell('Online Booking', 'Allowed'),
              _buildDetailCell('Birthday Date', c.dateOfBirth ?? ''),
            ]),
            const SizedBox(height: 16),
            _buildSectionHeader('Additional Info'),
            _buildDetailGrid([
              _buildDetailCell('Country', c.country ?? 'Not provided'),
              _buildDetailCell('Occupation', c.occupation ?? 'Not provided'),
              _buildDetailCell('Address', c.address ?? 'Not provided'),
              _buildDetailCell('Note', c.note ?? ''),
            ]),
            const SizedBox(height: 8),
            _buildDetailCell('Preferences', 'No preferences recorded.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailGrid(List<Widget> cells) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 12,
      children: cells,
    );
  }

  Widget _buildDetailCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Appointments ────────────────────────────────────────────────────────────

  Widget _buildAppointmentsContent() {
    final now = DateTime.now();

    final upcomingAppts = _appointments.where((a) {
      final apptDate = a.date ?? DateTime(0);
      final startTimeStr = a.startTime ?? '00:00';
      final parts = startTimeStr.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      final fullApptTime = DateTime(
        apptDate.year,
        apptDate.month,
        apptDate.day,
        hour,
        minute,
      );

      return fullApptTime.isAfter(now);
    }).toList()
      ..sort(
          (a, b) => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)));

    final pastAppts = _appointments.where((a) {
      final apptDate = a.date ?? DateTime(0);
      final startTimeStr = a.startTime ?? '00:00';
      final parts = startTimeStr.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

      final fullApptTime = DateTime(
        apptDate.year,
        apptDate.month,
        apptDate.day,
        hour,
        minute,
      );

      return fullApptTime.isBefore(now) || fullApptTime.isAtSameMomentAs(now);
    }).toList()
      ..sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 40,
            color: Colors.white,
            child: TabBar(
              tabs: [
                Tab(text: 'Upcoming (${upcomingAppts.length})'),
                Tab(text: 'Past (${pastAppts.length})'),
              ],
              labelColor: const Color(0xFF3B1F3A),
              unselectedLabelColor: Colors.black45,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
              indicatorColor: const Color(0xFF3B1F3A),
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          Expanded(
            child: TabBarView(
              children: [
                _buildAppointmentList(
                    upcomingAppts, 'No upcoming appointments.'),
                _buildAppointmentList(pastAppts, 'No past appointments.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentModel> appts, String emptyMsg) {
    if (appts.isEmpty) {
      return _buildEmptyState(Icons.calendar_today_outlined, emptyMsg);
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appts.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (context, index) {
          final appt = appts[index];
          final sc = _getStatusColors(appt.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.serviceName ?? 'Unknown Service',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('M/d/yyyy').format(appt.date ?? DateTime.now())} • ${appt.startTime ?? ''}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(appt.totalAmount ?? 0).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: sc.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        appt.status ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: sc.text,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Orders ──────────────────────────────────────────────────────────────────

  Widget _buildOrdersContent() {
    if (_invoices.isEmpty) {
      return _buildEmptyState(Icons.inventory_2_outlined, 'No orders yet.',
          subtitle:
              'Orders will appear here once the client makes a purchase from your store.');
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final inv = _invoices[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: Colors.black87),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${inv.invoiceNumber}',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, yyyy').format(inv.createdAt),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0F3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inv.paymentStatus.isEmpty
                                  ? 'Processing'
                                  : inv.paymentStatus,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3B1F3A)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${inv.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Items section
                ...inv.items
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.image_outlined,
                                    size: 20, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${item.price.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ))
                    .toList(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                      height: 24, thickness: 1, color: Color(0xFFF5F5F5)),
                ),

                // Footer (Address)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    inv.clientInfo.address.isEmpty
                        ? 'Nashik, Maharashtra'
                        : inv.clientInfo.address,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────────

  Widget _buildReviewsContent() {
    return _buildEmptyState(Icons.star_outline_rounded, 'No reviews found.',
        subtitle:
            "This client hasn't left any reviews for your services or products yet.");
  }

  // ─── Payment History ─────────────────────────────────────────────────────────

  Widget _buildPaymentHistoryContent() {
    final paidAppts = _appointments.where((a) {
      return (a.amountPaid ?? 0) > 0;
    }).toList()
      ..sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

    final totalPayment = paidAppts.fold<double>(
        0, (sum, appt) => sum + (appt.amountPaid ?? 0.0));

    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          // Total payment banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B1F3A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Payment',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalPayment.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.credit_card, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),

          // Transaction History section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.black87),
                          const SizedBox(width: 8),
                          Text('Transaction History',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                    Expanded(
                      child: paidAppts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F0F3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.description_outlined,
                                        size: 24,
                                        color: Color(0xFF3B1F3A)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('No payment history',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3B1F3A))),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Transactions for completed appointments will be listed here.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: paidAppts.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFF0F0F0)),
                              itemBuilder: (context, index) {
                                final appt = paidAppts[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appt.serviceName ??
                                                  'Unknown Service',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${DateFormat('MMM d, yyyy').format(appt.date ?? DateTime.now())} • ${appt.startTime ?? ''}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text('Paid',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 9,
                                                    color: Colors.black54)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '₹${(appt.amountPaid ?? 0).toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(IconData icon, String message, {String? subtitle}) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 10),
            Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade400)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.3)),
          const Divider(height: 10, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label,
      {Color valueColor = Colors.black87}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }

  ({Color bg, Color text}) _getStatusColors(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'confirmed':
        return (bg: const Color(0xFFE8F8EF), text: const Color(0xFF22A861));
      case 'completed':
        return (bg: const Color(0xFFE8F4FF), text: const Color(0xFF2563EB));
      case 'cancelled':
        return (bg: const Color(0xFFFDECEA), text: const Color(0xFFE03E3E));
      case 'scheduled':
        return (bg: const Color(0xFFFFF3E0), text: const Color(0xFFF57C00));
      default:
        return (bg: const Color(0xFFF0F0F0), text: Colors.grey);
    }
  }
}
