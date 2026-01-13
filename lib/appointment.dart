import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'book_Apointment.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'appointment_model.dart';
import 'widgets/appointment_detail_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
      print('📥 Fetching appointments from API...');
      final appointments = await ApiService.getAppointments();

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
              side: BorderSide(color: Colors.black54),
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
    Color bgColor;
    switch (status.toLowerCase()) {
      case "new":
        bgColor = Colors.orange;
        break;
      case "completed":
        bgColor = Colors.green;
        break;
      case "cancelled":
        bgColor = Colors.red;
        break;
      case "confirmed":
        bgColor = Colors.blue;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        border: Border.all(color: bgColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );
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
                  child: const CircleAvatar(
                    radius: 17,
                    backgroundImage: AssetImage('assets/images/profile.jpeg'),
                    backgroundColor: Colors.white,
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.event, color: Colors.blue, size: 18),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_filteredAppointments.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
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
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
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
                            child: Text("No appointments found.",
                                style: GoogleFonts.poppins(fontSize: 13)))
                        : Column(
                            children: _filteredAppointments.map((appointment) {
                              return _buildAppointmentCard(appointment);
                            }).toList(),
                          ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookAppointment()),
          );
        },
        backgroundColor: Colors.blue,
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

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    // Format date and time
    final scheduledDate = appointment.date != null
        ? DateFormat('MMM d, yyyy').format(appointment.date!)
        : 'No date';
    final timeRange =
        '${appointment.startTime ?? '--'}  - ${appointment.endTime ?? '--'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(appointment.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit feature coming soon!')),
                );
              },
              backgroundColor: const Color(0xFF21B7CA),
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (context) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Appointment'),
                    content: const Text(
                        'Are you sure you want to delete this appointment?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (appointment.id != null) {
                            _deleteAppointment(appointment.id!);
                          }
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              backgroundColor: const Color(0xFFFE4A49),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            if (appointment.id != null) {
              showDialog(
                context: context,
                builder: (context) => AppointmentDetailDialog(
                  appointmentId: appointment.id!,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          appointment.paymentMethod ?? 'unpaid',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    _buildStatusTag(appointment.status ?? 'Unknown'),
                  ],
                ),
                const SizedBox(height: 10),
                // Client and service
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.clientName ?? 'Unknown Client',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            appointment.serviceName ?? 'Unknown Service',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Staff and price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          appointment.staffName ?? 'Unassigned',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '\u20b9${appointment.amount?.toStringAsFixed(0) ?? '0'}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Schedule info
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$scheduledDate • $timeRange',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      Text(
                        '${appointment.duration ?? 0} mins',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleting appointment...')),
      );

      await ApiService.deleteAppointment(id);

      // Refresh list
      await _fetchAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
