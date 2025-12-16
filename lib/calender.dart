import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'widgets/create_appointment_form.dart';
import 'widgets/custom_drawer.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'shared_data.dart';

class Appointments {
  final DateTime startTime;
  final Duration duration;
  final String clientName;
  final String serviceName;
  final String staffName;
  final String status;
  final bool isWebBooking;

  Appointments({
    required this.startTime,
    required this.duration,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
    this.status = 'New',
    this.isWebBooking = false,
  });

  DateTime get endTime => startTime.add(duration);
}

class Calendar extends StatefulWidget {
  const Calendar({super.key});
  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDate = DateTime.now();
  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(0);

  late final ScrollController _verticalScrollController;
  late final ScrollController _horizontalScrollController;
  late final ScrollController _staffHeaderScrollController;

  Timer? _timer;

  static const double baseSlotHeight = 220.0;
  double get slotHeight => baseSlotHeight.h;

  static const double staffColumnBaseWidth = 160.0;
  double get staffColumnWidth => staffColumnBaseWidth.w;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double _timeToOffset(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    final quarterSlot = slotHeight / 4;
    return (minutes / 15) * quarterSlot;
  }

  // Using shared data service
  final List<String> staffName = sharedDataService.staffMembers.map((staff) => staff.name).toList();

  // Using shared data service
  final Map<String, Map<String, String>> staffInfo = {
    for (var staff in sharedDataService.staffMembers)
      staff.name: {'role': staff.role, 'availability': staff.availability}
  };

  final Map<String, bool> selectedStaff = {};
  late final List<Appointments> _appointments;

  void _setSelectedDate(DateTime newDate) {
    final d = _dateOnly(newDate);
    if (DateUtils.isSameDay(_selectedDate, d)) return;
    setState(() => _selectedDate = d);
  }

  @override
  void initState() {
    super.initState();

    _selectedDate = _dateOnly(DateTime.now());

    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _staffHeaderScrollController = ScrollController();

    for (var i = 0; i < staffName.length; i++) {
      selectedStaff[staffName[i]] = i < 2;
    }

    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    // Using shared data service
    _appointments = sharedDataService.appointments.map((sharedAppt) => Appointments(
      startTime: sharedAppt.startTime,
      duration: sharedAppt.duration,
      clientName: sharedAppt.clientName,
      serviceName: sharedAppt.serviceName,
      staffName: sharedAppt.staffName,
      status: sharedAppt.status,
      isWebBooking: sharedAppt.isWebBooking,
    )).toList();

    // Sync header with body scroll (clamp to header max)
    _horizontalScrollController.addListener(() {
      if (!_horizontalScrollController.hasClients || !_staffHeaderScrollController.hasClients) return;
      final target = _horizontalScrollController.offset;
      final max = _staffHeaderScrollController.position.maxScrollExtent;
      _staffHeaderScrollController.jumpTo(target.clamp(0.0, max));
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _timerNotifier.value = DateTime.now().millisecondsSinceEpoch;
    });
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Date picker copied from your first code (Cupertino bottom sheet)
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
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
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
                  child: Text('Done', style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStaffSelection() {
    final tempSelectedStaff = Map<String, bool>.from(selectedStaff);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  Text('Select Staff', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: staffName.length,
                      itemBuilder: (context, index) {
                        final staff = staffName[index];
                        return ListTile(
                          title: Text(staff),
                          trailing: Checkbox(
                            value: tempSelectedStaff[staff] ?? false,
                            onChanged: (value) {
                              setModalState(() {
                                tempSelectedStaff[staff] = value ?? false;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedStaff.updateAll((key, value) => false);
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedStaff
                                  ..clear()
                                  ..addAll(tempSelectedStaff);
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              minimumSize: Size(double.infinity, 40.h),
                            ),
                            child: Text('Apply', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateAppointmentForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: CreateAppointmentForm(
            onAppointmentCreated: (appointment) {
              // Add the new appointment to the list
              setState(() {
                _appointments.add(appointment);
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quarterSlot = slotHeight / 4;

    final selectedStaffList =
        selectedStaff.entries.where((e) => e.value).map((e) => e.key).toList();

    final Map<String, List<Appointments>> staffAppts = {};
    for (final staff in selectedStaffList) {
      staffAppts[staff] = _appointments
          .where((a) => a.staffName == staff && DateUtils.isSameDay(a.startTime, _selectedDate))
          .toList();
    }

    final totalApptsForDay =
        _appointments.where((a) => DateUtils.isSameDay(a.startTime, _selectedDate)).length;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Calendar'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text('Calendar', style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, size: 20.sp),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage())),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
              child: CircleAvatar(radius: 16.r, backgroundImage: const AssetImage('assets/images/profile.jpeg')),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Date navigation
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 16.sp),
                  onPressed: () => _setSelectedDate(_selectedDate.subtract(const Duration(days: 1))),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                // Keep this layout, but use Cupertino picker on tap (from first code)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(_selectedDate),
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: _showMonthYearPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            style: TextStyle(fontSize: 10.sp, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.arrow_drop_down, size: 16.sp, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),

                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16.sp),
                  onPressed: () => _setSelectedDate(_selectedDate.add(const Duration(days: 1))),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),

          // Staff header
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: SingleChildScrollView(
              controller: _staffHeaderScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(width: 60.w),
                  ...selectedStaffList.map(
                    (staff) => Container(
                      width: staffColumnWidth,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff,
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(staffInfo[staff]?['role'] ?? '', style: TextStyle(fontSize: 8.sp, color: Colors.grey[700])),
                          SizedBox(height: 1.h),
                          Text(
                            staffInfo[staff]?['availability'] ?? '',
                            style: TextStyle(fontSize: 7.sp, color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),

          // Grid
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: SizedBox(
                height: 24 * slotHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                                child: Text('$hour:00 $period', style: TextStyle(fontSize: 8.sp, color: Colors.black87)),
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
                          child: Row(
                            children: selectedStaffList.map((staff) {
                              final appts = staffAppts[staff] ?? [];
                              return SizedBox(
                                width: staffColumnWidth,
                                height: 24 * slotHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1)),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const SizedBox.expand(),

                                      // grid lines
                                      ...List.generate(97, (i) {
                                        return Positioned(
                                          top: i * quarterSlot,
                                          left: 0,
                                          right: 0,
                                          child: Divider(
                                            thickness: i % 4 == 0 ? 1.0 : 0.4,
                                            color: i % 4 == 0 ? Colors.grey[400] : Colors.grey[200],
                                          ),
                                        );
                                      }),

                                      // appointments
                                      ...appts.map((appt) {
                                        final startMin = appt.startTime.hour * 60 + appt.startTime.minute;
                                        final top = (startMin / 15) * quarterSlot;
                                        final height = (appt.duration.inMinutes / 15) * quarterSlot;

                                        return Positioned(
                                          top: top,
                                          left: 6.w,
                                          right: 6.w,
                                          height: height,
                                          child: Container(
                                            padding: EdgeInsets.all(4.w),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F7FA),
                                              borderRadius: BorderRadius.circular(4.r),
                                              border: Border.all(color: Colors.cyan[200]!),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${DateFormat.Hm().format(appt.startTime)} - ${DateFormat.Hm().format(appt.endTime)}',
                                                  style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  appt.serviceName,
                                                  style: TextStyle(fontSize: 7.sp, fontWeight: FontWeight.w600),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  appt.clientName,
                                                  style: TextStyle(fontSize: 6.sp),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 2.h),
                                                Row(
                                                  children: [
                                                    Icon(Icons.circle, size: 4.sp, color: _getStatusColor(appt.status)),
                                                    SizedBox(width: 2.w),
                                                    Text(
                                                      appt.status,
                                                      style: TextStyle(fontSize: 6.sp, color: _getStatusColor(appt.status)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Time line (red on today, grey otherwise)
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
                          child: Container(height: 2, color: isToday ? Colors.red : Colors.grey.shade400),
                        );
                      },
                    ),

                    if (totalApptsForDay == 0)
                      Positioned(
                        top: 12.h,
                        left: 70.w,
                        right: 12.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'No appointments for ${DateFormat('EEE, MMM d').format(_selectedDate)}',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _showCreateAppointmentForm,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: 45.w,
            height: 45.w,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 6,
              shape: CircleBorder(side: BorderSide(color: Colors.grey[300]!, width: 1)),
              onPressed: _showStaffSelection,
              child: const Icon(Icons.group, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
