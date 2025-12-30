import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../add_customer.dart';
import '../add_services.dart';
import '../customer_model.dart';
import '../calender.dart';
import '../services/api_service.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
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

class ServiceItem {
  final String name;
  final double price;
  final int durationMinutes;
  final double taxPercent;

  const ServiceItem({
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.taxPercent = 18, // default GST
  });

  @override
  String toString() => '$name  ₹${price.toStringAsFixed(2)}';
}

 class StaffMember {
  final String id;
  final String? fullName;
  final String? email;
  final String? mobile;

  StaffMember({
    required this.id,
    this.fullName,
    this.email,
    this.mobile,
  });
}

class CreateAppointmentForm extends StatefulWidget {
  final Function(Appointments)? onAppointmentCreated;
  
  const CreateAppointmentForm({super.key, this.onAppointmentCreated});

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
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _totalCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();

  Client? _selectedClient;
  StaffMember? _selectedStaff;
  List<StaffMember> _staff = [];
  bool _isLoadingStaff = true;
  ServiceItem? _selectedService;
 
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;

  // Initialize as empty lists
  List<Client> _clients = [];
 
  final List<ServiceItem> _services = const [
    ServiceItem(name: 'Soldier Cut', price: 150, durationMinutes: 25, taxPercent: 18),
    ServiceItem(name: 'Haircut', price: 250, durationMinutes: 30, taxPercent: 18),
    ServiceItem(name: 'Facial', price: 600, durationMinutes: 45, taxPercent: 18),
    ServiceItem(name: 'Keratin Treatment', price: 2500, durationMinutes: 90, taxPercent: 18),
  ];

  @override
  void initState() {
    super.initState();
    _recalculatePricingAndTimes();
    _discountCtrl.addListener(_recalculatePricingAndTimes);
    _loadClients();  
    _loadStaff();
  }

  // Add method to load clients from API
  Future<void> _loadClients() async {
    try {
      final apiCustomers = await ApiService.getClients();
      setState(() {
        _clients = apiCustomers.map((customer) => Client(
          name: customer.fullName,
          email: customer.email ?? '',
          mobile: customer.mobile,
          customer: customer,
        )).toList();
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
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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
          SnackBar(content: Text('Failed to load staff'), backgroundColor: Colors.red),
        );
      }
      setState(() => _staff = []);
    } finally {
      setState(() => _isLoadingStaff = false);
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

  TimeOfDay _addMinutes(TimeOfDay start, int minutes) {
    final dt = DateTime(2000, 1, 1, start.hour, start.minute).add(Duration(minutes: minutes));
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
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
    final service = _selectedService;

    // Pricing
    final amount = service?.price ?? 0.0;
    final discount = _parseMoney(_discountCtrl.text);
    final taxableBase = (amount - discount).clamp(0.0, double.infinity);
    final taxPercent = service?.taxPercent ?? 0.0;
    final tax = taxableBase * (taxPercent / 100.0);
    final total = taxableBase + tax;

    _amountCtrl.text = amount.toStringAsFixed(2);
    _taxCtrl.text = tax.toStringAsFixed(2);
    _totalCtrl.text = total.toStringAsFixed(2);

    // Duration + End time
    final durationMinutes = service?.durationMinutes ?? 0;
    _durationCtrl.text = durationMinutes == 0 ? '' : '$durationMinutes min';
    _endTime = durationMinutes == 0 ? null : _addMinutes(_startTime, durationMinutes);

    setState(() {});
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
                      _startTime = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                    });
                    _recalculatePricingAndTimes();
                  },
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

  // -------- Staff Add Dialog --------
  Future<void> _openAddStaffDialog() async {
    // Since we don't have an AddStaffPage, we'll just show a snackbar for now
    // In a real implementation, you would navigate to the AddStaffPage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Staff functionality not implemented yet')),
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

  // -------- Service Add Dialog --------

  Future<void> _openAddServiceDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddServicePage(),
      ),
    );

    // Note: In a real implementation, you would handle the result here
    // For now, we'll just refresh the service list or handle the new service
    // This would require updating the _services list with the new service
    // For demonstration purposes, we'll just show a snackbar
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added successfully! Please refresh the list.')),
      );
    }
  }

  // -------- Submit --------

  void _saveAppointment() {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }
    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a staff member')));
      return;
    }
     
    final start = _combine(_selectedDate, _startTime);
    final end = _endTime == null ? null : _combine(_selectedDate, _endTime!);
    
    // Create the appointment object 
    final appointment = Appointments(
      startTime: start,
      duration: Duration(minutes: _selectedService!.durationMinutes),
      clientName: _selectedClient!.name,
      serviceName: _selectedService!.name,
      staffName: _selectedStaff!.fullName ?? _selectedStaff!.id ?? 'Unknown Staff',
      status: 'New', // Default status
      isWebBooking: false, // Default to in-person booking
    );

    // Call the callback if provided
    if (widget.onAppointmentCreated != null) {
      widget.onAppointmentCreated!(appointment);
    }

    // Close the form
    Navigator.of(context).pop(appointment);
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)), // Reduced radius
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h), // Reduced padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy').format(_selectedDate); // Changed format to match calendar
    final startText = _formatTime(_startTime);
    final endText = _endTime == null ? '--:--' : _formatTime(_endTime!);

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
                        style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
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
                Text('Client *', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600)),
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
                            c.mobile.toLowerCase().contains(q)
                          );
                        },
                        displayStringForOption: (c) => c.name,
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: Colors.white, // White background for dropdown
                              child: Container(
                                width: 300.w,
                                decoration: BoxDecoration(
                                  color: Colors.white, // Ensure white background
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
                                      title: Text(client.name, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(client.email, style: TextStyle(fontSize: 8.sp, color: Colors.grey[600])),
                                          Text(client.mobile, style: TextStyle(fontSize: 8.sp, color: Colors.grey[600])),
                                        ],
                                      ),
                                      onTap: () => onSelected(client),
                                      tileColor: Colors.white, // White background for each tile
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
                          // Keep the same controller instance in the widget state
                          if (_clientSearchCtrl.text != textCtrl.text) {
                            textCtrl.text = _clientSearchCtrl.text;
                            textCtrl.selection = TextSelection.collapsed(offset: textCtrl.text.length);
                          }

                          textCtrl.addListener(() {
                            _clientSearchCtrl.text = textCtrl.text;
                            if (textCtrl.text.trim().isEmpty) {
                              setState(() => _selectedClient = null);
                            }
                          });

                          return TextFormField(
                            controller: textCtrl,
                            focusNode: focusNode,
                            decoration: _inputDecoration(
                              label: 'Search for a client...',
                              prefix: const Icon(Icons.search, size: 18),
                            ),
                            style: TextStyle(fontSize: 10.sp),
                            validator: (_) => (_selectedClient == null) ? 'Select a client' : null,
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
                        onPressed: _openAddClientDialog,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Date / Start / End (minimal row like screenshot)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Date *',
                            prefix: const Icon(Icons.calendar_month_outlined, size: 18),
                          ),
                          child: Text(dateText, style: TextStyle(fontSize: 10.sp)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Start Time *',
                            prefix: const Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(startText, style: TextStyle(fontSize: 10.sp)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          label: 'End Time *',
                          prefix: const Icon(Icons.access_time_filled, size: 18),
                        ),
                        child: Text(endText, style: TextStyle(fontSize: 10.sp)),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

Row(children: [
                  Expanded(flex: 3, child: DropdownButtonFormField<ServiceItem>(
                    value: _selectedService,
                    isExpanded: true,
                    decoration: _inputDecoration(label: 'Service *'),
                    items: _services.map((s) => DropdownMenuItem(value: s, child: Text('${s.name}  ₹${s.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 10.sp), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (s) { setState(() => _selectedService = s); _recalculatePricingAndTimes(); },
                    validator: (v) => v == null ? 'Select service' : null,
                  )),
                  SizedBox(width: 8.w),
                  SizedBox(height: 40.h, child: OutlinedButton(onPressed: _openAddServiceDialog, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))), child: const Icon(Icons.add, size: 18))),
                  SizedBox(width: 8.w),

                  // STAFF DROPDOWN ONLY — NO + BUTTON
                  Expanded(
                    flex: 4, // Takes more space since no add button
                    child: DropdownButtonFormField<StaffMember>(
                      value: _selectedStaff,
                      isExpanded: true,
                      decoration: _inputDecoration(label: 'Staff *'),
                      dropdownColor: Colors.white,
                      hint: _isLoadingStaff
                          ? Text('Loading staff...', style: TextStyle(fontSize: 10.sp, color: Colors.grey))
                          : Text('Select staff', style: TextStyle(fontSize: 10.sp)),
                      items: _staff.map((staff) => DropdownMenuItem<StaffMember>(
                        value: staff,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                staff.fullName ?? 'Unknown Staff',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (staff.email != null && staff.email!.isNotEmpty)
                                Text(staff.email!, style: TextStyle(fontSize: 9.sp, color: Colors.grey[700])),
                              if (staff.mobile != null && staff.mobile!.isNotEmpty)
                                Text(staff.mobile!, style: TextStyle(fontSize: 9.sp, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      )).toList(),
                      onChanged: _isLoadingStaff ? null : (value) => setState(() => _selectedStaff = value),
                      validator: (v) => v == null ? 'Select staff' : null,
                    ),
                  ),
                ]),
                SizedBox(height: 12.h),

                // Display selected client details if selected
                if (_selectedClient != null)
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Client:', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4.h),
                        Text('Name: ${_selectedClient!.name}', style: TextStyle(fontSize: 10.sp)),
                        Text('Email: ${_selectedClient!.email}', style: TextStyle(fontSize: 10.sp)),
                        Text('Mobile: ${_selectedClient!.mobile}', style: TextStyle(fontSize: 10.sp)),
                      ],
                    ),
                  ),

                // Selected Staff Info
                if (_selectedStaff != null)
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8.r)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Selected Staff:', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4.h),
                      Text('Name: ${_selectedStaff!.fullName ?? 'Unknown'}', style: TextStyle(fontSize: 10.sp)),
                      if (_selectedStaff!.email != null) Text('Email: ${_selectedStaff!.email}', style: TextStyle(fontSize: 10.sp)),
                      if (_selectedStaff!.mobile != null) Text('Mobile: ${_selectedStaff!.mobile}', style: TextStyle(fontSize: 10.sp)),
                    ]),
                  ),

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
                        readOnly: true,
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
                        child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: _saveAppointment,
                        child: Text('Create', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
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