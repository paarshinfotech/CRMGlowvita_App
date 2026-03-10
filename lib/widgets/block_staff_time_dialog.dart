import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const Color _kPrimary = Color(0xFF3D1A47);
const Color _kPrimaryLight = Color(0xFFF3EEF7);
const Color _kBorder = Color(0xFFE0E0E0);
const Color _kBg = Color(0xFFF9F9F9);

// ═══════════════════════════════════════════════════════
//  MAIN DIALOG
// ═══════════════════════════════════════════════════════
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
  DateTime _selDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonCtrl = TextEditingController();
  bool _isSaving = false;

  // Which picker is open: 'none' | 'date' | 'start' | 'end'
  String _openPicker = 'none';

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _togglePicker(String name) =>
      setState(() => _openPicker = _openPicker == name ? 'none' : name);

  String _fmtDate(DateTime d) => DateFormat('EEE, dd MMM yyyy').format(d);

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
          'date': DateFormat('yyyy-MM-dd').format(_selDate),
          'startTime': _fmtTime(_startTime),
          'endTime': _fmtTime(_endTime),
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

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 9.sp))));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 36.h),
      backgroundColor: Colors.white,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Block Staff Time',
                            style: GoogleFonts.poppins(
                                fontSize: 11.sp, fontWeight: FontWeight.w700)),
                        SizedBox(height: 1.h),
                        Text('Block a time slot for a staff member',
                            style: TextStyle(
                                fontSize: 7.5.sp, color: Colors.grey[500])),
                      ]),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Icon(Icons.close,
                          size: 13.sp, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14.h),
              _HDivider(),
              SizedBox(height: 14.h),

              // ── Staff ────────────────────────────────
              _Label('Staff Member'),
              DropdownButtonFormField<String>(
                value: _selStaffId,
                isDense: true,
                style: TextStyle(fontSize: 9.sp, color: Colors.black87),
                decoration: _fieldDec(Icons.person_outline_rounded),
                items: widget.staff
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.fullName ?? 'Unnamed',
                              style: TextStyle(fontSize: 9.sp)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selStaffId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),

              SizedBox(height: 14.h),

              // ── Date picker ──────────────────────────
              _Label('Date'),
              _PickerTrigger(
                icon: Icons.calendar_month_rounded,
                value: _fmtDate(_selDate),
                isOpen: _openPicker == 'date',
                accentColor: _kPrimary,
                onTap: () => _togglePicker('date'),
              ),
              _AnimatedExpand(
                open: _openPicker == 'date',
                child: _InlineCalendar(
                  selected: _selDate,
                  onChanged: (d) => setState(() {
                    _selDate = d;
                    _openPicker = 'none';
                  }),
                ),
              ),

              SizedBox(height: 12.h),

              // ── Time pickers ─────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Start
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Start Time'),
                      _PickerTrigger(
                        icon: Icons.access_time_rounded,
                        value: _fmtTime(_startTime),
                        isPlaceholder: _startTime == null,
                        isOpen: _openPicker == 'start',
                        accentColor: const Color(0xFF1565C0),
                        onTap: () => _togglePicker('start'),
                      ),
                      _AnimatedExpand(
                        open: _openPicker == 'start',
                        child: _DrumTimePicker(
                          initial:
                              _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                          accentColor: const Color(0xFF1565C0),
                          onChanged: (t) => setState(() => _startTime = t),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                // End
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('End Time'),
                      _PickerTrigger(
                        icon: Icons.access_time_rounded,
                        value: _fmtTime(_endTime),
                        isPlaceholder: _endTime == null,
                        isOpen: _openPicker == 'end',
                        accentColor: const Color(0xFF6A1B9A),
                        onTap: () => _togglePicker('end'),
                      ),
                      _AnimatedExpand(
                        open: _openPicker == 'end',
                        child: _DrumTimePicker(
                          initial:
                              _endTime ?? const TimeOfDay(hour: 10, minute: 0),
                          accentColor: const Color(0xFF6A1B9A),
                          onChanged: (t) => setState(() => _endTime = t),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              // Duration badge
              if (_startTime != null && _endTime != null) ...[
                SizedBox(height: 6.h),
                _DurationBadge(start: _startTime!, end: _endTime!),
              ],

              SizedBox(height: 12.h),

              // ── Reason ───────────────────────────────
              _Label('Reason (Optional)'),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 2,
                style: TextStyle(fontSize: 9.sp),
                decoration: _fieldDec(null).copyWith(
                  hintText: 'Enter reason for blocking…',
                  hintStyle: TextStyle(fontSize: 9.sp, color: Colors.grey[400]),
                ),
              ),

              SizedBox(height: 16.h),
              _HDivider(),
              SizedBox(height: 12.h),

              // ── Buttons ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Btn(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                    outlined: true,
                  ),
                  SizedBox(width: 8.w),
                  _Btn(
                    label: 'Block Time',
                    onTap: _isSaving ? null : _submit,
                    loading: _isSaving,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDec(IconData? icon) => InputDecoration(
        prefixIcon: icon != null
            ? Icon(icon, size: 13.sp, color: Colors.grey[500])
            : null,
        isDense: true,
        filled: true,
        fillColor: _kBg,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: _kPrimary, width: 1.2)),
        errorStyle: TextStyle(fontSize: 7.sp),
      );
}

// ═══════════════════════════════════════════════════════
//  INLINE CALENDAR
// ═══════════════════════════════════════════════════════
class _InlineCalendar extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  const _InlineCalendar({required this.selected, required this.onChanged});

  @override
  State<_InlineCalendar> createState() => _InlineCalendarState();
}

class _InlineCalendarState extends State<_InlineCalendar> {
  late DateTime _viewMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
    _viewMonth = DateTime(_selected.year, _selected.month);
  }

  void _prevMonth() => setState(
      () => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
  void _nextMonth() => setState(
      () => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);
    final firstWeekday =
        DateTime(_viewMonth.year, _viewMonth.month, 1).weekday % 7; // Sun=0

    return Container(
      margin: EdgeInsets.only(top: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(children: [
        // Month nav
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(children: [
            GestureDetector(
              onTap: _prevMonth,
              child:
                  Icon(Icons.chevron_left, size: 16.sp, color: Colors.black87),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(_viewMonth),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700),
              ),
            ),
            GestureDetector(
              onTap: _nextMonth,
              child:
                  Icon(Icons.chevron_right, size: 16.sp, color: Colors.black87),
            ),
          ]),
        ),

        // Day labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 7.5.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400])),
                      ),
                    ))
                .toList(),
          ),
        ),

        SizedBox(height: 4.h),

        // Date grid
        Padding(
          padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 8.h),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final date = DateTime(_viewMonth.year, _viewMonth.month, day);
              final isSelected = DateUtils.isSameDay(date, _selected);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return GestureDetector(
                onTap: () {
                  setState(() => _selected = date);
                  widget.onChanged(date);
                },
                child: Container(
                  margin: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPrimary
                        : isToday
                            ? _kPrimaryLight
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$day',
                        style: TextStyle(
                            fontSize: 8.5.sp,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? _kPrimary
                                    : Colors.black87)),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  DRUM-ROLL TIME PICKER
// ═══════════════════════════════════════════════════════
class _DrumTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  final Color accentColor;
  final ValueChanged<TimeOfDay> onChanged;

  const _DrumTimePicker({
    required this.initial,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_DrumTimePicker> createState() => _DrumTimePickerState();
}

class _DrumTimePickerState extends State<_DrumTimePicker> {
  late int _hour;
  late int _minute;
  late bool _isAm;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;
  late FixedExtentScrollController _ampmCtrl;

  static const _itemH = 32.0;

  @override
  void initState() {
    super.initState();
    _isAm = widget.initial.hour < 12;
    _hour = widget.initial.hour % 12 == 0 ? 12 : widget.initial.hour % 12;
    _minute = widget.initial.minute;

    _hourCtrl = FixedExtentScrollController(initialItem: _hour - 1);
    _minCtrl = FixedExtentScrollController(initialItem: _minute);
    _ampmCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _ampmCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    int h24 = _hour % 12 + (_isAm ? 0 : 12);
    widget.onChanged(TimeOfDay(hour: h24, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      child: Column(children: [
        // Column headers
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(children: [
            Expanded(child: _ColLabel('Hour')),
            SizedBox(width: 6.w),
            Expanded(child: _ColLabel('Min')),
            SizedBox(width: 6.w),
            SizedBox(width: 52.w, child: _ColLabel('AM/PM')),
          ]),
        ),
        SizedBox(height: 4.h),

        // Drum wheels
        SizedBox(
          height: _itemH * 3,
          child: Stack(children: [
            // Highlight band
            Center(
              child: Container(
                height: _itemH,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border:
                      Border.all(color: widget.accentColor.withOpacity(0.25)),
                ),
              ),
            ),

            Row(children: [
              // Hours  1–12
              Expanded(
                child: _Wheel(
                  controller: _hourCtrl,
                  count: 12,
                  label: (i) => '${i + 1}'.padLeft(2, '0'),
                  selectedIndex: _hour - 1,
                  accentColor: widget.accentColor,
                  onSelected: (i) {
                    _hour = i + 1;
                    _notify();
                  },
                ),
              ),

              // separator
              _Sep(widget.accentColor),

              SizedBox(width: 6.w),

              // Minutes 0–59
              Expanded(
                child: _Wheel(
                  controller: _minCtrl,
                  count: 60,
                  label: (i) => '$i'.padLeft(2, '0'),
                  selectedIndex: _minute,
                  accentColor: widget.accentColor,
                  onSelected: (i) {
                    _minute = i;
                    _notify();
                  },
                ),
              ),

              _Sep(widget.accentColor),
              SizedBox(width: 6.w),

              // AM / PM
              SizedBox(
                width: 52.w,
                child: _Wheel(
                  controller: _ampmCtrl,
                  count: 2,
                  label: (i) => i == 0 ? 'AM' : 'PM',
                  selectedIndex: _isAm ? 0 : 1,
                  accentColor: widget.accentColor,
                  onSelected: (i) {
                    _isAm = i == 0;
                    _notify();
                  },
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final int selectedIndex;
  final Color accentColor;
  final ValueChanged<int> onSelected;

  const _Wheel({
    required this.controller,
    required this.count,
    required this.label,
    required this.selectedIndex,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 32,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.003,
      diameterRatio: 1.6,
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (_, i) {
          final sel = i == selectedIndex;
          return Center(
            child: Text(
              label(i),
              style: TextStyle(
                fontSize: sel ? 13.sp : 10.sp,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? accentColor : Colors.grey[400],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  final Color color;
  const _Sep(this.color);

  @override
  Widget build(BuildContext context) => Text(':',
      style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.5)));
}

class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 7.5.sp,
            color: Colors.grey[400],
            fontWeight: FontWeight.w600),
      );
}

// ── Duration badge ──────────────────────────────────────
class _DurationBadge extends StatelessWidget {
  final TimeOfDay start, end;
  const _DurationBadge({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final sm = start.hour * 60 + start.minute;
    final em = end.hour * 60 + end.minute;
    final diff = em - sm;
    if (diff <= 0) return const SizedBox();
    final h = diff ~/ 60, m = diff % 60;
    final label = [if (h > 0) '${h}h', if (m > 0) '${m}m'].join(' ');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timelapse_rounded, size: 11.sp, color: _kPrimary),
        SizedBox(width: 4.w),
        Text('Duration: $label',
            style: TextStyle(
                fontSize: 8.sp, fontWeight: FontWeight.w600, color: _kPrimary)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PICKER TRIGGER BUTTON
// ═══════════════════════════════════════════════════════
class _PickerTrigger extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isOpen;
  final bool isPlaceholder;
  final Color accentColor;
  final VoidCallback onTap;

  const _PickerTrigger({
    required this.icon,
    required this.value,
    required this.isOpen,
    required this.accentColor,
    required this.onTap,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isOpen ? accentColor.withOpacity(0.06) : _kBg,
          border: Border.all(
            color: isOpen ? accentColor : _kBorder,
            width: isOpen ? 1.3 : 1,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(children: [
          Icon(icon,
              size: 13.sp, color: isOpen ? accentColor : Colors.grey[500]),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: isOpen ? FontWeight.w600 : FontWeight.w400,
                    color: isPlaceholder
                        ? Colors.grey[400]
                        : isOpen
                            ? accentColor
                            : Colors.black87)),
          ),
          Icon(
            isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 13.sp,
            color: isOpen ? accentColor : Colors.grey[400],
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  ANIMATED EXPAND
// ═══════════════════════════════════════════════════════
class _AnimatedExpand extends StatelessWidget {
  final bool open;
  final Widget child;
  const _AnimatedExpand({required this.open, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity),
      secondChild: child,
      crossFadeState:
          open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
      sizeCurve: Curves.easeInOut,
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SHARED MICRO WIDGETS
// ═══════════════════════════════════════════════════════
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Text(text,
            style: TextStyle(
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      );
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 0.6, color: Colors.grey[200]);
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool loading;

  const _Btn({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: outlined
              ? Colors.white
              : (onTap == null ? Colors.grey[300] : _kPrimary),
          border: Border.all(color: outlined ? _kBorder : Colors.transparent),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: loading
            ? SizedBox(
                width: 12.sp,
                height: 12.sp,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 1.5),
              )
            : Text(label,
                style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: outlined ? Colors.grey[700] : Colors.white)),
      ),
    );
  }
}
