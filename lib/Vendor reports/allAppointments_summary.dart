import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../Notification.dart';
import '../my_Profile.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _Appointment {
  final String id;
  final String clientName;
  final String serviceName;
  final String staffName;
  final String date;
  final String startTime;
  final String endTime;
  final int duration;
  final double amount;
  final double totalAmount;
  final double platformFee;
  final double serviceTax;
  final double finalAmount;
  final String status;
  final String paymentStatus;
  final String mode;
  final bool isMultiService;

  _Appointment({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.amount,
    required this.totalAmount,
    required this.platformFee,
    required this.serviceTax,
    required this.finalAmount,
    required this.status,
    required this.paymentStatus,
    required this.mode,
    required this.isMultiService,
  });

  factory _Appointment.fromJson(Map<String, dynamic> j) {
    return _Appointment(
      id: j['id'] ?? '',
      clientName: j['clientName'] ?? '—',
      serviceName: j['serviceName'] ?? '—',
      staffName: j['staffName'] ?? '—',
      date: j['date'] ?? '',
      startTime: j['startTime'] ?? '—',
      endTime: j['endTime'] ?? '—',
      duration: (j['duration'] as num?)?.toInt() ?? 0,
      amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0.0,
      serviceTax: (j['serviceTax'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (j['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: j['status'] ?? 'pending',
      paymentStatus: j['paymentStatus'] ?? 'pending',
      mode: j['mode'] ?? 'offline',
      isMultiService: j['isMultiService'] ?? false,
    );
  }

  String get timeLabel => '$startTime – $endTime';
  
  String get formattedDate {
    if (date.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AllAppointmentsSummary extends StatefulWidget {
  const AllAppointmentsSummary({super.key});

  @override
  State<AllAppointmentsSummary> createState() => _AllAppointmentsSummaryState();
}

class _AllAppointmentsSummaryState extends State<AllAppointmentsSummary> {
  // ── constants ───────────────────────────────────────────────────────────────
  static const Color _purple = Color(0xFF6C3EB8);

  // ── state ───────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMsg;

  List<_Appointment> _all = [];
  List<_Appointment> _filtered = [];

  String _searchText = '';
  DateTimeRange? _dateRange;

  // pagination
  int _rowsPerPage = 10;
  int _currentPage = 0;

  final _searchCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final response = await ApiService.getAllAppointmentsReport(
        startDate: _dateRange != null
            ? DateFormat('yyyy-MM-dd').format(_dateRange!.start)
            : null,
        endDate: _dateRange != null
            ? DateFormat('yyyy-MM-dd').format(_dateRange!.end)
            : null,
      );

      // JSON Structure: { success, data: { allAppointments: { total, appointments: [...] } } }
      final allData = response['data']?['allAppointments'];
      final List<dynamic> rawList = (allData?['appointments'] as List?) ?? [];

      _all = rawList.map((j) => _Appointment.fromJson(j)).toList();
      _applyFilter();
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _searchText.toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = _all.where((a) {
        return a.clientName.toLowerCase().contains(q) ||
               a.serviceName.toLowerCase().contains(q) ||
               a.staffName.toLowerCase().contains(q);
      }).toList();
    });
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  double get _totalRevenue => _filtered.fold(0, (sum, a) => sum + a.finalAmount);
  int get _onlineCount => _filtered.where((a) => a.mode.toLowerCase() == 'online').length;
  int get _offlineCount => _filtered.where((a) => a.mode.toLowerCase() == 'offline').length;

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmtCompact(num v) => '₹${NumberFormat('#,##0').format(v)}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateRange = picked;
      _fetchData();
    }
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  List<_Appointment> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Stats Row
            Row(
              children: [
                _statCard('Total Bookings', '${_filtered.length}', Icons.event_available_rounded, Colors.blue),
                SizedBox(width: 10.w),
                _statCard('Total Revenue', _fmtCompact(_totalRevenue), Icons.payments_rounded, Colors.green),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _statCard('Online Mode', '$_onlineCount', Icons.language_rounded, _purple),
                SizedBox(width: 10.w),
                _statCard('Offline Mode', '$_offlineCount', Icons.storefront_rounded, Colors.orange),
              ],
            ),
            SizedBox(height: 16.h),

            // Report Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('All Appointments Report',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                          Text('List of all appointments with status and payment tracking.',
                              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),

                    // Toolbar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38.h,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) { _searchText = v; _applyFilter(); },
                                style: GoogleFonts.poppins(fontSize: 13),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                                  hintText: 'Search client, service, staff…',
                                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F6FA),
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          _toolbarBtn(
                            icon: Icons.filter_list_rounded,
                            label: _dateRange != null ? 'Filtered' : 'Date Range',
                            isActive: _dateRange != null,
                            onTap: _pickDateRange,
                          ),
                          SizedBox(width: 10.w),
                          _toolbarBtn(
                            icon: Icons.refresh_rounded,
                            label: '',
                            onTap: _fetchData,
                            isIconOnly: true,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),

                    // Table
                    Expanded(child: _buildTable()),

                    // Footer
                    Divider(height: 1, color: Colors.grey.shade100),
                    _buildPaginationFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60.h,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
      ),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('All Appointments',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const My_Profile())),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _purple, width: 1.5)),
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
    );
  }

  Widget _buildTable() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _purple));
    if (_errorMsg != null) return _buildErrorState();
    if (_filtered.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        // Table Header
        Container(
          color: const Color(0xFFF9F9FB),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              _hCell('Client / Service', flex: 4),
              _hCell('Staff / Time', flex: 3),
              _hCell('Status / Mode', flex: 3),
              _hCell('Final Amount', flex: 2, right: true),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // Table Rows
        Expanded(
          child: ListView.separated(
            itemCount: _pageItems.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) => _buildRow(_pageItems[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_Appointment a, int idx) {
    return Container(
      color: idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFF),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          // Client & Service
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.clientName,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87),
                    overflow: TextOverflow.ellipsis),
                Text(a.serviceName,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Staff & Time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.staffName,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
                Text(a.timeLabel,
                    style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
          // Status & Mode
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(a.status),
                const SizedBox(height: 4),
                _modeBadge(a.mode),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(_fmtCurrency(a.finalAmount),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _purple)),
          ),
        ],
      ),
    );
  }

  // ── Table Helpers ───────────────────────────────────────────────────────────
  Widget _hCell(String label, {int flex = 1, bool right = false}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    );
  }

  String _fmtCurrency(num v) => '₹${NumberFormat('#,##0').format(v)}';

  Widget _statusBadge(String status) {
    status = status.toLowerCase();
    Color bg, fg;
    if (status == 'completed') { bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32); }
    else if (status == 'scheduled') { bg = const Color(0xFFE3F2FD); fg = const Color(0xFF1565C0); }
    else if (status == 'cancelled') { bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828); }
    else if (status == 'temp-locked') { bg = const Color(0xFFFFF3E0); fg = const Color(0xFFEF6C00); }
    else { bg = const Color(0xFFF5F5F5); fg = const Color(0xFF757575); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _modeBadge(String mode) {
    final isOnline = mode.toLowerCase() == 'online';
    return Row(
      children: [
        Icon(isOnline ? Icons.language_rounded : Icons.storefront_rounded,
            size: 11, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(mode.toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
      ],
    );
  }

  // ── Generic States ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_rounded, size: 50, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No appointments found', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 50, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text('Oops! Failed to load data', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        Padding(padding: const EdgeInsets.all(16), child: Text(_errorMsg!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))),
        ElevatedButton(onPressed: _fetchData, style: ElevatedButton.styleFrom(backgroundColor: _purple), child: const Text('Retry', style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildPaginationFooter() {
    final start = _filtered.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Text('Showing $start–$end of ${_filtered.length}',
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500)),
          const Spacer(),
          _pageBtn(Icons.chevron_left_rounded, _currentPage > 0, () => setState(() => _currentPage--)),
          SizedBox(width: 8.w),
          _pageBtn(Icons.chevron_right_rounded, _currentPage < _totalPages - 1, () => setState(() => _currentPage++)),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6), color: enabled ? Colors.white : const Color(0xFFF5F6FA)),
        child: Icon(icon, size: 18, color: enabled ? Colors.black54 : Colors.grey.shade200),
      ),
    );
  }

  // ── Components ──────────────────────────────────────────────────────────────
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 16, color: color)),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false, bool isIconOnly = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 8 : 12),
        decoration: BoxDecoration(
          color: isActive ? _purple.withOpacity(0.08) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? _purple : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? _purple : Colors.grey.shade600),
            if (!isIconOnly) ...[const SizedBox(width: 6), Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isActive ? _purple : Colors.grey.shade600, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))],
          ],
        ),
      ),
    );
  }
}
