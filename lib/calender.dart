import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glowvita/my_Profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'widgets/create_appointment_form.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/appointment_detail_dialog.dart';
import 'Notification.dart';
import 'vendor_model.dart';

// ══════════════════════════════════════════════════
// MODEL  — unchanged from original
// ══════════════════════════════════════════════════
class Appointments {
  final String id;
  final DateTime startTime;
  final Duration duration;
  final String clientName;
  final String serviceName;
  final String staffName;
  final String status;
  final bool isWebBooking;
  final String mode;
  final bool hasAddOns;
  final bool isWeddingService;
  final int addOnCount;

  Appointments({
    this.id = '',
    required this.startTime,
    required this.duration,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
    this.status = 'New',
    this.isWebBooking = false,
    this.mode = 'offline',
    this.hasAddOns = false,
    this.isWeddingService = false,
    this.addOnCount = 0,
  });

  DateTime get endTime => startTime.add(duration);
}

// ══════════════════════════════════════════════════
// WIDGET
// ══════════════════════════════════════════════════
class Calendar extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialAppointmentId;
  const Calendar({super.key, this.initialDate, this.initialAppointmentId});
  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _selectedDate;
  String? _highlightedAppointmentId;
  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(0);

  late final ScrollController _verticalScrollController;
  late final ScrollController _horizontalScrollController;
  late final ScrollController _staffHeaderScrollController;

  Timer? _timer;

  // ── layout constants (unchanged) ──────────────────
  static const double baseSlotHeight = 120.0;
  double get slotHeight => baseSlotHeight.h;

  static const double staffColumnBaseWidth = 160.0;
  double get staffColumnWidth => staffColumnBaseWidth.w;

  // ── data (unchanged) ──────────────────────────────
  List<StaffMember> staffList = [];
  bool isStaffLoading = false;
  List<Appointments> _appointments = [];
  VendorProfile? _profile;

  // ── UI-only filter state ──
  String? _selectedStaffId; // null = All Staff

  List<StaffMember> get _filteredStaff {
    if (_selectedStaffId == null) return staffList;
    return staffList.where((s) => s.id == _selectedStaffId).toList();
  }

  // ══════════════════════════════════════════════════
  // ▼▼▼  ORIGINAL BACKEND CODE — NOT MODIFIED  ▼▼▼
  // ══════════════════════════════════════════════════

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double _timeToOffset(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    final quarterSlot = slotHeight / 4;
    return (minutes / 15) * quarterSlot;
  }

  void _setSelectedDate(DateTime newDate) {
    final d = _dateOnly(newDate);
    if (DateUtils.isSameDay(_selectedDate, d)) return;
    setState(() {
      _selectedDate = d;
    });
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final models = await ApiService.getAppointments();
      setState(() {
        _appointments = models.where((m) {
          if (m.date == null) return true;
          return DateUtils.isSameDay(m.date!, _selectedDate);
        }).map((m) {
          DateTime start = m.date ?? _selectedDate;
          if (m.startTime != null && m.startTime!.contains(':')) {
            final parts = m.startTime!.split(':');
            start = DateTime(
              start.year,
              start.month,
              start.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
          String mappedStaffName =
              m.staff?.fullName ?? m.staffName ?? 'Unassigned';
          print('📅 Mapping Appointment: ${m.clientName}, Model ID: ${m.id}');
          return Appointments(
            id: m.id ?? '',
            startTime: start,
            duration: Duration(minutes: m.duration ?? 30),
            clientName: m.clientName ?? 'Unknown',
            serviceName: m.serviceName ?? 'Unknown Service',
            staffName: mappedStaffName,
            status: m.status ?? 'New',
            isWebBooking: m.isMultiService ?? false,
            mode: m.mode ?? 'offline',
            hasAddOns:
                m.serviceItems?.any((s) => s.addOns?.isNotEmpty ?? false) ??
                    false,
            isWeddingService: m.isWeddingService ?? false,
            addOnCount: m.serviceItems
                    ?.fold<int>(0, (sum, s) => sum + (s.addOns?.length ?? 0)) ??
                0,
          );
        }).toList();

        bool hasWeddingAppt = _appointments
            .any((a) => a.isWeddingService || a.staffName == 'Wedding Team');
        if (hasWeddingAppt) {
          bool weddingTeamExists =
              staffList.any((s) => s.fullName == 'Wedding Team');
          if (!weddingTeamExists) {
            staffList.add(StaffMember(
                id: 'wedding_team_virtual',
                fullName: 'Wedding Team',
                position: 'Package Team'));
          }
        }
      });
      debugPrint('Loaded ${_appointments.length} appointments from API');

      if (_highlightedAppointmentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAppointment(_highlightedAppointmentId!);
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    }
  }

  void _scrollToAppointment(String id) {
    if (!mounted) return;
    try {
      final appt = _appointments.firstWhere((a) => a.id == id);
      final startMin = appt.startTime.hour * 60 + appt.startTime.minute;
      final quarterSlot = slotHeight / 4;
      final targetTop = (startMin / 15) * quarterSlot;
      if (_verticalScrollController.hasClients) {
        _verticalScrollController.animateTo(
          (targetTop - 100)
              .clamp(0, _verticalScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      if (_horizontalScrollController.hasClients && staffList.isNotEmpty) {
        final staffIdx =
            staffList.indexWhere((s) => s.fullName == appt.staffName);
        if (staffIdx != -1) {
          final targetLeft = staffIdx * staffColumnWidth;
          _horizontalScrollController.animateTo(
            targetLeft.clamp(
                0, _horizontalScrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    } catch (e) {
      debugPrint('Scroll to appointment failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate ?? DateTime.now());
    _highlightedAppointmentId = widget.initialAppointmentId;

    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _staffHeaderScrollController = ScrollController();

    _loadStaff();
    _loadAppointments();
    _fetchProfile();

    _horizontalScrollController.addListener(() {
      if (!_horizontalScrollController.hasClients ||
          !_staffHeaderScrollController.hasClients) return;
      final target = _horizontalScrollController.offset;
      final max = _staffHeaderScrollController.position.maxScrollExtent;
      _staffHeaderScrollController.jumpTo(target.clamp(0.0, max));
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _timerNotifier.value = DateTime.now().millisecondsSinceEpoch;
    });
  }

  Future<void> _loadStaff() async {
    setState(() {
      isStaffLoading = true;
    });
    try {
      final List<StaffMember> staffMembers = await ApiService.getStaff();
      setState(() {
        staffList = staffMembers;
        debugPrint('Loaded ${staffList.length} staff members');
      });
    } catch (e, stack) {
      debugPrint('ERROR loading staff: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isStaffLoading = false);
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _staffHeaderScrollController.dispose();
    _timerNotifier.dispose();
    super.dispose();
  }

  // Dark shade — used for left border bar & status chip text
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFF2E7D32); // dark green
      case 'pending':
        return const Color(0xFFE65100); // deep orange
      case 'scheduled':
        return const Color(0xFF1565C0); // dark blue
      case 'cancelled':
        return const Color(0xFFC62828); // dark red
      default:
        return const Color(0xFF616161);
    }
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: 300.h,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.all(12.h),
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                Text(
                  'Select Month & Year',
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    onDateTimeChanged: (DateTime newDate) {
                      _setSelectedDate(newDate);
                    },
                    minimumYear: 2020,
                    maximumYear: 2030,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 30.h),
                    ),
                    child: Text('Done',
                        style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _showCreateAppointmentForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAppointmentForm(
          dailyAppointments: _appointments,
          onAppointmentCreated: (appointments) {
            setState(() {
              _appointments.addAll(appointments);
            });
          },
        );
      },
    );
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
          color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
    );
  }

  int _getMinutes(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return 0;
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  // ══════════════════════════════════════════════════
  // ▲▲▲  END OF ORIGINAL BACKEND CODE  ▲▲▲
  // ══════════════════════════════════════════════════

  // Light shade — used for card background
  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFFE8F5E9); // light green
      case 'pending':
        return const Color(0xFFFFF3E0); // light orange
      case 'scheduled':
        return const Color(0xFFE3F2FD); // light blue
      case 'cancelled':
        return const Color(0xFFFFEBEE); // light red
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final quarterSlot = slotHeight / 4;
    final displayingStaff = _filteredStaff;
    final isSingleStaff =
        _selectedStaffId != null && displayingStaff.length == 1;

    final Map<String, List<Appointments>> staffAppts = {};
    for (final staff in displayingStaff) {
      staffAppts[staff.fullName ?? ''] = _appointments
          .where((a) =>
              a.staffName == staff.fullName &&
              DateUtils.isSameDay(a.startTime, _selectedDate))
          .toList();
    }

    // Show all appointments (no tab filter)
    final Map<String, List<Appointments>> visibleAppts = Map.from(staffAppts);

    final totalApptsForDay = _appointments
        .where((a) => DateUtils.isSameDay(a.startTime, _selectedDate))
        .length;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Calendar'),
      backgroundColor: Colors.white,

      // ── Minimal top bar (no AppBar widget) ──────────
      body: SafeArea(
        child: Column(children: [
          // ── Header: Title + date + controls ───────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: drawer icon + title + refresh + notifications + avatar
                Row(children: [
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 12.sp,
                            color: Colors.black45,
                          ),
                          Text(
                            'Calendar',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(children: [
                      Text(
                        'Staff Schedule',
                        style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(
                            fontSize: 7.sp,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400),
                      ),
                    ]),
                  ),
                  // Action icons compact
                  GestureDetector(
                    onTap: () {
                      _loadStaff();
                      _loadAppointments();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(Icons.refresh,
                          size: 16.sp, color: Colors.black54),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => NotificationPage())),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(Icons.notifications_outlined,
                          size: 16.sp, color: Colors.black54),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => My_Profile())),
                    child: CircleAvatar(
                      radius: 13.r,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: ClipOval(
                        child: (_profile != null &&
                                _profile!.profileImage.isNotEmpty)
                            ? Image.network(
                                _profile!.profileImage,
                                width: 26.r,
                                height: 26.r,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) =>
                                    _buildInitialAvatar(),
                                loadingBuilder: (ctx, child, progress) =>
                                    progress == null
                                        ? child
                                        : _buildInitialAvatar(),
                              )
                            : _buildInitialAvatar(),
                      ),
                    ),
                  ),
                ]),

                SizedBox(height: 8.h),

                // Staff dropdown + Date navigator row
                Row(children: [
                  // Staff dropdown
                  Container(
                    height: 28.h,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6.r),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedStaffId,
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            size: 14.sp, color: Colors.grey),
                        style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.black87,
                            fontFamily: GoogleFonts.poppins().fontFamily),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Staff',
                                style: TextStyle(fontSize: 9.sp)),
                          ),
                          ...staffList.map((s) => DropdownMenuItem<String?>(
                                value: s.id,
                                child: Text(s.fullName ?? 'Staff',
                                    style: TextStyle(fontSize: 9.sp)),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedStaffId = v),
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Date navigator
                  Expanded(
                    child: Container(
                      height: 28.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => _setSelectedDate(
                              _selectedDate.subtract(const Duration(days: 1))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Icon(Icons.chevron_left,
                                size: 14.sp, color: Colors.black87),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showMonthYearPicker,
                            child: Text(
                              DateFormat('EEE, dd MMM yyyy')
                                  .format(_selectedDate),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _setSelectedDate(
                              _selectedDate.add(const Duration(days: 1))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Icon(Icons.chevron_right,
                                size: 14.sp, color: Colors.black87),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey[200]),

          // ── Staff avatar header (All Staff only) ────────
          if (!isSingleStaff)
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: SingleChildScrollView(
                controller: _staffHeaderScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(children: [
                  SizedBox(width: 60.w),
                  if (isStaffLoading)
                    ...List.generate(
                      3,
                      (_) => SizedBox(
                        width: staffColumnWidth,
                        child: Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    )
                  else
                    ...displayingStaff.map((s) => SizedBox(
                          width: staffColumnWidth,
                          child: Column(children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 1.5),
                              ),
                              child: ClipOval(
                                child: (s.photo?.isNotEmpty ?? false)
                                    ? Image.network(
                                        s.photo!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _staffInitialWidget(s),
                                      )
                                    : _staffInitialWidget(s),
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              s.fullName ?? 'Staff',
                              style: TextStyle(
                                  fontSize: 8.sp, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              s.position ?? '',
                              style: TextStyle(
                                  fontSize: 7.sp, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ]),
                        )),
                ]),
              ),
            ),

          Divider(height: 1, thickness: 1, color: Colors.grey[200]),

          // ── Grid ──────────────────────────────────────
          Expanded(
            child: isSingleStaff
                ? _buildSingleStaffGrid(
                    displayingStaff.first,
                    visibleAppts[displayingStaff.first.fullName] ?? [],
                    quarterSlot,
                    totalApptsForDay,
                  )
                : _buildAllStaffGrid(
                    displayingStaff,
                    visibleAppts,
                    quarterSlot,
                    totalApptsForDay,
                  ),
          ),
        ]),
      ),
    );
  }

  // ── staff initial avatar widget ────────────────────
  Widget _staffInitialWidget(StaffMember s) => Container(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Center(
          child: Text(
            (s.fullName ?? 'S').substring(0, 1).toUpperCase(),
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor),
          ),
        ),
      );

  // ══════════════════════════════════════════════════
  // ALL STAFF GRID
  // ══════════════════════════════════════════════════
  Widget _buildAllStaffGrid(
    List<StaffMember> displayingStaff,
    Map<String, List<Appointments>> staffAppts,
    double quarterSlot,
    int totalApptsForDay,
  ) {
    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: SizedBox(
        height: 24 * slotHeight,
        child: Stack(fit: StackFit.expand, children: [
          const SizedBox.expand(),

          // Time column
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 60.w,
            child: Column(
              children: List.generate(24, (h) {
                final hour = h % 12 == 0 ? 12 : h % 12;
                final period = h < 12 ? 'AM' : 'PM';
                return SizedBox(
                  height: slotHeight,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8.w, top: 4.h),
                      child: Text('$hour:00 $period',
                          style:
                              TextStyle(fontSize: 7.sp, color: Colors.black54)),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Staff columns
          Positioned(
            left: 60.w,
            right: 0,
            top: 0,
            bottom: 0,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 24 * slotHeight,
                width: displayingStaff.isEmpty
                    ? 0
                    : displayingStaff.length * staffColumnWidth,
                child: displayingStaff.isEmpty
                    ? const SizedBox()
                    : Row(
                        children: displayingStaff.map((staff) {
                          final appts = staffAppts[staff.fullName] ?? [];
                          return _buildStaffColumn(staff, appts, quarterSlot);
                        }).toList(),
                      ),
              ),
            ),
          ),

          // Current time indicator
          ValueListenableBuilder(
            valueListenable: _timerNotifier,
            builder: (_, __, ___) {
              final now = DateTime.now();
              final top = _timeToOffset(now);
              final isToday = DateUtils.isSameDay(now, _selectedDate);
              return Positioned(
                top: top - 1,
                left: 60.w,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.red : Colors.grey.shade400,
                    boxShadow: [
                      BoxShadow(
                        color: (isToday ? Colors.red : Colors.grey)
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Empty state
          if (totalApptsForDay == 0 && displayingStaff.isNotEmpty)
            Positioned(
              top: 50.h,
              left: 70.w,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_busy, size: 28.sp, color: Colors.grey[400]),
                  SizedBox(height: 8.h),
                  Text('No appointments',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]),
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),
                  Text(
                    'for ${DateFormat('EEE, MMM d').format(_selectedDate)}',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // SINGLE STAFF GRID
  // ══════════════════════════════════════════════════
  Widget _buildSingleStaffGrid(
    StaffMember staff,
    List<Appointments> appts,
    double quarterSlot,
    int totalApptsForDay,
  ) {
    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: SizedBox(
        height: 24 * slotHeight,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Time column
          SizedBox(
            width: 60.w,
            child: Column(
              children: List.generate(24, (h) {
                final hour = h % 12 == 0 ? 12 : h % 12;
                final period = h < 12 ? 'AM' : 'PM';
                return SizedBox(
                  height: slotHeight,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8.w, top: 4.h),
                      child: Text('$hour:00 $period',
                          style:
                              TextStyle(fontSize: 7.sp, color: Colors.black54)),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Full-width appointment column
          Expanded(
            child: Stack(children: [
              // Grid lines
              ...List.generate(
                  97,
                  (i) => Positioned(
                        top: i * quarterSlot,
                        left: 0,
                        right: 0,
                        child: Divider(
                          thickness: i % 4 == 0 ? 1.0 : 0.4,
                          color: i % 4 == 0
                              ? Colors.grey[400]!
                              : Colors.grey[200]!,
                        ),
                      )),

              // Blocked times
              ...(staff.blockedTimes ?? []).where((b) {
                if (b == null || b['isActive'] == false) return false;
                try {
                  final blockDate =
                      DateTime.parse(b['date'].toString()).toLocal();
                  return DateUtils.isSameDay(blockDate, _selectedDate);
                } catch (_) {
                  return false;
                }
              }).map((b) {
                final sm = _getMinutes(b['startTime']);
                final em = _getMinutes(b['endTime']);
                final top = (sm / 15) * quarterSlot;
                final height = ((em - sm) / 15) * quarterSlot;
                final reason = b['reason']?.toString();
                final startTime = b['startTime']?.toString() ?? '';
                final endTime = b['endTime']?.toString() ?? '';
                final timeLabel = (startTime.isNotEmpty && endTime.isNotEmpty)
                    ? '$startTime – $endTime'
                    : '';
                return Positioned(
                  top: top,
                  left: 4.w,
                  right: 4.w,
                  height: height.clamp(22.h, double.infinity),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border(
                        left: BorderSide(color: Colors.red.shade600, width: 3),
                        top: BorderSide(color: Colors.red.shade200, width: 0.5),
                        right:
                            BorderSide(color: Colors.red.shade200, width: 0.5),
                        bottom:
                            BorderSide(color: Colors.red.shade200, width: 0.5),
                      ),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(
                                'Blocked',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (timeLabel.isNotEmpty) ...[
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  timeLabel,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 6.5.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (reason != null &&
                            reason.isNotEmpty &&
                            height > 36.h) ...[
                          SizedBox(height: 2.h),
                          Text(
                            reason,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 6.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              // Appointments
              ...appts
                  .map((appt) => _buildApptCard(appt, 4.w, 4.w, quarterSlot)),

              // Current time indicator
              ValueListenableBuilder(
                valueListenable: _timerNotifier,
                builder: (_, __, ___) {
                  final now = DateTime.now();
                  final top = _timeToOffset(now);
                  final isToday = DateUtils.isSameDay(now, _selectedDate);
                  return Positioned(
                    top: top - 1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.red : Colors.grey.shade400,
                        boxShadow: [
                          BoxShadow(
                            color: (isToday ? Colors.red : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Empty state
              if (totalApptsForDay == 0)
                Positioned(
                  top: 50.h,
                  left: 8.w,
                  right: 8.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.event_busy,
                          size: 28.sp, color: Colors.grey[400]),
                      SizedBox(height: 8.h),
                      Text('No appointments',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700]),
                          textAlign: TextAlign.center),
                      SizedBox(height: 4.h),
                      Text(
                        'for ${DateFormat('EEE, MMM d').format(_selectedDate)}',
                        style:
                            TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── per-staff column (used in All Staff grid) ──────
  Widget _buildStaffColumn(
      StaffMember staff, List<Appointments> appts, double quarterSlot) {
    return SizedBox(
      width: staffColumnWidth,
      height: 24 * slotHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: Stack(fit: StackFit.expand, children: [
          const SizedBox.expand(),

          // Grid lines
          ...List.generate(97, (i) {
            return Positioned(
              top: i * quarterSlot,
              left: 0,
              right: 0,
              child: Divider(
                thickness: i % 4 == 0 ? 1.0 : 0.4,
                color: i % 4 == 0 ? Colors.grey[400]! : Colors.grey[200]!,
              ),
            );
          }),

          // Blocked times
          ...(staff.blockedTimes ?? []).where((b) {
            if (b == null || b['isActive'] == false) return false;
            try {
              final blockDate = DateTime.parse(b['date'].toString()).toLocal();
              return DateUtils.isSameDay(blockDate, _selectedDate);
            } catch (_) {
              return false;
            }
          }).map((b) {
            final sm = _getMinutes(b['startTime']);
            final em = _getMinutes(b['endTime']);
            final top = (sm / 15) * quarterSlot;
            final height = ((em - sm) / 15) * quarterSlot;
            final reason = b['reason']?.toString();
            final startTime = b['startTime']?.toString() ?? '';
            final endTime = b['endTime']?.toString() ?? '';
            final timeLabel = (startTime.isNotEmpty && endTime.isNotEmpty)
                ? '$startTime – $endTime'
                : '';
            return Positioned(
              top: top,
              left: 4.w,
              right: 4.w,
              height: height.clamp(22.h, double.infinity),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border(
                    left: BorderSide(color: Colors.red.shade600, width: 3),
                    top: BorderSide(color: Colors.red.shade200, width: 0.5),
                    right: BorderSide(color: Colors.red.shade200, width: 0.5),
                    bottom: BorderSide(color: Colors.red.shade200, width: 0.5),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Text(
                            'Blocked',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              timeLabel,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 6.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (reason != null &&
                        reason.isNotEmpty &&
                        height > 36.h) ...[
                      SizedBox(height: 2.h),
                      Text(
                        reason,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 6.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          // Appointments
          ...appts.map((appt) => _buildApptCard(appt, 6.w, 6.w, quarterSlot)),
        ]),
      ),
    );
  }

  // ── appointment card ───────────────────────────────
  Widget _buildApptCard(
      Appointments appt, double left, double right, double quarterSlot) {
    final startMin = appt.startTime.hour * 60 + appt.startTime.minute;
    final top = (startMin / 15) * quarterSlot;
    final height = (appt.duration.inMinutes / 15) * quarterSlot;
    final clampH = height.clamp(60.h, slotHeight * 4);
    final sc = _getStatusColor(appt.status);
    final bg = _getStatusBg(appt.status);

    return Positioned(
      top: top,
      left: left,
      right: right,
      height: clampH,
      child: GestureDetector(
        onTap: () {
          if (appt.id.isNotEmpty) {
            print('🔘 Tapped appointment: ${appt.clientName} (ID: ${appt.id})');
            showDialog(
              context: context,
              builder: (context) =>
                  AppointmentDetailDialog(appointmentId: appt.id),
            );
          } else {
            print('⚠️ Appointment has no ID: ${appt.clientName}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No ID for this appointment')),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6.r),
            border: Border(
              left: BorderSide(color: sc, width: 3.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 3.h, 4.w, 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name + status chip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                appt.clientName,
                                style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: sc.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(appt.status,
                                  style: TextStyle(
                                      fontSize: 6.sp,
                                      fontWeight: FontWeight.bold,
                                      color: sc)),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        // Service name
                        Text(appt.serviceName,
                            style: TextStyle(
                                fontSize: 7.sp, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 3.h),
                        // Booking mode chip
                        Row(children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                appt.mode.toLowerCase() == 'online'
                                    ? Icons.language
                                    : Icons.store,
                                size: 8.sp,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                appt.mode.toLowerCase() == 'online'
                                    ? 'Web Booking'
                                    : 'Offline',
                                style: TextStyle(
                                    fontSize: 6.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor),
                              ),
                            ]),
                          ),
                          if (appt.hasAddOns) ...[
                            SizedBox(width: 3.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5.r),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                Icon(Icons.add_circle_outline,
                                    size: 7.sp, color: Colors.orange[800]),
                                SizedBox(width: 2.w),
                                Text('+${appt.addOnCount}',
                                    style: TextStyle(
                                        fontSize: 6.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800])),
                              ]),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
