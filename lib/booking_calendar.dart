import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'appointment_model.dart';
import 'vendor_model.dart';
import 'calender.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/create_appointment_form.dart';
import 'widgets/block_staff_time_dialog.dart';
import 'My_Profile.dart';

// ── Brand colors (file-private to avoid duplicate-definition conflicts)
const Color _kPrimary = Color(0xFF3D1A47);
const Color _kBg = Color(0xFFF7F7F8);
const Color _kCard = Colors.white;
const Color _kBorder = Color(0xFFEEEEEE);

// ─────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────
class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  // ── Week navigation
  DateTime _weekStart = _mondayOf(DateTime.now());
  int _selDayIndex = DateTime.now().weekday - 1; // 0=Mon … 6=Sun

  // ── Filter
  String _selFilter = 'All';
  static const _filters = ['All', 'Wedding', 'Home Service'];

  // ── Data
  List<AppointmentModel> _allAppointments = [];
  List<StaffMember> _staff = [];
  VendorProfile? _profile;
  String? _selStaffId;
  bool _isLoading = true;

  List<Map<String, dynamic>> get _days => List.generate(14, (i) {
        final d = _weekStart.add(Duration(days: i));
        return {'lbl': DateFormat('E').format(d), 'n': d.day, 'date': d};
      });

  DateTime get _selectedDate => (_days[_selDayIndex]['date'] as DateTime);

  List<AppointmentModel> get _filteredAppointments {
    return _allAppointments.where((a) {
      // Date filter
      if (a.date != null) {
        final ad = DateTime(a.date!.year, a.date!.month, a.date!.day);
        final sd = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
        if (ad != sd) return false;
      }
      // Staff filter
      if (_selStaffId != null) {
        if (a.staff?.id != _selStaffId) return false;
      }
      // Category filter
      if (_selFilter == 'Wedding') return a.isWeddingService == true;
      if (_selFilter == 'Home Service') return a.isHomeService == true;
      return true;
    }).toList()
      ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
  }

  int get _confirmedCount => _filteredAppointments
      .where((a) =>
          (a.status ?? '').toLowerCase() == 'confirmed' ||
          (a.status ?? '').toLowerCase() == 'completed')
      .length;

  int get _pendingCount => _filteredAppointments
      .where((a) => (a.status ?? '').toLowerCase() == 'pending')
      .length;

  int get _cancelledCount => _filteredAppointments
      .where((a) => (a.status ?? '').toLowerCase() == 'cancelled')
      .length;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAppointments(limit: 1000),
        ApiService.getStaff(),
        ApiService.getVendorProfile(),
      ]);
      if (mounted) {
        final appointmentData = results[0] as Map<String, dynamic>;
        setState(() {
          _allAppointments = appointmentData['data'] ?? [];
          _staff = results[1] as List<StaffMember>;
          _profile = results[2] as VendorProfile;
        });
      }
    } catch (e) {
      debugPrint('BookingCalendar load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static DateTime _mondayOf(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String get _monthYearLabel =>
      DateFormat('MMMM yyyy').format(_weekStart.add(const Duration(days: 3)));

  void _openCalendar(AppointmentModel appt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Calendar(
          initialDate: appt.date ?? _selectedDate,
          initialAppointmentId: appt.id,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openCreateForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAppointmentForm(
          onAppointmentCreated: (_) => _loadData(),
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openBlockTimeDialog() {
    showDialog(
      context: context,
      builder: (_) => BlockStaffTimeDialog(
        staff: _staff,
        onBlocked: _loadData,
      ),
    );
  }

  Future<void> _selectMonthYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _weekStart = _mondayOf(picked);
        _selDayIndex = picked.weekday - 1;
        if (_selDayIndex < 0) _selDayIndex = 0;
        if (_selDayIndex >= _days.length) _selDayIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        drawer: CustomDrawer(
          currentPage: 'Booking Calendar',
          userName: _profile?.businessName ?? '',
          profileImageUrl: _profile?.profileImage ?? '',
        ),
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Header
            _Header(
              monthYearLabel: _monthYearLabel,
              selDayIndex: _selDayIndex,
              days: _days,
              onDayTap: (i) => setState(() => _selDayIndex = i),
              onPrev: () => setState(() =>
                  _weekStart = _weekStart.subtract(const Duration(days: 7))),
              onNext: () => setState(
                  () => _weekStart = _weekStart.add(const Duration(days: 7))),
              onRefresh: _loadData,
              staff: _staff,
              selStaffId: _selStaffId,
              onStaffChanged: (id) => setState(() => _selStaffId = id),
              onAddTap: _openCreateForm,
              onBlockTap: _openBlockTimeDialog,
              onMonthYearTap: _selectMonthYear,
              profile: _profile,
            ),
            // ── Summary bar
            _SummaryBar(
              date: _selectedDate,
              total: _filteredAppointments.length,
              confirmed: _confirmedCount,
              pending: _pendingCount,
              cancelled: _cancelledCount,
            ),
            // ── Category filter chips
            _FilterRow(
              filters: _filters,
              selected: _selFilter,
              onSelect: (f) => setState(() => _selFilter = f),
            ),
            // ── List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : _filteredAppointments.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 80.h),
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (_, i) => _AppointmentCard(
                            appt: _filteredAppointments[i],
                            onTap: () =>
                                _openCalendar(_filteredAppointments[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String monthYearLabel;
  final int selDayIndex;
  final List<Map<String, dynamic>> days;
  final ValueChanged<int> onDayTap;
  final VoidCallback onPrev, onNext, onRefresh;
  final List<StaffMember> staff;
  final String? selStaffId;
  final ValueChanged<String?> onStaffChanged;
  final VoidCallback onAddTap;
  final VoidCallback onBlockTap;
  final VoidCallback onMonthYearTap;
  final VendorProfile? profile;

  const _Header({
    required this.monthYearLabel,
    required this.selDayIndex,
    required this.days,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
    required this.onRefresh,
    required this.staff,
    required this.selStaffId,
    required this.onStaffChanged,
    required this.onAddTap,
    required this.onBlockTap,
    required this.onMonthYearTap,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      child: Column(children: [
        // Improved AppBar row (Dashboard style)
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 0),
            child: Row(children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              Expanded(
                child: Text('Booking Calendar',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh,
                    size: 20, color: Color.fromRGBO(0, 0, 0, 0.541)),
                onPressed: onRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    size: 22, color: Colors.black87),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => My_Profile())),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: _kPrimary,
                  child: ClipOval(
                    child: (profile != null && profile!.profileImage.isNotEmpty)
                        ? Image.network(
                            profile!.profileImage,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => _buildInitial(),
                            loadingBuilder: (ctx, child, progress) =>
                                progress == null ? child : _buildInitial(),
                          )
                        : _buildInitial(),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
            ]),
          ),
        ),
        SizedBox(height: 5.h),

        // Staff + Add + Block Time
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(children: [
            // Dynamic Staff Selection Dropdown
            _OutlineBtn(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selStaffId,
                  hint: Text('All Staff',
                      style: TextStyle(
                          fontSize: 9.sp, fontWeight: FontWeight.w500)),
                  icon: Icon(Icons.keyboard_arrow_down,
                      size: 12, color: Colors.grey),
                  onChanged: onStaffChanged,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child:
                          Text('All Staff', style: TextStyle(fontSize: 9.sp)),
                    ),
                    ...staff.map((s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.fullName ?? 'N/A',
                              style: TextStyle(fontSize: 9.sp)),
                        )),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Navigation to Create Appointment Form
            _HeaderActionBtn(
              icon: Icons.add,
              label: 'Add',
              color: _kPrimary,
              onTap: onAddTap,
            ),
            SizedBox(width: 6.w),
            _HeaderActionBtn(
              icon: Icons.timer_outlined,
              label: 'Block Time',
              color: const Color(0xFFFF6B6B),
              onTap: onBlockTap,
            ),
          ]),
        ),
        SizedBox(height: 7.h),

        // Month + nav
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(children: [
            GestureDetector(
              onTap: onMonthYearTap,
              child: Row(
                children: [
                  Text(monthYearLabel,
                      style: TextStyle(
                          fontSize: 10.sp, fontWeight: FontWeight.w700)),
                  SizedBox(width: 2.w),
                  Icon(Icons.keyboard_arrow_down,
                      size: 13, color: Colors.black87),
                ],
              ),
            ),
            const Spacer(),
          ]),
        ),
        SizedBox(height: 7.h),

        // Week strip
        SizedBox(
          height: 50.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final sel = i == selDayIndex;
              final isToday = DateUtils.isSameDay(
                  days[i]['date'] as DateTime, DateTime.now());
              return GestureDetector(
                onTap: () => onDayTap(i),
                child: Container(
                  width: 38.w,
                  margin: EdgeInsets.only(right: 6.w),
                  decoration: BoxDecoration(
                    color: sel ? _kPrimary : _kCard,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: sel
                            ? _kPrimary
                            : isToday
                                ? _kPrimary.withOpacity(0.4)
                                : _kBorder),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(days[i]['lbl'],
                            style: TextStyle(
                                fontSize: 7.sp,
                                color: sel ? Colors.white70 : Colors.grey[500],
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 2.h),
                        Text('${days[i]['n']}',
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : isToday
                                        ? _kPrimary
                                        : Colors.black87)),
                      ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 7.h),
      ]),
    );
  }

  Widget _buildInitial() {
    return Text(
      (profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
          color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUMMARY BAR
// ─────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final DateTime date;
  final int total, confirmed, pending, cancelled;

  const _SummaryBar({
    required this.date,
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      margin: EdgeInsets.only(top: 5.h),
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 10.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$total Total Appointment${total == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700)),
          Text(DateFormat('EEEE, d MMM').format(date),
              style: TextStyle(fontSize: 7.5.sp, color: Colors.grey[500])),
        ]),
        SizedBox(height: 7.h),
        Row(children: [
          _StatChip(
              label: 'CONFIRMED',
              count: '$confirmed',
              color: const Color(0xFF2E7D32)),
          SizedBox(width: 6.w),
          _StatChip(
              label: 'PENDING',
              count: '$pending',
              color: const Color(0xFFE65100)),
          SizedBox(width: 6.w),
          _StatChip(
              label: 'CANCELLED',
              count: '$cancelled',
              color: const Color(0xFFC62828)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER ROW
// ─────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow(
      {required this.filters, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: EdgeInsets.fromLTRB(14.w, 5.h, 14.w, 7.h),
      child: Row(
        children: filters.map((f) {
          final sel = f == selected;
          return Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: sel ? _kPrimary : _kCard,
                  border: Border.all(color: sel ? _kPrimary : _kBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.black54)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// APPOINTMENT CARD
// ─────────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appt;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appt, required this.onTap});

  Color get _statusColor {
    switch ((appt.status ?? '').toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      case 'pending':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color get _statusBg => _statusColor.withOpacity(0.10);
  Color get _accentColor => _statusColor.withOpacity(0.7);

  String _fmt12(String? t) {
    if (t == null || !t.contains(':')) return t ?? '--';
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1].padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      h = h % 12;
      if (h == 0) h = 12;
      return '$h:$m $ampm';
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startFmt = _fmt12(appt.startTime);
    final endFmt = _fmt12(appt.endTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 7.h),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Time col
              SizedBox(
                width: 46.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(startFmt,
                        style: TextStyle(
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    Expanded(
                        child: Center(
                      child: Container(width: 1, color: Colors.grey[200]),
                    )),
                    Text(endFmt,
                        style:
                            TextStyle(fontSize: 7.sp, color: Colors.grey[400])),
                  ],
                ),
              ),
              SizedBox(width: 5.w),
              // ── Accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 5.w),
              // ── Card body
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.025),
                          blurRadius: 4,
                          offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + status chip + menu
                      Row(children: [
                        Expanded(
                          child: Text(
                            appt.clientName ?? 'Unknown Client',
                            style: TextStyle(
                                fontSize: 10.sp, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 2.h),
                          decoration: BoxDecoration(
                              color: _statusBg,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(appt.status ?? 'Pending',
                              style: TextStyle(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor)),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.more_vert,
                            size: 13, color: Colors.grey[300]),
                      ]),
                      SizedBox(height: 4.h),
                      // Service
                      _InfoRow(
                          icon: Icons.cut_rounded,
                          label: appt.serviceName ?? 'N/A'),
                      if (appt.addOns != null && appt.addOns!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(left: 12.w, top: 2.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: appt.addOns!
                                .map((addon) => Text(
                                      "+ ${addon.name ?? 'Add-on'} (₹${addon.price?.toStringAsFixed(0)})",
                                      style: TextStyle(
                                          fontSize: 7.sp,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic),
                                    ))
                                .toList(),
                          ),
                        ),
                      SizedBox(height: 3.h),
                      // Duration + Staff
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 9, color: Colors.grey[400]),
                        SizedBox(width: 3.w),
                        Text(
                            appt.duration != null
                                ? '${appt.duration} min'
                                : '--',
                            style: TextStyle(
                                fontSize: 7.5.sp, color: Colors.grey[500])),
                        SizedBox(width: 8.w),
                        Icon(Icons.person_outline_rounded,
                            size: 9, color: Colors.grey[400]),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                              appt.staff?.fullName ?? appt.staffName ?? 'N/A',
                              style: TextStyle(
                                  fontSize: 7.5.sp, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      SizedBox(height: 5.h),
                      Divider(
                          height: 1, thickness: 0.5, color: Colors.grey[100]),
                      SizedBox(height: 4.h),
                      // Price + booking type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '₹ ${(appt.finalAmount ?? appt.amount ?? 0).toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700)),
                          Row(children: [
                            Icon(
                                appt.isHomeService == true
                                    ? Icons.home_outlined
                                    : appt.isWeddingService == true
                                        ? Icons.favorite_border
                                        : Icons.store_rounded,
                                size: 9,
                                color: Colors.grey[400]),
                            SizedBox(width: 3.w),
                            Text(appt.mode ?? 'offline',
                                style: TextStyle(
                                    fontSize: 7.sp,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic)),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_available_outlined,
              size: 44.sp, color: Colors.grey[300]),
          SizedBox(height: 10.h),
          Text('No appointments',
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400])),
          SizedBox(height: 4.h),
          Text('Nothing scheduled for this day',
              style: TextStyle(fontSize: 9.sp, color: Colors.grey[400])),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// SMALL SHARED WIDGETS
// ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 9, color: Colors.grey[400]),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 7.5.sp, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis),
        ),
      ]);
}

/// StatChip: no background, just colored text + count
class _StatChip extends StatelessWidget {
  final String label, count;
  final Color color;
  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 5.5.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3)),
            SizedBox(height: 2.h),
            Text(count,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ]),
        ),
      );
}

class _OutlineBtn extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _OutlineBtn({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: _kCard,
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      );
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeaderActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: _kCard,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          SizedBox(width: 3.w),
          Text(label,
              style: TextStyle(
                  fontSize: 9.sp, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 14, color: Colors.black87),
        ),
      );
}
