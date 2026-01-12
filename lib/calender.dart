import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show HttpClient, X509Certificate;
import 'package:http/io_client.dart' as http_io;
import 'widgets/create_appointment_form.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/appointment_detail_dialog.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'shared_data.dart';

class Appointments {
  final String id; // Added ID
  final DateTime startTime;
  final Duration duration;
  final String clientName;
  final String serviceName;
  final String staffName;
  final String status;
  final bool isWebBooking;
  final String mode;

  Appointments({
    this.id = '', // Default empty
    required this.startTime,
    required this.duration,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
    this.status = 'New',
    this.isWebBooking = false,
    this.mode = 'offline',
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

  // DYNAMIC STAFF DATA - fetched from API
  List<Map<String, dynamic>> staffList = [];
  bool isStaffLoading = false;
  Map<String, bool> selectedStaff = {};
  List<Appointments> _appointments = [];

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double _timeToOffset(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    final quarterSlot = slotHeight / 4;
    return (minutes / 15) * quarterSlot;
  }

//  helper to bypass SSL (same as in staff.dart)
  http_io.IOClient _cookieClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return http_io.IOClient(ioClient);
  }

  void _setSelectedDate(DateTime newDate) {
    final d = _dateOnly(newDate);
    if (DateUtils.isSameDay(_selectedDate, d)) return;
    setState(() {
      _selectedDate = d;
    });
    // Fetch appointments for the new date
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    // We can show a loading indicator if needed, but let's keep it simple for now as it's partial data
    try {
      final models = await ApiService.getAppointments();
      setState(() {
        _appointments = models.map((m) {
          // Combine date and startTime HH:mm
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

          return Appointments(
            id: m.id ?? '',
            startTime: start,
            duration: Duration(minutes: m.duration ?? 30),
            clientName: m.clientName ?? 'Unknown',
            serviceName: m.serviceName ?? 'Unknown Service',
            staffName: m.staffName ?? 'Unassigned',
            status: m.status ?? 'New',
            isWebBooking: m.isMultiService ?? false,
            mode: m.mode ?? 'offline',
          );
        }).toList();
      });
      debugPrint('Loaded ${_appointments.length} appointments from API');
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      // If API fails, maybe keep current or show error
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());

    // Controllers...
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _staffHeaderScrollController = ScrollController();

    // This will now actually fetch real staff and appointments
    _loadStaff();
    _loadAppointments();

    // Timer and scroll sync...
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        throw Exception('No auth token found. Please login again.');
      }

      final client = _cookieClient();
      final response = await client.get(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "Cookie": "crm_access_token=$token",
        },
      );
      client.close();

      debugPrint('Staff API Status: ${response.statusCode}');
      debugPrint('Staff API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> rawList = json.decode(response.body);

        setState(() {
          staffList = rawList.map<Map<String, dynamic>>((item) {
            final map = item as Map<String, dynamic>;
            final fullName =
                (map['fullName'] ?? 'Unknown Staff').toString().trim();
            return {
              'id': map['_id']?.toString() ?? 'unknown',
              'fullName': fullName.isEmpty ? 'No Name' : fullName,
              'position': (map['position'] ?? 'Staff').toString(),
              'status': (map['status'] ?? 'Active').toString(),
              'photo': map['photo']?.toString(),
            };
          }).toList();

          // Auto-select first 2 staff
          selectedStaff.clear();
          for (int i = 0; i < staffList.length && i < 2; i++) {
            final name = staffList[i]['fullName'] as String;
            selectedStaff[name] = true;
          }
          // Ensure others are false
          for (int i = 2; i < staffList.length; i++) {
            final name = staffList[i]['fullName'] as String;
            selectedStaff[name] = false;
          }

          debugPrint('Loaded ${staffList.length} staff members');
          debugPrint(
              'Selected: ${selectedStaff.keys.where((k) => selectedStaff[k]!).toList()}');
        });
      } else {
        throw Exception('Failed to load staff: ${response.statusCode}');
      }
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

      // Fallback to shared data
      setState(() {
        staffList = sharedDataService.staffMembers
            .map((s) => {
                  'id': s.name,
                  'fullName': s.name,
                  'position': s.role,
                  'status': s.availability,
                  'photo': null,
                })
            .toList();

        selectedStaff.clear();
        for (int i = 0; i < staffList.length && i < 2; i++) {
          selectedStaff[staffList[i]['fullName']] = true;
        }
      });
    } finally {
      if (mounted) {
        setState(() => isStaffLoading = false);
      }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return Colors.green[600]!;
      case 'pending':
        return Colors.orange[700]!;
      case 'scheduled':
        return Colors.purple[400]!;
      case 'cancelled':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
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
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
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

  void _showStaffSelection() {
    final tempSelectedStaff = Map<String, bool>.from(selectedStaff);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          return SizedBox(
            height: 300.h,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.all(8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Staff',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Text('${staffList.length} available',
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index]['fullName'];
                      return Container(
                        margin: EdgeInsets.only(bottom: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          title: Text(staff,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500)),
                          trailing: Checkbox(
                            value: tempSelectedStaff[staff] ?? false,
                            onChanged: (value) {
                              setModalState(() {
                                tempSelectedStaff[staff] = value ?? false;
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelectedStaff
                                  .updateAll((key, value) => false);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text('Clear All',
                              style: TextStyle(fontSize: 14.sp)),
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
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text('Apply',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14.sp)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
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
            onAppointmentCreated: (appointments) {
              setState(() {
                _appointments.addAll(appointments);
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
          .where((a) =>
              a.staffName == staff &&
              DateUtils.isSameDay(a.startTime, _selectedDate))
          .toList();
    }

    final totalApptsForDay = _appointments
        .where((a) => DateUtils.isSameDay(a.startTime, _selectedDate))
        .length;

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
        title: Text('Calendar',
            style: GoogleFonts.poppins(
                fontSize: 14.sp, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20.sp),
            onPressed: () {
              _loadStaff();
              _loadAppointments();
            }, // Refresh staff + appointments
            tooltip: 'Refresh Staff',
          ),
          IconButton(
            icon: Icon(Icons.notifications, size: 20.sp),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => NotificationPage())),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfilePage())),
              child: CircleAvatar(
                  radius: 16.r,
                  backgroundImage:
                      const AssetImage('assets/images/profile.jpeg')),
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
                  onPressed: () => _setSelectedDate(
                      _selectedDate.subtract(const Duration(days: 1))),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(_selectedDate),
                      style: TextStyle(
                          fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: _showMonthYearPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.arrow_drop_down,
                              size: 16.sp, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16.sp),
                  onPressed: () => _setSelectedDate(
                      _selectedDate.add(const Duration(days: 1))),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),

          // Staff header - DYNAMIC with real staff data
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: SingleChildScrollView(
              controller: _staffHeaderScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: isStaffLoading
                  ? SizedBox(
                      width:
                          60.w + (selectedStaffList.length * staffColumnWidth),
                      child: Row(
                        children: [
                          SizedBox(width: 60.w),
                          ...List.generate(
                              selectedStaffList.length,
                              (i) => Container(
                                  width: staffColumnWidth,
                                  height: 40.h,
                                  child: Center(
                                      child: SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))))),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        SizedBox(width: 60.w),
                        ...selectedStaffList.map((staffName) {
                          final staff = staffList.firstWhere(
                            (s) => s['fullName'] == staffName,
                            orElse: () => <String, String?>{
                              'position': 'Unknown',
                              'status': 'Active',
                              'fullName': staffName,
                              'id': ''
                            },
                          );
                          return Container(
                            width: staffColumnWidth,
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staffName,
                                  style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  staff['position'] ?? 'Staff',
                                  style: TextStyle(
                                      fontSize: 8.sp, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  staff['status'] ?? 'Active',
                                  style: TextStyle(
                                      fontSize: 7.sp, color: Colors.green[700]),
                                ),
                              ],
                            ),
                          );
                        }),
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
                                child: Text('$hour:00 $period',
                                    style: TextStyle(
                                        fontSize: 8.sp, color: Colors.black87)),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Staff columns - DYNAMIC appointments per staff
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
                          width: selectedStaffList.isEmpty
                              ? 0
                              : (selectedStaffList.length * staffColumnWidth),
                          child: selectedStaffList.isEmpty
                              ? const SizedBox()
                              : Row(
                                  children: selectedStaffList.map((staffName) {
                                    final appts = staffAppts[staffName] ?? [];
                                    final staff = staffList.firstWhere(
                                      (s) => s['fullName'] == staffName,
                                      orElse: () => <String, String?>{
                                        'photo': null,
                                        'fullName': staffName,
                                        'id': '',
                                        'position': '',
                                        'status': ''
                                      },
                                    );
                                    return SizedBox(
                                      width: staffColumnWidth,
                                      height: 24 * slotHeight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                              left: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 1)),
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            const SizedBox.expand(),
                                            // Grid lines
                                            ...List.generate(97, (i) {
                                              return Positioned(
                                                top: i * quarterSlot,
                                                left: 0,
                                                right: 0,
                                                child: Divider(
                                                  thickness:
                                                      i % 4 == 0 ? 1.0 : 0.4,
                                                  color: i % 4 == 0
                                                      ? Colors.grey[400]
                                                      : Colors.grey[200],
                                                ),
                                              );
                                            }),
                                            // Appointments for this staff
                                            ...appts.map((appt) {
                                              final startMin =
                                                  appt.startTime.hour * 60 +
                                                      appt.startTime.minute;
                                              final top =
                                                  (startMin / 15) * quarterSlot;
                                              final height =
                                                  (appt.duration.inMinutes /
                                                          15) *
                                                      quarterSlot;

                                              return Positioned(
                                                  top: top,
                                                  left: 6.w,
                                                  right: 6.w,
                                                  height: height.clamp(
                                                      60.h,
                                                      slotHeight *
                                                          4), // Prevent overflow
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (appt.id.isNotEmpty) {
                                                        print(
                                                            '🔘 Tapped appointment: ${appt.clientName} (ID: ${appt.id})');
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AppointmentDetailDialog(
                                                            appointmentId:
                                                                appt.id,
                                                          ),
                                                        );
                                                      } else {
                                                        print(
                                                            '⚠️ Appointment has no ID: ${appt.clientName}');
                                                        // fallback message if somehow no id
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'No ID for this appointment')),
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey[200]!,
                                                            width: 1),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.04),
                                                            blurRadius: 4,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                        child: Stack(
                                                          children: [
                                                            // Left Indicator Bar
                                                            Positioned(
                                                              left: 0,
                                                              top: 0,
                                                              bottom: 0,
                                                              child: Container(
                                                                width: 4.w,
                                                                color: _getStatusColor(appt
                                                                        .status)
                                                                    .withOpacity(
                                                                        0.8),
                                                              ),
                                                            ),
                                                            // Main Content
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .fromLTRB(
                                                                          10.w,
                                                                          4.h,
                                                                          8.w,
                                                                          2.h),
                                                              child:
                                                                  ScrollConfiguration(
                                                                behavior: const ScrollBehavior()
                                                                    .copyWith(
                                                                        scrollbars:
                                                                            false),
                                                                child:
                                                                    SingleChildScrollView(
                                                                  physics:
                                                                      const NeverScrollableScrollPhysics(),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      // Client Name Row
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              appt.clientName,
                                                                              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.black),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ),
                                                                          // Status Chip
                                                                          Container(
                                                                            padding:
                                                                                EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: _getStatusColor(appt.status).withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(12.r),
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              appt.status,
                                                                              style: TextStyle(fontSize: 7.sp, fontWeight: FontWeight.bold, color: _getStatusColor(appt.status)),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              4.h),
                                                                      // Time Row
                                                                      Row(
                                                                        children: [
                                                                          Icon(
                                                                            Icons.access_time,
                                                                            size:
                                                                                10.sp,
                                                                            color:
                                                                                Colors.blueGrey[600],
                                                                          ),
                                                                          SizedBox(
                                                                              width: 4.w),
                                                                          Text(
                                                                            '${DateFormat('hh:mma').format(appt.startTime)} - ${DateFormat('hh:mma').format(appt.endTime)}',
                                                                            style: TextStyle(
                                                                                fontSize: 8.sp,
                                                                                fontWeight: FontWeight.w600,
                                                                                color: Colors.blueGrey[800]),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              4.h),
                                                                      // Booking Mode Chip
                                                                      Container(
                                                                        padding: EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                8.w,
                                                                            vertical: 3.h),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.blue[50],
                                                                          borderRadius:
                                                                              BorderRadius.circular(6.r),
                                                                          border:
                                                                              Border.all(color: Colors.blue[100]!),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            Icon(
                                                                              appt.mode.toLowerCase() == 'online' ? Icons.language : Icons.store,
                                                                              size: 9.sp,
                                                                              color: Colors.blue[800],
                                                                            ),
                                                                            SizedBox(width: 4.w),
                                                                            Text(
                                                                              appt.mode.toLowerCase() == 'online' ? 'Web Booking' : 'Offline Booking',
                                                                              style: TextStyle(fontSize: 7.sp, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ));
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
                            height: 3,
                            decoration: BoxDecoration(
                              color:
                                  isToday ? Colors.red : Colors.grey.shade400,
                              boxShadow: [
                                BoxShadow(
                                  color: (isToday ? Colors.red : Colors.grey)
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Empty state
                    if (totalApptsForDay == 0 && selectedStaffList.isNotEmpty)
                      Positioned(
                        top: 50.h,
                        left: 70.w,
                        right: 20.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 32.sp, color: Colors.grey[400]),
                              SizedBox(height: 8.h),
                              Text(
                                'No appointments',
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700]),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'for ${DateFormat('EEE, MMM d').format(_selectedDate)}',
                                style: TextStyle(
                                    fontSize: 12.sp, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
          FloatingActionButton.extended(
            backgroundColor: Colors.black,
            onPressed: _showCreateAppointmentForm,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('New Appointment',
                style: TextStyle(color: Colors.white, fontSize: 12.sp)),
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              FloatingActionButton(
                backgroundColor: Colors.blue,
                elevation: 6,
                heroTag: 'staff_select',
                onPressed: _showStaffSelection,
                tooltip: '${selectedStaffList.length} staff selected',
                child: Text(
                  '${selectedStaffList.length}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                right: 4.w,
                bottom: 4.h,
                child: Icon(Icons.group, color: Colors.white, size: 14.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
