import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class SettlementSummary extends StatefulWidget {
  const SettlementSummary({super.key});

  @override
  State<SettlementSummary> createState() => _SettlementSummaryState();
}

class _SettlementSummaryState extends State<SettlementSummary> {
  static const Color _purple = Color(0xFF6C3EB8);

  bool _isLoading = false;
  String? _errorMsg;

  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _transfers = [];
  Map<String, dynamic> _totals = {};

  String _searchText = '';
  final _searchCtrl = TextEditingController();

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
      final response = await ApiService.getSettlementSummaryReport();
      final block = response['data']?['settlementSummary'] as Map<String, dynamic>?;

      if (block != null) {
        _appointments = (block['appointments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _transfers = (block['transfers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _totals = (block['totals'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransfers {
    if (_searchText.isEmpty) return _transfers;
    final q = _searchText.toLowerCase();
    return _transfers.where((t) {
      final type = (t['type'] ?? '').toString().toLowerCase();
      final method = (t['paymentMethod'] ?? '').toString().toLowerCase();
      return type.contains(q) || method.contains(q);
    }).toList();
  }

  String _fmt(num v) => '₹${NumberFormat('#,##0').format(v)}';
  double _n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : _errorMsg != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      SizedBox(height: 12.h),
                      _buildTitledSection('Money Transfers', _buildTransfersTable()),
                      SizedBox(height: 12.h),
                      _buildTitledSection('Detailed Settlements', _buildAppointmentsTable()),
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
      toolbarHeight: 50.h,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Settlement Summary',
                style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          _toolbarBtn(icon: Icons.refresh_rounded, label: '', onTap: _fetchData, isIconOnly: true),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final owed = _n(_totals['totalAdminOwesVendor']);
    final payable = _n(_totals['totalVendorOwesAdmin']);
    final balance = _n(_totals['finalBalance']);
    return Row(
      children: [
        _statCard('Owed to You', _fmt(owed), Icons.arrow_downward_rounded, Colors.green),
        SizedBox(width: 8.w),
        _statCard('Payable to Admin', _fmt(payable), Icons.arrow_upward_rounded, Colors.red),
        SizedBox(width: 8.w),
        _statCard('Net Balance', _fmt(balance.abs()), Icons.account_balance_wallet_rounded, _purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 12, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 12, color: color)),
            SizedBox(height: 6.h),
            Text(value, style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text(label, style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTitledSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))]),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTransfersTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9FB)),
        headingTextStyle: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        dataTextStyle: GoogleFonts.poppins(fontSize: 9.sp, color: Colors.black87),
        columnSpacing: 15.w,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Method')),
          DataColumn(label: Text('Amount')),
        ],
        rows: _filteredTransfers.map((t) {
          final isOut = (t['type'] as String? ?? '').toLowerCase().contains('admin');
          return DataRow(cells: [
            DataCell(Text(t['paymentDate'] != null ? DateFormat('dd MMM yy').format(DateTime.parse(t['paymentDate'])) : '—')),
            DataCell(Text(t['type']?.toString().toUpperCase() ?? '—')),
            DataCell(Text(t['paymentMethod'] ?? '—')),
            DataCell(Text(_fmt(_n(t['amount'])), style: TextStyle(fontWeight: FontWeight.bold, color: isOut ? Colors.red : Colors.green))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildAppointmentsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9FB)),
        headingTextStyle: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        dataTextStyle: GoogleFonts.poppins(fontSize: 9.sp, color: Colors.black87),
        columnSpacing: 15.w,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Owed')),
          DataColumn(label: Text('Payable')),
        ],
        rows: _appointments.map((a) {
          return DataRow(cells: [
            DataCell(Text(a['date'] != null ? DateFormat('dd MMM yy').format(DateTime.parse(a['date'])) : '—')),
            DataCell(Text(a['clientName'] ?? '—')),
            DataCell(Text(_fmt(_n(a['adminOwesVendor'])), style: const TextStyle(color: Colors.green))),
            DataCell(Text(_fmt(_n(a['vendorOwesAdmin'])), style: const TextStyle(color: Colors.red))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 40.sp, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text('Failed to load data', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.sp)),
          Text(_errorMsg!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchData, style: ElevatedButton.styleFrom(backgroundColor: _purple), child: const Text('Retry', style: TextStyle(color: Colors.white))),
        ]),
      ),
    );
  }

  Widget _toolbarBtn({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false, bool isIconOnly = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 8 : 10),
        decoration: BoxDecoration(
          color: isActive ? _purple.withOpacity(0.08) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? _purple : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? _purple : Colors.grey.shade600),
            if (!isIconOnly) ...[const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 9.sp, color: isActive ? _purple : Colors.grey.shade600, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))],
          ],
        ),
      ),
    );
  }
}
