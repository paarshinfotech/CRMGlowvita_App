import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart'; // Add missing api import

class StaffEarningsDialog extends StatefulWidget {
  final Map<String, dynamic> staff;

  const StaffEarningsDialog({Key? key, required this.staff}) : super(key: key);

  @override
  State<StaffEarningsDialog> createState() => _StaffEarningsDialogState();
}

class _StaffEarningsDialogState extends State<StaffEarningsDialog> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['Today', 'Week', 'Month', 'Year', 'All'];

  final _payoutAmountController = TextEditingController();
  final _payoutNotesController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';

  // Add ApiService import at the top
  // Add state variables for the earnings data
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _payouts = [];
  List<dynamic> _commissions = [];
  String _errorMessage = '';

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

      final earningsData =
          await ApiService.getStaffEarnings(widget.staff['id']);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payout recorded successfully'),
              backgroundColor: Colors.green),
        );
        await _fetchEarnings();
      } else {
        throw Exception('Failed to record payout: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
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
    final dialogW = screenW < 960 ? screenW - 32 : 920.0;
    final dialogH = MediaQuery.of(context).size.height * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogW,
        height: dialogH,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filters Row
                              _buildFilters(),
                              const SizedBox(height: 24),

                              // Summary Cards
                              _buildSummaryCards(),
                              const SizedBox(height: 24),

                              // Main Content
                              if (dialogW < 600) ...[
                                // Stack vertically on smaller screens
                                _buildRecordPayoutForm(),
                                const SizedBox(height: 24),
                                _buildRecentPayouts(),
                              ] else ...[
                                // Side by side on larger screens
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildRecordPayoutForm(),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 3,
                                      child: _buildRecentPayouts(),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Bottom Section: Commission History
                              _buildCommissionHistory(),
                            ],
                          ),
                        ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _fetchEarnings,
            icon: const Icon(Icons.sync, size: 16, color: Color(0xFF1F2937)),
            label: Text(
              'Sync History',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) {
            bool isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
                _recalculateSummary();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF4A2C40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final double totalEarned = (_summary['totalEarned'] ?? 0).toDouble();
    final double totalPaid = (_summary['totalPaid'] ?? 0).toDouble();
    final double balance = (_summary['balance'] ?? 0).toDouble();
    final int appointmentsCount = _summary['appointmentsCount'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardList = [
          _buildSummaryCard(
            title: 'TOTAL EARNED',
            value: '₹ ${totalEarned.toStringAsFixed(2)}',
            subtitle: '$appointmentsCount Appointments',
            color: const Color(0xFFF9FAFB),
            textColor: const Color(0xFF1F2937),
          ),
          _buildSummaryCard(
            title: 'TOTAL PAID',
            value: '₹ ${totalPaid.toStringAsFixed(2)}',
            subtitle: '',
            color: const Color(0xFFFFF1F2),
            textColor: const Color(0xFFE11D48),
          ),
          _buildSummaryCard(
            title: 'BALANCE DUE',
            value: '₹ ${balance.toStringAsFixed(2)}',
            subtitle: '',
            color: const Color(0xFFF0FDF4),
            textColor: const Color(0xFF16A34A),
          ),
        ];

        if (constraints.maxWidth < 600) {
          return Column(
            children: cardList
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cardList
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordPayoutForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record New Payout',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Payout Amount (₹)'),
              GestureDetector(
                onTap: () {
                  final balance = (_summary['balance'] ?? 0).toString();
                  _payoutAmountController.text = balance;
                },
                child: Text(
                  'PAY FULL BALANCE',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A2C40),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          _buildTextField(_payoutAmountController, 'Enter amount to pay',
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildLabel('Payment Method'),
          _buildDropdown(),
          const SizedBox(height: 16),
          _buildLabel('Notes'),
          _buildTextField(_payoutNotesController, 'Extra payment details...',
              maxLines: 3),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _recordPayout,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Record Payment',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A2C40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPayouts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Payouts',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          _buildPayoutTable(_filteredPayouts),
        ],
      ),
    );
  }

  Widget _buildPayoutTable(List<dynamic> payouts) {
    if (payouts.isEmpty) {
      return Center(
        child: Text(
          'No payouts recorded yet.',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: _tableHeader('Date')),
              Expanded(child: _tableHeader('Method')),
              Expanded(child: _tableHeader('Amount', align: TextAlign.right)),
            ],
          ),
        ),
        const Divider(height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payouts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = payouts[index];
            // Format date from ISO string or similar if needed. For now just displaying string.
            String dateStr = p['payoutDate'] ?? p['date'] ?? '';
            if (dateStr.length > 10) dateStr = dateStr.substring(0, 10);
            String methodStr = p['paymentMethod'] ?? p['method'] ?? '';
            double amount = (p['amount'] ?? 0).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: _tableCell(dateStr)),
                  Expanded(child: _tableCell(methodStr)),
                  Expanded(
                      child: _tableCell('-₹${amount.toStringAsFixed(2)}',
                          align: TextAlign.right,
                          color: const Color(0xFFE11D48))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommissionHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Commission History (Last 50 Appointments)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          if (_filteredCommissions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.history_edu, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No completed appointments with commissions found.',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 600, // Fixed width for horizontal scroll on mobile
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: _tableHeader('Date')),
                          Expanded(flex: 3, child: _tableHeader('Client')),
                          Expanded(flex: 3, child: _tableHeader('Service')),
                          Expanded(
                              flex: 2,
                              child: _tableHeader('Appt. Amount',
                                  align: TextAlign.right)),
                          Expanded(
                              flex: 2,
                              child: _tableHeader('Comm. Rate',
                                  align: TextAlign.right)),
                          Expanded(
                              flex: 2,
                              child: _tableHeader('Comm. Earned',
                                  align: TextAlign.right)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredCommissions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _filteredCommissions[index];
                        String dateStr = c['date'] ?? '';
                        if (dateStr.length > 10)
                          dateStr = dateStr.substring(0, 10);
                        String clientName = c['clientName'] ?? 'Guest';
                        String serviceName = c['serviceName'] ?? 'Service';
                        double apptAmount = (c['totalAmount'] ?? 0).toDouble();
                        double commRate = (c['commissionRate'] ?? 0).toDouble();
                        double commEarned =
                            (c['commissionAmount'] ?? 0).toDouble();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: _tableCell(dateStr)),
                              Expanded(
                                  flex: 3,
                                  child: _tableCell(clientName,
                                      fontWeight: FontWeight.bold)),
                              Expanded(flex: 3, child: _tableCell(serviceName)),
                              Expanded(
                                  flex: 2,
                                  child: _tableCell(
                                      '₹${apptAmount.toStringAsFixed(2)}',
                                      align: TextAlign.right)),
                              Expanded(
                                  flex: 2,
                                  child: _tableCell(
                                      '${commRate.toStringAsFixed(0)}%',
                                      align: TextAlign.right)),
                              Expanded(
                                  flex: 2,
                                  child: _tableCell(
                                      '+₹${commEarned.toStringAsFixed(2)}',
                                      align: TextAlign.right,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Previous',
                style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A2C40),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Save Staff',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4A2C40), width: 1.5)),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: GoogleFonts.poppins(fontSize: 11),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPaymentMethod,
          isExpanded: true,
          items:
              ['Cash', 'Bank Transfer', 'UPI', 'Cheque'].map((String method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Text(method, style: GoogleFonts.poppins(fontSize: 11)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
        ),
      ),
    );
  }

  Widget _tableHeader(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _tableCell(String text,
      {TextAlign align = TextAlign.left,
      Color? color,
      FontWeight? fontWeight}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? const Color(0xFF1F2937),
      ),
    );
  }
}
