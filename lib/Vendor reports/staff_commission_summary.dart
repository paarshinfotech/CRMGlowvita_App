import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../Notification.dart';
import '../my_Profile.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class _StaffCommission {
  final String staffId;
  final String staffName;
  final String commissionRate;
  final num totalCommissionEarned;
  final num totalPaidOut;
  final num netCommissionBalance;
  final int commissionCount;
  final String lastTransactionDate;
  final List<_Transaction> transactions;

  _StaffCommission({
    required this.staffId,
    required this.staffName,
    required this.commissionRate,
    required this.totalCommissionEarned,
    required this.totalPaidOut,
    required this.netCommissionBalance,
    required this.commissionCount,
    required this.lastTransactionDate,
    required this.transactions,
  });

  factory _StaffCommission.fromJson(Map<String, dynamic> j) {
    final txList = (j['transactions'] as List? ?? [])
        .map((t) => _Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    return _StaffCommission(
      staffId: j['staffId'] ?? '',
      staffName: j['staffName'] ?? '',
      commissionRate: j['commissionRate'] ?? '0%',
      totalCommissionEarned: (j['totalCommissionEarned'] as num?) ?? 0,
      totalPaidOut: (j['totalPaidOut'] as num?) ?? 0,
      netCommissionBalance: (j['netCommissionBalance'] as num?) ?? 0,
      commissionCount: (j['commissionCount'] as num?)?.toInt() ?? 0,
      lastTransactionDate: j['lastTransactionDate'] ?? 'N/A',
      transactions: txList,
    );
  }
}

class _Transaction {
  final String transactionId;
  final String transactionDate;
  final String appointmentId;
  final String client;
  final String serviceName;
  final num appointmentAmount;
  final num commissionRate;
  final num commissionEarned;
  final String type;
  final String notes;

  _Transaction({
    required this.transactionId,
    required this.transactionDate,
    required this.appointmentId,
    required this.client,
    required this.serviceName,
    required this.appointmentAmount,
    required this.commissionRate,
    required this.commissionEarned,
    required this.type,
    required this.notes,
  });

  factory _Transaction.fromJson(Map<String, dynamic> j) {
    return _Transaction(
      transactionId: j['transactionId'] ?? '',
      transactionDate: j['transactionDate'] ?? '',
      appointmentId: j['appointmentId'] ?? '-',
      client: j['client'] ?? '-',
      serviceName: j['serviceName'] ?? '',
      appointmentAmount: (j['appointmentAmount'] as num?) ?? 0,
      commissionRate: (j['commissionRate'] as num?) ?? 0,
      commissionEarned: (j['commissionEarned'] as num?) ?? 0,
      type: j['type'] ?? '',
      notes: j['notes'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class StaffCommissionSummary extends StatefulWidget {
  const StaffCommissionSummary({super.key});

  @override
  State<StaffCommissionSummary> createState() => _StaffCommissionSummaryState();
}

class _StaffCommissionSummaryState extends State<StaffCommissionSummary> {
  // ── state ───────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMsg;
  List<_StaffCommission> _all = [];
  List<_StaffCommission> _filtered = [];
  String _searchText = '';
  DateTimeRange? _dateRange;

  // pagination
  int _rowsPerPage = 10;
  int _currentPage = 0;

  static const Color _purple = Color(0xFF6C3EB8);
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
      final raw = await ApiService.getStaffCommissionReport(
        startDate: _dateRange != null
            ? DateFormat('yyyy-MM-dd').format(_dateRange!.start)
            : null,
        endDate: _dateRange != null
            ? DateFormat('yyyy-MM-dd').format(_dateRange!.end)
            : null,
      );
      _all = raw
          .map((e) => _StaffCommission.fromJson(e as Map<String, dynamic>))
          .toList();
      _applyFilter();
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _currentPage = 0;
      _filtered = _all.where((s) {
        final q = _searchText.toLowerCase();
        return s.staffName.toLowerCase().contains(q);
      }).toList();
    });
  }

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
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

  void _clearDateRange() {
    _dateRange = null;
    _fetchData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // helpers
  String _fmt(num v) => '₹${NumberFormat('#,##0.00').format(v)}';

  String _dateLabel(String raw) {
    if (raw == 'N/A' || raw.isEmpty) return 'N/A';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // pagination helpers
  List<_StaffCommission> get _pageItems {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ─────────────────────────────────────────────────────────────────────────
  // build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60.h,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Staff Commission Report',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.black87),
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
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _purple, width: 1.5),
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
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Report card wrapper ─────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header (title + subtitle) ─────────────────────────
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff Commission Report',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Detailed report showing commission earned by staff members for services provided.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),

                  // ── Toolbar (search + date + export) ─────────────────
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        // search
                        Expanded(
                          child: SizedBox(
                            height: 40.h,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) {
                                _searchText = v;
                                _applyFilter();
                              },
                              style: GoogleFonts.poppins(fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: Color(0xFFAAAAAA), size: 20),
                                hintText: 'Search staff…',
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade400),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: _purple, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // date range chip
                        InkWell(
                          onTap: _pickDateRange,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 40.h,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _dateRange != null
                                  ? _purple.withOpacity(0.08)
                                  : const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _dateRange != null
                                    ? _purple
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.date_range_rounded,
                                  size: 16,
                                  color: _dateRange != null
                                      ? _purple
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _dateRange != null
                                      ? '${DateFormat('dd MMM').format(_dateRange!.start)} – ${DateFormat('dd MMM yy').format(_dateRange!.end)}'
                                      : 'Date Range',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _dateRange != null
                                        ? _purple
                                        : Colors.grey.shade600,
                                    fontWeight: _dateRange != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (_dateRange != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _clearDateRange,
                                    child: const Icon(Icons.close_rounded,
                                        size: 14, color: _purple),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // export button
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Export coming soon…')),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 40.h,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.upload_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Export',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),

                  // ── Table ────────────────────────────────────────────
                  Expanded(child: _buildTable()),

                  // ── Footer / Pagination ──────────────────────────────
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildPaginationFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _purple),
      );
    }
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Failed to load data',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No staff records found',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── column headers ────────────────────────────────────────────────
        Container(
          color: const Color(0xFFF9F9FB),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              _hCell('Staff Name', flex: 3),
              _hCell('Commission Rate', flex: 2),
              _hCell('Total Earned', flex: 2),
              _hCell('Total Paid Out', flex: 2),
              _hCell('Net Balance', flex: 2),
              _hCell('Commission\nCount', flex: 2),
              _hCell('Last Transaction', flex: 2),
              _hCell('Action', flex: 1),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // ── rows ──────────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            itemCount: _pageItems.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) => _buildRow(_pageItems[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_StaffCommission s, int idx) {
    final hasBalance = s.netCommissionBalance > 0;
    return Container(
      color: idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFF),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          // Staff Name
          Expanded(
            flex: 3,
            child: Text(
              s.staffName,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // Commission Rate
          Expanded(
            flex: 2,
            child: Text(
              s.commissionRate,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          // Total Earned
          Expanded(
            flex: 2,
            child: Text(
              _fmt(s.totalCommissionEarned),
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          // Total Paid Out
          Expanded(
            flex: 2,
            child: Text(
              _fmt(s.totalPaidOut),
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          // Net Balance (bold)
          Expanded(
            flex: 2,
            child: Text(
              _fmt(s.netCommissionBalance),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: hasBalance ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ),
          // Commission Count
          Expanded(
            flex: 2,
            child: Text(
              '${s.commissionCount}',
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          // Last Transaction
          Expanded(
            flex: 2,
            child: Text(
              _dateLabel(s.lastTransactionDate),
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          // Action
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () => _showDetailSheet(s),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBF8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: _purple),
                    const SizedBox(width: 4),
                    Text(
                      'View',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _purple,
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

  // ── Pagination Footer ───────────────────────────────────────────────────────
  Widget _buildPaginationFooter() {
    final start = _filtered.isEmpty ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Text(
            'Showing $start to $end of ${_filtered.length} results',
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade500),
          ),
          const Spacer(),
          // Rows per page
          Text('Rows per page ',
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: Colors.grey.shade500)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
              items: [5, 10, 20, 50]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _rowsPerPage = v;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
          SizedBox(width: 16.w),
          // Page label
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade600),
          ),
          SizedBox(width: 8.w),
          // Prev
          _pageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--),
          ),
          SizedBox(width: 4.w),
          // Next
          _pageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages - 1,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(
      {required IconData icon,
      required bool enabled,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: enabled ? Colors.white : const Color(0xFFF5F6FA),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black54 : Colors.grey.shade300,
        ),
      ),
    );
  }

  // ── Detail bottom sheet ─────────────────────────────────────────────────────
  void _showDetailSheet(_StaffCommission s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // sheet header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _purple.withOpacity(0.12),
                      child: Text(
                        s.staffName.isNotEmpty
                            ? s.staffName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.staffName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Commission Rate: ${s.commissionRate}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              // summary chips
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    _summaryChip(
                      label: 'Total Earned',
                      value: _fmt(s.totalCommissionEarned),
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF1565C0),
                    ),
                    SizedBox(width: 8.w),
                    _summaryChip(
                      label: 'Paid Out',
                      value: _fmt(s.totalPaidOut),
                      icon: Icons.payments_outlined,
                      color: const Color(0xFFC62828),
                    ),
                    SizedBox(width: 8.w),
                    _summaryChip(
                      label: 'Net Balance',
                      value: _fmt(s.netCommissionBalance),
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              // transaction list
              Expanded(
                child: s.transactions.isEmpty
                    ? Center(
                        child: Text('No transactions',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade400, fontSize: 13)))
                    : Column(
                        children: [
                          // headers
                          Container(
                            color: const Color(0xFFF9F9FB),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 10.h),
                            child: Row(
                              children: [
                                _hCell('Date', flex: 2),
                                _hCell('Service', flex: 4),
                                _hCell('Client', flex: 3),
                                _hCell('Commission', flex: 2),
                                _hCell('Type', flex: 2),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          Expanded(
                            child: ListView.separated(
                              controller: ctrl,
                              itemCount: s.transactions.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1, color: Colors.grey.shade100),
                              itemBuilder: (_, i) =>
                                  _buildTxRow(s.transactions[i], i),
                            ),
                          ),
                          // subtotal
                          Divider(height: 1, color: Colors.grey.shade200),
                          Container(
                            color: const Color(0xFFF0EBF8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: Text('Subtotal',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmt(s.totalCommissionEarned),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                                const Expanded(flex: 2, child: SizedBox()),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTxRow(_Transaction tx, int idx) {
    final isCredit = tx.type == 'CREDIT';
    return Container(
      color: idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFF),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _dateLabel(tx.transactionDate),
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              tx.serviceName,
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tx.client,
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${tx.commissionEarned}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCredit
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isCredit
                    ? const Color(0xFF2E7D32).withOpacity(0.1)
                    : const Color(0xFFC62828).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tx.type,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isCredit
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── helper widgets ──────────────────────────────────────────────────────────
  Widget _hCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
