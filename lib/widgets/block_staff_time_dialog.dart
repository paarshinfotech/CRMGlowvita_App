import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BlockStaffTimeDialog extends StatefulWidget {
  final List<StaffMember> staff;
  final Function() onBlocked;

  const BlockStaffTimeDialog({
    super.key,
    required this.staff,
    required this.onBlocked,
  });

  @override
  State<BlockStaffTimeDialog> createState() => _BlockStaffTimeDialogState();
}

class _BlockStaffTimeDialogState extends State<BlockStaffTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selStaffId;
  DateTime? _selDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonCtrl = TextEditingController();
  bool _isSaving = false;

  // Theme Constants
  final Color _kPrimary = const Color(0xFF4A2C40);
  final Color _kPink = const Color(0xFFB33A6B);
  final Color _kBorder = const Color(0xFFE5E5E5);
  final Color _kLabel = const Color(0xFF2C2C2C);

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select Date';
    return DateFormat('dd-MM-yyyy').format(d);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return 'Select Time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selDate == null) {
      _snack('Please select a date');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _snack('Please select start and end times');
      return;
    }
    final sm = _startTime!.hour * 60 + _startTime!.minute;
    final em = _endTime!.hour * 60 + _endTime!.minute;
    if (sm >= em) {
      _snack('End time must be after start time');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final member = widget.staff.firstWhere((s) => s.id == _selStaffId);
      final blocked = List<dynamic>.from(member.blockedTimes ?? [])
        ..add({
          'date': DateFormat('yyyy-MM-dd').format(_selDate!),
          'startTime': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          'endTime': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
          'reason': _reasonCtrl.text.trim(),
        });
      await ApiService.updateStaff(_selStaffId!, {'blockedTimes': blocked});
      if (mounted) {
        widget.onBlocked();
        Navigator.pop(context);
        _snack('Time blocked successfully');
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: msg.contains('success') ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW < 480 ? screenW - 16 : 420.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: dialogW,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Matches AddStaffDialog styling)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Staff Member',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add a new staff member to your team.',
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
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  const SizedBox(height: 16),

                  // Section Title
                  Row(
                    children: [
                      Text(
                        'BLOCK TIME ENTRIES',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _kPink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: _kPink.withOpacity(0.3), height: 1)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Staff Selector
                  _buildFieldLabel('STAFF MEMBER', required: true),
                  DropdownButtonFormField<String>(
                    value: _selStaffId,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
                    decoration: _fieldDec(Icons.person_outline),
                    items: widget.staff
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.fullName ?? 'Unnamed', style: GoogleFonts.poppins(fontSize: 10)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selStaffId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),

                  // Block time box layout like entry 1 (Delete icon removed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Block Time Entry 1',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Date
                        _buildFieldLabel('DATE', required: true),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorder),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmtDate(_selDate),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: _selDate == null ? Colors.grey[400] : Colors.black87,
                                  ),
                                ),
                                Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Time slots row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('START TIME *', required: true),
                                  InkWell(
                                    onTap: () => _pickTime(true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _kBorder),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _fmtTime(_startTime),
                                            style: GoogleFonts.poppins(
                                              fontSize: 9.5,
                                              color: _startTime == null ? Colors.grey[400] : Colors.black87,
                                            ),
                                          ),
                                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('END TIME *', required: true),
                                  InkWell(
                                    onTap: () => _pickTime(false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _kBorder),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _fmtTime(_endTime),
                                            style: GoogleFonts.poppins(
                                              fontSize: 9.5,
                                              color: _endTime == null ? Colors.grey[400] : Colors.black87,
                                            ),
                                          ),
                                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Reason text area
                        _buildFieldLabel('REASON *', required: true),
                        TextFormField(
                          controller: _reasonCtrl,
                          maxLines: 3,
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Reason for block time. (e.g. Lunch Break, Meeting, etc.)',
                            hintStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.all(10),
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
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom buttons
                  Row(
                    children: [
                      Expanded(
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
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: _kBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Previous',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                                )
                              : Text(
                                  'Save Staff',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 6),
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

  InputDecoration _fieldDec(IconData? icon) => InputDecoration(
        prefixIcon: icon != null ? Icon(icon, size: 14, color: Colors.grey[500]) : null,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _kPrimary, width: 1.5)),
        errorStyle: GoogleFonts.poppins(fontSize: 8, color: Colors.red),
      );
}
