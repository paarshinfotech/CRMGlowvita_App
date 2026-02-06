import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../add_customer.dart';
import '../customer_model.dart';
import '../calender.dart';
import '../services/api_service.dart';
import '../appointment_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show HttpClient, X509Certificate;
import 'package:http/io_client.dart' as http_io;

class Client {
  final String name;
  final String email;
  final String mobile;
  final Customer customer;

  const Client({
    required this.name,
    required this.email,
    required this.mobile,
    required this.customer,
  });

  @override
  String toString() => name;
}

class QueuedService {
  final Service service;
  final StaffMember staff;
  final DateTime startTime;
  final DateTime endTime;

  QueuedService({
    required this.service,
    required this.staff,
    required this.startTime,
    required this.endTime,
  });
}

class CreateAppointmentForm extends StatefulWidget {
  final Function(List<Appointments>)? onAppointmentCreated;
  final AppointmentModel? existingAppointment;

  const CreateAppointmentForm({
    super.key,
    this.onAppointmentCreated,
    this.existingAppointment,
  });

  @override
  State<CreateAppointmentForm> createState() => _CreateAppointmentFormState();
}

class _CreateAppointmentFormState extends State<CreateAppointmentForm> {
  final _formKey = GlobalKey<FormState>();

  // Client search (Autocomplete)
  final TextEditingController _clientSearchCtrl = TextEditingController();

  // Notes
  final TextEditingController _notesCtrl = TextEditingController();

  // Auto-calculated fields (kept as text for simple UI)
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _totalCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _endTimeCtrl = TextEditingController();

  Client? _selectedClient;
  StaffMember? _selectedStaff;
  List<StaffMember> _staff = [];
  bool _isLoadingStaff = true;

  Service? _selectedService;
  List<Service> _availableServices = [];
  bool _isLoadingServices = true;

  List<QueuedService> _queuedServices = [];
  bool _isSaving = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();

  // Initialize as empty lists
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Add listeners for real-time pricing updates
    _discountCtrl.addListener(_recalculatePricingAndTimes);
    _taxCtrl.addListener(_recalculatePricingAndTimes);
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadClients(),
      _loadStaff(),
      _loadServices(),
    ]);

    if (widget.existingAppointment != null) {
      _prefillForm();
    }
  }

  void _prefillForm() {
    final appt = widget.existingAppointment!;
    setState(() {
      _selectedDate = appt.date ?? DateTime.now();
      if (appt.startTime != null && appt.startTime!.contains(':')) {
        final parts = appt.startTime!.split(':');
        _startTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      _notesCtrl.text = appt.notes ?? '';
      _discountCtrl.text = appt.discount?.toString() ?? '0';
      // Internal logic for tax if needed
      _taxCtrl.text = '0';

      // Prefill Client
      if (appt.client != null) {
        _selectedClient = _clients.cast<Client?>().firstWhere(
            (c) => c?.customer.id == appt.client!.id,
            orElse: () => null);
      }
      _clientSearchCtrl.text = appt.clientName ?? '';

      // Prefill Queue
      _queuedServices = [];
      if (appt.serviceItems != null && appt.serviceItems!.isNotEmpty) {
        for (var item in appt.serviceItems!) {
          final service = _availableServices.firstWhere(
            (s) => s.name == item.serviceName,
            orElse: () => Service(
              id: item.serviceName, // Fallback ID if not found
              name: item.serviceName,
              price: item.amount?.toInt(),
              duration: item.duration,
            ),
          );
          final staff = _staff.firstWhere(
            (s) => s.fullName == item.staffName,
            orElse: () => StaffMember(
              id: '',
              fullName: item.staffName ?? 'Unknown',
            ),
          );

          DateTime sTime;
          if (item.startTime != null && item.startTime!.contains(':')) {
            final p = item.startTime!.split(':');
            sTime = DateTime(_selectedDate.year, _selectedDate.month,
                _selectedDate.day, int.parse(p[0]), int.parse(p[1]));
          } else {
            sTime = _combine(_selectedDate, _startTime);
          }

          _queuedServices.add(QueuedService(
            service: service,
            staff: staff,
            startTime: sTime,
            endTime: sTime.add(Duration(minutes: item.duration ?? 0)),
          ));
        }
      } else {
        // Single service fallback
        final service = _availableServices.firstWhere(
          (s) => s.name == appt.serviceName,
          orElse: () => Service(
            name: appt.serviceName,
            price: appt.amount?.toInt(),
            duration: appt.duration,
          ),
        );
        final staff = _staff.firstWhere(
          (s) => s.fullName == appt.staffName,
          orElse: () => StaffMember(
            id: '',
            fullName: appt.staffName ?? 'Unknown staff',
          ),
        );
        final sTime = _combine(_selectedDate, _startTime);

        _queuedServices.add(QueuedService(
          service: service,
          staff: staff,
          startTime: sTime,
          endTime: sTime.add(Duration(minutes: appt.duration ?? 0)),
        ));
      }
    });

    _recalculatePricingAndTimes();
  }

  // Add method to load clients from API
  Future<void> _loadClients() async {
    try {
      final apiCustomers = await ApiService.getClients();
      setState(() {
        _clients = apiCustomers
            .map((customer) => Client(
                  name: customer.fullName,
                  email: customer.email ?? '',
                  mobile: customer.mobile,
                  customer: customer,
                ))
            .toList();
      });
    } catch (e) {
      print('Error loading clients: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
  }

  http_io.IOClient _cookieClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return http_io.IOClient(ioClient);
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoadingStaff = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) throw Exception('No login token');

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

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _staff = data.map<StaffMember>((item) {
            final map = item as Map<String, dynamic>;
            return StaffMember(
              id: map['_id']?.toString() ?? 'unknown',
              fullName: (map['fullName'] ?? 'Unknown Staff').toString().trim(),
              email: map['emailAddress']?.toString(),
              mobile: map['mobileNo']?.toString(),
            );
          }).toList();
        });
      } else {
        throw Exception('Failed to load staff');
      }
    } catch (e) {
      debugPrint('Staff load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load staff'),
              backgroundColor: Colors.red),
        );
      }
      setState(() => _staff = []);
    } finally {
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final services = await ApiService.getServices();
      setState(() {
        _availableServices = services;
      });
    } catch (e) {
      debugPrint('Services load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load services'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _refreshStaff() async => await _loadStaff();
  Future<void> _refreshClients() async => await _loadClients();

  @override
  void dispose() {
    _clientSearchCtrl.dispose();
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    _totalCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  // -------- Helpers --------

  DateTime _combine(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  String _formatTime(TimeOfDay t) {
    final loc = MaterialLocalizations.of(context);
    return loc.formatTimeOfDay(t);
  }

  double _parseMoney(String s) {
    final cleaned = s.trim().replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _recalculatePricingAndTimes() {
    double totalAmount = 0;
    int totalDuration = 0;

    for (var qs in _queuedServices) {
      totalAmount += (qs.service.price ?? 0).toDouble();
      totalDuration += qs.service.duration ?? 0;
    }

    final discount = _parseMoney(_discountCtrl.text);
    final tax = _parseMoney(_taxCtrl.text);
    final total = (totalAmount - discount).clamp(0.0, double.infinity) + tax;

    _amountCtrl.text = totalAmount > 0 ? totalAmount.toStringAsFixed(2) : '';
    _totalCtrl.text = total > 0 ? total.toStringAsFixed(2) : '';
    _durationCtrl.text = totalDuration == 0 ? '' : '$totalDuration min';

    if (_queuedServices.isNotEmpty) {
      _endTimeCtrl.text =
          _formatTime(TimeOfDay.fromDateTime(_queuedServices.last.endTime));
    } else {
      _endTimeCtrl.text = '';
    }

    setState(() {});
  }

  void _recalculateQueue() {
    if (_queuedServices.isEmpty) return;

    List<QueuedService> updatedQueue = [];
    DateTime currentStartTime = _combine(_selectedDate, _startTime);

    for (var qs in _queuedServices) {
      final duration = qs.service.duration ?? 0;
      final endTime = currentStartTime.add(Duration(minutes: duration));

      updatedQueue.add(QueuedService(
        service: qs.service,
        staff: qs.staff,
        startTime: currentStartTime,
        endTime: endTime,
      ));

      currentStartTime = endTime;
    }

    setState(() {
      _queuedServices = updatedQueue;
    });
    _recalculatePricingAndTimes();
  }

  void _addToQueue() {
    if (_selectedService == null || _selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both service and staff')),
      );
      return;
    }

    DateTime currentStartTime;
    if (_queuedServices.isEmpty) {
      currentStartTime = _combine(_selectedDate, _startTime);
    } else {
      currentStartTime = _queuedServices.last.endTime;
    }

    final duration = _selectedService!.duration ?? 0;
    final endTime = currentStartTime.add(Duration(minutes: duration));

    setState(() {
      _queuedServices.add(QueuedService(
        service: _selectedService!,
        staff: _selectedStaff!,
        startTime: currentStartTime,
        endTime: endTime,
      ));
      // Clear selection buffers
      _selectedService = null;
      // Note: We keep _selectedStaff for easier multiple additions
    });

    _recalculatePricingAndTimes();
  }

  void _removeFromQueue(int index) {
    setState(() {
      _queuedServices.removeAt(index);
    });
    _recalculateQueue();
  }

  double _calculateTotalAmount() {
    return _queuedServices.fold(
        0.0, (sum, item) => sum + (item.service.price ?? 0).toDouble());
  }

  int _calculateTotalDuration() {
    return _queuedServices.fold<int>(
        0, (sum, item) => sum + (item.service.duration ?? 0));
  }

  // -------- Pickers --------

  Future<void> _pickDate() async {
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
                'Select Date',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                    _recalculateQueue();
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
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: Size(double.infinity, 30.h),
                  ),
                  child: Text('Done',
                      style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickStartTime() async {
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
                'Select Start Time',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _combine(_selectedDate, _startTime),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      _startTime = TimeOfDay(
                          hour: newDateTime.hour, minute: newDateTime.minute);
                    });
                    _recalculateQueue();
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: Size(double.infinity, 30.h),
                  ),
                  child: Text('Done',
                      style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------- Staff Add Dialog --------
  Future<void> _openAddStaffDialog() async {
    // Since we don't have an AddStaffPage, we'll just show a snackbar for now
    // In a real implementation, you would navigate to the AddStaffPage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Add Staff functionality not implemented yet')),
    );

    // Refresh the staff list after adding a new staff member
    await _refreshStaff();
  }

  // -------- Client Add Dialog --------

  Future<void> _openAddClientDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomer(),
      ),
    );

    if (result == null) return;

    // Refresh the client list after adding a new client
    await _refreshClients();

    // Find the newly added client and select it
    final newClient = _clients.firstWhere(
      (client) => client.customer.id == result.id,
      orElse: () => Client(
        name: result.fullName ?? 'Unknown',
        email: result.email ?? '',
        mobile: result.mobile,
        customer: result,
      ),
    );

    setState(() {
      _selectedClient = newClient;
      _clientSearchCtrl.text = newClient.name;
    });
  }

  // -------- Submit --------

  Future<void> _saveAppointment() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    if (_queuedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one service to the queue')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Use the first service from the queue for the primary fields
      final qs = _queuedServices.first;

      final appointmentData = {
        "client": _selectedClient?.customer.id ??
            widget.existingAppointment?.client?.id,
        "clientName": _selectedClient?.name ??
            widget.existingAppointment?.clientName ??
            '',
        "service": qs.service.id,
        "serviceName": qs.service.name,
        "staff": qs.staff.id,
        "staffName": qs.staff.fullName,
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "startTime": DateFormat('HH:mm').format(qs.startTime),
        "endTime": DateFormat('HH:mm').format(qs.endTime),
        "duration": qs.service.duration,
        "amount": _calculateTotalAmount(),
        "discount": _parseMoney(_discountCtrl.text),
        "tax": _parseMoney(_taxCtrl.text),
        "totalAmount": _calculateTotalAmount(),
        "finalAmount": _parseMoney(_totalCtrl.text),
        "paymentStatus":
            widget.existingAppointment?.status == 'paid' ? 'paid' : 'pending',
        "status": "scheduled",
        "mode": "offline",
        "isMultiService": _queuedServices.length > 1,
        "notes": _notesCtrl.text,
        "internalNotes": "",
        "rescheduleReason": "",
        "cancelReason": "",
        "serviceItems": _queuedServices.map((item) {
          return {
            "service": item.service.id,
            "serviceName": item.service.name,
            "staff": item.staff.id,
            "staffName": item.staff.fullName,
            "startTime": DateFormat('HH:mm').format(item.startTime),
            "endTime": DateFormat('HH:mm').format(item.endTime),
            "duration": item.service.duration,
            "amount": item.service.price,
            "addOns": [],
          };
        }).toList(),
      };

      if (widget.existingAppointment != null) {
        await ApiService.updateAppointment(
            widget.existingAppointment!.id!, appointmentData);
      } else {
        await ApiService.createAppointment(appointmentData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingAppointment != null
                ? 'Appointment updated successfully'
                : 'Appointment created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        final List<Appointments> createdAppointments =
            _queuedServices.map((qs) {
          return Appointments(
            startTime: qs.startTime,
            duration: Duration(minutes: qs.service.duration ?? 0),
            clientName: _selectedClient?.name ??
                widget.existingAppointment?.clientName ??
                'Unknown',
            serviceName: qs.service.name ?? 'Unknown',
            staffName: (qs.staff.fullName ?? qs.staff.id) ?? 'Unknown',
            status: 'scheduled',
            isWebBooking: _queuedServices.length > 1,
            mode: 'offline',
          );
        }).toList();

        if (widget.onAppointmentCreated != null) {
          widget.onAppointmentCreated!(createdAppointments);
        }

        Navigator.of(context).pop(createdAppointments);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${widget.existingAppointment != null ? 'updating' : 'creating'} appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // -------- UI --------

  InputDecoration _inputDecoration({
    required String label,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 10.sp), // Reduced font size
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r)), // Reduced radius
      contentPadding: EdgeInsets.symmetric(
          horizontal: 10.w, vertical: 10.h), // Reduced padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy')
        .format(_selectedDate); // Changed format to match calendar
    final startText = _formatTime(_startTime);

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New Appointment',
                        style: GoogleFonts.poppins(
                            fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  'Create a new appointment',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 16.h),

                // Client (search + add)
                Text('Client *',
                    style: TextStyle(
                        fontSize: 10.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<Client>(
                        optionsBuilder: (value) {
                          final q = value.text.trim().toLowerCase();
                          if (q.isEmpty) return _clients;
                          return _clients.where((c) =>
                              c.name.toLowerCase().contains(q) ||
                              c.email.toLowerCase().contains(q) ||
                              c.mobile.toLowerCase().contains(q));
                        },
                        displayStringForOption: (c) => c.name,
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color:
                                  Colors.white, // White background for dropdown
                              child: Container(
                                width: 300.w,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white, // Ensure white background
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final client = options.elementAt(index);
                                    return ListTile(
                                      title: Text(client.name,
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(client.email,
                                              style: TextStyle(
                                                  fontSize: 8.sp,
                                                  color: Colors.grey[600])),
                                          Text(client.mobile,
                                              style: TextStyle(
                                                  fontSize: 8.sp,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                      onTap: () => onSelected(client),
                                      tileColor: Colors
                                          .white, // White background for each tile
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder:
                            (context, textCtrl, focusNode, onSubmit) {
                          // Sync initial text if needed
                          if (_clientSearchCtrl.text != textCtrl.text &&
                              textCtrl.text.isEmpty) {
                            textCtrl.text = _clientSearchCtrl.text;
                          }

                          return TextFormField(
                            controller: textCtrl,
                            focusNode: focusNode,
                            readOnly: widget.existingAppointment != null,
                            decoration: _inputDecoration(
                              label: 'Search for a client...',
                              prefix: const Icon(Icons.search, size: 18),
                            ),
                            style: TextStyle(fontSize: 10.sp),
                            validator: (_) => (_selectedClient == null &&
                                    widget.existingAppointment == null)
                                ? 'Select a client'
                                : null,
                          );
                        },
                        onSelected: (c) => setState(() => _selectedClient = c),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      height: 40.h,
                      width: 40.h,
                      child: OutlinedButton(
                        onPressed: widget.existingAppointment == null
                            ? _openAddClientDialog
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Date / Start / End / Duration Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Date *',
                            prefix: const Icon(Icons.calendar_month_outlined,
                                size: 14),
                          ),
                          child:
                              Text(dateText, style: TextStyle(fontSize: 9.sp)),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickStartTime,
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Start *',
                            prefix: const Icon(Icons.access_time, size: 14),
                          ),
                          child:
                              Text(startText, style: TextStyle(fontSize: 9.sp)),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          label: 'End',
                          prefix:
                              const Icon(Icons.timer_off_outlined, size: 14),
                        ),
                        child: Text(
                            _endTimeCtrl.text.isEmpty
                                ? '--:--'
                                : _endTimeCtrl.text,
                            style: TextStyle(fontSize: 9.sp)),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          label: 'Min',
                          prefix: const Icon(Icons.timer_outlined, size: 14),
                        ),
                        child: Text(_durationCtrl.text.replaceAll(' min', ''),
                            style: TextStyle(fontSize: 9.sp)),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Staff Selection FIRST
                Text('Select Staff *',
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
                SizedBox(height: 6.h),
                DropdownButtonFormField<StaffMember>(
                  value: _selectedStaff,
                  isExpanded: true,
                  decoration: _inputDecoration(label: '').copyWith(
                    hintText: _isLoadingStaff
                        ? 'Loading staff...'
                        : 'Select staff member',
                  ),
                  items: _staff
                      .map((staff) => DropdownMenuItem(
                            value: staff,
                            child: Text(
                              staff.fullName ?? 'Unknown',
                              style: TextStyle(fontSize: 11.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (staff) {
                    setState(() {
                      _selectedStaff = staff;
                      // Staff Update Fix: If this is a single-service appointment,
                      // update the staff for the item in the queue immediately.
                      if (_queuedServices.length == 1 && staff != null) {
                        _queuedServices[0] = QueuedService(
                          service: _queuedServices[0].service,
                          staff: staff,
                          startTime: _queuedServices[0].startTime,
                          endTime: _queuedServices[0].endTime,
                        );
                      }
                    });
                  },
                ),

                SizedBox(height: 12.h),

                // Service Selection SECOND
                Text('Select Service *',
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Service>(
                        value: _selectedService,
                        isExpanded: true,
                        decoration: _inputDecoration(label: '').copyWith(
                          hintText: _isLoadingServices
                              ? 'Loading services...'
                              : 'Pick a service',
                        ),
                        items: _availableServices
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.name ?? 'Unknown',
                                          style: TextStyle(fontSize: 11.sp),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '₹${s.price} · ${s.duration}m',
                                        style: TextStyle(
                                            fontSize: 9.sp,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (s) => setState(() => _selectedService = s),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      height: 42.h,
                      width: 42.h,
                      child: ElevatedButton(
                        onPressed: _addToQueue,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Helper Steps and Selected Info
                Text(
                  'Step 1: Select staff · Step 2: Select service · Step 3: Click + to add',
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey[500]),
                ),
                if (_selectedService != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Selected: ${_selectedService!.name} · ${_selectedService!.duration ?? 0} min · ₹${_selectedService!.price ?? 0}',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                  ),
                ],

                SizedBox(height: 16.h),

                // Service Sequence Section
                if (_queuedServices.isNotEmpty) ...[
                  Text(
                    'Service sequence (queued back-to-back):',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12.h),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _queuedServices.length,
                    itemBuilder: (context, index) {
                      final qs = _queuedServices[index];
                      final start = DateFormat('HH:mm').format(qs.startTime);
                      final end = DateFormat('HH:mm').format(qs.endTime);

                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F0F2), // Light brand maroon
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20.h,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        qs.service.name ?? 'Unknown',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '₹${qs.service.price}',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    '${qs.staff.fullName} · $start - $end (${qs.service.duration} min)',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 9.sp),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            IconButton(
                              onPressed: () => _removeFromQueue(index),
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.grey, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Time Bar Reconstruction (AFTER the cards)
                  SizedBox(height: 8.h),
                  Container(
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      children: _queuedServices.map((qs) {
                        final totalWidth = _calculateTotalDuration();
                        final serviceDuration = qs.service.duration ?? 0;
                        final flexValue = totalWidth > 0
                            ? (serviceDuration / totalWidth * 100).toInt()
                            : 1;
                        return Expanded(
                          flex: flexValue,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Total Summary Card (Minimalist Light Theme)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Services (${_queuedServices.length})',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹${_calculateTotalAmount().toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        const Divider(color: Color(0xFFEEEEEE), height: 1),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Duration',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${_calculateTotalDuration()} min',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Time Slot',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${DateFormat('HH:mm').format(_queuedServices.first.startTime)} - ${DateFormat('HH:mm').format(_queuedServices.last.endTime)}',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                SizedBox(height: 12.h),

                SizedBox(height: 12.h),

                // Amount / Discount / Tax / Total
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountCtrl,
                        readOnly: true,
                        decoration: _inputDecoration(label: 'Amount'),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(label: 'Discount'),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(label: 'Tax'),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _totalCtrl,
                        readOnly: true,
                        decoration: _inputDecoration(label: 'Total Amount'),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Duration + Notes
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationCtrl,
                        readOnly: true,
                        decoration: _inputDecoration(label: 'Duration'),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _notesCtrl,
                        minLines: 1,
                        maxLines: 2,
                        decoration: _inputDecoration(label: 'Notes'),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child:
                            Text('Cancel', style: TextStyle(fontSize: 12.sp)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: _isSaving ? null : _saveAppointment,
                        child: _isSaving
                            ? SizedBox(
                                height: 16.h,
                                width: 16.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Create',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12.sp)),
                      ),
                    ),
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
