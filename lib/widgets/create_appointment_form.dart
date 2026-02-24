import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glowvita/addon_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../add_customer.dart';
import '../customer_model.dart';
import '../calender.dart';
import '../services/api_service.dart';
import '../appointment_model.dart';

class FormClient {
  final String name;
  final String email;
  final String mobile;
  final Customer customer;

  const FormClient({
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
  final List<AddOn> selectedAddOns;
  final bool isFromPackage; // New field

  QueuedService({
    required this.service,
    required this.staff,
    required this.startTime,
    required this.endTime,
    this.selectedAddOns = const [],
    this.isFromPackage = false, // Default to false
  });
}

class CreateAppointmentForm extends StatefulWidget {
  final List<Appointments>
      dailyAppointments; // New field for conflict detection
  final Function(List<Appointments>)? onAppointmentCreated;
  final AppointmentModel? existingAppointment;

  const CreateAppointmentForm({
    super.key,
    this.onAppointmentCreated,
    this.existingAppointment,
    this.dailyAppointments = const [],
  });

  @override
  State<CreateAppointmentForm> createState() => _CreateAppointmentFormState();
}

class _CreateAppointmentFormState extends State<CreateAppointmentForm> {
  final _formKey = GlobalKey<FormState>();

  // Client search (Autocomplete)
  final TextEditingController _clientSearchCtrl = TextEditingController();

  // No longer needed: Home Service fields
  // No longer needed: Wedding Service fields

  // Auto-calculated fields (kept as text for simple UI)
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _totalCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _endTimeCtrl = TextEditingController();
  // Notes
  final TextEditingController _notesCtrl = TextEditingController();

  FormClient? _selectedClient;
  StaffMember? _selectedStaff;
  List<StaffMember> _staff = [];
  bool _isLoadingStaff = true;

  // No longer needed: WeddingPackage state

  List<QueuedService> _queuedServices = [];
  bool _isSaving = false;

  List<AddOn> _allAddOns = [];
  List<AddOn> _availableAddOns = [];
  List<AddOn> _selectedAddOns = [];

  List<Service> _availableServices = [];
  bool _isLoadingServices = true;
  Service? _selectedService;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();

  // Initialize as empty lists
  List<FormClient> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    // Add listeners for real-time pricing updates
    _discountCtrl.addListener(_recalculatePricingAndTimes);
    _taxCtrl.addListener(_recalculatePricingAndTimes);
  }

  Future<void> _loadData() async {
    // Basic shared data
    await Future.wait([
      _loadClients(),
      _loadStaff(),
      _loadServices(),
      _loadAddOns(),
    ]);

    if (widget.existingAppointment != null && _queuedServices.isEmpty) {
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
      _taxCtrl.text = (appt.serviceTax ?? 0).toString();

      // Type is now always regular for new appointments

      // Prefill Client
      if (appt.client != null) {
        _selectedClient = _clients.cast<FormClient?>().firstWhere(
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
            .map((customer) => FormClient(
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

  Future<void> _loadStaff() async {
    setState(() => _isLoadingStaff = true);

    try {
      final fetchedStaff = await ApiService.getStaff();
      if (mounted) {
        setState(() {
          _staff = fetchedStaff;
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      debugPrint('Staff load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load staff'),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoadingStaff = false);
      }
    }
  }

  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    try {
      List<Service> fetchedServices = await ApiService.getServices();
      if (mounted) {
        setState(() {
          _availableServices = fetchedServices;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      print('Error loading services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load services'),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoadingServices = false);
      }
    }
  }

  Future<void> _loadAddOns() async {
    try {
      List<AddOn> fetchedAddOns = await ApiService.getAddOns();
      if (mounted) {
        setState(() {
          _allAddOns = fetchedAddOns;
        });
      }
    } catch (e) {
      print('Error loading add-ons: $e');
    }
  }

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

    if (_queuedServices.isEmpty) return;

    for (var qs in _queuedServices) {
      // Only add price/duration if NOT part of the package (custom/extra services)
      if (!qs.isFromPackage) {
        totalAmount += (qs.service.price ?? 0).toDouble();
        totalDuration += qs.service.duration ?? 0;
      }

      // Add add-ons price and duration (Add-ons are always extra)
      for (var addon in qs.selectedAddOns) {
        totalAmount += (addon.price ?? 0).toDouble();
        totalDuration += addon.duration ?? 0;
      }
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
      // Calculate total duration including add-ons
      final serviceDuration = qs.service.duration ?? 0;
      final addOnsDuration = qs.selectedAddOns
          .fold<int>(0, (sum, addon) => sum + (addon.duration ?? 0));
      final totalDuration = serviceDuration + addOnsDuration;

      final endTime = currentStartTime.add(Duration(minutes: totalDuration));

      // Check conflict for this item in the queue
      final conflict = _hasConflict(currentStartTime, endTime, qs.staff);
      if (conflict) {
        _showConflictDialog(qs.staff, qs.service, currentStartTime, endTime);
        // We still add it to the queue visually but the user has been warned
        // Or we could stop here.
      }

      updatedQueue.add(QueuedService(
        service: qs.service,
        staff: qs.staff,
        startTime: currentStartTime,
        endTime: endTime,
        selectedAddOns: qs.selectedAddOns, // Preserve add-ons
      ));

      currentStartTime = endTime;
    }

    setState(() {
      _queuedServices = updatedQueue;
    });
    _recalculatePricingAndTimes();
  }

  bool _hasConflict(DateTime start, DateTime end, StaffMember staff) {
    for (var appt in widget.dailyAppointments) {
      // Exclude current appointment if editing
      if (widget.existingAppointment != null &&
          appt.id == widget.existingAppointment!.id) {
        continue;
      }

      // Check staff match
      // Assuming staffNames are consistent.
      // Ideally should match IDs if possible, but existing 'Appointments' model might not have IDs populated from calendar yet.
      // let's try to match name.
      if (appt.staffName != staff.fullName) continue;

      // Check overlap
      // Overlap if (StartA < EndB) and (EndA > StartB)
      if (appt.startTime.isBefore(end) && appt.endTime.isAfter(start)) {
        return true;
      }
    }
    return false;
  }

  void _showConflictDialog(
      StaffMember staff, Service service, DateTime start, DateTime end) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slot Unavailable'),
        content: Text(
            '${staff.fullName} is already booked between ${DateFormat('HH:mm').format(start)} and ${DateFormat('HH:mm').format(end)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

    // Calculate total duration including add-ons
    final serviceDuration = _selectedService!.duration ?? 0;
    final addOnsDuration = _selectedAddOns.fold<int>(
        0, (sum, addon) => sum + (addon.duration ?? 0));
    final totalDuration = serviceDuration + addOnsDuration;
    final endTime = currentStartTime.add(Duration(minutes: totalDuration));

    // Check conflict BEFORE adding (now with correct end time including add-ons)
    if (_hasConflict(currentStartTime, endTime, _selectedStaff!)) {
      _showConflictDialog(
          _selectedStaff!, _selectedService!, currentStartTime, endTime);
      return; // Do not add to queue
    }

    setState(() {
      _queuedServices.add(QueuedService(
        service: _selectedService!,
        staff: _selectedStaff!,
        startTime: currentStartTime,
        endTime: endTime,
        selectedAddOns: List.from(_selectedAddOns),
      ));
      // Clear selection buffers
      _selectedService = null;
      _selectedAddOns = [];
      _availableAddOns = [];
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
    double total = _queuedServices.fold(0.0, (sum, item) {
      // Add service price
      double sTotal = sum + (item.service.price ?? 0).toDouble();
      // Add add-on prices
      for (var addon in item.selectedAddOns) {
        sTotal += (addon.price ?? 0).toDouble();
      }
      return sTotal;
    });

    return total;
  }

  int _calculateTotalDuration() {
    int duration = _queuedServices.fold<int>(
        0,
        (sum, item) =>
            sum +
            (item.service.duration ?? 0) +
            item.selectedAddOns.fold<int>(0, (s, a) => s + (a.duration ?? 0)));

    return duration;
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
      orElse: () => FormClient(
        name: result.fullName,
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
        "mode": 'offline',
        "appointmentType": 'regular',
        "homeAddress": "",
        "city": "",
        "pincode": "",
        "weddingPackage": null,
        "venueAddress": "",
        "isMultiService": _queuedServices.length > 1,
        "clientPhone": _selectedClient?.mobile ?? '',
        "clientEmail": _selectedClient?.email ?? '',
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
            "addOns": item.selectedAddOns
                .map((a) => {
                      "id": a.id ?? '',
                      "name": a.name ?? '',
                      "price": a.price ?? 0.0,
                      "duration": a.duration ?? 0,
                    })
                .toList(),
          };
        }).toList(),
      };

      Map<String, dynamic> result;
      if (widget.existingAppointment != null) {
        result = await ApiService.updateAppointment(
            widget.existingAppointment!.id!, appointmentData);
      } else {
        result = await ApiService.createAppointment(appointmentData);
      }

      // Extract details from response
      // The API might return the object directly or wrapped in 'data'
      Map<String, dynamic> appointmentDetails = result;
      if (result.containsKey('data') && result['data'] is Map) {
        appointmentDetails = result['data'];
      } else if (result.containsKey('appointment') &&
          result['appointment'] is Map) {
        appointmentDetails = result['appointment'];
      }

      final String newId = appointmentDetails['_id'] ??
          appointmentDetails['id'] ??
          widget.existingAppointment?.id ??
          '';

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
            id: newId, // Pass the ID from API
            hasAddOns: qs.selectedAddOns.isNotEmpty,
            addOnCount: qs.selectedAddOns.length,
          );
        }).toList();

        if (widget.onAppointmentCreated != null) {
          widget.onAppointmentCreated!(createdAppointments);
        }

        Navigator.of(context).pop(createdAppointments);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(
                'Error ${widget.existingAppointment != null ? 'updating' : 'creating'} appointment: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
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
      labelStyle: GoogleFonts.poppins(fontSize: 8.sp), // Reduced font size
      prefixIcon:
          prefix != null ? Transform.scale(scale: 0.7, child: prefix) : null,
      suffixIcon:
          suffix != null ? Transform.scale(scale: 0.7, child: suffix) : null,
      isDense: true,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r)), // Reduced radius
      contentPadding: EdgeInsets.symmetric(
          horizontal: 8.w, vertical: 4.h), // Further reduced padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy')
        .format(_selectedDate); // Changed format to match calendar
    final startText = _formatTime(_startTime);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 400.w),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New Appointment',
                        style: GoogleFonts.poppins(
                            fontSize: 12.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  'Create a new appointment',
                  style: GoogleFonts.poppins(
                      fontSize: 8.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 12.h),

                // Client (search + add)
                Text('Client *',
                    style: GoogleFonts.poppins(
                        fontSize: 8.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<FormClient>(
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
                                          style: GoogleFonts.poppins(
                                              fontSize: 9.sp,
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
                            style: GoogleFonts.poppins(fontSize: 9.sp),
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

                // Date / Start / End Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date *',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: _inputDecoration(
                                label: '',
                                suffix: const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 14),
                              ),
                              child: Text(dateText,
                                  style: GoogleFonts.poppins(fontSize: 8.sp)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Time *',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          InkWell(
                            onTap: _pickStartTime,
                            child: InputDecorator(
                              decoration: _inputDecoration(
                                label: '',
                                suffix: const Icon(Icons.access_time, size: 14),
                              ),
                              child: Text(startText,
                                  style: TextStyle(fontSize: 9.sp)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Time *',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          InputDecorator(
                            decoration: _inputDecoration(
                              label: '',
                              suffix: const Icon(Icons.timer_off_outlined,
                                  size: 14),
                            ),
                            child: Text(
                                _endTimeCtrl.text.isEmpty
                                    ? '--:--'
                                    : _endTimeCtrl.text,
                                style: TextStyle(fontSize: 9.sp)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Service and Staff Selection Row (Now Column for responsiveness)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Staff Selection
                    Text('Staff *',
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
                            : 'Select staff',
                      ),
                      items: _staff
                          .map((staff) => DropdownMenuItem(
                                value: staff,
                                child: Text(
                                  staff.fullName ?? 'Unknown',
                                  style: TextStyle(fontSize: 10.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (staff) {
                        setState(() {
                          _selectedStaff = staff;
                          if (_queuedServices.length == 1 && staff != null) {
                            _queuedServices[0] = QueuedService(
                              service: _queuedServices[0].service,
                              staff: staff,
                              startTime: _queuedServices[0].startTime,
                              endTime: _queuedServices[0].endTime,
                              selectedAddOns: _queuedServices[0].selectedAddOns,
                            );
                          }
                        });
                      },
                    ),
                    SizedBox(height: 12.h),

                    // Service Selection
                    Text('Service *',
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600])),
                    SizedBox(height: 6.h),
                    Row(
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
                                              style: TextStyle(fontSize: 10.sp),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${s.price}',
                                            style: TextStyle(
                                                fontSize: 9.sp,
                                                color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (s) {
                              setState(() {
                                _selectedService = s;
                                _selectedAddOns = [];
                                if (s != null) {
                                  _availableAddOns = _allAddOns.where((addon) {
                                    return addon.mappedServices
                                            ?.contains(s.id ?? '') ??
                                        false;
                                  }).toList();
                                } else {
                                  _availableAddOns = [];
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Circular Add Button
                        SizedBox(
                          height: 42.h,
                          width: 42.h,
                          child: ElevatedButton(
                            onPressed: _addToQueue,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).primaryColor,
                              shape: const CircleBorder(),
                              side: BorderSide(color: Colors.grey[300]!),
                              elevation: 0,
                            ),
                            child: const Icon(
                                Icons.center_focus_strong_outlined,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Helper Steps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 1: Select staff ·\n Step 2: Select service ·\n Step 3: Click + to add',
                      style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
                    ),
                    Text(
                      'Select staff member for each\n service when adding',
                      style: TextStyle(fontSize: 8.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
                if (_selectedService != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Selected: ${_selectedService?.name ?? ''} · ${_selectedService?.duration ?? 0} min · ₹${_selectedService?.price ?? 0}',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                  ),
                  if (_availableAddOns.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF4FF), // Very light purple
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFE8D5FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: const Color(0xFF9145EE), size: 16.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Available Add-ons (Optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9145EE),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: _availableAddOns.map((addon) {
                              final isSelected =
                                  _selectedAddOns.contains(addon);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedAddOns.remove(addon);
                                    } else {
                                      _selectedAddOns.add(addon);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF9145EE)
                                          : Colors.grey[300]!,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Text(
                                    '${addon.name} (+₹${addon.price})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      color: isSelected
                                          ? const Color(0xFF9145EE)
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                SizedBox(height: 16.h),

                // Service Sequence Section
                if (_queuedServices.isNotEmpty) ...[
                  Text(
                    'Service sequence (queued back-to-back):',
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
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
                                  // Display add-ons if any
                                  if (qs.selectedAddOns.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    ...qs.selectedAddOns.map((addon) => Padding(
                                          padding: EdgeInsets.only(top: 2.h),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '  + ${addon.name}',
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 9.sp,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                              Text(
                                                '+₹${addon.price} · ${addon.duration}m',
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 9.sp,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
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
                                      .withValues(alpha: 0.5)
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
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹${_calculateTotalAmount().toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 9.sp,
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
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${_calculateTotalDuration()} min',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 8.sp,
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
                              style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${DateFormat('HH:mm').format(_queuedServices.first.startTime)} - ${DateFormat('HH:mm').format(_queuedServices.last.endTime)}',
                              style: GoogleFonts.poppins(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 9.sp,
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

                // Pricing Row (Compact)
                // Pricing Row 1: Amount & Discount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount (₹)',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          TextFormField(
                            controller: _amountCtrl,
                            readOnly: true,
                            decoration: _inputDecoration(label: ''),
                            style: GoogleFonts.poppins(fontSize: 9.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Discount (₹)',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          TextFormField(
                            controller: _discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(label: ''),
                            style: GoogleFonts.poppins(fontSize: 9.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Pricing Row 2: Tax & Total Amount
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tax (₹)',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          TextFormField(
                            controller: _taxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(label: ''),
                            style: GoogleFonts.poppins(fontSize: 9.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount (₹)',
                              style: GoogleFonts.poppins(
                                  fontSize: 8.sp, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          TextFormField(
                            controller: _totalCtrl,
                            readOnly: true,
                            decoration: _inputDecoration(label: '').copyWith(
                              fillColor: Colors.grey[100],
                              filled: true,
                            ),
                            style: GoogleFonts.poppins(
                                fontSize: 9.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
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
                        style: GoogleFonts.poppins(fontSize: 9.sp),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _notesCtrl,
                        minLines: 1,
                        maxLines: 2,
                        decoration: _inputDecoration(label: 'Notes'),
                        style: GoogleFonts.poppins(fontSize: 9.sp),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700])),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E66E7),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                          elevation: 0,
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
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600)),
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
