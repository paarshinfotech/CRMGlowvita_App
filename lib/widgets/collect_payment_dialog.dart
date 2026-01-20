import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../appointment_model.dart';
import '../services/api_service.dart';

class CollectPaymentDialog extends StatefulWidget {
  final AppointmentModel appointment;

  const CollectPaymentDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  String _method = 'cash';
  bool _isSaving = false;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'cash', 'label': 'Cash', 'icon': Icons.payments_outlined},
    {'id': 'upi', 'label': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
    {'id': 'card', 'label': 'Card', 'icon': Icons.credit_card_rounded},
    {
      'id': 'netbanking',
      'label': 'Net Banking',
      'icon': Icons.account_balance_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    final total =
        widget.appointment.totalAmount ?? widget.appointment.amount ?? 0.0;
    final paid = widget.appointment.amountPaid ?? 0.0;
    final remaining = (total - paid).clamp(0.0, double.infinity);

    // If it's a whole number, don't show .00
    if (remaining == remaining.toInt()) {
      _amountController.text = remaining.toInt().toString();
    } else {
      _amountController.text = remaining.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  Future<void> _handleCollect() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final paymentData = {
        "appointmentId": widget.appointment.id,
        "amount": _amount,
        "paymentMethod": _method,
        "notes": _notesController.text.trim(),
        "transactionId": _transactionIdController.text.trim(),
        "paymentDate": DateTime.now().toUtc().toIso8601String(),
      };

      final response = await ApiService.collectPayment(paymentData);

      if (mounted) {
        Navigator.pop(context, response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        widget.appointment.totalAmount ?? widget.appointment.amount ?? 0.0;
    final paid = widget.appointment.amountPaid ?? 0.0;
    final remaining = (total - paid).clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collect Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 12),

            // Summary Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _summaryMiniRow('Total Amount', total),
                  const SizedBox(height: 4),
                  _summaryMiniRow('Paid Amount', paid, color: Colors.green),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _summaryMiniRow('Remaining', remaining,
                      bold: true, color: Colors.red.shade800),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Amount Input
            Text('Amount to Collect', style: _labelStyle()),
            const SizedBox(height: 4),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('Enter amount', prefix: '₹ '),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            // Payment Methods
            Text('Payment Method', style: _labelStyle()),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _methods.map((m) {
                final bool isSelected = _method == m['id'];
                return InkWell(
                  onTap: () => setState(() => _method = m['id']),
                  child: Container(
                    width: (340 - 32 - 8) / 2 - 1,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      border: Border.all(
                          color:
                              isSelected ? Colors.black : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(m['icon'],
                            size: 14,
                            color: isSelected ? Colors.white : Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          m['label'],
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Transaction ID (if not cash)
            if (_method != 'cash') ...[
              Text('Transaction ID', style: _labelStyle()),
              const SizedBox(height: 4),
              TextField(
                controller: _transactionIdController,
                style: GoogleFonts.poppins(fontSize: 12),
                decoration: _inputDecoration('TXN123...'),
              ),
              const SizedBox(height: 12),
            ],

            // Notes
            Text('Notes', style: _labelStyle()),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 2,
              decoration: _inputDecoration('Details...'),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleCollect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Collect ₹${_amount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade700,
      letterSpacing: 0.5);

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black)),
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
    );
  }

  Widget _summaryMiniRow(String label, double value,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text('₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? Colors.black)),
      ],
    );
  }
}
