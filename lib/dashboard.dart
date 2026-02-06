import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/animation.dart';

import 'Notification.dart';
import 'Profile.dart';
import 'view_appointment.dart';
import 'widgets/custom_drawer.dart';
import 'calender.dart';
import 'widgets/create_appointment_form.dart';
import 'shared_data.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _filter = 0;
  VendorProfile? _profile;
  bool _isLoadingProfile = true;

  late AnimationController _kpiAnimationController;
  late Animation<double> _kpiFadeAnimation;

  late List<AnimationController> _appointmentControllers;
  late List<Animation<double>> _appointmentAnimations;

  @override
  void initState() {
    super.initState();

    _kpiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _kpiFadeAnimation = CurvedAnimation(
      parent: _kpiAnimationController,
      curve: Curves.easeInOut,
    );

    _appointmentControllers = List.generate(
      appointments.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );

    _appointmentAnimations = _appointmentControllers
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            ))
        .toList();

    _fetchProfile();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _kpiAnimationController.forward();
      for (var controller in _appointmentControllers) {
        controller.forward();
      }
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ApiService.getVendorProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
      debugPrint('Error fetching profile for dashboard: $e');
    }
  }

  @override
  void dispose() {
    _kpiAnimationController.dispose();
    for (var controller in _appointmentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final String today = DateFormat('dd MMM yyyy').format(DateTime.now());
    ScreenUtil.init(context, designSize: const Size(375, 812));

    appointments.sort((a, b) {
      final timeA = TimeOfDay(
        hour: int.parse(a['time'].split(' ')[1].split(':')[0]) +
            (a['time'].contains('PM') && !a['time'].contains('12') ? 12 : 0),
        minute: int.parse(a['time'].split(':')[1].substring(0, 2)),
      );
      final timeB = TimeOfDay(
        hour: int.parse(b['time'].split(' ')[1].split(':')[0]) +
            (b['time'].contains('PM') && !b['time'].contains('12') ? 12 : 0),
        minute: int.parse(b['time'].split(':')[1].substring(0, 2)),
      );
      return timeA.hour.compareTo(timeB.hour) != 0
          ? timeA.hour.compareTo(timeB.hour)
          : timeA.minute.compareTo(timeB.minute);
    });

    final double baseFontScale = (mediaQuery.size.width / 375).clamp(0.8, 0.95);

    // Demo summary data (replace with real values)
    final int todaysDone = 0;
    final double todaysEarnings = 0;
    final int upcomingCount = 0;
    final int occupancyPercent = 0;

    const double bottomSheetInitialPadding = 120;

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ).apply(fontSizeFactor: baseFontScale),
        ),
        child: Scaffold(
          drawer: CustomDrawer(
            currentPage: 'Dashboard',
            userName: _profile?.businessName ?? 'HarshalSpa',
            profileImageUrl: _profile?.profileImage ?? '',
          ),
          backgroundColor: const Color(0xFFF7F7F8),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    expandedHeight: 150.h,
                    leading: Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationPage()),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProfilePage(profile: _profile)),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 1.w),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage: (_profile != null &&
                                      _profile!.profileImage.isNotEmpty)
                                  ? NetworkImage(_profile!.profileImage)
                                  : const AssetImage(
                                          'assets/images/profile.jpeg')
                                      as ImageProvider,
                              backgroundColor: Colors.white,
                              child: (_profile == null ||
                                      _profile!.profileImage.isEmpty)
                                  ? Icon(Icons.person,
                                      size: 16.sp, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(16.w, 70.h, 16.w, 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                _MiniChip(
                                    text: today,
                                    icon: Icons.calendar_month_outlined),
                                SizedBox(width: 8.w),
                                _MiniChip(
                                    text: '$todaysDone done',
                                    icon: Icons.check_circle_outline),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickAction(
                                    label: 'New booking',
                                    icon: Icons.add,
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (BuildContext context) {
                                          return SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.8,
                                            child:
                                                const CreateAppointmentForm(),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _QuickAction(
                                    label: 'View calendar',
                                    icon: Icons.calendar_view_week_outlined,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const Calendar()),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(10.h),
                      child: Container(
                        height: 10.h,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F7F8),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                      ),
                    ),
                  ),

                  // ---- OVERVIEW ----
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overview',
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700)),
                          Text('Swipe',
                              style: TextStyle(
                                  fontSize: 11.sp, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120.h,
                      child: FadeTransition(
                        opacity: _kpiFadeAnimation,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (_, __) => SizedBox(width: 12.w),
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return _KpiCard(
                                title: "Today's earnings",
                                value: '₹ ${todaysEarnings.toStringAsFixed(0)}',
                                subtitle: '$todaysDone appointments',
                                icon: Icons.payments_outlined,
                                accent: const Color(0xFF111827),
                              );
                            }
                            if (i == 1) {
                              return _KpiCard(
                                title: 'Upcoming',
                                value: '$upcomingCount',
                                subtitle: 'Next 7 days',
                                icon: Icons.event_available_outlined,
                                accent: Theme.of(context).primaryColor,
                              );
                            }
                            if (i == 2) {
                              return _KpiCard(
                                title: 'Booked hours',
                                value: '0',
                                subtitle: '$occupancyPercent% occupancy',
                                icon: Icons.schedule_outlined,
                                accent: const Color(0xFF16A34A),
                              );
                            }

                            // ✅ UPDATED: Top services card shows only 1 top service
                            return _KpiCard(
                              title: 'Top service',
                              value: 'Top',
                              subtitle: 'Today',
                              icon: Icons.local_fire_department_outlined,
                              accent: const Color(0xFFF97316),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _TopServiceSingle(
                                    baseFontScale: baseFontScale),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // ---- APPOINTMENTS ----
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Appointments',
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700)),
                          Text('Timeline',
                              style: TextStyle(
                                  fontSize: 11.sp, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _FilterChip(
                              label: 'All',
                              selected: _filter == 0,
                              onTap: () => setState(() => _filter = 0)),
                          _FilterChip(
                              label: 'Past',
                              selected: _filter == 1,
                              onTap: () => setState(() => _filter = 1)),
                          _FilterChip(
                              label: 'Current',
                              selected: _filter == 2,
                              onTap: () => setState(() => _filter = 2)),
                          _FilterChip(
                              label: 'Future',
                              selected: _filter == 3,
                              onTap: () => setState(() => _filter = 3)),
                        ],
                      ),
                    ),
                  ),

                  if (appointments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _EmptyStateCard(
                          title: 'No upcoming appointments',
                          subtitle: 'Create a booking to see it here.',
                          actionLabel: 'Create',
                          onAction: () {},
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList.separated(
                        itemCount: appointments.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final appt = appointments[index];
                          return FadeTransition(
                            opacity: _appointmentAnimations[index],
                            child: _TimelineAppointmentTile(
                              appointment: appt,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ViewAppointmentPage(appointment: appt),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  SliverToBoxAdapter(
                      child: SizedBox(height: bottomSheetInitialPadding.h)),
                ],
              ),

              // ---- DRAGGABLE STAFF COMMISSION PANEL ----
              DraggableScrollableSheet(
                initialChildSize: 0.12,
                minChildSize: 0.10,
                maxChildSize: 0.65,
                builder: (context, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Staff Commission',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700)),
                              Text('Pull up',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            controller: controller,
                            padding:
                                EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                            children: [
                              Text('All Time',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600])),
                              SizedBox(height: 10.h),
                              if (staffList.isEmpty)
                                Center(
                                  child: Text('No staff added yet.',
                                      style: TextStyle(
                                          fontSize: 12.sp, color: Colors.grey)),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowHeight: 36,
                                    dataRowMinHeight: 38,
                                    dataRowMaxHeight: 44,
                                    columnSpacing: 22,
                                    headingRowColor: MaterialStateProperty.all(
                                        const Color(0xFFF5F5F5)),
                                    columns: [
                                      DataColumn(
                                          label: Text('Staff',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      DataColumn(
                                          label: Text('Appts',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      DataColumn(
                                          label: Text('Sales',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      DataColumn(
                                          label: Text('Comm.',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                    ],
                                    rows: [
                                      ...staffList.map((staff) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(staff['name'] ?? '',
                                                style: TextStyle(
                                                    fontSize: 11.sp))),
                                            DataCell(Text(
                                                '${staff['appointments']}',
                                                style: TextStyle(
                                                    fontSize: 11.sp))),
                                            DataCell(Text('₹ ${staff['sales']}',
                                                style: TextStyle(
                                                    fontSize: 11.sp))),
                                            DataCell(Text(
                                                '₹ ${staff['commission']}',
                                                style: TextStyle(
                                                    fontSize: 11.sp))),
                                          ],
                                        );
                                      }).toList(),
                                      DataRow(
                                        color: MaterialStateProperty.all(
                                            Colors.grey.shade100),
                                        cells: [
                                          DataCell(Text('Total',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                          DataCell(Text(
                                              getTotal('appointments'),
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                          DataCell(Text(
                                              '₹ ${getTotal('sales')}',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                          DataCell(Text(
                                              '₹ ${getTotal('commission')}',
                                              style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- UPDATED: show only 1 top service -----------------

class _TopServiceSingle extends StatelessWidget {
  final double baseFontScale;
  const _TopServiceSingle({required this.baseFontScale});

  final List<Map<String, dynamic>> services = const [
    {'service': 'Spa', 'sold': 2},
    {'service': 'Facial', 'sold': 5},
    {'service': 'Haircut', 'sold': 3},
    {'service': 'Manicure', 'sold': 4},
  ];

  Map<String, dynamic> _topService() {
    Map<String, dynamic> top = services.first;
    for (final s in services) {
      final sold = (s['sold'] as num?)?.toInt() ?? 0;
      final topSold = (top['sold'] as num?)?.toInt() ?? 0;
      if (sold > topSold) top = s;
    }
    return top;
  }

  @override
  Widget build(BuildContext context) {
    final top = _topService();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            top['service'] ?? '',
            style: TextStyle(
              fontSize: 10 * baseFontScale,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${top['sold']} sold',
            style: TextStyle(
              fontSize: 10 * baseFontScale,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------- UI Widgets (unchanged from your file) -----------------

class _MiniChip extends StatefulWidget {
  final String text;
  final IconData icon;

  const _MiniChip({required this.text, required this.icon});

  @override
  State<_MiniChip> createState() => _MiniChipState();
}

class _MiniChipState extends State<_MiniChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: Colors.black87),
              SizedBox(width: 4.w),
              Text(widget.text,
                  style: TextStyle(fontSize: 10.sp, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.label, required this.icon, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 14, color: Colors.black),
                SizedBox(width: 6.w),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? Theme.of(context).primaryColor
        : const Color(0xFFF3F4F6);
    final fg = widget.selected ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(
            widget.label,
            style: TextStyle(
                fontSize: 10.sp, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? child;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.child,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 200.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 14, color: widget.accent),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                          fontSize: 11.sp, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(widget.value,
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 2.h),
              Text(widget.subtitle,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
              if (widget.child != null) ...[
                SizedBox(height: 6.h),
                Expanded(child: widget.child!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineAppointmentTile extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const _TimelineAppointmentTile(
      {required this.appointment, required this.onTap});

  @override
  State<_TimelineAppointmentTile> createState() =>
      _TimelineAppointmentTileState();
}

class _TimelineAppointmentTileState extends State<_TimelineAppointmentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _statusColor() => const Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.appointment['time'],
                        style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 2.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.appointment['service'],
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2.h),
                      Text(
                        '${widget.appointment['client']} • ${widget.appointment['duration']} • ${widget.appointment['staff']}',
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_clock, size: 12, color: color),
                          SizedBox(width: 2.w),
                          Text('New',
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text('₹ ${widget.appointment['price']}',
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  State<_EmptyStateCard> createState() => _EmptyStateCardState();
}

class _EmptyStateCardState extends State<_EmptyStateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_busy,
                    size: 16, color: Colors.black87),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 1.h),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 10.sp, color: Colors.grey[600])),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onAction,
                child:
                    Text(widget.actionLabel, style: TextStyle(fontSize: 10.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Demo data -----------------

// Using shared data service
final List<Map<String, dynamic>> staffList =
    sharedDataService.getDashboardStaffList();

// Using shared data service
final List<Map<String, dynamic>> appointments =
    sharedDataService.getDashboardAppointments();

String getTotal(String key) {
  double total = 0.0;
  for (var staff in staffList) {
    total += double.tryParse(staff[key].toString()) ?? 0.0;
  }
  return total.toStringAsFixed(2);
}
