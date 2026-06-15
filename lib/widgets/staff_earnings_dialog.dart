import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class StaffEarningsDialog extends StatefulWidget {
  final Map<String, dynamic> staff;

  const StaffEarningsDialog({Key? key, required this.staff}) : super(key: key);

  @override
  State<StaffEarningsDialog> createState() => _StaffEarningsDialogState();
}

class _StaffEarningsDialogState extends State<StaffEarningsDialog> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'Week', 'Month', 'Year'];

  final _payoutAmountController = TextEditingController();
  final _payoutNotesController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';

  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _payouts = [];
  List<dynamic> _commissions = [];
  String _errorMessage = '';

  // Theme Constants
  final Color _kPrimary = const Color(0xFF4A2C40);
  final Color _kPink = const Color(0xFFB33A6B);
  final Color _kBorder = const Color(0xFFE5E5E5);
  final Color _kLabel = const Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final earningsData = await ApiService.getStaffEarnings(widget.staff['id']);

      setState(() {
        _summary = earningsData['summary'] ?? {};
        _payouts = earningsData['payouts'] ?? [];
        _commissions = earningsData['commissionHistory'] ?? [];
        _isLoading = false;
        _recalculateSummary();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load earnings: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _recalculateSummary() {
    final filteredComms = _filteredCommissions;
    final filteredPayouts = _filteredPayouts;

    double totalEarned = 0;
    for (var c in filteredComms) {
      totalEarned += (c['commissionAmount'] ?? 0).toDouble();
    }

    double totalPaid = 0;
    for (var p in filteredPayouts) {
      totalPaid += (p['amount'] ?? 0).toDouble();
    }

    setState(() {
      _summary['totalEarned'] = totalEarned;
      _summary['totalPaid'] = totalPaid;
      _summary['balance'] = totalEarned - totalPaid;
      _summary['appointmentsCount'] = filteredComms.length;
    });
  }

  List<dynamic> get _filteredCommissions {
    if (_selectedFilter == 'All') return _commissions;
    final now = DateTime.now();
    return _commissions.where((c) {
      final dateStr = c['date'] ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;

      if (_selectedFilter == 'Today') {
        return date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
      } else if (_selectedFilter == 'Week') {
        final lastWeek = now.subtract(const Duration(days: 7));
        return date.isAfter(lastWeek);
      } else if (_selectedFilter == 'Month') {
        return date.month == now.month && date.year == now.year;
      } else if (_selectedFilter == 'Year') {
        return date.year == now.year;
      }
      return true;
    }).toList();
  }

  List<dynamic> get _filteredPayouts {
    if (_selectedFilter == 'All') return _payouts;
    final now = DateTime.now();
    return _payouts.where((p) {
      final dateStr = p['payoutDate'] ?? p['date'] ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;

      if (_selectedFilter == 'Today') {
        return date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
      } else if (_selectedFilter == 'Week') {
        final lastWeek = now.subtract(const Duration(days: 7));
        return date.isAfter(lastWeek);
      } else if (_selectedFilter == 'Month') {
        return date.month == now.month && date.year == now.year;
      } else if (_selectedFilter == 'Year') {
        return date.year == now.year;
      }
      return true;
    }).toList();
  }

  Future<void> _recordPayout() async {
    final amountText = _payoutAmountController.text.trim();
    if (amountText.isEmpty) {
      _snack('Please enter an amount', isError: true);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final now = DateTime.now();
      final payoutData = {
        "amount": amount,
        "paymentMethod": _selectedPaymentMethod,
        "notes": _payoutNotesController.text.trim(),
        "payoutDate": "${now.year}-${now.month}-${now.day}"
      };

      final response =
          await ApiService.recordStaffPayout(widget.staff['id'], payoutData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _payoutAmountController.clear();
        _payoutNotesController.clear();
        _snack('Payout recorded successfully', isError: false);
        await _fetchEarnings();
      } else {
        throw Exception('Failed to record payout: ${response.statusCode}');
      }
    } catch (e) {
      _snack('Error: ${e.toString()}', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  void dispose() {
    _payoutAmountController.dispose();
    _payoutNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW < 480 ? screenW - 16 : 420.0;
    final dialogH = MediaQuery.of(context).size.height * 0.88;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: dialogW,
          height: dialogH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header (Matches AddStaffDialog header exactly)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.staff['name'] ?? 'Staff Earnings',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Earnings, commissions & payout history',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F1F1)),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.poppins(color: Colors.red, fontSize: 10),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Filters row
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _filters.map((filter) {
                                        final isSel = _selectedFilter == filter;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() => _selectedFilter = filter);
                                            _recalculateSummary();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSel ? _kPrimary : Colors.transparent,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              filter,
                                              style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                                color: isSel ? Colors.white : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Row of three summary cards
                                _buildSummaryRow(),
                                const SizedBox(height: 16),

                                // Record New Payout form
                                _buildSectionHeader('RECORD NEW PAYOUT'),

                                _buildFieldLabel('PAYOUT AMOUNT', required: true),
                                _buildTextField(
                                  controller: _payoutAmountController,
                                  hintText: 'Enter amount to pay',
                                  keyboardType: TextInputType.number,
                                ),

                                _buildFieldLabel('PAYMENT METHOD', required: true),
                                _buildDropdown(),

                                _buildFieldLabel('NOTES', required: true),
                                _buildTextField(
                                  controller: _payoutNotesController,
                                  hintText: 'Extra payment details......',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _recordPayout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Record Payment',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Recent Payouts list
                                _buildSectionHeader('RECENT PAYOUTS'),
                                _buildRecentPayoutsSection(),
                                const SizedBox(height: 16),

                                // Recent Commissions list
                                _buildSectionHeader('RECENT COMMISSION HISTORY (Last 50 Appointments)'),
                                _buildRecentCommissionsSection(),
                              ],
                            ),
                          ),
              ),

              // Bottom close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final double totalEarned = (_summary['totalEarned'] ?? 0).toDouble();
    final double totalPaid = (_summary['totalPaid'] ?? 0).toDouble();
    final double balance = (_summary['balance'] ?? 0).toDouble();
    final int appointmentsCount = _summary['appointmentsCount'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'TOTAL EARNED',
            value: '₹ ${totalEarned.toStringAsFixed(0)}/-',
            subtitle: '$appointmentsCount Appointments',
            color: Colors.grey[50]!,
            borderColor: Colors.grey[300]!,
            textColor: _kPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            title: 'TOTAL PAID',
            value: '₹ ${totalPaid.toStringAsFixed(2)}',
            subtitle: '',
            color: const Color(0xFFFFF1F2),
            borderColor: const Color(0xFFFDA4AF),
            textColor: const Color(0xFFE11D48),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            title: 'BALANCE DUE',
            value: '₹ ${balance.toStringAsFixed(2)}',
            subtitle: '',
            color: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFF86EFAC),
            textColor: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 7, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentPayoutsSection() {
    final payouts = _filteredPayouts;
    if (payouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No payouts recorded yet.',
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final p = payouts[index];
        String dateStr = p['payoutDate'] ?? p['date'] ?? '';
        if (dateStr.length > 10) dateStr = dateStr.substring(0, 10);
        final methodStr = p['paymentMethod'] ?? p['method'] ?? '';
        final amount = (p['amount'] ?? 0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$dateStr ($methodStr)', style: GoogleFonts.poppins(fontSize: 9, color: Colors.black87)),
              Text('-₹${amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentCommissionsSection() {
    final comms = _filteredCommissions;
    if (comms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No completed appointments with commission found.',
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comms.length,
      itemBuilder: (context, index) {
        final c = comms[index];
        String dateStr = c['date'] ?? '';
        if (dateStr.length > 10) dateStr = dateStr.substring(0, 10);
        final serviceName = c['serviceName'] ?? 'Service';
        final commEarned = (c['commissionAmount'] ?? 0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$dateStr - $serviceName', style: GoogleFonts.poppins(fontSize: 9, color: Colors.black87)),
              Text('+₹${commEarned.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _kPink,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: _kPink.withOpacity(0.3), height: 1)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _kLabel,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 8, color: Colors.red),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPaymentMethod,
          isExpanded: true,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
          items: ['Cash', 'Bank Transfer', 'UPI', 'Cheque'].map((String method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Text(method, style: GoogleFonts.poppins(fontSize: 10)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
        ),
      ),
    );
  }
}
