import 'package:flutter/material.dart';
import 'package:glowvita/widgets/create_appointment_form.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'appointment_model.dart';
import 'services/api_service.dart';
import 'widgets/collect_payment_dialog.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

enum QuickDateRange {
  today,
  tomorrow,
  yesterday,
  next7Days,
  last7Days,
  next30Days,
  last30Days,
  last90Days,
  lastMonth,
  lastYear,
  allTime,
}

class Appointment extends StatefulWidget {
  const Appointment({super.key});

  @override
  State<Appointment> createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? _selectedDateRange;
  String? _selectedClient, _selectedService, _selectedStaff;
  String _selectedStatus = 'All';

  // Dynamic data from API
  List<AppointmentModel> _apiAppointments = [];
  bool _isLoading = true;
  Set<String> _uniqueClients = {};
  Set<String> _uniqueServices = {};
  Set<String> _uniqueStaff = {};

  // Pagination state
  int _currentPage = 1;
  int _limit = 10;
  final List<int> _limitOptions = [5, 10, 15, 20, 25, 50];

  final List<String> statuses = [
    'All',
    'scheduled',
    'confirmed',
    'in_progress',
    'completed',
    'completed_without_payment',
    'cancelled',
    'pending'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      print(
          '📥 Fetching appointments from API (Page: $_currentPage, Limit: $_limit)...');
      final appointments =
          await ApiService.getAppointments(page: _currentPage, limit: _limit);

      setState(() {
        _apiAppointments = appointments;
        _isLoading = false;

        // Extract unique values for filters
        _uniqueClients = appointments
            .map((a) => a.clientName ?? 'Unknown')
            .where((name) => name.isNotEmpty)
            .toSet();

        _uniqueServices = appointments
            .map((a) => a.serviceName ?? 'Unknown')
            .where((name) => name.isNotEmpty)
            .toSet();

        _uniqueStaff = appointments
            .map((a) => a.staffName ?? 'Unassigned')
            .where((name) => name.isNotEmpty)
            .toSet();
      });

      print('✅ Loaded ${appointments.length} appointments');
    } catch (e) {
      print('❌ Error fetching appointments: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  List<AppointmentModel> get _filteredAppointments {
    return _apiAppointments.where((appt) {
      // Date filtering
      final scheduled = appt.date;
      final inRange = _selectedDateRange == null ||
          scheduled == null ||
          (scheduled.isAfter(
                  _selectedDateRange!.start.subtract(Duration(days: 1))) &&
              scheduled
                  .isBefore(_selectedDateRange!.end.add(Duration(days: 1))));

      // Client filtering
      final clientMatch =
          _selectedClient == null || appt.clientName == _selectedClient;

      // Service filtering
      final serviceMatch =
          _selectedService == null || appt.serviceName == _selectedService;

      // Staff filtering
      final staffMatch =
          _selectedStaff == null || appt.staffName == _selectedStaff;

      // Status filtering
      final statusMatch = _selectedStatus == 'All' ||
          (appt.status?.toLowerCase() == _selectedStatus.toLowerCase());

      return inRange &&
          clientMatch &&
          serviceMatch &&
          staffMatch &&
          statusMatch;
    }).toList();
  }

  Widget _buildDropdown<T>({
    required String hint,
    required List<T> items,
    T? selectedValue,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: selectedValue,
        hint: Text(hint, style: GoogleFonts.poppins(fontSize: 12)),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.toString(),
                      style: GoogleFonts.poppins(fontSize: 12)),
                ))
            .toList(),
        onChanged: onChanged,
      );
  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          // Styled Quick Ranges dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<QuickDateRange>(
              underline: SizedBox(),
              hint: Text("Quick Ranges",
                  style:
                      GoogleFonts.poppins(color: Colors.black, fontSize: 11)),
              onChanged: (range) {
                if (range == null) return;
                final now = DateTime.now();
                DateTime start, end;
                switch (range) {
                  case QuickDateRange.today:
                    start = end = now;
                    break;
                  case QuickDateRange.tomorrow:
                    start = end = now.add(Duration(days: 1));
                    break;
                  case QuickDateRange.yesterday:
                    start = end = now.subtract(Duration(days: 1));
                    break;
                  case QuickDateRange.next7Days:
                    start = now;
                    end = now.add(Duration(days: 7));
                    break;
                  case QuickDateRange.last7Days:
                    start = now.subtract(Duration(days: 7));
                    end = now;
                    break;
                  case QuickDateRange.next30Days:
                    start = now;
                    end = now.add(Duration(days: 30));
                    break;
                  case QuickDateRange.last30Days:
                    start = now.subtract(Duration(days: 30));
                    end = now;
                    break;
                  case QuickDateRange.last90Days:
                    start = now.subtract(Duration(days: 90));
                    end = now;
                    break;
                  case QuickDateRange.lastMonth:
                    start = DateTime(now.year, now.month - 1, 1);
                    end = DateTime(now.year, now.month, 0);
                    break;
                  case QuickDateRange.lastYear:
                    start = DateTime(now.year - 1, 1, 1);
                    end = DateTime(now.year - 1, 12, 31);
                    break;
                  case QuickDateRange.allTime:
                  default:
                    start = DateTime(2000);
                    end = DateTime(2100);
                }
                setState(() =>
                    _selectedDateRange = DateTimeRange(start: start, end: end));
              },
              items: QuickDateRange.values.map((e) {
                final label = e.name
                    .replaceAllMapped(
                        RegExp(r'([a-z])([A-Z])'), (m) => "${m[1]} ${m[2]}")
                    .capitalize();
                return DropdownMenuItem(
                  value: e,
                  child: Text(label, style: GoogleFonts.poppins(fontSize: 11)),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 8),

          // Styled Pick Range button - reduced size
          ElevatedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range, size: 16),
            label: Text(
              _selectedDateRange != null
                  ? "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}"
                  : "Pick Range",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side:
                  BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size(0, 30),
            ),
          ),

          const Spacer(),

          IconButton(
            icon: const Icon(Icons.clear, color: Colors.black, size: 18),
            tooltip: "Clear Date Filter",
            onPressed: () => setState(() => _selectedDateRange = null),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'schedule':
        color = Colors.orange.shade700;
        break;
      case 'confirmed':
        color = Theme.of(context).primaryColor;
        break;
      case 'completed':
        color = Colors.green.shade700;
        break;
      case 'cancelled':
        color = Colors.red.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        status.capitalize(),
        style: GoogleFonts.poppins(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPaymentTag(AppointmentModel appt) {
    final paid = appt.amountPaid ?? 0;
    final total = appt.totalAmount ?? appt.amount ?? 0;

    String label;
    Color color;

    if (paid >= total && total > 0) {
      label = "PAID";
      color = Colors.green.shade600;
    } else if (paid > 0) {
      label = "PARTIALLY PAID (₹${paid.toStringAsFixed(0)})";
      color = Colors.orange.shade600;
    } else {
      label = "UNPAID";
      color = Colors.red.shade400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appt) {
    final cardStyle = GoogleFonts.poppins(fontSize: 13, color: Colors.black87);
    final subStyle =
        GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600);

    final dateStr =
        appt.date != null ? DateFormat('MMM d, yyyy').format(appt.date!) : '-';
    final timeStr = '${appt.startTime ?? '--'} - ${appt.endTime ?? '--'}';

    final items = appt.serviceItems ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Client & Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.clientName ?? 'Unknown Client',
                          style: cardStyle.copyWith(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('$dateStr • $timeStr', style: subStyle),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusTag(appt.status ?? 'Schedule'),
              ],
            ),
          ),

          // Services Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SERVICES & STAFF',
                    style: subStyle.copyWith(
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...items.isEmpty
                    ? [Text(appt.serviceName ?? '—', style: cardStyle)]
                    : items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.serviceName} (${item.duration} min)',
                                  style: cardStyle.copyWith(fontSize: 12.5),
                                ),
                              ),
                              Text(
                                item.staffName ?? '—',
                                style: subStyle.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ],
            ),
          ),

          // Footer: Payment & Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPaymentTag(appt),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Paid: ',
                            style: subStyle.copyWith(fontSize: 10),
                          ),
                          TextSpan(
                            text:
                                '₹${appt.amountPaid?.toStringAsFixed(2) ?? '0.00'}',
                            style: cardStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Total: ',
                            style: subStyle.copyWith(fontSize: 10),
                          ),
                          TextSpan(
                            text:
                                '₹${(appt.totalAmount ?? appt.amount ?? 0).toStringAsFixed(2)}',
                            style: cardStyle.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(appt.paymentMethod ?? 'Pay at Salon', style: subStyle),
                  ],
                ),
              ],
            ),
          ),

          // Divider and Mini Action Bar
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if ((appt.amountPaid ?? 0) <
                        (appt.totalAmount ?? appt.amount ?? 0) &&
                    !(appt.status?.toLowerCase().contains('cancelled') ??
                        false) &&
                    !(appt.status?.toLowerCase().contains('completed') ??
                        false))
                  _actionIcon(Icons.payments_outlined, Colors.green, () {
                    _showCollectPaymentDialog(appt);
                  }, label: 'Pay'),
                _actionIcon(Icons.edit_outlined, Theme.of(context).primaryColor,
                    () {
                  _editAppointment(appt);
                }, label: 'Edit'),
                _actionIcon(Icons.delete_outline, Colors.red, () {
                  _confirmDelete(appt);
                }, label: 'Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap,
      {String? label}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editAppointment(AppointmentModel appt) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CreateAppointmentForm(
              existingAppointment: appt,
            ),
          ),
        )
        .then((_) => _fetchAppointments());
  }

  void _confirmDelete(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content:
            const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (appt.id != null) {
                _deleteAppointment(appt.id!);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCollectPaymentDialog(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (context) => CollectPaymentDialog(appointment: appt),
    ).then((result) {
      if (result != null) {
        print('Payment Collected: $result');
        // TODO: Call API to save payment
        // For now, reload appointments to reflect any changes if API was called
        _fetchAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Appointments'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50.h,
        titleSpacing: 0,
        automaticallyImplyLeading: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 22),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            // Back Button removed since drawer provides navigation
            Text('All Appointment',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),

            Spacer(), // Pushes buttons to the right

            SizedBox(width: 15),

            IconButton(
              icon: Icon(Icons.notifications, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()),
                );
              },
            ),

            SizedBox(width: 15),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Container(
                  padding: EdgeInsets.all(1.5.w), // Border width
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 1.w,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundImage: AssetImage('assets/images/profile.jpeg'),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search appointments...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              // Single filter row for status
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Status filter dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          underline: const SizedBox(),
                          items: statuses
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
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Stats cards
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(12),
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
                                  Icons.event_available,
                                  size: 14,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Today',
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
                              '${_getTodayCount()}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
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
                        padding: const EdgeInsets.all(12),
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
                                  size: 14,
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
                                fontSize: 14,
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
              SizedBox(height: 12),
              // Count card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.event,
                          color: Theme.of(context).primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appointments',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                          Text(
                              '${_filteredAppointments.length} appointments in total',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              )),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_filteredAppointments.length}',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          )),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Filter tabs
              SizedBox(
                height: 16,
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.black54,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                tabs: const [
                  Tab(text: "Clients"),
                  Tab(text: "Services"),
                  Tab(text: "Staff"),
                  Tab(text: "Date"),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 80,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDropdown(
                        hint: "Select Client",
                        items: _uniqueClients.toList(),
                        selectedValue: _selectedClient,
                        onChanged: (v) => setState(() => _selectedClient = v)),
                    _buildDropdown(
                        hint: "Select Service",
                        items: _uniqueServices.toList(),
                        selectedValue: _selectedService,
                        onChanged: (v) => setState(() => _selectedService = v)),
                    _buildDropdown(
                        hint: "Select Staff",
                        items: _uniqueStaff.toList(),
                        selectedValue: _selectedStaff,
                        onChanged: (v) => setState(() => _selectedStaff = v)),
                    _buildDateRangeSelector(),
                  ],
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedClient = null;
                    _selectedService = null;
                    _selectedStaff = null;
                    _selectedStatus = 'All';
                    _selectedDateRange = null;
                  });
                },
                child: Text("Clear All Filters",
                    style: GoogleFonts.poppins(fontSize: 12)),
              ),

              SizedBox(height: 8),

              // Appointments list header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointments List',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              // Appointments cards
              // Appointments list
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _filteredAppointments.isEmpty
                        ? Center(
                            child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text("No appointments found.",
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _filteredAppointments.map((appointment) {
                              return _buildAppointmentCard(appointment);
                            }).toList(),
                          ),
              ),

              // Pagination Controls
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text("Show",
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _limit,
                              items: _limitOptions.map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString(),
                                      style: GoogleFonts.poppins(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _limit = newValue;
                                    _currentPage = 1;
                                    _isLoading = true;
                                  });
                                  _fetchAppointments();
                                }
                              },
                              icon: const Icon(Icons.arrow_drop_down, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                    _isLoading = true;
                                  });
                                  _fetchAppointments();
                                }
                              : null,
                        ),
                        Text("Page $_currentPage",
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _apiAppointments.length >= _limit
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                    _isLoading = true;
                                  });
                                  _fetchAppointments();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAppointmentForm()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, size: 26, color: Colors.white),
        tooltip: 'Add Appointment',
      ),
    );
  }

  int _getTodayCount() {
    final today = DateTime.now();
    return _apiAppointments.where((appt) {
      final scheduled = appt.date;
      if (scheduled == null) return false;
      return scheduled.year == today.year &&
          scheduled.month == today.month &&
          scheduled.day == today.day;
    }).length;
  }

  int _getPendingCount() {
    return _apiAppointments
        .where((appt) =>
            appt.status?.toLowerCase() == 'pending' ||
            appt.status?.toLowerCase() == 'scheduled')
        .length;
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      print('🗑️ Deleting appointment with ID: $id');
      await ApiService.deleteAppointment(id);

      // Refresh list
      await _fetchAppointments();
      print('✅ Appointment deleted successfully');
    } catch (e) {
      print('❌ Failed to delete appointment: $e');
    }
  }
}
