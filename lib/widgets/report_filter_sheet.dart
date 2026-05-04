import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportFilterSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Map<String, dynamic> initialFilters;
  final List<FilterField> fields;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const ReportFilterSheet({
    super.key,
    this.title = 'Filters',
    this.subtitle = 'Apply filters to refine your report data.',
    required this.initialFilters,
    required this.fields,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late Map<String, dynamic> _currentFilters;
  final DateFormat _df = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _currentFilters = Map<String, dynamic>.from(widget.initialFilters);
  }

  Future<void> _pickDate(String key) async {
    DateTime initialDate;
    try {
      initialDate = _currentFilters[key] != null 
          ? DateTime.parse(_currentFilters[key]) 
          : DateTime.now();
    } catch (_) {
      initialDate = DateTime.now();
    }
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF372935), // Primary color from design
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentFilters[key] = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Date Fields
          Row(
            children: [
              Expanded(
                child: _buildDateField('Start Date', 'startDate'),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDateField('End Date', 'endDate'),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Dynamic Dropdown Fields
          ...widget.fields.map((field) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildDropdownField(field),
            );
          }),

          SizedBox(height: 16.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_currentFilters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF372935),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, String key) {
    String dateStr = _currentFilters[key] ?? '';
    String displayDate = 'dd-mm-yyyy';
    if (dateStr.isNotEmpty) {
      try {
        displayDate = _df.format(DateTime.parse(dateStr));
      } catch (_) {
        displayDate = dateStr;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: () => _pickDate(key),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayDate,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: dateStr.isNotEmpty ? Colors.black87 : const Color(0xFF94A3B8),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 16.sp, color: const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(FilterField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _currentFilters[field.key] ?? 'All',
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black87),
              onChanged: (String? newValue) {
                setState(() {
                  _currentFilters[field.key] = newValue;
                });
              },
              items: field.options.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class FilterField {
  final String label;
  final String key;
  final List<String> options;

  FilterField({
    required this.label,
    required this.key,
    required this.options,
  });
}
