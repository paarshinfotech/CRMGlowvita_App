import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              child: SingleChildScrollView(
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

                    // Main Content Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Record Payout
                        Expanded(
                          flex: 2,
                          child: _buildRecordPayoutForm(),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Recent Payouts
                        Expanded(
                          flex: 2,
                          child: _buildRecentPayouts(),
                        ),
                      ],
                    ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff Earnings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Text(
                'View earnings and payout history for ${widget.staff['fullName']}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
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
              onTap: () => setState(() => _selectedFilter = filter),
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
    return Row(
      children: [
        _buildSummaryCard(
          title: 'TOTAL EARNED',
          value: '₹ 0.00',
          subtitle: '0 Appointments',
          color: Colors.grey[100]!,
          textColor: const Color(0xFF1F2937),
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          title: 'TOTAL PAID',
          value: '₹ 5.00',
          subtitle: '',
          color: const Color(0xFFFFF1F2),
          textColor: const Color(0xFFE11D48),
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          title: 'BALANCE DUE',
          value: '₹ -5.00',
          subtitle: '',
          color: const Color(0xFFF0FDF4),
          textColor: const Color(0xFF16A34A),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
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
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
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
          _buildLabel('Payout Amount (₹)'),
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
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: Text('Record Payment',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A2C40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
      height: 380, // Match height of left column roughly
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
          Expanded(
            child: _buildPayoutTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutTable() {
    // Example data
    final List<Map<String, dynamic>> payouts = [
      {'date': '1/19/2026', 'method': 'Cash', 'amount': '-₹5.00'},
    ];

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
        Expanded(
          child: ListView.separated(
            itemCount: payouts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = payouts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: _tableCell(p['date'])),
                    Expanded(child: _tableCell(p['method'])),
                    Expanded(
                        child: _tableCell(p['amount'],
                            align: TextAlign.right,
                            color: const Color(0xFFE11D48))),
                  ],
                ),
              );
            },
          ),
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
          const SizedBox(height: 40),
          Center(
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
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
            ),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text('Previous',
                style: GoogleFonts.poppins(
                    color: Colors.grey[700], fontWeight: FontWeight.w500)),
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
            child: Text('Next',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _tableCell(String text,
      {TextAlign align = TextAlign.left, Color? color}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color ?? const Color(0xFF1F2937),
      ),
    );
  }
}
