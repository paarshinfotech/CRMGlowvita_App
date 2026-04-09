import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../vendor_model.dart';

class AddStaffDialog extends StatefulWidget {
  final Map? existing;
  final VoidCallback? onRefresh;

  const AddStaffDialog({Key? key, this.existing, this.onRefresh}) : super(key: key);

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog>
    with SingleTickerProviderStateMixin {
  // Personal
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _position = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _description = TextEditingController();

  // Employment
  final _salary = TextEditingController();
  final _experience = TextEditingController();
  final _clients = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _commissionEnabled = false;
  final _commissionPercentage = TextEditingController();

  // Bank
  final _accHolder = TextEditingController();
  final _accNumber = TextEditingController();
  final _bankName = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();

  // Permissions (display name -> checked)
  final Map<String, bool> _permissions = {
    'Dashboard': false,
    'Staff': false,
    'Products': false,
    'Orders': false,
    'Offers & Coupons': false,
    'Notifications': false,
    'Calendar': false,
    'Clients': false,
    'Marketplace': false,
    'Shipping': false,
    'Referrals': false,
    'Reports': false,
    'Appointments': false,
    'Services': false,
    'Sales': false,
    'Settlements': false,
    'Marketing': false,
    'Expenses': false,
  };

  // Timing controllers
  final Map<String, TextEditingController> _weeklyTiming = {
    'Mon': TextEditingController(),
    'Tue': TextEditingController(),
    'Wed': TextEditingController(),
    'Thu': TextEditingController(),
    'Fri': TextEditingController(),
    'Sat': TextEditingController(),
    'Sun': TextEditingController(),
  };

  // Weekly availability (day -> isAvailable)
  final Map<String, bool> _weeklyAvailability = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };

  // Salon Opening Hours
  VendorProfile? _vendorProfile;
  bool _isLoadingSalonHours = true;

  // Photo (either http url or local file path)
  String? _imagePath;

  // Form keys per tab
  final _personalFormKey = GlobalKey<FormState>();
  final _employmentFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  late final TabController _tabController;
  bool _isSaving = false;
  Map? _localExisting;

  // Mapping: Display permission -> API permission string
  static const Map<String, String> displayToPerm = {
    'Dashboard': 'dashboard_view',
    'Calendar': 'calendar_view',
    'Appointments': 'appointments_view',
    'Staff': 'staff_view',
    'Products': 'products_view',
    'Orders': 'orders_view',
    'Offers & Coupons': 'offers_view',
    'Notifications': 'notifications_view',
    'Clients': 'clients_view',
    'Marketplace': 'marketplace_view',
    'Shipping': 'shipping_view',
    'Referrals': 'referrals_view',
    'Reports': 'reports_view',
    'Services': 'services_view',
    'Sales': 'sales_view',
    'Settlements': 'settlements_view',
    'Marketing': 'marketing_view',
    'Expenses': 'expenses_view',
  };

  static const Map<String, String> dayAbbrToFull = {
    'Mon': 'monday',
    'Tue': 'tuesday',
    'Wed': 'wednesday',
    'Thu': 'thursday',
    'Fri': 'friday',
    'Sat': 'saturday',
    'Sun': 'sunday',
  };

  static const Map<String, String> dayFullToAbbr = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  ImageProvider? _getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('data:image')) {
      return MemoryImage(base64Decode(path.split(',').last));
    }
    if (path.contains('/')) {
      // Relative path
      final baseUrl = 'https://partners.glowvitasalon.com';
      final fullUrl = '$baseUrl${path.startsWith('/') ? path : '/$path'}';
      return NetworkImage(fullUrl);
    }
    // Local file path
    return FileImage(File(path));
  }

  int _timeToMinutes(String time) {
    if (time.isEmpty) return 0;
    try {
      // Try parsing with AM/PM first
      try {
        final date = DateFormat.jm().parse(time.trim());
        return date.hour * 60 + date.minute;
      } catch (_) {
        // Fallback to 24h format
        final date = DateFormat("HH:mm").parse(time.trim());
        return date.hour * 60 + date.minute;
      }
    } catch (e) {
      debugPrint('Error parsing time to minutes ($time): $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _localExisting = widget.existing;
    _fetchSalonHours();

    // Initialize default availability to true for all days
    _weeklyAvailability['monday'] = true;
    _weeklyAvailability['tuesday'] = true;
    _weeklyAvailability['wednesday'] = true;
    _weeklyAvailability['thursday'] = true;
    _weeklyAvailability['friday'] = true;
    _weeklyAvailability['saturday'] = true;
    _weeklyAvailability['sunday'] = true;

    if (widget.existing != null) {
      final m = widget.existing!;

      // Personal
      final fullName = m['fullName'] ?? '';
      final parts = fullName.toString().split(RegExp(r'\s+'));
      _firstName.text = parts.isNotEmpty ? parts.first : '';
      _lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _position.text = m['position'] ?? '';
      _mobile.text = m['mobileNo'] ?? '';
      _email.text = m['emailAddress'] ?? '';
      _description.text = m['description'] ?? '';

      // Employment
      _salary.text = (m['salary'] ?? '').toString();
      _experience.text = (m['yearOfExperience'] ?? '').toString();
      _clients.text = (m['clientsServed'] ?? '').toString();
      _commissionEnabled = m['commission'] == true;
      _commissionPercentage.text =
          (m['commissionRate'] ?? m['commissionPercentage'] ?? '').toString();

      if (m['startDate'] != null)
        _startDate = DateTime.tryParse(m['startDate'].toString());
      if (m['endDate'] != null)
        _endDate = DateTime.tryParse(m['endDate'].toString());

      // Bank
      final bank = (m['bankDetails'] as Map?) ?? {};
      _accHolder.text = (bank['accountHolderName'] ?? '').toString();
      _accNumber.text = (bank['accountNumber'] ?? '').toString();
      _bankName.text = (bank['bankName'] ?? '').toString();
      _ifsc.text = (bank['ifscCode'] ?? '').toString();
      _upi.text = (bank['upiId'] ?? '').toString();

      // Permissions
      final permList = (m['permissions'] as List?) ?? [];
      final inverse = displayToPerm.map((k, v) => MapEntry(v, k));
      for (final perm in permList) {
        final displayName = inverse[perm];
        if (displayName != null) _permissions[displayName] = true;
      }

      // Availability
      for (final fullDay in dayFullToAbbr.keys) {
        final abbr = dayFullToAbbr[fullDay]!;

        bool available = false;
        List slots = [];

        // 1. Try flat fields (priority)
        if (m.containsKey('${fullDay}Available')) {
          available = m['${fullDay}Available'] == true;
          slots = m['${fullDay}Slots'] as List? ?? [];
        }
        // 2. Try nested availability object
        else {
          final availabilityData = m['availability'] as Map?;
          if (availabilityData != null) {
            // Check for flattened key inside (StaffMember.toJson adds them there)
            if (availabilityData.containsKey('${fullDay}Available')) {
              available = availabilityData['${fullDay}Available'] == true;
              slots = availabilityData['${fullDay}Slots'] as List? ?? [];
            }
            // Check for nested day key
            else if (availabilityData.containsKey(fullDay)) {
              final dayData = availabilityData[fullDay] as Map?;
              if (dayData != null) {
                available = dayData['available'] == true;
                slots = dayData['slots'] as List? ?? [];
              }
            }
          }
        }

        _weeklyAvailability[fullDay] = available;
        if (available && slots.isNotEmpty) {
          final slot = (slots.first as Map?) ?? {};
          final start = (slot['startTime'] ?? '10:00').toString();
          final end = (slot['endTime'] ?? '19:00').toString();
          _weeklyTiming[abbr]!.text = '$start - $end';
        }
      }


      // Photo
      if (m['photo'] != null && m['photo'].toString().isNotEmpty) {
        _imagePath = m['photo'].toString();
      }
    }
  }

  Future<void> _fetchSalonHours() async {
    try {
      final profile = await ApiService.getVendorProfile();
      if (mounted) {
        setState(() {
          _vendorProfile = profile;
          _isLoadingSalonHours = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching salon hours: $e');
      if (mounted) {
        setState(() {
          _isLoadingSalonHours = false;
        });
      }
    }
  }

  bool _isTimeWithinSalonHours(
      String day, TimeOfDay staffStart, TimeOfDay staffEnd) {
    if (_vendorProfile == null) return true; // Fallback if profile not loaded

    final fullDay = day.toLowerCase();
    final oh = _vendorProfile!.openingHours.firstWhere(
      (h) => h.day.toLowerCase() == fullDay,
      orElse: () =>
          OpeningHour(day: day, open: '00:00', close: '23:59', isOpen: true),
    );

    if (!oh.isOpen) return false;

    final salonOpen = _parseTimeOfDay(oh.open);
    final salonClose = _parseTimeOfDay(oh.close);

    final staffStartMins = staffStart.hour * 60 + staffStart.minute;
    final staffEndMins = staffEnd.hour * 60 + staffEnd.minute;
    final salonOpenMins = salonOpen.hour * 60 + salonOpen.minute;
    final salonCloseMins = salonClose.hour * 60 + salonClose.minute;

    return staffStartMins >= salonOpenMins && staffEndMins <= salonCloseMins;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _tabController.dispose();

    _firstName.dispose();
    _lastName.dispose();
    _position.dispose();
    _mobile.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _description.dispose();

    _salary.dispose();
    _experience.dispose();
    _clients.dispose();
    _commissionPercentage.dispose();

    _accHolder.dispose();
    _accNumber.dispose();
    _bankName.dispose();
    _ifsc.dispose();
    _upi.dispose();

    _weeklyTiming.values.forEach((c) => c.dispose());

    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  bool _validateAll() {
    final personalOk = _personalFormKey.currentState?.validate() ?? true;
    final employmentOk = _employmentFormKey.currentState?.validate() ?? true;
    final bankOk = _bankFormKey.currentState?.validate() ?? true;

    if (!personalOk) {
      _tabController.animateTo(0);
      return false;
    }
    if (!employmentOk) {
      _tabController.animateTo(1);
      return false;
    }
    if (!bankOk) {
      _tabController.animateTo(2);
      return false;
    }

    // Extra password checks for new staff
    if (widget.existing == null) {
      if (_password.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password is required for new staff'),
              backgroundColor: Colors.red),
        );
        _tabController.animateTo(0);
        return false;
      }
      if (_password.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password must be at least 6 characters'),
              backgroundColor: Colors.red),
        );
        _tabController.animateTo(0);
        return false;
      }
      if (_confirmPassword.text != _password.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red),
        );
        _tabController.animateTo(0);
        return false;
      }
    } else {
      // On edit, password is optional; if user enters it, validate it
      if (_password.text.trim().isNotEmpty) {
        if (_password.text.trim().length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Password must be at least 6 characters'),
                backgroundColor: Colors.red),
          );
          _tabController.animateTo(0);
          return false;
        }
        if (_confirmPassword.text != _password.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Passwords do not match'),
                backgroundColor: Colors.red),
          );
          _tabController.animateTo(0);
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _save() async {
    debugPrint('=== Staff Save Process Started ===');
    debugPrint('Status: Validating form data');

    if (!_validateAll()) {
      debugPrint('Status: Validation failed, cannot proceed with save');
      return;
    }

    debugPrint('Status: Validation passed, processing staff data');

    final fullName =
        '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
    debugPrint('Activities: Full name constructed: $fullName');

    // Permissions -> API list
    final List<String> permissions = _permissions.entries
        .where((e) => e.value)
        .map((e) => displayToPerm[e.key]!)
        .toList();
    debugPrint('Activities: Permissions selected: $permissions');

    // Availability format (Flattened day-specific fields)
    final Map<String, dynamic> availabilityFields = {};

    _weeklyTiming.forEach((abbr, controller) {
      final text = controller.text.trim();
      final fullDay = dayAbbrToFull[abbr]!;
      final isAvailable = _weeklyAvailability[fullDay] ?? false;

      availabilityFields['${fullDay}Available'] = isAvailable;

      if (!isAvailable || text.isEmpty) {
        availabilityFields['${fullDay}Slots'] = [];
      } else {
        final parts = text.split(' - ');
        if (parts.length == 2) {
          final startTime = parts[0].trim();
          final endTime = parts[1].trim();

          availabilityFields['${fullDay}Slots'] = [
            {
              "startTime": startTime,
              "endTime": endTime,
              "startMinutes": _timeToMinutes(startTime),
              "endMinutes": _timeToMinutes(endTime),
            }
          ];
        } else {
          availabilityFields['${fullDay}Slots'] = [];
        }
      }
    });
    debugPrint('Activities: Availability fields set: $availabilityFields');

    // Commission percentage
    final double commissionPercentage =
        double.tryParse(_commissionPercentage.text.trim()) ?? 0.0;

    // Blocked times (None as requested)
    final List<Map<String, dynamic>> blockedTimes = [];

    // Bank details
    final Map<String, dynamic> bankDetails = {
      "accountHolderName": _accHolder.text.trim(),
      "accountNumber": _accNumber.text.trim(),
      "bankName": _bankName.text.trim(),
      "ifscCode": _ifsc.text.trim(),
      "upiId": _upi.text.trim(),
    };
    debugPrint('Activities: Bank details set: $bankDetails');

    // Numeric fields
    final int salary = int.tryParse(_salary.text.trim()) ?? 0;
    final int yearOfExperience = int.tryParse(_experience.text.trim()) ?? 0;
    final int clientsServed = int.tryParse(_clients.text.trim()) ?? 0;
    debugPrint(
        'Activities: Numeric values - Salary: $salary, Experience: $yearOfExperience, Clients: $clientsServed');

    // Dates
    final String? startDate = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;
    final String? endDate =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;
    debugPrint(
        'Activities: Employment dates - Start: $startDate, End: $endDate');

    // Password (optional on edit)
    String? password;
    if (widget.existing == null) {
      password = _password.text.trim();
      debugPrint('Activities: Creating new staff, password provided');
    } else {
      if (_password.text.trim().isNotEmpty) {
        password = _password.text.trim();
        debugPrint('Activities: Updating staff, password changed');
      } else {
        debugPrint('Activities: Updating staff, password unchanged');
      }
    }

    // Convert photo to base64 if it's a local file
    String? photoBase64 = _imagePath;
    if (_imagePath != null &&
        !_imagePath!.startsWith('http') &&
        !_imagePath!.startsWith('data:image')) {
      try {
        final bytes = File(_imagePath!).readAsBytesSync();
        photoBase64 =
            'data:image/${_imagePath!.split('.').last};base64,${base64Encode(bytes)}';
      } catch (e) {
        debugPrint('Error converting image to base64: $e');
      }
    }

    final Map<String, dynamic> result = {
      'fullName': fullName.isEmpty ? 'Unnamed Staff' : fullName,
      'position': _position.text.trim(),
      'mobileNo': _mobile.text.trim(),
      'emailAddress': _email.text.trim(),
      'description': _description.text.trim(),
      'salary': salary,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'yearOfExperience': yearOfExperience,
      'clientsServed': clientsServed,
      'commission': _commissionEnabled,
      'commissionRate': commissionPercentage,
      'permissions': permissions,
      'permission': permissions,
      ...availabilityFields,
      'blockedTimes': blockedTimes,
      'bankDetails': bankDetails,
      'userType': 'staff',
      if (password != null) 'password': password,
      if (photoBase64 != null) 'photo': photoBase64,
    };
    // keep id for edit
    if (_localExisting != null) {
      result['id'] = _localExisting!['_id'];
      result['_id'] = _localExisting!['_id'];
      debugPrint('Activities: Editing existing staff with ID: ${result['id']}');
    }

    setState(() => _isSaving = true);
    try {
      if (_localExisting != null) {
        await ApiService.updateStaff(_localExisting!['_id'], result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Staff details updated successfully'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        final response = await ApiService.createStaff(result);
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['staff'] != null) {
            _localExisting = data['staff'];
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Staff created successfully'),
                  backgroundColor: Colors.green),
            );
          }
        }
      }
      widget.onRefresh?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving staff: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW < 960 ? screenW - 32 : 920.0;
    final dialogH = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.existing == null ? 'Add New Staff' : 'Edit Staff',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Employment'),
                Tab(text: 'Bank Details'),
                Tab(text: 'Permissions'),
                Tab(text: 'Timing'),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(),
                  _buildEmploymentTab(),
                  _buildBankTab(),
                  _buildPermissionsTab(),
                  _buildTimingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A2C40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    _localExisting == null ? 'Save Staff' : 'Update Staff',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      );

  Widget _buildPersonalTab() {
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _labeled(
                    'First Name',
                    TextFormField(
                      controller: _firstName,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'First name is required'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: _labeled(
                        'Last Name', TextFormField(controller: _lastName))),
              ],
            ),
            _labeled(
              'Position',
              TextFormField(
                controller: _position,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Position is required'
                    : null,
              ),
            ),
            _labeled(
              'Mobile Number',
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Mobile number is required';
                  if (v.trim().length < 10)
                    return 'Enter a valid mobile number';
                  return null;
                },
              ),
            ),
            _labeled(
              'Email Address',
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final ok = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v.trim());
                  if (!ok) return 'Enter a valid email address';
                  return null;
                },
              ),
            ),
            // Password always shown; on edit it's optional
            _labeled(
              'Password ${widget.existing == null ? "(Required)" : "(Optional)"}',
              TextFormField(
                controller: _password,
                obscureText: true,
                validator: (v) {
                  if (widget.existing == null) {
                    if (v == null || v.trim().isEmpty)
                      return 'Password is required';
                    if (v.trim().length < 6)
                      return 'Password must be at least 6 characters';
                  } else {
                    if (v != null &&
                        v.trim().isNotEmpty &&
                        v.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                  }
                  return null;
                },
              ),
            ),
            _labeled(
              'Confirm Password ${widget.existing == null ? "(Required)" : "(If changing password)"}',
              TextFormField(
                controller: _confirmPassword,
                obscureText: true,
                validator: (v) {
                  if (widget.existing == null) {
                    if (v == null || v.isEmpty)
                      return 'Confirm password is required';
                    if (v != _password.text) return 'Passwords do not match';
                  } else {
                    if (_password.text.trim().isNotEmpty) {
                      if (v != _password.text) return 'Passwords do not match';
                    }
                  }
                  return null;
                },
              ),
            ),
            _labeled('Description',
                TextFormField(controller: _description, maxLines: 3)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: _getImageProvider(_imagePath),
                  child: _imagePath == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: Text('Upload Photo',
                          style: GoogleFonts.poppins(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A2C40),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_imagePath != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _imagePath = null),
                        icon: const Icon(Icons.delete_outline,
                            size: 14, color: Colors.red),
                        label: Text('Remove',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.red)),
                      ),
                  ],
                )
              ],
            ),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentTab() {
    return Form(
      key: _employmentFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _labeled(
                    'Salary',
                    TextFormField(
                      controller: _salary,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return null; // optional
                        if (double.tryParse(v.trim()) == null)
                          return 'Enter a valid salary';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeled(
                    'Years of Experience',
                    TextFormField(
                      controller: _experience,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return null; // optional
                        if (int.tryParse(v.trim()) == null)
                          return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _labeled(
                    'Clients Served',
                    TextFormField(
                      controller: _clients,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return null; // optional
                        if (int.tryParse(v.trim()) == null)
                          return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: _commissionEnabled,
                            activeColor: const Color(0xFF4A2C40),
                            onChanged: (v) =>
                                setState(() => _commissionEnabled = v),
                          ),
                          Text('Staff Commission',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_commissionEnabled) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commission Percentage (%)',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _commissionPercentage,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '10',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF4A2C40), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    validator: (v) {
                      if (_commissionEnabled) {
                        if (v == null || v.trim().isEmpty)
                          return 'Percentage is required';
                        if (double.tryParse(v.trim()) == null)
                          return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.auto_graph,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Staff will earn ${_commissionPercentage.text.isEmpty ? '0' : _commissionPercentage.text}% on all completed appointments.',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            Row(
              children: [
                Expanded(
                    child: _DateField(
                        label: 'Start Date',
                        date: _startDate,
                        onTap: () => _pickDate(start: true))),
                const SizedBox(width: 16),
                Expanded(
                    child: _DateField(
                        label: 'End Date (Optional)',
                        date: _endDate,
                        onTap: () => _pickDate(start: false))),
              ],
            ),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTab() {
    return Form(
      key: _bankFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _labeled(
              'Account Holder Name',
              TextFormField(
                controller: _accHolder,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Account holder name is required';
                  return null;
                },
              ),
            ),
            _labeled(
              'Account Number',
              TextFormField(
                controller: _accNumber,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Account number is required';
                  if (int.tryParse(v.trim()) == null)
                    return 'Enter a valid account number';
                  return null;
                },
              ),
            ),
            _labeled(
              'Bank Name',
              TextFormField(
                controller: _bankName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Bank name is required'
                    : null,
              ),
            ),
            _labeled(
              'IFSC Code',
              TextFormField(
                controller: _ifsc,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'IFSC code is required'
                    : null,
              ),
            ),
            _labeled(
              'UPI ID',
              TextFormField(
                controller: _upi,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'UPI ID is required'
                    : null,
              ),
            ),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _permissions.keys.map((key) {
              return SizedBox(
                width: 200,
                child: CheckboxListTile(
                  title: Text(key, style: GoogleFonts.poppins(fontSize: 11)),
                  value: _permissions[key],
                  onChanged: (v) =>
                      setState(() => _permissions[key] = v ?? false),
                  dense: true,
                ),
              );
            }).toList(),
          ),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _buildTimingTab() {
    if (_isLoadingSalonHours) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set staff working hours within salon opening hours.',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._weeklyTiming.keys.map((abbr) {
            final fullDay = dayAbbrToFull[abbr]!;
            final isAvailable = _weeklyAvailability[fullDay] ?? false;

            // Get salon hours for this day
            final oh = _vendorProfile?.openingHours.firstWhere(
              (h) => h.day.toLowerCase() == fullDay.toLowerCase(),
              orElse: () => OpeningHour(
                  day: fullDay, open: '00:00', close: '23:59', isOpen: true),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          fullDay[0].toUpperCase() + fullDay.substring(1),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        activeColor: const Color(0xFF4A2C40),
                        onChanged: (v) {
                          setState(() {
                            _weeklyAvailability[fullDay] = v;
                            if (!v) {
                              _weeklyTiming[abbr]!.clear();
                            } else if (_weeklyTiming[abbr]!.text.isEmpty) {
                              // Default hours if toggled ON and empty
                              if (oh != null && oh.isOpen) {
                                _weeklyTiming[abbr]!.text =
                                    '${oh.open} - ${oh.close}';
                              } else {
                                _weeklyTiming[abbr]!.text = '10:00 - 19:00';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAvailable ? 'Available' : 'Unavailable',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (isAvailable) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 100),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TimeRangePicker(
                                day: fullDay,
                                controller: _weeklyTiming[abbr]!,
                                salonHours: oh,
                              ),
                              if (oh != null && oh.isOpen)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 4),
                                  child: Text(
                                    'Salon Hours: ${oh.open} - ${oh.close}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(),
                ],
              ),
            );
          }).toList(),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget field) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                  labelStyle: GoogleFonts.poppins(fontSize: 11),
                  hintStyle:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  errorStyle: GoogleFonts.poppins(fontSize: 9),
                ),
              ),
              child: field,
            ),
          ],
        ),
      );

  Widget _buildBlockTimeTab() {
    return Container();
  }

  Widget _buildNoData(String s) {
    return Center(
      child: Text(s, style: GoogleFonts.poppins(fontSize: 11)),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        date == null
                            ? 'Not set'
                            : DateFormat('dd/MM/yyyy').format(date!),
                        style: GoogleFonts.poppins(fontSize: 11))),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeRangePicker extends StatefulWidget {
  final String day;
  final TextEditingController controller;
  final OpeningHour? salonHours;

  const _TimeRangePicker({
    required this.day,
    required this.controller,
    this.salonHours,
  });

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  TimeOfDay? start;
  TimeOfDay? end;

  @override
  void initState() {
    super.initState();
    _parseFromController();
  }

  void _parseFromController() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    final parts = text.split(' - ');
    if (parts.length == 2) {
      setState(() {
        start = _parseTime(parts[0]);
        end = _parseTime(parts[1]);
      });
    }
  }

  void _updateText() {
    if (start != null && end != null) {
      // Use 12h format with AM/PM for display
      final now = DateTime.now();
      final dtStart = DateTime(now.year, now.month, now.day, start!.hour, start!.minute);
      final dtEnd = DateTime(now.year, now.month, now.day, end!.hour, end!.minute);
      widget.controller.text = '${DateFormat.jm().format(dtStart)} - ${DateFormat.jm().format(dtEnd)}';
    } else {
      widget.controller.text = '';
    }
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (start ?? const TimeOfDay(hour: 9, minute: 0))
          : (end ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      if (widget.salonHours != null && widget.salonHours!.isOpen) {
        final salonOpen = _parseTime(widget.salonHours!.open);
        final salonClose = _parseTime(widget.salonHours!.close);

        final staffTimeMins = picked.hour * 60 + picked.minute;
        final salonOpenMins = salonOpen.hour * 60 + salonOpen.minute;
        final salonCloseMins = salonClose.hour * 60 + salonClose.minute;

        if (staffTimeMins < salonOpenMins || staffTimeMins > salonCloseMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Selected time must be within salon hours (${widget.salonHours!.open} - ${widget.salonHours!.close})'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      setState(() {
        if (isStart)
          start = picked;
        else
          end = picked;
      });

      if (start != null && end != null) {
        final startMins = start!.hour * 60 + start!.minute;
        final endMins = end!.hour * 60 + end!.minute;
        if (startMins >= endMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start time must be before end time'),
              backgroundColor: Colors.red,
            ),
          );
          // Don't clear but flag maybe?
        }
      }

      _updateText();
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      // Try AM/PM
      try {
        final date = DateFormat.jm().parse(time.trim());
        return TimeOfDay(hour: date.hour, minute: date.minute);
      } catch (_) {
        // Fallback to 24h
        final pts = time.split(':');
        return TimeOfDay(
            hour: int.parse(pts[0].trim()),
            minute: int.parse(pts[1].trim().split(' ')[0]));
      }
    } catch (e) {
      debugPrint('Error parsing time string ($time): $e');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pick(true),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
              ),
              child: Text(start?.format(context) ?? 'Start',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 10)),
            ),
          ),
        ),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('-', style: TextStyle(color: Colors.grey))),
        Expanded(
          child: InkWell(
            onTap: () => _pick(false),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).primaryColor.withOpacity(0.02),
              ),
              child: Text(end?.format(context) ?? 'End',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 10)),
            ),
          ),
        ),
        if (start != null || end != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                start = null;
                end = null;
              });
              widget.controller.clear();
            },
          ),
      ],
    );
  }
}
